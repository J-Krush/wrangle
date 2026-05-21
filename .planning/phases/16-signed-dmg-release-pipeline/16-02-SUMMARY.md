---
phase: 16-signed-dmg-release-pipeline
plan: 02
subsystem: infra
tags: [release-pipeline, github-release, draft-release, gh-cli, git-tag, gatekeeper, second-mac, audit-trail]

requires:
  - phase: 16-signed-dmg-release-pipeline (Plan 16-01)
    provides: build/Wrangle-1.3.0.dmg — signed + notarized + stapled + REL-04 spctl PASS; scripts/preflight-release.sh; expanded docs/release-checklist.md
  - phase: 13-app-de-commercialization
    provides: wrangle/App/WhatsNewChangelog.swift v1.3.0 entry (OSS-flip wording reused in release notes); LOCKED v1.3.0 MARKETING_VERSION
  - phase: 14-app-repo-oss-surface
    provides: D-09 anti-regression rules; D-10 redaction baseline (overridden in Plan 16-01 for release-checklist.md)

provides:
  - .planning/phases/16-signed-dmg-release-pipeline/release-notes-v1.3.0.md — 5-bullet notes leading with OSS flip + v1.2 browser features (consumed by gh release create --notes-file)
  - REL-06 second-Mac attestation — DMG opened cleanly on MacBook Pro M1 Pro running macOS Sequoia 15.6.1; screenshot of running app captured at .planning/phases/16-signed-dmg-release-pipeline/16-02-VERIFY/second-mac-screenshot.png
  - REL-05 git tag v1.3.0 pushed to origin (J-Krush/wrangle), pointing at commit 1f13550
  - REL-05 draft GH Release v1.3.0 with Wrangle-1.3.0.dmg attached as asset (NOT publicly visible per --draft + private-repo locks)

affects: [phase-18-public-flip, phase-17-landing-page]

tech-stack:
  added: []
  patterns:
    - "Pattern 3a manual-tag-first (git tag → git push origin <tag> → gh release create --verify-tag) — explicit, audit-friendly, no auto-tag-from-gh"
    - "--draft + --verify-tag + --notes-file flag triplet on gh release create"
    - "Atomic push of branch + tag via `git push --atomic origin main v1.3.0` (keeps the branch HEAD and the tag-pointed commit in lock-step on origin)"
    - "Draft-release invisibility verification: unauthenticated curl to api.github.com/repos/<owner>/<repo>/releases/latest returns 404 (private repo + draft state — D-10 LOCKED behavior carried from Phase 13)"
    - "Second-Mac REL-06 evidence: screenshot of the running app (not just the mounted DMG window) is stronger evidence — proves install + launch path on a fresh host"

key-files:
  created:
    - .planning/phases/16-signed-dmg-release-pipeline/release-notes-v1.3.0.md
    - .planning/phases/16-signed-dmg-release-pipeline/16-02-VERIFY/second-mac-screenshot.png
    - .planning/phases/16-signed-dmg-release-pipeline/16-02-SUMMARY.md
  modified:
    - docs/release-checklist.md (Rule 1 fix — codesign --verbose=4)

key-decisions:
  - "Atomic push of main + v1.3.0 tag via `git push --atomic origin main v1.3.0` instead of separate pushes. Rationale: `git push origin <tag>` only updates the tag ref, leaving origin/main behind — we wanted origin/main to match the tagged commit for audit cleanliness."
  - "Screenshot of running app accepted as stronger REL-06 evidence than the planned 'mounted DMG window' screenshot. Stronger because it proves the full install + launch + first-run path on the second Mac, not just the trust handshake at mount time."
  - "Combined .planning/STATE.md + .planning/ROADMAP.md tracking updates into the closing atomic commit alongside SUMMARY + screenshot. They were modified by Plan 16-01's mid-flow gsd-sdk state.advance-plan and roadmap.update-plan-progress calls (interactive mode = orchestrator + executor in one context), so committing them now closes Plan 16-02 cleanly without a separate tracking-only commit."

patterns-established:
  - "Phase 16 release-flow audit trail: per-plan SUMMARY captures notary submission IDs + DMG SHA-256 + tag commit SHA + GH Release URL. Future releases can use the same template structure."
  - "Acceptance-criteria self-check pattern: every plan's acceptance criteria are re-run inline before SUMMARY commit; failures are auto-fixed and re-documented in the Deviations section."

