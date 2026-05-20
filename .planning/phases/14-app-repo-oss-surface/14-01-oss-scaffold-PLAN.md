---
id: 14-01-oss-scaffold
phase: 14-app-repo-oss-surface
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - LICENSE
  - CONTRIBUTING.md
  - SECURITY.md
  - .github/ISSUE_TEMPLATE/bug_report.md
  - .github/ISSUE_TEMPLATE/feature_request.md
  - .github/PULL_REQUEST_TEMPLATE.md
  - CLAUDE.md
autonomous: true
requirements: [REPO-01, REPO-03, REPO-04, REPO-05, REPO-06, REPO-10, REPO-11]

must_haves:
  truths:
    - "Repo root contains LICENSE (MIT) attributed exactly 'Copyright (c) 2026 J Krush'."
    - "Repo root contains CONTRIBUTING.md framed as portfolio-piece / slow-maintenance (D-12), linking to CLAUDE.md and docs/coding-patterns.md and documenting the GSD .planning/ workflow per D-13; consistent with D-06's transparency posture that .planning/ stays public on the Phase 18 flip."
    - "Repo root contains SECURITY.md routing disclosure to GitHub Security Advisories only — no email channel (D-14)."
    - ".github/ISSUE_TEMPLATE/bug_report.md, .github/ISSUE_TEMPLATE/feature_request.md, and .github/PULL_REQUEST_TEMPLATE.md all exist."
    - "CLAUDE.md has an OSS header note + a 'Contributors' section pointing at CONTRIBUTING.md."
  artifacts:
    - path: "LICENSE"
      provides: "MIT License, attributed to J Krush 2026"
      contains: "Copyright (c) 2026 J Krush"
    - path: "CONTRIBUTING.md"
      provides: "Contributor expectations + setup pointers + GSD .planning/ workflow note"
      contains: "best-effort"
    - path: "SECURITY.md"
      provides: "Security Advisories disclosure path"
      contains: "Security Advisories"
    - path: ".github/ISSUE_TEMPLATE/bug_report.md"
      provides: "Bug report template with REPO-04 mandated fields"
      contains: "steps to reproduce"
    - path: ".github/ISSUE_TEMPLATE/feature_request.md"
      provides: "Feature request template with REPO-05 mandated fields"
      contains: "AI-dev"
    - path: ".github/PULL_REQUEST_TEMPLATE.md"
      provides: "PR template with REPO-06 mandated checklist"
      contains: "CLAUDE.md"
    - path: "CLAUDE.md"
      provides: "OSS header + Contributors pointer to CONTRIBUTING.md"
      contains: "open source"
  key_links:
    - from: "CONTRIBUTING.md"
      to: "CLAUDE.md"
      via: "markdown link"
      pattern: "\\(CLAUDE\\.md\\)"
    - from: "CONTRIBUTING.md"
      to: "docs/coding-patterns.md"
      via: "markdown link"
      pattern: "docs/coding-patterns\\.md"
    - from: "CLAUDE.md"
      to: "CONTRIBUTING.md"
      via: "Contributors section link"
      pattern: "CONTRIBUTING\\.md"
---

<objective>
Stand up the OSS scaffold for `J-Krush/wrangle`: MIT LICENSE, CONTRIBUTING.md
(portfolio-piece / slow-maintenance framing), SECURITY.md (GitHub Security
Advisories only), the three `.github/` issue + PR templates, and the
CLAUDE.md OSS-header + Contributors-pointer update.

Purpose: All other Phase 14 work depends on these existing — README's
"Contributing" + "License" link block (Plan 14-02) must resolve to real
files, and Plan 14-03's repo hygiene sweep needs to see them as
intentionally-tracked OSS surface (not noise to ignore).
Output: 7 new/edited files at repo root + `.github/`, with no GUI checkpoints
and no destructive git operations.
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
@CLAUDE.md
@docs/architecture.md
@docs/coding-patterns.md
</context>

<tasks>

