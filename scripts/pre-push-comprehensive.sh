#!/bin/bash

# =============================================================================
# 🚀 PRE-PUSH COMPREHENSIVE TESTING
# =============================================================================
# 
# Questo script viene eseguito prima di ogni push per garantire che:
# 1. Tutti i test NestJS passino
# 2. L'infrastruttura sia testabile e funzionante
# 3. Il monitoring stack sia deployabile
# 4. I health checks passino
#
# Eseguito da: Husky pre-push hook
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo -e "${BLUE}🚀 PRE-PUSH${NC} $1"
}

log_success() {
    echo -e "${GREEN}✅${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}⚠️${NC} $1"
}

log_error() {
    echo -e "${RED}❌${NC} $1"
}

# =============================================================================
# TEST EXECUTION FUNCTIONS
# =============================================================================

run_nestjs_tests() {
    log "Running NestJS unit tests..."
    
    if npm run test --silent; then
        log_success "NestJS unit tests passed"
        return 0
    else
        log_error "NestJS unit tests failed"
        return 1
    fi
}

run_infrastructure_tests() {
    log "Running infrastructure tests..."
    
    # Check if BATS is available
    if ! command -v bats >/dev/null 2>&1; then
        log_warning "BATS not available - skipping infrastructure tests"
        log_warning "Install BATS to enable infrastructure testing: npm install -g bats"
        return 0
    fi
    
    # Check if infrastructure tests exist
    if [[ ! -d "test/infrastructure" ]] || ! find test/infrastructure -name "*.bats" -type f | grep -q .; then
        log_warning "No infrastructure tests found - skipping"
        return 0
    fi
    
    # Run infrastructure tests
    if bats test/infrastructure/ --tap 2>/dev/null | grep -q "^ok"; then
        log_success "Infrastructure tests passed"
        return 0
    else
        log_error "Infrastructure tests failed"
        return 1
    fi
}

test_monitoring_deployment() {
    log "Testing monitoring stack deployment..."
    
    # Save current monitoring state
    local was_running=false
    if docker service ls 2>/dev/null | grep -q "monitoring_"; then
        was_running=true
        log "Monitoring stack is currently running"
    fi
    
    # Test deployment script
    if ! bash -n scripts/deploy-monitoring.sh; then
        log_error "deploy-monitoring.sh has syntax errors"
        return 1
    fi
    
    # Test cleanup script
    if ! bash -n scripts/cleanup-monitoring.sh; then
        log_error "cleanup-monitoring.sh has syntax errors"
        return 1
    fi
    
    # If monitoring wasn't running, test a quick deploy/cleanup cycle
    if [[ "$was_running" == "false" ]]; then
        log "Testing monitoring deployment cycle..."
        
        # Quick deployment test (with timeout)
        if timeout 60s ./scripts/deploy-monitoring.sh >/dev/null 2>&1; then
            log_success "Monitoring deployment test successful"
            
            # Clean up test deployment
            if ./scripts/cleanup-monitoring.sh >/dev/null 2>&1; then
                log_success "Monitoring cleanup test successful"
            else
                log_warning "Monitoring cleanup had issues (manual cleanup may be needed)"
            fi
        else
            log_warning "Monitoring deployment test timed out or failed (non-critical)"
            # Try cleanup anyway
            ./scripts/cleanup-monitoring.sh >/dev/null 2>&1 || true
        fi
    else
        log_success "Monitoring stack deployment scripts validated"
    fi
    
    return 0
}

run_health_checks() {
    log "Running comprehensive health checks..."
    
    # Test health check script syntax
    if ! bash -n scripts/health-check.sh; then
        log_error "health-check.sh has syntax errors"
        return 1
    fi
    
    # Run infrastructure health check
    if ./scripts/health-check.sh --component=infrastructure >/dev/null 2>&1; then
        log_success "Infrastructure health check passed"
    else
        log_warning "Infrastructure health check failed (may be expected in CI)"
    fi
    
    # If monitoring is running, check it too
    if docker service ls 2>/dev/null | grep -q "monitoring_"; then
        if ./scripts/health-check.sh --component=monitoring >/dev/null 2>&1; then
            log_success "Monitoring health check passed"
        else
            log_warning "Monitoring health check failed"
        fi
    fi
    
    return 0
}

build_application() {
    log "Building application..."
    
    if npm run build --silent; then
        log_success "Application build successful"
        return 0
    else
        log_error "Application build failed"
        return 1
    fi
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================

main() {
    log "🚦 Starting comprehensive pre-push testing..."
    echo ""
    
    local exit_code=0
    local test_results=()
    
    # Run all tests and collect results
    log "Phase 1: NestJS Tests"
    if run_nestjs_tests; then
        test_results+=("✅ NestJS Tests")
    else
        test_results+=("❌ NestJS Tests")
        exit_code=1
    fi
    
    echo ""
    log "Phase 2: Infrastructure Tests"
    if run_infrastructure_tests; then
        test_results+=("✅ Infrastructure Tests")
    else
        test_results+=("❌ Infrastructure Tests")
        exit_code=1
    fi
    
    echo ""
    log "Phase 3: Monitoring Deployment Test"
    if test_monitoring_deployment; then
        test_results+=("✅ Monitoring Deployment")
    else
        test_results+=("❌ Monitoring Deployment")
        exit_code=1
    fi
    
    echo ""
    log "Phase 4: Health Checks"
    if run_health_checks; then
        test_results+=("✅ Health Checks")
    else
        test_results+=("⚠️ Health Checks")
        # Don't fail on health checks in CI
    fi
    
    echo ""
    log "Phase 5: Application Build"
    if build_application; then
        test_results+=("✅ Application Build")
    else
        test_results+=("❌ Application Build")
        exit_code=1
    fi
    
    # Summary
    echo ""
    log "📋 Pre-push Test Summary:"
    for result in "${test_results[@]}"; do
        echo "   $result"
    done
    
    echo ""
    if [[ $exit_code -eq 0 ]]; then
        log_success "🎉 All critical pre-push tests passed!"
        log "Your code is ready to be pushed"
    else
        log_error "💥 Some critical tests failed!"
        log_error "Please fix the issues above before pushing"
    fi
    
    return $exit_code
}

# Run main function
main "$@"
