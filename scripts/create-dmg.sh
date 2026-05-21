#!/bin/bash
set -euo pipefail

# Wrangle — Create DMG
# Run after build-release.sh has produced a stapled .app

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
EXPORT_PATH="$PROJECT_DIR/build/export"
APP_PATH="$EXPORT_PATH/Wrangle.app"
DMG_DIR="$PROJECT_DIR/build/dmg"
DMG_NAME="Wrangle"
DMG_PATH="$PROJECT_DIR/build/${DMG_NAME}.dmg"

if [ ! -d "$APP_PATH" ]; then
    echo "Error: $APP_PATH not found. Run build-release.sh first."
    exit 1
fi

# Get version from the built app
VERSION=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "$APP_PATH/Contents/Info.plist")
DMG_FINAL="$PROJECT_DIR/build/Wrangle-${VERSION}.dmg"

echo "==> Preparing DMG staging area..."
rm -rf "$DMG_DIR"
mkdir -p "$DMG_DIR"
cp -R "$APP_PATH" "$DMG_DIR/"
ln -s /Applications "$DMG_DIR/Applications"

echo "==> Creating DMG..."
rm -f "$DMG_PATH"

# Check if create-dmg is available (brew install create-dmg)
if command -v create-dmg &>/dev/null; then
    create-dmg \
        --volname "$DMG_NAME" \
        --volicon "$APP_PATH/Contents/Resources/AppIcon.icns" \
        --window-pos 200 120 \
        --window-size 600 400 \
        --icon-size 100 \
        --icon "Wrangle.app" 150 190 \
        --icon "Applications" 450 190 \
        --hide-extension "Wrangle.app" \
        --app-drop-link 450 190 \
        "$DMG_FINAL" \
        "$DMG_DIR"
else
    echo "    (create-dmg not found, using hdiutil)"
    hdiutil create \
        -volname "$DMG_NAME" \
        -srcfolder "$DMG_DIR" \
        -ov \
        -format UDZO \
        "$DMG_FINAL"
fi

echo "==> Signing DMG..."
# REL-04 / D-02: DMG must carry a primary signature for
#   spctl -a -t open --context context:primary-signature to pass.
# Long-form identity pins to Team 3DEKQ7GUK6 to avoid silent multi-cert
# ambiguity. `codesign --sign "Developer ID Application"` does a substring
# match against the Keychain — if a renewal-in-parallel or org-shared Mac
# has two Developer ID Application certs, the wrong one could sign silently.
codesign --sign "Developer ID Application: John Kreisher (3DEKQ7GUK6)" \
    --timestamp \
    --options runtime \
    "$DMG_FINAL"

# Belt-and-suspenders: assert the signature carries the expected Team ID.
# Fails the script before notarytool submission if codesign somehow picked
# a different identity (e.g. expired long-form identity, Keychain glitch).
if ! codesign -dv --verbose=4 "$DMG_FINAL" 2>&1 | grep -q "TeamIdentifier=3DEKQ7GUK6"; then
    echo "FAIL: DMG signature does not carry the expected TeamIdentifier=3DEKQ7GUK6."
    echo "      Inspect with: codesign -dv --verbose=4 $DMG_FINAL"
    exit 1
fi

echo "==> Notarizing DMG..."
xcrun notarytool submit "$DMG_FINAL" \
    --keychain-profile "wrangle-notary" \
    --wait

echo "==> Stapling DMG..."
xcrun stapler staple "$DMG_FINAL"

echo ""
echo "DMG ready: $DMG_FINAL"

echo "==> Verifying DMG (REL-04 canonical check)..."
spctl -a -t open --context context:primary-signature -v "$DMG_FINAL"
# Expected output: <dmg>: accepted  /  source=Notarized Developer ID

# Clean up staging
rm -rf "$DMG_DIR"
