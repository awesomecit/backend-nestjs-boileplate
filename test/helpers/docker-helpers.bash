#!/usr/bin/env bash

# test/helpers/docker-helpers.bash
# Docker Swarm and Container Management Utilities
# Follows SOLID principles for maintainable test infrastructure

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# ============================================================================
# CONFIGURATION & CONSTANTS (Single Responsibility)
# ============================================================================

readonly DOCKER_HELPERS_VERSION="1.0.0"
readonly DEFAULT_TIMEOUT=60
readonly DEFAULT_RETRY_INTERVAL=2
readonly SWARM_INIT_TIMEOUT=30

# Environment detection
readonly CI_ENVIRONMENT=${CI:-false}
# readonly DOCKER_HOST_IP=$(get_docker_host_ip)

# ============================================================================
# LOGGING UTILITIES (Single Responsibility) 
# ============================================================================

log_info() {
    echo "[INFO $(date '+%Y-%m-%d %H:%M:%S')] $*" >&2
}

log_error() {
    echo "[ERROR $(date '+%Y-%m-%d %H:%M:%S')] $*" >&2
}

log_debug() {
    if [[ "${DEBUG:-false}" == "true" ]]; then
        echo "[DEBUG $(date '+%Y-%m-%d %H:%M:%S')] $*" >&2
    fi
}

# ============================================================================
# NETWORK & CONNECTIVITY (Interface Segregation)
# ============================================================================

get_docker_host_ip() {
    # Abstraction for Docker host IP detection
    if [[ "$CI_ENVIRONMENT" == "true" ]]; then
        echo "127.0.0.1"
    elif command -v docker-machine >/dev/null 2>&1; then
        docker-machine ip default 2>/dev/null || echo "127.0.0.1"
    else
        # Local Docker Desktop or native Linux
        echo "127.0.0.1"
    fi
}

get_primary_ip() {
    # Get primary network interface IP for Swarm advertising
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        route get default | grep gateway | awk '{print $2}' | head -1
    elif [[ "$CI_ENVIRONMENT" == "true" ]]; then
        # CI environment
        echo "127.0.0.1"
    else
        # Linux
        ip route get 1.1.1.1 | grep -oP 'src \K\S+' | head -1
    fi
}

wait_for_port() {
    local host=${1:-localhost}
    local port=${2:?Port is required}
    local timeout=${3:-$DEFAULT_TIMEOUT}
    local count=0
    
    log_info "Waiting for $host:$port to be available..."
    
    while [ $count -lt $timeout ]; do
        if timeout 1 bash -c "</dev/tcp/$host/$port" 2>/dev/null; then
            log_info "Port $host:$port is available"
            return 0
        fi
        sleep $DEFAULT_RETRY_INTERVAL
        ((count += DEFAULT_RETRY_INTERVAL))
    done
    
    log_error "Timeout waiting for $host:$port after ${timeout}s"
    return 1
}

# ============================================================================
# DOCKER SWARM MANAGEMENT (Single Responsibility)
# ============================================================================

is_swarm_active() {
    # Check if Docker Swarm is initialized and active
    local swarm_state
    swarm_state=$(docker info --format '{{.Swarm.LocalNodeState}}' 2>/dev/null || echo "inactive")
    [[ "$swarm_state" == "active" ]]
}

init_swarm_cluster() {
    # Initialize Docker Swarm cluster with proper error handling
    local advertise_addr=${1:-$(get_primary_ip)}
    
    log_info "Initializing Docker Swarm cluster..."
    log_debug "Advertise address: $advertise_addr"
    
    if is_swarm_active; then
        log_info "Swarm already active, skipping initialization"
        return 0
    fi
    
    if ! docker swarm init --advertise-addr "$advertise_addr" 2>/dev/null; then
        log_error "Failed to initialize Docker Swarm"
        return 1
    fi
    
    # Wait for swarm to be fully ready
    wait_for_swarm_ready
    
    log_info "Docker Swarm cluster initialized successfully"
    return 0
}

