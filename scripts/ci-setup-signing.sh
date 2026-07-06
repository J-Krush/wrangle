#!/bin/bash
set -euo pipefail

# Recreate, on a CI runner, the local Keychain state the release scripts
# expect: a Developer ID Application identity available to codesign, and a
# `wrangle-notary` notarytool credential profile. This lets build-release.sh,
# create-dmg.sh, and preflight-release.sh run unmodified in CI.
#
# Required environment (wire these from GitHub Actions secrets):
#   BUILD_CERTIFICATE_BASE64  base64 of the exported Developer ID Application
#                             .p12 (certificate + private key)
#   P12_PASSWORD              password protecting that .p12
#   KEYCHAIN_PASSWORD         arbitrary password for the temporary keychain
#   NOTARY_APPLE_ID           Apple ID email used for notarization
#   NOTARY_PASSWORD           app-specific password for that Apple ID
#   NOTARY_TEAM_ID            Developer Team ID (3DEKQ7GUK6)
#
# Idempotent-ish: safe to run once per job on a fresh runner.

: "${BUILD_CERTIFICATE_BASE64:?missing}"
: "${P12_PASSWORD:?missing}"
: "${KEYCHAIN_PASSWORD:?missing}"
: "${NOTARY_APPLE_ID:?missing}"
: "${NOTARY_PASSWORD:?missing}"
: "${NOTARY_TEAM_ID:?missing}"

WORKDIR="${RUNNER_TEMP:-/tmp}"
KEYCHAIN="$WORKDIR/wrangle-signing.keychain-db"
CERT_P12="$WORKDIR/certificate.p12"

echo "==> Creating temporary keychain..."
# Remove any leftover from a previous run on a reused runner.
security delete-keychain "$KEYCHAIN" 2>/dev/null || true
security create-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN"
# Disable auto-lock/timeout so the keychain stays unlocked for the whole job.
security set-keychain-settings -lut 21600 "$KEYCHAIN"
security unlock-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN"

echo "==> Importing Developer ID Application certificate..."
echo "$BUILD_CERTIFICATE_BASE64" | base64 --decode > "$CERT_P12"
security import "$CERT_P12" \
    -P "$P12_PASSWORD" \
    -f pkcs12 \
    -k "$KEYCHAIN" \
    -T /usr/bin/codesign \
    -T /usr/bin/security \
    -T /usr/bin/productbuild
rm -f "$CERT_P12"

# Allow codesign to use the private key without an interactive prompt.
security set-key-partition-list \
    -S apple-tool:,apple:,codesign: \
    -s -k "$KEYCHAIN_PASSWORD" "$KEYCHAIN" >/dev/null

echo "==> Making the keychain default + searchable..."
# The release scripts call `security find-identity`, `codesign`, and
# `notarytool --keychain-profile` without an explicit --keychain, so the
# signing keychain must be in the search list AND the default keychain.
security list-keychains -d user -s "$KEYCHAIN" "$(security default-keychain -d user | tr -d ' \t"')"
security default-keychain -s "$KEYCHAIN"

echo "==> Verifying the identity is visible..."
security find-identity -v -p codesigning "$KEYCHAIN" | grep -q "Developer ID Application" \
    || { echo "FAIL: Developer ID Application identity not found after import"; exit 1; }

echo "==> Storing notarytool credentials as profile 'wrangle-notary'..."
# No --keychain flag: store-credentials writes to the default keychain (now the
# signing keychain), matching how the release scripts read the profile.
xcrun notarytool store-credentials "wrangle-notary" \
    --apple-id "$NOTARY_APPLE_ID" \
    --password "$NOTARY_PASSWORD" \
    --team-id "$NOTARY_TEAM_ID" >/dev/null

echo "==> Signing environment ready."
