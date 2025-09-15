# test/helpers/nestjs-helpers.bash

wait_for_service_ready() {
    local service_name=$1
    local timeout=${2:-30}
    local count=0
    
    while [ $count -lt $timeout ]; do
        if docker service ls --filter name=$service_name --format "{{.Replicas}}" | grep -q "3/3"; then
            return 0
        fi
        sleep 1
        ((count++))
    done
    
    return 1
}

check_app_health() {
    local url=${1:-"http://localhost:3000/health"}
    curl -f "$url" >/dev/null 2>&1
}

get_service_nodes() {
    local service_name=$1
    docker service ps $service_name --format "{{.Node}}" | sort | uniq
}