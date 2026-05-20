# Phase 14: App Repo OSS Surface - Context

**Gathered:** 2026-05-20
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 14 prepares the `J-Krush/wrangle` GitHub repo to be presented to a
first-time anonymous visitor when it flips public in Phase 18. This phase
delivers the *artifact* layer of OSS readiness — LICENSE, story-driven README,
CONTRIBUTING, issue + PR templates, screenshots, SECURITY policy, secrets
sweep, `.gitignore` hygiene, and `docs/` redaction.

After this phase the repo:

1. Contains an MIT `LICENSE` at the root attributed to "Copyright (c) 2026 J Krush".
2. Has a story-driven `README.md` covering: hero pitch + screenshot, "What this is"
   (with an explicit callout of `.planning/` as a feature), "Why it's free and open
   source now" (reflective lessons-learned, qualitative, ~2-3 paragraphs, takeaway =
   "distribution is harder than product"), "Built with," install via DMG, build from
   source, contributing, license.
3. Has `CONTRIBUTING.md` framed for portfolio-piece / slow-maintenance reality
   (best-effort review, major architectural changes unlikely).
4. Has `SECURITY.md` pointing all disclosures to GitHub Security Advisories
   (no email channel).
5. Has `.github/ISSUE_TEMPLATE/bug_report.md`, `.github/ISSUE_TEMPLATE/feature_request.md`,
   `.github/PULL_REQUEST_TEMPLATE.md`.
6. Has 3 product screenshots committed in `screenshots/raw/` (editor with rendered
   markdown, browser tab, project overview) plus 1 animated demo GIF, all embedded
   in README. Three of those four come from copying existing landing-page assets;
   the browser tab + GIF are captured by user at an interactive checkpoint.
7. Has a redacted `docs/` directory: keeps `architecture.md`, `coding-patterns.md`,
   `token-counting-research.md` (linked from CLAUDE.md, contributor-useful);
   `git rm --cached` + `.gitignore` for `audit-report.md`, `launch-strategy.md`,
   `release-checklist.md`, `product-hunt/` (files stay local, leave the index,
   future commits don't track); deletes obsolete `pre-launch-todo.md` (references
   the stripped v1.0.5 LemonSqueezy paid flow); deletes any tracked `.DS_Store`.
8. Has a `.gitignore` that excludes macOS metadata (`.DS_Store`), Xcode build
   detritus (`build/`, `DerivedData/`, `*.xcuserstate`, `xcuserdata/`), Swift Package
   Manager state (`.build/`, `.swiftpm/`), and the redaction list from item 7.
9. Has `CLAUDE.md` updated with a header noting the project is open source and a
   "Contributors" pointer to `CONTRIBUTING.md`.
10. Has a completed secrets sweep (`git rev-list --all | xargs git grep -i …`)
    against the documented forbidden-token list (`secret`, `api[-_]key`, `token`,
    `password`, `wrangleapp.dev`, `lemonsqueezy`, analytics keys). Hits trigger an
    interactive checkpoint at execution time to decide filter-repo vs rotate-and-document.
11. Retains `.planning/` as a public-facing artifact — the structured planning
    history (PROJECT.md, ROADMAP.md, per-phase CONTEXT/PLAN/SUMMARY/VERIFICATION
    files) is *not* redacted and is *explicitly mentioned* in the README as a
    transparency feature for the AI-dev audience.

What Phase 14 does NOT deliver:

- **The actual public flip.** Repo stays private after Phase 14 ships. Phase 18
  is the flip + final secrets sweep + Release publish.
- **Signed-DMG / notarize / staple pipeline + `docs/release.md`** — Phase 16.
- **Landing page repositioning** — Phase 17.
- **Landing repo OSS surface** (`J-Krush/wrangle-landing` LICENSE/README/secrets
  sweep) — Phase 15 (independent, can run in parallel).
