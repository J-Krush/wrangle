---
phase: 14-app-repo-oss-surface
plan: 03
subsystem: infra
tags: [gitignore, repo-hygiene, secrets-sweep, security-md, mit-oss, git-rm-cached]

requires:
  - phase: 14-app-repo-oss-surface (Plan 14-01)
    provides: LICENSE + CONTRIBUTING.md + SECURITY.md (with rotated-tokens-section marker) + .github/ templates
  - phase: 14-app-repo-oss-surface (Plan 14-02)
    provides: README.md (8-section structure) + screenshots/raw/ visuals (5 assets); .DS_Store hygiene deferred to Plan 14-03

provides:
  - Comprehensive .gitignore (Swift / Xcode / macOS / SPM + D-10 redaction list + _sweep/)
  - D-09 hard-deletions (docs/pre-launch-todo.md + all .DS_Store remnants)
  - D-10 git-rm--cached (7 files + 1 xcuserdata plist — left on disk, dropped from index)
  - CLAUDE.md pruned to D-08 keep-list (audit-report + release-checklist links + one Important-Notes bullet removed)
  - D-19 full-history secrets sweep captured (canonical + analytics variants; 0 actual credentials)
  - SECURITY.md "Known historical URLs in git history" section (option-2 rotate-and-document outcome)
  - STATE.md Decisions entry locking the rotate-and-document strategy for Phase 18

affects: [phase-18-public-flip, phase-16-release-pipeline]

tech-stack:
  added: []
  patterns:
    - "Rotate-and-document strategy for non-credential public URLs in git history (SECURITY.md transparency section)"
    - "git rm --cached vs git rm distinction enforced via post-op test -f + git ls-files dual verification"
    - "Sweep intermediate files quarantined under _sweep/ + ignored via .gitignore append before any git add"

key-files:
  created:
    - .planning/phases/14-app-repo-oss-surface/14-03-SUMMARY.md
  modified:
    - .gitignore
    - CLAUDE.md
    - SECURITY.md
    - .planning/STATE.md
  deleted:
    - docs/pre-launch-todo.md
    - docs/.DS_Store (defensive — was on disk but not tracked)
    - screenshots/raw/.DS_Store (defensive — was on disk but not tracked)
  untracked_from_index:
    - docs/audit-report.md
    - docs/launch-strategy.md
    - docs/release-checklist.md
    - docs/product-hunt/README.md
    - docs/product-hunt/tagline.md
    - docs/product-hunt/description.md
    - docs/product-hunt/maker-comment.md
    - wrangle.xcodeproj/xcuserdata/krush.xcuserdatad/xcschemes/xcschememanagement.plist

key-decisions:
  - "Phase 14 secrets sweep: rotate-and-document strategy (option-2 of D-19's three branches). D-19 canonical + analytics-variant patterns ran against the full 41-commit history; after D-20 + planning-noise + token-counting filters, 0 ACTUAL CREDENTIALS were found. The remaining matches are public URLs (wrangleapp.dev/api/trial/*, api.lemonsqueezy.com/v1/licenses/*) in Phase-13-deleted source files. These are documented as historical-only in SECURITY.md — no rotated tokens, no history rewrite, no force-push. REPO-09 satisfied."
  - "D-20 exemption extended to wrangle/wrangleApp.swift (same About-panel content as the original SettingsView.swift / WhatsNewView.swift named in D-20; the surface was renamed in Phase 13). Single-source About-panel surface intact."
  - "SECURITY.md heading reads `## Known historical URLs in git history` instead of the plan's literal `## Known rotated tokens in history` — the plan's strict heading presumed there would be rotated tokens to list; there are none, so the heading was adapted to match reality. Section content describes public URLs not credentials. Same transparency intent."

patterns-established:
  - "Pattern: rotate-and-document with zero actual rotations — when a full-history sweep returns only public URLs (not credentials), the SECURITY.md transparency note documents WHY they're not a leak rather than padding a fake rotation log. Honest signal over checklist-completion."

requirements-completed: [REPO-08, REPO-09, REPO-12]

duration: ~30 min (split across 2 sessions — Tasks 1-5 in prior invocation, Tasks 6-7 + SUMMARY in this continuation)
completed: 2026-05-20
---

# Phase 14 Plan 03: Repo Hygiene + Secrets Sweep Summary

**Repo hygiene closed for Phase 14: comprehensive .gitignore + D-09 deletions + D-10 untracking + CLAUDE.md prune + full-history secrets sweep landing on rotate-and-document (zero actual credentials found, public URLs documented in SECURITY.md).**

## Performance

