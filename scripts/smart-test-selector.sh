#!/bin/bash

# scripts/smart-test-selector.sh
# Script intelligente per selezionare i test in base ai file modificati

set -e

# =============================================================================
# CONFIGURAZIONE
# =============================================================================

# Pattern dei file per categoria
NESTJS_PATTERNS=(
    "src/**/*.ts"
    "test/unit/**/*.spec.ts" 
    "test/e2e/**/*.ts"
    "test/integration/**/*.ts"
    "nest-cli.json"
    "tsconfig.json"
    "tsconfig.build.json"
    "jest.config.js"
    "test/jest-e2e.json"
)

INFRASTRUCTURE_PATTERNS=(
    "deployment/**/*"
    "infrastructure/**/*"
    "docker-compose*.yml"
    "Dockerfile*"
    "scripts/**/*.sh"
    "test/infrastructure/**/*.bats"
    "test/helpers/**/*.bash"
    "Makefile"
    ".env*"
)

MONITORING_PATTERNS=(
    "deployment/monitoring/**/*"
    "test/monitoring/**/*.bats"
    "monitoring/**/*"
    "grafana/**/*"
    "prometheus/**/*"
)

# =============================================================================
# FUNZIONI HELPER
# =============================================================================

# Ottieni lista file modificati da ultimo commit
get_changed_files() {
    local comparison="${1:-HEAD~1}"
    git diff --name-only "$comparison" 2>/dev/null || {
        # Se non c'è git history, usa staged files
        git diff --cached --name-only 2>/dev/null || {
            echo "⚠️  No git repository or staged files found" >&2
            return 1
        }
    }
}

# Verifica se pattern match con file modificati
matches_pattern() {
    local file="$1"
    shift
    local patterns=("$@")
    
    for pattern in "${patterns[@]}"; do
        # Converte glob pattern in regex per grep
        local regex=$(echo "$pattern" | sed 's/\*\*/.*/' | sed 's/\*/[^\/]*/')
        if echo "$file" | grep -qE "$regex"; then
            return 0
        fi
    done
    return 1
}

# Analizza tipi di cambiamenti
analyze_changes() {
    local changed_files=()
    readarray -t changed_files < <(get_changed_files "$@")
    
    if [ ${#changed_files[@]} -eq 0 ]; then
        echo "📝 No changes detected"
        return 0
    fi
    
    local nestjs_changed=false
    local infrastructure_changed=false  
    local monitoring_changed=false
    local docs_changed=false
    local config_changed=false
    
    echo "📊 Analyzing ${#changed_files[@]} changed files..."
    
    for file in "${changed_files[@]}"; do
        echo "  📄 $file"
        
        if matches_pattern "$file" "${NESTJS_PATTERNS[@]}"; then
            nestjs_changed=true
            echo "    └─ 🚀 NestJS component"
        fi
        
        if matches_pattern "$file" "${INFRASTRUCTURE_PATTERNS[@]}"; then
            infrastructure_changed=true
            echo "    └─ 🏗️ Infrastructure component"
        fi
        
        if matches_pattern "$file" "${MONITORING_PATTERNS[@]}"; then
            monitoring_changed=true  
            echo "    └─ 📊 Monitoring component"
        fi
        
        if [[ "$file" == docs/* ]] || [[ "$file" == *.md ]]; then
            docs_changed=true
            echo "    └─ 📚 Documentation"
        fi
        
        if [[ "$file" == package.json ]] || [[ "$file" == *.config.* ]]; then
            config_changed=true
            echo "    └─ ⚙️ Configuration"
        fi
    done
    
    # Output dei risultati
    echo ""
    echo "🎯 CHANGE ANALYSIS RESULTS:"
    echo "NESTJS_CHANGED=$nestjs_changed"
    echo "INFRASTRUCTURE_CHANGED=$infrastructure_changed"
    echo "MONITORING_CHANGED=$monitoring_changed"
    echo "DOCS_CHANGED=$docs_changed"
    echo "CONFIG_CHANGED=$config_changed"
}

# Determina quali test eseguire
determine_tests() {
    local changed_files=()
    readarray -t changed_files < <(get_changed_files "$@")
    
    local nestjs_changed=false
    local infrastructure_changed=false  
    local monitoring_changed=false
    
    for file in "${changed_files[@]}"; do
        if matches_pattern "$file" "${NESTJS_PATTERNS[@]}"; then
            nestjs_changed=true
        fi
        
        if matches_pattern "$file" "${INFRASTRUCTURE_PATTERNS[@]}"; then
            infrastructure_changed=true
        fi
        
        if matches_pattern "$file" "${MONITORING_PATTERNS[@]}"; then
            monitoring_changed=true  
        fi
    done
    
    # Determina strategy
    if [[ "$nestjs_changed" == true && "$infrastructure_changed" == true ]]; then
        echo "all"
    elif [[ "$nestjs_changed" == true ]]; then
        echo "nestjs"
    elif [[ "$infrastructure_changed" == true || "$monitoring_changed" == true ]]; then
        echo "infrastructure"
    else
        echo "quick"
    fi
}

# Esegui test strategy
run_tests() {
    local strategy="${1:-auto}"
    
    if [[ "$strategy" == "auto" ]]; then
        strategy=$(determine_tests)
    fi
    
    echo "🧪 EXECUTING TEST STRATEGY: $strategy"
    echo ""
    
    case "$strategy" in
        "all")
            echo "🚀 Running FULL test suite (NestJS + Infrastructure changes detected)"
            npm run test:all
            ;;
        "nestjs")
            echo "🚀 Running NESTJS test suite"
            npm run test
            npm run test:e2e
            ;;
        "infrastructure") 
            echo "🏗️ Running INFRASTRUCTURE test suite"
            npm run test:infrastructure
            npm run test:monitoring
            ;;
        "quick")
            echo "⚡ Running QUICK health checks (docs/config changes only)"
            npm run health:nestjs
            npm run health:infrastructure
            ;;
        *)
            echo "❌ Unknown test strategy: $strategy"
            exit 1
            ;;
    esac
}

# =============================================================================
# MAIN
# =============================================================================

main() {
    local command="${1:-analyze}"
    shift
    
    case "$command" in
        "analyze")
            analyze_changes "$@"
            ;;
        "determine")
            determine_tests "$@"
            ;;
        "run")
            run_tests "$@"
            ;;
        *)
            echo "Usage: $0 {analyze|determine|run} [comparison]"
            echo ""
            echo "Commands:"
            echo "  analyze   - Analyze changed files and categorize"
            echo "  determine - Determine optimal test strategy"
            echo "  run       - Run tests based on strategy"
            echo ""
            echo "Examples:"
            echo "  $0 analyze HEAD~1     # Analyze changes since last commit"
            echo "  $0 determine          # Get recommended test strategy"
            echo "  $0 run nestjs         # Run only NestJS tests"
            echo "  $0 run auto           # Auto-detect and run appropriate tests"
            exit 1
            ;;
    esac
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
