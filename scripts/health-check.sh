#!/bin/bash

# =============================================================================
# 🏥 COMPREHENSIVE HEALTH CHECK SCRIPT
# =============================================================================
# 
# Verifica lo stato di salute di tutti i sistemi:
# - NestJS Application
# - Infrastructure (Docker Swarm)
# - Monitoring Stack (Prometheus, Grafana, Portainer, Node Exporter)
#
# Usage:
#   ./scripts/health-check.sh [--verbose] [--json] [--component=<component>]
#
# Components: nestjs, infrastructure, monitoring, all (default)
# =============================================================================

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_PREFIX="🏥 HEALTH CHECK"
TIMEOUT=10
VERBOSE=false
JSON_OUTPUT=false
COMPONENT="all"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

log() {
    if [[ "$JSON_OUTPUT" == "false" ]]; then
        echo -e "${BLUE}${LOG_PREFIX}${NC} $1"
    fi
}

log_verbose() {
    if [[ "$VERBOSE" == "true" && "$JSON_OUTPUT" == "false" ]]; then
        echo -e "  ${BLUE}→${NC} $1"
    fi
}

log_success() {
    if [[ "$JSON_OUTPUT" == "false" ]]; then
        echo -e "  ${GREEN}✅${NC} $1"
    fi
}

log_warning() {
    if [[ "$JSON_OUTPUT" == "false" ]]; then
        echo -e "  ${YELLOW}⚠️${NC} $1"
    fi
}

log_error() {
    if [[ "$JSON_OUTPUT" == "false" ]]; then
        echo -e "  ${RED}❌${NC} $1"
    fi
}

# Test HTTP endpoint with timeout
test_http_endpoint() {
    local url="$1"
    local name="$2"
    local expected_status="${3:-200}"
    
    log_verbose "Testing $name at $url..."
    
    if response=$(curl -s -w "%{http_code}" --max-time "$TIMEOUT" "$url" 2>/dev/null); then
        http_code="${response: -3}"
        if [[ "$http_code" == "$expected_status" ]]; then
            log_success "$name is healthy (HTTP $http_code)"
            return 0
        else
            log_error "$name returned HTTP $http_code (expected $expected_status)"
            return 1
        fi
    else
        log_error "$name is unreachable"
        return 1
    fi
}

# Test command execution
test_command() {
    local cmd="$1"
    local name="$2"
    
    log_verbose "Testing command: $cmd"
    
    if eval "$cmd" >/dev/null 2>&1; then
        log_success "$name is available"
        return 0
    else
        log_error "$name is not available"
        return 1
    fi
}

# =============================================================================
# NESTJS APPLICATION HEALTH CHECKS
# =============================================================================

check_nestjs_health() {
    local status=0
    log "🚀 Checking NestJS Application Health..."
    
    # Check if NestJS is running (assuming default port 3000)
    local nestjs_url="http://localhost:3001"  # Assuming NestJS runs on 3001 to avoid conflict with Grafana
    
    # Basic health endpoint
    if test_http_endpoint "$nestjs_url/health" "NestJS Basic Health"; then
        # Check cluster health endpoint
        if test_http_endpoint "$nestjs_url/health/cluster" "NestJS Cluster Health"; then
            log_success "NestJS application is fully healthy"
        else
            log_warning "NestJS basic health OK, but cluster health unavailable"
            status=1
        fi
    else
        # Try different common ports
        for port in 3000 3001 8000 8080; do
            log_verbose "Trying NestJS on port $port..."
            if test_http_endpoint "http://localhost:$port/health" "NestJS (port $port)"; then
                log_success "Found NestJS running on port $port"
                return 0
            fi
        done
        log_error "NestJS application not found on common ports"
        status=1
    fi
    
    return $status
}

# =============================================================================
# INFRASTRUCTURE HEALTH CHECKS
# =============================================================================

check_infrastructure_health() {
    local status=0
    log "🏗️ Checking Infrastructure Health..."
    
    # Check Docker daemon
    if test_command "docker info" "Docker Daemon"; then
        log_success "Docker is running"
        
        # Check Docker Swarm
        if docker info --format '{{.Swarm.LocalNodeState}}' 2>/dev/null | grep -q "active"; then
            log_success "Docker Swarm is active"
            
            # Check Swarm nodes
            local node_count=$(docker node ls --format "{{.Status}}" 2>/dev/null | grep -c "Ready" || echo "0")
            log_success "Docker Swarm has $node_count ready node(s)"
            
            # Check running services
            local service_count=$(docker service ls --quiet 2>/dev/null | wc -l)
            if [[ "$service_count" -gt 0 ]]; then
                log_success "Docker Swarm has $service_count active service(s)"
            else
                log_warning "No Docker Swarm services are running"
            fi
        else
            log_warning "Docker Swarm is not active"
            status=1
        fi
    else
        log_error "Docker is not available"
        status=1
    fi
    
    return $status
}