requirements-completed:
  - REL-05
  - REL-06

duration: ~30min
completed: 2026-05-21
---

# Phase 16 Plan 02: Draft GH Release + Second-Mac Verification Summary

**Pushed git tag v1.3.0 to origin, drafted GitHub Release v1.3.0 with the signed + notarized + stapled Wrangle-1.3.0.dmg attached as an asset, and captured REL-06 evidence by opening the DMG cleanly on a MacBook Pro M1 Pro running macOS Sequoia 15.6.1 — all six REL-IDs (REL-01..REL-06) for Phase 16 now satisfied.**

## Performance

- **Duration:** ~30 min (Task 1 release-notes auth: ~3 min; Task 2 second-Mac verification: ~10 min wall time including transfer; Task 3 tag+push+release+verify: ~5 min)
- **Started:** 2026-05-20T21:14Z (Plan 16-01 SUMMARY commit — Plan 02 begin)
- **Completed:** 2026-05-21T02:18Z (gh release create succeeded; 404 unauth verified)
- **Tasks:** 3 (1 file-edit + 1 blocking checkpoint:human-verify + 1 side-effect + SUMMARY)
- **Files modified:** 3 (release-notes-v1.3.0.md + screenshot + docs/release-checklist.md Rule 1 fix)
- **Commits:** 2 atomic for Plan 02 work (release-notes; codesign verbatim fix), plus this SUMMARY commit which closes the plan and updates tracking
- **Side effects on origin:** main pushed from 73bb6fe → 1f13550 (+54 commits); v1.3.0 tag created; draft Release v1.3.0 created with DMG asset

## Accomplishments

- Authored `.planning/phases/16-signed-dmg-release-pipeline/release-notes-v1.3.0.md` (5 bullets, OSS-flip narrative leading, v1.2 browser features enumerated, macOS 15 / Sequoia / Apple Silicon system req, no emojis — all 8 acceptance criteria PASS).
- Second-Mac REL-06 verified live: DMG transferred to MacBook Pro M1 Pro (macOS Sequoia 15.6.1), opened cleanly with no Gatekeeper warning, app installed to /Applications and launched directly to the editor + WhatsNew modal. Screenshot of running app captured at `16-02-VERIFY/second-mac-screenshot.png` (SHA-256 `32051fe332b86f3139d5186e879ee5c23d9e4897846b97a2fb45a374f8621423`).
- Tag `v1.3.0` (lightweight) created at commit `1f135507f63d852e2d2d1cb6649edc36350aa5dc` and pushed atomically to origin alongside main (54 commits) via `git push --atomic origin main v1.3.0`.
- Draft GitHub Release `v1.3.0` created on `J-Krush/wrangle` via `gh release create --draft --verify-tag --title v1.3.0 --notes-file ... build/Wrangle-1.3.0.dmg`. Release shows `draft: true`, lists `Wrangle-1.3.0.dmg` as the sole asset, and renders the release-notes markdown correctly in the GH UI.
- D-10 LOCKED invisibility behavior confirmed: `curl -s -o /dev/null -w "%{http_code}" https://api.github.com/repos/J-Krush/wrangle/releases/latest` returns `HTTP 404` from an unauthenticated request (private repo + draft state — the documented expected outcome).

## Task Commits

Each task was committed atomically (Pattern E):

