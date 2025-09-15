#!/usr/bin/env bats

load '../../helpers/docker-helpers'

# Helper function per garantire consistenza (SOLID: Single Responsibility)
get_test_stack_name() {
    echo "visibility-test"
}

# Setup persistente per questo specifico test file
setup_file() {
    export PERSIST_CLUSTER="true"
    # Non fare export qui - usa helper function
}

teardown_file() {
    # Cleanup solo alla fine di tutti i test del file
    if [[ "$PERSIST_CLUSTER" == "true" ]]; then
        cleanup_docker_environment
    fi
}

@test "INTEGRATION: Cluster + Service deployment end-to-end" {
    # Definizione locale della variabile (guaranteed scope)
    local TEST_STACK_NAME
    TEST_STACK_NAME=$(get_test_stack_name)
    
    # Given: Cluster inizializzato
    run init_swarm_cluster
    [ "$status" -eq 0 ]
    
    # When: Deploy servizio test
    run deploy_test_service "$TEST_STACK_NAME"
    [ "$status" -eq 0 ]
    
    # Then: Servizio visibile e funzionante
    run docker service ls --format "{{.Name}}"
    [[ "$output" =~ "$TEST_STACK_NAME" ]]
    
    run wait_for_service_ready "$TEST_STACK_NAME" 60
    [ "$status" -eq 0 ]
    
    # Verifica container attivi
    local container_count
    container_count=$(docker ps --filter "label=com.docker.swarm.service.name=$TEST_STACK_NAME" --format "{{.ID}}" | wc -l)
    [ "$container_count" -gt 0 ]
    
    echo "✅ SUCCESS: $container_count containers running for service $TEST_STACK_NAME" >&3
}

@test "INTEGRATION: Service scaling works correctly" {
    # Definizione locale consistente (DRY principle via helper)
    local TEST_STACK_NAME
    TEST_STACK_NAME=$(get_test_stack_name)
    
    # Given: Servizio già deployato dal test precedente
    local initial_replicas=1
    local target_replicas=3
    
    # When: Scale servizio
    run docker service scale "$TEST_STACK_NAME=$target_replicas"
    [ "$status" -eq 0 ]
    
    # Then: Replicas corrette
    run wait_for_service_scaled "$TEST_STACK_NAME" "$target_replicas" 60
    [ "$status" -eq 0 ]
    
    local container_count
    container_count=$(docker ps --filter "label=com.docker.swarm.service.name=$TEST_STACK_NAME" --format "{{.ID}}" | wc -l)
    [ "$container_count" -eq "$target_replicas" ]
    
    echo "✅ SUCCESS: Scaled to $container_count containers" >&3
}