#!/bin/bash
# Compartilhado pelos comandos; não muda o xcode-select global.
set -euo pipefail
TEST_CASES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CHECKER_DIR="$(cd "$TEST_CASES_DIR/.." && pwd)"
if [[ -z "${DEVELOPER_DIR:-}" ]] && ! xcodebuild -version >/dev/null 2>&1; then
    export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
fi
if ! xcodebuild -version >/dev/null 2>&1; then
    echo 'Xcode completo não encontrado. Defina DEVELOPER_DIR para o Xcode instalado.' >&2
    exit 1
fi
mkdir -p "$TEST_CASES_DIR/Reports"