wait_for_swarm_ready() {
    # Wait for Swarm cluster to be fully operational
    local timeout=${1:-$SWARM_INIT_TIMEOUT}
    local count=0
    
    while [ $count -lt $timeout ]; do
        if is_swarm_active && docker node ls >/dev/null 2>&1; then
            log_debug "Swarm cluster is ready"
            return 0
        fi
        sleep 1
        ((count++))
    done
    
    log_error "Swarm cluster not ready after ${timeout}s"
    return 1
}

leave_swarm_cluster() {
    # Safely leave Docker Swarm cluster
    if is_swarm_active; then
        log_info "Leaving Docker Swarm cluster..."
        docker swarm leave --force 2>/dev/null || {
            log_error "Failed to leave swarm cluster"
            return 1
        }
        log_info "Left Docker Swarm cluster successfully"
    else
        log_debug "Not in a swarm cluster, nothing to leave"
    fi
}

get_swarm_join_token() {
    # Get worker join token for adding nodes
    local token_type=${1:-worker}  # worker or manager
    
    if ! is_swarm_active; then
        log_error "Swarm not active, cannot get join token"
        return 1
    fi
    
    docker swarm join-token "$token_type" -q 2>/dev/null || {
        log_error "Failed to get $token_type join token"
        return 1
    }
}

# ============================================================================
# SERVICE MANAGEMENT (Single Responsibility)
# ============================================================================

deploy_stack() {
    # Deploy Docker stack with validation
    local stack_name=${1:?Stack name is required}
    local compose_file=${2:?Compose file is required}
    local timeout=${3:-$DEFAULT_TIMEOUT}
    
    log_info "Deploying stack '$stack_name' from '$compose_file'..."
    
    # Validate compose file exists
    if [[ ! -f "$compose_file" ]]; then
        log_error "Compose file '$compose_file' not found"
        return 1
    fi
    
    # Deploy the stack
    if ! docker stack deploy -c "$compose_file" "$stack_name"; then
        log_error "Failed to deploy stack '$stack_name'"
        return 1
    fi
    
    # Wait for services to be ready
    wait_for_stack_ready "$stack_name" "$timeout"
}

wait_for_stack_ready() {
    # Wait for all services in stack to be ready
    local stack_name=${1:?Stack name is required}
    local timeout=${2:-$DEFAULT_TIMEOUT}
    local count=0
    
    log_info "Waiting for stack '$stack_name' to be ready..."
    
    while [ $count -lt $timeout ]; do
        local services_ready=true
        
        # Check each service in the stack
        while IFS= read -r service; do
            if ! is_service_ready "$service"; then
                services_ready=false
                break
            fi
        done < <(docker stack services "$stack_name" --format "{{.Name}}" 2>/dev/null)
        
        if [[ "$services_ready" == "true" ]]; then
            log_info "Stack '$stack_name' is ready"
            return 0
        fi
        
        sleep $DEFAULT_RETRY_INTERVAL
        ((count += DEFAULT_RETRY_INTERVAL))
    done
    
    log_error "Stack '$stack_name' not ready after ${timeout}s"
    show_stack_status "$stack_name"
    return 1
}

is_service_ready() {
    # Check if a Docker service is ready (all replicas running)
    local service_name=${1:?Service name is required}
    
    local replica_status
    replica_status=$(docker service ls --filter "name=$service_name" --format "{{.Replicas}}" 2>/dev/null || echo "0/0")
    
    if [[ "$replica_status" == *"/"* ]]; then
        local running=$(echo "$replica_status" | cut -d'/' -f1)
        local desired=$(echo "$replica_status" | cut -d'/' -f2)
        [[ "$running" == "$desired" && "$running" != "0" ]]
    else
        false
    fi
}

