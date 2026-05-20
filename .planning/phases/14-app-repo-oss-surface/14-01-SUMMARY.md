---
phase: 14-app-repo-oss-surface
plan: 01
slug: oss-scaffold
subsystem: repo-meta
tags: [oss, license, governance, repo-hygiene, contributing, security]
requirements: [REPO-01, REPO-03, REPO-04, REPO-05, REPO-06, REPO-10, REPO-11]
dependency-graph:
  requires: []
  provides:
    - "LICENSE for README license link (Plan 14-02)"
    - "CONTRIBUTING.md for README contributing link (Plan 14-02)"
    - ".github/ templates (referenced from CONTRIBUTING.md and visible in repo OSS surface)"
    - "SECURITY.md with rotated-tokens placeholder for Plan 14-03 secrets sweep"
    - "CLAUDE.md OSS header + Contributors pointer (CONTRIBUTING.md backlink)"
  affects: []
tech-stack:
  added: []
  patterns:
    - "Repo-root OSS scaffolding: LICENSE + CONTRIBUTING + SECURITY + .github/ templates"
key-files:
  created:
    - LICENSE
    - SECURITY.md
    - CONTRIBUTING.md
    - .github/ISSUE_TEMPLATE/bug_report.md
    - .github/ISSUE_TEMPLATE/feature_request.md
    - .github/PULL_REQUEST_TEMPLATE.md
  modified:
    - CLAUDE.md
decisions:
  - "MIT attribution locked to literal 'Copyright (c) 2026 J Krush' per D-20 / REPO-01"
  - "SECURITY.md routes to GitHub Security Advisories only — zero email channels (D-14)"
  - "CONTRIBUTING.md uses portfolio-piece / slow-maintenance voice (D-12)"
  - ".planning/ workflow documented in CONTRIBUTING.md as transparency feature (D-13, D-06)"
  - "No Code of Conduct, no CHANGELOG.md, no root ROADMAP.md (deferred per CONTEXT.md)"
metrics:
  duration: "~5 minutes wall clock"
  completed: "2026-05-20"
  tasks-completed: 5
  files-created: 6
  files-modified: 1
  commits: 5
---

# Phase 14 Plan 01: OSS Scaffold Summary

Stood up the seven repo-root / `.github/` files that make `J-Krush/wrangle` legible as an open-source project: MIT LICENSE attributed to "Copyright (c) 2026 J Krush", a portfolio-piece-framed CONTRIBUTING.md, a SECURITY.md routing disclosures exclusively to GitHub Security Advisories, three `.github/` issue + PR templates with REPO-04/05/06 mandated fields, and a CLAUDE.md edit adding an "open source" header blockquote plus a "## Contributors" pointer section — completing the artifact layer that Plans 14-02 (README) and 14-03 (repo hygiene + secrets sweep) depend on.

## Tasks Completed

| # | Task | Commit | Files |
|---|------|--------|-------|
| 1 | Write MIT LICENSE | `1f0b7a0` | `LICENSE` |
| 2 | Write SECURITY.md (Security Advisories disclosure path) | `bc87646` | `SECURITY.md` |
| 3 | Write CONTRIBUTING.md (portfolio-piece framing) | `5e6d7bf` | `CONTRIBUTING.md` |
| 4 | Write `.github/` issue and PR templates | `3c5ccfc` | `.github/ISSUE_TEMPLATE/bug_report.md`, `.github/ISSUE_TEMPLATE/feature_request.md`, `.github/PULL_REQUEST_TEMPLATE.md` |
| 5 | Update CLAUDE.md with OSS header + Contributors pointer | `82130e3` | `CLAUDE.md` |

## Attribution String Used

The MIT LICENSE uses the exact, locked attribution:

```
Copyright (c) 2026 J Krush
```

Per D-20 / REPO-01 / T-14-03 mitigation. Verified across all 7 written/edited files: no occurrence of `Krush LLC`, `John Kreisher`, or any other identity.

## Requirements Satisfied

- **REPO-01** — MIT LICENSE at repo root, canonical body, locked attribution.
- **REPO-03** — CONTRIBUTING.md exists with portfolio-piece / best-effort framing; links CLAUDE.md, `docs/coding-patterns.md`, SECURITY.md, LICENSE; documents the `.planning/` workflow.
- **REPO-04** — `.github/ISSUE_TEMPLATE/bug_report.md` has YAML frontmatter + sections for steps to reproduce, expected vs actual, macOS version, Wrangle version, screenshot.
- **REPO-05** — `.github/ISSUE_TEMPLATE/feature_request.md` has YAML frontmatter + sections for problem, proposed solution, alternatives, and a dedicated "AI-dev-workflow context" section.
- **REPO-06** — `.github/PULL_REQUEST_TEMPLATE.md` has Description, Screenshots (if UI), Tests, and Checklist sections, with explicit `Follows CLAUDE.md conventions` and `No new build warnings` checkbox items.
- **REPO-10** — SECURITY.md routes to `github.com/J-Krush/wrangle/security/advisories/new` with zero email channels; includes `<!-- rotated-tokens-section -->` placeholder for Plan 14-03's optional append.
- **REPO-11** — CLAUDE.md gained an "Open source" blockquote between the existing "Detailed docs" line and the "Project Overview" heading (linking LICENSE + CONTRIBUTING.md) and a `## Contributors` section at the end pointing at CONTRIBUTING.md and `.planning/`. Original "Detailed docs" blockquote was preserved verbatim for Plan 14-03 to surgically prune.

