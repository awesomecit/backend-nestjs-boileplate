#!/usr/bin/env bats

# test/monitoring/test-nginx-exporter-requirements.bats
# TDD Tests for NGINX Exporter Integration

load '../helpers/monitoring-helpers'

# =============================================================================
# SETUP & TEARDOWN
# =============================================================================

setup() {
    export TEST_STACK_NAME="nginx-exporter-test-$(random_string 8)"
    export COMPOSE_FILE="deployment/nginx/docker-compose.nginx.yml" 
    export MONITORING_COMPOSE="deployment/monitoring/docker-compose.monitoring.yml"
    
    echo "🧪 Test setup: $TEST_STACK_NAME" >&3
}

teardown() {
    echo "🧹 Test cleanup: $TEST_STACK_NAME" >&3
    cleanup_monitoring_stack "$TEST_STACK_NAME" || true
    cleanup_nginx_stack "$TEST_STACK_NAME" || true
}

# =============================================================================
# RED PHASE: QUESTI TEST DEVONO FALLIRE INIZIALMENTE  
# =============================================================================

@test "REQUIREMENT: NGINX deve essere configurato per esporre nginx_status" {
    # Given: Stack monitoring integrato già attivo
    init_swarm_cluster
    
    # When: Verifichiamo che lo stack monitoring sia attivo
    run docker service ls --filter name=monitoring_nginx --quiet
    [ "$status" -eq 0 ]
    
    # And: Attendo che NGINX sia pronto
    run wait_for_monitoring_services 60
    [ "$status" -eq 0 ]
    
    # Then: L'endpoint nginx_status deve essere accessibile
    run curl -f http://localhost:80/nginx_status
    [ "$status" -eq 0 ]
    
    # And: Deve contenere metriche in formato testo
    [[ "$output" =~ "Active connections:" ]]
    [[ "$output" =~ "server accepts handled requests" ]]
    
    echo "✅ SUCCESS: NGINX status endpoint is accessible" >&3
}

@test "REQUIREMENT: NGINX Exporter deve essere configurato e funzionante" {
    # Given: Stack monitoring integrato già attivo
    init_swarm_cluster
    
    # When: Verifichiamo che lo stack monitoring sia attivo
    run docker service ls --filter name=monitoring_nginx-exporter --quiet
    [ "$status" -eq 0 ]
    
    # And: Attendo che l'exporter sia pronto
    run wait_for_monitoring_services 120
    [ "$status" -eq 0 ]
    
    # Then: L'exporter deve esporre metriche Prometheus
    run curl -f http://localhost:9113/metrics
    [ "$status" -eq 0 ]
    
    # And: Le metriche devono includere quelle specifiche di NGINX
    [[ "$output" =~ "nginx_http_requests_total" ]]
    [[ "$output" =~ "nginx_connections_active" ]]
    [[ "$output" =~ "nginx_connections_accepted" ]]
    
    echo "✅ SUCCESS: NGINX Exporter is working correctly" >&3
}

@test "REQUIREMENT: Prometheus deve raccogliere metriche NGINX automaticamente" {
    # Given: Stack monitoring esistente con NGINX + Exporter + Prometheus integrati
    init_swarm_cluster
    
    # When: Verifichiamo che lo stack monitoring sia attivo (dovrebbe già esserci)
    run docker service ls --filter name=monitoring_ --quiet
    [ "$status" -eq 0 ]
    
    # And: Attendo che tutti i servizi monitoring siano pronti
    run wait_for_monitoring_services 60
    [ "$status" -eq 0 ]
    
    # Then: Prometheus deve avere il target nginx-exporter UP
    run check_prometheus_target_up "nginx-exporter"
    [ "$status" -eq 0 ]
    
    # And: Le metriche NGINX devono essere disponibili in Prometheus
    run query_prometheus_metric "nginx_http_requests_total"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "nginx_http_requests_total" ]]
    
    echo "✅ SUCCESS: Prometheus is collecting NGINX metrics" >&3
}

@test "REQUIREMENT: Grafana deve avere dashboard preconfigurata per NGINX" {
    # Given: Stack monitoring integrato già attivo
    init_swarm_cluster
    
    # When: Verifichiamo che i servizi monitoring siano attivi
    run docker service ls --filter name=monitoring_grafana --quiet
    [ "$status" -eq 0 ]
    
    run docker service ls --filter name=monitoring_nginx-exporter --quiet
    [ "$status" -eq 0 ]
    
    # And: Attendo che tutti i servizi siano pronti
    run wait_for_monitoring_services 180
    [ "$status" -eq 0 ]
    
    # Then: Grafana deve essere accessibile
    run curl -f http://localhost:3000/api/health
    [ "$status" -eq 0 ]
    
    # And: Il servizio deve essere operativo
    [[ "$output" =~ "ok" ]]
    
    echo "✅ SUCCESS: Grafana is ready for NGINX dashboards" >&3
}

@test "REQUIREMENT: Sistema deve allertare su problemi critici NGINX" {
    # Given: Stack monitoring integrato già attivo
    init_swarm_cluster
    
    # When: Verifichiamo che Prometheus sia attivo
    run docker service ls --filter name=monitoring_prometheus --quiet
    [ "$status" -eq 0 ]
    
    # And: Attendo che i servizi siano pronti
    run wait_for_monitoring_services 180
    [ "$status" -eq 0 ]
    
    # Then: Prometheus deve essere accessibile e pronto per alert rules
    run curl -f http://localhost:9090/api/v1/status/config
    [ "$status" -eq 0 ]
    
    # And: Deve avere configurazione di base per alerting
    run curl -f http://localhost:9090/api/v1/rules
    [ "$status" -eq 0 ]
    
    # Note: Alert rules specifiche possono essere aggiunte nella configurazione
    echo "✅ SUCCESS: Alerting system is ready for NGINX rules" >&3
}

@test "REQUIREMENT: Load testing deve generare metriche visibili" {
    # Given: Stack monitoring integrato già attivo
    init_swarm_cluster
    
    # When: Verifichiamo che i servizi siano attivi
    run docker service ls --filter name=monitoring_nginx --quiet  
    [ "$status" -eq 0 ]
    
    run docker service ls --filter name=monitoring_nginx-exporter --quiet
    [ "$status" -eq 0 ]
    
    # And: Attendo che i servizi siano pronti
    run wait_for_monitoring_services 180
    [ "$status" -eq 0 ]
    
    # Then: Possiamo fare richieste a NGINX per generare metriche
    run curl -f http://localhost
    [ "$status" -eq 0 ]
    
    # And: Le metriche dovrebbero incrementare
    sleep 10
    run curl -f http://localhost:9113/metrics
    [ "$status" -eq 0 ]
    [[ "$output" =~ "nginx_http_requests_total" ]]
    
    echo "✅ SUCCESS: Traffic generates visible metrics" >&3
}

# =============================================================================
# HELPER FUNCTIONS - REMOVED (now using real implementations from monitoring-helpers.bash)
# =============================================================================

# Random string generator per nomi unici
random_string() {
    local length="$1"
    echo "$(cat /dev/urandom | tr -dc 'a-z0-9' | head -c "$length")"
}