<task type="auto">
  <name>Task 1: Write MIT LICENSE</name>
  <files>LICENSE</files>
  <read_first>
    - .planning/phases/14-app-repo-oss-surface/14-CONTEXT.md (D-01..D-20 — attribution string is locked)
    - .planning/REQUIREMENTS.md §REPO-01
  </read_first>
  <action>
    Create `LICENSE` at repo root with the canonical MIT License text. First non-blank line is `MIT License`. The copyright line must be exactly `Copyright (c) 2026 J Krush` — no other variations (not `Krush`, not `John Kreisher`, not `Krush LLC`). Use the standard MIT body (Permission is hereby granted, free of charge ... THE SOFTWARE IS PROVIDED "AS IS"...). Do not invent custom clauses; do not add a year range. Per D-20 / REPO-01 this is the canonical attribution that flows through every credit surface in v1.3. Per REPO-01.
  </action>
  <verify>
    <automated>test -f LICENSE && head -1 LICENSE | grep -q "^MIT License$" && grep -q "^Copyright (c) 2026 J Krush$" LICENSE && grep -qi "permission is hereby granted" LICENSE</automated>
  </verify>
  <acceptance_criteria>
    - `LICENSE` exists at repo root.
    - First non-blank line is exactly `MIT License`.
    - File contains exactly the string `Copyright (c) 2026 J Krush` on its own line.
    - File contains the canonical MIT body (matches the standard "Permission is hereby granted" and `THE SOFTWARE IS PROVIDED "AS IS"` clauses).
    - `git ls-files --error-unmatch LICENSE` succeeds after staging (REPO-08 will not ignore this file).
  </acceptance_criteria>
  <done>
    `LICENSE` exists with MIT body + locked attribution string. REPO-01 satisfied.
  </done>
</task>

<task type="auto">
  <name>Task 2: Write SECURITY.md (Security Advisories disclosure path)</name>
  <files>SECURITY.md</files>
  <read_first>
    - .planning/phases/14-app-repo-oss-surface/14-CONTEXT.md (D-14: Security Advisories only, no email channel)
    - .planning/REQUIREMENTS.md §REPO-10
  </read_first>
  <action>
    Create `SECURITY.md` at repo root. 5-15 lines. Structure: (1) one-sentence intro that thanks reporters; (2) "How to report" paragraph instructing the reporter to use the GitHub Security tab → "Report a vulnerability" private disclosure flow, with a markdown link to `https://github.com/J-Krush/wrangle/security/advisories/new`; (3) "What counts as a vulnerability" — short 3-5 bullet list (e.g., remote code execution via malicious markdown, sandbox escape, credential leak, persistent XSS in rendered HTML/markdown). Per D-14 do NOT list any email address (no `jkrush@pm.me`, no dedicated alias). Tone is planner's call (D-14 Claude's Discretion) — pick concise + neutral. No "Response time SLA" promise (portfolio-piece project, REPO-03 D-12 framing applies). If Plan 14-03's secrets sweep turns up a rotated credential, a "Known rotated tokens in history" section will be appended at execute-plan time (do NOT include that section in this initial write — leave a comment marker `<!-- rotated-tokens-section -->` immediately above the final blank line so Plan 14-03 can append idempotently if needed). Per REPO-10.
  </action>
  <verify>
    <automated>test -f SECURITY.md && grep -q "Security Advisories" SECURITY.md && grep -q "github.com/J-Krush/wrangle/security/advisories" SECURITY.md && ! grep -qi "mailto:\|jkrush@\|@pm.me" SECURITY.md && [ $(wc -l < SECURITY.md) -ge 5 ] && [ $(wc -l < SECURITY.md) -le 30 ]</automated>
  </verify>
  <acceptance_criteria>
    - `SECURITY.md` exists at repo root.
    - File contains the substring `Security Advisories`.
    - File contains the substring `github.com/J-Krush/wrangle/security/advisories`.
    - File contains zero email addresses (no `mailto:`, no `@pm.me`, no `jkrush@`).
    - File is between 5 and 30 lines inclusive.
    - File contains the literal HTML comment `<!-- rotated-tokens-section -->` as a placeholder for Plan 14-03's optional append.
  </acceptance_criteria>
  <done>
    `SECURITY.md` exists with the canonical Security Advisories disclosure path and zero email channels. REPO-10 satisfied.
  </done>
