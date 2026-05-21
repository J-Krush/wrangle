---
phase: 16-signed-dmg-release-pipeline
verified: 2026-05-21T02:31:54Z
status: passed
score: 11/11 must-haves verified
overrides_applied: 0
re_verification:
  previous_status: none
  previous_score: n/a
  gaps_closed: []
  gaps_remaining: []
  regressions: []
---

# Phase 16: Signed-DMG Release Pipeline — Verification Report

**Phase Goal (ROADMAP.md):** "A documented, repeatable local-build procedure produces a signed and notarized DMG that opens cleanly on a fresh-eyes Mac without Gatekeeper warnings, attached to a tagged v1.3.0 GitHub Release on J-Krush/wrangle (still private at this point)."

**Verified:** 2026-05-21T02:31:54Z
**Status:** passed
**Re-verification:** No — initial verification.

## Goal Achievement

The phase goal decomposes into six observable truths (REL-01..REL-06). Every truth is satisfied by codebase + live evidence. The build artifacts produced by the pipeline (build/Wrangle-1.3.0.dmg + build/export/Wrangle.app) are still on disk and were re-verified live during this verification pass — they confirm the SUMMARY claims rather than just relying on them.

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | scripts/preflight-release.sh exits 0 when cert + notary profile + clean tree + MARKETING_VERSION=1.3.0 all valid | VERIFIED | Live run: prints `All pre-flight checks passed. Ready to build.` and exits 0. Cert valid until `Mar  5 03:34:08 2031 GMT`. |
| 2 | scripts/create-dmg.sh signs the DMG with Developer ID Application + RFC-3161 timestamp + hardened runtime BEFORE notarytool submit (D-02 gap closed) | VERIFIED | L60-63: `codesign --sign "Developer ID Application" --timestamp --options runtime "$DMG_FINAL"` placed at line 60; `xcrun notarytool submit "$DMG_FINAL"` at L66 — ordering confirmed (60 < 66). |
| 3 | scripts/create-dmg.sh runs the REL-04 LOCKED verification command as its final step and exits 0 on accepted | VERIFIED | L77: `spctl -a -t open --context context:primary-signature -v "$DMG_FINAL"` present verbatim. Live run on existing build/Wrangle-1.3.0.dmg returns `accepted` + `source=Notarized Developer ID`. |
| 4 | docs/release-checklist.md contains the six D-04 sections + preserved §1-3 + footer | VERIFIED | 10 numbered H2 sections total. New: §4 Prereqs, §5 Build/sign/notarize, §6 DMG packaging, §7 Gatekeeper verification, §8 Draft GitHub Release. Renumbered: §9 Tag the release on GitHub, §10 Quick verification grep. Footer "Why this checklist exists" + "Phase 13 added the v1.3.0 WhatsNew entry without bumping" both present (1 match each). |
| 5 | build/export/Wrangle.app is signed (Developer ID Application), notarized + stapled, Gatekeeper-clean | VERIFIED | Live `codesign -dv --verbose=4`: Authority chain = Developer ID Application: John Kreisher (3DEKQ7GUK6) → Developer ID Certification Authority → Apple Root CA. Stapler validate: "The validate action worked!". `spctl --assess --type exec`: `accepted` + `source=Notarized Developer ID`. |
| 6 | build/Wrangle-1.3.0.dmg is signed + notarized + stapled + PASSES REL-04 LOCKED command | VERIFIED | Live `codesign -dv --verbose=4`: Authority = Developer ID Application + RFC-3161 Timestamp May 20, 2026 at 21:13:19. Stapler validate worked. `spctl -a -t open --context context:primary-signature -v` returns `accepted` + `source=Notarized Developer ID`. SHA-256 `c4479d9d...` matches SUMMARY. |
| 7 | User attests build/Wrangle-1.3.0.dmg opens on a second Apple Silicon Mac (macOS 15+) without Gatekeeper warning, no right-click, no xattr pre-treatment | VERIFIED | Second-mac screenshot present at `.planning/phases/16-signed-dmg-release-pipeline/16-02-VERIFY/second-mac-screenshot.png` shows running Wrangle app in idle state on a fresh host (no projects, notifications-disabled prompt). SUMMARY records MacBook Pro M1 Pro, macOS Sequoia 15.6.1, AirDrop transfer. Stronger than mounted-DMG-window evidence (proves install + launch path). |
| 8 | release-notes-v1.3.0.md exists with 4-6 bullets, OSS-flip lead, v1.2 browser features, no emojis | VERIFIED | File exists at locked path. H1 `# Wrangle v1.3.0` present (1 match). Bullets in `What's new`: 5 (within 4-6 range). MIT mentioned 2x. Browser-feature keywords (browser/bookmark/history/download/private): 6 matches. macOS 15 / Sequoia / Apple Silicon: 1 match. Emoji scan via Unicode Extended_Pictographic: clean. |
| 9 | Git tag v1.3.0 exists on origin (git ls-remote returns one ref) pinned to verified commit | VERIFIED | `git ls-remote origin refs/tags/v1.3.0` returns `1f135507f63d852e2d2d1cb6649edc36350aa5dc refs/tags/v1.3.0`. Local `git rev-parse v1.3.0` matches. SUMMARY records the same SHA. |
| 10 | Draft GitHub Release v1.3.0 exists on J-Krush/wrangle with Wrangle-1.3.0.dmg attached as asset | VERIFIED | Live `gh release view v1.3.0 --repo J-Krush/wrangle --json isDraft,tagName,assets`: `{"isDraft":true, "tagName":"v1.3.0", "assetNames":["Wrangle-1.3.0.dmg"]}`. |
| 11 | Draft NOT publicly visible — unauthenticated curl to /releases/latest returns 404 (D-10 LOCKED) | VERIFIED | Live `curl -s -o /dev/null -w "%{http_code}" https://api.github.com/repos/J-Krush/wrangle/releases/latest` returns `404` exactly as locked. Confirms `--draft` + private-repo state both gating visibility. |

