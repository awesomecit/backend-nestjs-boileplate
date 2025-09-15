#!/usr/bin/env bats

# test/helpers/test-docker-helpers.bats
# Tests for docker-helpers.bash functions

load 'docker-helpers'

setup() {
    # Cleanup before each test
    cleanup_docker_environment
}

teardown() {
    # Cleanup after each test
    cleanup_docker_environment
}

@test "get_primary_ip returns valid IP address" {
    # Given: System with network interface
    # When: Get primary IP
    run get_primary_ip
    [ "$status" -eq 0 ]
    
    # Then: Should return valid IP format
    [[ "$output" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]
}

@test "init_swarm_cluster creates functional cluster" {
    # Given: Clean Docker environment
    run is_swarm_active
    [ "$status" -eq 1 ]
    
    # When: Initialize swarm cluster
    run init_swarm_cluster
    [ "$status" -eq 0 ]
    
    # Then: Swarm should be active
    run is_swarm_active
    [ "$status" -eq 0 ]
    
    # And: Should be able to list nodes
    run docker node ls
    [ "$status" -eq 0 ]
}

@test "deploy_stack deploys and waits for readiness" {
    # Given: Active swarm cluster
    init_swarm_cluster
    
    # When: Deploy test stack
    run deploy_stack "test-app" "test/fixtures/docker-compose.test.yml"
    [ "$status" -eq 0 ]
    
    # Then: Stack should be running
    run docker stack ls --format "{{.Name}}"
    [[ "$output" == *"test-app"* ]]
    
    # And: Services should be ready
    run is_service_ready "test-app_web"
    [ "$status" -eq 0 ]
}