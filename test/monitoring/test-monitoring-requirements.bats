#!/usr/bin/env bats

# Load helpers
load '../helpers/config'
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
    # Given: Stack monitoring integrato già attivo
    init_swarm_cluster
    
    # When: Verifichiamo che Prometheus sia attivo
    run docker service ls --filter name=monitoring_prometheus --quiet
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
    # Given: Stack monitoring integrato già attivo
    init_swarm_cluster
    
    # When: Verifichiamo che NGINX exporter sia attivo
    run docker service ls --filter name=monitoring_nginx-exporter --quiet
    [ "$status" -eq 0 ]
    
    # And: Attendo che i servizi siano pronti
    run wait_for_monitoring_services 120
    [ "$status" -eq 0 ]
    
    # Then: NGINX exporter deve esporre metriche HTTP
    run is_nginx_monitored
    [ "$status" -eq 0 ]
    
    # And: Le metriche devono includere request count
    run curl -s "${NGINX_EXPORTER_URL}/metrics"
    [[ "$output" =~ "nginx_http_requests_total" ]]
    
    echo "✅ SUCCESS: NGINX is being monitored" >&3
}

@test "REQUIREMENT: Grafana deve avere dashboard preconfigurate" {
    # Given: Stack monitoring integrato già attivo
    init_swarm_cluster
    
    # When: Verifichiamo che Grafana sia disponibile
    run docker service ls --filter name=monitoring_grafana --quiet
    [ "$status" -eq 0 ]
    
    # And: Attendo che i servizi siano pronti
    run wait_for_monitoring_services 120
    [ "$status" -eq 0 ]
    
    # Then: Accesso Grafana dashboard
    run curl -s -u "${GRAFANA_ADMIN_USER}:${GRAFANA_ADMIN_PASSWORD}" "${GRAFANA_URL}/api/search"
    [ "$status" -eq 0 ]
    
    # And: Deve esistere dashboard per Docker Swarm
    [[ "$output" =~ "Docker Swarm" ]] || [[ "$output" =~ "docker-swarm" ]]
    
    echo "✅ SUCCESS: Grafana dashboards are available" >&3
}

@test "REQUIREMENT: Sistema deve allertare su problemi critici" {
    # Given: Stack monitoring integrato già attivo
    init_swarm_cluster
    
    # When: Verifichiamo che Prometheus sia disponibile
    run docker service ls --filter name=monitoring_prometheus --quiet
    [ "$status" -eq 0 ]
    
    # And: Attendo che i servizi siano pronti
    run wait_for_monitoring_services 120
    [ "$status" -eq 0 ]
    
    # Then: Verifico configurazione alert rules
    run curl -s "${PROMETHEUS_URL}/api/v1/rules"
    [ "$status" -eq 0 ]
    
    # And: Devono esistere regole per servizi down
    [[ "$output" =~ ServiceDown ]] || [[ "$output" =~ service.*down ]]
    
    # And: Devono esistere regole per alto CPU usage
    [[ "$output" =~ HighCPUUsage ]] || [[ "$output" =~ cpu.*usage ]]
    
    echo "✅ SUCCESS: Alert rules are configured" >&3
}

@test "REQUIREMENT: Portainer deve fornire UI per gestione Swarm" {
    # Given: Stack monitoring integrato già attivo
    init_swarm_cluster
    
    # When: Verifichiamo che Portainer sia disponibile (se configurato)
    if docker service ls --filter name=monitoring_portainer --quiet | grep -q .; then
        # And: Attendo che i servizi siano pronti
        run wait_for_monitoring_services 120
        [ "$status" -eq 0 ]
        
        # Then: Accesso Portainer
        run curl -s "${PORTAINER_URL}/api/status"
        [ "$status" -eq 0 ]
        
        # And: Portainer deve essere accessibile
        [[ "$output" =~ "\"Version\"" ]]
        
        echo "✅ SUCCESS: Portainer UI is accessible" >&3
    else
        echo "⚠️  SKIPPED: Portainer not configured in integrated monitoring stack" >&3
        skip "Portainer not available in current configuration"
    fi
}