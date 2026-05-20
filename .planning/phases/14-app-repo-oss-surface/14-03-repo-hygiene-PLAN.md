---
id: 14-03-repo-hygiene
phase: 14-app-repo-oss-surface
plan: 03
type: execute
wave: 3
depends_on: ["14-01", "14-02"]
files_modified:
  - .gitignore
  - CLAUDE.md
  - SECURITY.md
  - docs/pre-launch-todo.md
  - docs/.DS_Store
  - docs/audit-report.md
  - docs/launch-strategy.md
  - docs/release-checklist.md
  - docs/product-hunt/README.md
  - docs/product-hunt/tagline.md
  - docs/product-hunt/description.md
  - docs/product-hunt/maker-comment.md
  - wrangle.xcodeproj/xcuserdata/krush.xcuserdatad/xcschemes/xcschememanagement.plist
autonomous: false

requirements: [REPO-08, REPO-09, REPO-12]

must_haves:
  truths:
    - "`.gitignore` is a comprehensive rewrite based on GitHub's Swift.gitignore + macOS + Xcode + SPM + the D-10 redaction list; no tracked `.DS_Store`, `DerivedData/`, `.build/`, `*.xcuserstate`, or `xcuserdata/` files remain."
    - "Per D-09, `docs/pre-launch-todo.md` and any tracked `docs/.DS_Store` are deleted from disk and index."
    - "Per D-10, `docs/audit-report.md`, `docs/launch-strategy.md`, `docs/release-checklist.md`, and `docs/product-hunt/` are `git rm --cached`ed (left the index, stay on disk, future commits don't track them) and listed in `.gitignore`. Per D-11, Phase 14 only changes the working tree + index — git history rewrite is deferred to Phase 18."
    - "Per D-08, `docs/architecture.md`, `docs/coding-patterns.md`, and `docs/token-counting-research.md` are preserved as-is."
    - "Full-history secrets sweep is run with the canonical D-19 forbidden-token list + analytics-key variants; if clean → REPO-09 satisfied; if hits → an interactive checkpoint surfaces the hits and the user chooses filter-repo vs rotate-and-document. Per D-20, `wrangleapp.dev` is exempt inside the About-panel surface (Phase 13 D-12 exemption); any sweep hit outside the About-panel is a genuine find."
    - "CLAUDE.md's `> **Detailed docs:**` blockquote is surgically pruned to drop links to audit-report.md and release-checklist.md (those files are no longer tracked); architecture.md, coding-patterns.md, token-counting-research.md links remain."
  artifacts:
    - path: ".gitignore"
      provides: "Comprehensive Swift/Xcode/macOS/SPM exclusions + D-10 redaction list"
      contains: "xcuserdata/"
    - path: "CLAUDE.md"
      provides: "Detailed-docs blockquote pruned to D-08 keep-list only"
      contains_not: "audit-report.md"
  key_links:
    - from: ".gitignore"
      to: "docs/audit-report.md"
      via: ".gitignore entry"
      pattern: "docs/audit-report\\.md"
    - from: ".gitignore"
      to: "xcuserdata/"
      via: ".gitignore entry"
      pattern: "xcuserdata/"
---

<objective>
Clean up the repo's hygiene surface before Phase 18's public flip: write a
comprehensive `.gitignore` (REPO-08), `git rm --cached` the D-10 redaction
list + delete the D-09 obsolete files (REPO-12), prune CLAUDE.md's Detailed
Docs blockquote to match the new D-08 keep-list (also REPO-12), and run the
full-history secrets sweep (REPO-09) with an interactive checkpoint at
execution time if any hit surfaces.

Purpose: This is the last Phase-14 plan because every prior plan adds files
to the tracked tree, and the secrets sweep must run AFTER all other Phase 14
writes so it captures any new artifact. The `.gitignore` rewrite must also
post-date Plans 14-01 and 14-02 so it doesn't accidentally ignore files
those plans created (LICENSE, CONTRIBUTING.md, SECURITY.md, README.md,
`.github/`, `screenshots/raw/*`).
Output: One rewritten `.gitignore`, one CLAUDE.md edit, 1 file deleted, 1
file untracked (.DS_Store if tracked), 7 files `git rm --cached`ed, 1 plist
`git rm --cached`ed, full-history sweep run, SECURITY.md possibly appended.
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/PROJECT.md
@.planning/ROADMAP.md
@.planning/STATE.md
@.planning/REQUIREMENTS.md
@.planning/phases/14-app-repo-oss-surface/14-CONTEXT.md
@.planning/phases/14-app-repo-oss-surface/14-01-oss-scaffold-PLAN.md
@.planning/phases/14-app-repo-oss-surface/14-02-readme-and-screenshots-PLAN.md
@.gitignore
@CLAUDE.md

<interfaces>
<!-- Locked file lists from CONTEXT.md D-08, D-09, D-10 -->

D-08 KEEP as-is (do NOT touch — must remain tracked):
- docs/architecture.md
- docs/coding-patterns.md
- docs/token-counting-research.md

D-09 DELETE from disk AND index (obsolete content):
- docs/pre-launch-todo.md (references stripped v1.0.5 LemonSqueezy paid flow)
- docs/.DS_Store (per git status not tracked, but `find docs/ -name .DS_Store` may show it on disk — delete any instance)
- screenshots/raw/.DS_Store (also on disk — delete)

D-10 git rm --cached (leave on disk, drop from index, add to .gitignore):
- docs/audit-report.md
- docs/launch-strategy.md
- docs/release-checklist.md
- docs/product-hunt/README.md
- docs/product-hunt/tagline.md
- docs/product-hunt/description.md
- docs/product-hunt/maker-comment.md

Also git rm --cached (per CONTEXT.md Integration Points + STATE.md observation — long-standing hygiene issue):
- wrangle.xcodeproj/xcuserdata/krush.xcuserdatad/xcschemes/xcschememanagement.plist

D-19 canonical secrets-sweep grep pattern (must run exactly):
- `secret|api[-_]key|token|password|wrangleapp.dev|lemonsqueezy`

D-19 extended analytics-key variants (must also run):
- `plausible|fathom|posthog|mixpanel|segment`

D-20 known exemption (single legitimate hit, not a violation):
- `wrangleapp.dev` inside any About-panel credit surface in `wrangle/App/SettingsView.swift` or `wrangle/App/WhatsNewView.swift` (Phase 13 D-12). Any OTHER hit on `wrangleapp.dev` is a genuine find.

GitHub Swift.gitignore baseline (CONTEXT.md canonical_refs):
- https://github.com/github/gitignore/blob/main/Swift.gitignore
- Patterns to include: `*.xcuserstate`, `*.xcuserdatad`, `xcuserdata/`, `*.moved-aside`, `*.xccheckout`, `*.xcscmblueprint`, `build/`, `DerivedData/`, `.swiftpm/`, `.build/`. Package.resolved is INTENTIONALLY tracked (Wrangle is an app, not a library). Carthage / fastlane / Playgrounds patterns omitted (not used in this project).
</interfaces>
</context>

<tasks>

<task type="auto">
  <name>Task 1: Rewrite .gitignore (Swift.gitignore baseline + macOS + SPM + D-10 redaction list)</name>
  <files>.gitignore</files>
  <read_first>
    - .gitignore (current — 2 lines: `build/` + `engine/target/`; the full rewrite replaces this entirely)
    - .planning/phases/14-app-repo-oss-surface/14-CONTEXT.md (D-10 redaction list + D-09 obsolete list + the xcuserdata note in code_context)
    - .planning/REQUIREMENTS.md §REPO-08
    - GitHub's Swift.gitignore (https://github.com/github/gitignore/blob/main/Swift.gitignore) — fetch the current canonical content via WebFetch or by reading a known-good snapshot; baseline patterns to include are listed in the interfaces block above
  </read_first>
  <action>
    Rewrite `.gitignore` at repo root. Replace the current 2-line content (`build/` + `engine/target/`) entirely. New file is sectioned with `# Comment headers` for readability. Required sections (in order):

    Section "# macOS" — lines: `.DS_Store`, `.AppleDouble`, `.LSOverride`.

    Section "# Xcode (per GitHub Swift.gitignore)" — lines: `build/`, `DerivedData/`, `*.xcuserstate`, `*.xcscmblueprint`, `*.xccheckout`, `*.moved-aside`, `xcuserdata/`, `**/xcshareddata/WorkspaceSettings.xcsettings`.

    Section "# Swift Package Manager" — lines: `.build/`, `.swiftpm/`. Add a comment line stating `# Package.resolved is intentionally tracked — app, not library`.

    Section "# Local-only docs (D-10 redaction list — git rm --cached happens in Task 3)" — lines: `docs/audit-report.md`, `docs/launch-strategy.md`, `docs/release-checklist.md`, `docs/product-hunt/`.

    Section "# Legacy / obsolete" — line: `engine/target/` (carried forward from current `.gitignore`).

    Section "# Environment / secrets (defensive, even though none are committed)" — lines: `.env`, `.env.*`, `*.pem`, `*.p12`.

    Section "# Release-artifact safety" — line: `/*.dmg` (root-scoped — DMGs produced by scripts/build-release.sh land under `build/` which is already ignored; the root-scoped pattern catches stray copies).

    Important: the file MUST NOT ignore anything Plans 14-01 / 14-02 created — that is, do NOT include patterns matching `LICENSE`, `CONTRIBUTING.md`, `SECURITY.md`, `README.md`, `.github/`, or `screenshots/`. Per REPO-08.
  </action>
  <verify>
    <automated>test -f .gitignore && grep -q '^\.DS_Store$' .gitignore && grep -q '^xcuserdata/$' .gitignore && grep -q '^DerivedData/$' .gitignore && grep -q '^\*\.xcuserstate$' .gitignore && grep -q '^\.build/$' .gitignore && grep -q '^\.swiftpm/$' .gitignore && grep -q '^docs/audit-report\.md$' .gitignore && grep -q '^docs/launch-strategy\.md$' .gitignore && grep -q '^docs/release-checklist\.md$' .gitignore && grep -q '^docs/product-hunt/$' .gitignore && ! grep -qE '^LICENSE|^CONTRIBUTING|^SECURITY|^README|^\.github|^screenshots' .gitignore</automated>
  </verify>
  <acceptance_criteria>
    - `.gitignore` exists and is at least 25 lines (substantive, not the old 2-line stub).
    - File contains the required patterns (each anchored with `^…$`): `.DS_Store`, `xcuserdata/`, `DerivedData/`, `*.xcuserstate`, `.build/`, `.swiftpm/`, `docs/audit-report.md`, `docs/launch-strategy.md`, `docs/release-checklist.md`, `docs/product-hunt/`.
    - File does NOT contain any pattern starting with `LICENSE`, `CONTRIBUTING`, `SECURITY`, `README`, `.github`, or `screenshots` (defensive: nothing Plans 14-01/14-02 wrote should be ignored).
    - File contains a `# Package.resolved is intentionally tracked` comment (documents the deliberate omission).
  </acceptance_criteria>
  <done>
    `.gitignore` is the comprehensive Swift/Xcode/macOS/SPM baseline + D-10 redaction list. Subsequent tasks rely on these patterns being in place before any `git rm --cached`.
  </done>
</task>

