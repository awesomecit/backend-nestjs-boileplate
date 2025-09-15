#!/usr/bin/env bash
# scripts/install-vscode-extensions.sh

set -uo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
readonly EXTENSIONS_FILE="$PROJECT_ROOT/.vscode/extensions.json"

# Colori per output
readonly GREEN='\033[0;32m'
readonly RED='\033[0;31m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m'

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

check_code_command() {
    if ! command -v code >/dev/null 2>&1; then
        log_error "VS Code command 'code' not found in PATH"
        log_info "Make sure VS Code is installed and the 'code' command is available"
        log_info "You can enable it from VS Code: View → Command Palette → Shell Command: Install 'code' command in PATH"
        return 1
    fi
    return 0
}

extract_extensions() {
    if [[ ! -f "$EXTENSIONS_FILE" ]]; then
        log_error "Extensions file not found: $EXTENSIONS_FILE"
        return 1
    fi

    # Extract extension IDs from JSON file
    grep -o '"[^"]*"' "$EXTENSIONS_FILE" | \
    grep -v '"recommendations"' | \
    sed 's/"//g' | \
    grep -v '^$'
}

install_extension() {
    local extension_id="$1"
    
    log_info "Installing extension: $extension_id"
    
    if code --install-extension "$extension_id" --force; then
        log_success "Successfully installed: $extension_id"
        return 0
    else
        log_error "Failed to install: $extension_id"
        return 1
    fi
}

main() {
    log_info "=== VS Code Extensions Installer ==="
    
    if ! check_code_command; then
        return 1
    fi
    
    local extensions
    if ! extensions=$(extract_extensions); then
        return 1
    fi
    
    if [[ -z "$extensions" ]]; then
        log_warning "No extensions found in $EXTENSIONS_FILE"
        return 0
    fi
    
    local total_extensions
    total_extensions=$(echo "$extensions" | wc -l)
    log_info "Found $total_extensions extensions to install"
    
    local installed=0
    local failed=0
    
    while IFS= read -r extension; do
        if [[ -n "$extension" ]]; then
            if install_extension "$extension"; then
                ((installed++))
            else
                ((failed++))
            fi
            echo  # Empty line for readability
        fi
    done <<< "$extensions"
    
    log_info "=== Installation Summary ==="
    log_success "Successfully installed: $installed extensions"
    
    if [[ $failed -gt 0 ]]; then
        log_error "Failed to install: $failed extensions"
        return 1
    else
        log_success "All extensions installed successfully!"
        return 0
    fi
}

# Esegui installazione se script chiamato direttamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
