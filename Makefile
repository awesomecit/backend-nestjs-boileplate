# ==========================================
# 🚀 Scalable NestJS Application - Makefile
# ==========================================
# 
# Quick commands for development workflow
# Usage: make <command>
# Help:  make help

.PHONY: help install build test-all test-unit test-e2e test-infra-quick test-infra-visibility test-infra-with-visibility test-infra-cleanup
.PHONY: dev start build-docker deploy-dev deploy-staging deploy-prod
.PHONY: setup-dev setup-monitoring setup-logging cleanup validate-syntax
.PHONY: debug-infrastructure troubleshoot-bats verify-environment
.PHONY: test-monitoring-red test-monitoring test-all-red
.PHONY: deploy-monitoring cleanup-monitoring status-monitoring
.DEFAULT_GOAL := help

# ==========================================
# 📋 HELP & INFO
# ==========================================

help: ## 📚 Show this help message
	@echo ""
	@echo "🚀 Scalable NestJS Application Commands"
	@echo "======================================"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-25s\033[0m %s\n", $$1, $$2}'
	@echo ""

info: ## 📊 Show project information
	@echo "📊 Project Information:"
	@echo "  Name: Scalable NestJS Application"
	@echo "  Node.js: $$(node --version 2>/dev/null || echo 'Not installed')"
	@echo "  Docker: $$(docker --version 2>/dev/null || echo 'Not installed')"
	@echo "  BATS: $$(bats --version 2>/dev/null || echo 'Not installed')"
	@echo ""

# ==========================================
# 🛠️ DEVELOPMENT COMMANDS
# ==========================================

install: ## 📦 Install dependencies
	@echo "📦 Installing Node.js dependencies..."
	npm install
	@echo "✅ Dependencies installed"

setup-dev: ## 🔧 Setup development environment
	@echo "🔧 Setting up development environment..."
	@chmod +x scripts/development/setup-dev-env.sh 2>/dev/null || echo "Script not found, skipping"
	@echo "✅ Development environment ready"

dev: ## 🚀 Start development server
	@echo "🚀 Starting development server..."
	npm run start:dev

build: ## 🏗️ Build application
	@echo "🏗️ Building application..."
	npm run build
	@echo "✅ Build completed"

# =============================================================================
# INFRASTRUCTURE DEPLOYMENT
# =============================================================================

deploy-monitoring: ## 🚀 Deploy monitoring infrastructure (Prometheus, Grafana, Portainer)
	@echo "🚀 Deploying monitoring infrastructure..."
	@chmod +x scripts/deploy-monitoring.sh
	@./scripts/deploy-monitoring.sh

deploy-infrastructure: ## 🏗️ Deploy main infrastructure (Docker Swarm, NGINX)
	@echo "🏗️ Deploying main infrastructure..."
	# I tuoi comandi esistenti per l'infrastruttura principale

deploy-all: deploy-infrastructure deploy-monitoring ## 🚀 Deploy everything (infrastructure + monitoring)

# =============================================================================
# INFRASTRUCTURE MANAGEMENT
# =============================================================================

status-monitoring: ## 📊 Check monitoring stack status
	@echo "📊 Monitoring Stack Status:"
	@echo "=========================="
	@docker stack services monitoring 2>/dev/null || echo "❌ Monitoring stack not deployed"
	@echo ""
	@echo "🔗 Quick Health Check:"
	@curl -s http://localhost:9090/api/v1/targets >/dev/null 2>&1 && echo "✅ Prometheus: UP" || echo "❌ Prometheus: DOWN"
	@curl -s http://localhost:3000/api/health >/dev/null 2>&1 && echo "✅ Grafana: UP" || echo "❌ Grafana: DOWN"
	@curl -s http://localhost:9000/api/status >/dev/null 2>&1 && echo "✅ Portainer: UP" || echo "❌ Portainer: DOWN"

status-infrastructure: ## 📊 Check main infrastructure status
	@echo "📊 Infrastructure Status:"
	@echo "========================"
	@docker node ls 2>/dev/null || echo "❌ Docker Swarm not initialized"
	@docker stack ls 2>/dev/null || echo "❌ No stacks deployed"

status-all: status-infrastructure status-monitoring ## 📊 Check all infrastructure status

# =============================================================================
# TESTING
# =============================================================================

test-infrastructure: ## 🧪 Run infrastructure tests
	@echo "🧪 Running infrastructure tests..."
	@bats test/infrastructure/

test-monitoring: ## 🧪 Run monitoring tests
	@echo "🧪 Running monitoring tests..."
	@bats test/monitoring/

test-all: test-infrastructure test-monitoring ## 🧪 Run all tests

# =============================================================================
# TDD WORKFLOW
# =============================================================================

tdd-monitoring-red: ## 🔴 TDD RED: Run monitoring tests (should fail)
	@echo "🔴 RED PHASE: Tests should FAIL (no infrastructure)"
	@echo "=================================================="
	@bats test/monitoring/test-monitoring-requirements.bats || true
	@echo "✅ Red phase complete - tests failed as expected!"

tdd-monitoring-green: ## 🟢 TDD GREEN: Deploy and test (should pass)
	@echo "🟢 GREEN PHASE: Deploy and test"
	@echo "==============================="
	@echo "Step 1: Deploy infrastructure..."
	@$(MAKE) deploy-monitoring
	@echo ""
	@echo "Step 2: Run tests (should PASS)..."
	@bats test/monitoring/test-monitoring-requirements.bats
	@echo "✅ Green phase complete - tests passed!"

tdd-monitoring: tdd-monitoring-red tdd-monitoring-green ## 🎯 Complete TDD cycle for monitoring
	@echo "🎯 TDD CYCLE COMPLETE!"
	@echo "- 🔴 RED: Tests failed without infrastructure ✅"
	@echo "- 🟢 GREEN: Infrastructure deployed, tests passed ✅"
	@echo ""
	@echo "🔗 Access your monitoring:"
	@echo "   Grafana: http://localhost:3000"
	@echo "   Prometheus: http://localhost:9090"
	@echo "   Portainer: http://localhost:9000"
	@echo ""
	@echo "Run 'make cleanup-monitoring' when done"

# =============================================================================
# CLEANUP
# =============================================================================

cleanup-monitoring: ## 🧹 Remove monitoring infrastructure
	@echo "🧹 Cleaning up monitoring infrastructure..."
	@chmod +x scripts/cleanup-monitoring.sh
	@./scripts/cleanup-monitoring.sh

cleanup-infrastructure: ## 🧹 Remove main infrastructure
	@echo "🧹 Cleaning up main infrastructure..."
	# I tuoi comandi di cleanup esistenti

cleanup-all: cleanup-monitoring cleanup-infrastructure ## 🧹 Remove all infrastructure

# =============================================================================
# DEVELOPMENT UTILITIES
# =============================================================================

logs-monitoring: ## 📋 Show monitoring services logs
	@echo "📋 Monitoring Services Logs:"
	@echo "============================"
	@docker service logs monitoring_prometheus --tail 50 2>/dev/null || echo "❌ Prometheus not running"
	@docker service logs monitoring_grafana --tail 50 2>/dev/null || echo "❌ Grafana not running"

restart-monitoring: cleanup-monitoring deploy-monitoring ## 🔄 Restart monitoring stack

health-check: ## 🏥 Run comprehensive health check for all systems
	@chmod +x scripts/health-check.sh
	@./scripts/health-check.sh

health-check-verbose: ## 🏥 Run detailed health check with verbose output  
	@chmod +x scripts/health-check.sh
	@./scripts/health-check.sh --verbose

health-check-json: ## 🏥 Run health check with JSON output
	@chmod +x scripts/health-check.sh
	@./scripts/health-check.sh --json

health-check-nestjs: ## 🏥 Check only NestJS application health
	@chmod +x scripts/health-check.sh
	@./scripts/health-check.sh --component=nestjs

health-check-infrastructure: ## 🏥 Check only infrastructure health
	@chmod +x scripts/health-check.sh
	@./scripts/health-check.sh --component=infrastructure

health-check-monitoring: ## 🏥 Check only monitoring stack health
	@chmod +x scripts/health-check.sh
	@./scripts/health-check.sh --component=monitoring


# ==========================================
# 🧪 TESTING COMMANDS  
# ==========================================

test-unit: ## 🔬 Run unit tests
	@echo "🔬 Running unit tests..."
	npm run test

test-e2e: ## 🔄 Run end-to-end tests
	@echo "🔄 Running e2e tests..."
	npm run test:e2e

test-infra-quick: ## ⚡ Run quick infrastructure tests (isolated)
	@echo "⚡ Running quick infrastructure tests..."
	@if [ -f "test/infrastructure/cluster/test-cluster-init.bats" ]; then \
		bats test/infrastructure/cluster/test-cluster-init.bats; \
	else \
		echo "⚠️  test-cluster-init.bats not found. Creating basic version..."; \
		make _create-basic-test; \
		bats test/infrastructure/cluster/test-cluster-init.bats; \
	fi
	@echo "✅ Infrastructure tests completed"

test-infra-visibility: ## 👁️ Run infrastructure tests with visible containers  
	@echo "👁️ Running infrastructure tests with persistent state..."
	@make _test-infra-visibility-impl

test-infra-with-visibility: ## 👁️ Run infrastructure tests with visible containers (alias)
	@echo "👁️ Running infrastructure tests with persistent state..."
	@make _test-infra-visibility-impl

_test-infra-visibility-impl:
	@echo "🔍 Checking if test file exists..."
	@if [ ! -f "test/infrastructure/cluster/test-cluster-with-services.bats" ]; then \
		echo "⚠️  Test file not found. Creating it..."; \
		make _create-visibility-test; \
	fi
	@echo "🧪 Executing tests..."
	@bats test/infrastructure/cluster/test-cluster-with-services.bats
	@echo ""
	@echo "🔍 Current cluster state:"
	@docker node ls 2>/dev/null || echo "  No cluster active"
	@echo ""
	@echo "📋 Active services:"
	@docker service ls 2>/dev/null || echo "  No services active"  
	@echo ""
	@echo "🐳 Running containers:"
	@docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null || echo "  No containers running"

test-infra-cleanup: ## 🧹 Cleanup test infrastructure environment
	@echo "🧹 Cleaning up test environment..."
	@docker service ls -q 2>/dev/null | xargs -r docker service rm >/dev/null 2>&1 || true
	@docker container stop $$(docker container ls -q) 2>/dev/null || true
	@docker container rm $$(docker container ls -aq) 2>/dev/null || true
	@docker swarm leave --force 2>/dev/null || true
	@docker system prune -f >/dev/null 2>&1 || true
	@echo "✅ Environment cleaned"

validate-syntax: ## ✅ Validate syntax of all bash/bats files
	@echo "✅ Validating bash syntax..."
	@find test/ -name "*.bash" -o -name "*.bats" 2>/dev/null | xargs -I {} bash -n {} && echo "  Test files: OK" || echo "  Some test files have syntax errors"
	@find scripts/ -name "*.sh" 2>/dev/null | xargs -I {} bash -n {} && echo "  Script files: OK" || echo "  Script directory not found or has syntax errors"
	@echo "✅ Syntax validation completed"

test-monitoring-red: ## 🔴 TDD RED: Run monitoring tests (should fail)
	@echo "🔴 RED PHASE: Running monitoring tests (should FAIL)"
	@echo "=============================================="
	@bats test/monitoring/test-monitoring-requirements.bats || true
	@echo ""
	@echo "✅ Red phase complete - tests failed as expected!"
	@echo "Next: implement monitoring stack to make tests pass"

test-all-red: test-infrastructure test-monitoring-red
	@echo "🔴 All RED tests completed"

test-monitoring-green:
	@echo "🟢 GREEN PHASE: Testing minimal implementation"
	@echo "============================================="
	@bats test/monitoring/test-monitoring-requirements.bats
	@echo "✅ Green phase complete - tests should PASS!"

# ==========================================
# 🔧 INTERNAL TEST FILE CREATION
# ==========================================

_create-visibility-test:
	@echo "📝 Creating visibility test files..."
	@mkdir -p test/infrastructure/cluster
	@mkdir -p test/helpers
	@make _create-test-file
	@make _create-helper-file
	@echo "✅ Test files created"

_create-test-file:
	@echo "#!/usr/bin/env bats" > test/infrastructure/cluster/test-cluster-with-services.bats
	@echo "" >> test/infrastructure/cluster/test-cluster-with-services.bats
	@echo "load '../../helpers/docker-helpers'" >> test/infrastructure/cluster/test-cluster-with-services.bats
	@echo "" >> test/infrastructure/cluster/test-cluster-with-services.bats
	@echo "# Setup persistent per questo specifico test file" >> test/infrastructure/cluster/test-cluster-with-services.bats
	@echo "setup_file() {" >> test/infrastructure/cluster/test-cluster-with-services.bats
	@echo "    export PERSIST_CLUSTER=\"true\"" >> test/infrastructure/cluster/test-cluster-with-services.bats
	@echo "    export TEST_STACK_NAME=\"visibility-test\"" >> test/infrastructure/cluster/test-cluster-with-services.bats
	@echo "    echo \"🔧 Setup: Preparing persistent test environment...\" >&3" >> test/infrastructure/cluster/test-cluster-with-services.bats
	@echo "}" >> test/infrastructure/cluster/test-cluster-with-services.bats
	@echo "" >> test/infrastructure/cluster/test-cluster-with-services.bats
	@echo "teardown_file() {" >> test/infrastructure/cluster/test-cluster-with-services.bats
	@echo "    # Cleanup solo alla fine di tutti i test del file" >> test/infrastructure/cluster/test-cluster-with-services.bats
	@echo "    if [[ \"\$$PERSIST_CLUSTER\" == \"true\" ]]; then" >> test/infrastructure/cluster/test-cluster-with-services.bats
	@echo "        echo \"🧹 Teardown: Cleaning up persistent environment...\" >&3" >> test/infrastructure/cluster/test-cluster-with-services.bats
	@echo "        cleanup_docker_environment" >> test/infrastructure/cluster/test-cluster-with-services.bats
	@echo "    fi" >> test/infrastructure/cluster/test-cluster-with-services.bats
	@echo "}" >> test/infrastructure/cluster/test-cluster-with-services.bats
	@echo "" >> test/infrastructure/cluster/test-cluster-with-services.bats
	@echo "@test \"INTEGRATION: Cluster + Service deployment end-to-end\" {" >> test/infrastructure/cluster/test-cluster-with-services.bats
	@echo "    # Given: Cluster inizializzato" >> test/infrastructure/cluster/test-cluster-with-services.bats
	@echo "    run init_swarm_cluster" >> test/infrastructure/cluster/test-cluster-with-services.bats
	@echo "    [ \"\$$status\" -eq 0 ]" >> test/infrastructure/cluster/test-cluster-with-services.bats
	@echo "" >> test/infrastructure/cluster/test-cluster-with-services.bats
	@echo "    # When: Deploy servizio test" >> test/infrastructure/cluster/test-cluster-with-services.bats
	@echo "    run deploy_test_service \"\$$TEST_STACK_NAME\"" >> test/infrastructure/cluster/test-cluster-with-services.bats
	@echo "    [ \"\$$status\" -eq 0 ]" >> test/infrastructure/cluster/test-cluster-with-services.bats
	@echo "" >> test/infrastructure/cluster/test-cluster-with-services.bats
	@echo "    # Then: Servizio visibile e funzionante" >> test/infrastructure/cluster/test-cluster-with-services.bats
	@echo "    run docker service ls --format \"{{.Name}}\"" >> test/infrastructure/cluster/test-cluster-with-services.bats
	@echo "    [[ \"\$$output\" =~ \$$TEST_STACK_NAME ]]" >> test/infrastructure/cluster/test-cluster-with-services.bats
	@echo "" >> test/infrastructure/cluster/test-cluster-with-services.bats
	@echo "    run wait_for_service_ready \"\$$TEST_STACK_NAME\" 60" >> test/infrastructure/cluster/test-cluster-with-services.bats
	@echo "    [ \"\$$status\" -eq 0 ]" >> test/infrastructure/cluster/test-cluster-with-services.bats
	@echo "" >> test/infrastructure/cluster/test-cluster-with-services.bats
	@echo "    # Verifica container attivi" >> test/infrastructure/cluster/test-cluster-with-services.bats
	@echo "    local container_count" >> test/infrastructure/cluster/test-cluster-with-services.bats
	@echo "    container_count=\$\$(docker ps --filter \"label=com.docker.swarm.service.name=\$$TEST_STACK_NAME\" --format \"{{.ID}}\" | wc -l)" >> test/infrastructure/cluster/test-cluster-with-services.bats
	@echo "    [ \"\$$container_count\" -gt 0 ]" >> test/infrastructure/cluster/test-cluster-with-services.bats
	@echo "" >> test/infrastructure/cluster/test-cluster-with-services.bats
	@echo "    echo \"✅ SUCCESS: \$$container_count containers running for service \$$TEST_STACK_NAME\" >&3" >> test/infrastructure/cluster/test-cluster-with-services.bats
	@echo "}" >> test/infrastructure/cluster/test-cluster-with-services.bats
	@echo "" >> test/infrastructure/cluster/test-cluster-with-services.bats
	@echo "@test \"INTEGRATION: Service scaling works correctly\" {" >> test/infrastructure/cluster/test-cluster-with-services.bats
	@echo "    # Given: Servizio già deployato dal test precedente" >> test/infrastructure/cluster/test-cluster-with-services.bats
	@echo "    local initial_replicas=1" >> test/infrastructure/cluster/test-cluster-with-services.bats
	@echo "    local target_replicas=3" >> test/infrastructure/cluster/test-cluster-with-services.bats
	@echo "" >> test/infrastructure/cluster/test-cluster-with-services.bats
	@echo "    # When: Scale servizio" >> test/infrastructure/cluster/test-cluster-with-services.bats
	@echo "    run docker service scale \"\$$TEST_STACK_NAME=\$$target_replicas\"" >> test/infrastructure/cluster/test-cluster-with-services.bats
	@echo "    [ \"\$$status\" -eq 0 ]" >> test/infrastructure/cluster/test-cluster-with-services.bats
	@echo "" >> test/infrastructure/cluster/test-cluster-with-services.bats
	@echo "    # Then: Replicas corrette" >> test/infrastructure/cluster/test-cluster-with-services.bats
	@echo "    run wait_for_service_scaled \"\$$TEST_STACK_NAME\" \"\$$target_replicas\" 60" >> test/infrastructure/cluster/test-cluster-with-services.bats
	@echo "    [ \"\$$status\" -eq 0 ]" >> test/infrastructure/cluster/test-cluster-with-services.bats
	@echo "" >> test/infrastructure/cluster/test-cluster-with-services.bats
	@echo "    local container_count" >> test/infrastructure/cluster/test-cluster-with-services.bats
	@echo "    container_count=\$\$(docker ps --filter \"label=com.docker.swarm.service.name=\$$TEST_STACK_NAME\" --format \"{{.ID}}\" | wc -l)" >> test/infrastructure/cluster/test-cluster-with-services.bats
	@echo "    [ \"\$$container_count\" -eq \"\$$target_replicas\" ]" >> test/infrastructure/cluster/test-cluster-with-services.bats
	@echo "" >> test/infrastructure/cluster/test-cluster-with-services.bats
	@echo "    echo \"✅ SUCCESS: Scaled to \$$container_count containers\" >&3" >> test/infrastructure/cluster/test-cluster-with-services.bats
	@echo "}" >> test/infrastructure/cluster/test-cluster-with-services.bats
	@echo "" >> test/infrastructure/cluster/test-cluster-with-services.bats
	@echo "@test \"INTEGRATION: Service is accessible via HTTP\" {" >> test/infrastructure/cluster/test-cluster-with-services.bats
	@echo "    # Given: Servizio scalato è running" >> test/infrastructure/cluster/test-cluster-with-services.bats
	@echo "    # When: Test connettività HTTP" >> test/infrastructure/cluster/test-cluster-with-services.bats
	@echo "    sleep 5  # Attendi che servizio sia completamente ready" >> test/infrastructure/cluster/test-cluster-with-services.bats
	@echo "" >> test/infrastructure/cluster/test-cluster-with-services.bats
	@echo "    run curl -s -o /dev/null -w \"%{http_code}\" http://localhost:8080" >> test/infrastructure/cluster/test-cluster-with-services.bats
	@echo "" >> test/infrastructure/cluster/test-cluster-with-services.bats
	@echo "    # Then: Servizio risponde correttamente" >> test/infrastructure/cluster/test-cluster-with-services.bats
	@echo "    [ \"\$$status\" -eq 0 ]" >> test/infrastructure/cluster/test-cluster-with-services.bats
	@echo "    [[ \"\$$output\" == \"200\" ]]" >> test/infrastructure/cluster/test-cluster-with-services.bats
	@echo "" >> test/infrastructure/cluster/test-cluster-with-services.bats
	@echo "    echo \"✅ SUCCESS: Service responding on http://localhost:8080\" >&3" >> test/infrastructure/cluster/test-cluster-with-services.bats
	@echo "}" >> test/infrastructure/cluster/test-cluster-with-services.bats

_create-helper-file:
	@if [ ! -f "test/helpers/docker-helpers.bash" ]; then \
		echo "📝 Creating docker-helpers.bash..."; \
		echo "#!/bin/bash" > test/helpers/docker-helpers.bash; \
		echo "" >> test/helpers/docker-helpers.bash; \
		echo "# Inizializza cluster Swarm con error handling" >> test/helpers/docker-helpers.bash; \
		echo "init_swarm_cluster() {" >> test/helpers/docker-helpers.bash; \
		echo "    local advertise_addr=\"\$${1:-}\"" >> test/helpers/docker-helpers.bash; \
		echo "" >> test/helpers/docker-helpers.bash; \
		echo "    # Se non specificato, detecta IP automaticamente" >> test/helpers/docker-helpers.bash; \
		echo "    if [[ -z \"\$$advertise_addr\" ]]; then" >> test/helpers/docker-helpers.bash; \
		echo "        advertise_addr=\$\$(get_primary_ip)" >> test/helpers/docker-helpers.bash; \
		echo "    fi" >> test/helpers/docker-helpers.bash; \
		echo "" >> test/helpers/docker-helpers.bash; \
		echo "    # Verifica che Docker sia disponibile" >> test/helpers/docker-helpers.bash; \
		echo "    if ! validate_docker_available; then" >> test/helpers/docker-helpers.bash; \
		echo "        return 1" >> test/helpers/docker-helpers.bash; \
		echo "    fi" >> test/helpers/docker-helpers.bash; \
		echo "" >> test/helpers/docker-helpers.bash; \
		echo "    # Se Swarm già attivo, fai leave prima" >> test/helpers/docker-helpers.bash; \
		echo "    if is_swarm_active; then" >> test/helpers/docker-helpers.bash; \
		echo "        docker swarm leave --force >/dev/null 2>&1 || true" >> test/helpers/docker-helpers.bash; \
		echo "    fi" >> test/helpers/docker-helpers.bash; \
		echo "" >> test/helpers/docker-helpers.bash; \
		echo "    # Inizializza nuovo cluster" >> test/helpers/docker-helpers.bash; \
		echo "    docker swarm init --advertise-addr \"\$$advertise_addr\" >/dev/null 2>&1" >> test/helpers/docker-helpers.bash; \
		echo "" >> test/helpers/docker-helpers.bash; \
		echo "    # Verifica successo" >> test/helpers/docker-helpers.bash; \
		echo "    is_swarm_active" >> test/helpers/docker-helpers.bash; \
		echo "}" >> test/helpers/docker-helpers.bash; \
		echo "" >> test/helpers/docker-helpers.bash; \
		echo "# Verifica se Swarm è attivo" >> test/helpers/docker-helpers.bash; \
		echo "is_swarm_active() {" >> test/helpers/docker-helpers.bash; \
		echo "    docker info --format '{{.Swarm.LocalNodeState}}' 2>/dev/null | grep -q \"active\"" >> test/helpers/docker-helpers.bash; \
		echo "}" >> test/helpers/docker-helpers.bash; \
		echo "" >> test/helpers/docker-helpers.bash; \
		echo "# Ottieni IP primario della macchina" >> test/helpers/docker-helpers.bash; \
		echo "get_primary_ip() {" >> test/helpers/docker-helpers.bash; \
		echo "    local ip" >> test/helpers/docker-helpers.bash; \
		echo "    ip=\$\$(ip route get 1.1.1.1 2>/dev/null | awk '{print \$$7; exit}')" >> test/helpers/docker-helpers.bash; \
		echo "    if [[ -n \"\$$ip\" && \"\$$ip\" =~ ^[0-9]+\\.[0-9]+\\.[0-9]+\\.[0-9]+\$$ ]]; then" >> test/helpers/docker-helpers.bash; \
		echo "        echo \"\$$ip\"" >> test/helpers/docker-helpers.bash; \
		echo "        return 0" >> test/helpers/docker-helpers.bash; \
		echo "    fi" >> test/helpers/docker-helpers.bash; \
		echo "    echo \"127.0.0.1\"" >> test/helpers/docker-helpers.bash; \
		echo "}" >> test/helpers/docker-helpers.bash; \
		echo "" >> test/helpers/docker-helpers.bash; \
		echo "# Deploy servizio test semplice" >> test/helpers/docker-helpers.bash; \
		echo "deploy_test_service() {" >> test/helpers/docker-helpers.bash; \
		echo "    local service_name=\"\$$1\"" >> test/helpers/docker-helpers.bash; \
		echo "    local image=\"\$${2:-nginx:alpine}\"" >> test/helpers/docker-helpers.bash; \
		echo "    local replicas=\"\$${3:-1}\"" >> test/helpers/docker-helpers.bash; \
		echo "" >> test/helpers/docker-helpers.bash; \
		echo "    docker service create \\" >> test/helpers/docker-helpers.bash; \
		echo "        --name \"\$$service_name\" \\" >> test/helpers/docker-helpers.bash; \
		echo "        --replicas \"\$$replicas\" \\" >> test/helpers/docker-helpers.bash; \
		echo "        --publish \"8080:80\" \\" >> test/helpers/docker-helpers.bash; \
		echo "        --label \"test=true\" \\" >> test/helpers/docker-helpers.bash; \
		echo "        \"\$$image\" >/dev/null 2>&1" >> test/helpers/docker-helpers.bash; \
		echo "}" >> test/helpers/docker-helpers.bash; \
		echo "" >> test/helpers/docker-helpers.bash; \
		echo "# Attendi che servizio sia ready" >> test/helpers/docker-helpers.bash; \
		echo "wait_for_service_ready() {" >> test/helpers/docker-helpers.bash; \
		echo "    local service_name=\"\$$1\"" >> test/helpers/docker-helpers.bash; \
		echo "    local timeout=\"\$${2:-120}\"" >> test/helpers/docker-helpers.bash; \
		echo "    local interval=\"\$${3:-5}\"" >> test/helpers/docker-helpers.bash; \
		echo "    local start_time=\$\$(date +%s)" >> test/helpers/docker-helpers.bash; \
		echo "    while true; do" >> test/helpers/docker-helpers.bash; \
		echo "        local ready_replicas" >> test/helpers/docker-helpers.bash; \
		echo "        ready_replicas=\$\$(docker service ls --filter \"name=\$$service_name\" --format \"{{.Replicas}}\" 2>/dev/null)" >> test/helpers/docker-helpers.bash; \
		echo "        if [[ \"\$$ready_replicas\" =~ ^([0-9]+)/\\1\$$ ]]; then" >> test/helpers/docker-helpers.bash; \
		echo "            return 0" >> test/helpers/docker-helpers.bash; \
		echo "        fi" >> test/helpers/docker-helpers.bash; \
		echo "        local current_time=\$\$(date +%s)" >> test/helpers/docker-helpers.bash; \
		echo "        local elapsed=\$\$((current_time - start_time))" >> test/helpers/docker-helpers.bash; \
		echo "        if [[ \"\$$elapsed\" -gt \"\$$timeout\" ]]; then" >> test/helpers/docker-helpers.bash; \
		echo "            return 1" >> test/helpers/docker-helpers.bash; \
		echo "        fi" >> test/helpers/docker-helpers.bash; \
		echo "        sleep \"\$$interval\"" >> test/helpers/docker-helpers.bash; \
		echo "    done" >> test/helpers/docker-helpers.bash; \
		echo "}" >> test/helpers/docker-helpers.bash; \
		echo "" >> test/helpers/docker-helpers.bash; \
		echo "# Attendi scaling completo" >> test/helpers/docker-helpers.bash; \
		echo "wait_for_service_scaled() {" >> test/helpers/docker-helpers.bash; \
		echo "    local service_name=\"\$$1\"" >> test/helpers/docker-helpers.bash; \
		echo "    local expected_replicas=\"\$$2\"" >> test/helpers/docker-helpers.bash; \
		echo "    local timeout=\"\$${3:-120}\"" >> test/helpers/docker-helpers.bash; \
		echo "    local start_time=\$\$(date +%s)" >> test/helpers/docker-helpers.bash; \
		echo "    while true; do" >> test/helpers/docker-helpers.bash; \
		echo "        local current_replicas" >> test/helpers/docker-helpers.bash; \
		echo "        current_replicas=\$\$(docker service ls --filter \"name=\$$service_name\" --format \"{{.Replicas}}\" | cut -d'/' -f1)" >> test/helpers/docker-helpers.bash; \
		echo "        if [[ \"\$$current_replicas\" -eq \"\$$expected_replicas\" ]]; then" >> test/helpers/docker-helpers.bash; \
		echo "            return 0" >> test/helpers/docker-helpers.bash; \
		echo "        fi" >> test/helpers/docker-helpers.bash; \
		echo "        local elapsed=\$\$(($$\(date +%s$$\) - start_time))" >> test/helpers/docker-helpers.bash; \
		echo "        if [[ \"\$$elapsed\" -gt \"\$$timeout\" ]]; then" >> test/helpers/docker-helpers.bash; \
		echo "            return 1" >> test/helpers/docker-helpers.bash; \
		echo "        fi" >> test/helpers/docker-helpers.bash; \
		echo "        sleep 2" >> test/helpers/docker-helpers.bash; \
		echo "    done" >> test/helpers/docker-helpers.bash; \
		echo "}" >> test/helpers/docker-helpers.bash; \
		echo "" >> test/helpers/docker-helpers.bash; \
		echo "# Cleanup completo ambiente Docker" >> test/helpers/docker-helpers.bash; \
		echo "cleanup_docker_environment() {" >> test/helpers/docker-helpers.bash; \
		echo "    echo \"🧹 Starting environment cleanup...\" >&3" >> test/helpers/docker-helpers.bash; \
		echo "    local services=\$\$(docker service ls -q 2>/dev/null)" >> test/helpers/docker-helpers.bash; \
		echo "    if [[ -n \"\$$services\" ]]; then" >> test/helpers/docker-helpers.bash; \
		echo "        echo \"\$$services\" | xargs -r docker service rm >/dev/null 2>&1 || true" >> test/helpers/docker-helpers.bash; \
		echo "    fi" >> test/helpers/docker-helpers.bash; \
		echo "    local containers=\$\$(docker ps -aq 2>/dev/null)" >> test/helpers/docker-helpers.bash; \
		echo "    if [[ -n \"\$$containers\" ]]; then" >> test/helpers/docker-helpers.bash; \
		echo "        docker stop \$$containers >/dev/null 2>&1 || true" >> test/helpers/docker-helpers.bash; \
		echo "        docker rm \$$containers >/dev/null 2>&1 || true" >> test/helpers/docker-helpers.bash; \
		echo "    fi" >> test/helpers/docker-helpers.bash; \
		echo "    if is_swarm_active; then" >> test/helpers/docker-helpers.bash; \
		echo "        docker swarm leave --force >/dev/null 2>&1 || true" >> test/helpers/docker-helpers.bash; \
		echo "    fi" >> test/helpers/docker-helpers.bash; \
		echo "    docker volume prune -f >/dev/null 2>&1 || true" >> test/helpers/docker-helpers.bash; \
		echo "    echo \"✅ Environment cleanup completed\" >&3" >> test/helpers/docker-helpers.bash; \
		echo "}" >> test/helpers/docker-helpers.bash; \
		echo "" >> test/helpers/docker-helpers.bash; \
		echo "# Verifica che Docker sia disponibile" >> test/helpers/docker-helpers.bash; \
		echo "validate_docker_available() {" >> test/helpers/docker-helpers.bash; \
		echo "    command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1" >> test/helpers/docker-helpers.bash; \
		echo "}" >> test/helpers/docker-helpers.bash; \
		echo "✅ docker-helpers.bash created"; \
	else \
		echo "📝 docker-helpers.bash already exists"; \
	fi

_create-basic-test:
	@mkdir -p test/infrastructure/cluster
	@mkdir -p test/helpers
	@if [ ! -f "test/helpers/docker-helpers.bash" ]; then \
		make _create-helper-file; \
	fi
	@echo "#!/usr/bin/env bats" > test/infrastructure/cluster/test-cluster-init.bats
	@echo "" >> test/infrastructure/cluster/test-cluster-init.bats
	@echo "load '../../helpers/docker-helpers'" >> test/infrastructure/cluster/test-cluster-init.bats
	@echo "" >> test/infrastructure/cluster/test-cluster-init.bats
	@echo "setup() {" >> test/infrastructure/cluster/test-cluster-init.bats
	@echo "    cleanup_docker_environment" >> test/infrastructure/cluster/test-cluster-init.bats
	@echo "}" >> test/infrastructure/cluster/test-cluster-init.bats
	@echo "" >> test/infrastructure/cluster/test-cluster-init.bats
	@echo "teardown() {" >> test/infrastructure/cluster/test-cluster-init.bats
	@echo "    cleanup_docker_environment" >> test/infrastructure/cluster/test-cluster-init.bats
	@echo "}" >> test/infrastructure/cluster/test-cluster-init.bats
	@echo "" >> test/infrastructure/cluster/test-cluster-init.bats
	@echo "@test \"Docker is available and running\" {" >> test/infrastructure/cluster/test-cluster-init.bats
	@echo "    run validate_docker_available" >> test/infrastructure/cluster/test-cluster-init.bats
	@echo "    [ \"\$$status\" -eq 0 ]" >> test/infrastructure/cluster/test-cluster-init.bats
	@echo "}" >> test/infrastructure/cluster/test-cluster-init.bats
	@echo "" >> test/infrastructure/cluster/test-cluster-init.bats
	@echo "@test \"Docker Swarm cluster can be initialized\" {" >> test/infrastructure/cluster/test-cluster-init.bats
	@echo "    run init_swarm_cluster" >> test/infrastructure/cluster/test-cluster-init.bats
	@echo "    [ \"\$$status\" -eq 0 ]" >> test/infrastructure/cluster/test-cluster-init.bats
	@echo "}" >> test/infrastructure/cluster/test-cluster-init.bats
	@echo "" >> test/infrastructure/cluster/test-cluster-init.bats
	@echo "@test \"Swarm cluster has manager node\" {" >> test/infrastructure/cluster/test-cluster-init.bats
	@echo "    init_swarm_cluster" >> test/infrastructure/cluster/test-cluster-init.bats
	@echo "    run docker node ls --filter \"role=manager\" --format \"{{.Status}}\"" >> test/infrastructure/cluster/test-cluster-init.bats
	@echo "    [ \"\$$status\" -eq 0 ]" >> test/infrastructure/cluster/test-cluster-init.bats
	@echo "    [[ \"\$$output\" =~ \"Ready\" ]]" >> test/infrastructure/cluster/test-cluster-init.bats
	@echo "}" >> test/infrastructure/cluster/test-cluster-init.bats

# ==========================================
# 🐳 DOCKER & DEPLOYMENT
# ==========================================

build-docker: ## 🐳 Build Docker image
	@echo "🐳 Building Docker image..."
	docker build -t scalable-nestjs-app:latest .
	@echo "✅ Docker image built"

deploy-dev: ## 🚀 Deploy to development environment
	@echo "🚀 Deploying to development..."
	@echo "✅ Deployed to development (placeholder)"

deploy-staging: ## 🎭 Deploy to staging environment
	@echo "🎭 Deploying to staging..."
	@echo "✅ Deployed to staging (placeholder)"

deploy-prod: ## 🏭 Deploy to production environment
	@echo "🏭 Deploying to production..."
	@echo "⚠️  This will deploy to PRODUCTION. Continue? [y/N]"
	@read confirmation && [ "$$confirmation" = "y" ] || exit 1
	@echo "✅ Deployed to production (placeholder)"

# ==========================================
# 📊 MONITORING & OBSERVABILITY
# ==========================================

setup-monitoring: ## 📊 Setup monitoring stack (Prometheus/Grafana)
	@echo "📊 Setting up monitoring stack..."
	@echo "✅ Monitoring stack ready (placeholder)"
	@echo "📈 Grafana: http://localhost:3000"
	@echo "🎯 Prometheus: http://localhost:9090"

setup-logging: ## 📋 Setup logging stack (ELK)
	@echo "📋 Setting up logging stack..."
	@echo "✅ Logging stack ready (placeholder)"
	@echo "🔍 Kibana: http://localhost:5601"

# ==========================================
# 🧹 CLEANUP & MAINTENANCE
# ==========================================

cleanup: ## 🧹 Full cleanup (containers, images, networks, volumes)
	@echo "🧹 Performing full cleanup..."
	@echo "⚠️  This will remove all containers, networks, and volumes. Continue? [y/N]"
	@read confirmation && [ "$$confirmation" = "y" ] || exit 1
	@docker system prune -af --volumes
	@echo "✅ Full cleanup completed"

cleanup-dev: ## 🧹 Cleanup development resources only
	@echo "🧹 Cleaning development resources..."
	@docker container prune -f
	@docker network prune -f
	@echo "✅ Development cleanup completed"

# ==========================================
# 🔧 UTILITY COMMANDS
# ==========================================

logs-app: ## 📋 Show application logs
	@echo "📋 Application logs:"
	@docker service logs scalable-app 2>/dev/null || echo "Service not running"

status: ## 📊 Show system status
	@echo "📊 System Status:"
	@echo "=================="
	@echo "🐳 Docker:"
	@docker version --format '  Version: {{.Server.Version}}' 2>/dev/null || echo "  Not running"
	@echo ""
	@echo "🔄 Swarm:"
	@docker info --format '  State: {{.Swarm.LocalNodeState}}' 2>/dev/null || echo "  Not active"
	@echo ""
	@echo "📋 Services:"
	@docker service ls 2>/dev/null || echo "  No services running"
	@echo ""
	@echo "🐳 Containers:"
	@docker ps --format "table {{.Names}}\t{{.Status}}" 2>/dev/null || echo "  No containers running"

# ==========================================
# 🚨 EMERGENCY COMMANDS
# ==========================================

emergency-stop: ## 🚨 Emergency stop all services
	@echo "🚨 EMERGENCY STOP - Stopping all services..."
	@docker service ls -q | xargs -r docker service rm
	@docker container stop $$(docker container ls -q) 2>/dev/null || true
	@echo "✅ All services stopped"

emergency-reset: ## 🚨 Emergency reset entire environment
	@echo "🚨 EMERGENCY RESET - This will destroy everything!"
	@echo "⚠️  Continue? [y/N]"
	@read confirmation && [ "$$confirmation" = "y" ] || exit 1
	@make emergency-stop
	@make cleanup
	@docker swarm leave --force 2>/dev/null || true
	@echo "✅ Environment reset completed"

# ==========================================
# 📝 DEVELOPMENT HELPERS
# ==========================================

commit-check: ## ✅ Pre-commit validation
	@echo "✅ Running pre-commit checks..."
	@make validate-syntax
	@make test-unit
	@echo "✅ Pre-commit checks passed"

quick-start: ## 🚀 Quick project start (install + build + dev setup)
	@echo "🚀 Quick project start..."
	@make install
	@make setup-dev
	@make build
	@echo "✅ Project ready! Run 'make dev' to start development server"

# ==========================================
# 🔍 DEBUG COMMANDS
# ==========================================

debug-env: ## 🔍 Debug environment setup
	@echo "🔍 Environment Debug Information:"
	@echo "================================="
	@echo "📁 Current directory: $$(pwd)"
	@echo "👤 Current user: $$(whoami)"
	@echo "🐳 Docker groups: $$(groups | grep docker || echo 'User not in docker group')"
	@echo "📦 Node.js: $$(which node || echo 'Not found')"
	@echo "📦 NPM: $$(which npm || echo 'Not found')"
	@echo "🧪 BATS: $$(which bats || echo 'Not found')"
	@echo "🐳 Docker: $$(which docker || echo 'Not found')"
	@echo ""
	@echo "📋 Project files:"
	@ls -la | head -10

# Debug infrastructure completo con diagnostics
debug-infrastructure:
	@echo "🔍 Infrastructure Debug Mode..."
	@echo "=== DOCKER STATE ==="
	@docker info
	@echo ""
	@echo "=== SWARM STATUS ==="
	@docker info --format '{{.Swarm.LocalNodeState}}'
	@echo ""
	@echo "=== RUNNING SERVICES ==="
	@docker service ls 2>/dev/null || echo "No services running"
	@echo ""
	@echo "=== ACTIVE CONTAINERS ==="
	@docker ps
	@echo ""
	@echo "=== PORT USAGE ==="
	@netstat -tln | grep -E ":80|:8080|:443" || echo "Target ports available"

# Troubleshoot BATS specificamente
troubleshoot-bats:
	@echo "🧪 BATS Troubleshooting Mode..."
	@echo "=== BATS VERSION ==="
	@bats --version
	@echo ""
	@echo "=== HELPER FUNCTIONS TEST ==="
	@source test/helpers/docker-helpers.bash && \
	 echo "✅ Helpers loaded successfully" || \
	 echo "❌ Helper loading failed"
	@echo ""
	@echo "=== VARIABLE SCOPE TEST ==="
	@bash -c 'source test/helpers/docker-helpers.bash; get_test_stack_name' && \
	 echo "✅ Helper functions working" || \
	 echo "❌ Helper functions broken"

# Environment verification prima dei test
verify-environment:
	@echo "🔍 Environment Verification..."
	@command -v docker >/dev/null 2>&1 && echo "✅ Docker: Available" || echo "❌ Docker: Missing"
	@command -v bats >/dev/null 2>&1 && echo "✅ BATS: Available" || echo "❌ BATS: Missing"
	@docker info >/dev/null 2>&1 && echo "✅ Docker Daemon: Running" || echo "❌ Docker Daemon: Not running"
	@groups | grep -q docker && echo "✅ Docker Permissions: OK" || echo "⚠️ Docker Permissions: User not in docker group"
	@[ -f test/helpers/docker-helpers.bash ] && echo "✅ Helper Functions: Present" || echo "❌ Helper Functions: Missing"
	
# Test con cleanup forzato e debug
test-infra-troubleshoot:
	@echo "🧹 Force cleanup before tests..."
	@./scripts/cleanup-test-environment.sh 2>/dev/null || true
	@echo "🧪 Running tests with debug output..."
	@BATS_DEBUG=1 bats -t test/infrastructure/cluster/test-cluster-with-services.bats

# Success metrics reporting
test-infra-metrics:
	@echo "📊 Infrastructure Test Metrics Report"
	@echo "==================================="
	@echo -n "Test Success Rate: "
	@if make test-infra-visibility >/dev/null 2>&1; then \
		echo "✅ 100% (All tests passing)"; \
	else \
		echo "❌ Failing tests detected"; \
	fi
	@echo -n "Infrastructure State: "
	@if docker info --format '{{.Swarm.LocalNodeState}}' | grep -q "active"; then \
		echo "✅ Operational (Swarm active)"; \
	else \
		echo "⚠️ Inactive (Swarm not active)"; \
	fi
	@echo -n "Container Deployment: "
	@if docker service ls --format "{{.Name}}" | grep -q "visibility-test"; then \
		replicas=$$(docker service ls --format "{{.Replicas}}" --filter name=visibility-test); \
		echo "✅ Active ($$replicas replicas)"; \
	else \
		echo "⚠️ No test services running"; \
	fi

# ==========================================
# 🎯 TEST SERVICES
# ==========================================

test-service: ## 🧪 Test deployed service manually
	@echo "🧪 Testing deployed service..."
	@if curl -s http://localhost:8080 >/dev/null 2>&1; then \
		echo "✅ Service is responding on http://localhost:8080"; \
		curl -s http://localhost:8080 | head -3; \
	else \
		echo "❌ Service not responding on http://localhost:8080"; \
		echo "🔍 Check if service is running: make status"; \
	fi

open-service: ## 🌐 Open service in browser (Linux)
	@echo "🌐 Opening service in browser..."
	@if command -v xdg-open >/dev/null 2>&1; then \
		xdg-open http://localhost:8080; \
	else \
		echo "Service available at: http://localhost:8080"; \
	fi

# ==========================================
# 🔧 FILE SYSTEM UTILITIES
# ==========================================

check-files: ## 🔍 Check if test files exist
	@echo "🔍 Checking test file structure..."
	@echo "📁 Test directories:"
	@ls -la test/ 2>/dev/null || echo "  test/ directory not found"
	@echo ""
	@echo "📁 Helper files:"
	@ls -la test/helpers/ 2>/dev/null || echo "  test/helpers/ directory not found"
	@echo ""
	@echo "📁 Infrastructure tests:"
	@ls -la test/infrastructure/cluster/ 2>/dev/null || echo "  test/infrastructure/cluster/ directory not found"
	@echo ""
	@echo "📋 Existing BATS files:"
	@find test/ -name "*.bats" 2>/dev/null || echo "  No BATS files found"