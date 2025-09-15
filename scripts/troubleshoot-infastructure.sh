#!/bin/bash
# scripts/troubleshoot-infrastructure.sh
# Automated troubleshooting script per infrastructure issues

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
log_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_error() { echo -e "${RED}❌ $1${NC}"; }

# Load project helpers if available
if [[ -f "test/helpers/docker-helpers.bash" ]]; then
    source test/helpers/docker-helpers.bash
    log_success "Project helpers loaded"
else
    log_warning "Project helpers not found, using basic functions"
fi

# Function to check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    local missing_deps=()
    
    # Check Docker
    if ! command -v docker >/dev/null 2>&1; then
        missing_deps+=("docker")
    elif ! docker info >/dev/null 2>&1; then
        log_error "Docker installed but daemon not running"
        return 1
    else
        log_success "Docker: Available and running"
    fi
    
    # Check BATS
    if ! command -v bats >/dev/null 2>&1; then
        missing_deps+=("bats")
    else
        log_success "BATS: Available"
    fi
    
    # Check user permissions
    if ! groups | grep -q docker; then
        log_warning "User not in docker group - may need sudo for Docker commands"
    else
        log_success "Docker permissions: OK"
    fi
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        log_error "Missing dependencies: ${missing_deps[*]}"
        echo ""
        echo "Install missing dependencies:"
        echo "  sudo apt-get update"
        echo "  sudo apt-get install -y ${missing_deps[*]}"
        if [[ " ${missing_deps[*]} " =~ " docker " ]]; then
            echo "  sudo usermod -aG docker \$USER"
            echo "  # Then logout and login again"
        fi
        return 1
    fi
    
    return 0
}

# Function to diagnose BATS issues
diagnose_bats_issues() {
    log_info "Diagnosing BATS infrastructure issues..."
    
    # Check test files exist
    if [[ ! -f "test/infrastructure/cluster/test-cluster-with-services.bats" ]]; then
        log_error "Main test file not found"
        return 1
    fi
    
    # Check helpers
    if [[ ! -f "test/helpers/docker-helpers.bash" ]]; then
        log_error "Helper functions not found"
        return 1
    fi
    
    # Test helper loading
    if bash -c "source test/helpers/docker-helpers.bash && get_test_stack_name" >/dev/null 2>&1; then
        log_success "Helper functions: Working correctly"
    else
        log_error "Helper functions: Failed to load or execute"
        return 1
    fi
    
    # Check for common variable scope issues
    log_info "Checking for variable scope issues..."
    if grep -r "export.*=" test/ | grep -q setup_file; then
        log_warning "Found global exports in setup_file() - potential scope issues"
        echo "Consider using helper functions instead of global exports"
    else
        log_success "No problematic global exports found"
    fi
    
    return 0
}

# Function to diagnose Docker/Swarm issues
diagnose_docker_issues() {
    log_info "Diagnosing Docker/Swarm issues..."
    
    # Check Docker system status
    local docker_status=$(docker info --format '{{.ServerVersion}}' 2>/dev/null || echo "ERROR")
    if [[ "$docker_status" == "ERROR" ]]; then
        log_error "Docker daemon not responding"
        return 1
    else
        log_success "Docker daemon: Version $docker_status"
    fi
    
    # Check Swarm status
    local swarm_status=$(docker info --format '{{.Swarm.LocalNodeState}}' 2>/dev/null || echo "inactive")
    case "$swarm_status" in
        "active")
            log_success "Swarm: Active"
            local is_manager=$(docker info --format '{{.Swarm.ControlAvailable}}' 2>/dev/null || echo "false")
            if [[ "$is_manager" == "true" ]]; then
                log_success "Node role: Manager"
            else
                log_warning "Node role: Worker"
            fi
            ;;
        "pending")
            log_warning "Swarm: Pending state"
            ;;
        "error"|"locked")
            log_error "Swarm: Error state"
            ;;
        "inactive"|*)
            log_warning "Swarm: Inactive"
            ;;
    esac
    
    # Check for conflicting services
    local existing_services=$(docker service ls --format "{{.Name}}" 2>/dev/null | grep -E "(test|visibility)" || echo "")
    if [[ -n "$existing_services" ]]; then
        log_warning "Existing test services found: $existing_services"
        echo "These may cause conflicts. Remove with: docker service rm $existing_services"
    else
        log_success "No conflicting services found"
    fi
    
    # Check port usage
    local port_8080=$(netstat -tln 2>/dev/null | grep ":8080" || echo "")
    if [[ -n "$port_8080" ]]; then
        log_warning "Port 8080 in use: $port_8080"
    else
        log_success "Port 8080: Available"
    fi
    
    return 0
}