show_stack_status() {
    # Display detailed status of stack for debugging
    local stack_name=${1:?Stack name is required}
    
    log_info "=== Stack Status: $stack_name ==="
    docker stack services "$stack_name" 2>/dev/null || log_error "Failed to get stack services"
    
    log_info "=== Service Tasks ==="
    docker stack ps "$stack_name" --no-trunc 2>/dev/null || log_error "Failed to get stack tasks"
}

remove_stack() {
    # Remove Docker stack with cleanup verification
    local stack_name=${1:?Stack name is required}
    local timeout=${2:-30}
    
    log_info "Removing stack '$stack_name'..."
    
    if ! docker stack ls --format "{{.Name}}" | grep -q "^${stack_name}$"; then
        log_debug "Stack '$stack_name' does not exist"
        return 0
    fi
    
    docker stack rm "$stack_name" || {
        log_error "Failed to remove stack '$stack_name'"
        return 1
    }
    
    # Wait for complete removal
    local count=0
    while [ $count -lt $timeout ]; do
        if ! docker stack ls --format "{{.Name}}" | grep -q "^${stack_name}$"; then
            log_info "Stack '$stack_name' removed successfully"
            return 0
        fi
        sleep 1
        ((count++))
    done
    
    log_error "Stack '$stack_name' removal timeout after ${timeout}s"
    return 1
}

# ============================================================================
# SCALING OPERATIONS (Open/Closed Principle)
# ============================================================================

scale_service() {
    # Scale a Docker service to specified replica count
    local service_name=${1:?Service name is required}
    local replica_count=${2:?Replica count is required}
    local timeout=${3:-$DEFAULT_TIMEOUT}
    
    log_info "Scaling service '$service_name' to $replica_count replicas..."
    
    if ! docker service scale "$service_name=$replica_count"; then
        log_error "Failed to scale service '$service_name'"
        return 1
    fi
    
    # Wait for scaling to complete
    wait_for_service_scaled "$service_name" "$replica_count" "$timeout"
}

wait_for_service_scaled() {
    # Wait for service to reach desired replica count
    local service_name=${1:?Service name is required}
    local desired_replicas=${2:?Desired replica count is required}
    local timeout=${3:-$DEFAULT_TIMEOUT}
    local count=0
    
    while [ $count -lt $timeout ]; do
        local current_replicas
        current_replicas=$(get_service_replica_count "$service_name")
        
        if [[ "$current_replicas" == "$desired_replicas" ]]; then
            log_info "Service '$service_name' scaled to $desired_replicas replicas"
            return 0
        fi
        
        sleep $DEFAULT_RETRY_INTERVAL
        ((count += DEFAULT_RETRY_INTERVAL))
    done
    
    log_error "Service '$service_name' scaling timeout after ${timeout}s"
    return 1
}

get_service_replica_count() {
    # Get current running replica count for a service
    local service_name=${1:?Service name is required}
    
    docker service ls --filter "name=$service_name" --format "{{.Replicas}}" 2>/dev/null | \
        cut -d'/' -f1 || echo "0"
}

# ============================================================================
# HEALTH CHECK UTILITIES (Interface Segregation)
# ============================================================================

wait_for_service_healthy() {
    # Wait for service to pass health checks
    local service_name=${1:?Service name is required}
    local timeout=${2:-$DEFAULT_TIMEOUT}
    local count=0
    
    log_info "Waiting for service '$service_name' to be healthy..."
    
    while [ $count -lt $timeout ]; do
        local unhealthy_tasks
        unhealthy_tasks=$(docker service ps "$service_name" \
            --filter "desired-state=running" \
            --format "{{.CurrentState}}" 2>/dev/null | \
            grep -v "Running" | wc -l)
        
        if [[ "$unhealthy_tasks" -eq 0 ]]; then
            log_info "Service '$service_name' is healthy"
            return 0
        fi
        
        sleep $DEFAULT_RETRY_INTERVAL
        ((count += DEFAULT_RETRY_INTERVAL))
    done
    
    log_error "Service '$service_name' health check timeout after ${timeout}s"
    show_service_health "$service_name"
    return 1
}

