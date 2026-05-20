# Phase 14: App Repo OSS Surface - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-20
**Phase:** 14-app-repo-oss-surface
**Areas discussed:** Story narrative, `.planning/` exposure, `docs/` redaction, CONTRIBUTING + SECURITY framing, README disposition, Screenshots/GIF, Secrets sweep strategy

---

## Story narrative (REPO-02 section c)

### Q1: Voice and tone

| Option | Description | Selected |
|--------|-------------|----------|
| Matter-of-fact / portfolio-honest | Tight, no-excuses framing of the experiment | |
| Reflective / lessons-learned | Short essay framing the OSS pivot as a deliberate experiment | ✓ |
| Mission-forward / 'this was always the goal' | Reframes OSS pivot as the point, downplays failed paid funnel | |
| Brief and skip the story | 1-2 sentences with no PH/Reddit narrative | |

**User's choice:** Reflective / lessons-learned

### Q2: Story detail level (numbers vs qualitative)

| Option | Description | Selected |
|--------|-------------|----------|
| Qualitative — no concrete numbers | No PH rank, no DAU, no ad spend, no conversion % | ✓ |
| Selective numbers — one or two | Disclose the most telling metric only | |
| Full transparency — disclose key metrics | PH rank, DAU peak, revenue, ad spend, conversion | |
| You decide | Planner drafts qualitatively, flags where numbers would land | |

**User's choice:** Qualitative — no concrete numbers

### Q3: Length

| Option | Description | Selected |
|--------|-------------|----------|
| Tight — 2-3 short paragraphs | Reads in ~30 seconds, fits the launch/ads/lesson/pivot beats | ✓ |
| Medium — 4-5 paragraphs with subheadings | Separate beats, scannable, longer README | |
| Essay-length — dedicated story page linked from README | `docs/story.md` with one-paragraph README hook | |

**User's choice:** Tight — 2-3 short paragraphs

### Q4: Lesson / takeaway

| Option | Description | Selected |
|--------|-------------|----------|
| 'Distribution is harder than product' | Built a focused tool, found real audience, paid-channel proof was harder | ✓ |
| 'Niche markets need niche economics' | Paid macOS apps for narrow audience don't scale via consumer channels | |
| 'Solo-dev paid app is wrong shape' | Maintaining paid app is too much overhead for side project | |
| You decide | Planner drafts from project context | |

**User's choice:** 'Distribution is harder than product'

**Notes:** Story beats locked in 13-CONTEXT.md — PH 2026-04-22, Reddit ads channel experiment, portfolio piece pivot — flow forward unchanged.

---

## `.planning/` directory public exposure

### Q1: Public or private when repo flips?

| Option | Description | Selected |
|--------|-------------|----------|
| Keep it — transparency is a feature | 41 commits stay; `.planning/` is itself a product demo of GSD-style planning | ✓ |
| Strip from history via `git filter-repo` before flip | Cleanest public surface; rewrites tags, breaks any clones | |
| Stop tracking now, leave history alone | Add to `.gitignore` from this commit forward; past commits still visible | |
| Selective — keep PROJECT/ROADMAP/REQUIREMENTS, strip per-phase artifacts | Middle ground: high-level intent visible, working detail hidden | |

**User's choice:** Keep it — transparency is a feature

### Q2: README call-out

| Option | Description | Selected |
|--------|-------------|----------|
| Call it out explicitly | "This repo includes its own structured planning history under `.planning/`" + a pointer | ✓ |
| Leave unmentioned | Don't draw attention; people who look will find it | |
| You decide | Planner picks the right spot and treatment | |

**User's choice:** Call it out explicitly

---

## `docs/` redaction (REPO-12)

### Q1: Per-file disposition (overrides on Claude's defaults)

Defaults presented:
- Keep as-is: `architecture.md`, `coding-patterns.md`, `token-counting-research.md`
- Delete: `pre-launch-todo.md`, `.DS_Store`
- Open question: `audit-report.md`, `release-checklist.md`, `product-hunt/`
- Lean delete: `launch-strategy.md`

| Override option | Description | Selected |
|--------|-------------|----------|
| Override `audit-report.md` — don't keep | Move to .planning/ or delete instead | (overridden via freeform) |
| Override `release-checklist.md` — don't keep in docs/ | Move to .planning/ as internal-only | (overridden via freeform) |
| Override `product-hunt/` — don't delete | Keep as historical launch artifacts | (overridden via freeform) |
| Override `launch-strategy.md` — don't delete | Keep as a story artifact | (overridden via freeform) |

**User's choice (freeform):** "For all of these I want to add them to gitignore instead so that I still have them locally, but they aren't in the repo."

**Resolution:** `git rm --cached` + `.gitignore` for all four — files stay on user's local disk, leave the git index, future commits don't track. Phase 18 will decide separately whether to also rewrite history.