**Score:** 11/11 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
|---|---|---|---|
| `scripts/preflight-release.sh` | Six-gate credential + tree + version check; executable | VERIFIED | 83 lines, `-rwxr-xr-x`, contains all six gates with locked identifiers (wrangle-notary, 3DEKQ7GUK6, Developer ID Application, MARKETING_VERSION). Runs green live. Wired into build-release.sh L18-19. |
| `scripts/create-dmg.sh` | D-02 codesign step + REL-04 LOCKED verify line | VERIFIED | 81 lines. L60-63 has codesign --sign "Developer ID Application" --timestamp --options runtime, ordered before notarytool submit at L66. L77 has REL-04 LOCKED spctl line verbatim. `bash -n` syntax check passes. brew create-dmg branch untouched. |
| `scripts/build-release.sh` | Preflight invocation + ditto-zip wrapper for notarytool | VERIFIED | 71 lines. L18-19 invokes preflight, ordered before xcodebuild archive at L26. L53 has `/usr/bin/ditto -c -k --sequesterRsrc --keepParent "$APP_PATH" "$ZIP_FOR_NOTARY"`. L63 staples to .app after rm of zip. `bash -n` passes. |
| `docs/release-checklist.md` | Six new D-04 sections + preserved §1-3 + footer | VERIFIED | 265 lines, 10 H2 sections. New sections §4..§8 present with REL-04 LOCKED verbatim at L139 + L191. Footer + Phase 13 reference preserved verbatim. D-10 mentioned 2x. gh flag triplet (--draft/--verify-tag/--notes-file) appears 6 times across §8 + §9. |
| `.planning/phases/16-signed-dmg-release-pipeline/release-notes-v1.3.0.md` | 4-6 bullets, MIT lead, browser features, no emojis | VERIFIED | 25 lines. 5 bullets in `What's new` section. MIT mentioned 2x. All 5 browser features named. Sequoia + Apple Silicon system req present. Emoji scan clean. Tracked in git. |
| `.planning/phases/16-signed-dmg-release-pipeline/16-02-VERIFY/second-mac-screenshot.png` | REL-06 evidence (mounted DMG window OR running app) | VERIFIED | 136 KB PNG; visually inspected — shows running Wrangle app in `All Projects / No projects yet` idle state, with `Select a project to get started` empty state on the fresh host. Stronger evidence than the planned mounted-DMG-window screenshot (proves install + launch path). Tracked in git. |
| `build/Wrangle-1.3.0.dmg` | Signed + notarized + stapled + spctl-clean (ephemeral) | VERIFIED | Still on disk at 6,549,583 bytes. SHA-256 `c4479d9df030c8b2292c258d2a1a6c9b2798a21f7f030dbfe6934b836c84fe27` matches Plan 01 + Plan 02 SUMMARIES exactly. Codesign + stapler + REL-04 spctl all live-verified. Gitignored as expected. |
| `build/export/Wrangle.app` | Signed + notarized + stapled + Gatekeeper-clean (ephemeral) | VERIFIED | Still on disk. Codesign authority chain correct. Stapler validate worked. `spctl --assess --type exec`: accepted, Notarized Developer ID. Gitignored as expected. |