<task type="auto">
  <name>Task 2: Delete D-09 obsolete files from disk + index</name>
  <files>docs/pre-launch-todo.md, docs/.DS_Store, screenshots/raw/.DS_Store</files>
  <read_first>
    - .planning/phases/14-app-repo-oss-surface/14-CONTEXT.md (D-09 — delete from disk + don't reintroduce)
    - .planning/REQUIREMENTS.md §REPO-12
  </read_first>
  <action>
    Hard-delete the D-09 obsolete files:

    1. `git rm docs/pre-launch-todo.md` — normal `rm` (file is tracked per `git ls-files`); the file's content references the stripped v1.0.5 LemonSqueezy paid-launch flow that Phase 13 wiped from the binary. It would be a confusing artifact in a public OSS repo and must not survive.

    2. `find docs -name .DS_Store -delete 2>/dev/null` — defensive cleanup of any local `.DS_Store` under `docs/` (per git ls-files none are currently tracked, but `ls -la docs/` shows one exists on disk at 6148 bytes; with `.gitignore` now ignoring `.DS_Store` globally per Task 1, the on-disk copy is no longer a tracking risk — but the on-disk presence is hygiene noise, so delete it).

    3. `find screenshots -name .DS_Store -delete 2>/dev/null` — same defensive cleanup for `screenshots/raw/.DS_Store`.

    If any of the three delete operations report "no such file," that's fine (idempotent). Per REPO-12 + D-09.
  </action>
  <verify>
    <automated>! test -f docs/pre-launch-todo.md && ! git ls-files | grep -q '^docs/pre-launch-todo\.md$' && [ -z "$(find docs -name .DS_Store 2>/dev/null)" ] && [ -z "$(find screenshots -name .DS_Store 2>/dev/null)" ]</automated>
  </verify>
  <acceptance_criteria>
    - `docs/pre-launch-todo.md` does not exist on disk.
    - `docs/pre-launch-todo.md` is not in the git index (`git ls-files` returns no match).
    - No `.DS_Store` files exist anywhere under `docs/` (`find docs -name .DS_Store` returns empty).
    - No `.DS_Store` files exist anywhere under `screenshots/` (`find screenshots -name .DS_Store` returns empty).
    - The D-08 keep-list is untouched: `docs/architecture.md`, `docs/coding-patterns.md`, `docs/token-counting-research.md` all still exist on disk and in the index.
  </acceptance_criteria>
  <done>
    D-09 deletions complete. Obsolete content gone.
  </done>
</task>

<task type="auto">
  <name>Task 3: git rm --cached D-10 redaction list + tracked xcuserdata</name>
  <files>docs/audit-report.md, docs/launch-strategy.md, docs/release-checklist.md, docs/product-hunt/README.md, docs/product-hunt/tagline.md, docs/product-hunt/description.md, docs/product-hunt/maker-comment.md, wrangle.xcodeproj/xcuserdata/krush.xcuserdatad/xcschemes/xcschememanagement.plist</files>
  <read_first>
    - .planning/phases/14-app-repo-oss-surface/14-CONTEXT.md (D-10 — `git rm --cached`, files stay on disk, leave the index, future commits don't track them; D-11 — history rewrite deferred to Phase 18)
    - .planning/phases/14-app-repo-oss-surface/14-CONTEXT.md (code_context section — tracked xcuserdata plist note)
    - .planning/REQUIREMENTS.md §REPO-08, §REPO-12
  </read_first>
  <action>
    Run `git rm --cached` (NOT `git rm`) for each file in the D-10 redaction list plus the long-standing xcuserdata plist hygiene issue. The `--cached` flag is critical — it removes from the git index only, leaves the working-tree copy untouched. The user's local dev workflow is unaffected (files still openable locally); future commits no longer track them; the `.gitignore` entries written in Task 1 prevent them from re-entering the index on a future `git add`.

    Per CONTEXT.md D-11, this task only touches the working tree + index. The files remain in commit HISTORY — Phase 18 will decide whether to `git filter-repo` them out of history.

    Files to `git rm --cached`:
    1. `docs/audit-report.md` (30 KB Feb 2026 SwiftUI codebase audit — internal)
    2. `docs/launch-strategy.md` (8 KB anti-marketing playbook, pre-OSS-pivot, internal)
    3. `docs/release-checklist.md` (4 KB internal release process)
    4. `docs/product-hunt/README.md` (PH launch artifact)
    5. `docs/product-hunt/tagline.md` (PH launch artifact)
    6. `docs/product-hunt/description.md` (PH launch artifact)
    7. `docs/product-hunt/maker-comment.md` (PH launch artifact)
    8. `wrangle.xcodeproj/xcuserdata/krush.xcuserdatad/xcschemes/xcschememanagement.plist` (long-standing hygiene issue — per-user Xcode scheme state never belongs in git)

    For each file: verify it exists in the index pre-operation (`git ls-files --error-unmatch <path>` should succeed); run `git rm --cached <path>`; verify post-operation that the file still exists on disk (`test -f <path>`) AND no longer appears in the index (`git ls-files <path>` returns empty).

    Per REPO-08 (the xcuserdata one) + REPO-12 (the docs ones) + D-10.
  </action>
  <verify>
    <automated>test -f docs/audit-report.md && test -f docs/launch-strategy.md && test -f docs/release-checklist.md && test -f docs/product-hunt/README.md && test -f docs/product-hunt/tagline.md && test -f docs/product-hunt/description.md && test -f docs/product-hunt/maker-comment.md && test -f wrangle.xcodeproj/xcuserdata/krush.xcuserdatad/xcschemes/xcschememanagement.plist && [ -z "$(git ls-files docs/audit-report.md docs/launch-strategy.md docs/release-checklist.md 'docs/product-hunt/*' 'wrangle.xcodeproj/xcuserdata/krush.xcuserdatad/xcschemes/xcschememanagement.plist')" ]</automated>
  </verify>
  <acceptance_criteria>
    - All 8 files still exist on disk after the operation (`test -f` succeeds for each).
    - None of the 8 files appears in the git index (`git ls-files <each path>` returns empty for all).
    - `git status` shows each as a "deleted" change staged for commit (this is the `--cached` removal — the file is on disk but no longer tracked).
    - The D-08 keep-list (`docs/architecture.md`, `docs/coding-patterns.md`, `docs/token-counting-research.md`) is STILL tracked: `git ls-files docs/architecture.md` returns the file.
  </acceptance_criteria>
  <done>
    8 files removed from the index; all still on disk; D-08 keep-list intact. Working-tree state matches D-10 + D-11.
  </done>
</task>

<task type="auto">
  <name>Task 4: Prune CLAUDE.md "Detailed docs" blockquote to D-08 keep-list</name>
  <files>CLAUDE.md</files>
  <read_first>
    - CLAUDE.md (current — line 3 contains `> **Detailed docs:** [Architecture & Structure](docs/architecture.md) | [Coding Patterns](docs/coding-patterns.md) | [Audit Report](docs/audit-report.md) | [Release Checklist](docs/release-checklist.md)`)
    - .planning/phases/14-app-repo-oss-surface/14-CONTEXT.md (D-08 keep-list + D-10 redaction list)
    - .planning/REQUIREMENTS.md §REPO-12
  </read_first>
  <action>
    Surgically edit the existing `> **Detailed docs:**` blockquote near the top of `CLAUDE.md` (currently line 3). Remove the two links that point at files Task 3 just removed from the index:

    - Remove `[Audit Report](docs/audit-report.md)` and the preceding ` | ` separator.
    - Remove `[Release Checklist](docs/release-checklist.md)` and the preceding ` | ` separator.

    Optionally add a link to `[Token Counting Research](docs/token-counting-research.md)` (D-08 keep-list third entry) — planner's call (CONTEXT.md Claude's Discretion on CLAUDE.md edits). Recommendation: add it, since it's already on the D-08 keep-list and is contributor-useful.

    Final shape (after edit): `> **Detailed docs:** [Architecture & Structure](docs/architecture.md) | [Coding Patterns](docs/coding-patterns.md) | [Token Counting Research](docs/token-counting-research.md)`

    Do NOT touch Plan 14-01 Task 5's additions (the OSS-header blockquote and the `## Contributors` section). Do NOT touch any other CLAUDE.md content. Per REPO-12.
  </action>
  <verify>
    <automated>grep -q '^> \*\*Detailed docs:\*\*' CLAUDE.md && grep -q 'docs/architecture\.md' CLAUDE.md && grep -q 'docs/coding-patterns\.md' CLAUDE.md && ! grep -q 'docs/audit-report\.md' CLAUDE.md && ! grep -q 'docs/release-checklist\.md' CLAUDE.md && grep -q '\[MIT License\](LICENSE)' CLAUDE.md && grep -q '^## Contributors$' CLAUDE.md</automated>
  </verify>
  <acceptance_criteria>
    - `CLAUDE.md` still contains a `> **Detailed docs:**` blockquote.
    - That blockquote still links to `docs/architecture.md` and `docs/coding-patterns.md`.
    - `CLAUDE.md` contains ZERO references to `docs/audit-report.md`.
    - `CLAUDE.md` contains ZERO references to `docs/release-checklist.md`.
    - Plan 14-01's `[MIT License](LICENSE)` link is still present (the OSS header is intact).
    - Plan 14-01's `## Contributors` section is still present.
  </acceptance_criteria>
  <done>
    CLAUDE.md "Detailed docs" links match the D-08 keep-list. REPO-12 satisfied jointly with Tasks 2 and 3.
  </done>
</task>

<task type="auto">
  <name>Task 5: Run the canonical full-history secrets sweep</name>
  <files></files>
  <read_first>
    - .planning/phases/14-app-repo-oss-surface/14-CONTEXT.md (D-19 — exact canonical grep pattern + extended analytics-key variants; D-20 — wrangleapp.dev About-panel exemption)
    - .planning/REQUIREMENTS.md §REPO-09
    - .planning/phases/13-app-de-commercialization/13-02-SUMMARY.md (Phase 13 APP-13 exemption list — `wrangleapp.dev` confirmed in About-panel only)
  </read_first>
  <action>
    Run the canonical full-history secrets sweep per D-19. This task does NOT modify any files; it produces a HITS list that drives Task 6's interactive checkpoint decision.

    **Sweep 1 — D-19 canonical pattern (mandatory):**

    Command (run from repo root):

        git rev-list --all | xargs git grep -i -n 'secret\|api[-_]key\|token\|password\|wrangleapp.dev\|lemonsqueezy' 2>/dev/null

    **Sweep 2 — D-19 extended analytics-key variants (mandatory):**

        git rev-list --all | xargs git grep -i -n 'plausible\|fathom\|posthog\|mixpanel\|segment' 2>/dev/null

    **Capture results to a temp file** for Task 6's checkpoint to consume:

        mkdir -p .planning/phases/14-app-repo-oss-surface/_sweep
        git rev-list --all | xargs git grep -i -n 'secret\|api[-_]key\|token\|password\|wrangleapp.dev\|lemonsqueezy' 2>/dev/null > .planning/phases/14-app-repo-oss-surface/_sweep/canonical-hits.txt || true
        git rev-list --all | xargs git grep -i -n 'plausible\|fathom\|posthog\|mixpanel\|segment' 2>/dev/null > .planning/phases/14-app-repo-oss-surface/_sweep/analytics-hits.txt || true

    **Filter exemptions per D-20:**

    Any hit on `wrangleapp.dev` inside `wrangle/App/SettingsView.swift` or `wrangle/App/WhatsNewView.swift` is the legitimate About-panel credit surface preserved in Phase 13 D-12. Filter those out:

        grep -v 'wrangle/App/SettingsView\.swift\|wrangle/App/WhatsNewView\.swift' .planning/phases/14-app-repo-oss-surface/_sweep/canonical-hits.txt > .planning/phases/14-app-repo-oss-surface/_sweep/canonical-hits-filtered.txt || true

    Also filter the noise hits from the planning artifacts themselves — every PLAN.md and CONTEXT.md in `.planning/phases/14-app-repo-oss-surface/` literally contains the words `secret`, `token`, `wrangleapp.dev`, `lemonsqueezy` because they document the secrets-sweep work. Those are not real hits:

        grep -v '^\.planning/phases/14-app-repo-oss-surface/\|:.\.planning/phases/14-app-repo-oss-surface/' .planning/phases/14-app-repo-oss-surface/_sweep/canonical-hits-filtered.txt > .planning/phases/14-app-repo-oss-surface/_sweep/canonical-hits-real.txt || true

    Also filter the same `.planning/phases/14-app-repo-oss-surface/` noise from the analytics sweep:

        grep -v '^\.planning/phases/14-app-repo-oss-surface/\|:.\.planning/phases/14-app-repo-oss-surface/' .planning/phases/14-app-repo-oss-surface/_sweep/analytics-hits.txt > .planning/phases/14-app-repo-oss-surface/_sweep/analytics-hits-real.txt || true

    **Decision branch:**

    Count the real hits:

        CANONICAL_COUNT=$(wc -l < .planning/phases/14-app-repo-oss-surface/_sweep/canonical-hits-real.txt 2>/dev/null || echo 0)
        ANALYTICS_COUNT=$(wc -l < .planning/phases/14-app-repo-oss-surface/_sweep/analytics-hits-real.txt 2>/dev/null || echo 0)

    - If both counts are 0 → REPO-09 satisfied with NO further work. Task 6 (the interactive checkpoint) becomes a no-op informational confirmation. Record `secrets_sweep: clean` in the SUMMARY.
    - If either count is >0 → REPO-09 requires Task 6's interactive checkpoint to fire. The hits files are the checkpoint input.

    Important: note that the sweep results are intentionally written under `.planning/phases/14-app-repo-oss-surface/_sweep/` which itself becomes a "noise source" if this task is re-run. That's fine — the `grep -v` filter above strips matches from that directory. Add `.planning/phases/14-app-repo-oss-surface/_sweep/` to `.gitignore` (append, do NOT rewrite the rest of `.gitignore`) so these intermediate files don't get committed:

        echo '' >> .gitignore
        echo '# Phase 14 secrets-sweep intermediate files (do not commit)' >> .gitignore
        echo '.planning/phases/14-app-repo-oss-surface/_sweep/' >> .gitignore

    Per REPO-09 + D-19 + D-20.
  </action>
  <verify>
    <automated>test -f .planning/phases/14-app-repo-oss-surface/_sweep/canonical-hits.txt && test -f .planning/phases/14-app-repo-oss-surface/_sweep/canonical-hits-real.txt && test -f .planning/phases/14-app-repo-oss-surface/_sweep/analytics-hits-real.txt && grep -q '_sweep/' .gitignore</automated>
  </verify>
  <acceptance_criteria>
    - Both raw hits files exist: `canonical-hits.txt` and `analytics-hits.txt`.
    - Both filtered hits files exist: `canonical-hits-real.txt` and `analytics-hits-real.txt`.
    - `.gitignore` now contains a `_sweep/` exclusion (so these intermediate files do not get committed).
    - The sweep COMMANDS used were exactly the D-19 canonical pattern + analytics variants (verified by checking the raw hits file headers / command record — executor records the exact commands run in the SUMMARY).
    - Exemption filter for D-20 (`wrangle/App/SettingsView.swift` + `wrangle/App/WhatsNewView.swift`) was applied to canonical hits.
    - Planning-noise filter (`.planning/phases/14-app-repo-oss-surface/`) was applied to both sweeps.
  </acceptance_criteria>
  <done>
    Full-history sweep run; results captured for Task 6's checkpoint. Sweep intermediate dir ignored from future commits.
  </done>
</task>

<task type="checkpoint:human-verify" gate="blocking">
  <name>Task 6: Secrets-sweep recovery-strategy checkpoint (D-19)</name>
  <files>SECURITY.md</files>
  <read_first>
    - .planning/phases/14-app-repo-oss-surface/14-CONTEXT.md (D-19 — strategy deferred to execution-time; D-11 — Phase 14 only changes working tree + index; D-14 — SECURITY.md "known-rotated" section spec)
    - .planning/phases/14-app-repo-oss-surface/_sweep/canonical-hits-real.txt (Task 5 output)
    - .planning/phases/14-app-repo-oss-surface/_sweep/analytics-hits-real.txt (Task 5 output)
    - SECURITY.md (Plan 14-01 Task 2 placeholder marker `<!-- rotated-tokens-section -->`)
  </read_first>
  <what-built>
    Task 5 ran the canonical D-19 secrets sweep and wrote the filtered hits to two files under `.planning/phases/14-app-repo-oss-surface/_sweep/`. This checkpoint surfaces the results to the user. If both files are empty, the checkpoint is an informational confirmation (REPO-09 satisfied trivially). If either file has hits, the checkpoint asks the user to choose between `git filter-repo` (history rewrite) and rotate-and-document.
  </what-built>
  <how-to-verify>
    The executor pauses here and shows the user the hits files (or confirms they are empty).

    **Case A — both `canonical-hits-real.txt` and `analytics-hits-real.txt` are empty (0 lines):**

    The executor reports:

        Secrets sweep complete. No hits found in:
          - canonical D-19 pattern (secret|api[-_]key|token|password|wrangleapp.dev|lemonsqueezy)
          - analytics variants (plausible|fathom|posthog|mixpanel|segment)
        D-20 exemption (wrangleapp.dev in About-panel) accounted for.
        REPO-09 satisfied. No further action.

    User responds: `approved` → executor proceeds to Task 7 (no SECURITY.md edit needed).

    **Case B — one or both files have hits:**

    The executor reports:

        Secrets sweep found N canonical hit(s) and M analytics hit(s):

        --- canonical-hits-real.txt ---
        <paste full contents here, max ~50 lines; if larger, paste first 50 + "...(K more truncated, full file at .planning/phases/14-app-repo-oss-surface/_sweep/canonical-hits-real.txt)">

        --- analytics-hits-real.txt ---
        <paste full contents, same rule>

        Each hit format: <commit-sha>:<filepath>:<line>: <line content>

    Then the executor asks the user to choose ONE of three strategies:

    **Option 1 — `git filter-repo` (history rewrite):**
    - Clean: removes all hits from history, no leakage post-flip.
    - Cost: rewrites SHAs (every existing tag's SHA changes); rewrites the `origin/main` you just pushed; user must force-push (`git push --force-with-lease origin main`); breaks any clones (per CONTEXT.md "practical impact zero since you have one remote and only your local copy"). Out of scope for THIS plan — Phase 14 commits the strategy decision but defers the actual `filter-repo` to Phase 18 (per D-11). Task 6 records the choice in `.planning/STATE.md` and stops.
    - Best for: live API keys, current LemonSqueezy webhook secrets, wrangleapp.dev API tokens that are still valid.

    **Option 2 — Rotate-and-document:**
    - Cost: the token-in-history is visible to anonymous viewers post-flip, but it's been revoked / rotated so the leak is decorative.
    - Workflow: (a) user rotates the affected credential in its source-of-truth dashboard (LemonSqueezy admin, Plausible admin, etc.); (b) executor appends a "Known rotated tokens in history" section to SECURITY.md at the `<!-- rotated-tokens-section -->` marker, listing each rotated token by ROLE (not value) and the rotation date.
    - Best for: dev/test tokens; analytics keys that have low impact even if leaked; tokens already known to be expired.

    **Option 3 — Defer entirely:**
    - Don't choose strategy now; record the hits in `.planning/STATE.md` under Blockers/Concerns and let Phase 18 (final secrets sweep) make the decision in the context of the actual public-flip workflow.
    - Cost: kicks the decision can to Phase 18; risk = forgetting and flipping with hits live.
    - Best for: ambiguous hits the user needs time to investigate (e.g., a string that grep flagged but might not be a real secret).

    User responds with one of:
    - `option-1: filter-repo` — Executor records decision in `.planning/STATE.md` Decisions block (e.g., "Phase 14 secrets sweep: filter-repo strategy chosen; Phase 18 executes the history rewrite of paths [path1, path2, ...]"). REPO-09 marked "satisfied — filter-repo strategy locked for Phase 18 execution." No SECURITY.md edit.
    - `option-2: rotate-and-document` — User confirms rotation has been done (or commits to doing it before Phase 18). Executor edits SECURITY.md to insert a "Known rotated tokens in history" section at the `<!-- rotated-tokens-section -->` marker. The section format: `## Known rotated tokens in history` heading; one bullet per rotated token: `- **<role>** (rotated <YYYY-MM-DD>): The original credential was committed in early development and has since been revoked. See [GitHub Security Advisories](https://github.com/J-Krush/wrangle/security/advisories/new) to report continued exposure.` REPO-09 marked "satisfied — rotated and documented."
    - `option-3: defer` — Executor records hits in `.planning/STATE.md` Blockers/Concerns block (e.g., "Phase 14 secrets sweep: <N> hits unresolved; strategy decision deferred to Phase 18"). REPO-09 marked "deferred to Phase 18" (acceptable per D-19 because Phase 18 also runs a sweep — the deferred decision lands there).
  </how-to-verify>
  <action>
    Interactive checkpoint — see `<what-built>` and `<how-to-verify>` above. The executor surfaces the hits files from Task 5 to the user. Case A (both real-hits files empty): executor reports "Secrets sweep clean" and waits for `approved`; on approval, records `Phase 14 secrets sweep: clean` in `.planning/STATE.md` Decisions block. Case B (at least one hits file non-empty): executor pastes the hits to the user with file/line context, then asks the user to choose `option-1: filter-repo` (record in STATE.md Decisions, Phase 18 executes the rewrite per D-11), `option-2: rotate-and-document` (executor edits SECURITY.md to insert a "Known rotated tokens in history" section at the `<!-- rotated-tokens-section -->` marker, listing each rotated token by ROLE + rotation date), or `option-3: defer` (record hits in STATE.md Blockers/Concerns, defer decision to Phase 18). Per D-19 + D-11 + D-14.
  </action>
  <verify>
    <human-check>User explicitly responded with one of: `approved` (Case A), `option-1: filter-repo`, `option-2: rotate-and-document`, or `option-3: defer` (Case B). Executor verifies the resulting state matches the chosen branch: (Case A) `grep -qE 'Phase 14 secrets sweep.*clean' .planning/STATE.md`; (option-1) `grep -qE 'Phase 14 secrets sweep.*filter-repo' .planning/STATE.md`; (option-2) `grep -q '^## Known rotated tokens in history$' SECURITY.md`; (option-3) `grep -qE 'Phase 14 secrets sweep.*deferred' .planning/STATE.md`.</human-check>
  </verify>
  <resume-signal>Reply `approved` (Case A), or one of: `option-1: filter-repo` / `option-2: rotate-and-document` / `option-3: defer` (Case B).</resume-signal>
  <acceptance_criteria>
    - If Case A: SECURITY.md is unchanged from Plan 14-01 Task 2's output (the `<!-- rotated-tokens-section -->` marker is still present, no new section appended). `.planning/STATE.md` Decisions block contains a "Phase 14 secrets sweep: clean" entry.
    - If Case B option-1: `.planning/STATE.md` Decisions block contains a "Phase 14 secrets sweep: filter-repo strategy" entry naming the affected paths.
    - If Case B option-2: SECURITY.md now contains a `## Known rotated tokens in history` heading; the section contains at least one bullet matching the format above; the original `<!-- rotated-tokens-section -->` marker has been replaced (or remains immediately above the new section).
    - If Case B option-3: `.planning/STATE.md` Blockers/Concerns block contains a "Phase 14 secrets sweep: <N> unresolved hits, deferred to Phase 18" entry with hit count.
    - In ALL cases: the user explicitly responded with one of the four signal values; the executor did not infer.
  </acceptance_criteria>
  <done>
    Recovery strategy locked. REPO-09 satisfied (or explicitly deferred per the option-3 path).
  </done>
</task>

<task type="auto">
  <name>Task 7: Verify D-08 keep-list intact + final tracking check</name>
  <files></files>
  <read_first>
    - .planning/phases/14-app-repo-oss-surface/14-CONTEXT.md (D-08 keep-list)
    - .planning/REQUIREMENTS.md §REPO-08 + §REPO-12 (success criteria 5 in ROADMAP §Phase 14)
  </read_first>
  <action>
    Confirmation pass — no destructive operations. Walk through ROADMAP §Phase 14 Success Criterion 5 ("`.gitignore` is updated and no `.DS_Store`, `DerivedData/`, `.build/`, or `*.xcuserstate` files remain tracked; `docs/architecture.md` / `docs/coding-patterns.md` / `docs/audit-report.md` are reviewed and `CLAUDE.md` has a header note that the project is now open source plus a 'Contributors' pointer to `CONTRIBUTING.md`") and validate each part:

    1. Run `git ls-files | grep -E '\.DS_Store$|/DerivedData/|/\.build/|\.xcuserstate$|/xcuserdata/'` — should return ZERO matches (everything must be untracked at this point).

    2. Run `git ls-files docs/architecture.md docs/coding-patterns.md docs/token-counting-research.md` — should return all three (D-08 keep-list intact).

    3. Run `git ls-files docs/audit-report.md docs/launch-strategy.md docs/release-checklist.md docs/product-hunt/` — should return ZERO matches (D-10 untracked).

    4. Run `git ls-files docs/pre-launch-todo.md` — should return ZERO matches (D-09 deleted).

    5. Confirm CLAUDE.md has both Plan 14-01 additions intact (`[MIT License](LICENSE)` and `## Contributors`) AND the Task 4 prune (no `docs/audit-report.md` reference, no `docs/release-checklist.md` reference).

    6. Run `git status` and confirm the working-tree state is consistent: deleted files staged for commit; the secret-sweep intermediate dir ignored.

    If any check fails: report the specific failure to the user and DO NOT proceed. Per REPO-08 + REPO-12 + ROADMAP §Phase 14 Success Criterion 5.
  </action>
  <verify>
    <automated>[ -z "$(git ls-files | grep -E '\.DS_Store$|/DerivedData/|/\.build/|\.xcuserstate$|/xcuserdata/')" ] && git ls-files --error-unmatch docs/architecture.md docs/coding-patterns.md docs/token-counting-research.md > /dev/null && [ -z "$(git ls-files docs/audit-report.md docs/launch-strategy.md docs/release-checklist.md 'docs/product-hunt/*')" ] && [ -z "$(git ls-files docs/pre-launch-todo.md)" ] && grep -q '\[MIT License\](LICENSE)' CLAUDE.md && grep -q '^## Contributors$' CLAUDE.md && ! grep -q 'docs/audit-report\.md' CLAUDE.md && ! grep -q 'docs/release-checklist\.md' CLAUDE.md</automated>
  </verify>
  <acceptance_criteria>
    - `git ls-files` returns ZERO matches for `.DS_Store`, `DerivedData/`, `.build/`, `*.xcuserstate`, `xcuserdata/` patterns (REPO-08 + ROADMAP success criterion 5 part A).
    - `git ls-files` returns matches for all three D-08 keep-list files (REPO-12 + D-08).
    - `git ls-files` returns ZERO matches for the D-10 redaction list (REPO-12 + D-10).
    - `git ls-files` returns ZERO matches for `docs/pre-launch-todo.md` (D-09).
    - `CLAUDE.md` contains both Plan 14-01 additions (`[MIT License](LICENSE)` link AND `## Contributors` section).
    - `CLAUDE.md` contains ZERO references to `docs/audit-report.md` or `docs/release-checklist.md` (REPO-12 + Task 4 prune).
  </acceptance_criteria>
  <done>
    Phase 14 success criterion 5 fully validated. Repo hygiene state matches CONTEXT.md D-08..D-11 + CLAUDE.md edits + REPO-08/REPO-12 mandates.
  </done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| Git history → anonymous GitHub visitor (post-Phase-18 flip) | Any string in any commit in any branch is visible after the flip. The secrets-sweep task (Task 5) is the last line of defense against credential leaks. |
| Working tree → git index | `git rm --cached` operations (Task 3) must NOT also delete the working-tree file (that's `git rm` without `--cached`). Wrong flag = user loses local docs/audit-report.md content. |
| Sweep grep pattern → forbidden-token list completeness | If the D-19 canonical pattern is missing a token name that DOES exist in history, the sweep returns false-clean. D-19 + the extended analytics variants are the union — extending further is out of scope (deferred per D-19's "rejected: pre-commit to filter-repo"). |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-14-10 | Information Disclosure | Full-history secrets sweep coverage | mitigate | Task 5 runs the exact D-19 canonical pattern PLUS the extended analytics variants (`plausible|fathom|posthog|mixpanel|segment`). Acceptance criteria force both sweeps to run and persist results to disk so the user can review the full forbidden-token list at the checkpoint. |
| T-14-11 | Tampering | `git rm --cached` flag mistake | mitigate | Task 3 explicitly contrasts `git rm --cached` (correct: drops index only) vs `git rm` (wrong: also deletes from disk). Acceptance criteria verify post-operation that the file STILL EXISTS on disk (`test -f`) AND no longer appears in the index (`git ls-files` empty) — both conditions must hold. A `git rm` (without `--cached`) would fail the `test -f` check. |
| T-14-12 | Repudiation | Secrets-sweep strategy decision lost | mitigate | Task 6's checkpoint records the chosen strategy in `.planning/STATE.md` (either Decisions block for options 1/2 or Blockers/Concerns for option 3). Phase 18's final-sweep planner reads STATE.md as canonical input. The decision can't be lost between Phase 14 and Phase 18. |
| T-14-13 | Information Disclosure | Sweep intermediate files committed | mitigate | Task 5 appends `.planning/phases/14-app-repo-oss-surface/_sweep/` to `.gitignore` before any `git add`. Acceptance criterion `grep -q '_sweep/' .gitignore` enforces this — prevents accidentally committing the very hits file containing the secrets we're trying to clean. |
| T-14-14 | Denial of Service | `.gitignore` accidentally ignores Plans 14-01 / 14-02 outputs | mitigate | Task 1 acceptance criterion `! grep -qE '^LICENSE|^CONTRIBUTING|^SECURITY|^README|^\.github|^screenshots' .gitignore` enforces that nothing from earlier plans gets ignored. Plus Task 7 confirms D-08 keep-list is still tracked. |
| T-14-SC | Tampering | Supply chain (npm/pip/cargo) | accept | This plan adds zero new package dependencies (pure git operations + markdown / config file edits). No package-legitimacy gate required. |
</threat_model>

<verification>
After all 7 tasks complete:

```bash
# REPO-08: .gitignore comprehensive + no offenders tracked
grep -q '^xcuserdata/$' .gitignore
grep -q '^\.DS_Store$' .gitignore
test -z "$(git ls-files | grep -E '\.DS_Store$|/DerivedData/|/\.build/|\.xcuserstate$|/xcuserdata/')"

# REPO-12: D-08 kept, D-09 deleted, D-10 untracked, CLAUDE.md pruned
git ls-files --error-unmatch docs/architecture.md docs/coding-patterns.md docs/token-counting-research.md
! test -f docs/pre-launch-todo.md
test -z "$(git ls-files docs/audit-report.md docs/launch-strategy.md docs/release-checklist.md 'docs/product-hunt/*')"
test -f docs/audit-report.md   # still on disk per D-10
! grep -q 'docs/audit-report\.md' CLAUDE.md
! grep -q 'docs/release-checklist\.md' CLAUDE.md
grep -q '^## Contributors$' CLAUDE.md

# REPO-09: Sweep ran; STATE.md records strategy
test -f .planning/phases/14-app-repo-oss-surface/_sweep/canonical-hits-real.txt
grep -qE 'Phase 14 secrets sweep|secrets_sweep' .planning/STATE.md
```

All three `requirements` IDs (REPO-08, REPO-09, REPO-12) are claimed by this plan.
</verification>

<success_criteria>
- `.gitignore` rewritten to comprehensive Swift/Xcode/macOS/SPM + D-10 redaction list + `_sweep/` exclusion.
- `docs/pre-launch-todo.md` deleted from disk + index; no `.DS_Store` remnants anywhere under `docs/` or `screenshots/`.
- D-10 redaction list (7 files) + `wrangle.xcodeproj/xcuserdata/...plist` (1 file) are `git rm --cached`ed: gone from index, still on disk.
- D-08 keep-list (`docs/architecture.md`, `docs/coding-patterns.md`, `docs/token-counting-research.md`) remains tracked.
- CLAUDE.md "Detailed docs" blockquote pruned to D-08 keep-list; Plan 14-01's OSS-header + Contributors section both intact.
- Full-history secrets sweep run with D-19 canonical pattern + analytics variants; D-20 exemption applied; D-17 Plan-14-pattern-style interactive checkpoint surfaced results to user; user chose one of the three recovery strategies; `.planning/STATE.md` records the decision.
- ROADMAP §Phase 14 Success Criterion 5 fully validated (Task 7 confirmation pass).
</success_criteria>

<output>
Create `.planning/phases/14-app-repo-oss-surface/14-03-SUMMARY.md` when done, recording: (1) the exact `.gitignore` line count + key sections; (2) the list of files removed from the index via `git rm --cached`; (3) the secrets-sweep result (clean vs `<N>` hits); (4) the user-chosen recovery strategy (n/a if clean, otherwise option-1/2/3); (5) confirmation that ROADMAP §Phase 14 Success Criterion 5 is met; (6) which REPO-NN IDs are now satisfied (REPO-08, REPO-09, REPO-12).
</output>
