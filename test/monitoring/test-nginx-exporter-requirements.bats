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
    # Given: Un cluster Swarm attivo
    init_swarm_cluster
    
    # When: Deploy NGINX con configurazione status module
    run deploy_nginx_with_status_module "$TEST_STACK_NAME"
    [ "$status" -eq 0 ]
    
    # And: Attendo che NGINX sia pronto
    run wait_for_nginx_ready 60
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
    # Given: Un cluster Swarm attivo
    init_swarm_cluster
    
    # When: Deploy NGINX + Exporter stack completo
    run deploy_nginx_exporter "$TEST_STACK_NAME"
    [ "$status" -eq 0 ]
    
    # And: Attendo che l'exporter sia pronto (timeout aumentato)
    run wait_for_nginx_exporter_ready 120
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
    # Given: Stack completo con NGINX + Exporter + Prometheus
    init_swarm_cluster
    deploy_nginx_with_status_module "$TEST_STACK_NAME"
    deploy_nginx_exporter "$TEST_STACK_NAME"
    deploy_monitoring_stack "$TEST_STACK_NAME" "$MONITORING_COMPOSE"
    
    # When: Attendo che tutti i servizi siano pronti
    run wait_for_complete_nginx_monitoring_stack 180
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
    # Given: Stack completo operativo
    init_swarm_cluster
    deploy_complete_nginx_monitoring_stack "$TEST_STACK_NAME"
    wait_for_complete_nginx_monitoring_stack 180
    
    # When: Verifico dashboard NGINX in Grafana
    run check_grafana_dashboard_exists "nginx-performance"
    [ "$status" -eq 0 ]
    
    # And: La dashboard deve contenere pannelli per metriche chiave
    run check_grafana_dashboard_panels "nginx-performance" "Request Rate,Active Connections,Response Time"
    [ "$status" -eq 0 ]
    
    # Then: I dati devono essere visualizzati correttamente
    run test_grafana_dashboard_data_flow "nginx-performance"
    [ "$status" -eq 0 ]
    
    echo "✅ SUCCESS: Grafana NGINX dashboard is configured" >&3
}

@test "REQUIREMENT: Sistema deve allertare su problemi critici NGINX" {
    # Given: Stack completo con alert rules
    init_swarm_cluster
    deploy_complete_nginx_monitoring_stack_with_alerts "$TEST_STACK_NAME"
    wait_for_complete_nginx_monitoring_stack 180
    
    # When: Verifico configurazione alert rules per NGINX
    run check_prometheus_alert_rules_nginx
    [ "$status" -eq 0 ]
    
    # Then: Devono esistere regole per condizioni critiche
    [[ "$output" =~ "NginxDown" ]]
    [[ "$output" =~ "NginxHighRequestRate" ]]
    [[ "$output" =~ "NginxHighErrorRate" ]]
    [[ "$output" =~ "NginxConnectionsHigh" ]]
    
    # And: Gli alert devono essere testabili
    run test_nginx_alert_simulation "NginxHighRequestRate"
    [ "$status" -eq 0 ]
    
    echo "✅ SUCCESS: NGINX alerts are configured and testable" >&3
}

@test "REQUIREMENT: Load testing deve generare metriche visibili" {
    # Given: Sistema completo operativo
    init_swarm_cluster
    deploy_complete_nginx_monitoring_stack "$TEST_STACK_NAME"
    wait_for_complete_nginx_monitoring_stack 180
    
    # When: Eseguo load test contro NGINX
    run simulate_traffic_load 100 60  # 100 RPS per 60 secondi
    [ "$status" -eq 0 ]
    
    # Then: Le metriche devono riflettere il traffico generato
    run verify_nginx_metrics_increased "nginx_http_requests_total"
    [ "$status" -eq 0 ]
    
    # And: I grafici di Grafana devono mostrare l'attività
    run verify_grafana_shows_traffic_spike "nginx-performance"
    [ "$status" -eq 0 ]
    
    echo "✅ SUCCESS: Load testing generates visible metrics" >&3
}

# =============================================================================
# HELPER FUNCTIONS - REMOVED (now using real implementations from monitoring-helpers.bash)
# =============================================================================

# Random string generator per nomi unici
random_string() {
    local length="$1"
    echo "$(cat /dev/urandom | tr -dc 'a-z0-9' | head -c "$length")"
}
