---
phase: 16-signed-dmg-release-pipeline
plan: 01
subsystem: infra
tags: [release-pipeline, codesign, notarytool, stapler, spctl, gatekeeper, developer-id, dmg, hardened-runtime]

requires:
  - phase: 13-app-de-commercialization
    provides: Phase 13 stripped the license/trial gates and shipped WhatsNew v1.3.0; the .app being notarized here is the OSS-flipped binary
  - phase: 14-app-repo-oss-surface
    provides: gitignore + repo hygiene; D-09 anti-regression rules referenced throughout this plan; D-10 redaction list (overridden for docs/release-checklist.md)

provides:
  - scripts/preflight-release.sh — six-gate credential check (cert, team ID, expiry, notary profile, clean tree, MARKETING_VERSION)
  - scripts/create-dmg.sh patched with D-02 codesign step + REL-04 LOCKED spctl verification
  - scripts/build-release.sh wired to preflight invocation (D-03) + ditto-zip fix for notarytool
  - docs/release-checklist.md expanded with five new D-04 sections (Prereqs / Build .app / DMG packaging / Gatekeeper / Draft Release) and removed from D-10 gitignore
  - End-to-end pipeline execution verified live — signed + notarized + stapled build/Wrangle-1.3.0.dmg that passes the REL-04 LOCKED spctl assessment

affects: [phase-16-plan-02, phase-17-landing-page, phase-18-public-flip]

tech-stack:
  added: []
  patterns:
    - "Pre-flight credential gate as standalone script (Pattern A bash prologue) invoked from build-release.sh"
    - "ditto -c -k --sequesterRsrc --keepParent for notarytool-compatible zip + staple-back to .app"
    - "DMG codesign with --timestamp --options runtime BEFORE notarytool submit (D-02)"
    - "REL-04 LOCKED verification command (spctl -a -t open --context context:primary-signature) as the final create-dmg.sh step"
    - "D-10 override pattern: per-file removal from gitignore redaction list with .gitignore comment documenting the reversal"

key-files:
  created:
    - scripts/preflight-release.sh
    - .planning/phases/16-signed-dmg-release-pipeline/16-01-SUMMARY.md
  modified:
    - scripts/create-dmg.sh
    - scripts/build-release.sh
    - docs/release-checklist.md
    - .gitignore

key-decisions:
  - "Override D-10 for docs/release-checklist.md — the file is now tracked and public, matching the README's 'release pipeline is public' claim and giving contributors a reproducible procedure. Other D-10 entries (audit-report.md, launch-strategy.md, product-hunt/) remain gitignored."
  - "Use the short signing identity 'Developer ID Application' (not the long form 'Developer ID Application: John Kreisher (3DEKQ7GUK6)') in the new create-dmg.sh codesign step — matches build-release.sh CODE_SIGN_IDENTITY for cross-script consistency."
  - "Implement the pre-flight gate as a standalone scripts/preflight-release.sh invoked from build-release.sh (not inlined) so it can be re-run independently as a sanity check."
  - "Count-based MARKETING_VERSION assertion in preflight (grep -c 'MARKETING_VERSION = 1.3.0;' must equal 2) instead of grep -m1 extraction — robust against the WrangleTests target's separate version block added in Plan 13-03."

patterns-established:
  - "Pre-flight credential gate (Pattern A prologue + Pattern C fail-fast with actionable next step) as the first action in any release script."
  - "ditto-zip-then-staple-to-app for notarizing macOS .app bundles via notarytool."
  - "REL-04 LOCKED command verbatim across script + checklist + plan + summary — single canonical Gatekeeper assertion."

requirements-completed:
  - REL-01
  - REL-02
  - REL-03
  - REL-04

duration: ~45min
completed: 2026-05-20
---

# Phase 16 Plan 01: Signed DMG Release Pipeline (Patch + Execute) Summary

**Closed the D-02 DMG-signing gap and the D-03 pre-flight credential gap, expanded the release checklist with five new D-04 sections, and ran the full sign-notarize-staple pipeline live to produce build/Wrangle-1.3.0.dmg with the REL-04 LOCKED spctl assessment returning `accepted source=Notarized Developer ID`.**

## Performance

- **Duration:** ~45 min (including two notarytool roundtrips ~3 min each)
- **Started:** 2026-05-20T19:55Z (Phase 16 begin commit)
- **Completed:** 2026-05-20T21:14Z (REL-04 verify PASS)
- **Tasks:** 4 (3 file-edit + 1 blocking checkpoint:human-verify)
- **Files modified:** 4 (1 new script + 2 patched scripts + 1 expanded doc + 1 gitignore tweak)
- **Commits:** 6 atomic (Pattern E), plus this SUMMARY commit

