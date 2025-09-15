#!/usr/bin/env bats

# test/infrastructure/test-nestjs-cluster-integration.bats

load '../helpers/docker-helpers'
load '../helpers/nestjs-helpers'

@test "NestJS app deploys successfully on Docker Swarm cluster" {
    # Given: Functional Docker Swarm cluster
    init_swarm_cluster
    assert_swarm_node_count 1
    
    # When: Deploy NestJS application
    deploy_stack "scalable-nestjs" "docker-compose.test.yml"
    
    # Then: Service should be healthy and distributed
    wait_for_service_healthy "scalable-nestjs_app"
    assert_service_distributed "scalable-nestjs_app" 1
}