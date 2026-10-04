#!/bin/bash
# Aquece o cache do plugin e compila os seis apps para o simulador.
set -euo pipefail
source "$(dirname "$0")/ambiente.sh"
for APP in ListaCompras LeituraFacil MinhaRotina; do
    for VARIANT in ComProblemas Corrigido; do
        SCHEME="$APP-$VARIANT"
        LOG="$TEST_CASES_DIR/Reports/build-$SCHEME.log"
        echo "Compilando ${SCHEME}…"
        if ! xcodebuild -workspace "$TEST_CASES_DIR/Demo.xcworkspace" -scheme "$SCHEME" \
            -configuration Debug -destination 'generic/platform=iOS Simulator' \
            -derivedDataPath "$TEST_CASES_DIR/.DerivedData" CODE_SIGNING_ALLOWED=NO build > "$LOG" 2>&1; then
            tail -80 "$LOG" >&2
            exit 1
        fi
        # Somente os avisos do checker: os demais ficam no log completo.
        grep -E 'warning:.*\[SAC[0-9]+\]' "$LOG" || true
        echo "Build OK: $SCHEME"
    done
done
echo 'Seis apps compilados. Execute ./scripts/executar.sh ListaCompras ComProblemas'