## Accomplishments

- `scripts/preflight-release.sh` deployed and verified live — all six gates green on this host (cert valid through Mar 2031, Team `3DEKQ7GUK6` matched, notary profile `wrangle-notary` configured, clean tree, MARKETING_VERSION = 1.3.0).
- `scripts/create-dmg.sh` now signs the DMG with `Developer ID Application` + RFC-3161 timestamp + `--options runtime` BEFORE notarytool submit (D-02 gap closed), and verifies via the REL-04 LOCKED `spctl -a -t open --context context:primary-signature` command as its final step.
- `scripts/build-release.sh` invokes preflight as first action (D-03), and now correctly zips the .app via `ditto -c -k --sequesterRsrc --keepParent` before notarytool submit (Rule 1 auto-fix during Task 4 — see Deviations).
- `docs/release-checklist.md` expanded to 10 numbered sections — preserved §1-3 + footer verbatim, inserted five new D-04 sections (§4 Prereqs / §5 Build .app / §6 DMG packaging / §7 Gatekeeper verification / §8 Draft GH Release), renumbered original §4-§5 to §9-§10. D-10 override documented inline in .gitignore.
- End-to-end pipeline ran live: `xcodebuild archive` → `xcodebuild -exportArchive` → `ditto` → `xcrun notarytool submit --wait` (id `76fcee46-513d-4317-8e60-4a3bf76f08ba` Accepted) → `xcrun stapler staple` → `spctl --assess --type exec` PASS → `hdiutil create` → `codesign Developer ID Application --timestamp --options runtime` → `xcrun notarytool submit --wait` (id `47d8aae4-5e81-4090-93fc-1b962f10efb1` Accepted) → `xcrun stapler staple` → `spctl -a -t open --context context:primary-signature` PASS. All Apple-side roundtrips completed in ~3 minutes each (well under the 30-minute escape valve from CONTEXT.md).

## Task Commits

Each task was committed atomically (Pattern E):

1. **Task 1: Create scripts/preflight-release.sh** — `fc75c6e` (feat) + `6ef3eea` (fix — MARKETING_VERSION count assertion, see Deviations)
2. **Task 2a: Patch scripts/create-dmg.sh** (D-02 codesign + REL-04 verify) — `f5f88ab` (feat)
3. **Task 2b: Wire scripts/build-release.sh to preflight** (D-03) — `693b761` (feat) + `7dbecdf` (fix — ditto-zip-before-notarize, see Deviations)
4. **Task 3: Expand docs/release-checklist.md + override D-10** — `25ce64c` (docs)
5. **Task 4: End-to-end pipeline execution** — no commit (build artifacts are gitignored)

**Prep commits (state setup before Task 1):**
- `7bdc5d3` chore(14-03): track walkthrough-short-2.gif (Plan 14-03 retro decision — committed as Phase 16 preflight prerequisite)
- `51a06b1` docs(state): begin phase 16 execution

## Pipeline Execution Outcomes

**Notarization submissions:**

| Artifact | Submission ID | Status | Duration |
|----------|---------------|--------|----------|
| `build/export/Wrangle.zip` (the .app, zipped via ditto) | `76fcee46-513d-4317-8e60-4a3bf76f08ba` | Accepted | ~3 min |
| `build/Wrangle-1.3.0.dmg` | `47d8aae4-5e81-4090-93fc-1b962f10efb1` | Accepted | ~3 min |

**Artifact properties (build/export/Wrangle.app):**
- Identifier: `com.krush.wrangle`
- Authority: `Developer ID Application: John Kreisher (3DEKQ7GUK6)` → `Developer ID Certification Authority` → `Apple Root CA`
- Timestamp: `May 20, 2026 at 21:12:28`
- TeamIdentifier: `3DEKQ7GUK6`
- Stapler: `The staple and validate action worked!`
- spctl: `build/export/Wrangle.app: accepted` + `source=Notarized Developer ID`

**Artifact properties (build/Wrangle-1.3.0.dmg):**
- Size: 7.2 MB
- SHA-256: `c4479d9df030c8b2292c258d2a1a6c9b2798a21f7f030dbfe6934b836c84fe27`
- Authority: `Developer ID Application: John Kreisher (3DEKQ7GUK6)` → `Developer ID Certification Authority` → `Apple Root CA`
- Timestamp: `May 20, 2026 at 21:13:19`
- TeamIdentifier: `3DEKQ7GUK6`
- Stapler: `The staple and validate action worked!`

**REL-04 LOCKED verification (verbatim output):**
```
build/Wrangle-1.3.0.dmg: accepted
source=Notarized Developer ID
```