# Function to run automated fixes
run_automated_fixes() {
    log_info "Running automated fixes..."
    
    # Clean up existing test services
    log_info "Cleaning up existing test services..."
    docker service ls --format "{{.Name}}" 2>/dev/null | grep -E "(test|visibility)" | while read -r service; do
        log_info "Removing service: $service"
        docker service rm "$service" >/dev/null 2>&1 || true
    done
    
    # Initialize swarm if needed
    local swarm_status=$(docker info --format '{{.Swarm.LocalNodeState}}' 2>/dev/null || echo "inactive")
    if [[ "$swarm_status" != "active" ]]; then
        log_info "Initializing Docker Swarm..."
        if docker swarm init --advertise-addr 127.0.0.1 >/dev/null 2>&1; then
            log_success "Swarm initialized"
        else
            log_warning "Swarm initialization failed or already initialized"
        fi
    fi
    
    log_success "Automated fixes completed"
}

# Function to test infrastructure
test_infrastructure() {
    log_info "Testing infrastructure..."
    
    if make test-infra-visibility >/dev/null 2>&1; then
        log_success "Infrastructure tests: PASSING"
        return 0
    else
        log_error "Infrastructure tests: FAILING"
        echo ""
        echo "Run tests with verbose output to see details:"
        echo "  BATS_DEBUG=1 bats -t test/infrastructure/cluster/test-cluster-with-services.bats"
        return 1
    fi
}

# Main troubleshooting workflow
main() {
    echo "🔧 Infrastructure Troubleshooting Tool"
    echo "======================================"
    echo ""
    
    local fix_mode=false
    local verbose=false
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --fix)
                fix_mode=true
                shift
                ;;
            --verbose)
                verbose=true
                shift
                ;;
            --help)
                echo "Usage: $0 [--fix] [--verbose] [--help]"
                echo ""
                echo "Options:"
                echo "  --fix      Run automated fixes"
                echo "  --verbose  Show detailed output"
                echo "  --help     Show this help"
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                exit 1
                ;;
        esac
    done
    
    # Enable verbose mode if requested
    if [[ "$verbose" == "true" ]]; then
        set -x
    fi
    
    # Run diagnostics
    local issues_found=0
    
    if ! check_prerequisites; then
        issues_found=$((issues_found + 1))
    fi
    
    if ! diagnose_bats_issues; then
        issues_found=$((issues_found + 1))
    fi
    
    if ! diagnose_docker_issues; then
        issues_found=$((issues_found + 1))
    fi
    
    # Run fixes if requested and issues found
    if [[ "$fix_mode" == "true" && $issues_found -gt 0 ]]; then
        echo ""
        run_automated_fixes
        echo ""
        
        # Re-test after fixes
        log_info "Re-testing after fixes..."
        if test_infrastructure; then
            log_success "All issues resolved!"
            exit 0
        else
            log_error "Some issues remain - manual intervention required"
            exit 1
        fi
    elif [[ $issues_found -eq 0 ]]; then
        echo ""
        test_infrastructure
        if [[ $? -eq 0 ]]; then
            log_success "Infrastructure is healthy!"
            exit 0
        else
            exit 1
        fi
    else
        echo ""
        log_warning "Issues found. Run with --fix to attempt automated resolution"
        exit 1
    fi
}

# Only run main if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi