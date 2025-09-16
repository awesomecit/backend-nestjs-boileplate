#!/bin/bash

# Source gli helper esistenti
source "$(dirname "${BASH_SOURCE[0]}")/docker-helpers.bash"

# =============================================================================
# MONITORING HEALTH CHECKS
# =============================================================================

# Verifica che Prometheus sia accessibile e raccolga metriche
is_prometheus_collecting() {
    local prometheus_url="${1:-http://localhost:9090}"
    
    # Verifica che Prometheus risponda
    if ! curl -s "${prometheus_url}/api/v1/query?query=up" >/dev/null 2>&1; then
        return 1
    fi
    
    # Verifica che abbia almeno un target UP
    local response
    response=$(curl -s "${prometheus_url}/api/v1/targets")
    echo "$response" | grep -q '"health":"up"'
}

# Verifica che Grafana sia configurato con datasource
is_grafana_configured() {
    local grafana_url="${1:-http://localhost:3000}"
    local user="${2:-admin}"
    local pass="${3:-admin123}"
    
    # Test connessione
    if ! curl -s -u "$user:$pass" "${grafana_url}/api/health" >/dev/null 2>&1; then
        return 1
    fi
    
    # Verifica datasource Prometheus configurato
    curl -s -u "$user:$pass" "${grafana_url}/api/datasources" | grep -q "Prometheus"
}

# Verifica che NGINX exporter stia esponendo metriche
is_nginx_monitored() {
    local nginx_exporter_url="${1:-http://localhost:9113}"
    
    # Verifica che exporter risponda
    if ! curl -s "${nginx_exporter_url}/metrics" >/dev/null 2>&1; then
        return 1
    fi
    
    # Verifica che ci siano metriche nginx specifiche
    curl -s "${nginx_exporter_url}/metrics" | grep -q "nginx_http_requests_total"
}

# Verifica che il cluster Docker Swarm sia monitorato
is_swarm_monitored() {
    local prometheus_url="${1:-http://localhost:9090}"
    
    # Query per verificare che Prometheus veda i nodi del cluster
    local response
    response=$(curl -s "${prometheus_url}/api/v1/query?query=node_uname_info")
    
    # Verifica che ci siano metriche dei nodi
    echo "$response" | grep -q '"status":"success"' && \
    echo "$response" | grep -q '"result":\[' && \
    ! echo "$response" | grep -q '"result":\[\]'
}

# =============================================================================
# DEPLOYMENT HELPERS
# =============================================================================

# Deploy stack monitoring con retry logic
deploy_monitoring_stack() {
    local stack_name="${1:-monitoring}"
    local compose_file="${2:-deployment/monitoring/docker-compose.monitoring.yml}"
    local max_retries="${3:-3}"
    
    echo "Deploying monitoring stack: $stack_name"
    
    for i in $(seq 1 $max_retries); do
        if docker stack deploy -c "$compose_file" "$stack_name"; then
            echo "Stack deployed successfully on attempt $i"
            return 0
        fi
        echo "Deploy attempt $i failed, retrying..."
        sleep 5
    done
    
    echo "Failed to deploy stack after $max_retries attempts"
    return 1
}

# Rimuovi stack con cleanup completo
cleanup_monitoring_stack() {
    local stack_name="${1:-monitoring}"
    
    echo "Removing monitoring stack: $stack_name"
    docker stack rm "$stack_name" 2>/dev/null || true
    
    # Attendi rimozione completa con timeout
    local timeout=60
    local start_time=$(date +%s)
    
    while docker stack ls --format "{{.Name}}" | grep -q "^${stack_name}$"; do
        local current_time=$(date +%s)
        local elapsed=$((current_time - start_time))
        
        if [ "$elapsed" -gt "$timeout" ]; then
            echo "Warning: Timeout waiting for stack removal"
            break
        fi
        
        sleep 2
    done
    
    echo "Stack $stack_name removed"
}

# Attendi che tutti i servizi siano pronti
wait_for_monitoring_services() {
    local timeout="${1:-180}"
    local start_time=$(date +%s)
    
    echo "Waiting for monitoring services to be ready (timeout: ${timeout}s)..."
    
    local services=(
        "prometheus:is_prometheus_collecting"
        "grafana:is_grafana_configured" 
        "nginx-exporter:is_nginx_monitored"
        "swarm-monitoring:is_swarm_monitored"
    )
    
    while true; do
        local ready_count=0
        local total_services=${#services[@]}
        
        for service_check in "${services[@]}"; do
            local service_name="${service_check%%:*}"
            local check_function="${service_check##*:}"
            
            if $check_function 2>/dev/null; then
                ((ready_count++))
                echo "✅ $service_name ready"
            else
                echo "⏳ $service_name not ready yet"
            fi
        done
        
        if [ "$ready_count" -eq "$total_services" ]; then
            echo "🎉 All monitoring services are ready!"
            return 0
        fi
        
        # Timeout check
        local current_time=$(date +%s)
        local elapsed=$((current_time - start_time))
        
        if [ "$elapsed" -gt "$timeout" ]; then
            echo "❌ Timeout waiting for services. Ready: $ready_count/$total_services"
            return 1
        fi
        
        echo "📊 Services ready: $ready_count/$total_services (${elapsed}s elapsed)"
        sleep 10
    done
}