### Key Link Verification

| From | To | Via | Status | Details |
|---|---|---|---|---|
| `scripts/build-release.sh` | `scripts/preflight-release.sh` | Shell invocation in build-release prologue | WIRED | L19: `"$SCRIPT_DIR/preflight-release.sh"` invoked before any build steps. Confirmed ordering: preflight at L19, xcodebuild archive at L26. |
| `scripts/create-dmg.sh` | Apple Notary service | codesign + notarytool submit + stapler staple | WIRED | L60-63 (codesign), L66-68 (notarytool submit), L70-71 (stapler staple). Live submission IDs `76fcee46-...` (.app via ditto-zip) and `47d8aae4-...` (DMG) recorded in SUMMARIES; both `Accepted`. |
| `scripts/create-dmg.sh` | Gatekeeper assessment engine | spctl -a -t open --context context:primary-signature | WIRED | L77 final verification step. Live run on existing build/Wrangle-1.3.0.dmg returns `accepted` + `source=Notarized Developer ID`. |
| `release-notes-v1.3.0.md` | GitHub Release v1.3.0 body | `gh release create --notes-file` consumes the file | WIRED | Checklist L201 references the locked path verbatim. SUMMARY records that the gh release was created via `gh release create --notes-file .planning/phases/16-signed-dmg-release-pipeline/release-notes-v1.3.0.md`. |
| `git tag v1.3.0` | GitHub origin | git push origin v1.3.0 (manual-tag-first Pattern 3a) | WIRED | `git ls-remote origin refs/tags/v1.3.0` returns one ref pinned at `1f135507f63d852e2d2d1cb6649edc36350aa5dc`. Local rev-parse confirms same SHA. |
| `build/Wrangle-1.3.0.dmg` (Plan 01 output) | Draft Release v1.3.0 assets | `gh release create --draft ... build/Wrangle-1.3.0.dmg` uploads as asset | WIRED | `gh release view v1.3.0 --repo J-Krush/wrangle --json assets`: asset list = `["Wrangle-1.3.0.dmg"]`. |

### Data-Flow Trace (Level 4)

Not applicable — this phase ships scripts, documentation, and a draft GitHub Release. There are no dynamic-data-rendering components. The closest equivalent (live notary submissions + spctl assessments) was verified directly in the truth/key-link tables above.

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|---|---|---|---|
| Preflight gate runs green on this host | `bash scripts/preflight-release.sh` | exit 0; stdout ends with `All pre-flight checks passed. Ready to build.` | PASS |
| All three release scripts pass bash syntax check | `bash -n scripts/{preflight-release,create-dmg,build-release}.sh` | exit 0 for each | PASS |
| Existing DMG passes REL-04 LOCKED command | `spctl -a -t open --context context:primary-signature -v build/Wrangle-1.3.0.dmg` | `accepted` + `source=Notarized Developer ID` | PASS |
| Existing .app passes Gatekeeper exec assessment | `spctl --assess --type exec --verbose build/export/Wrangle.app` | `accepted source=Notarized Developer ID` | PASS |
| DMG stapler ticket validates | `xcrun stapler validate -v build/Wrangle-1.3.0.dmg` | `The validate action worked!` | PASS |
| .app stapler ticket validates | `xcrun stapler validate -v build/export/Wrangle.app` | `The validate action worked!` | PASS |
| DMG SHA-256 matches SUMMARY-recorded SHA-256 (no silent re-signing) | `shasum -a 256 build/Wrangle-1.3.0.dmg` | `c4479d9df030c8b2292c258d2a1a6c9b2798a21f7f030dbfe6934b836c84fe27` (matches both SUMMARIES) | PASS |
| Draft GH Release v1.3.0 exists with DMG asset | `gh release view v1.3.0 --repo J-Krush/wrangle --json isDraft,tagName,assets` | `{"isDraft":true,"tagName":"v1.3.0","assetNames":["Wrangle-1.3.0.dmg"]}` | PASS |
| Tag v1.3.0 on origin pinned to verified commit | `git ls-remote origin refs/tags/v1.3.0` | `1f135507f63d852e2d2d1cb6649edc36350aa5dc refs/tags/v1.3.0` | PASS |
| D-10 LOCKED: unauthenticated `/releases/latest` returns 404 | `curl -s -o /dev/null -w "%{http_code}" https://api.github.com/repos/J-Krush/wrangle/releases/latest` | `404` | PASS |

