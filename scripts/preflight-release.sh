#!/bin/bash
set -euo pipefail

# Wrangle — Release Pre-flight Gate
# Verifies six prerequisites before running build-release.sh / create-dmg.sh:
#   1. Developer ID Application certificate present in Keychain
#   2. Certificate's Team ID matches the locked Wrangle team
#   3. Certificate not expired
#   4. notarytool keychain profile configured
#   5. Working tree is clean (no uncommitted changes)
#   6. MARKETING_VERSION matches the expected release version
#
# Exits 0 with "All pre-flight checks passed. Ready to build." when every
# gate passes. Exits 1 with "FAIL: <message>" and an actionable next step
# on the first failure.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

NOTARY_PROFILE="wrangle-notary"
TEAM_ID="3DEKQ7GUK6"
EXPECTED_VERSION="1.3.0"

echo "==> Checking Developer ID Application certificate in Keychain..."
if ! security find-identity -v -p codesigning | grep -q "Developer ID Application"; then
    echo "FAIL: No 'Developer ID Application' identity in Keychain."
    echo "      Set up: https://developer.apple.com/account → Certificates → Developer ID Application"
    exit 1
fi

if ! security find-identity -v -p codesigning | grep -q "$TEAM_ID"; then
    echo "FAIL: Developer ID Application identity for Team $TEAM_ID not found."
    echo "      Verify the cert belongs to the expected team via:"
    echo "        security find-identity -v -p codesigning"
    exit 1
fi

echo "==> Checking certificate is not expired..."
CERT_ENDDATE=$(security find-certificate -c "Developer ID Application" -p | \
    openssl x509 -enddate -noout 2>/dev/null | cut -d= -f2)
if [[ -z "$CERT_ENDDATE" ]]; then
    echo "WARN: Could not parse cert expiry date — proceed with caution."
else
    EXPIRY_EPOCH=$(date -j -f "%b %d %T %Y %Z" "$CERT_ENDDATE" "+%s" 2>/dev/null || echo "0")
    NOW_EPOCH=$(date "+%s")
    if [[ "$EXPIRY_EPOCH" -lt "$NOW_EPOCH" ]]; then
        echo "FAIL: Developer ID Application certificate expired on $CERT_ENDDATE."
        echo "      Renew at https://developer.apple.com/account → Certificates"
        exit 1
    fi
    echo "  OK — cert valid until $CERT_ENDDATE"
fi

echo "==> Checking notarytool keychain profile '$NOTARY_PROFILE' is configured..."
if ! xcrun notarytool history --keychain-profile "$NOTARY_PROFILE" > /dev/null 2>&1; then
    echo "FAIL: notarytool profile '$NOTARY_PROFILE' not configured."
    echo "      Set up: xcrun notarytool store-credentials $NOTARY_PROFILE"
    echo "              (prompts for Apple ID, app-specific password, Team ID)"
    exit 1
fi

echo "==> Checking working tree is clean..."
if [[ -n "$(git -C "$PROJECT_DIR" status --porcelain)" ]]; then
    echo "FAIL: Working tree has uncommitted changes. Commit or stash before releasing."
    git -C "$PROJECT_DIR" status --short
    exit 1
fi

echo "==> Checking MARKETING_VERSION matches expected ($EXPECTED_VERSION)..."
# Main app target has Debug + Release build configs, so MARKETING_VERSION = $EXPECTED_VERSION;
# must appear exactly 2 times. WrangleTests target has its own MARKETING_VERSION (currently 1.0)
# so grep -m1 cannot be used to extract the shipping version reliably.
EXPECTED_MV_COUNT=2
ACTUAL_MV_COUNT=$(grep -c "MARKETING_VERSION = $EXPECTED_VERSION;" "$PROJECT_DIR/Wrangle.xcodeproj/project.pbxproj" || true)
if [[ "$ACTUAL_MV_COUNT" -ne "$EXPECTED_MV_COUNT" ]]; then
    echo "FAIL: MARKETING_VERSION = $EXPECTED_VERSION found $ACTUAL_MV_COUNT time(s), expected $EXPECTED_MV_COUNT (Debug + Release on the main Wrangle target)."
    echo "      Run: bash scripts/bump-version.sh $EXPECTED_VERSION"
    exit 1
fi

echo ""
echo "All pre-flight checks passed. Ready to build."
