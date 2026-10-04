#!/bin/bash
# Reexecuta o checker real e verifica cobertura, contagens e isolamento dos targets.
set -euo pipefail
source "$(dirname "$0")/ambiente.sh"
echo 'Compilando o SwiftAccessibilityChecker…'
swift build --package-path "$CHECKER_DIR" --product swift-accessibility-checker > "$TEST_CASES_DIR/Reports/checker-build.log" 2>&1 || {
    cat "$TEST_CASES_DIR/Reports/checker-build.log" >&2
    exit 1
}
CHECKER_BIN="$(swift build --package-path "$CHECKER_DIR" --show-bin-path)/swift-accessibility-checker"
python3 "$TEST_CASES_DIR/scripts/verificar_resultados.py" "$CHECKER_BIN"
echo
echo 'Para abrir a comparação dos seis relatórios no navegador:'
printf 'open "%s/Reports/index.html"\n' "$TEST_CASES_DIR"