show_service_health() {
    # Display service health information for debugging
    local service_name=${1:?Service name is required}
    
    log_info "=== Service Health: $service_name ==="
    docker service ps "$service_name" --no-trunc 2>/dev/null || \
        log_error "Failed to get service tasks"
}

# ============================================================================
# CLEANUP UTILITIES (Dependency Inversion)
# ============================================================================

cleanup_docker_environment() {
    # Comprehensive Docker environment cleanup
    log_info "Cleaning up Docker environment..."
    
    # Remove all stacks
    cleanup_stacks
    
    # Leave swarm if active
    leave_swarm_cluster
    
    # Clean up containers, networks, volumes
    cleanup_containers
    cleanup_networks
    cleanup_volumes
    
    log_info "Docker environment cleanup completed"
}

cleanup_stacks() {
    # Remove all Docker stacks
    local stacks
    stacks=$(docker stack ls --format "{{.Name}}" 2>/dev/null || true)
    
    if [[ -n "$stacks" ]]; then
        log_info "Removing Docker stacks..."
        echo "$stacks" | while read -r stack; do
            remove_stack "$stack"
        done
    fi
}

cleanup_containers() {
    # Remove all containers (running and stopped)
    log_debug "Cleaning up containers..."
    docker container prune -f >/dev/null 2>&1 || true
}

cleanup_networks() {
    # Remove unused networks
    log_debug "Cleaning up networks..."
    docker network prune -f >/dev/null 2>&1 || true
}

cleanup_volumes() {
    # Remove unused volumes
    log_debug "Cleaning up volumes..."
    docker volume prune -f >/dev/null 2>&1 || true
}

# ============================================================================
# TESTING UTILITIES (Single Responsibility)
# ============================================================================

assert_swarm_node_count() {
    # Assert that swarm has expected number of nodes
    local expected_count=${1:?Expected node count is required}
    
    local actual_count
    actual_count=$(docker node ls --format "{{.Hostname}}" 2>/dev/null | wc -l)
    
    if [[ "$actual_count" -eq "$expected_count" ]]; then
        log_info "Swarm has expected $expected_count nodes"
        return 0
    else
        log_error "Expected $expected_count nodes, found $actual_count"
        return 1
    fi
}

assert_service_distributed() {
    # Assert that service replicas are distributed across nodes
    local service_name=${1:?Service name is required}
    local min_nodes=${2:-2}
    
    local unique_nodes
    unique_nodes=$(docker service ps "$service_name" \
        --filter "desired-state=running" \
        --format "{{.Node}}" 2>/dev/null | \
        sort | uniq | wc -l)
    
    if [[ "$unique_nodes" -ge "$min_nodes" ]]; then
        log_info "Service '$service_name' is distributed across $unique_nodes nodes"
        return 0
    else
        log_error "Service '$service_name' only on $unique_nodes nodes (minimum: $min_nodes)"
        return 1
    fi
}

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

validate_docker_available() {
    # Validate Docker is available and running
    if ! command -v docker >/dev/null 2>&1; then
        log_error "Docker command not found"
        return 1
    fi
    
    if ! docker info >/dev/null 2>&1; then
        log_error "Docker daemon not running"
        return 1
    fi
    
    log_debug "Docker is available and running"
    return 0
}

# Inizializza DOCKER_HOST_IP dopo aver definito le funzioni
readonly DOCKER_HOST_IP=$(get_docker_host_ip)

# ============================================================================
# INITIALIZATION
# ============================================================================

# Validate Docker availability when sourcing this file
if ! validate_docker_available; then
    log_error "Docker validation failed - some functions may not work"
fi

log_debug "Docker helpers v$DOCKER_HELPERS_VERSION loaded"