**Certificate enddate (parsed by preflight):**
- `Mar  5 03:34:08 2031 GMT` — valid for ~5 more years.

## Anti-Regression Results (D-09 + version invariants)

All four anti-regression checks PASS:

| Check | Expected | Actual |
|-------|----------|--------|
| `git reflog --since="2026-05-20" \| grep -E "filter-repo\|push.*--force\|reset.*--hard"` | empty | empty ✓ |
| `grep -c 'MARKETING_VERSION = 1.3.0' Wrangle.xcodeproj/project.pbxproj` | 2 | 2 ✓ |
| `grep -c 'CURRENT_PROJECT_VERSION = 6' Wrangle.xcodeproj/project.pbxproj` | 2 | 2 ✓ |
| `git diff -- ExportOptions.plist` | empty | empty ✓ |

D-09 stands. No history rewrites, no force-pushes, no hard-resets executed in Phase 16 Plan 01.

## Files Created/Modified

| Path | Change | Notes |
|------|--------|-------|
| `scripts/preflight-release.sh` | created (79 lines, executable) | Six-gate credential + tree + version check |
| `scripts/create-dmg.sh` | +12 lines (insert at L57 + L77) | D-02 codesign block + REL-04 spctl verify; brew create-dmg branch untouched |
| `scripts/build-release.sh` | +12 lines | preflight invocation (L18-19) + ditto-zip wrapper around notarytool submit (Rule 1 fix) |
| `docs/release-checklist.md` | rewritten (262 lines) | Inserted 5 new D-04 sections; renumbered original §4-§5 to §9-§10; preserved §1-3 + footer verbatim |
| `.gitignore` | -1 / +4 lines | Removed `docs/release-checklist.md` from D-10 redaction list; added comment explaining override |
| `screenshots/raw/walkthrough-short-2.gif` | added (1.8 MB) | Plan 14-03 retro decision: tracked to satisfy preflight clean-tree gate |
| `.planning/STATE.md` | updated | Phase 16 begin marker |

## Decisions Made

- **Override D-10 for `docs/release-checklist.md`** (user-approved during Task 3): the README publicly states "the release pipeline is public" and contributors need the documented procedure to be reproducible. Other D-10 entries (`docs/audit-report.md`, `docs/launch-strategy.md`, `docs/product-hunt/`) remain gitignored. Rationale captured in `.gitignore` comment.
- **Short signing identity** in `scripts/create-dmg.sh` (`"Developer ID Application"` not the long form): matches `build-release.sh` `CODE_SIGN_IDENTITY` and works correctly when only one such identity exists in the Keychain — verified locally.
- **Preflight as standalone script** (not inlined into `build-release.sh`): planner discretion preserved per RESEARCH.md Open Question #2. Gives the user a one-command sanity check independent of the long-running build.
- **Track `screenshots/raw/walkthrough-short-2.gif`** (Plan 14-03 retro decision, user-approved): Plan 14-03 SUMMARY explicitly left this open ("leave as-is unless user wants it tracked or deleted"); user chose to track to close the decision and satisfy Phase 16's preflight clean-tree gate.

## Deviations from Plan

Three auto-fixes were applied during execution (all Rule 1 — bugs in plan-as-written or pre-existing code), plus one Rule 4 architectural decision (D-10 override).

### Auto-fixed Issues

**1. [Rule 1 — Plan grep pattern collision] preflight gate 6 used `grep -m1`, returned wrong target's version**
- **Found during:** Task 1 (first live preflight run after committing the script)
- **Issue:** Plan specified `grep -m1 'MARKETING_VERSION = ' Wrangle.xcodeproj/project.pbxproj | sed -E 's/.*= ([0-9.]+);.*/\1/'` which returns `1.0` because the WrangleTests target (wired up in Plan 13-03 after Phase 16 was researched) appears before the main Wrangle app target in `project.pbxproj`. The plan did not anticipate the multi-target pbxproj layout.
- **Fix:** Replaced with count-based assertion `grep -c "MARKETING_VERSION = $EXPECTED_VERSION;" pbxproj` requiring exactly 2 matches (Debug + Release on the main Wrangle target). Matches the anti-regression check style every plan in Phase 16 already uses.
- **Files modified:** `scripts/preflight-release.sh`
- **Verification:** `bash scripts/preflight-release.sh` now exits 0 with "All pre-flight checks passed. Ready to build."
- **Committed in:** `6ef3eea` (fix(16-01): preflight gate 6 — count MARKETING_VERSION = 1.3.0 lines)