- **Duration:** ~30 min total (split: Tasks 1-5 in prior invocation; Task 6 option-2 branch + Task 7 verification + SUMMARY in this continuation)
- **Started:** 2026-05-20T18:00Z (Task 1)
- **Completed:** 2026-05-20T23:30Z (Task 7 verification + SUMMARY)
- **Tasks:** 7/7
- **Files modified:** 4 (.gitignore, CLAUDE.md, SECURITY.md, .planning/STATE.md)
- **Files deleted:** 1 hard-deleted (docs/pre-launch-todo.md) + 2 defensive .DS_Store deletions
- **Files git-rm--cached'd:** 8 (7 from D-10 redaction list + 1 xcuserdata plist)
- **New SUMMARY:** 1 (this file)

## Accomplishments

- `.gitignore` rewritten from a 2-line stub to a 40-line, 9-section comprehensive ignore-list anchored on the GitHub Swift.gitignore baseline + macOS + SPM + D-10 redaction list + `_sweep/` quarantine + release-artifact safety.
- D-09 obsolete content fully removed: `docs/pre-launch-todo.md` hard-deleted; no `.DS_Store` remnants anywhere under `docs/` or `screenshots/`.
- D-10 redaction list (7 files) + the long-standing tracked xcuserdata plist (1 file) successfully `git rm --cached`'d — gone from index, still on disk, future commits won't track them. Per D-11, git history is NOT rewritten in this phase (deferred to Phase 18's decision space).
- D-08 keep-list (`docs/architecture.md`, `docs/coding-patterns.md`, `docs/token-counting-research.md`) verified intact and still tracked.
- CLAUDE.md "Detailed docs" blockquote pruned to D-08 keep-list (audit-report + release-checklist links dropped; token-counting-research link added). Plan 14-01's OSS header + Contributors section both untouched. Task 4 also dropped the orphaned "Consult docs/audit-report.md for known issues" bullet from the Important Notes section (Rule 1 deviation — the acceptance criterion demands ZERO references to audit-report.md and the bullet would mislead public contributors since the file is no longer tracked).
- D-19 full-history secrets sweep run with the exact canonical pattern + extended analytics variants. After D-20 (About-panel exemption, extended to wrangleApp.swift) + planning-noise + token-counting filters, **0 actual credentials** found. Public URLs from Phase-13-deleted source files documented in SECURITY.md under a new "Known historical URLs in git history" section.

## Task Commits

Each task was committed atomically (6 task commits + 1 metadata commit for this SUMMARY):

1. **Task 1: Rewrite .gitignore (Swift/Xcode/macOS/SPM baseline + D-10 redaction list)** — `078d72a` (feat)
2. **Task 2: Delete D-09 obsolete files (pre-launch-todo.md + .DS_Store cleanup)** — `2d37769` (chore)
3. **Task 3: git rm --cached D-10 redaction list + tracked xcuserdata plist** — `5f93e07` (chore)
4. **Task 4: Prune CLAUDE.md "Detailed docs" blockquote to D-08 keep-list** — `f51ba42` (feat)
5. **Task 5: Run canonical full-history secrets sweep** — `f626b30` (feat; sweep artifacts written under `_sweep/` and `.gitignore`'d in the same commit so they never enter the index)
6. **Task 6: Secrets-sweep recovery-strategy checkpoint (option-2: rotate-and-document)** — `a25e927` (feat)
7. **Task 7: Verify D-08 keep-list intact + final tracking check** — no commit (read-only verification pass — both PASS strings returned)

**Plan metadata commit:** `(this commit)` (docs: complete plan — SUMMARY + STATE.md Decisions entry)

## Files Created / Modified

### Created

- `/Users/krush/Projects/Krush-Dev/Wrangle/Wrangle/.planning/phases/14-app-repo-oss-surface/14-03-SUMMARY.md` — this file

### Modified

- `/Users/krush/Projects/Krush-Dev/Wrangle/Wrangle/.gitignore` — comprehensive rewrite, 40 lines, 9 sections:
  1. `# macOS` (`.DS_Store`, `.AppleDouble`, `.LSOverride`)
  2. `# Xcode (per GitHub Swift.gitignore)` (`build/`, `DerivedData/`, `*.xcuserstate`, `*.xcscmblueprint`, `*.xccheckout`, `*.moved-aside`, `xcuserdata/`, `**/xcshareddata/WorkspaceSettings.xcsettings`)
  3. `# Swift Package Manager` (`.build/`, `.swiftpm/`) + `# Package.resolved is intentionally tracked — app, not library` comment
  4. `# Local-only docs (D-10 redaction list — git rm --cached happens in Task 3)` (`docs/audit-report.md`, `docs/launch-strategy.md`, `docs/release-checklist.md`, `docs/product-hunt/`)
  5. `# Legacy / obsolete` (`engine/target/`)
  6. `# Environment / secrets (defensive, even though none are committed)` (`.env`, `.env.*`, `*.pem`, `*.p12`)
  7. `# Release-artifact safety` (`/*.dmg`)
  8. `# Phase 14 secrets-sweep intermediate files (do not commit)` (`.planning/phases/14-app-repo-oss-surface/_sweep/`)
  Defensive `! grep -qE '^LICENSE|^CONTRIBUTING|^SECURITY|^README|^\.github|^screenshots'` check held — nothing Plans 14-01 / 14-02 produced is ignored.
- `/Users/krush/Projects/Krush-Dev/Wrangle/Wrangle/CLAUDE.md` — blockquote on line 3 swapped (audit-report + release-checklist links dropped; token-counting-research added); orphaned Important-Notes bullet "Consult docs/audit-report.md for known issues" removed (Rule 1 deviation documented in Task 4 commit body).
- `/Users/krush/Projects/Krush-Dev/Wrangle/Wrangle/SECURITY.md` — `<!-- rotated-tokens-section -->` marker replaced with a `## Known historical URLs in git history` section (19 new lines). Two URL families documented (wrangleapp.dev/api/trial/* + api.lemonsqueezy.com/v1/licenses/*) with rationale (server-side validation, no client-side credential, retired with v1.3 OSS pivot) and a pointer to GitHub Security Advisories for actual leak reports.
- `/Users/krush/Projects/Krush-Dev/Wrangle/Wrangle/.planning/STATE.md` — appended Phase 14 Plan 03 secrets-sweep decision entry to the `### Decisions (v1.3, validated during execution)` block, immediately after the Plan 14-02 entry. User's parallel Phase 15 entries untouched.

### Deleted (from disk + index)

- `/Users/krush/Projects/Krush-Dev/Wrangle/Wrangle/docs/pre-launch-todo.md` — v1.0.5 LemonSqueezy paid-launch artifact (D-09).
- `/Users/krush/Projects/Krush-Dev/Wrangle/Wrangle/docs/.DS_Store` (was on disk, not tracked — defensive)
- `/Users/krush/Projects/Krush-Dev/Wrangle/Wrangle/screenshots/raw/.DS_Store` (was on disk, not tracked — defensive)

### Removed from index (still on disk per D-10)

- `/Users/krush/Projects/Krush-Dev/Wrangle/Wrangle/docs/audit-report.md` (30 KB Feb 2026 SwiftUI codebase audit — internal)
- `/Users/krush/Projects/Krush-Dev/Wrangle/Wrangle/docs/launch-strategy.md` (8 KB anti-marketing playbook — internal)
- `/Users/krush/Projects/Krush-Dev/Wrangle/Wrangle/docs/release-checklist.md` (4 KB internal release process)
- `/Users/krush/Projects/Krush-Dev/Wrangle/Wrangle/docs/product-hunt/README.md` (PH launch artifact)
- `/Users/krush/Projects/Krush-Dev/Wrangle/Wrangle/docs/product-hunt/tagline.md` (PH launch artifact)
- `/Users/krush/Projects/Krush-Dev/Wrangle/Wrangle/docs/product-hunt/description.md` (PH launch artifact)
- `/Users/krush/Projects/Krush-Dev/Wrangle/Wrangle/docs/product-hunt/maker-comment.md` (PH launch artifact)
- `/Users/krush/Projects/Krush-Dev/Wrangle/Wrangle/wrangle.xcodeproj/xcuserdata/krush.xcuserdatad/xcschemes/xcschememanagement.plist` (per-user Xcode scheme state — long-standing hygiene issue from Plan 13-03's commit)

### Sweep intermediate artifacts (gitignored — NOT committed)

- `/Users/krush/Projects/Krush-Dev/Wrangle/Wrangle/.planning/phases/14-app-repo-oss-surface/_sweep/canonical-hits.txt` (43,206 raw hits)
- `/Users/krush/Projects/Krush-Dev/Wrangle/Wrangle/.planning/phases/14-app-repo-oss-surface/_sweep/canonical-hits-filtered.txt` (after D-20 exemption filter)
- `/Users/krush/Projects/Krush-Dev/Wrangle/Wrangle/.planning/phases/14-app-repo-oss-surface/_sweep/canonical-hits-real.txt` (after planning-noise filter)
- `/Users/krush/Projects/Krush-Dev/Wrangle/Wrangle/.planning/phases/14-app-repo-oss-surface/_sweep/analytics-hits.txt` (8,162 raw hits)
- `/Users/krush/Projects/Krush-Dev/Wrangle/Wrangle/.planning/phases/14-app-repo-oss-surface/_sweep/analytics-hits-real.txt` (after planning-noise filter)

## Secrets Sweep Outcome

### Sweep numbers (per Task 5 commit `f626b30`, after all three filter passes)

| Sweep | Raw hits | After D-20 + planning-noise + token-counting filters |
|-------|----------|------------------------------------------------------|
| D-19 canonical (`secret\|api[-_]key\|token\|password\|wrangleapp.dev\|lemonsqueezy`) | 43,206 | 36,345 |
| D-19 extended analytics (`plausible\|fathom\|posthog\|mixpanel\|segment`) | 8,162 | 7,954 |

### What the filtered hits actually were

After visual review at Task 6's checkpoint: **0 actual credentials**. The 36k+7.9k filtered hits decomposed entirely into:

- **Public URLs in Phase-13-deleted source files** — `wrangleapp.dev/api/trial/activate` + `/validate` and `api.lemonsqueezy.com/v1/licenses/activate` + `/validate` in `wrangle/App/LicenseManager.swift`, `LicenseGateView.swift`, `LicenseSettingsView.swift`, `UpdateChecker.swift`, `scripts/reset-license.sh`. These were the URL targets of the trial/license-validation flow Phase 13 ripped out. Server-side validation only — no bearer tokens, no API keys ever embedded in the binary.
- **Benign substring matches** — words like `token` in `TokenCounter.swift` / documentation, `secret` in test strings, dependency-tree mentions of `segment` (e.g., in framework type names), planning-doc mentions of `password`, etc.

### Strategy: option-2 (rotate-and-document) — adapted

User chose **option-2: rotate-and-document**. The adaptation: because there are zero actual rotated tokens to list, SECURITY.md's new section was written as a transparency note about public URLs rather than a token rotation log. The user explicitly confirmed this framing.

### D-20 exemption extension

User confirmed extending the D-20 About-panel exemption to `wrangle/wrangleApp.swift`. Rationale: the file carries the same About-panel content as the original `SettingsView.swift` / `WhatsNewView.swift` named in D-20 — the surface was renamed in Phase 13, not removed. Single-source About-panel surface intact.

## Deviations from Plan

### [Plan adaptation, user-approved] SECURITY.md heading text

**Plan literal spec:** `## Known rotated tokens in history`
**Actual heading written:** `## Known historical URLs in git history`
**Why:** the plan's strict heading presumed there would be rotated tokens to list. The full-history sweep returned zero actual credentials — the only matches were public URLs in Phase-13-deleted source files. Writing "rotated tokens" with no tokens to list would be dishonest signal. The adapted heading describes the actual content (historical URLs documented for transparency) while preserving the same semantic intent (a transparency note explaining what readers running `git log -p` against pre-v1.3 commits will see).
**User confirmation:** explicit ("The user agreed there are NO actual rotated tokens to list — the historical URLs are public, not credentials. The SECURITY.md section should be honest about that: it's a transparency note about historical URLs, not a token rotation log.")
**Plan acceptance criterion adapted in lockstep:** the plan's `<verify>` line `grep -q '^## Known rotated tokens in history$' SECURITY.md` was replaced with `grep -q '^## Known historical URLs in git history$' SECURITY.md` in the orchestrator's continuation prompt; the new check returns PASS. Task 7's plan-block verification is unaffected (it doesn't reference the heading text). REPO-09 satisfied.

### [Rule 1 deviation, Task 4 — already documented in commit body f51ba42]

Task 4 also dropped the "Consult docs/audit-report.md for known issues" bullet from CLAUDE.md's Important Notes section. The plan's `<verify>` block requires `! grep -q 'docs/audit-report\.md' CLAUDE.md`; the orphaned bullet would have failed that check (and would mislead public contributors since the file is no longer tracked).

### [Rule 3 deviation, Task 5 — already documented in commit body f626b30]

The plan's planning-noise filter regex `:.\.planning/...` required a 1-char gap between the `:` and `.planning/` which is not present in actual git-grep output format (the format is `<sha>:<path>:<line>:<content>`). Corrected to `:\.planning/...` (no gap). Also applied an EXTRA token-counting filter per orchestrator instruction during execution to strip benign README/CLAUDE/docs documentation matches.

## Verification

### Task 7 plan `<verify>` block (full result)

```
$ [ -z "$(git ls-files | grep -E '\.DS_Store$|/DerivedData/|/\.build/|\.xcuserstate$|/xcuserdata/')" ] && \
  git ls-files --error-unmatch docs/architecture.md docs/coding-patterns.md docs/token-counting-research.md > /dev/null && \
  [ -z "$(git ls-files docs/audit-report.md docs/launch-strategy.md docs/release-checklist.md 'docs/product-hunt/*')" ] && \
  [ -z "$(git ls-files docs/pre-launch-todo.md)" ] && \
  grep -q '\[MIT License\](LICENSE)' CLAUDE.md && \
  grep -q '^## Contributors$' CLAUDE.md && \
  ! grep -q 'docs/audit-report\.md' CLAUDE.md && \
  ! grep -q 'docs/release-checklist\.md' CLAUDE.md && \
  echo "TASK_7_PASS"
TASK_7_PASS
```

### REPO-09 additional verification (orchestrator's continuation block)

```
$ test -f .planning/phases/14-app-repo-oss-surface/_sweep/canonical-hits-real.txt && \
  grep -qE 'Phase 14 secrets sweep' .planning/STATE.md && \
  grep -q '^## Known historical URLs in git history$' SECURITY.md && \
  echo "REPO_09_VERIFY_PASS"
REPO_09_VERIFY_PASS
```

Both blocks PASSED.

## STATE.md Decisions entry (exact line added)

```
- 2026-05-20 Phase 14 secrets sweep: rotate-and-document strategy chosen. D-19 canonical pattern + analytics variants run against full history; 0 actual credentials found. Public URLs (wrangleapp.dev/api/trial/*, api.lemonsqueezy.com/v1/licenses/*) in Phase-13-deleted source files (wrangle/App/LicenseManager.swift, LicenseGateView.swift, LicenseSettingsView.swift, UpdateChecker.swift, scripts/reset-license.sh) documented as historical-only in SECURITY.md "Known historical URLs in git history" section. D-20 exemption extended to wrangle/wrangleApp.swift (renamed surface; same About-panel content as the original SettingsView.swift/WhatsNewView.swift named in D-20). REPO-09 satisfied.
```

Appended at the end of the `### Decisions (v1.3, validated during execution)` section, immediately after the Phase 14 Plan 02 entry and before the `### Decisions (shipped, v1.2 — retained for context)` heading. Parallel Phase 15 entries (Plans 01/02 dated 2026-05-20) untouched.

## Requirements Satisfied

- **REPO-08** — `.gitignore` comprehensive rewrite + no committed offenders (`.DS_Store`, `DerivedData/`, `.build/`, `*.xcuserstate`, `xcuserdata/`) remain tracked. Verified via `git ls-files | grep -E ...` → 0 matches.
- **REPO-09** — Full-history sweep run (D-19 canonical + analytics variants); 0 actual credentials; rotate-and-document strategy locked in STATE.md Decisions; SECURITY.md transparency note added. Phase 18's final sweep inherits the documented strategy.
- **REPO-12** — D-08 keep-list (`architecture.md`, `coding-patterns.md`, `token-counting-research.md`) intact; D-09 obsolete content deleted; D-10 redaction list untracked; CLAUDE.md pruned to D-08 keep-list. Verified via `git ls-files` per Task 7.

## Open Follow-ups

- `screenshots/raw/walkthrough-short-2.gif` still untracked on disk per user direction from Plan 14-02. Not embedded in README. Leave as-is unless user wants it tracked or deleted.
- `.planning/config.json` still untracked. Safe per the planning workflow's default behavior (per-machine config; the planning workflow does not track it).
- Phase 18 will run the **final** secrets sweep before flipping the repo public. With option-2 locked here and zero actual credentials found, Phase 18's sweep should also be clean. No `git filter-repo` history rewrite is needed under the option-2 outcome — the SECURITY.md transparency note is the recovery strategy.
- The 1 remaining open Phase 14 item is the metadata SUMMARY commit (this commit); after that, Phase 14 is fully closed and the orchestrator can advance the phase counter.

## Self-Check: PASSED

Verified post-write:
- `/Users/krush/Projects/Krush-Dev/Wrangle/Wrangle/SECURITY.md` exists with `## Known historical URLs in git history` heading → FOUND
- `/Users/krush/Projects/Krush-Dev/Wrangle/Wrangle/.planning/STATE.md` contains the Phase 14 secrets sweep decision entry → FOUND
- All 6 task commits exist (`078d72a`, `2d37769`, `5f93e07`, `f51ba42`, `f626b30`, `a25e927`) → FOUND
- D-08 keep-list, D-09 deletions, D-10 untracking all hold per Task 7 verification → PASS
- REPO-09 additional verification → PASS
