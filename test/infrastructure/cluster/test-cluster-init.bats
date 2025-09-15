#!/usr/bin/env bats

# test-cluster-init.bats
# Test Docker Swarm cluster initialization

load '../../helpers/docker-helpers'

setup() {
    # Cleanup before each test
    cleanup_docker_environment >/dev/null 2>&1 || true
}

teardown() {
    # Cleanup after each test
    cleanup_docker_environment >/dev/null 2>&1 || true
}

@test "Docker is available and running" {
    # Given: System with Docker installed
    run validate_docker_available
    [ "$status" -eq 0 ]
}

@test "Docker Swarm cluster can be initialized" {
    # Given: Clean Docker environment
    run is_swarm_active
    [ "$status" -eq 1 ]  # Should NOT be active initially
    
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

@test "Swarm cluster has manager node" {
    # Given: Initialized swarm cluster
    init_swarm_cluster
    
    # When: Check node roles
    run docker node ls --format "{{.ManagerStatus}}"
    [ "$status" -eq 0 ]
    
    # Then: Should have at least one manager
    [[ "$output" == *"Leader"* ]]
}

@test "Swarm cluster can generate join tokens" {
    # Given: Active swarm cluster
    init_swarm_cluster
    
    # When: Get worker join token
    run docker swarm join-token worker -q
    [ "$status" -eq 0 ]
    
    # Then: Token should be valid format
    [[ "$output" =~ ^SWMTKN-.*$ ]]
}

@test "Swarm cluster survives leave and rejoin" {
    # Given: Active swarm cluster
    init_swarm_cluster
    
    # When: Leave and rejoin cluster
    run leave_swarm_cluster
    [ "$status" -eq 0 ]
    
    run init_swarm_cluster
    [ "$status" -eq 0 ]
    
    # Then: Cluster should be functional again
    run is_swarm_active
    [ "$status" -eq 0 ]
}