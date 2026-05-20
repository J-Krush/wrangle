# Phase 16: Signed-DMG Release Pipeline — Pattern Map

**Mapped:** 2026-05-20
**Files analyzed:** 5 (3 modified, 2 created)
**Analogs found:** 5 / 5

This is a release-engineering, verify-and-fill-gaps phase. Every new/modified
file has a strong existing analog in `scripts/` or `docs/`. The dominant
"shared pattern" is the bash-script idiom used by all five existing
`scripts/*.sh` files (shebang + `set -euo pipefail` + `SCRIPT_DIR` +
`PROJECT_DIR`-relative paths). All patches MUST conform to it.

## File Classification

| File | Status | Role | Data Flow | Closest Analog | Match Quality |
|------|--------|------|-----------|----------------|---------------|
| `scripts/create-dmg.sh` | MODIFY | release-script | batch (codesign→notarize→staple→verify) | self (insert between L55 and L57) | exact (same file) |
| `scripts/build-release.sh` | MODIFY | release-script | batch (archive→export→notarize→staple) | self (prepend pre-flight block before L18) | exact (same file) |
| `docs/release-checklist.md` | MODIFY | release-doc | reference / runbook | self (append 6 sections; preserve existing 5) | exact (same file) |
| `scripts/preflight-release.sh` | CREATE | gate-script | sequential checks → exit 0/1 | `scripts/build-release.sh` (idiom) + `scripts/bump-version.sh` (arg-less validation pattern) | role-match (gate script) |
| `.planning/phases/16-signed-dmg-release-pipeline/release-notes-v1.3.0.md` | CREATE | release-notes | static markdown bullets | `wrangle/App/WhatsNewChangelog.swift` v1.3.0 entry (content reference); `docs/release-checklist.md` (markdown style) | content-source |

**Notes on the "live path" in `create-dmg.sh`:** Research §"Environment Availability" confirmed `create-dmg` (brew) is NOT installed on the build host, so the `hdiutil` branch (lines 47–55) is the live path. The D-02 codesign patch lands directly on the live execution branch, after the `if/else` block exits (between L55 and L57, before "Notarizing DMG"). The brew branch already supports `--identity` signing (per upstream `create-dmg` docs) and stays untouched.

## Pattern Assignments

### `scripts/create-dmg.sh` (release-script, batch) — D-02 PATCH

**Analog:** self. The patch sits between the existing `hdiutil create` block (lines 47–55) and the existing `xcrun notarytool submit` (lines 57–60).

**Shared script-prologue pattern** (lines 1–13 — preserve verbatim):
```bash
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
```

**Existing notarize+staple pattern** (lines 57–63 — the patch slots BEFORE these):
```bash
echo "==> Notarizing DMG..."
xcrun notarytool submit "$DMG_FINAL" \
    --keychain-profile "wrangle-notary" \
    --wait

echo "==> Stapling DMG..."
xcrun stapler staple "$DMG_FINAL"
```

**D-02 patch to INSERT** (between current line 55 and current line 57; verbatim from RESEARCH.md §"D-02 patch site"):
```bash
echo "==> Signing DMG..."
# REL-04 / D-02: DMG must carry a primary signature for
#   spctl -a -t open --context context:primary-signature to pass.
codesign --sign "Developer ID Application" \
    --timestamp \
    --options runtime \
    "$DMG_FINAL"
```

**REL-04 verification to INSERT** (after current line 66 `echo "DMG ready: ..."`, before line 69 cleanup):
```bash
echo "==> Verifying DMG (REL-04 canonical check)..."
spctl -a -t open --context context:primary-signature -v "$DMG_FINAL"
# Expected output: <dmg>: accepted  /  source=Notarized Developer ID
```

**Signing-identity short-vs-long form:** RESEARCH.md §"Note for planner" recommends the short form `"Developer ID Application"` (matches `CODE_SIGN_IDENTITY` on `build-release.sh` L28 + L35) for consistency. The long form `"Developer ID Application: John Kreisher (3DEKQ7GUK6)"` is acceptable as defensive multi-team disambiguation but not required.

**Error handling pattern** (already present at line 15–18 — DO NOT change):
```bash
if [ ! -d "$APP_PATH" ]; then
    echo "Error: $APP_PATH not found. Run build-release.sh first."
    exit 1
fi
```
The D-02 patch inherits `set -euo pipefail`: if `codesign` fails, the script exits non-zero. No additional error-handling code is needed beyond following the established idiom.

---

### `scripts/build-release.sh` (release-script, batch) — D-03 STRENGTHEN

