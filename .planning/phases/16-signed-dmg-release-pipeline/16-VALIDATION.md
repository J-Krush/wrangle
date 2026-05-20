---
phase: 16
slug: signed-dmg-release-pipeline
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-20
---

# Phase 16 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
>
> **Phase 16 is a release-engineering phase**, not an app-code phase. The
> substitute test surface is **artifact-property assertions** (codesign /
> notarytool / stapler / spctl) plus **GH Release state assertions**. No
> Swift unit-test framework is exercised by this phase (Wrangle's
> `xcodebuild test -scheme Wrangle` covers app code from Phase 13-03 and
> stays green at the phase boundary, but does not validate the release
> pipeline).

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | shell + Apple toolchain (codesign, notarytool, stapler, spctl, gh CLI) |
| **Config file** | none — assertions run inline in `scripts/preflight-release.sh` + acceptance commands per task |
| **Quick run command** | `bash scripts/preflight-release.sh` (or inline pre-flight block if D-03 keeps it inside `build-release.sh`) |
| **Full suite command** | end-to-end: `bash scripts/build-release.sh && bash scripts/create-dmg.sh && spctl -a -t open --context context:primary-signature -v build/Wrangle-1.3.0.dmg` |
| **Estimated runtime** | ~5–20 min (notarization wait dominates; build ~1–3 min; DMG package ~30s; spctl ~1s) |

---

## Sampling Rate

- **After every task commit (Plan 1 Tasks 2–3 — script patch / doc expand):** `git status` clean, commit message lints OK. No build needed for non-output-producing edits.
- **After every output-producing task (Plan 1 Task 4):** assert the corresponding row from the Build-output or DMG-output table below.
- **After every plan wave:** N/A — atomic-commit cadence per CONTEXT.md established patterns; no waves in this phase.
- **Before `/gsd:verify-work`:** every row in Pre-execution gates + Build-output assertions + DMG-output assertions + End-state assertions + Anti-regression checks must PASS.
- **Max feedback latency:** ~20 min (worst-case notarization wait + spctl). Pre-flight gate alone is <2 s.

---

## Per-Task Verification Map

> **Note for planner:** This table is seeded against the expected 2-plan
> split from CONTEXT.md (`Plans` section: Plan 1 = patch scripts +
> expand doc + run end-to-end; Plan 2 = second-Mac verify + draft GH
> Release). The planner MUST overwrite task IDs and rows here to match
> the actual PLAN.md task breakdown — including any sub-task split of
> Plan 1 Task 4 into `4a .app build` / `4b DMG build`.

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 16-01-01 | 01 | 1 | REL-01, REL-02 | — | Pre-flight blocks build when cert/notary/working-tree state is wrong | artifact | `bash scripts/preflight-release.sh` exits 0 | ❌ W0 | ⬜ pending |
| 16-01-02 | 01 | 1 | REL-04 | — | DMG signed with Developer ID + secure timestamp before notarization (D-02) | artifact | `codesign -dv --verbose=4 build/Wrangle-1.3.0.dmg 2>&1 \| grep -E "Developer ID Application\|Timestamp="` | ✅ existing | ⬜ pending |
| 16-01-03 | 01 | 1 | REL-01 | — | release-checklist.md expanded with 6 sections per D-04 | doc | `grep -E "^## (Prereqs\|Build / sign / notarize\|DMG packaging\|Gatekeeper verification\|Draft GitHub Release)" docs/release-checklist.md \| wc -l` ≥ 5 | ✅ existing | ⬜ pending |
| 16-01-04 | 01 | 1 | REL-02, REL-03 | — | `.app` is signed + stapled + Gatekeeper-clean | artifact | `spctl --assess --type exec --verbose build/export/Wrangle.app` prints `accepted` | ✅ existing | ⬜ pending |
| 16-01-05 | 01 | 1 | REL-04 (LOCKED) | — | DMG passes primary-signature assessment | artifact | `spctl -a -t open --context context:primary-signature -v build/Wrangle-1.3.0.dmg` prints `accepted` + `source=Notarized Developer ID` | ✅ existing | ⬜ pending |
| 16-02-01 | 02 | 2 | REL-06, D-05 | — | DMG opens on second Apple Silicon Mac (macOS 15+) without Gatekeeper prompt | manual | screenshot capture + optional `spctl -a -v` on second Mac | N/A — manual | ⬜ pending |
| 16-02-02 | 02 | 2 | REL-05 | — | `v1.3.0` tag pushed; draft GH Release created with DMG asset | artifact | `gh release view v1.3.0` shows `Status: Draft` + `Wrangle-1.3.0.dmg` asset | ❌ W0 | ⬜ pending |
| 16-02-03 | 02 | 2 | REL-05 | — | Draft NOT publicly visible via `releases/latest` (private repo + draft) | artifact | `curl -s -o /dev/null -w "%{http_code}" https://api.github.com/repos/J-Krush/wrangle/releases/latest` returns `404` | ✅ existing endpoint | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `scripts/preflight-release.sh` — embeds the pre-execution gate table as a callable script. Alternative per D-03: inline at top of `build-release.sh` (planner choice; either form satisfies Wave 0).
- [ ] `.planning/phases/16-signed-dmg-release-pipeline/release-notes-v1.3.0.md` — 4–6 bullets per CONTEXT.md discretion; consumed by Plan 2 Task 2 via `gh release create --notes-file`.

