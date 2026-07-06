#!/bin/bash
set -euo pipefail

# Bump version across all project files
# Usage: ./scripts/bump-version.sh 1.0.6

NEW_VERSION="${1:-}"
if [[ -z "$NEW_VERSION" ]]; then
    echo "Usage: $0 <version>"
    echo "Example: $0 1.0.6"
    exit 1
fi

# Resolve paths relative to repo root (one level up from scripts/)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

PBXPROJ="$REPO_ROOT/wrangle.xcodeproj/project.pbxproj"
ENV_FILE="$REPO_ROOT/../Landing Page/.env"
PREFLIGHT="$REPO_ROOT/scripts/preflight-release.sh"

# Validate required files exist. The landing-page .env lives outside this repo
# (a sibling checkout) and is absent on CI runners, so it is optional.
for f in "$PBXPROJ" "$PREFLIGHT"; do
    if [[ ! -f "$f" ]]; then
        echo "Error: File not found: $f"
        exit 1
    fi
done

# Get current values from the MAIN app target specifically. Build settings are
# alphabetized, so within each config block CURRENT_PROJECT_VERSION and
# MARKETING_VERSION precede PRODUCT_BUNDLE_IDENTIFIER; we latch the last-seen
# pair and emit it when the app's bundle id appears. Reading the first match in
# the file instead would pick up the WrangleTests target (which sits earlier in
# the file and is intentionally pinned at 1.0 / build 1), silently bumping the
# wrong target — see docs/release-checklist.md.
APP_BUNDLE_ID="com.krush.wrangle"
read -r OLD_VERSION OLD_BUILD < <(awk -v id="$APP_BUNDLE_ID" '
    /CURRENT_PROJECT_VERSION = /{b=$3; gsub(/;/,"",b)}
    /MARKETING_VERSION = /{v=$3; gsub(/;/,"",v)}
    $0 ~ ("PRODUCT_BUNDLE_IDENTIFIER = " id ";"){print v, b; exit}
' "$PBXPROJ")

if [[ -z "${OLD_VERSION:-}" || -z "${OLD_BUILD:-}" ]]; then
    echo "Error: could not read current version/build for app target ($APP_BUNDLE_ID) from $PBXPROJ"
    exit 1
fi
NEW_BUILD=$((OLD_BUILD + 1))

echo "Bumping version: $OLD_VERSION → $NEW_VERSION"
echo "Bumping build:   $OLD_BUILD → $NEW_BUILD"
echo ""

# 1. Update project.pbxproj
sed -i '' "s/MARKETING_VERSION = $OLD_VERSION;/MARKETING_VERSION = $NEW_VERSION;/g" "$PBXPROJ"
sed -i '' "s/CURRENT_PROJECT_VERSION = $OLD_BUILD;/CURRENT_PROJECT_VERSION = $NEW_BUILD;/g" "$PBXPROJ"
echo "✓ project.pbxproj — MARKETING_VERSION and CURRENT_PROJECT_VERSION updated"

# Sanity-check: the app target has exactly 2 configs (Debug + Release), so the
# new version/build must appear exactly twice. More means the global sed also
# hit the test target (e.g. it shared the old version); fail loudly rather than
# ship a corrupted project.
MV_COUNT=$(grep -c "MARKETING_VERSION = $NEW_VERSION;" "$PBXPROJ")
CV_COUNT=$(grep -c "CURRENT_PROJECT_VERSION = $NEW_BUILD;" "$PBXPROJ")
if [[ "$MV_COUNT" -ne 2 || "$CV_COUNT" -ne 2 ]]; then
    echo "Error: expected the app target's version/build to appear exactly twice each"
    echo "       (MARKETING_VERSION=$NEW_VERSION: $MV_COUNT, CURRENT_PROJECT_VERSION=$NEW_BUILD: $CV_COUNT)."
    echo "       The test target may have shared the old value and been bumped too."
    echo "       Review $PBXPROJ before committing."
    exit 1
fi

# 2. Update Landing Page .env (skip if the sibling checkout isn't present, e.g. CI)
if [[ -f "$ENV_FILE" ]]; then
    sed -i '' "s/APP_VERSION=.*/APP_VERSION=$NEW_VERSION/" "$ENV_FILE"
    echo "✓ .env — APP_VERSION updated to $NEW_VERSION"
else
    echo "• .env not found (${ENV_FILE}) — skipping landing-page version update"
fi

# 3. Update preflight-release.sh EXPECTED_VERSION so the release gate matches
sed -i '' "s/^EXPECTED_VERSION=\".*\"/EXPECTED_VERSION=\"$NEW_VERSION\"/" "$PREFLIGHT"
echo "✓ preflight-release.sh — EXPECTED_VERSION updated to $NEW_VERSION"

echo ""
echo "Done! Verify with:"
echo "  grep MARKETING_VERSION wrangle.xcodeproj/project.pbxproj"
echo "  grep CURRENT_PROJECT_VERSION wrangle.xcodeproj/project.pbxproj"
echo "  cat \"../Landing Page/.env\""
echo ""
echo "⚠️  Remember: Update APP_VERSION in Vercel environment variables to $NEW_VERSION"
echo "   Vercel Dashboard → Landing Page project → Settings → Environment Variables → APP_VERSION"
