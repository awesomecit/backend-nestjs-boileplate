#!/bin/bash

set -euo pipefail

echo "🧹 Cleaning up monitoring infrastructure..."

cleanup_stack() {
    local stack_name="${1:-monitoring}"
    
    echo "🗑️  Removing stack: $stack_name"
    docker stack rm "$stack_name" 2>/dev/null || true
    
    # Attendi rimozione completa
    echo "⏳ Waiting for complete removal..."
    local timeout=60
    local start_time=$(date +%s)
    
    while docker stack ls --format "{{.Name}}" | grep -q "^${stack_name}$"; do
        local current_time=$(date +%s)
        local elapsed=$((current_time - start_time))
        
        if [ "$elapsed" -gt "$timeout" ]; then
            echo "⚠️  Timeout waiting for stack removal"
            break
        fi
        
        sleep 2
    done
    
    echo "✅ Stack removed"
}

# Cleanup networks se rimangono orfane
cleanup_networks() {
    echo "🔌 Cleaning up orphaned networks..."
    docker network prune -f >/dev/null 2>&1 || true
}

# Cleanup volumes se richiesto
cleanup_volumes() {
    if [[ "${1:-}" == "--volumes" ]]; then
        echo "💾 Cleaning up volumes..."
        docker volume prune -f >/dev/null 2>&1 || true
    fi
}

main() {
    local stack_name="${1:-monitoring}"
    
    cleanup_stack "$stack_name"
    cleanup_networks
    cleanup_volumes "$2"
    
    echo "✅ Cleanup complete!"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi