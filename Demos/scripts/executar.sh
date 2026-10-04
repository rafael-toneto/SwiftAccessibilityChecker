#!/bin/bash
# Usa um simulador exclusivo para a demonstração; não apaga dados de outros devices.
set -euo pipefail
source "$(dirname "$0")/ambiente.sh"
APP="${1:-ListaCompras}"
VARIANT="${2:-ComProblemas}"
case "$APP" in ListaCompras|LeituraFacil|MinhaRotina) ;; *) echo 'App: ListaCompras, LeituraFacil ou MinhaRotina' >&2; exit 64;; esac
case "$VARIANT" in ComProblemas|Corrigido) ;; *) echo 'Versão: ComProblemas ou Corrigido' >&2; exit 64;; esac
PRODUCT="$TEST_CASES_DIR/.DerivedData/Build/Products/Debug-iphonesimulator/$APP-$VARIANT.app"
if [[ ! -d "$PRODUCT" ]]; then
    echo 'Compile os apps primeiro: ./scripts/preparar.sh' >&2
    exit 1
fi
DEVICE="$(python3 "$TEST_CASES_DIR/scripts/simulador.py")"
xcrun simctl bootstatus "$DEVICE" -b
xcrun simctl install "$DEVICE" "$PRODUCT"
BUNDLE_ID="$(/usr/libexec/PlistBuddy -c 'Print CFBundleIdentifier' "$PRODUCT/Info.plist")"
xcrun simctl launch --terminate-running-process "$DEVICE" "$BUNDLE_ID"
echo "Aberto: $APP — $VARIANT (SAC Demo)"

XCODE_DEVELOPER="${DEVELOPER_DIR:-$(xcode-select -p)}"
if [[ -d "$XCODE_DEVELOPER/Applications/Simulator.app" ]]; then
    open -a "$XCODE_DEVELOPER/Applications/Simulator.app" --args -CurrentDeviceUDID "$DEVICE"
elif [[ -d "$XCODE_DEVELOPER/../Applications/Simulator.app" ]]; then
    open -a "$XCODE_DEVELOPER/../Applications/Simulator.app" --args -CurrentDeviceUDID "$DEVICE"
elif [[ -d "$XCODE_DEVELOPER/../Applications/DeviceHub.app" ]]; then
    open -a "$XCODE_DEVELOPER/../Applications/DeviceHub.app"
    echo 'No DeviceHub do Xcode 27, selecione SAC Demo para visualizar o iPhone.'
else
    echo 'App executado. Abra o simulador SAC Demo pela interface do Xcode.'
fi
