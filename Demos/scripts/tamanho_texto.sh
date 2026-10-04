#!/bin/bash
set -euo pipefail
source "$(dirname "$0")/ambiente.sh"
case "${1:-grande}" in
    normal) SIZE=large ;;
    grande) SIZE=accessibility-medium ;;
    maximo) SIZE=accessibility-extra-extra-extra-large ;;
    *) echo 'Uso: ./scripts/tamanho_texto.sh normal|grande|maximo' >&2; exit 64 ;;
esac
DEVICE="$(python3 "$TEST_CASES_DIR/scripts/simulador.py")"
xcrun simctl bootstatus "$DEVICE" -b
xcrun simctl ui "$DEVICE" content_size "$SIZE"
echo "Tamanho de texto no SAC Demo: $SIZE"