**Analog:** self. The pre-flight gate block prepends before the existing `==> Cleaning build directory` (current line 18).

**Shared script-prologue pattern** (lines 1–16 — preserve verbatim):
```bash
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
```

**Existing xcpretty fallback pattern** (lines 22–36 — PRESERVE this idiom for any new xcodebuild invocation):
```bash
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
```

**D-03 pre-flight block to INSERT** (before current line 18 `==> Cleaning build directory`; sourced verbatim from RESEARCH.md §"Pre-flight credential gate" code example):
```bash
echo "==> Pre-flight: Developer ID Application cert in Keychain..."
if ! security find-identity -v -p codesigning | grep -q "Developer ID Application"; then
    echo "FAIL: No 'Developer ID Application' identity in Keychain."
    echo "      Set up: https://developer.apple.com/account → Certificates"
    exit 1
fi
if ! security find-identity -v -p codesigning | grep -q "3DEKQ7GUK6"; then
    echo "FAIL: Developer ID Application identity for Team 3DEKQ7GUK6 not found."
    exit 1
fi

echo "==> Pre-flight: notarytool keychain profile '$NOTARY_PROFILE'..."
if ! xcrun notarytool history --keychain-profile "$NOTARY_PROFILE" > /dev/null 2>&1; then
    echo "FAIL: notarytool profile '$NOTARY_PROFILE' not configured."
    echo "      Set up: xcrun notarytool store-credentials $NOTARY_PROFILE"
    exit 1
fi

echo "==> Pre-flight: working tree clean..."
if [[ -n "$(git -C "$PROJECT_DIR" status --porcelain)" ]]; then
    echo "FAIL: Working tree has uncommitted changes. Commit or stash first."
    git -C "$PROJECT_DIR" status --short
    exit 1
fi
```

**Planner option:** if the planner chooses to extract the pre-flight into the standalone `scripts/preflight-release.sh`, this block becomes a one-line invocation here: `"$SCRIPT_DIR/preflight-release.sh"`. Either path satisfies D-03.

---

### `docs/release-checklist.md` (release-doc, reference) — D-04 EXPAND IN PLACE

**Analog:** self. D-04 mandates "expand in place — no rename, no split." Preserve all 114 existing lines verbatim; add the 6 new sections without renumbering or rewriting the existing prose.

**Existing markdown-pattern conventions to follow:**

1. **Numbered top-level sections** (`## 1. Bump the bundle version` ... `## 5. Quick verification grep`) — new sections continue the numbering or get inserted as `## 2a. Prereqs`, `## 4a. DMG`, etc. RESEARCH.md and CONTEXT.md D-04 spec list the 6 new sections; planner picks ordering (recommended: insert new sections AFTER existing §3 "Build & smoke test" and BEFORE existing §4 "Tag the release on GitHub" so the doc reads linearly from version-bump → build → sign/notarize/staple → DMG → second-Mac verify → tag/draft Release).

2. **Code-fence language tags** — bash blocks use ` ```bash `, diff blocks use ` ```diff ` (see existing L20–25 for diff example, L29 / L78 / L93 for bash). Preserve.

3. **Per-section "Verify" or "Expected output" subsection** — every existing section ends with a verification command (L29, L57–67, L93–101). New sections MUST follow this pattern:
   - §"Build / sign / notarize / staple the .app" ends with `spctl --assess --type exec --verbose build/export/Wrangle.app` → expect `accepted`.
   - §"DMG packaging + DMG sign + notarize + staple" ends with the REL-04 locked command `spctl -a -t open --context context:primary-signature -v build/Wrangle-1.3.0.dmg` → expect `accepted` + `source=Notarized Developer ID`.
   - §"Draft GitHub Release" ends with `gh release view v1.3.0` → expect `Status: Draft`.

4. **Preserve "Why this checklist exists" footer verbatim** (lines 104–114). It's the Phase 13 drift-story narrative; CONTEXT.md `<code_context>` §Reusable Assets calls this out explicitly. Append new sections BEFORE the footer.

**Example excerpt for new §"Prereqs" section** (modeled on existing §1 Bump table style at L13–17):

```markdown
## 2. Prereqs

| Prereq | Verify | Set up if missing |
|--------|--------|-------------------|
| Developer ID Application cert in Keychain (Team `3DEKQ7GUK6`) | `security find-identity -v -p codesigning \| grep "Developer ID Application"` | https://developer.apple.com/account → Certificates → Developer ID Application |
| `wrangle-notary` keychain profile configured | `xcrun notarytool history --keychain-profile wrangle-notary` | `xcrun notarytool store-credentials wrangle-notary` (prompts for Apple ID, app-specific password, Team ID) |
| Xcode command-line tools | `xcode-select -p` | `xcode-select --install` |
```