---

## CONTRIBUTING + SECURITY framing

### Q1: CONTRIBUTING.md voice

| Option | Description | Selected |
|--------|-------------|----------|
| Portfolio-piece / slow-maintenance | "PRs welcome but best-effort review; major architectural changes unlikely" | ✓ |
| Open-collaboration / community-friendly | Aim for week response, good-first-issue labels, mentorship welcome | |
| Minimalist / 'see issues for guidance' | Short CONTRIBUTING with just setup + PR checklist | |
| You decide | Planner picks based on story narrative tone | |

**User's choice:** Portfolio-piece / slow-maintenance

### Q2: SECURITY.md disclosure channel

| Option | Description | Selected |
|--------|-------------|----------|
| GitHub Security Advisories only | Built-in private disclosure flow, no email inbox to monitor | ✓ |
| jkrush@pm.me | Existing personal email | |
| New oss-specific email (e.g., wrangle-security@…) | Dedicated address; setup + monitoring overhead | |
| Both: GitHub Security Advisories AND email | Belt-and-suspenders; dedupe burden | |

**User's choice:** GitHub Security Advisories only

---

## README disposition

### Q1: How much of the current 13.5KB README to preserve?

| Option | Description | Selected |
|--------|-------------|----------|
| Heavy rewrite, preserve the feature list | New REPO-02 structure; keep "Key Features" bullets verbatim; drop everything else | ✓ |
| Light edit on top of current | Keep current structure, insert new sections; weaker structurally | |
| Fresh blank rewrite, no preservation | From scratch; loses well-tuned feature list | |
| You decide | Planner stitches both intelligently | |

**User's choice:** Heavy rewrite, preserve the feature list

---

## Screenshots / animated GIF (REPO-07)

### Initial framing (before user surfaced existing assets)

Original options around capture timing (during phase / defer to 14.1 / pre-execution) and storage location were rejected by user with the freeform note that the landing-page repo already has a product-image library.

**User's freeform input:** "There are a number of product photos in this directory: `/Users/krush/Projects/Krush-Dev/Wrangle/Landing Page/public/images`"

### Q1 (revised after asset discovery): Handling approach

| Option | Description | Selected |
|--------|-------------|----------|
| Copy 3 existing + checkpoint for browser tab + GIF | Copy editor-simple/project-overview/terminal from landing repo; checkpoint asks user for browser PNG + demo GIF | ✓ |
| Copy 3 existing, defer browser+GIF to 14.1 | Phase 14 ships with placeholders; 14.1 = capture pass | |
| Use editor + project-overview only, drop browser-tab requirement | Reduce REPO-07 scope to 2 screenshots; capture GIF in checkpoint | |
| You decide | Planner picks based on efficiency | |

**User's choice:** Copy 3 existing + checkpoint for browser tab + GIF

---

## Secrets sweep strategy (REPO-09)

### Q1: Pre-commit strategy or decide based on grep results?

| Option | Description | Selected |
|--------|-------------|----------|
| Run grep first, decide based on results | If clean — done. If hits — checkpoint with filter-repo vs rotate-and-document | ✓ |
| Pre-commit: filter-repo any hits | Every found secret removed from history; rewrites tags | |
| Pre-commit: rotate + document, never rewrite history | Found secret rotated, documented as known-rotated; history preserved | |

**User's choice:** Run grep first, decide based on results

---

## Claude's Discretion

Items where Claude / planner has flexibility (captured in CONTEXT.md `<decisions>` "Claude's Discretion"):

- Exact CONTRIBUTING.md wording within "portfolio-piece / slow-maintenance" framing
- Exact README hero pitch phrasing
- Exact story prose within D-01..D-05 constraints
- Exact SECURITY.md wording
- Issue template field labels + ordering within REPO-04/05 mandates
- PR template checklist exact items
- `.gitignore` patterns beyond redaction list
- README placement of `.planning/` callout (subsection / standalone / footer)
- Whether to add a public-friendly repo-root `ROADMAP.md`
- Whether copied screenshots get renamed
- File-delivery sequencing within Phase 14 plans

---

## Deferred Ideas

Captured in CONTEXT.md `<deferred>`:

- Git history rewrite for the `git rm --cached` files — Phase 18
- Public-friendly repo-root `ROADMAP.md` — optional / v1.4
- Code of Conduct (Contributor Covenant) — unless user requests
- Repo-root `CHANGELOG.md` — Phase 18 or v1.4
- GitHub Actions CI — v1.4
- Screenshots refresh after Phase 17 landing-page redesign — v1.4
- CLAUDE.md → AI-CONTRIBUTING.md split — v1.4
- `gsd-pr-branch` skill update for the `.planning/`-stays-public reality — out of scope; revisit when external PRs arrive

---

*Phase: 14-app-repo-oss-surface*
*Discussion logged: 2026-05-20*
