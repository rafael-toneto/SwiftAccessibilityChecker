#!/bin/zsh
set -e

cd "$(dirname "$0")/.."
if [[ -d /Applications/Xcode.app/Contents/Developer ]]; then
    export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
fi

exec swift run swift-accessibility-checker-gui