# =============================================================================
# MONITORING STACK HEALTH CHECKS
# =============================================================================

check_monitoring_health() {
    local status=0
    log "📊 Checking Monitoring Stack Health..."
    
    # Define monitoring services
    local services=(
        "prometheus:9090:/-/healthy:Prometheus"
        "grafana:3000:/api/health:Grafana"  
        "portainer:9000:/api/status:Portainer"
        "node-exporter:9100:/metrics:Node Exporter"
    )
    
    local healthy_services=0
    local total_services=${#services[@]}
    
    for service_def in "${services[@]}"; do
        IFS=':' read -r host port path name <<< "$service_def"
        local url="http://localhost:$port$path"
        
        if test_http_endpoint "$url" "$name"; then
            ((healthy_services++))
        else
            status=1
        fi
    done
    
    log "Monitoring Stack Status: $healthy_services/$total_services services healthy"
    
    # Additional monitoring-specific checks
    if [[ "$healthy_services" -gt 0 ]]; then
        # Check Prometheus targets if Prometheus is up
        if curl -s "http://localhost:9090/api/v1/targets" >/dev/null 2>&1; then
            local targets_up=$(curl -s "http://localhost:9090/api/v1/targets" | grep -c '"health":"up"' || echo "0")
            log_success "Prometheus has $targets_up targets in 'up' state"
        fi
    fi
    
    return $status
}

# =============================================================================
# COMPREHENSIVE HEALTH CHECK
# =============================================================================

check_all_health() {
    local overall_status=0
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    log "🩺 Running Comprehensive Health Check at $timestamp"
    log "=============================================="
    
    # Initialize results for JSON output
    local nestjs_status="unknown"
    local infrastructure_status="unknown" 
    local monitoring_status="unknown"
    
    # Run component checks based on selection
    case "$COMPONENT" in
        "nestjs")
            if check_nestjs_health; then
                nestjs_status="healthy"
            else
                nestjs_status="unhealthy"
                overall_status=1
            fi
            ;;
        "infrastructure") 
            if check_infrastructure_health; then
                infrastructure_status="healthy"
            else
                infrastructure_status="unhealthy"
                overall_status=1
            fi
            ;;
        "monitoring")
            if check_monitoring_health; then
                monitoring_status="healthy" 
            else
                monitoring_status="unhealthy"
                overall_status=1
            fi
            ;;
        "all"|*)
            # Check NestJS
            if check_nestjs_health; then
                nestjs_status="healthy"
            else
                nestjs_status="unhealthy"
                overall_status=1
            fi
            
            echo ""  # Spacing between sections
            
            # Check Infrastructure
            if check_infrastructure_health; then
                infrastructure_status="healthy"
            else
                infrastructure_status="unhealthy" 
                overall_status=1
            fi
            
            echo ""  # Spacing between sections
            
            # Check Monitoring
            if check_monitoring_health; then
                monitoring_status="healthy"
            else
                monitoring_status="unhealthy"
                overall_status=1
            fi
            ;;
    esac
    
    # Output results
    if [[ "$JSON_OUTPUT" == "true" ]]; then
        cat << EOF
{
  "timestamp": "$timestamp",
  "overall_status": $([ $overall_status -eq 0 ] && echo '"healthy"' || echo '"unhealthy"'),
  "components": {
    "nestjs": "$nestjs_status",
    "infrastructure": "$infrastructure_status", 
    "monitoring": "$monitoring_status"
  }
}
EOF
    else
        echo ""
        log "=============================================="
        if [[ $overall_status -eq 0 ]]; then
            log_success "🎉 ALL SYSTEMS HEALTHY!"
        else
            log_error "⚠️ SOME SYSTEMS NEED ATTENTION"
        fi
        log "Health check completed at $(date)"
    fi
    
    return $overall_status
}

# =============================================================================
# ARGUMENT PARSING
# =============================================================================

while [[ $# -gt 0 ]]; do
    case $1 in
        --verbose|-v)
            VERBOSE=true
            shift
            ;;
        --json|-j)
            JSON_OUTPUT=true
            shift
            ;;
        --component=*)
            COMPONENT="${1#*=}"
            shift
            ;;
        --timeout=*)
            TIMEOUT="${1#*=}"
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --verbose, -v        Enable verbose output"
            echo "  --json, -j          Output in JSON format"
            echo "  --component=NAME     Check specific component (nestjs|infrastructure|monitoring|all)"
            echo "  --timeout=SECONDS    HTTP request timeout (default: 10)"
            echo "  --help, -h          Show this help message"
            echo ""
            echo "Components:"
            echo "  nestjs              NestJS application health"
            echo "  infrastructure      Docker and Swarm health"  
            echo "  monitoring          Monitoring stack health"
            echo "  all                 All components (default)"
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# =============================================================================
# MAIN EXECUTION
# =============================================================================

main() {
    check_all_health
    exit $?
}

# Run main function
main "$@"