**2. [Rule 1 — Pre-existing script bug] build-release.sh submitted raw .app to notarytool**
- **Found during:** Task 4 (first live pipeline run after committing all Task 1-3 changes)
- **Issue:** Pre-existing `scripts/build-release.sh` (committed in `de466f6`, Phase 13 era) ran `xcrun notarytool submit "$APP_PATH"` on the raw `.app` bundle. notarytool only accepts `.zip`, `.pkg`, or `.dmg` and failed with: `Wrangle.app must be a zip archive (.zip), flat installer package (.pkg), or UDIF disk image (.dmg)`. RESEARCH.md §"Don't Hand-Roll" already documented the correct pattern ("staple-the-app-then-DMG-the-stapled-app") but the plan didn't include the script fix because it assumed build-release.sh already worked.
- **Fix:** Inserted `ditto -c -k --sequesterRsrc --keepParent "$APP_PATH" "$ZIP_FOR_NOTARY"` before `notarytool submit`, submit the zip, staple back to the original `.app` (stapler cannot attach to a zip), then `rm` the zip.
- **Files modified:** `scripts/build-release.sh`
- **Verification:** Re-ran pipeline end-to-end; notarytool accepted the submission (id `76fcee46-...`), stapler validated the .app, spctl returned `accepted`.
- **Committed in:** `7dbecdf` (fix(16-01): zip .app via ditto before notarytool submit)

### User-Approved Architectural Decision

**3. [Rule 4 — D-10 redaction list override] docs/release-checklist.md moved from gitignored to tracked**
- **Found during:** Task 3 (the file was gitignored from Plan 14-03 — could not be `git add`-ed)
- **Issue:** Plan 14-03 added `docs/release-checklist.md` to the D-10 redaction list ("could be useful publicly but user prefers private"). Plan 16-01 Task 3 acceptance criterion required a tracked commit of the file. README.md (committed in Phase 14 Plan 02) publicly states "the release pipeline is public" — the repo state contradicted the README's promise.
- **Resolution:** User approved overriding D-10 specifically for `docs/release-checklist.md` to align repo state with README. Other D-10 entries (`docs/audit-report.md`, `docs/launch-strategy.md`, `docs/product-hunt/`) remain gitignored. .gitignore comment added explaining the override.
- **Files modified:** `.gitignore`, `docs/release-checklist.md` (now tracked)
- **Committed in:** `25ce64c` (docs(16-01): expand release-checklist with D-04 sections; override D-10)

**Total deviations:** 2 Rule-1 auto-fixes + 1 Rule-4 user-approved override. No silent skips; no acceptance criteria bypassed.

## Authentication Gates

None encountered. `gh` was not invoked in this plan (Plan 02 will); `notarytool` was pre-authenticated via the `wrangle-notary` keychain profile (verified by preflight gate 4 before each pipeline run).

## Next Phase Readiness

`build/Wrangle-1.3.0.dmg` is signed, notarized, stapled, and passes the REL-04 LOCKED `spctl` assessment on the build host. The DMG is in the gitignored `build/` directory — it persists on disk for Plan 02 (second-Mac verify + draft GH Release upload) but does not enter git history.

Plan 02 picks up immediately with:
- Task 1: Author `release-notes-v1.3.0.md` (4-6 bullets per CONTEXT.md discretion)
- Task 2: Copy DMG to a second Apple Silicon Mac via AirDrop, verify clean Gatekeeper open, capture screenshot (REL-06)
- Task 3: `git tag v1.3.0`, `git push origin v1.3.0`, `gh release create --draft --verify-tag --notes-file ... build/Wrangle-1.3.0.dmg` (REL-05)

The DMG SHA-256 `c4479d9df030c8b2292c258d2a1a6c9b2798a21f7f030dbfe6934b836c84fe27` will be recorded in 16-02-SUMMARY.md for reproducibility audit.

## Issues Encountered

The two Rule-1 auto-fixes (preflight grep collision + notarytool input-type) are documented under Deviations above. Both surfaced at the earliest possible moment (Task 1 first run + Task 4 first run) and were fixed within minutes. No issues remain unresolved at plan close.

## Self-Check: PASSED

- [x] All four tasks executed
- [x] All acceptance criteria for Tasks 1-3 verified post-fix (preflight green; create-dmg.sh contains required strings; release-checklist.md has 10 numbered sections + REL-04 LOCKED verbatim + preserved footer)
- [x] Task 4 blocking checkpoint approved by user
- [x] All five plan-level `<verification>` checks PASS
- [x] All four success criteria PASS (REL-01..REL-04 satisfied)
- [x] All four anti-regression checks PASS (D-09 + MARKETING_VERSION x2 + CURRENT_PROJECT_VERSION x2 + ExportOptions.plist)
- [x] Six atomic commits (Pattern E) — one per logical change; no consolidated commits, no skipped commits
