# File: test/helpers/service-helpers.bash

# Deploy servizio test semplice
deploy_test_service() {
    local service_name="$1"
    local image="${2:-nginx:alpine}"
    local replicas="${3:-1}"
    
    docker service create \
        --name "$service_name" \
        --replicas "$replicas" \
        --publish "8080:80" \
        --label "test=true" \
        "$image" >/dev/null 2>&1
}

# Attendi scaling completo
wait_for_service_scaled() {
    local service_name="$1"
    local expected_replicas="$2"
    local timeout="${3:-120}"
    
    local start_time=$(date +%s)
    
    while true; do
        local current_replicas
        current_replicas=$(docker service ls --filter "name=$service_name" --format "{{.Replicas}}" | cut -d'/' -f1)
        
        if [[ "$current_replicas" -eq "$expected_replicas" ]]; then
            return 0
        fi
        
        local elapsed=$(($(date +%s) - start_time))
        if [[ "$elapsed" -gt "$timeout" ]]; then
            return 1
        fi
        
        sleep 2
    done
}

# Verifica servizio healthy
verify_service_healthy() {
    local service_name="$1"
    local endpoint="${2:-http://localhost:8080}"
    
    # Test connettività
    curl -s -f "$endpoint" >/dev/null
}