**Example excerpt for new §"Draft GitHub Release" section** (sourced from RESEARCH.md §"Draft GH Release" code example):

```markdown
## 6. Draft the GitHub Release

```bash
# Pin the tag to the verified commit BEFORE drafting (Pattern 3a).
git tag v1.3.0
git push origin v1.3.0

gh release create v1.3.0 \
    --draft \
    --verify-tag \
    --title "v1.3.0" \
    --notes-file .planning/phases/16-signed-dmg-release-pipeline/release-notes-v1.3.0.md \
    build/Wrangle-1.3.0.dmg

gh release view v1.3.0
```

Expected: `gh release view` reports `Status: Draft` and lists `Wrangle-1.3.0.dmg` as an asset. The `--draft` flag is mandatory — **Phase 18 publishes**.
```

---

### `scripts/preflight-release.sh` (gate-script, sequential checks) — NEW

**Analog:** `scripts/build-release.sh` for the script-prologue idiom (shebang + `set -euo pipefail` + `SCRIPT_DIR` + `PROJECT_DIR`), and `scripts/bump-version.sh` for the "validate then fail with actionable message" pattern.

**Shared prologue to copy verbatim** (from `scripts/build-release.sh` lines 1–10, adapted):
```bash
#!/bin/bash
set -euo pipefail

# Wrangle — Pre-flight Release Gate
# Verifies all prerequisites for build-release.sh + create-dmg.sh.
# Exits 0 if all gates pass; exits 1 with actionable message on the first failure.
#
# Run before: scripts/build-release.sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
NOTARY_PROFILE="wrangle-notary"
TEAM_ID="3DEKQ7GUK6"
EXPECTED_VERSION="1.3.0"
```

**Fail-fast validation pattern to copy from `scripts/bump-version.sh` lines 7–12, 22–27** (arg/file validation idiom; shown for stylistic reference):
```bash
NEW_VERSION="${1:-}"
if [[ -z "$NEW_VERSION" ]]; then
    echo "Usage: $0 <version>"
    echo "Example: $0 1.0.6"
    exit 1
fi

# Validate files exist
for f in "$PBXPROJ" "$ENV_FILE"; do
    if [[ ! -f "$f" ]]; then
        echo "Error: File not found: $f"
        exit 1
    fi
done
```

**Full pre-flight body to write** (sourced verbatim from RESEARCH.md §"Pre-flight credential gate (Plan 1 Task 1 source material)" — already covers the 6 gates from RESEARCH.md §"Validation Architecture" §"Pre-execution gates"):

```bash
echo "==> Checking Developer ID Application certificate in Keychain..."
if ! security find-identity -v -p codesigning | grep -q "Developer ID Application"; then
    echo "FAIL: No 'Developer ID Application' identity in Keychain."
    echo "      Set up: https://developer.apple.com/account → Certificates → Developer ID Application"
    exit 1
fi

if ! security find-identity -v -p codesigning | grep -q "$TEAM_ID"; then
    echo "FAIL: Developer ID Application identity for Team $TEAM_ID not found."
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
        exit 1
    fi
    echo "  OK — cert valid until $CERT_ENDDATE"
fi

echo "==> Checking notarytool keychain profile '$NOTARY_PROFILE'..."
if ! xcrun notarytool history --keychain-profile "$NOTARY_PROFILE" > /dev/null 2>&1; then
    echo "FAIL: notarytool profile '$NOTARY_PROFILE' not configured."
    echo "      Set up: xcrun notarytool store-credentials $NOTARY_PROFILE"
    exit 1
fi

echo "==> Checking working tree is clean..."
if [[ -n "$(git -C "$PROJECT_DIR" status --porcelain)" ]]; then
    echo "FAIL: Working tree has uncommitted changes."
    git -C "$PROJECT_DIR" status --short
    exit 1
fi

echo "==> Checking MARKETING_VERSION matches expected ($EXPECTED_VERSION)..."
MV=$(grep -m1 'MARKETING_VERSION = ' "$PROJECT_DIR/Wrangle.xcodeproj/project.pbxproj" \
    | sed -E 's/.*= ([0-9.]+);.*/\1/')
if [[ "$MV" != "$EXPECTED_VERSION" ]]; then
    echo "FAIL: MARKETING_VERSION is '$MV', expected '$EXPECTED_VERSION'."
    exit 1
fi

echo ""
echo "All pre-flight checks passed. Ready to build."
```

