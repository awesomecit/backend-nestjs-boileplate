#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
COMPOSE_FILE="$PROJECT_ROOT/deployment/monitoring/prometheus/docker-compose.monitoring.yml"

echo "🚀 Deploying monitoring infrastructure..."

# =============================================================================
# PREREQUISITI
# =============================================================================

check_prerequisites() {
    echo "🔍 Checking prerequisites..."
    
    # Docker disponibile
    if ! command -v docker &> /dev/null; then
        echo "❌ Docker non installato"
        exit 1
    fi
    
    # Docker running
    if ! docker info >/dev/null 2>&1; then
        echo "❌ Docker daemon non running"
        exit 1
    fi
    
    # Swarm attivo
    if ! docker info 2>/dev/null | grep -q "Swarm: active"; then
        echo "⚠️  Docker Swarm non attivo. Inizializzando..."
        docker swarm init --advertise-addr $(docker info --format '{{.Swarm.NodeAddr}}' 2>/dev/null || hostname -I | awk '{print $1}')
    fi
    
    # File compose esiste
    if [ ! -f "$COMPOSE_FILE" ]; then
        echo "❌ Compose file non trovato: $COMPOSE_FILE"
        exit 1
    fi
    
    echo "✅ Prerequisites OK"
}

# =============================================================================
# DEPLOYMENT
# =============================================================================

deploy_stack() {
    local stack_name="${1:-monitoring}"
    
    echo "📦 Deploying stack: $stack_name"
    echo "📄 Using compose file: $COMPOSE_FILE"
    
    # Navigate to monitoring directory per relative paths
    cd "$PROJECT_ROOT/deployment/monitoring"
    
    # Deploy stack
    if docker stack deploy -c docker-compose.monitoring.yml "$stack_name"; then
        echo "✅ Stack deployed successfully"
        return 0
    else
        echo "❌ Failed to deploy stack"
        return 1
    fi
}

# =============================================================================
# WAIT FOR SERVICES
# =============================================================================

wait_for_services() {
    local timeout="${1:-180}"
    local start_time=$(date +%s)
    
    echo "⏳ Waiting for services to be ready (timeout: ${timeout}s)..."
    
    local services=(
        "prometheus:9090:/api/v1/targets"
        "grafana:3000:/api/health"
        "portainer:9000:/api/status"
        "node-exporter:9100:/metrics"
    )
    
    while true; do
        local ready_count=0
        
        for service_def in "${services[@]}"; do
            local name="${service_def%%:*}"
            local port_path="${service_def#*:}"
            local port="${port_path%%:*}"
            local path="${port_path#*:}"
            local url="http://localhost:${port}${path}"
            
            echo "🔍 Testing $name at $url..."
            if curl -s "$url" >/dev/null 2>&1; then
                echo "✅ $name ready"
                ready_count=$((ready_count + 1))
            else
                echo "⏳ $name not ready yet..."
            fi
        done
        
        if [ "$ready_count" -eq "${#services[@]}" ]; then
            echo "🎉 All services ready!"
            return 0
        fi
        
        # Timeout check
        local current_time=$(date +%s)
        local elapsed=$((current_time - start_time))
        
        if [ "$elapsed" -gt "$timeout" ]; then
            echo "❌ Timeout waiting for services"
            echo "📊 Ready: $ready_count/${#services[@]}"
            return 1
        fi
        
        echo "📊 Services ready: $ready_count/${#services[@]} (${elapsed}s elapsed)"
        sleep 10
    done
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================

main() {
    local stack_name="${1:-monitoring}"
    
    echo "🏗️  Starting monitoring infrastructure deployment"
    echo "================================================"
    
    check_prerequisites
    deploy_stack "$stack_name"
    wait_for_services 180
    
    echo ""
    echo "🎯 Monitoring Infrastructure Ready!"
    echo "=================================="
    echo "🔗 Access URLs:"
    echo "   📊 Grafana:        http://localhost:3000 (admin/admin123)"
    echo "   📈 Prometheus:     http://localhost:9090"
    echo "   🐳 Portainer:      http://localhost:9000" 
    echo "   📡 Node Exporter:  http://localhost:9100/metrics"
    echo ""
    echo "✅ Ready for testing!"
}

# Esegui se chiamato direttamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi