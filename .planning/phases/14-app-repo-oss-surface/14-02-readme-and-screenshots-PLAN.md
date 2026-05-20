---
id: 14-02-readme-and-screenshots
phase: 14-app-repo-oss-surface
plan: 02
type: execute
wave: 2
depends_on: ["14-01"]
files_modified:
  - README.md
  - screenshots/raw/editor-simple.png
  - screenshots/raw/project-overview.png
  - screenshots/raw/terminal.png
  - screenshots/raw/browser-tab.png
  - screenshots/raw/demo.gif
autonomous: false

requirements: [REPO-02, REPO-07]

must_haves:
  truths:
    - "README.md is structured per REPO-02 sections (a) hero+screenshot, (b) What this is, (c) Why it's free and open source now, (d) Built with, (e) Install, (f) Build from source, (g) Contributing, (h) License — in that order."
    - "Section (c) story is 2-3 paragraphs, tight ~30-second read (D-03), in reflective-lessons-learned voice (D-01), qualitative-no-numbers (D-02), with the takeaway 'distribution is harder than product' (D-04) and the locked beats: 2026-04-22 Product Hunt launch + Reddit ads channel experiment + portfolio-piece framing (D-05)."
    - "Current README's 'Key Features' bullet list is preserved verbatim per D-15."
    - "README explicitly mentions `.planning/` as a transparency feature per D-07, consistent with D-06's decision that `.planning/` stays public on the Phase 18 flip."
    - "screenshots/raw/ contains the 3 copied landing-page assets (editor-simple.png, project-overview.png, terminal.png) per D-16 + 1 user-captured browser-tab PNG + 1 user-captured demo GIF from the D-17 interactive checkpoint, all embedded in README; the existing `Wrangle-2026-04-21-173707-2x-native.png` is retained per D-18 (reuse is planner discretion)."
  artifacts:
    - path: "README.md"
      provides: "Story-driven public README per REPO-02"
      contains: "distribution is harder than product"
    - path: "screenshots/raw/editor-simple.png"
      provides: "Editor with rendered markdown screenshot"
    - path: "screenshots/raw/project-overview.png"
      provides: "Project overview screenshot"
    - path: "screenshots/raw/terminal.png"
      provides: "Embedded terminal screenshot"
    - path: "screenshots/raw/browser-tab.png"
      provides: "Active browser tab screenshot (user-captured at checkpoint)"
    - path: "screenshots/raw/demo.gif"
      provides: "Animated demo GIF (user-captured at checkpoint)"
  key_links:
    - from: "README.md"
      to: "LICENSE"
      via: "License section link"
      pattern: "\\(LICENSE\\)"
    - from: "README.md"
      to: "CONTRIBUTING.md"
      via: "Contributing section link"
      pattern: "\\(CONTRIBUTING\\.md\\)"
    - from: "README.md"
      to: "https://github.com/J-Krush/wrangle/releases/latest"
      via: "Install section DMG download link"
      pattern: "releases/latest"
    - from: "README.md"
      to: ".planning/"
      via: ".planning/ callout per D-07"
      pattern: "\\.planning/"
    - from: "README.md"
      to: "screenshots/raw/editor-simple.png"
      via: "Embedded image"
      pattern: "screenshots/raw/editor-simple\\.png"
---

<objective>
Rewrite `README.md` heavily per REPO-02's 8-section structure (a-h) while
preserving the current README's "Key Features" bullet list verbatim (D-15).
Import 3 landing-page screenshots into `screenshots/raw/`; capture 1
browser-tab PNG + 1 demo GIF via an interactive checkpoint (D-17); embed
all 5 visuals in the README at their canonical sections.

Purpose: This is THE portfolio piece — the first thing an anonymous visitor
sees when the repo flips public in Phase 18. The story-driven section (c) is
the differentiator from a generic README; the screenshots make the product
real. Plan 14-01's LICENSE / CONTRIBUTING / SECURITY must exist first so
this README's link block resolves to real files.
Output: One rewritten README.md + 5 image assets in `screenshots/raw/`.
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
@README.md
@CLAUDE.md
@docs/architecture.md

<interfaces>
<!-- Locked strings the executor must use verbatim -->

Repo URL (D-05, D-20):
- `https://github.com/J-Krush/wrangle`

Release URL pattern (REPO-02 (e), Phase 16 will publish here):
- `https://github.com/J-Krush/wrangle/releases/latest`

Story beats (D-01..D-05 locked, all paraphrased in planner's prose — no numbers):
- Product Hunt launch on 2026-04-22 (date is the only number allowed in the story)
- Reddit ads channel experiment
- "Distribution is harder than product" (D-04 takeaway, must appear as a near-verbatim phrase)
- Portfolio-piece framing (D-05)

Preserved-verbatim block (D-15) — copy these bullets EXACTLY from current README.md:21-27:
- "**Inline markdown rendering** — Rich formatting displayed as you type, raw syntax revealed at the cursor"
- "**XML-in-markdown highlighting** — First-class rendering for `<tools>`, `<instructions>`, and other XML tags common in AI prompts"
- "**Embedded terminal** — Full terminal via SwiftTerm, launch shells or Claude Code sessions without leaving the editor"
- "**Token counting** — Approximate token counts in the status bar for prompt files"
- "**Fuzzy finder** — `Cmd+P` to quickly open any file across all bookmarked projects"
- "**File tree with bookmarks** — Bookmark directories for fast access with security-scoped persistence"
- "**AI file recognition** — Distinct icons and behavior for `CLAUDE.md`, `SKILL.md`, `AGENTS.md`, and system prompt files"

Tech stack (REPO-02 (d) "Built with"):
- Swift 5.9+ / SwiftUI / SwiftData / SwiftTerm / WKWebView
- macOS 15+ (Sequoia), Apple Silicon

Landing-page screenshot source paths (D-16 — these are `cp`, not `mv`):
- `/Users/krush/Projects/Krush-Dev/Wrangle/Landing Page/public/images/product-images/editor-simple.png`
- `/Users/krush/Projects/Krush-Dev/Wrangle/Landing Page/public/images/product-images/project-overview.png`
- `/Users/krush/Projects/Krush-Dev/Wrangle/Landing Page/public/images/product-images/terminal.png`
</interfaces>
</context>

<tasks>

<task type="auto">
  <name>Task 1: Copy 3 landing-page screenshots into screenshots/raw/</name>
  <files>screenshots/raw/editor-simple.png, screenshots/raw/project-overview.png, screenshots/raw/terminal.png</files>
  <read_first>
    - .planning/phases/14-app-repo-oss-surface/14-CONTEXT.md (D-16 — exact source paths + `cp` not `mv`)
    - .planning/REQUIREMENTS.md §REPO-07
  </read_first>
  <action>
    Run three `cp` operations to copy the landing-page product-image assets into the Wrangle repo's `screenshots/raw/` directory. Source paths (D-16, locked) — these live in a different git repo (the landing-page repo at `/Users/krush/Projects/Krush-Dev/Wrangle/Landing Page/`); the operation is a copy, not a move; the originals stay where they are. Destination is `screenshots/raw/` (which already exists and is tracked). Use the same filenames at the destination: `editor-simple.png`, `project-overview.png`, `terminal.png`. Do NOT rename (CONTEXT.md Claude's Discretion lists renaming as optional; planner picks "keep names" for source-traceability). After copy, do not modify the PNG content (no resize, no recompress). Per REPO-07 + D-16.
  </action>
  <verify>
    <automated>test -f screenshots/raw/editor-simple.png && test -f screenshots/raw/project-overview.png && test -f screenshots/raw/terminal.png && [ $(stat -f%z screenshots/raw/editor-simple.png) -gt 100000 ] && [ $(stat -f%z screenshots/raw/project-overview.png) -gt 100000 ] && [ $(stat -f%z screenshots/raw/terminal.png) -gt 100000 ]</automated>
  </verify>
  <acceptance_criteria>
    - All three files exist under `screenshots/raw/`: `editor-simple.png`, `project-overview.png`, `terminal.png`.
    - Each file is >100 KB (a sanity check that the copy succeeded and didn't produce an empty or near-empty file — sources are 798 KB / 283 KB / 508 KB respectively).
    - The landing-page source files at `/Users/krush/Projects/Krush-Dev/Wrangle/Landing Page/public/images/product-images/` still exist after the operation (the copy did not move).
    - `file screenshots/raw/editor-simple.png` reports PNG image data.
  </acceptance_criteria>
  <done>
    3 screenshots present in `screenshots/raw/`, ready to be embedded in the README in Task 3. Half of REPO-07's "at least 3 screenshots" mandate satisfied (the other 2 — browser tab + demo GIF — come from Task 2).
  </done>
</task>

<task type="checkpoint:human-verify" gate="blocking">
  <name>Task 2: Capture browser-tab PNG + animated demo GIF (interactive)</name>
  <files>screenshots/raw/browser-tab.png, screenshots/raw/demo.gif</files>
  <read_first>
    - .planning/phases/14-app-repo-oss-surface/14-CONTEXT.md (D-17 — modeled on Plan 13-03 Task 1 pattern; user picks tool and filenames; ~5-10s GIF)
    - .planning/REQUIREMENTS.md §REPO-07 ("at least 3 screenshots ... plus an animated demo GIF ... visibly embedded in README.md")
    - .planning/phases/13-app-de-commercialization/13-03-test-target-wireup-PLAN.md (the pattern reference for interactive checkpoints)
  </read_first>
  <what-built>
    The previous task copied 3 existing landing-page screenshots. Two visual assets remain to be captured by the user — the v1.2 browser-tab feature isn't represented in the landing-page library (predates it), and an animated demo GIF must be created. The planner's README embeds use placeholder paths the user replaces inline at this checkpoint.
  </what-built>
  <how-to-verify>
    The executor pauses here and prompts the user to do TWO things:

    **(1) Capture browser-tab PNG** —
    - Launch Wrangle (Cmd+R from Xcode or open the built app)
    - Open a Browser tab (Cmd+T → Browser, or via UnifiedAddMenu)
    - Navigate to any clean, visually-interesting page (suggestions: `github.com/J-Krush/wrangle`, `apple.com/macos`, a docs site — pick a page that demonstrates the browser-tab feature WITHOUT showing the user's private bookmarks/history)
    - Capture the window: `screencapture -l <windowID> -o screenshots/raw/browser-tab.png` (or use Cleanshot / built-in Cmd+Shift+4)
    - Confirm the file lands at `screenshots/raw/browser-tab.png` (executor's README embed uses this exact path — if the user picks a different filename, the executor edits the README embed inline before continuing)

    **(2) Capture animated demo GIF** —
    - Pick a workflow to demo (suggestion: open a `.md` file in Wrangle and type — show inline markdown rendering as it happens; or scroll a CLAUDE.md with XML tags)
    - Record ~5-10 seconds with Cleanshot / Kap / built-in screen recorder
    - Export as GIF (NOT MP4 — README embed needs to autoplay on GitHub.com; only animated GIF or APNG work there without click-to-play)
    - Save to `screenshots/raw/demo.gif`
    - Target file size: keep under 10 MB if possible (GitHub will display GIFs >10 MB but slower; if Kap produces a bigger file, that's fine for v1 — Phase 14 Deferred Ideas allow a v1.4 refresh)

    **(3) Pre-commit visual inspection** — Before approving:
    - Open both files and confirm they do NOT show:
      - Slack/Discord DMs or unread badges
      - Browser tabs with auth tokens or session URLs in the address bar
      - Terminal output containing API keys, passwords, or `wrangleapp.dev/api/trial/*` traces (Phase 13 stripped these but a local backup might still display them in a recent-history view)
      - Personal file names that don't belong public (real client names, etc.)
    - If anything sensitive is visible, re-capture before approving.

    Then return one of:
    - `approved` — both files present and visually clean; executor proceeds to Task 3
    - `re-capture <which-file>` — re-capture and re-prompt
    - `different filename: <filename>` — file landed at a different name; executor updates the README embed paths accordingly
  </how-to-verify>
  <action>
    Interactive checkpoint — see `<what-built>` and `<how-to-verify>` above. The executor pauses, surfaces an AskUserQuestion prompt asking the user to (1) capture a browser-tab PNG by launching Wrangle, opening a Browser tab, navigating to a clean public page, and screen-capturing with `screencapture -l <windowID> -o screenshots/raw/browser-tab.png` (or Cleanshot / Cmd+Shift+4); (2) capture a ~5-10 second animated GIF demonstrating markdown rendering, saving to `screenshots/raw/demo.gif`; (3) visually inspect both files for sensitive content (Slack DMs, auth tokens in URLs, API keys in terminal output, personal filenames) before approving. User responds with `approved`, `re-capture <file>`, or `different filename: <filename>`. Per D-17.
  </action>
  <verify>
    <human-check>User confirms both screenshots/raw/browser-tab.png (or chosen filename) and screenshots/raw/demo.gif (or chosen filename) exist, are PNG/GIF format respectively, and contain no sensitive on-screen content. Executor verifies with: `test -f screenshots/raw/browser-tab.png && test -f screenshots/raw/demo.gif && file screenshots/raw/browser-tab.png | grep -q PNG && file screenshots/raw/demo.gif | grep -qi gif` — substituting alternate filenames if the user chose them.</human-check>
  </verify>
  <resume-signal>Type `approved`, or describe what to fix / which filename was used.</resume-signal>
  <acceptance_criteria>
    - `screenshots/raw/browser-tab.png` exists (or the user's chosen filename — executor adjusts README embeds to match before resuming).
    - `screenshots/raw/demo.gif` exists (or the user's chosen filename — same adjustment).
    - User has confirmed (via the resume signal) that both files visually contain no sensitive content per the pre-commit inspection list.
    - Both files are PNG / GIF format respectively (`file` command confirms).
  </acceptance_criteria>
  <done>
    Two user-captured assets present in `screenshots/raw/`; executor knows the final filenames to embed in README Task 3.
  </done>
</task>

<task type="auto">
  <name>Task 3: Rewrite README.md per REPO-02 8-section structure with embedded media</name>
  <files>README.md</files>
  <read_first>
    - README.md (current — preserve the "Key Features" bullet list verbatim per D-15; drop everything else)
    - .planning/phases/14-app-repo-oss-surface/14-CONTEXT.md (D-01..D-07, D-15, D-18)
    - .planning/REQUIREMENTS.md §REPO-02
    - .planning/PROJECT.md (current milestone narrative — source for the story-section beats)
    - LICENSE (must exist per Plan 14-01 Task 1 — README's License section links to it)
    - CONTRIBUTING.md (must exist per Plan 14-01 Task 3 — README's Contributing section links to it)
  </read_first>
  <action>
    Heavy rewrite of `README.md` per REPO-02's mandated 8-section structure. Drop all content below the current "Key Features" block (which removes: Getting Started, Project Structure, Scripts, Marketing Screenshots, Marketing Videos, Release Guide, Dev & Internal Builds, Documentation, Architecture — per D-15). The user-facing README is structured top-to-bottom as:

    **Top of file:**
    - H1: `# Wrangle`
    - (a) **Hero pitch** — One paragraph (planner's exact phrasing, stitched from PROJECT.md's positioning + current README's Overview — Claude's Discretion). Must convey: native macOS markdown editor, purpose-built for developers working with AI agents, inline rendering as you type. Immediately below the paragraph, embed the hero image: `![Wrangle editor with rendered markdown](screenshots/raw/editor-simple.png)`. (Per D-18, optionally instead use `screenshots/raw/Wrangle-2026-04-21-173707-2x-native.png` if the planner inspects it during execution and decides it's stronger — but `editor-simple.png` is the recommended default since D-16 explicitly maps it to the "editor with rendered markdown" REPO-07 requirement.)

    **Section (b) — What this is**
    - H2: `## What this is`
    - 2-4 paragraphs covering: native macOS markdown editor, AI-file-awareness angle (CLAUDE.md, SKILL.md, AGENTS.md, system prompts), XML-in-markdown rendering, embedded terminal, token counting.
    - Subsection — `### Key features` — paste the CURRENT README's 7-bullet "Key Features" list verbatim per D-15 (lines 13-19 of the current README.md). Do not edit the bullets; do not reorder; do not add or remove.
    - Subsection — `### How this project is planned` (or planner's exact heading matching D-07's flow) — 1 short paragraph mentioning `.planning/` as a transparency feature: "This repo includes its own structured planning history under `.planning/` — phases, requirements, decisions, summaries. The OSS pivot itself was scoped and decided in `.planning/phases/13-app-de-commercialization/` and `.planning/phases/14-app-repo-oss-surface/`. See it as a product demo of GSD-style structured planning for AI-driven workflows." Per D-07 the `.planning/` callout MUST appear visible within the first 60 seconds of top-to-bottom reading; placing it inside section (b) satisfies that.
    - Embed `![Project overview](screenshots/raw/project-overview.png)` at the end of section (b).

    **Section (c) — Why it's free and open source now**
    - H2: `## Why it's free and open source now`
    - 2-3 paragraphs (D-03 tight). Voice: reflective lessons-learned per D-01. Beats (D-05):
      - Paragraph 1: The product worked — a native macOS editor for AI-prompt workflows found a real audience of AI devs.
      - Paragraph 2: Distribution was the hard part. Reference the Product Hunt launch on **2026-04-22** (date is the only number allowed — D-02 forbids ranks, DAUs, ad spend, conversion %, revenue). Reference the **Reddit ads channel experiment**. Use D-02 phrasings like "the launch underperformed," "ad spend didn't convert at a rate that made sustained development viable," "a small group of paid users." NO concrete numbers — no PH rank, no MRR, no ad spend, no conversion %, nothing the user later wishes was private.
      - Paragraph 3: The takeaway — "**distribution is harder than product**" (D-04, must appear near-verbatim). The pivot — converting to MIT + portfolio piece per D-05 — lets the tool find its right users organically without the user becoming a full-time marketer.
    - Embed `![Embedded terminal](screenshots/raw/terminal.png)` at the end of section (c) (or after section (d) — planner's call for flow).

    **Section (d) — Built with**
    - H2: `## Built with`
    - Bullet list (planner's exact items, but must include): Swift 5.9+, SwiftUI, SwiftData, SwiftTerm (with link to `https://github.com/migueldeicaza/SwiftTerm`), WKWebView, macOS 15+ (Sequoia), Apple Silicon (arm64).
    - Embed `![Active browser tab](screenshots/raw/browser-tab.png)` at the end of section (d) — or wherever the planner thinks flows best (D-07 / Claude's Discretion). If Task 2 ended with a different filename, the executor MUST update this embed path to match the user's filename before writing.

    **Section (e) — Install**
    - H2: `## Install`
    - Brief: "Download the latest signed DMG from [Releases](https://github.com/J-Krush/wrangle/releases/latest)." Then: "Open the DMG → drag Wrangle to Applications → launch. macOS 15 (Sequoia) or later, Apple Silicon."
    - Add a note: "DMG link goes live with the `v1.3.0` Release published in Phase 18 — the Release is currently drafted on a private repo. Once published, this link resolves automatically."

    **Section (f) — Build from source**
    - H2: `## Build from source`
    - Brief: Xcode 16+, macOS 15+, Apple Silicon. Clone, `open Wrangle.xcodeproj`, Cmd+R. SwiftTerm resolves via SPM on first build. Note: App Sandbox is disabled (required for the embedded terminal to launch child processes).
    - Embed `![Demo](screenshots/raw/demo.gif)` somewhere in this section or just below it (planner's call — the GIF works well as a "see it in action" capper before the Contributing block). If Task 2 used a different filename, executor updates the embed path.

    **Section (g) — Contributing**
    - H2: `## Contributing`
    - One paragraph linking to `[CONTRIBUTING.md](CONTRIBUTING.md)`. Set portfolio-piece expectations briefly (mirror D-12's framing: best-effort review, days-to-weeks).
    - One-line pointer to `[SECURITY.md](SECURITY.md)` for vulnerability disclosure.

    **Section (h) — License**
    - H2: `## License`
    - One line: "MIT — see [LICENSE](LICENSE)."

    **Voice and constraints:**
    - No numbers in section (c) other than the 2026-04-22 date (D-02).
    - The phrase "distribution is harder than product" must appear in section (c) (D-04).
    - The 7 "Key Features" bullets must appear verbatim from the current README (D-15).
    - The `.planning/` callout must appear in section (b) within the first 60 seconds of top-to-bottom reading (D-07).
    - Total length target: 150-300 lines.
    - Do NOT add a separate public `ROADMAP.md` (planner discretion declined — `.planning/ROADMAP.md` is enough per CONTEXT.md Deferred Ideas).
    - Do NOT add a `CHANGELOG.md` reference (deferred per CONTEXT.md Deferred Ideas).
    - Do NOT keep the current README's "Marketing Screenshots" / "Marketing Videos" / "Release Guide" sections — those are internal release-engineering docs and move to (Phase 16's) `docs/release.md`, not the public README.
    - Do NOT reference `wrangleapp.dev` anywhere in the README except as an inline note that it currently serves the landing page (D-20 — `wrangleapp.dev` survives in the About panel; the README should not feature it as a destination since Phase 17 is repositioning the landing page).
    - Do NOT reference `LemonSqueezy` / `Buy` / `$24` / `Trial` / `License` (except linking to `LICENSE`) — Phase 13 stripped these and they must not return through the README.

    Per REPO-02.
  </action>
  <verify>
    <automated>test -f README.md && grep -q "^# Wrangle$" README.md && grep -q "^## What this is$" README.md && grep -q "^## Why it'\''s free and open source now$" README.md && grep -q "^## Built with$" README.md && grep -q "^## Install$" README.md && grep -q "^## Build from source$" README.md && grep -q "^## Contributing$" README.md && grep -q "^## License$" README.md && grep -q "distribution is harder than product" README.md && grep -q "2026-04-22" README.md && grep -qi "reddit" README.md && grep -q "\.planning/" README.md && grep -q "screenshots/raw/editor-simple\.png" README.md && grep -q "screenshots/raw/project-overview\.png" README.md && grep -q "screenshots/raw/terminal\.png" README.md && grep -q "screenshots/raw/browser-tab\.png\|screenshots/raw/demo.gif" README.md && grep -q "\[LICENSE\](LICENSE)" README.md && grep -q "\[CONTRIBUTING\.md\](CONTRIBUTING\.md)" README.md && grep -q "github.com/J-Krush/wrangle/releases/latest" README.md && grep -q "Inline markdown rendering" README.md && grep -q "XML-in-markdown highlighting" README.md && grep -q "Fuzzy finder" README.md && ! grep -qi "lemonsqueezy\|\$24\|Buy Wrangle" README.md</automated>
  </verify>
  <acceptance_criteria>
    - `README.md` exists and starts with `# Wrangle` as its only H1.
    - All 7 mandated H2 headings present in order: `## What this is`, `## Why it's free and open source now`, `## Built with`, `## Install`, `## Build from source`, `## Contributing`, `## License`.
    - Section (c) contains the literal phrase `distribution is harder than product`.
    - Section (c) contains the date `2026-04-22`.
    - Section (c) contains a case-insensitive mention of `reddit` (Reddit ads beat per D-05).
    - Section (c) contains NO other numbers — confirmed by `grep -E '\$[0-9]+|[0-9]+%|[0-9]+x|[0-9]+ DAU|MRR\|ARR'` returning zero hits in the file as a whole except where allowed (the `2026-04-22` date, version numbers like `macOS 15`, `Swift 5.9+`, `Apple Silicon` references). Executor performs a manual visual scan during the action for any inadvertent numeric leak (PH rank, ad spend, etc.).
    - The `.planning/` directory is referenced at least once in the body (D-07 callout).
    - All 5 image assets embedded with their canonical paths (matching the actual filenames in `screenshots/raw/` — if Task 2 used different names, the embeds use those names).
    - The verbatim "Key Features" block from the current README contains at least the 7 bullet substrings: `Inline markdown rendering`, `XML-in-markdown highlighting`, `Embedded terminal`, `Token counting`, `Fuzzy finder`, `File tree with bookmarks`, `AI file recognition` (D-15 verbatim preservation).
    - File contains markdown links: `[LICENSE](LICENSE)`, `[CONTRIBUTING.md](CONTRIBUTING.md)`, and a link to `github.com/J-Krush/wrangle/releases/latest`.
    - File contains ZERO matches for any of: `LemonSqueezy`, `lemonsqueezy`, `$24`, `Buy Wrangle`, `Trial`, `trial-gated` (case-insensitive).
    - README length is 150-400 lines (sanity range — too short means missing content; too long means we kept old sections).
  </acceptance_criteria>
  <done>
    `README.md` is the public-facing portfolio piece, all 5 visuals embedded, story-section voice locked to D-01..D-05. REPO-02 satisfied; REPO-07 satisfied jointly with Tasks 1 + 2.
  </done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| User's local screen capture → repo working tree | Anything visible on the user's screen when capturing browser-tab.png / demo.gif crosses into the repo. The user is trusted to capture, but accidental on-screen secrets (Slack DMs, auth tokens in URLs, terminal output containing API keys) would leak to anonymous viewers post-flip. |
| Landing-page repo (separate git) → Wrangle repo | The three `cp` operations in Task 1 read files from a different git repo on disk. Risk: if those landing-page files have already been tampered with (e.g., contain steganographic payloads), the copy propagates them. Practical risk is negligible (user-controlled local repo), but `file` command verification confirms they are valid PNGs. |
| README story prose → public visitor | Section (c) is public-facing forever. A numeric leak (PH rank, ad spend) violates D-02 and exposes data the user wants private. |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-14-05 | Information Disclosure | screenshots/raw/browser-tab.png | mitigate | Interactive checkpoint (Task 2) requires user pre-commit visual inspection of the browser-tab capture for Slack DMs / auth-token URLs / sensitive bookmarks / personal filenames. User must explicitly approve before executor proceeds. |
| T-14-06 | Information Disclosure | screenshots/raw/demo.gif | mitigate | Same interactive checkpoint (Task 2) covers the GIF — user inspects every captured frame for sensitive content before approving. |
| T-14-07 | Information Disclosure | README.md section (c) story | mitigate | Acceptance criteria force the presence of `distribution is harder than product` (D-04) AND require the planner to perform a manual visual scan during the action for inadvertent numbers (PH rank, MRR, ad spend, conversion %). The automated grep can only catch obvious offenders; the action narrative explicitly directs the executor to read the draft top-to-bottom for D-02 compliance before committing. |
| T-14-08 | Information Disclosure | README.md residual commercial copy | mitigate | Acceptance criterion `! grep -qi "lemonsqueezy\|\$24\|Buy Wrangle"` ensures the rewrite did not re-import any Phase-13-stripped commercial language. |
| T-14-09 | Tampering | Landing-page asset copy | accept | `cp` reads from a user-controlled local repo. Risk of tampered binaries is negligible; `file` command verifies PNG validity. No supply-chain gate required. |
| T-14-SC | Tampering | Supply chain (npm/pip/cargo) | accept | This plan adds zero new package dependencies. No package-legitimacy gate required. |
</threat_model>

<verification>
After all 3 tasks complete:

```bash
# REPO-07: 3+ screenshots + 1 animated GIF, embedded in README
ls screenshots/raw/editor-simple.png screenshots/raw/project-overview.png screenshots/raw/terminal.png screenshots/raw/browser-tab.png screenshots/raw/demo.gif
grep -c "screenshots/raw/" README.md  # expect >=5

# REPO-02: 8-section structure
for h in "^# Wrangle$" "^## What this is$" "^## Why it's free and open source now$" "^## Built with$" "^## Install$" "^## Build from source$" "^## Contributing$" "^## License$"; do
  grep -q "$h" README.md || echo "MISSING: $h"
done

# Story-section locks
grep -q "distribution is harder than product" README.md
grep -q "2026-04-22" README.md
grep -qi "reddit" README.md

# .planning/ callout (D-07)
grep -q "\.planning/" README.md

# D-15 verbatim "Key Features" preservation
grep -q "Inline markdown rendering" README.md
grep -q "AI file recognition" README.md

# Forbidden commercial residue
! grep -qi "lemonsqueezy\|\$24\|Buy Wrangle\|trial-gated" README.md
```

Both `requirements` IDs (REPO-02, REPO-07) are claimed by this plan.
</verification>

<success_criteria>
- 5 image files present under `screenshots/raw/` (3 copied + 2 user-captured).
- `README.md` rewritten with 8-section structure per REPO-02; all 5 images embedded with paths matching real files; story section in D-01..D-05 voice with locked beats + locked takeaway.
- Interactive checkpoint completed — user has visually inspected both captures for sensitive content and explicitly approved.
- README contains zero residual commercial copy (`LemonSqueezy`, `$24`, `Buy`, `Trial` outside the LICENSE link).
- README's `[LICENSE](LICENSE)` and `[CONTRIBUTING.md](CONTRIBUTING.md)` links resolve to files created by Plan 14-01 (validates `depends_on: ["14-01"]`).
</success_criteria>

<output>
Create `.planning/phases/14-app-repo-oss-surface/14-02-SUMMARY.md` when done, recording: the final filenames the user picked for browser-tab + demo (in case they differed from defaults), confirmation that the user approved the captures' visual-content review, and which REPO-NN IDs are now satisfied.
</output>
