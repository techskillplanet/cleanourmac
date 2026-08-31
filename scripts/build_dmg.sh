#!/bin/bash
# Builds Mac Tool.app and packages it as a DMG.
# Requirements: Flutter, Xcode, hdiutil (macOS built-in)
# Usage: bash scripts/build_dmg.sh

set -euo pipefail
export LANG=en_US.UTF-8
export DEVELOPER_DIR=/Volumes/outmount/Applications/Xcode.app/Contents/Developer

APP_NAME="Mac Tool"
BUNDLE_NAME="Mac Tool.app"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$PROJECT_DIR/build"
RELEASE_DIR="$BUILD_DIR/macos/Build/Products/Release"
APP_PATH="$RELEASE_DIR/$BUNDLE_NAME"
DMG_OUT="$BUILD_DIR/Mac-Tool.dmg"
TMP_DMG="$BUILD_DIR/tmp.dmg"

echo "==> Building Flutter release..."
cd "$PROJECT_DIR"
flutter build macos --release

if [ ! -d "$APP_PATH" ]; then
  echo "ERROR: $APP_PATH not found after build"
  exit 1
fi

echo "==> Signing ad-hoc (no Apple Developer cert)..."
codesign --force --deep --sign - "$APP_PATH"
xattr -cr "$APP_PATH"

echo "==> Creating staging area..."
STAGE=$(mktemp -d)
cp -R "$APP_PATH" "$STAGE/"
ln -s /Applications "$STAGE/Applications"

echo "==> Creating read-write DMG..."
hdiutil create \
  -srcfolder "$STAGE" \
  -volname "$APP_NAME" \
  -fs HFS+ \
  -format UDRW \
  -ov "$TMP_DMG"

echo "==> Attaching for cosmetic setup..."
DEV=$(hdiutil attach -readwrite -noverify -noautoopen "$TMP_DMG" \
  | awk '/Apple_HFS/{print $1; exit}')

# Set icon size via AppleScript if available
if [ -f "$SCRIPT_DIR/dmg_window.applescript" ]; then
  osascript "$SCRIPT_DIR/dmg_window.applescript" "$APP_NAME" 2>/dev/null || true
fi

sync
hdiutil detach "$DEV"

echo "==> Compressing to final DMG..."
rm -f "$DMG_OUT"
hdiutil convert "$TMP_DMG" -format UDZO -imagekey zlib-level=9 -o "$DMG_OUT"
rm -f "$TMP_DMG"
rm -rf "$STAGE"

echo ""
echo "✓ DMG ready: $DMG_OUT"
echo ""
echo "--- IMPORTANT: Gatekeeper Note ---"
echo "This DMG is ad-hoc signed (no Apple Developer cert)."
echo "Users must right-click → Open, or run:"
echo "  xattr -dr com.apple.quarantine \"/Applications/$BUNDLE_NAME\""
echo "After each update, re-grant Full Disk Access in:"
echo "  System Settings → Privacy & Security → Full Disk Access"
