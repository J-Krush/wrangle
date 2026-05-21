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

echo "==> Notarizing..."
xcrun notarytool submit "$APP_PATH" \
    --keychain-profile "$NOTARY_PROFILE" \
    --wait

echo "==> Stapling..."
xcrun stapler staple "$APP_PATH"

echo "==> Verifying..."
spctl --assess --type exec --verbose "$APP_PATH"

echo ""
echo "Build complete: $APP_PATH"
echo "Run scripts/create-dmg.sh to package as DMG."
