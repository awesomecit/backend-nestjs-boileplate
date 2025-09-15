# Enhanced docker-helpers.bash - Seguendo SOLID principles

# ==========================================
# CONFIGURATION MANAGEMENT (Single Responsibility)
# ==========================================

# Helper per configurazione test (SRP: gestisce solo configurazione)
get_test_stack_name() {
    echo "${TEST_STACK_NAME:-visibility-test}"
}

get_test_image_name() {
    echo "${TEST_IMAGE:-nginx:alpine}"
}

get_test_replicas() {
    echo "${TEST_REPLICAS:-1}"
}

# ==========================================
# SERVICE DEPLOYMENT (Open/Closed Principle)
# ==========================================

# Base deployment function (aperta per estensione)
deploy_test_service() {
    local stack_name="$1"
    local image_name="${2:-$(get_test_image_name)}"
    local replicas="${3:-$(get_test_replicas)}"
    
    # Validazione input (Liskov Substitution)
    if [[ -z "$stack_name" ]]; then
        echo "ERROR: Stack name required" >&2
        return 1
    fi
    
    # Verifica se servizio esiste già
    if docker service ls --filter "name=$stack_name" --format "{{.Name}}" | grep -q "^$stack_name$"; then
        echo "Service $stack_name already exists, skipping creation" >&2
        return 0
    fi
    
    # Deploy con parametri configurabili
    docker service create \
        --name "$stack_name" \
        --replicas "$replicas" \
        --publish 8080:80 \
        "$image_name" > /dev/null 2>&1
}

# Specializzazione per test specifici (Open/Closed)
deploy_nginx_test_service() {
    local stack_name="$1"
    deploy_test_service "$stack_name" "nginx:alpine" "1"
}

deploy_scaled_test_service() {
    local stack_name="$1"
    local replicas="$2"
    deploy_test_service "$stack_name" "nginx:alpine" "$replicas"
}

# ==========================================
# SERVICE MONITORING (Interface Segregation)
# ==========================================

# Interface per service readiness
wait_for_service_ready() {
    local service_name="$1"
    local timeout="${2:-30}"
    local interval="${3:-2}"
    
    for ((i=0; i<timeout; i+=interval)); do
        if docker service ps "$service_name" --format "{{.CurrentState}}" | grep -q "Running"; then
            return 0
        fi
        sleep "$interval"
    done
    
    echo "ERROR: Service $service_name not ready within ${timeout}s" >&2
    return 1
}

# Interface per service scaling
wait_for_service_scaled() {
    local service_name="$1"
    local expected_replicas="$2"
    local timeout="${3:-60}"
    local interval="${4:-3}"
    
    for ((i=0; i<timeout; i+=interval)); do
        local current_replicas
        current_replicas=$(docker service ps "$service_name" --format "{{.CurrentState}}" | grep -c "Running" || echo "0")
        
        if [[ "$current_replicas" -eq "$expected_replicas" ]]; then
            echo "Service scaled to $current_replicas replicas"
            return 0
        fi
        
        sleep "$interval"
    done
    
    echo "ERROR: Service $service_name not scaled to $expected_replicas within ${timeout}s" >&2
    return 1
}

# ==========================================
# CLUSTER MANAGEMENT (Dependency Inversion)
# ==========================================

# Astratto - dipende dall'interfaccia, non dall'implementazione
init_swarm_cluster() {
    if ! docker info | grep -q "Swarm: active"; then
        docker swarm init --advertise-addr 127.0.0.1 > /dev/null 2>&1
        echo "Swarm cluster initialized"
    else
        echo "Swarm cluster already active"
    fi
}

# Cleanup orchestrato e safe
cleanup_docker_environment() {
    echo "🧹 Cleaning up test environment..."
    
    # Remove services (se esistono)
    docker service ls --format "{{.Name}}" | grep -E "(visibility|test)" | while read -r service; do
        echo "Removing service: $service"
        docker service rm "$service" > /dev/null 2>&1 || true
    done
    
    # Leave swarm if we're in one (solo per test)
    if docker info | grep -q "Swarm: active"; then
        docker swarm leave --force > /dev/null 2>&1 || true
        echo "Left swarm cluster"
    fi
    
    echo "✅ Cleanup completed"
}

# ==========================================
# VALIDATION UTILITIES (Single Responsibility)
# ==========================================

# Validazione specifica per service existence
service_exists() {
    local service_name="$1"
    docker service ls --format "{{.Name}}" | grep -q "^${service_name}$"
}

# Validazione per service health
service_is_healthy() {
    local service_name="$1"
    local running_count
    running_count=$(docker service ps "$service_name" --format "{{.CurrentState}}" | grep -c "Running" || echo "0")
    [[ "$running_count" -gt 0 ]]
}