## Decisions Made

- **CONTRIBUTING.md voice** — Followed D-12 portfolio-piece / slow-maintenance framing: "personal portfolio project," "best-effort," response-time hedge "days to weeks, not hours," explicit "major architectural changes are unlikely to be accepted." Voice is reflective and direct rather than corporate.
- **SECURITY.md disclosure channel** — D-14 enforced via positive content (`github.com/J-Krush/wrangle/security/advisories/new` link) and negative grep (`! grep -qi "mailto:\|jkrush@\|@pm.me"`); the file lists 5 vulnerability classes (RCE via markdown, sandbox escape, credential leakage, persistent XSS, SwiftTerm privilege escalation) that reflect Wrangle's actual attack surface rather than generic web-app categories.
- **`.planning/` framing in CONTRIBUTING.md** — Per D-13 / D-06, described as a transparency feature (anchors: PROJECT.md, ROADMAP.md, REQUIREMENTS.md, per-phase artifacts) with an explicit statement that external contributors do NOT need to author `.planning/` files. Frames it as "transparency, not bureaucracy."
- **PR template scope** — Beyond REPO-06 mandate, added "Updated documentation if behavior changed" and "PR is scoped to a single problem (split mixed changes before review)" checkbox items, consistent with the portfolio-piece slow-review reality. No CI checkbox added (deferred per CONTEXT.md — no GH Actions this milestone).
- **No deferred items snuck in** — Verified absence of "Code of Conduct" section in CONTRIBUTING.md, absence of root-level `ROADMAP.md` / `CHANGELOG.md`, no Discord / forum links.

## Deviations from Plan

None — plan executed exactly as written. No bugs found, no missing functionality discovered, no blockers encountered, no architectural questions raised.

## Verification

All seven plan-level acceptance-criteria grep families passed in the final overall verification run:

```
REPO-01  ok    (LICENSE exists, first line "MIT License", locked attribution line)
REPO-03  ok    (CONTRIBUTING.md exists, "portfolio" + "CLAUDE.md" + "docs/coding-patterns.md")
REPO-04/05/06  ok  (all three .github/ templates exist)
REPO-10  ok    ("Security Advisories" present, no "mailto:" anywhere)
REPO-11  ok    ("## Contributors" heading + "[MIT License](LICENSE)" link in CLAUDE.md)
T-14-03  ok    (no "Krush LLC" in LICENSE, CONTRIBUTING.md, SECURITY.md, CLAUDE.md, or .github/)
```

## Threat Model Outcomes

| Threat ID | Disposition | Status |
|-----------|-------------|--------|
| T-14-01 (CONTRIBUTING.md tone) | mitigate | satisfied — "portfolio" + "best-effort" both present, no open-collaboration framing |
| T-14-02 (SECURITY.md email channel) | mitigate | satisfied — zero email addresses; verified via negative grep |
| T-14-03 (LICENSE attribution) | mitigate | satisfied — exact locked string written; no "Krush LLC" anywhere in plan output |
| T-14-04 (Issue/PR template fields) | mitigate | satisfied — per-field grep enforcement on all three templates |
| T-14-SC (Supply chain) | accept | no package installs occurred (pure markdown authoring) |

## Known Stubs

None. Every file is substantive content. The `<!-- rotated-tokens-section -->` HTML comment in SECURITY.md is an intentional, plan-mandated placeholder for Plan 14-03's secrets-sweep append, not a stub.

## Self-Check: PASSED

Files created (all 6 confirmed present on disk):

- `LICENSE` — FOUND
- `SECURITY.md` — FOUND
- `CONTRIBUTING.md` — FOUND
- `.github/ISSUE_TEMPLATE/bug_report.md` — FOUND
- `.github/ISSUE_TEMPLATE/feature_request.md` — FOUND
- `.github/PULL_REQUEST_TEMPLATE.md` — FOUND

File modified (confirmed present, OSS header + Contributors section both verified):

- `CLAUDE.md` — FOUND

Commits (all 5 confirmed in `git log --oneline`):

- `1f0b7a0` — FOUND
- `bc87646` — FOUND
- `5e6d7bf` — FOUND
- `3c5ccfc` — FOUND
- `82130e3` — FOUND