1. **Task 1: Author release-notes-v1.3.0.md** — `dcc8c9d` (docs)
2. **Task 2: Second-Mac Gatekeeper verification** — no commit (screenshot staged for Task 3's closing commit per plan)
3. **Task 3a: codesign --verbose=4 fix in release-checklist.md** — `1f13550` (fix; pre-tag deviation auto-fixed before pushing so the shipped doc is reproducible)
4. **Task 3b: SUMMARY + screenshot + STATE/ROADMAP tracking** — *this commit*

## Pipeline Side-Effect Audit Trail

**Git operations against origin:**

| Operation | Refs touched | Outcome |
|-----------|--------------|---------|
| `git tag v1.3.0` (local, lightweight) | `refs/tags/v1.3.0` → `1f135507f63d852e2d2d1cb6649edc36350aa5dc` | created |
| `git push --atomic origin main v1.3.0` | `main` (73bb6fe..1f13550, +54 commits); `refs/tags/v1.3.0` (new) | both refs pushed atomically; no rejections |

**Tag-on-origin verification:**
```
$ git ls-remote origin refs/tags/v1.3.0
1f135507f63d852e2d2d1cb6649edc36350aa5dc	refs/tags/v1.3.0
```

**GH Release metadata:**

| Field | Value |
|-------|-------|
| Repo | J-Krush/wrangle (PRIVATE) |
| Tag | v1.3.0 |
| Title | v1.3.0 |
| Draft | true |
| Prerelease | false |
| Asset | Wrangle-1.3.0.dmg |
| Notes-file | .planning/phases/16-signed-dmg-release-pipeline/release-notes-v1.3.0.md |
| URL (draft preview) | https://github.com/J-Krush/wrangle/releases/tag/untagged-a12004e1af184cd154ed |
| Created | 2026-05-21T02:18:25Z |
| Author | J-Krush |

Note on the URL: GitHub assigns drafts a `/releases/tag/untagged-XXXXX` URL pattern until publish. When Phase 18 (FLIP-05) publishes the draft, the URL becomes `/releases/tag/v1.3.0`. This is GitHub UX, not a configuration issue — the tag association is correct (`gh release view --json tagName --jq .tagName` returns `v1.3.0`).

**Draft-invisibility verification (D-10 LOCKED — Phase 13 behavior carried forward):**
```
$ curl -s -o /dev/null -w "HTTP %{http_code}\n" https://api.github.com/repos/J-Krush/wrangle/releases/latest
HTTP 404
```
Expected for a private repo with no published releases. Confirms `--draft` plus private-repo state successfully gates visibility. Phase 18 will flip the repo public AND publish the draft, both of which are required for the in-app UpdateChecker (`api.github.com/.../releases/latest`) to start returning the v1.3.0 release.

## DMG Reproducibility Audit

**Path:** `build/Wrangle-1.3.0.dmg` (NOT committed; in gitignored `build/`)
**Size:** 7.2 MB (6,549,583 bytes)
**SHA-256:** `c4479d9df030c8b2292c258d2a1a6c9b2798a21f7f030dbfe6934b836c84fe27`

**Apple Notary submission IDs (full audit trail):**

| Pipeline step | Submission ID | Outcome | Recorded in |
|---------------|---------------|---------|-------------|
| .app notarization (via ditto-zip wrapper) | `76fcee46-513d-4317-8e60-4a3bf76f08ba` | Accepted | 16-01-SUMMARY.md |
| DMG notarization | `47d8aae4-5e81-4090-93fc-1b962f10efb1` | Accepted | 16-01-SUMMARY.md + this SUMMARY |

**Codesign authority chain (per Apple verification):**
- DMG: `Authority=Developer ID Application: John Kreisher (3DEKQ7GUK6)` → `Developer ID Certification Authority` → `Apple Root CA`
- Timestamp: `May 20, 2026 at 21:13:19` (RFC-3161 secure timestamp from Apple's TSA)
- TeamIdentifier: `3DEKQ7GUK6`

## Second-Mac REL-06 Attestation

**Test host:** MacBook Pro M1 Pro, macOS Sequoia 15.6.1
**Transfer method:** AirDrop (preferred — exercises the `com.apple.quarantine` extended attribute)
**Outcome attestation (user-reported):**
- DMG opened cleanly with no Gatekeeper "macOS cannot verify the developer" dialog
- No right-click → Open required
- No `xattr -d com.apple.quarantine` pre-treatment
- Drag-to-Applications layout rendered correctly
- App launched directly from /Applications (no "downloaded from internet" first-launch prompt)
- WhatsNew v1.3.0 modal fired correctly on first launch — proves Phase 13 WhatsNewChangelog wiring works end-to-end on a fresh host

**Evidence file:** `.planning/phases/16-signed-dmg-release-pipeline/16-02-VERIFY/second-mac-screenshot.png` (136 KB, captured 2026-05-20T22:08:01)

The screenshot shows the Wrangle app running in its empty-state ("All Projects / No projects yet") rather than the originally-specified "mounted DMG window" — this is stronger REL-06 evidence because it proves the full install + launch + idle-state path on a fresh second Mac, not just the trust handshake at mount time. Accepted deviation; documented below.

## Anti-Regression Results (D-09 + version invariants — every plan)

All four anti-regression checks PASS:

| Check | Expected | Actual |
|-------|----------|--------|
| `git reflog --since="2026-05-20" \| grep -E "filter-repo\|push.*--force\|reset.*--hard"` | empty | empty ✓ |
| `grep -c 'MARKETING_VERSION = 1.3.0' Wrangle.xcodeproj/project.pbxproj` | 2 | 2 ✓ |
| `grep -c 'CURRENT_PROJECT_VERSION = 6' Wrangle.xcodeproj/project.pbxproj` | 2 | 2 ✓ |
| `git diff -- ExportOptions.plist` | empty | empty ✓ |

D-09 stands. `git push --atomic origin main v1.3.0` is non-destructive (no force, no rewrite). `gh release create --draft` only creates a server-side GitHub object pointing at the already-pushed tag — does not rewrite any git history.

## Phase 16 Closure — All Six REL-IDs Satisfied

| ID | Description | Satisfied by |
|----|-------------|--------------|
| REL-01 | Documented + executable release procedure | docs/release-checklist.md §4-§10 + scripts/preflight-release.sh + scripts/build-release.sh + scripts/create-dmg.sh (Plan 01) |
| REL-02 | Developer ID Application signing of .app + bundled binaries | xcodebuild archive automatic signing with CODE_SIGN_IDENTITY="Developer ID Application" DEVELOPMENT_TEAM=3DEKQ7GUK6 (Plan 01 Task 4) |
| REL-03 | Notarize + staple .app | notarytool submit (id 76fcee46-...) + stapler staple build/export/Wrangle.app (Plan 01 Task 4) |
| REL-04 | Signed DMG that passes `spctl -a -t open --context context:primary-signature` | D-02 codesign step in create-dmg.sh + REL-04 LOCKED verify line; live PASS recorded in 16-01-SUMMARY.md (Plan 01 Task 4) |
| REL-05 | Tagged draft GH Release with DMG attached | git tag v1.3.0 → push → gh release create --draft --verify-tag --notes-file ... build/Wrangle-1.3.0.dmg (Plan 02 Task 3 — this commit's prelude) |
| REL-06 | DMG opens cleanly on a second Mac without Gatekeeper warning | MacBook Pro M1 Pro on macOS Sequoia 15.6.1; screenshot of running app + user attestation (Plan 02 Task 2) |

## Decisions Made

- **Atomic main + tag push** (`git push --atomic origin main v1.3.0`) over separate `git push origin main` + `git push origin v1.3.0`: prevents a transient state where origin/main is behind the tag-pointed commit. Aligns with the user's "Push all 54 with the tag" intent.
- **Accept stronger-than-asked REL-06 evidence**: screenshot of running app instead of mounted DMG window. Plan said mount-window; user produced running-app. Strictly stronger evidence; accepted with deviation note.
- **Bundle .planning/STATE.md + .planning/ROADMAP.md tracking updates into the closing SUMMARY commit** instead of a separate tracking-only commit. In interactive mode the orchestrator and executor are the same context; the tracking writes happened mid-flow (state.advance-plan after Plan 16-01 SUMMARY, roadmap.update-plan-progress after Plan 16-01 close) and need committing somewhere — folding them into this plan's closing commit satisfies the "single atomic commit per logical change" intent of Pattern E (the logical change being "close Plan 16-02 and advance phase tracking").

## Deviations from Plan

Two auto-fixes during Task 3 + one accepted-stronger-evidence deviation in Task 2.

### Auto-fixed Issues

**1. [Rule 1 — Plan + RESEARCH copy-paste error] release-checklist.md §8 codesign sanity used `codesign -dv` without `--verbose=4`**
- **Found during:** Task 3 pre-flight sanity (first live run of the §8 bash block)
- **Issue:** Both the planned bash block and the RESEARCH.md source called `codesign -dv "$DMG" 2>&1 | grep -q "Developer ID Application"`. But `codesign -dv` alone only prints Identifier / Format / Timestamp / TeamIdentifier — the Authority chain (which contains "Developer ID Application") only appears at `--verbose=4`. The grep returns exit 1 on a correctly-signed DMG, producing the misleading "FAIL: $DMG not signed" message.
- **Fix:** Replaced with `codesign -dv --verbose=4 "$DMG" 2>&1 | grep -q "Developer ID Application"`. Added inline comment explaining the `--verbose=4` requirement.
- **Files modified:** `docs/release-checklist.md` (§8)
- **Verification:** Live re-test on `build/Wrangle-1.3.0.dmg` confirms `codesign -dv --verbose=4 ... | grep "Developer ID Application"` matches `Authority=Developer ID Application: John Kreisher (3DEKQ7GUK6)`.
- **Committed in:** `1f13550` (fix(16-02): codesign sanity in release-checklist §8 needs --verbose=4)

### Accepted Deviation (stronger evidence)

**2. [Plan Step 3 — second-Mac screenshot scope] Captured running app instead of mounted DMG window**
- **Found during:** Task 2 (user-reported)
- **Issue:** Plan Step 3 specified "Capture a screenshot of the mounted DMG window (Cmd+Shift+4, drag over the window)." User completed the protocol but captured the running app's empty-state ("All Projects / No projects yet" with WhatsNew dismissed) instead.
- **Resolution:** Accepted as stronger evidence — the running-app screenshot proves the full install + launch + idle-state path on the second Mac, while the mounted-DMG-window screenshot would have only proved the trust handshake at mount time. Plan acceptance criterion ("screenshot file exists at the locked path") is satisfied; the substantive REL-06 contract ("DMG opens cleanly on a second Mac without Gatekeeper warning") is verified by the user's plain-prose attestation plus the visible-app-state evidence.
- **Files modified:** none (screenshot saved at locked path with stronger content)
- **Committed in:** *this commit*

**Total deviations:** 1 Rule-1 auto-fix + 1 accepted-stronger-evidence. No silent skips; no acceptance criteria bypassed.

## Authentication Gates

**One auth gate hit at Task 3 start:** `gh auth status` reported "You are not logged into any GitHub hosts." Per `<authentication_gates>` protocol, execution halted; user ran `gh auth login` out-of-band; verification re-ran (`✓ Logged in to github.com account J-Krush (keyring), scopes: admin:public_key, gist, read:org, repo`); Task 3 resumed and completed successfully.

## Next Phase Readiness

Phase 16 is fully closed — all six REL-IDs satisfied; both plans have SUMMARYs with self-check PASS; D-09 anti-regression clean.

**Carryover to Phase 17 (Landing Page Repositioning):**
- The draft GH Release URL becomes the "Download for macOS" target for SITE-XX once Phase 18 publishes it. Until then, the landing page can stage its "Download" button with a placeholder URL.
- DMG SHA-256 `c4479d9df030c8b2292c258d2a1a6c9b2798a21f7f030dbfe6934b836c84fe27` recorded here for cross-reference; Phase 17 can publish it on the landing page's download section if desired (optional — most users don't verify SHA themselves).

**Carryover to Phase 18 (Public Flip + v1.3.0 Release):**
- FLIP-05 publishes the draft Release (changes URL from `/releases/tag/untagged-XXX` to `/releases/tag/v1.3.0`).
- FLIP-XX flips repo visibility from PRIVATE → PUBLIC.
- After both flips, `api.github.com/.../releases/latest` returns 200 with v1.3.0 metadata, and the in-app UpdateChecker starts reporting "You're up to date" instead of the 404 fallback.
- The v1.3.0 tag is already on origin and immutable — Phase 18 only needs to publish, not re-create.

## Issues Encountered

The Rule-1 codesign fix and the auth gate are both documented above. No issues remain unresolved at plan close. Apple Notary submissions both completed in ~3 minutes each (well under the 30-minute escape valve from CONTEXT.md).

## Self-Check: PASSED

- [x] All three tasks executed
- [x] All 8 acceptance criteria for Task 1 (release notes) PASS
- [x] Task 2 blocking checkpoint: user attestation collected ("Macbook Pro M1 Pro Sequoia 15.6.1"); screenshot at locked path
- [x] Task 3 acceptance: tag on origin (1 ref, verified via git ls-remote); draft release with DMG asset; 404 unauth confirmed; SUMMARY with all required content (v1.3.0, REL-05, REL-06 references)
- [x] All six plan-level `<verification>` checks PASS
- [x] All five success criteria PASS (REL-05, REL-06 satisfied; release-notes file committed; SUMMARY committed; D-09 stands)
- [x] All four anti-regression checks PASS
- [x] Two atomic commits for Plan 02 work + this SUMMARY commit (Pattern E); audit trail complete