- **Git history rewrite for the `git rm --cached` files.** Phase 14 only changes
  the working-tree + index. The files remain in commit history. A history-rewrite
  decision is deferred to Phase 18's final sweep.
- **Code of Conduct** (e.g., Contributor Covenant) — not in REPO-* requirements;
  deferred unless user adds it explicitly.

</domain>

<decisions>
## Implementation Decisions

### Story narrative voice (REPO-02 section c)

- **D-01:** Voice is **reflective / lessons-learned** — a short essay framing
  the OSS pivot as a deliberate experiment, not a confession of failure.
  Rejected: matter-of-fact (too tight for the structure), mission-forward
  (revisionist), brief (under-delivers REPO-02 mandate).
- **D-02:** Specifics are **qualitative — no concrete numbers**. No PH rank, no
  DAU, no ad spend, no conversion %, no revenue. Phrasings like "the launch
  underperformed," "ad spend didn't convert at a rate that made sustained
  development viable," "a small group of paid users." Numbers in a public
  README are forever; the user prefers not to commit.
- **D-03:** Length is **tight — 2-3 short paragraphs**. Reads in ~30 seconds.
  Enough room for the launch beat, the ads beat, the lesson, the pivot.
  Rejected: medium with subheadings (bloats README), essay-with-linked-page
  (most readers won't click through).
- **D-04:** Takeaway is **"distribution is harder than product"** — frames the
  lesson as: built a focused tool, found a real audience (AI devs), but
  proving it to a wider market via paid ads + Product Hunt was the harder
  problem. OSS lets the tool find its right users organically.
- **D-05:** Story beats are pre-locked by Phase 13 context — PH launch date
  is **2026-04-22**, the channel experiment was **Reddit ads**, the framing
  is **portfolio piece**.

### `.planning/` directory public exposure

- **D-06:** When the repo flips public in Phase 18, `.planning/` **stays public**.
  All 41 currently-tracked commits + ~50 markdown files (PROJECT.md, ROADMAP.md,
  REQUIREMENTS.md, per-phase CONTEXT/PLAN/SUMMARY/VERIFICATION files, this very
  CONTEXT.md) are visible to any anonymous visitor. Rationale: for an audience
  that IS people building with AI-driven development workflows, `.planning/` is
  itself a product demo of GSD-style structured planning. Transparency is the
  feature. Rejected: filter-repo strip (loses transparency), stop-tracking-now
  (reads weird — past exposed, present opaque), selective keep (PROJECT/ROADMAP
  only, strip per-phase artifacts) was the second-best option but lost on the
  "show the work, including the gray-area decisions and discarded options"
  rationale.
- **D-07:** README **explicitly mentions** `.planning/` as a feature. Wording
  is planner discretion (Claude's discretion below), but the placement should
  land somewhere that a first-time visitor reading top-to-bottom sees it within
  the first 60 seconds (e.g., subsection inside "What this is" or its own
  one-paragraph section). The framing is "this repo includes its own structured
  planning history — see how the OSS pivot got decided in Phase 13," not a
  generic "see `.planning/` for details."

### `docs/` redaction (REPO-12)

- **D-08:** **Keep as-is, public:** `docs/architecture.md` (6.6 KB), `docs/coding-patterns.md`
  (9 KB), `docs/token-counting-research.md` (3.7 KB). All three are linked from
  CLAUDE.md and useful to contributors. No redaction.
- **D-09:** **Delete from disk + don't reintroduce:** `docs/pre-launch-todo.md`
  (2.5 KB, obsolete — references the v1.0.5 LemonSqueezy paid-launch flow that
  Phase 13 stripped) and any tracked `docs/.DS_Store` / `docs/**/.DS_Store`.
- **D-10:** **`git rm --cached` + add to `.gitignore`** (file stays on user's
  local disk, leaves the git index, future commits don't track; HISTORY still
  contains the file — separate Phase 18 decision):
  - `docs/audit-report.md` (30 KB, Feb 2026 internal SwiftUI codebase audit — reveals known issues)
  - `docs/launch-strategy.md` (8 KB, "anti-marketing playbook," pre-OSS-pivot, internal)
  - `docs/release-checklist.md` (4 KB, internal release process — could be useful publicly but user prefers private)
  - `docs/product-hunt/` (entire directory, 4 files ~10 KB total: tagline.md, description.md, maker-comment.md, README.md — historical PH launch artifacts, pre-OSS-pivot)
- **D-11:** Phase 18 will revisit whether to rewrite git history to remove these
  files from past commits. Phase 14 only changes the working tree + index.

### CONTRIBUTING.md framing (REPO-03)

- **D-12:** Voice is **portfolio-piece / slow-maintenance**. CONTRIBUTING.md
  explicitly sets expectations: "This is a personal portfolio project. Issues
  and PRs are welcome, but review is best-effort — expect days-to-weeks, not
  hours. Major architectural changes are unlikely to be accepted." Rejected:
  open-collaboration framing (sets unsustainable maintenance expectations),
  minimalist (punts the question), you-decide (user wanted this nailed down).
- **D-13:** CONTRIBUTING.md links to / references CLAUDE.md and
  `docs/coding-patterns.md` for code conventions (per REPO-03). Documents the
  GSD `.planning/` workflow as "how contributions are scoped and planned"
  rather than treating `.planning/` as invisible internal scaffolding —
  consistent with D-06's transparency posture.

### SECURITY.md disclosure channel (REPO-10)

- **D-14:** Disclosure channel is **GitHub Security Advisories only.**
  SECURITY.md instructs reporters to use the repo's Security tab → "Report a
  vulnerability." No email channel listed. Rationale: built-in private
  disclosure flow, no inbox to monitor, no email-rotation problem later. Best
  for a portfolio-piece project. Rejected: `jkrush@pm.me` (mixes personal mail
  with sec reports), dedicated oss email (overkill), both channels (dedupe
  burden).

### README disposition (REPO-02)

- **D-15:** **Heavy rewrite** to match REPO-02's 8-section structure (a-h),
  but **preserve the current README's "Key Features" bullet list verbatim**
  (it's tight, accurate, and didn't need changes for the OSS pivot). Drop the
  current "Getting Started / Build & Run" subsection and replace with REPO-02's
  required Install (DMG download) + Build from source sections. Drop everything
  else from the current README. Rejected: light-edit-on-top (ends up structurally
  weaker than REPO-02 mandates), fresh blank rewrite (loses the well-tuned
  feature list).

### Screenshots / animated GIF (REPO-07)

- **D-16:** **Copy three existing assets** from
  `/Users/krush/Projects/Krush-Dev/Wrangle/Landing Page/public/images/product-images/`
  into this repo's `screenshots/raw/`:
  - `editor-simple.png` → "editor with rendered markdown" requirement.
  - `project-overview.png` → "project overview" requirement.
  - `terminal.png` → bonus / Built-with-an-embedded-terminal visual support
    (not REPO-07 mandated but enhances the README).
  These are April-21 captures, predating Phase 13. Phase 13 did NOT touch the
  editor / project-overview / terminal UI, so they remain accurate. Visual
  review during planning will confirm.
- **D-17:** **Interactive checkpoint** at execution time, modeled on Plan
  13-03 Task 1, asks the user to capture:
  - 1 PNG of an active browser tab (the v1.2 browser-tab feature reactivation
    isn't represented in the existing assets — they predate it).
  - 1 animated GIF demonstrating markdown rendering in action (~5-10s loop,
    capture tool is user's choice — Cleanshot / Kap / built-in).
  Both files drop into `screenshots/raw/` at user-chosen filenames; planner's
  README embeds use placeholder paths the user replaces inline at the
  checkpoint.
- **D-18:** Existing `screenshots/raw/Wrangle-2026-04-21-173707-2x-native.png`
  (April-21 capture, tracked in git) — keep, may or may not be re-used in
  README. Planner inspects and includes if it adds value (e.g., as the hero
  image), otherwise leaves it for archival.

### Secrets sweep recovery strategy (REPO-09)

- **D-19:** **Defer the recovery strategy to execution-time results.** Plan
  step: run the full sweep
  `git rev-list --all | xargs git grep -i 'secret\|api[-_]key\|token\|password\|wrangleapp.dev\|lemonsqueezy'`
  plus analytics-key variants (`plausible`, `fathom`, `posthog`, `mixpanel`,
  `segment`). If grep returns clean → REPO-09 satisfied, no further work.
  If grep finds hits → pause at an interactive checkpoint surfacing the hits
  + ask: `git filter-repo` (rewrites history, breaks any clones, rewrites
  tags — practical impact zero since you have one remote and only your local
  copy) vs rotate-and-document (revoke the credential, document as
  "known-rotated" in SECURITY.md, accept that public can see the now-invalid
  token in history). Rejected: pre-commit to filter-repo (wasteful if grep
  is clean), pre-commit to rotate-only (loses the option to clean history if
  the find is serious).
- **D-20:** APP-13-style exemption list applies — `wrangleapp.dev` is
  intentionally present in About-panel credits (Phase 13 D-12). Any sweep
  hit on `wrangleapp.dev` outside that one surface is a genuine find.

### Claude's Discretion

- Exact CONTRIBUTING.md wording within "portfolio-piece / slow-maintenance"
  framing — tone, phrasing, response-time language ("best-effort," "days to
  weeks," "may not be accepted") is planner's call.
- Exact README hero pitch phrasing (1 paragraph above the first screenshot).
  Stitch from current README's Overview + PROJECT.md's positioning. Planner
  picks the strongest single sentence.
- Exact story prose within D-01..D-05 constraints — planner drafts the 2-3
  paragraphs. Reviewer (user) iterates after first draft.
- Exact SECURITY.md wording — 5-15 line file pointing at the Security
  Advisories flow + a "what counts as a vulnerability" note. Planner's call
  on tone (formal vs friendly).
- Issue template fields within REPO-04 / REPO-05 mandates — REPO-04 specifies
  steps-to-reproduce / expected-vs-actual / macOS version / Wrangle version /
  screenshot; planner picks exact field labels + ordering + any optional
  fields beyond the mandated set.
- PR template checklist exact items beyond REPO-06 mandate (description,
  screenshots if UI, tests run, CLAUDE.md conventions followed).
- `.gitignore` patterns beyond the redaction-list addition — standard macOS +
  Xcode + Swift Package Manager set is planner's call (see canonical refs for
  the GitHub `Swift.gitignore` template).
- README placement for the `.planning/` callout — subsection inside "What
  this is" / standalone section / footer note. Planner picks based on flow,
  per D-07.
- Whether to also add a public-friendly `ROADMAP.md` at repo root (separate
  from `.planning/ROADMAP.md`, summarizing what's planned for the project
  going forward) — not REPO-* mandated; planner decides if it'd help the
  story or if `.planning/ROADMAP.md` alone is enough.
- Whether copied landing-page screenshots get renamed (e.g.,
  `editor-simple.png` → `01-editor-rendered.png`) for README clarity.
- The order of file delivery within Phase 14's plans — REPO-01 (LICENSE) is
  obviously first; the README, CONTRIBUTING, SECURITY, templates, docs
  redaction, secrets sweep can be sequenced as planner prefers.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone requirements

- `.planning/REQUIREMENTS.md` §REPO-01 through §REPO-12 — the 12 requirements
  this phase satisfies (1-to-1 with Phase 14).
- `.planning/ROADMAP.md` §Phase 14 — Goal, Depends-on (Phase 13), Success
  Criteria (5 rows), Plans (expected 3).
- `.planning/PROJECT.md` §Current Milestone v1.3 — milestone narrative
  (OSS conversion as portfolio piece, PH 2026-04-22 + Reddit ads channel
  experiment).

### Prior-phase context that flows through

- `.planning/phases/13-app-de-commercialization/13-CONTEXT.md` — locks the
  OSS-pivot rationale, the MIT attribution, the Star-on-GitHub URL/CTA, the
  About-panel survival of `wrangleapp.dev`, and the v1.3 story beats. The
  story narrative in Phase 14's README inherits all of these.
- `.planning/phases/13-app-de-commercialization/13-02-SUMMARY.md` — confirms
  the `wrangleapp.dev` + GitHub dual-link Out panel layout that's
  install-instruction-adjacent in the README.
- `.planning/STATE.md` §Pending Todos — "Capture the 3+ README screenshots +
  animated demo GIF in Phase 14" is the live tracking entry this phase closes.
- `.planning/STATE.md` §Blockers/Concerns — the "Repo history secrets" entry
  is the source of D-19's strategy-deferral approach.

### Existing repo artifacts to preserve / reference

- `README.md` (current, repo root, 13.5 KB, last edited 2026-03-06) — feature
  list at top is preserved verbatim per D-15.
- `CLAUDE.md` (current, repo root) — updated per REPO-11 with OSS header +
  Contributors pointer; the planning section also flows into CONTRIBUTING.md
  per D-13.
- `docs/architecture.md`, `docs/coding-patterns.md`, `docs/token-counting-research.md` —
  kept as-is per D-08; referenced from CONTRIBUTING.md per REPO-03.
- `screenshots/raw/Wrangle-2026-04-21-173707-2x-native.png` — existing tracked
  screenshot, may or may not be re-used per D-18.

### External assets to import

- `/Users/krush/Projects/Krush-Dev/Wrangle/Landing Page/public/images/product-images/editor-simple.png`
  — copy into `screenshots/raw/` per D-16.
- `/Users/krush/Projects/Krush-Dev/Wrangle/Landing Page/public/images/product-images/project-overview.png`
  — copy into `screenshots/raw/` per D-16.
- `/Users/krush/Projects/Krush-Dev/Wrangle/Landing Page/public/images/product-images/terminal.png`
  — copy into `screenshots/raw/` per D-16.
  - Note: these assets live in a *different* git repo (the landing-page repo).
    The copy operation produces new file refs in the Wrangle app repo; the
    landing-page originals are untouched and continue to serve the live site.

### Standards to follow

- GitHub's official `Swift.gitignore`
  (`https://github.com/github/gitignore/blob/main/Swift.gitignore`) — baseline
  for the `.gitignore` rewrite (REPO-08), with macOS + Xcode SPM additions.
- GitHub Security Advisories flow
  (`https://docs.github.com/en/code-security/security-advisories/guidance-on-reporting-and-writing/privately-reporting-a-security-vulnerability`)
  — referenced from SECURITY.md per D-14.
- Optional reference, not adopted: Contributor Covenant
  (`https://www.contributor-covenant.org/`) — not in REPO-* mandate;
  CONTRIBUTING.md may reference it in a "Code of Conduct" subsection if
  planner thinks the portfolio-piece framing benefits from one, otherwise skip.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- **Current `README.md` feature list** — the "Key Features" bullet block is
  tight and accurate (inline markdown rendering, XML-in-markdown highlighting,
  embedded terminal, token counting, fuzzy finder, file tree + bookmarks, AI
  file recognition). Preserved verbatim per D-15; only the surrounding
  structure changes.
- **`docs/architecture.md`** — already documents the SwiftUI + AppKit + NSTextView
  editor core, SwiftData persistence layer, SwiftTerm terminal embed. REPO-03
  CONTRIBUTING.md "where to start contributing" pointer routes here without
  needing a rewrite.
- **`docs/coding-patterns.md`** — already documents the modern-concurrency
  conventions (`@Observable`, `@MainActor`, `async/await`, Task-based
  debouncing, regex caching). REPO-03 CONTRIBUTING.md coding-conventions
  pointer routes here.
- **CLAUDE.md** — already documents the project's tech stack, sidebar/overview
  conventions, NSTextView constraints, and AI-file-awareness pattern.
  REPO-11's OSS-header + Contributors-pointer update lands at the top of this
  file.
- **Landing-page product-images library** — 12 product PNGs already captured
  for the live site; three are directly usable for REPO-07 (D-16). Saves the
  user from re-shooting most of REPO-07's required assets.

### Established Patterns

- **`.planning/` per-phase directory structure** — `XX-name/XX-CONTEXT.md`,
  `XX-NN-{plan-slug}-PLAN.md`, `XX-NN-SUMMARY.md`, `XX-VERIFICATION.md`,
  `XX-SECURITY.md`, `XX-VALIDATION.md`, `XX-UAT.md`. The README's
  `.planning/` callout (D-07) can pitch this structure to contributors.
- **Phase 13's "interactive checkpoint" pattern** (Plan 13-03 Task 1) — the
  executor pauses, surfaces an `AskUserQuestion` for a user-driven action
  (e.g., Xcode GUI steps), validates the result, continues. D-17's
  browser-tab + GIF capture step lifts this pattern verbatim. Planner uses
  the same checkpoint formulation.
- **MIT license attribution string** — Phase 13 PROJECT.md and 13-CONTEXT.md
  both reference "Copyright (c) 2026 J Krush." Phase 14 LICENSE writes this
  exact string at REPO-01.
- **`@User` rebrand** — the project recently moved from `Krush` to `J-Krush`
  for credits / copyright (see commit `52b72c5`). README author credit + the
  LICENSE attribution use `J-Krush` consistently.
- **`gsd-pr-branch` skill exists** — the project has historically routed PRs
  through a branch that filters out `.planning/` commits. With D-06's
  decision to keep `.planning/` public, the skill remains useful for
  external contributor PRs that shouldn't touch `.planning/` directly,
  but the public flip in Phase 18 doesn't require pre-flip `.planning/`
  filtering.

### Integration Points

- **Repo root** is the primary surface for Phase 14 (LICENSE, README,
  CONTRIBUTING, SECURITY, `.gitignore`, `.github/`, `screenshots/`).
- **CLAUDE.md** gets a header note + Contributors pointer at REPO-11.
- **`docs/`** undergoes the redaction outlined in D-08..D-10.
- **`screenshots/raw/`** receives the three copied landing-page assets
  (D-16) and gains a browser-tab PNG + demo GIF via the user checkpoint
  (D-17).
- **`.gitignore`** at repo root gets a comprehensive rewrite (REPO-08)
  incorporating macOS + Xcode + SPM defaults + the D-10 redaction list +
  `xcuserdata/` (catches the long-standing hygiene issue surfaced during
  Plan 13-03's commit).
- **Existing `wrangle.xcodeproj/xcuserdata/krush.xcuserdatad/xcschemes/xcschememanagement.plist`
  is currently tracked** — REPO-08 / `.gitignore` work should also
  `git rm --cached` this entry (in addition to adding the pattern).

### Code Hotspots / Complexity

- **`.planning/` directory size** — 41 commits, ~50+ markdown files. When the
  repo flips public in Phase 18, GitHub renders the full tree. Visually
  scanning the `.planning/` tree should not surface any sensitive content
  (no API keys, no customer data) given the project's planning has all been
  about app architecture and the OSS-pivot decision. Planner inspects
  `.planning/PROJECT.md` and `.planning/STATE.md` "Decisions" / "Blockers"
  sections during planning to confirm.
- **`docs/audit-report.md`'s `git rm --cached` operation** is the most
  invasive Phase 14 git operation. Touches 30 KB. Worth a quick visual
  confirmation that the file remains on disk after the operation (so the
  user's local dev workflow is unaffected) and that future commits
  genuinely don't include it.
- **Existing screenshot's freshness** — `screenshots/raw/Wrangle-2026-04-21-173707-2x-native.png`
  predates Phase 13. Planner spot-checks during planning whether it still
  represents current UI; if not, D-18 says it's archival.

</code_context>

<specifics>
## Specific Ideas

- **MIT attribution string is locked**: `Copyright (c) 2026 J Krush` exactly.
  Not `John Kreisher`, not `Krush`, not `Krush LLC`. Matches Phase 13's
  credit rebrand (commit `52b72c5`).
- **README repo URL is locked**: `https://github.com/J-Krush/wrangle` exactly.
  Same URL as the Phase 13 "Star on GitHub" CTA.
- **Story takeaway is one sentence**: "distribution is harder than product."
  Planner expands into prose but should not dilute or replace the core
  framing.
- **Screenshot import is a `cp` operation, not a `mv`** — the landing-page
  originals stay where they are; only the Wrangle repo gets new copies. Both
  repos own their own `screenshots/` / `images/` independently going forward.
- **The browser-tab screenshot is the only genuinely missing visual asset** —
  the landing-page library covers editor + project-overview + terminal + a
  notification-UI set, but not the browser tab feature reactivated in v1.2.
- **CONTRIBUTING.md's "PRs welcome but slow review" framing applies to
  external contributors, not the user.** The user's own work continues
  through the GSD workflow inside `.planning/` and bypasses the slow-review
  framing.
- **No Code of Conduct, no `CHANGELOG.md` at repo root**, no `ROADMAP.md` at
  repo root unless planner deems them useful — REPO-* doesn't mandate them.

</specifics>

<deferred>
## Deferred Ideas

- **Git history rewrite for the `git rm --cached` files** (D-11) — Phase 18
  decides whether to `git filter-repo` `docs/audit-report.md`,
  `docs/launch-strategy.md`, `docs/release-checklist.md`, and
  `docs/product-hunt/` out of history. Phase 14 only changes the working
  tree + index.
- **Public-friendly `ROADMAP.md` at repo root** — separate from
  `.planning/ROADMAP.md`. Optional planner-discretion item per D-15 Claude's
  Discretion list; if not adopted in Phase 14, defer to a v1.4 docs phase.
- **Code of Conduct** (Contributor Covenant) — not REPO-* mandated; defer
  unless the user requests it.
- **`CHANGELOG.md` at repo root** — public-facing changelog. The in-app
  WhatsNewChangelog.swift already documents user-facing changes; whether a
  separate `CHANGELOG.md` at repo root is worth the maintenance cost is
  deferred. Likely Phase 18 or v1.4.
- **GitHub Actions CI** — automated tests, lint, build on PR. Not REPO-*
  mandated; deferred to v1.4 (consistent with PROJECT.md's "no GH Actions
  automation this milestone" lock).
- **Screenshots/GIF re-capture pass after Phase 17 landing-page redesign** —
  the landing site itself may get new screenshots for its OSS-positioned
  hero; if those land cleaner than the current April-21 set, Phase 14's
  README screenshots may be worth refreshing. Defer to a v1.4 polish.
- **Migrating CLAUDE.md private guidance into a separate public
  `AI-CONTRIBUTING.md`** — CLAUDE.md currently mixes project conventions
  with Claude-specific instructions. Phase 14 just adds an OSS header per
  REPO-11; a cleaner split between human-contributor and AI-agent guidance
  is deferred to a v1.4 docs cleanup.
- **`gsd-pr-branch` skill workflow update** — with `.planning/` going public,
  the skill's "filter out `.planning/` commits before PR" behavior may need
  rethinking. Out of scope for Phase 14; revisit if/when external PRs start
  arriving.

</deferred>

---

*Phase: 14-app-repo-oss-surface*
*Context gathered: 2026-05-20*
