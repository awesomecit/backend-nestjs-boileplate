#!/usr/bin/env bats

# Load helpers
load '../helpers/monitoring-helpers'

# =============================================================================
# SETUP & TEARDOWN
# =============================================================================

setup() {
    export TEST_STACK_NAME="test-monitoring-$(random_string 8)"
    export COMPOSE_FILE="deployment/monitoring/docker-compose.monitoring.yml"
    
    echo "🧪 Test setup: $TEST_STACK_NAME" >&3
}

teardown() {
    echo "🧹 Test cleanup: $TEST_STACK_NAME" >&3
    cleanup_monitoring_stack "$TEST_STACK_NAME" || true
}

# =============================================================================
# RED PHASE: QUESTI TEST DEVONO FALLIRE INIZIALMENTE
# =============================================================================

@test "REQUIREMENT: Docker Swarm cluster deve essere monitorabile via Prometheus" {
    # Given: Un cluster Swarm attivo
    init_swarm_cluster
    
    # When: Deploy monitoring stack
    run deploy_monitoring_stack "$TEST_STACK_NAME" "$COMPOSE_FILE"
    [ "$status" -eq 0 ]
    
    # And: Attendo che i servizi siano pronti
    run wait_for_monitoring_services 120
    [ "$status" -eq 0 ]
    
    # Then: Prometheus deve raccogliere metriche dai nodi Swarm
    run is_swarm_monitored
    [ "$status" -eq 0 ]
    
    echo "✅ SUCCESS: Swarm cluster is being monitored" >&3
}

@test "REQUIREMENT: NGINX deve essere monitorato con metriche HTTP" {
    # Given: Cluster con stack monitoring
    init_swarm_cluster
    deploy_monitoring_stack "$TEST_STACK_NAME" "$COMPOSE_FILE"
    wait_for_monitoring_services 120
    
    # When: Verifico monitoring NGINX
    run is_nginx_monitored
    
    # Then: NGINX exporter deve esporre metriche HTTP
    [ "$status" -eq 0 ]
    
    # And: Le metriche devono includere request count
    run curl -s http://localhost:9113/metrics
    [[ "$output" =~ "nginx_http_requests_total" ]]
    
    echo "✅ SUCCESS: NGINX is being monitored" >&3
}

@test "REQUIREMENT: Grafana deve avere dashboard preconfigurate" {
    # Given: Stack monitoring deployato
    init_swarm_cluster
    deploy_monitoring_stack "$TEST_STACK_NAME" "$COMPOSE_FILE"
    wait_for_monitoring_services 120
    
    # When: Accesso Grafana dashboard
    run curl -s -u admin:admin123 http://localhost:3000/api/dashboards/search
    [ "$status" -eq 0 ]
    
    # Then: Deve esistere dashboard per Docker Swarm
    [[ "$output" =~ "Docker Swarm" ]] || [[ "$output" =~ "docker-swarm" ]]
    
    echo "✅ SUCCESS: Grafana dashboards are available" >&3
}

@test "REQUIREMENT: Sistema deve allertare su problemi critici" {
    # Given: Stack monitoring attivo
    init_swarm_cluster
    deploy_monitoring_stack "$TEST_STACK_NAME" "$COMPOSE_FILE"
    wait_for_monitoring_services 120
    
    # When: Verifico configurazione alert rules
    run curl -s http://localhost:9090/api/v1/rules
    [ "$status" -eq 0 ]
    
    # Then: Devono esistere regole per servizi down
    [[ "$output" =~ "ServiceDown" ]] || [[ "$output" =~ "service.*down" ]]
    
    # And: Devono esistere regole per alto CPU usage
    [[ "$output" =~ "HighCPUUsage" ]] || [[ "$output" =~ "cpu.*usage" ]]
    
    echo "✅ SUCCESS: Alert rules are configured" >&3
}

@test "REQUIREMENT: Portainer deve fornire UI per gestione Swarm" {
    # Given: Stack monitoring deployato
    init_swarm_cluster  
    deploy_monitoring_stack "$TEST_STACK_NAME" "$COMPOSE_FILE"
    wait_for_monitoring_services 120
    
    # When: Accesso Portainer
    run curl -s http://localhost:9000/api/status
    [ "$status" -eq 0 ]
    
    # Then: Portainer deve essere accessibile
    [[ "$output" =~ "\"Version\"" ]]
    
    echo "✅ SUCCESS: Portainer UI is accessible" >&3
}