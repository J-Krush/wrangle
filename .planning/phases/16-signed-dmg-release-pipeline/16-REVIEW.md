---
phase: 16-signed-dmg-release-pipeline
reviewed: 2026-05-21T03:00:00Z
depth: standard
files_reviewed: 5
files_reviewed_list:
  - scripts/preflight-release.sh
  - scripts/create-dmg.sh
  - scripts/build-release.sh
  - docs/release-checklist.md
  - .planning/phases/16-signed-dmg-release-pipeline/release-notes-v1.3.0.md
  - .gitignore
findings:
  critical: 2
  warning: 6
  info: 5
  total: 13
status: issues_found
---

# Phase 16: Code Review Report

**Reviewed:** 2026-05-21T03:00:00Z
**Depth:** standard
**Files Reviewed:** 6 (5 source + .gitignore)
**Status:** issues_found

## Summary

Phase 16 ships a working, signed + notarized + stapled DMG and the live evidence (REL-04 LOCKED PASS, second-Mac open, draft GH Release with asset) confirms the end-to-end pipeline runs. The bash scripts are mostly well-disciplined (`set -euo pipefail`, quoted variables, double-quoted paths, no obvious command-injection surfaces) and credential handling is safe (notarytool keychain profile + Apple ID app-specific password held only in Keychain — never echoed). However, the user-facing documentation (`docs/release-checklist.md`) contains **two concrete reproducibility bugs**, the DMG-signing logic has a **silent ambiguity that bites the moment a second Developer ID Application identity lands in the Keychain**, and several quality issues degrade the contributor experience.

This is a release-engineering review — none of the findings blocked the v1.3.0 cut (which already shipped), but every BLOCKER and several WARNINGS will trip the next contributor (or the user, six months from now) trying to reproduce from these scripts + checklist alone.

The two BLOCKERs both fall on the "documentation accuracy / reproducibility" axis the prompt called out explicitly — the §10 grep prints a misleading MISMATCH on a correctly-set repo, and `scripts/create-dmg.sh`'s short signing identity silently signs with whichever Developer ID Application cert `codesign` finds first when multiple exist.

## Critical Issues

### CR-01: `docs/release-checklist.md` §10 verification grep returns wrong version, falsely reports MISMATCH

**File:** `docs/release-checklist.md:243-251`
**Issue:** The §10 "Quick verification grep" block uses `head -1` to extract `MARKETING_VERSION` from `Wrangle.xcodeproj/project.pbxproj`:

```bash
MARKETING=$(grep -E 'MARKETING_VERSION = ' \
  Wrangle.xcodeproj/project.pbxproj | head -1 | \
  sed -E 's/.*MARKETING_VERSION = ([0-9]+\.[0-9]+\.[0-9]+);/\1/')
```

This is **exactly the bug Plan 16-01 documented and fixed in `preflight-release.sh`** (Deviation 1 / commit `6ef3eea`). The WrangleTests target's `MARKETING_VERSION = 1.0;` block appears at lines 221 + 242 of `project.pbxproj`, BEFORE the main app's `MARKETING_VERSION = 1.3.0;` blocks at lines 399 + 438. `head -1` therefore returns `1.0`, not `1.3.0`, and the script prints `MISMATCH: changelog=1.3.0 marketing=1.0` against a correctly-configured repo.

Verified live:
```
$ grep -nE 'MARKETING_VERSION = ' Wrangle.xcodeproj/project.pbxproj
221: MARKETING_VERSION = 1.0;        ← WrangleTests, picked by head -1
242: MARKETING_VERSION = 1.0;        ← WrangleTests
399: MARKETING_VERSION = 1.3.0;      ← main Wrangle target
438: MARKETING_VERSION = 1.3.0;      ← main Wrangle target
```

The fix learned in Plan 16-01 (count-based assertion) was not back-ported to the documentation it was meant to replace. A contributor who runs the §10 snippet on the current main branch will see MISMATCH and assume the version is broken.

**Fix:**
```bash
# Count-based — matches the pattern preflight-release.sh now uses.
MARKETING_LINES=$(grep -c 'MARKETING_VERSION = 1.3.0;' \
  Wrangle.xcodeproj/project.pbxproj)
test "$MARKETING_LINES" -eq 2 && echo "OK: 2 main-target lines" || \
  echo "MISMATCH: expected 2 main-target lines, found $MARKETING_LINES"
```