### Probe Execution

Not applicable — Phase 16 does not declare conventional `scripts/*/tests/probe-*.sh` probes. The pipeline's PASS markers ARE the live preflight + codesign + stapler + spctl + gh-release commands, all of which were exercised directly in the spot-checks above (not relying on SUMMARY narration).

### Requirements Coverage

All Phase 16 requirement IDs (REL-01..REL-06) are claimed across Plan 01 (REL-01..04) and Plan 02 (REL-05..06). REQUIREMENTS.md Traceability table assigns exactly these six to Phase 16. No orphans.

| Requirement | Source Plan | Description | Status | Evidence |
|---|---|---|---|---|
| REL-01 | 16-01-PLAN | Documented + executable release procedure | SATISFIED | `scripts/build-release.sh` builds Release-config .app for arm64 macOS 15+. `docs/release-checklist.md §4-§8` documents the full procedure end-to-end (prereqs → build → DMG → Gatekeeper → draft Release). Live preflight + scripts validated. |
| REL-02 | 16-01-PLAN | Developer ID Application signing of .app + bundled binaries | SATISFIED | `build-release.sh` L31+L38: `CODE_SIGN_IDENTITY="Developer ID Application"` + `DEVELOPMENT_TEAM=3DEKQ7GUK6`. Live `codesign -dv --verbose=4 build/export/Wrangle.app`: Authority chain anchored at Developer ID Application: John Kreisher (3DEKQ7GUK6), TeamIdentifier=3DEKQ7GUK6. |
| REL-03 | 16-01-PLAN | Notarize + staple .app | SATISFIED | `build-release.sh` L55-58: notarytool submit --wait via `wrangle-notary` keychain profile (zip wrapper at L51-53). L63: `xcrun stapler staple "$APP_PATH"`. Live submission ID `76fcee46-513d-4317-8e60-4a3bf76f08ba` Accepted; stapler validate live = "The validate action worked!" |
| REL-04 | 16-01-PLAN | Signed DMG that passes `spctl -a -t open --context context:primary-signature` (LOCKED command) | SATISFIED | `create-dmg.sh` L60-63 (codesign with --timestamp --options runtime) + L77 (REL-04 LOCKED command verbatim). Live `spctl -a -t open --context context:primary-signature -v build/Wrangle-1.3.0.dmg` returns `accepted` + `source=Notarized Developer ID`. |
| REL-05 | 16-02-PLAN | Tagged draft GH Release with DMG attached | SATISFIED | Tag `v1.3.0` on origin at `1f135507f63d852e2d2d1cb6649edc36350aa5dc`. Live `gh release view v1.3.0 --repo J-Krush/wrangle --json isDraft,assets` returns `isDraft: true` + asset list `["Wrangle-1.3.0.dmg"]`. Unauth `/releases/latest` returns 404 confirming `--draft` worked. |
| REL-06 | 16-02-PLAN | DMG opens cleanly on a second Mac without Gatekeeper warning | SATISFIED | Second-mac screenshot at `.planning/phases/16-signed-dmg-release-pipeline/16-02-VERIFY/second-mac-screenshot.png` shows running Wrangle app on MacBook Pro M1 Pro / macOS Sequoia 15.6.1 (per SUMMARY attestation). Stronger evidence than mount-window — proves install + launch + idle-state on a fresh host. User attestation captured in 16-02-SUMMARY.md. |