</task>

<task type="auto">
  <name>Task 3: Write CONTRIBUTING.md (portfolio-piece framing)</name>
  <files>CONTRIBUTING.md</files>
  <read_first>
    - .planning/phases/14-app-repo-oss-surface/14-CONTEXT.md (D-12, D-13)
    - .planning/REQUIREMENTS.md §REPO-03
    - CLAUDE.md (current — link target)
    - docs/coding-patterns.md (current — link target)
    - docs/architecture.md (current — link target for "where to start")
  </read_first>
  <action>
    Create `CONTRIBUTING.md` at repo root. Required sections (in order, planner picks exact headings):

    1. **Introduction / Expectations** — Set the portfolio-piece / slow-maintenance frame explicitly. Include the literal phrases `personal portfolio project`, `best-effort`, and a response-time hedge (planner's wording — e.g., "days to weeks, not hours"). State that major architectural changes are unlikely to be accepted.
    2. **Dev environment setup** — Brief: macOS 15+ (Sequoia), Xcode 16+, Apple Silicon, clone + `open Wrangle.xcodeproj` + Cmd+R. Note that SwiftTerm resolves automatically via SPM. Note that the App Sandbox entitlement is disabled (required for embedded-terminal child processes). This subsumes REPO-02 (h) "Build from source" expectations.
    3. **Filing issues** — Point at `.github/ISSUE_TEMPLATE/bug_report.md` and `.github/ISSUE_TEMPLATE/feature_request.md`. One sentence each on when to use which.
    4. **PR process** — Point at `.github/PULL_REQUEST_TEMPLATE.md`. One paragraph: fork, branch, PR, expect best-effort review.
    5. **Coding conventions** — One paragraph + two markdown links. Link `CLAUDE.md` at repo root (full project conventions: `@Observable` + `@MainActor`, NSTextView constraints, sidebar invariants). Link `docs/coding-patterns.md` (modern-concurrency rules with code examples). Per REPO-03 + D-13.
    6. **How work gets planned (the `.planning/` workflow)** — Per D-13. ~5-10 line subsection explaining that this repo uses a structured planning workflow rooted in `.planning/` — phases under `.planning/phases/`, requirements in `.planning/REQUIREMENTS.md`, roadmap in `.planning/ROADMAP.md`. State that user-driven work flows through this loop (gather context → plan → execute → summarize) and that external PRs do NOT need to author `.planning/` files. Frame it as transparency, not bureaucracy.
    7. **Security disclosures** — One line: "For vulnerabilities, see SECURITY.md" with a markdown link to `SECURITY.md`.
    8. **License** — One line: "All contributions are licensed under the MIT License — see LICENSE."

    Voice: portfolio-piece / slow-maintenance per D-12 (rejected: open-collaboration framing). Do not promise specific response SLAs. Do not invent a Code of Conduct subsection (D-12 / CONTEXT.md Deferred Ideas — Contributor Covenant deferred). Length target ~80-150 lines. Per REPO-03.
  </action>
  <verify>
    <automated>test -f CONTRIBUTING.md && grep -q "portfolio" CONTRIBUTING.md && grep -q "best-effort" CONTRIBUTING.md && grep -q "CLAUDE\.md" CONTRIBUTING.md && grep -q "docs/coding-patterns\.md" CONTRIBUTING.md && grep -q "\.planning/" CONTRIBUTING.md && grep -q "SECURITY\.md" CONTRIBUTING.md && grep -q "LICENSE" CONTRIBUTING.md && [ $(wc -l < CONTRIBUTING.md) -ge 50 ]</automated>
  </verify>
  <acceptance_criteria>
    - `CONTRIBUTING.md` exists at repo root.
    - File contains the substring `portfolio` (D-12 framing).
    - File contains the substring `best-effort` (D-12 response-time language).
    - File contains markdown links to `CLAUDE.md`, `docs/coding-patterns.md`, `SECURITY.md`, `LICENSE`.
    - File contains a subsection referencing `.planning/` per D-13.
    - File is at least 50 lines (substantive, not a stub).
    - File does NOT contain a "Code of Conduct" section (deferred per D-12 / CONTEXT Deferred Ideas).
  </acceptance_criteria>
  <done>
    `CONTRIBUTING.md` exists with D-12 / D-13 framing, all required links, and the `.planning/` workflow callout. REPO-03 satisfied.
  </done>
</task>

<task type="auto">
  <name>Task 4: Write .github/ issue and PR templates</name>
  <files>.github/ISSUE_TEMPLATE/bug_report.md, .github/ISSUE_TEMPLATE/feature_request.md, .github/PULL_REQUEST_TEMPLATE.md</files>
  <read_first>
    - .planning/REQUIREMENTS.md §REPO-04, §REPO-05, §REPO-06
    - .planning/phases/14-app-repo-oss-surface/14-CONTEXT.md (Claude's Discretion on exact field labels)
  </read_first>
  <action>
    Create the `.github/` directory and the three template files. Use GitHub's standard issue-template YAML frontmatter format (`name`, `about`, `title`, `labels`, `assignees`) for the two issue templates; the PR template is body-only (no frontmatter).

    **`.github/ISSUE_TEMPLATE/bug_report.md`** — Required fields per REPO-04: steps to reproduce, expected vs actual, macOS version, Wrangle version, screenshot. Frontmatter: `name: Bug report`, `about: Report something that doesn't work as expected`, `title: '[Bug] '`, `labels: 'bug'`. Body uses `## Section` headings with placeholder prompt text under each (planner picks exact prose, but every REPO-04 mandated field must appear as its own section). Include `Wrangle version` and `macOS version` as a short metadata block at the top of the body.

    **`.github/ISSUE_TEMPLATE/feature_request.md`** — Required fields per REPO-05: problem, proposed solution, alternatives, AI-dev-workflow context. Frontmatter: `name: Feature request`, `about: Propose a new capability`, `title: '[Feature] '`, `labels: 'enhancement'`. Body uses `## Section` headings for each mandated field; include "AI-dev-workflow context" as its own section (this is the REPO-05 differentiator — the planner must literally label it, not roll it into "problem").

    **`.github/PULL_REQUEST_TEMPLATE.md`** — Required checklist per REPO-06: description, screenshots if UI, tests run, CLAUDE.md conventions followed. Body-only (no frontmatter). Structure: `## Description` (free-form), `## Screenshots (if UI)` (image upload hint), `## Tests` (a checklist `- [ ] Tests pass locally (Cmd+U in Xcode)` etc.), `## Checklist` (a checklist that explicitly includes `- [ ] Follows CLAUDE.md conventions`, plus `- [ ] No new build warnings`, `- [ ] Updated documentation if behavior changed`).

    Planner picks exact field labels and any optional fields beyond the mandate (CONTEXT.md Claude's Discretion). Do not add a Discord / forum link (deferred per CONTEXT.md). Per REPO-04, REPO-05, REPO-06.
  </action>
  <verify>
    <automated>test -f .github/ISSUE_TEMPLATE/bug_report.md && test -f .github/ISSUE_TEMPLATE/feature_request.md && test -f .github/PULL_REQUEST_TEMPLATE.md && grep -qi "steps to reproduce" .github/ISSUE_TEMPLATE/bug_report.md && grep -qi "expected" .github/ISSUE_TEMPLATE/bug_report.md && grep -qi "macOS" .github/ISSUE_TEMPLATE/bug_report.md && grep -qi "wrangle version" .github/ISSUE_TEMPLATE/bug_report.md && grep -qi "screenshot" .github/ISSUE_TEMPLATE/bug_report.md && grep -qi "AI-dev" .github/ISSUE_TEMPLATE/feature_request.md && grep -qi "alternatives" .github/ISSUE_TEMPLATE/feature_request.md && grep -q "CLAUDE\.md" .github/PULL_REQUEST_TEMPLATE.md && grep -qi "screenshots" .github/PULL_REQUEST_TEMPLATE.md && grep -qi "tests" .github/PULL_REQUEST_TEMPLATE.md</automated>
  </verify>
  <acceptance_criteria>
    - `.github/ISSUE_TEMPLATE/bug_report.md` exists and contains case-insensitive matches for: `steps to reproduce`, `expected`, `macOS`, `Wrangle version`, `screenshot`.
    - `.github/ISSUE_TEMPLATE/bug_report.md` contains YAML frontmatter (file starts with `---`).
    - `.github/ISSUE_TEMPLATE/feature_request.md` exists and contains case-insensitive matches for: `problem`, `proposed solution`, `alternatives`, `AI-dev`.
    - `.github/ISSUE_TEMPLATE/feature_request.md` contains YAML frontmatter (file starts with `---`).
    - `.github/PULL_REQUEST_TEMPLATE.md` exists and contains case-insensitive matches for: `description`, `screenshots`, `tests`, plus an exact reference to `CLAUDE.md`.
    - `.github/PULL_REQUEST_TEMPLATE.md` contains at least one markdown checkbox `- [ ]`.
  </acceptance_criteria>
  <done>
    `.github/` contains all three templates with REPO-04/05/06 mandated fields. REPO-04, REPO-05, REPO-06 satisfied.
  </done>
</task>

<task type="auto">
  <name>Task 5: Update CLAUDE.md with OSS header + Contributors pointer</name>
  <files>CLAUDE.md</files>
  <read_first>
    - CLAUDE.md (current — top of file, the "# CLAUDE.md — Wrangle" header + "Detailed docs" blockquote line + "## Project Overview" section)
    - .planning/REQUIREMENTS.md §REPO-11
    - .planning/phases/14-app-repo-oss-surface/14-CONTEXT.md (D-13 — CLAUDE.md is linked from CONTRIBUTING.md)
  </read_first>
  <action>
    Edit `CLAUDE.md` (repo root) to add two new things while leaving the existing content intact:

    **(a) OSS header note** — Insert a blockquote IMMEDIATELY AFTER the existing `> **Detailed docs:** …` line (which is currently line 3) and BEFORE the `## Project Overview` heading. The blockquote should be 2-3 lines max and contain (exact phrasings are planner's call, but each of these must be present):
    - The phrase "open source" or "open-source"
    - A link to `LICENSE` (markdown style: `[MIT License](LICENSE)`)
    - A link to `CONTRIBUTING.md` (markdown style: `[CONTRIBUTING.md](CONTRIBUTING.md)`)

    Suggested shape: `> **Open source:** Wrangle is now free and open source under the [MIT License](LICENSE). New contributors — start at [CONTRIBUTING.md](CONTRIBUTING.md).`

    **(b) Contributors section** — Append a new top-level section at the END of `CLAUDE.md` (after the existing "## Important Notes for Claude Code" section). Heading: `## Contributors`. Body (planner's exact prose, but must contain):
    - A link to `CONTRIBUTING.md`.
    - A one-line pointer that human contributors should read CONTRIBUTING.md, while Claude-Code sessions continue reading this file as their primary source of conventions.
    - A one-line note that the project's planning history lives in `.planning/` (per D-13 + D-06's transparency framing).

    Do NOT touch anything else in CLAUDE.md. Do NOT remove the "Detailed docs" blockquote (Plan 14-03 will surgically prune the audit-report / release-checklist links from that line as part of REPO-12). Per REPO-11.
  </action>
  <verify>
    <automated>grep -q "open[- ]source" CLAUDE.md && grep -q "\[MIT License\](LICENSE)" CLAUDE.md && grep -q "\[CONTRIBUTING\.md\](CONTRIBUTING\.md)" CLAUDE.md && grep -q "^## Contributors$" CLAUDE.md && awk '/^## Contributors$/,EOF' CLAUDE.md | grep -q "\.planning/"</automated>
  </verify>
  <acceptance_criteria>
    - `CLAUDE.md` contains the case-insensitive phrase `open source` OR `open-source`.
    - `CLAUDE.md` contains the exact markdown link `[MIT License](LICENSE)`.
    - `CLAUDE.md` contains the exact markdown link `[CONTRIBUTING.md](CONTRIBUTING.md)`.
    - `CLAUDE.md` contains a top-level heading `## Contributors` (matches `^## Contributors$`).
    - The `## Contributors` section body references `.planning/`.
    - The original `> **Detailed docs:**` blockquote line is still present (Plan 14-03 will edit it later; do not delete here).
    - The original `## Project Overview` heading is still present.
  </acceptance_criteria>
  <done>
    `CLAUDE.md` now opens with an OSS-aware header and ends with a Contributors section pointing at `CONTRIBUTING.md` + `.planning/`. REPO-11 satisfied.
  </done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| Repo root → anonymous GitHub visitor (post-Phase-18 flip) | Every file written by this plan will be read by anonymous visitors. No untrusted input crosses INTO the project from this plan — the threat is what we write OUT. |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-14-01 | Information Disclosure | CONTRIBUTING.md tone | mitigate | D-12 portfolio-piece framing forced via acceptance criteria (`grep -q "portfolio"`, `grep -q "best-effort"`) — prevents the file accidentally setting "open-collaboration" expectations that don't match the user's actual maintenance capacity. |
| T-14-02 | Information Disclosure | SECURITY.md email channel | mitigate | Acceptance criterion `! grep -qi "mailto:\|jkrush@\|@pm.me"` enforces D-14 (Security Advisories only, no personal email exposure). |
| T-14-03 | Information Disclosure | LICENSE attribution | mitigate | Acceptance criterion locks the exact string `Copyright (c) 2026 J Krush` — prevents accidental exposure of `Krush LLC` (entity name from v1.2) or any earlier identity. |
| T-14-04 | Repudiation | Issue/PR templates missing mandated fields | mitigate | Per-field grep acceptance criteria on each template enforce REPO-04/05/06 — prevents shipping templates that don't actually capture the information needed to triage bugs. |
| T-14-SC | Tampering | Supply chain (npm/pip/cargo) | accept | This plan adds zero new package dependencies (pure markdown / config file authoring). No package-legitimacy gate required. |
</threat_model>

<verification>
After all 5 tasks complete:

```bash
# REPO-01
test -f LICENSE && head -1 LICENSE | grep -q "^MIT License$" && grep -q "^Copyright (c) 2026 J Krush$" LICENSE

# REPO-03
test -f CONTRIBUTING.md && grep -q "portfolio" CONTRIBUTING.md && grep -q "CLAUDE\.md" CONTRIBUTING.md && grep -q "docs/coding-patterns\.md" CONTRIBUTING.md

# REPO-04 / REPO-05 / REPO-06
test -f .github/ISSUE_TEMPLATE/bug_report.md && test -f .github/ISSUE_TEMPLATE/feature_request.md && test -f .github/PULL_REQUEST_TEMPLATE.md

# REPO-10
test -f SECURITY.md && grep -q "Security Advisories" SECURITY.md && ! grep -qi "mailto:" SECURITY.md

# REPO-11
grep -q "^## Contributors$" CLAUDE.md && grep -q "\[MIT License\](LICENSE)" CLAUDE.md
```

All seven `requirements` IDs (REPO-01, REPO-03, REPO-04, REPO-05, REPO-06, REPO-10, REPO-11) are claimed by this plan.
</verification>

<success_criteria>
- 7 files written (1 LICENSE + 1 CONTRIBUTING + 1 SECURITY + 3 templates + 1 CLAUDE.md edit).
- All 7 acceptance-criteria automated greps pass.
- No file refers to a deferred item (no Code of Conduct, no public ROADMAP.md, no `CHANGELOG.md`).
- No file contains the literal string `Krush LLC` (T-14-03 mitigation).
- The work is fully autonomous — no checkpoints, no GUI steps, no user judgment required.
</success_criteria>

<output>
Create `.planning/phases/14-app-repo-oss-surface/14-01-SUMMARY.md` when done, recording: which files were created, the attribution string used (must be exactly `Copyright (c) 2026 J Krush`), and which REPO-NN IDs are now satisfied.
</output>