Or, to keep the original "compare changelog to pbxproj" intent:
```bash
TOP_ENTRY=$(grep -E 'version: "[0-9]+\.[0-9]+\.[0-9]+"' \
  wrangle/App/WhatsNewChangelog.swift | head -1 | \
  sed -E 's/.*"([0-9]+\.[0-9]+\.[0-9]+)".*/\1/')
# Count occurrences of MARKETING_VERSION = <TOP_ENTRY>; — must be 2 (Debug + Release).
COUNT=$(grep -c "MARKETING_VERSION = ${TOP_ENTRY};" \
  Wrangle.xcodeproj/project.pbxproj)
test "$COUNT" -eq 2 && echo "OK: $TOP_ENTRY" || \
  echo "MISMATCH: changelog=$TOP_ENTRY, pbxproj had $COUNT MARKETING_VERSION=$TOP_ENTRY lines (expected 2)"
```

---

### CR-02: `scripts/create-dmg.sh` short signing identity ambiguous when ≥2 Developer ID Application certs in Keychain — `codesign` silently picks one

**File:** `scripts/create-dmg.sh:60`
**Issue:**
```bash
codesign --sign "Developer ID Application" \
    --timestamp \
    --options runtime \
    "$DMG_FINAL"
```

`codesign --sign "Developer ID Application"` resolves by substring match across the Keychain. On the build host this works because the cert is unique; but the moment a second valid Developer ID Application identity exists (e.g., a renewal kept in parallel during transition, an org-shared Mac, two team certs), `codesign` will either:
- silently sign with whichever the Keychain returns first (potentially the WRONG team's cert), or
- abort with `Multiple identities match` (depending on the macOS version and how the Keychain enumerates).

`preflight-release.sh:31` validates that *a* cert for `TEAM_ID=3DEKQ7GUK6` is present — it does NOT validate that the cert `codesign --sign "Developer ID Application"` will resolve to is the correct-team one. So the preflight passes; the DMG gets signed under whichever cert happens to sort first; notarization proceeds; the user ships a DMG signed under the wrong Team ID.

Compounding: `scripts/build-release.sh:31` uses the same short form (`CODE_SIGN_IDENTITY="Developer ID Application"`) — same ambiguity. The 16-01 SUMMARY explicitly calls out this design choice ("Use the short signing identity ... works correctly when only one such identity exists in the Keychain — verified locally"), acknowledging it as a known footgun.

This is a release-engineering BLOCKER because the failure mode is silent (a notarized DMG signed by the wrong team is indistinguishable from a correct one until a downstream verifier checks `TeamIdentifier`).

**Fix:** Sign with the SHA-1 hash or the full identity string, and pin to Team ID. Two options:

Option A — use the explicit Team-scoped long form (matches the cert chain shown in 16-01 SUMMARY):
```bash
codesign --sign "Developer ID Application: John Kreisher (3DEKQ7GUK6)" \
    --timestamp \
    --options runtime \
    "$DMG_FINAL"
```

Option B (more robust, survives cert renewal which changes the SHA-1 but not the team) — resolve from preflight and pass via env:
```bash
# In preflight-release.sh, after Gate 2 passes, export the matching SHA-1:
SIGNING_IDENTITY_SHA1=$(security find-identity -v -p codesigning | \
    grep "Developer ID Application" | grep "$TEAM_ID" | \
    head -1 | awk '{print $2}')
export SIGNING_IDENTITY_SHA1

# In create-dmg.sh + build-release.sh:
: "${SIGNING_IDENTITY_SHA1:?run preflight-release.sh first to export this}"
codesign --sign "$SIGNING_IDENTITY_SHA1" ...
```

Either way, also add a post-sign assertion to `create-dmg.sh` (after the codesign block) that verifies the actual team that ended up on the artifact:
```bash
SIGNED_TEAM=$(codesign -dv --verbose=4 "$DMG_FINAL" 2>&1 | \
    grep -E '^TeamIdentifier=' | cut -d= -f2)
if [[ "$SIGNED_TEAM" != "3DEKQ7GUK6" ]]; then
    echo "FAIL: DMG signed under TeamIdentifier=$SIGNED_TEAM, expected 3DEKQ7GUK6"
    exit 1
fi
```

## Warnings

### WR-01: `scripts/create-dmg.sh` does not abort if `codesign`, `notarytool`, or `stapler` fails — exit code is propagated but no user-facing diagnostic

**File:** `scripts/create-dmg.sh:60-71`
**Issue:** The script runs `set -euo pipefail`, so a non-zero exit from `codesign` / `notarytool submit --wait` / `stapler staple` will abort. However, `notarytool submit --wait` returns 0 even when the submission status is `Invalid` or `Rejected` (the command succeeded; the notarization itself failed). The script then continues to `stapler staple`, which fails with a cryptic `CloudKit` error instead of "notarization was rejected — fetch log with `notarytool log <id>`."

**Fix:** Capture the submission ID and assert `Status: Accepted`:
```bash
echo "==> Notarizing DMG..."
SUBMIT_OUTPUT=$(xcrun notarytool submit "$DMG_FINAL" \
    --keychain-profile "wrangle-notary" \
    --wait 2>&1)
echo "$SUBMIT_OUTPUT"
SUBMIT_ID=$(echo "$SUBMIT_OUTPUT" | awk '/^  id:/{print $2; exit}')
if ! echo "$SUBMIT_OUTPUT" | grep -q "status: Accepted"; then
    echo "FAIL: notarization not accepted (id=$SUBMIT_ID)"
    echo "      Fetch detailed log:"
    echo "        xcrun notarytool log $SUBMIT_ID --keychain-profile wrangle-notary"
    exit 1
fi
```
Apply the same pattern in `scripts/build-release.sh:56`.

---

### WR-02: `scripts/build-release.sh` `xcodebuild | xcpretty || xcodebuild` fallback masks the first-run exit code

**File:** `scripts/build-release.sh:26-39`
**Issue:**
```bash
xcodebuild archive ... | xcpretty || xcodebuild archive ...
```

Under `set -o pipefail`, this works if `xcpretty` is missing (the pipe fails, the second `xcodebuild` runs). BUT: if `xcodebuild` itself fails (genuine build error) AND `xcpretty` is present, the pipe's exit code is non-zero, and the `||` branch runs the build a SECOND time without `xcpretty`. The user sees the same error twice (the second time un-prettied), and the script burns ~2 minutes re-archiving before failing. Worse, if the second `xcodebuild` accidentally succeeds (e.g., transient flake / dirty derived data resolved by the wasted minutes), the user gets a green build despite the first attempt having failed for a real reason that was never surfaced.

**Fix:** Use the standard idiom — only fall back when `xcpretty` is absent:
```bash
if command -v xcpretty &>/dev/null; then
    xcodebuild archive ... | xcpretty
    BUILD_RC=${PIPESTATUS[0]}
else
    xcodebuild archive ...
    BUILD_RC=$?
fi
[ "$BUILD_RC" -eq 0 ] || { echo "FAIL: xcodebuild archive failed"; exit "$BUILD_RC"; }
```

---

### WR-03: `scripts/preflight-release.sh` certificate-expiry check parses only the first matching cert

**File:** `scripts/preflight-release.sh:39-40`
**Issue:**
```bash
CERT_ENDDATE=$(security find-certificate -c "Developer ID Application" -p | \
    openssl x509 -enddate -noout 2>/dev/null | cut -d= -f2)
```

`security find-certificate -c "Developer ID Application" -p` returns the **first** matching cert from the Keychain. If two Developer ID Application certs exist (old + renewed), this might be the expired one OR the unexpired one — undefined. The same multi-cert ambiguity as CR-02, but here it shows up as a misleading "FAIL: expired" warning when the user actually has a valid renewed cert installed, or — more dangerous — a false PASS when the expired cert sorts second.

**Fix:** Scope the cert lookup to the team, and use the longest-validity match:
```bash
# Get all Developer ID Application certs for our team, pick the one with the latest expiry.
CERT_ENDDATE=$(security find-certificate -a -c "Developer ID Application" -p | \
    awk '/-----BEGIN/,/-----END/' | \
    openssl x509 -enddate -noout 2>/dev/null | \
    sed 's/notAfter=//' | sort -t' ' -k4,4n | tail -1)
```
(Or pin to SHA-1 from Gate 2 and parse that specific cert by hash.)

Also: the script prints `WARN: Could not parse cert expiry date — proceed with caution.` and continues. A WARN that lets release proceed is a missed gate — at minimum, prompt the user, or treat the parse failure as FAIL.

---

### WR-04: `docs/release-checklist.md` §1 says "4 occurrences total" but Phase 16 itself documented that there are 6 (2 in WrangleTests + 4 in main)

**File:** `docs/release-checklist.md:8-11`
**Issue:** §1 reads "Two settings live in **both** the Debug and Release config blocks (4 occurrences total)" and the verification grep `grep -nE 'MARKETING_VERSION|CURRENT_PROJECT_VERSION' Wrangle.xcodeproj/project.pbxproj` will print 8 lines (2 WrangleTests MARKETING + 2 WrangleTests CURRENT + 2 main MARKETING + 2 main CURRENT). The "Both `MARKETING_VERSION` lines must match" assertion is wrong — there are 4 such lines, only 2 of which need to match the new version. A contributor following this literally will be confused.

**Fix:**
```markdown
| Setting | What it is | Bump rule |
| ------- | ---------- | --------- |
| `MARKETING_VERSION` | The semver shown in About / Check-for-Updates / WhatsNew dismiss sentinel | Every release — change the 2 lines on the main `Wrangle` target only (Debug + Release). The 2 lines on the `WrangleTests` target stay at `1.0`. |
| `CURRENT_PROJECT_VERSION` | Monotonic build number | Every release — same rule: 2 lines on main `Wrangle`, leave `WrangleTests` alone. |

Verify:

```bash
grep -nE 'MARKETING_VERSION|CURRENT_PROJECT_VERSION' Wrangle.xcodeproj/project.pbxproj
# Expect 8 lines: 4 from the WrangleTests target (MARKETING = 1.0; CURRENT = 1)
# and 4 from the main Wrangle target (MARKETING = $NEW_VERSION; CURRENT = $NEW_BUILD).
```
```

---

### WR-05: `docs/release-checklist.md` §8 (Draft GH Release) and §9 (Tag the release) duplicate `git tag` + `git push` — running them in order tries to tag twice

**File:** `docs/release-checklist.md:177-236`
**Issue:** §8 already runs:
```bash
git tag "$TAG"
git push origin "$TAG"
gh release create "$TAG" ...
```
Then §9 says:
```bash
git tag v1.3.0
git push origin v1.3.0
# Then draft a GitHub Release pointing at the tag.
```

A contributor walking through the checklist top-to-bottom hits `fatal: tag 'v1.3.0' already exists` on §9. §9 is residue from the original `release-checklist.md` (pre-Phase-16) that should have been removed or restructured during the §4–§8 insertion. The "Why this checklist exists" footer (§"Why this checklist exists") references §1+§2 — that's the canonical footer the SUMMARY says was preserved verbatim — but §9 in its current form is *redundant with §8*, not preserved-for-good-reason.

Plan 16-01 SUMMARY claims "renumbered original §4-§5 to §9-§10." Original §4 was probably the "tag on GitHub" step and §5 the "verification grep." With §8 now performing the tag + release work, §9 should be DELETED or rewritten as "after the public flip (Phase 18), the same tag becomes the source of truth for the in-app `Check for Updates...` endpoint" — purely explanatory, no commands.

**Fix:** Either:
1. Delete §9 entirely and renumber §10 → §9.
2. Rewrite §9 to remove the `git tag` / `git push` lines and clarify it documents the post-publish behavior, not a step to execute.

---

### WR-06: `release-notes-v1.3.0.md` "Download" section instructs users to drag to the `Applications` alias but the DMG layout only renders that alias in the GUI mount

**File:** `.planning/phases/16-signed-dmg-release-pipeline/release-notes-v1.3.0.md:23-25`
**Issue:** The notes say:
> To install, mount the DMG and drag `Wrangle.app` to the `Applications` alias in the same window.

`scripts/create-dmg.sh:34-46` shows the brew `create-dmg` branch does configure window-pos / icon positions / `--app-drop-link`. BUT the `hdiutil` fallback branch (lines 49-54) does NOT — it just builds a vanilla UDZO disk image with the `$DMG_DIR` contents but no `.DS_Store` window-layout file. The Plan 16-01 SUMMARY does not specify which branch produced the shipped `Wrangle-1.3.0.dmg`. If it was the `hdiutil` branch (likely — no evidence in the SUMMARY that `create-dmg` brew package was installed during the live run), users see a Finder window with `Wrangle.app` + a generic `Applications` symlink with no positioning / `app-drop-link` UX. The release notes promise a polished drag-target experience that the script's actual default path doesn't deliver.

Either:
1. Document this — change the release notes to say "drag Wrangle.app to /Applications" (works with either DMG layout).
2. Fix `create-dmg.sh` to ensure brew `create-dmg` is installed before running, or replicate the window-positioning via a small AppleScript step on the `hdiutil` branch.

Option 1 is the cheap defensive fix. Option 2 matches the Plan-as-specified UX.

## Info

### IN-01: `scripts/build-release.sh` does not `cd "$PROJECT_DIR"` — runs `git`/`xcodebuild` against the caller's cwd if invoked from outside the repo

**File:** `scripts/build-release.sh:9-19`, `scripts/create-dmg.sh:7-13`, `scripts/preflight-release.sh:17-18`
**Issue:** All three scripts compute `PROJECT_DIR` correctly but only `preflight-release.sh` uses `git -C "$PROJECT_DIR"`. `build-release.sh` invokes `xcodebuild -project "$PROJECT_DIR/Wrangle.xcodeproj"` (absolute, good) and `create-dmg.sh` uses absolute paths throughout — so functionally OK. But a future maintainer adding `git rev-parse HEAD` or any cwd-relative tool will silently inherit the caller's cwd. Add `cd "$PROJECT_DIR"` near the top of each script for defense in depth.

---

### IN-02: `scripts/preflight-release.sh` Gate 6 uses `|| true` to swallow grep's exit code — masks a missing pbxproj file

**File:** `scripts/preflight-release.sh:74`
**Issue:**
```bash
ACTUAL_MV_COUNT=$(grep -c "MARKETING_VERSION = $EXPECTED_VERSION;" "$PROJECT_DIR/Wrangle.xcodeproj/project.pbxproj" || true)
```
The `|| true` is there because `grep -c` returns exit 1 when there are zero matches. Fine — but it also returns exit 2 when the file doesn't exist, and `|| true` masks that too. If `project.pbxproj` is missing (catastrophic repo corruption), `ACTUAL_MV_COUNT` is empty string and the `-ne` comparison gets weird.

**Fix:**
```bash
PBXPROJ="$PROJECT_DIR/Wrangle.xcodeproj/project.pbxproj"
if [[ ! -f "$PBXPROJ" ]]; then
    echo "FAIL: $PBXPROJ not found — wrong PROJECT_DIR?"
    exit 1
fi
ACTUAL_MV_COUNT=$(grep -c "MARKETING_VERSION = $EXPECTED_VERSION;" "$PBXPROJ" || true)
```

---

### IN-03: `EXPECTED_VERSION="1.3.0"` hardcoded in `preflight-release.sh` — every release needs a script edit

**File:** `scripts/preflight-release.sh:22`
**Issue:** Every future release will require editing this constant and committing it BEFORE running preflight (otherwise Gate 5 — clean tree — fails on the uncommitted change to preflight itself). Either accept this as an explicit "version-pinned per release" pattern (commit immediately after bumping pbxproj as part of step 1) and document it in the checklist, or read the version from the pbxproj at runtime.

**Fix (option 1 — document):** Add to checklist §4: "After bumping the pbxproj version (§1), also update `EXPECTED_VERSION` in `scripts/preflight-release.sh` to match, and commit both changes together. Preflight Gate 5 (clean tree) requires zero uncommitted changes."

**Fix (option 2 — auto-detect):** Read from pbxproj. Since the script already grep-counts the file, derive the target version from the highest-numbered `MARKETING_VERSION` on the main Wrangle target (or accept a CLI arg).

---

### IN-04: `release-notes-v1.3.0.md` says "no `xattr -d com.apple.quarantine`" — phrasing implies the user might attempt this, but Phase 16's notarization explicitly makes it unnecessary

**File:** `.planning/phases/16-signed-dmg-release-pipeline/release-notes-v1.3.0.md:19`
**Issue:** Telling new users they don't need `xattr -d com.apple.quarantine` is reassuring to power users but leaks an unfamiliar concept to everyone else. Consider softening to: "Wrangle opens cleanly on first launch — no extra steps, no security workarounds." The CLI command can stay in the Phase 16 SUMMARY for the audit trail; the release notes are user-facing.

---

### IN-05: `.gitignore` "Phase 16 override" comment is informative now but will go stale fast

**File:** `.gitignore:22-24`
**Issue:**
```
# Phase 16 override: docs/release-checklist.md is now tracked + public — the
# README's "release pipeline is public" claim depends on this, and contributors
# need the procedure to be reproducible.
```
This comment narrates a one-time D-10 override decision that won't mean anything to a contributor in six months who hasn't read the Phase 16 planning artifacts. It's not wrong to retain — it answers "why isn't this gitignored like the others?" — but the "Phase 16" reference will be opaque. Consider trimming to:
```
# docs/release-checklist.md is intentionally tracked + public — README links
# to it and contributors need the documented release procedure.
```

---

_Reviewed: 2026-05-21T03:00:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard (bash + markdown reproducibility focus per Phase 16 prompt)_