### Anti-Patterns Found

None. All five Phase 16 modified files (scripts/preflight-release.sh, scripts/create-dmg.sh, scripts/build-release.sh, docs/release-checklist.md, release-notes-v1.3.0.md) scanned for TBD/FIXME/XXX (debt markers), TODO/HACK/PLACEHOLDER (warning markers), and placeholder copy ("not yet implemented" / "coming soon" / "will be here"). All clean.

### Anti-Regression Spot-Checks (D-09 + version invariants)

All four PASS:

| Check | Expected | Actual |
|---|---|---|
| `git reflog --since="2026-05-20" \| grep -E "filter-repo\|push.*--force\|reset.*--hard"` | empty | EMPTY |
| `grep -c 'MARKETING_VERSION = 1.3.0' Wrangle.xcodeproj/project.pbxproj` | 2 | 2 |
| `grep -c 'CURRENT_PROJECT_VERSION = 6' Wrangle.xcodeproj/project.pbxproj` | 2 | 2 |
| `git diff -- ExportOptions.plist` | empty | EMPTY |

D-09 invariant holds: no history rewrites, no force-pushes, no hard-resets. Version invariants intact. ExportOptions.plist untouched.

### Known Documented Deviations (NOT gaps)

Two deviation classes were explicitly documented in the SUMMARIES; both were intentional and accepted at the time of execution. They are NOT counted as gaps per the verification prompt:

1. **Plan 01 Rule-1 auto-fix:** preflight gate 6 switched from `grep -m1` to `grep -c` count assertion because the WrangleTests target's separate MARKETING_VERSION block (added in Plan 13-03) made `-m1` return the wrong version. Captured in commit `6ef3eea`. Re-verified live: count-based check works correctly on this host.
2. **Plan 01 Rule-4 D-10 override** for `docs/release-checklist.md` — moved from gitignored to tracked because README publicly says "release pipeline is public". `.gitignore` carries an inline comment explaining the override. Other D-10 entries (audit-report.md, launch-strategy.md, product-hunt/) remain gitignored — verified by reading SUMMARY decision rationale.
3. **Plan 02 Rule-1 auto-fix:** `codesign -dv` in release-checklist.md §8 sanity block lacked `--verbose=4`, returning false-negative on a correctly-signed DMG. Fixed in commit `1f13550` BEFORE the tag was pushed, so the shipped checklist is reproducible. Live re-verified: `codesign -dv --verbose=4 build/Wrangle-1.3.0.dmg` shows the Developer ID Application authority chain correctly.
4. **Plan 02 accepted-stronger-evidence:** second-mac screenshot captures the running app (post-install, post-launch, idle state) instead of the planned mounted-DMG-window. Visually inspected: stronger REL-06 evidence (proves install + launch path on a fresh host, not just trust handshake at mount).

### Human Verification Required

None remaining. The two `checkpoint:human-verify` tasks in the plans (Plan 01 Task 4 end-to-end pipeline execution, Plan 02 Task 2 second-Mac REL-06 attestation) were both signed off by the user during execution per the SUMMARIES. All evidence (live preflight, live spctl, screenshot, tag on origin, draft release with asset, 404 unauth) was re-verified programmatically in this pass.

### Gaps Summary

None. All 11 must-have truths verified, all 8 artifacts present and substantive, all 6 key links wired and functional, all 6 requirement IDs (REL-01..REL-06) satisfied with live evidence, all four anti-regression invariants hold, no anti-patterns in modified files. The phase goal is achieved: a documented, repeatable local-build procedure produces a signed + notarized DMG that opens cleanly on a fresh-eyes Mac without Gatekeeper warnings, and that DMG is attached to a tagged v1.3.0 GitHub Release on J-Krush/wrangle while the repo remains private.

---

_Verified: 2026-05-21T02:31:54Z_
_Verifier: Claude (gsd-verifier)_
