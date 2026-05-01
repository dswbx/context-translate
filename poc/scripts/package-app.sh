#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

APP_NAME="Context Translate POC"
BUNDLE_ID="dev.contexttranslate.poc"
EXECUTABLE_NAME="context-translate-poc"
CONFIGURATION="${CONFIGURATION:-release}"
APP_OUTPUT_DIR="$ROOT_DIR/dist"
APP_PATH="$APP_OUTPUT_DIR/$APP_NAME.app"
CONTENTS_DIR="$APP_PATH/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"
BUILT_EXECUTABLE="$ROOT_DIR/.build/$CONFIGURATION/$EXECUTABLE_NAME"

cd "$ROOT_DIR"

echo "Building $EXECUTABLE_NAME ($CONFIGURATION)..."
swift build -c "$CONFIGURATION"

echo "Creating $APP_PATH..."
rm -rf "$APP_PATH"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"
cp "$BUILT_EXECUTABLE" "$MACOS_DIR/$EXECUTABLE_NAME"
chmod +x "$MACOS_DIR/$EXECUTABLE_NAME"

cat > "$CONTENTS_DIR/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>en</string>
  <key>CFBundleDisplayName</key>
  <string>$APP_NAME</string>
  <key>CFBundleExecutable</key>
  <string>$EXECUTABLE_NAME</string>
  <key>CFBundleIdentifier</key>
  <string>$BUNDLE_ID</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundleName</key>
  <string>$APP_NAME</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>0.1.0</string>
  <key>CFBundleVersion</key>
  <string>0.1.0</string>
  <key>LSMinimumSystemVersion</key>
  <string>13.0</string>
  <key>LSUIElement</key>
  <true/>
  <key>NSPrincipalClass</key>
  <string>NSApplication</string>
</dict>
</plist>
PLIST

if command -v codesign >/dev/null 2>&1; then
  if codesign --force --sign - "$APP_PATH" >/dev/null 2>&1; then
    echo "Ad-hoc signed app bundle."
  else
    echo "Warning: ad-hoc signing failed. The app bundle was still created."
  fi
fi

echo
echo "Created: $APP_PATH"
echo "Open it with:"
echo "  open \"$APP_PATH\""
echo
echo "This is an interim local bundle, not a notarized production release."