**Permissions:** make executable: `chmod +x scripts/preflight-release.sh` (matches the +x bit on all other `scripts/*.sh`).

**Planner reminder:** Per RESEARCH.md §"Open Questions" #2, the planner's choice is "separate script vs inline in `build-release.sh`." This PATTERNS.md covers BOTH so the planner can pick either. If the planner picks "inline," skip this file and use the smaller pre-flight block under `build-release.sh` above (D-03 STRENGTHEN section). If the planner picks "separate," use this full body.

---

### `release-notes-v1.3.0.md` (release-notes, static markdown) — NEW

**Analog:** `wrangle/App/WhatsNewChangelog.swift` (Phase 13 v1.3.0 entry — content source for the narrative). Markdown style: match the existing `docs/release-checklist.md` formatting (terse, numbered/bulleted lists, no emojis per project conventions).

**Location:** `.planning/phases/16-signed-dmg-release-pipeline/release-notes-v1.3.0.md` (consumed by `gh release create --notes-file` in Plan 2; not shipped in the binary).

**Content guidance from CONTEXT.md (Claude's Discretion, "Release notes content"):**
- 4–6 bullets
- Lead with OSS-flip narrative (Wrangle is now MIT-licensed; free for everyone)
- Include v1.2 headline browser-support features (Browsers, Bookmarks, History, Downloads, Private Mode) so v1.3.0 reads as a cumulative product, not just "we removed the paywall"

**Skeleton structure to write** (planner fills in prose at write-time after consulting `wrangle/App/WhatsNewChangelog.swift` for the canonical wording):

```markdown
# Wrangle v1.3.0

Wrangle is now free and open source under the MIT License. The full source
tree, planning history, and release pipeline are public.

## What's new in v1.3.0

- Wrangle is now MIT-licensed and free for everyone — no license key required.
- (continue with 3–5 more bullets covering v1.2 browser-support features:
  Browsers, Bookmarks, History, Downloads, Private Mode, etc.)

## Download

Drag `Wrangle.app` from the mounted DMG to `/Applications`. The app is
signed with Apple's Developer ID and notarized — no right-click → Open
required.

Requires macOS 15 (Sequoia) or later on Apple Silicon.
```

**Constraint:** plain prose only — NO emojis, per global project CLAUDE.md ("Only use emojis if the user explicitly requests it").

---

## Shared Patterns

### Pattern A: Bash-script prologue (apply to all `scripts/*.sh` changes)

**Source:** `scripts/build-release.sh` lines 1–10; mirrored in `scripts/create-dmg.sh` lines 1–8 and `scripts/bump-version.sh` lines 1–16.

**Apply to:** Every script file in Phase 16 (`scripts/preflight-release.sh` new; `scripts/create-dmg.sh` patch preserves L1–13 verbatim; `scripts/build-release.sh` patch preserves L1–16 verbatim).

```bash
#!/bin/bash
set -euo pipefail

# Wrangle — <one-line purpose>
# <optional prerequisites>

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
```

**Why this matters:** `set -euo pipefail` is non-negotiable per CONTEXT.md `<code_context>` §"Established Patterns" — any new script that omits it deviates from the project standard. `SCRIPT_DIR` + `PROJECT_DIR` make scripts cwd-independent so they can be invoked from any directory (validation chains in release-checklist.md depend on this).

### Pattern B: xcpretty graceful fallback (apply to any new xcodebuild invocation)

**Source:** `scripts/build-release.sh` lines 22–36.

**Apply to:** Any new `xcodebuild` invocation Phase 16 adds. (Currently Phase 16 adds none — `create-dmg.sh` and `preflight-release.sh` don't invoke xcodebuild. This pattern is documented here for completeness because CONTEXT.md `<code_context>` §"Established Patterns" lists it as an invariant.)

```bash
xcodebuild <subcommand> <args...> \
    | xcpretty || xcodebuild <subcommand> <args...>
```

**Why this matters:** RESEARCH.md §"Environment Availability" confirms `xcpretty` is NOT installed on the build host. The `|| xcodebuild …` fallback runs the bare command when xcpretty pipe fails. Scripts work on any contributor's machine regardless of xcpretty install state.

### Pattern C: Fail-fast with actionable message (apply to all gate / validation logic)

**Source:** `scripts/create-dmg.sh` lines 15–18 (pre-condition check); `scripts/bump-version.sh` lines 7–12 + 22–27 (arg / file validation).

**Apply to:** `scripts/preflight-release.sh` (full body); `scripts/build-release.sh` D-03 pre-flight block (inline form).

```bash
if [ <bad-condition> ]; then
    echo "FAIL: <what went wrong>"
    echo "      <what to do about it — URL or command>"
    exit 1
fi
```

**Why this matters:** `set -e` already exits on command failure, but `set -e` alone gives no message. The explicit `if/echo/exit 1` pattern produces an actionable error rather than a silent non-zero exit. RESEARCH.md §"Pre-flight credential gate" code example uses this pattern throughout — copy it.

### Pattern D: Locked names / identities / tags (DO NOT introduce variants)

**Source:** CONTEXT.md `<specifics>`.

**Apply to:** Every code excerpt + doc edit in Phase 16.

| Item | Locked value | Where it's already embedded |
|------|--------------|------------------------------|
| Notary profile name | `wrangle-notary` | `build-release.sh:16,46`; `create-dmg.sh:59` |
| Team ID | `3DEKQ7GUK6` | `ExportOptions.plist`; `build-release.sh:29,36` |
| Signing identity (short form, preferred) | `Developer ID Application` | `build-release.sh:28,35` |
| Signing identity (long form, optional) | `Developer ID Application: John Kreisher (3DEKQ7GUK6)` | RESEARCH.md verified via `security find-identity` |
| REL-04 verification command (locked verbatim) | `spctl -a -t open --context context:primary-signature <dmg>` | RESEARCH.md §"D-02 patch site"; CONTEXT.md `<specifics>` |
| GH Release tag format | `v` + semver (`v1.3.0`) | `docs/release-checklist.md:79` |
| GH Release state | `--draft` (Phase 16) → published (Phase 18) | CONTEXT.md D-04 §5 |
| Xcode project path | `Wrangle.xcodeproj` (Capital W — canonical) | `build-release.sh:24`; RESEARCH.md confirms only `./Wrangle.xcodeproj` exists |
| DMG filename pattern | `Wrangle-${VERSION}.dmg` | `create-dmg.sh:22` |

### Pattern E: Atomic-commit cadence (carried from Phases 13/14/15)

**Source:** CONTEXT.md `<code_context>` §"Established Patterns".

**Apply to:** Every plan task in Phase 16. One logical change = one commit.

Concrete commit boundaries the planner should respect:
- One commit for the D-02 codesign patch on `create-dmg.sh` (plus REL-04 verification line)
- One commit for the D-03 pre-flight strengthening on `build-release.sh` (or for `scripts/preflight-release.sh` creation if planner chooses standalone form)
- One commit for `docs/release-checklist.md` expansion (D-04)
- One commit for `release-notes-v1.3.0.md` creation (Plan 2)
- One commit for the actual end-to-end build artifacts (none — `build/` is gitignored; this is a "no commit" milestone)

### Pattern F: D-09 anti-pattern enforcement (carried from Phase 15)

**Source:** CONTEXT.md `<specifics>`, reaffirmed in `<code_context>` §"Established Patterns".

**Apply to:** Every plan in Phase 16.

| Forbidden | Why |
|-----------|-----|
| `git filter-repo` | Phase 15 audit confirmed zero secret VALUES in history; no rewrite need |
| `git push --force` | Same |
| `git reset --hard` | Same |

Acceptance-criteria check for every plan: `git reflog --since="<phase start>" \| grep -E "(filter-repo\|push.*--force\|reset.*--hard)"` returns empty.

## No Analog Found

None. Every file in this phase has a strong existing analog. The two new files (`scripts/preflight-release.sh`, `release-notes-v1.3.0.md`) reuse the existing bash-script idiom and existing markdown styling respectively. There is nothing greenfield about Phase 16.

## Metadata

**Analog search scope:** `scripts/` (8 files), `docs/` (release-checklist + architecture + coding-patterns), `wrangle/App/` (WhatsNewChangelog.swift for v1.3.0 content reference), `.planning/phases/16-signed-dmg-release-pipeline/` (CONTEXT, RESEARCH, DISCUSSION-LOG, VALIDATION).

**Files scanned:** 5 scripts read in full; 1 doc read in full; RESEARCH.md (775 lines, read in two pages) + CONTEXT.md (334 lines, read in full).

**Pattern extraction date:** 2026-05-20

**Cross-references the planner consumes:**
- `16-CONTEXT.md` §`<decisions>` D-02 / D-03 / D-04 / D-05 / D-09 (verbatim locks)
- `16-RESEARCH.md` §"Code Examples" (pre-flight body, D-02 diff, gh release create body — all three sourced into PATTERNS.md above)
- `16-RESEARCH.md` §"Validation Architecture" (assertion tables that PATTERNS.md does NOT duplicate — the planner pulls those into per-plan acceptance criteria)
