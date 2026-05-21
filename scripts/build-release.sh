#!/bin/bash
set -euo pipefail

# Wrangle — Build, Notarize, and Staple
# Prerequisites:
#   - Developer ID Application certificate installed
#   - App-specific password stored: xcrun notarytool store-credentials "wrangle-notary"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
SCHEME="Wrangle"
ARCHIVE_PATH="$PROJECT_DIR/build/Wrangle.xcarchive"
EXPORT_PATH="$PROJECT_DIR/build/export"
EXPORT_OPTIONS="$PROJECT_DIR/ExportOptions.plist"
APP_PATH="$EXPORT_PATH/Wrangle.app"
NOTARY_PROFILE="wrangle-notary"

echo "==> Pre-flight: running preflight-release.sh..."
"$SCRIPT_DIR/preflight-release.sh"

echo "==> Cleaning build directory..."
rm -rf "$PROJECT_DIR/build"
mkdir -p "$PROJECT_DIR/build"

echo "==> Archiving..."
xcodebuild archive \
    -project "$PROJECT_DIR/Wrangle.xcodeproj" \
    -scheme "$SCHEME" \
    -archivePath "$ARCHIVE_PATH" \
    -configuration Release \
    CODE_SIGN_IDENTITY="Developer ID Application" \
    DEVELOPMENT_TEAM=3DEKQ7GUK6 \
    | xcpretty || xcodebuild archive \
    -project "$PROJECT_DIR/Wrangle.xcodeproj" \
    -scheme "$SCHEME" \
    -archivePath "$ARCHIVE_PATH" \
    -configuration Release \
    CODE_SIGN_IDENTITY="Developer ID Application" \
    DEVELOPMENT_TEAM=3DEKQ7GUK6

echo "==> Exporting archive..."
xcodebuild -exportArchive \
    -archivePath "$ARCHIVE_PATH" \
    -exportPath "$EXPORT_PATH" \
    -exportOptionsPlist "$EXPORT_OPTIONS"

# Belt-and-suspenders: confirm xcodebuild's automatic signing picked a cert
# for the expected team. DEVELOPMENT_TEAM=3DEKQ7GUK6 above narrows by team
# during xcodebuild, but a post-export assertion catches the multi-cert
# edge case where two Developer ID Application certs for the same team
# both exist (parallel renewal, etc.).
if ! codesign -dv --verbose=4 "$APP_PATH" 2>&1 | grep -q "TeamIdentifier=3DEKQ7GUK6"; then
    echo "FAIL: $APP_PATH signature does not carry the expected TeamIdentifier=3DEKQ7GUK6."
    echo "      Inspect with: codesign -dv --verbose=4 $APP_PATH"
    exit 1
fi

echo "==> Zipping .app for notarytool submission..."
# notarytool only accepts .zip, .pkg, or .dmg — never a raw .app bundle.
# ditto -c -k --sequesterRsrc --keepParent is Apple's documented pattern
# for producing a notarization-compatible zip that preserves bundle metadata.
ZIP_FOR_NOTARY="$EXPORT_PATH/Wrangle.zip"
rm -f "$ZIP_FOR_NOTARY"
/usr/bin/ditto -c -k --sequesterRsrc --keepParent "$APP_PATH" "$ZIP_FOR_NOTARY"

echo "==> Notarizing..."
xcrun notarytool submit "$ZIP_FOR_NOTARY" \
    --keychain-profile "$NOTARY_PROFILE" \
    --wait

echo "==> Stapling..."
# Staple to the .app (not the zip — stapler cannot attach a ticket to a zip).
# The zip was only the submission vehicle; the .app retains the stapled ticket.
xcrun stapler staple "$APP_PATH"
rm -f "$ZIP_FOR_NOTARY"

echo "==> Verifying..."
spctl --assess --type exec --verbose "$APP_PATH"

echo ""
echo "Build complete: $APP_PATH"
echo "Run scripts/create-dmg.sh to package as DMG."
