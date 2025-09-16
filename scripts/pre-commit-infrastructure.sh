#!/bin/bash

# =============================================================================
# 🚀 PRE-COMMIT INFRASTRUCTURE VALIDATION
# =============================================================================
# 
# Questo script viene eseguito prima di ogni commit per garantire che:
# 1. L'infrastruttura di base sia funzionante
# 2. I servizi critici siano disponibili
# 3. La configurazione sia valida
#
# Eseguito da: Husky pre-commit hook
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo -e "${BLUE}🔍 PRE-COMMIT${NC} $1"
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
# VALIDATION FUNCTIONS
# =============================================================================

validate_docker() {
    log "Validating Docker setup..."
    
    if ! command -v docker >/dev/null 2>&1; then
        log_error "Docker is not installed"
        return 1
    fi
    
    if ! docker info >/dev/null 2>&1; then
        log_error "Docker daemon is not running"
        return 1
    fi
    
    log_success "Docker is available and running"
    return 0
}

validate_infrastructure_config() {
    log "Validating infrastructure configuration..."
    
    # Check if critical infrastructure files exist
    local required_files=(
        "deployment/monitoring/docker-compose.monitoring.yml"
        "scripts/deploy-monitoring.sh"
        "scripts/cleanup-monitoring.sh"
        "scripts/health-check.sh"
    )
    
    for file in "${required_files[@]}"; do
        if [[ ! -f "$file" ]]; then
            log_error "Required file missing: $file"
            return 1
        fi
    done
    
    # Validate YAML syntax
    if command -v docker-compose >/dev/null 2>&1; then
        if ! docker-compose -f deployment/monitoring/docker-compose.monitoring.yml config >/dev/null 2>&1; then
            log_error "Invalid docker-compose configuration"
            return 1
        fi
    fi
    
    log_success "Infrastructure configuration is valid"
    return 0
}

validate_scripts() {
    log "Validating shell scripts syntax..."
    
    local script_files=(
        "scripts/deploy-monitoring.sh"
        "scripts/cleanup-monitoring.sh" 
        "scripts/health-check.sh"
    )
    
    for script in "${script_files[@]}"; do
        if [[ -f "$script" ]]; then
            if ! bash -n "$script" 2>/dev/null; then
                log_error "Syntax error in script: $script"
                return 1
            fi
        fi
    done
    
    log_success "All scripts have valid syntax"
    return 0
}

validate_test_structure() {
    log "Validating test structure..."
    
    local required_test_dirs=(
        "test/infrastructure"
        "test/monitoring" 
        "test/helpers"
    )
    
    for dir in "${required_test_dirs[@]}"; do
        if [[ ! -d "$dir" ]]; then
            log_warning "Test directory missing: $dir"
            # Don't fail for missing test directories, just warn
        fi
    done
    
    # Check for BATS availability if tests exist
    if [[ -d "test/infrastructure" ]] && find test/infrastructure -name "*.bats" -type f | grep -q .; then
        if ! command -v bats >/dev/null 2>&1; then
            log_warning "BATS not installed - infrastructure tests will be skipped"
        else
            log_success "BATS is available for infrastructure testing"
        fi
    fi
    
    log_success "Test structure validation completed"
    return 0
}

quick_infrastructure_health() {
    log "Running quick infrastructure health check..."
    
    # Only run if Docker is available
    if validate_docker; then
        # Quick Docker Swarm check
        if docker info --format '{{.Swarm.LocalNodeState}}' 2>/dev/null | grep -q "active"; then
            log_success "Docker Swarm is active"
        else
            log_warning "Docker Swarm is not active (not required for development)"
        fi
        
        # Check for running monitoring services using Docker
        local running_services=0
        if docker service ls 2>/dev/null | grep -q "monitoring_"; then
            running_services=$(docker service ls --filter "name=monitoring_" --format "{{.Name}}" 2>/dev/null | wc -l)
            log_success "$running_services monitoring service(s) running via Docker Swarm"
        else
            log_warning "No monitoring services detected (use 'make deploy-monitoring' to start)"
        fi
    fi
    
    return 0
}

# =============================================================================
# MAIN VALIDATION
# =============================================================================

main() {
    log "🚦 Starting pre-commit infrastructure validation..."
    echo ""
    
    local exit_code=0
    
    # Run validations (some can warn without failing)
    validate_docker || exit_code=1
    validate_infrastructure_config || exit_code=1
    validate_scripts || exit_code=1
    validate_test_structure  # This only warns
    quick_infrastructure_health  # This only warns
    
    echo ""
    if [[ $exit_code -eq 0 ]]; then
        log_success "🎉 Pre-commit validation passed!"
        log "Your infrastructure configuration is ready for commit"
    else
        log_error "💥 Pre-commit validation failed!"
        log_error "Please fix the issues above before committing"
    fi
    
    return $exit_code
}

# Run main function
main "$@"