*Test framework note:* `xcodebuild test -scheme Wrangle -only-testing:WrangleTests` exists from Phase 13-03 and exercises Swift app code, not the release pipeline. Phase 16 does **not** invoke it; the artifact-property assertions in the tables below are the substitute test surface for this release-engineering phase.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| DMG opens on a fresh-eyes second Mac without Gatekeeper warning | REL-06, D-05 | Gatekeeper's online-check vs stapled-ticket fallback can only be exercised on a host that has never seen the signing identity locally; requires physical second machine | 1. Copy `build/Wrangle-1.3.0.dmg` to second Apple Silicon Mac (macOS 15+) via AirDrop / USB / external drive. 2. Double-click DMG in Finder. 3. Confirm DMG mounts immediately with drag-to-Applications layout and NO right-click → Open prompt. 4. Capture screenshot of mounted DMG window. 5. (Optional) Run `spctl -a -v /Volumes/Wrangle/Wrangle.app` on second Mac; capture output. |
| Notarization succeeds against Apple's service | REL-03 | Apple's notary service is an external dependency; pass/fail can only be observed by running `notarytool submit … --wait` and inspecting the returned status | Run `bash scripts/build-release.sh` end-to-end; watch for `status: Accepted` from notarytool. If `status: Invalid`, run `xcrun notarytool log <submission-id> --keychain-profile wrangle-notary` and triage (see RESEARCH.md Pitfalls 1–4). |

---

## Anti-Regression Checks

Run at phase gate (before `/gsd:verify-work`). Source: RESEARCH.md Validation Architecture §"Anti-regression checks".

| Check | Command | Pass Criterion |
|-------|---------|----------------|
| D-09: No history rewrites this session | `git reflog --since="2026-05-20" \| grep -E "filter-repo\|push.*--force\|reset.*--hard"` | empty output |
| MARKETING_VERSION unchanged at 1.3.0 | `grep MARKETING_VERSION Wrangle.xcodeproj/project.pbxproj` | all occurrences `= 1.3.0;` |
| `CURRENT_PROJECT_VERSION` unchanged at 6 | `grep CURRENT_PROJECT_VERSION Wrangle.xcodeproj/project.pbxproj` | all occurrences `= 6;` |
| No `git push --force` in session history | `fc -l 1 \| grep "push.*--force"` (zsh) | empty output |
| No provisioning-profile churn | `git diff --name-only HEAD~10..HEAD -- '*.mobileprovision' '*.provisionprofile'` | empty output |
| `ExportOptions.plist` unchanged | `git diff HEAD~10..HEAD -- ExportOptions.plist` | empty (or only whitespace) |

---

## Validation Sign-Off

- [ ] All tasks have an artifact-property assertion or are explicitly marked manual-only in the table above
- [ ] Sampling continuity: no 3 consecutive tasks without an automated artifact assertion (Plan 1 has 5 consecutive automated rows; Plan 2's manual second-Mac row is bracketed by automated `gh release` + `curl /releases/latest` rows — compliant)
- [ ] Wave 0 covers both gaps (`preflight-release.sh` + `release-notes-v1.3.0.md`) before Plan 1 Task 4 executes
- [ ] No watch-mode flags (none applicable to release-engineering tasks)
- [ ] Feedback latency: pre-flight <2 s; build+sign+notarize+staple end-to-end <20 min (notarization wait dominates)
- [ ] `nyquist_compliant: true` set in frontmatter once the planner updates the Per-Task Verification Map to match real task IDs

**Approval:** pending
