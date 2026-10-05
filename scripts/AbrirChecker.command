#!/bin/zsh
set -e

cd "$(dirname "$0")/.."
if [[ -d /Applications/Xcode.app/Contents/Developer ]]; then
    export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
fi

swift build --product swift-accessibility-checker-gui

binary="$(swift build --show-bin-path)/swift-accessibility-checker-gui"
app="$HOME/Applications/Swift Accessibility Checker.app"
mkdir -p "$app/Contents/MacOS"
cp "$binary" "$app/Contents/MacOS/SwiftAccessibilityChecker"

cat > "$app/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key><string>pt_BR</string>
    <key>CFBundleDisplayName</key><string>Swift Accessibility Checker</string>
    <key>CFBundleExecutable</key><string>SwiftAccessibilityChecker</string>
    <key>CFBundleIdentifier</key><string>com.rafaeltoneto.SwiftAccessibilityChecker</string>
    <key>CFBundleInfoDictionaryVersion</key><string>6.0</string>
    <key>CFBundleName</key><string>Swift Accessibility Checker</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleShortVersionString</key><string>1.0</string>
    <key>CFBundleVersion</key><string>1</string>
    <key>LSApplicationCategoryType</key><string>public.app-category.developer-tools</string>
    <key>LSMinimumSystemVersion</key><string>13.0</string>
    <key>NSHighResolutionCapable</key><true/>
</dict>
</plist>
PLIST

codesign --force --sign - "$app"
open "$app"
