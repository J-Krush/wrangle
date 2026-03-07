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

# Validate files exist
for f in "$PBXPROJ" "$ENV_FILE"; do
    if [[ ! -f "$f" ]]; then
        echo "Error: File not found: $f"
        exit 1
    fi
done

# Get current values from pbxproj
OLD_VERSION=$(grep -m1 'MARKETING_VERSION = ' "$PBXPROJ" | sed 's/.*= //;s/;.*//')
OLD_BUILD=$(grep -m1 'CURRENT_PROJECT_VERSION = ' "$PBXPROJ" | sed 's/.*= //;s/;.*//')
NEW_BUILD=$((OLD_BUILD + 1))

echo "Bumping version: $OLD_VERSION → $NEW_VERSION"
echo "Bumping build:   $OLD_BUILD → $NEW_BUILD"
echo ""

# 1. Update project.pbxproj
sed -i '' "s/MARKETING_VERSION = $OLD_VERSION;/MARKETING_VERSION = $NEW_VERSION;/g" "$PBXPROJ"
sed -i '' "s/CURRENT_PROJECT_VERSION = $OLD_BUILD;/CURRENT_PROJECT_VERSION = $NEW_BUILD;/g" "$PBXPROJ"
echo "✓ project.pbxproj — MARKETING_VERSION and CURRENT_PROJECT_VERSION updated"

# 2. Update Landing Page .env
sed -i '' "s/APP_VERSION=.*/APP_VERSION=$NEW_VERSION/" "$ENV_FILE"
echo "✓ .env — APP_VERSION updated to $NEW_VERSION"

echo ""
echo "Done! Verify with:"
echo "  grep MARKETING_VERSION wrangle.xcodeproj/project.pbxproj"
echo "  grep CURRENT_PROJECT_VERSION wrangle.xcodeproj/project.pbxproj"
echo "  cat \"../Landing Page/.env\""
