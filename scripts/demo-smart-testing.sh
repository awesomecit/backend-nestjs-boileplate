#!/bin/bash

# scripts/demo-smart-testing.sh
# Script per dimostrare il funzionamento del sistema di test intelligenti

set -e

echo "🎯 DEMO: Sistema di Test Intelligenti Husky"
echo "=========================================="
echo

# 1. Analisi file correnti
echo "📊 1. ANALISI FILE MODIFICATI (ultimi cambiamenti):"
echo "----------------------------------------------------"
./scripts/smart-test-selector.sh analyze HEAD~1
echo

# 2. Strategia raccommandata
echo "🤖 2. STRATEGIA TEST RACCOMANDATA:"
echo "----------------------------------"
strategy=$(./scripts/smart-test-selector.sh determine)
echo "Strategia rilevata: $strategy"
echo

# 3. Spiegazione strategia
echo "💡 3. SPIEGAZIONE STRATEGIA:"
echo "----------------------------"
case "$strategy" in
    "all")
        echo "🎯 FULL SUITE - Rilevati cambiamenti sia NestJS che Infrastructure"
        echo "   → Esegue: npm run test:all"
        echo "   → Include: Unit tests + E2E + BATS infrastructure + Monitoring"
        echo "   ⏱️ Tempo stimato: ~3-5 minuti"
        ;;
    "nestjs")
        echo "🚀 NESTJS SUITE - Rilevati solo cambiamenti NestJS"
        echo "   → Esegue: npm run test + npm run test:e2e"
        echo "   → Include: Unit tests + E2E tests"
        echo "   ⏱️ Tempo stimato: ~1-2 minuti"
        ;;
    "infrastructure")
        echo "🏗️ INFRASTRUCTURE SUITE - Rilevati cambiamenti infrastruttura"
        echo "   → Esegue: npm run test:infrastructure + npm run test:monitoring"
        echo "   → Include: BATS tests per Docker/Monitoring"
        echo "   ⏱️ Tempo stimato: ~2-3 minuti"
        ;;
    "quick")
        echo "⚡ HEALTH CHECKS - Solo documentazione/config modificati"
        echo "   → Esegue: npm run health"
        echo "   → Include: Health check base"
        echo "   ⏱️ Tempo stimato: ~30 secondi"
        ;;
esac
echo

# 4. Esempi di pattern matching
echo "🔍 4. PATTERN MATCHING RULES:"
echo "-----------------------------"
echo "📁 NestJS Files:"
echo "   ✅ src/**/*.ts"
echo "   ✅ test/unit/**/*.spec.ts"
echo "   ✅ test/e2e/**/*.ts"
echo "   ✅ jest.config.js, tsconfig.json"
echo
echo "🏗️ Infrastructure Files:"
echo "   ✅ deployment/**/*"
echo "   ✅ docker-compose*.yml"
echo "   ✅ scripts/**/*.sh"
echo "   ✅ test/infrastructure/**/*.bats"
echo
echo "📊 Monitoring Files:"
echo "   ✅ deployment/monitoring/**/*"
echo "   ✅ test/monitoring/**/*.bats"
echo "   ✅ grafana/**, prometheus/**"
echo

# 5. Comando per eseguire i test
echo "🚀 5. ESECUZIONE (OPZIONALE):"
echo "------------------------------"
echo "Per eseguire i test raccomandati, usa:"
echo "   npm run test:smart"
echo
echo "O manualmente:"
echo "   ./scripts/smart-test-selector.sh run $strategy"
echo

# 6. Test hook simulation
echo "🎭 6. SIMULAZIONE HOOK HUSKY:"
echo "-----------------------------"
echo "Pre-commit comportamento:"
case "$strategy" in
    "nestjs") echo "   → Esegue solo npm run test" ;;
    "infrastructure") echo "   → Esegue health checks" ;;
    "all") echo "   → Quick validation (test + health)" ;;
    "quick") echo "   → Skip tests (solo docs)" ;;
esac

echo "Pre-push comportamento:"
case "$strategy" in
    "nestjs") echo "   → Full NestJS suite (test + e2e)" ;;
    "infrastructure") echo "   → Full Infrastructure suite (BATS)" ;;
    "all") echo "   → Complete test suite" ;;
    "quick") echo "   → Health checks" ;;
esac

echo
echo "✅ Demo completata! Il sistema è pronto per l'uso."
