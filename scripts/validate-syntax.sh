#!/usr/bin/env bash
# scripts/validate-syntax.sh

set -uo pipefail  # Removed -e to handle errors manually

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Colori per output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m' # No Color

log_success() {
    echo -e "${GREEN}✓${NC} $*"
}

log_error() {
    echo -e "${RED}✗${NC} $*"
}

log_warning() {
    echo -e "${YELLOW}⚠${NC} $*"
}

log_info() {
    echo -e "ℹ $*"
}

validate_bash_syntax() {
    local file="$1"
    local filename=$(basename "$file")
    
    log_info "Checking syntax for $filename..."
    
    # Check bash syntax using a simpler approach
    if bash -n "$file" 2>/dev/null; then
        log_success "$filename has valid bash syntax"
        return 0
    else
        log_error "$filename has syntax errors"
        return 1
    fi
}

validate_shellcheck() {
    local file="$1"
    local filename=$(basename "$file")
    
    if command -v shellcheck >/dev/null 2>&1; then
        log_info "Running shellcheck on $filename..."
        set +e
        local shellcheck_output
        shellcheck_output=$(shellcheck "$file" 2>&1)
        local shellcheck_exit_code=$?
        set -e
        
        if [[ $shellcheck_exit_code -eq 0 ]]; then
            log_success "$filename passed shellcheck"
            return 0
        else
            log_warning "$filename has shellcheck warnings (non-blocking):"
            echo "$shellcheck_output"
            return 0  # Warnings are non-blocking
        fi
    else
        log_warning "shellcheck not installed, skipping static analysis"
        return 0
    fi
}

main() {
    log_info "=== Syntax Validation Started ==="
    
    local exit_code=0
    local files_checked=0
    
    # Find all bash files to validate
    local bash_files=(
        "test/helpers/docker-helpers.bash"
    )
    
    # Add any .sh files in scripts directory
    local temp_files
    mapfile -t temp_files < <(find "$PROJECT_ROOT/scripts" -name "*.sh" -type f 2>/dev/null || true)
    
    for file in "${temp_files[@]}"; do
        # Convert absolute path to relative path for consistency
        local relative_file="${file#$PROJECT_ROOT/}"
        bash_files+=("$relative_file")
    done
    
    # Remove duplicates by using associative array
    declare -A unique_files
    for file in "${bash_files[@]}"; do
        unique_files["$file"]=1
    done
    
    # Process each unique file
    for file in "${!unique_files[@]}"; do
        local full_path="$PROJECT_ROOT/$file"
        
        if [[ -f "$full_path" ]]; then
            ((files_checked++))
            
            if ! validate_bash_syntax "$full_path"; then
                exit_code=1
            fi
            
            validate_shellcheck "$full_path"
            
            echo  # Empty line for readability
        else
            log_warning "File not found: $full_path"
        fi
    done
    
    log_info "=== Syntax Validation Completed ==="
    log_info "Files checked: $files_checked"
    
    if [[ $exit_code -eq 0 ]]; then
        log_success "All syntax checks passed!"
    else
        log_error "Some syntax checks failed!"
    fi
    
    return $exit_code
}

# Esegui validazione se script chiamato direttamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi