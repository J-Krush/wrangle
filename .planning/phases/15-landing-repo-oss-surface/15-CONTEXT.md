# Phase 15: Landing Repo OSS Surface - Context

**Gathered:** 2026-05-20
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 15 prepares the `J-Krush/wrangle-landing` repo (on disk at
`/Users/krush/Projects/Krush-Dev/Wrangle/Landing Page/`) to be safely flipped
public in Phase 18 — without changing the actual page copy / CTA / hero / SEO
(that's Phase 17).

Deliverables:

1. **MIT `LICENSE`** at repo root, attributed to "Copyright (c) 2026 J Krush"
   (matches Phase 14's app-repo LICENSE convention) (LAND-02).
2. **Public-facing `README.md`** rewrite — strict LAND-03 minimal: what the
   repo is, dev commands (`pnpm install` / `pnpm dev` / `pnpm build`), generic
   Vercel deploy target, top + footer links to `github.com/J-Krush/wrangle`,
   small License section at the bottom (LAND-03).
3. **Private/internal content removal** — `git rm -r .agents/` (ad-spend plan,
   community posts, product-marketing context) and `git rm scripts/send-survey.mjs`
   (LemonSqueezy + Resend customer-survey tool). Working-tree deletions only;
   history preserved (LAND-01).
4. **Dead paid-product surfaces deleted** — `src/pages/api/trial/activate.ts`,
   `src/pages/api/trial/validate.ts`, `src/pages/api/version.json.ts`,
   `src/pages/refund.astro`, `src/pages/terms.astro`. Phase 13 killed the app
   clients; these endpoints/pages have no remaining consumers (LAND-01).
5. **`.gitignore` hygiene** — `.astro/` cache directory added; the 6 currently
   tracked `.astro/*` files (`content-assets.mjs`, `content-modules.mjs`,
   `content.d.ts`, `data-store.json`, `settings.json`, `types.d.ts`)
   `git rm -r --cached`'d. Confirm `node_modules/`, `dist/`, `.env*`,
   `.DS_Store`, `.vercel` already covered (they are) (LAND-04).
6. **History audit** — `git rev-list --all | xargs git grep -i` with an
   expanded forbidden-string list (LAND-05 base + repo-specific known
   surface). Findings summarized in this CONTEXT.md (after execution: also in
   the phase SUMMARY.md). No standalone audit doc inside the repo.
7. **Verify the public-checkout story** — clone the repo to `/tmp/`, run
   `pnpm install && pnpm dev` with no `.env` file, confirm the dev server
   boots. Document the expected `RESEND_API_KEY` missing warning in the
   README's dev section (Success Criteria #4).

What Phase 15 does NOT deliver:

- **Page copy / hero / CTA / story rewrite** — Phase 17 (SITE-01..10).
- **Buy → Free messaging, download wiring, OG/SEO updates, deploy** — Phase 17.
- **Removing the `@astrojs/vercel` adapter** — kept (the kept `/api/feedback`
  route needs server execution; adapter swap is Phase 17's call if needed).
- **Removing `/api/feedback` + `src/pages/feedback.astro`** — kept (Resend env
  var only, no leak; normal landing-page feature; Phase 17 reskins copy).
- **Removing `pencil/wrangle-landing-1.pen`** — kept (encrypted at rest;
  legitimate design source artifact).
- **Filter-repo / squash history rewrite** — explicitly rejected. LemonSqueezy
  checkout URL was public; $24/$19 pricing existed publicly; no secret values
  ever committed. Preserving lineage tells the honest "shipped paid, flipped
  OSS" portfolio story.
- **Public flip itself** — Phase 18 (FLIP-03).

</domain>

<decisions>
## Implementation Decisions

### Private content disposition (LAND-01)

- **D-01:** Delete `.agents/` outright (`git rm -r .agents/`). Removes
  `ad-copy-plan.md` (Google + Reddit ad spend plan), `community-posts.md`,
  and `product-marketing-context.md`. Working-tree only; history preserved
  per D-08.

- **D-02:** Delete `scripts/send-survey.mjs` outright (`git rm
  scripts/send-survey.mjs`). LemonSqueezy customer CSV + Vercel KV trial-user
  survey tool — zero remaining use case once Phase 13 killed the trial flow
  and Phase 14/15 retire LemonSqueezy. If the `scripts/` directory goes
  empty after deletion, remove it too.

- **D-03:** Keep `src/pages/feedback.astro` + `src/pages/api/feedback.ts`.
  The Resend-backed feedback form is a normal landing-page surface; the API
  key is env-var only (no leak). Phase 17 will reskin the page copy if
  needed; Phase 15 does not touch the route.

- **D-04:** Keep `pencil/wrangle-landing-1.pen`. The Pencil design file is
  encrypted at rest and only viewable via the Pencil MCP / app. Legitimate
  design source artifact; no leak risk.

### Build-cache hygiene (LAND-04)

- **D-05:** `git rm -r --cached .astro/` to untrack the 6 currently tracked
  files (`content-assets.mjs`, `content-modules.mjs`, `content.d.ts`,
  `data-store.json`, `settings.json`, `types.d.ts`). They regenerate on every
  `pnpm dev` / `pnpm build`.

- **D-06:** Append `.astro/` to `.gitignore` so future builds don't re-track
  them. The existing `.gitignore` already covers `node_modules/`, `.env*`,
  `.DS_Store`, `dist/*`, `.vercel`, `*.pem` — confirm via grep that those are
  still intact after the edit.

### Dead paid-product surfaces (LAND-01)

- **D-07:** Delete `src/pages/api/trial/activate.ts`,
  `src/pages/api/trial/validate.ts`, and `src/pages/api/version.json.ts` in
  Phase 15. Phase 13's app-side strip (APP-01..15) and `UpdateChecker`
  repoint (D-09) leave these endpoints with zero remaining clients. Remove
  the `src/pages/api/trial/` directory if it goes empty. Aligns with Phase
  13's "strip wholesale" philosophy — no shim, no 410-Gone stub.

- **D-08:** Delete `src/pages/refund.astro` (30-day money-back paid-product
  artifact) and `src/pages/terms.astro` in Phase 15. **Scope expansion vs.
  the LAND-01..05 letter** — these are page-copy files but they reference a
  paid-product model that's gone. User explicitly chose to remove in Phase 15
  rather than defer to Phase 17, so the repo's working tree shows zero
  paid-product surface before the public flip. Phase 17 won't have these
  files to handle. If any other pages link to `/refund` or `/terms`, the
  planner identifies and updates/removes those links (likely `Layout.astro`
  footer or top-nav — to verify during planning).

### History posture (LAND-05)

- **D-09:** Preserve history as-is. No `git filter-repo`, no squash.
  Justification: history grep against `secret|api[-_]key|token|password|
  lemonsqueezy|RESEND_API|KV_REST_API` shows only env-var *name* references
  (`process.env.RESEND_API_KEY`) and the **public** LemonSqueezy checkout URL
  `https://jkrush.lemonsqueezy.com/checkout/buy/8860d1f0-c122-4ab6-8528-ee727d3065e3`.
  No secret VALUES were ever committed. The LemonSqueezy URL is the public
  buyer-facing checkout endpoint, not credentials. Old commits show $24/$19
  pricing copy, which was publicly visible on Product Hunt launch day —
  preserving lineage is honest and tells a "shipped paid, flipped OSS"
  story, which matches the portfolio thesis in PROJECT.md.

- **D-10:** Audit deliverable shape — capture the grep results inside this
  CONTEXT.md (pre-execution sanity check, see `code_context` below) and
  expand them into the phase's `15-SUMMARY.md` during execution. **No
  standalone repo-visible audit doc** (`SECRETS-AUDIT.md` etc.) — Phase 14's
  `SECURITY.md` covers responsible-disclosure messaging; an audit log inside
  the public repo is not load-bearing.

- **D-11:** Forbidden-string list for the audit — LAND-05 base
  (`secret|api[-_]key|token|plausible|fathom|posthog`) PLUS repo-specific
  surface: `lemonsqueezy|RESEND_API|KV_REST_API|hello@wrangleapp.dev|
  jkrush\.lemonsqueezy\.com`. Run on `git rev-list --all` AND the working
  tree separately. Document each surviving hit's category: (a) env-var
  *name* reference, (b) public-URL artifact, (c) historical pricing copy,
  (d) actual secret value (must be zero).

### Verification (Success Criteria #4)

- **D-12:** Verify "clean checkout boots" via a `/tmp` clone:
  ```bash
  git clone "/Users/krush/Projects/Krush-Dev/Wrangle/Landing Page" /tmp/wrangle-landing-verify
  cd /tmp/wrangle-landing-verify
  pnpm install
  pnpm dev
  ```
  Expected: dev server boots on `http://localhost:4321`, index page renders,
  the kept `/api/feedback` route logs a `RESEND_API_KEY` missing warning on
  POST attempts. The README documents this expected dev-mode warning so a
  contributor knows it's not a misconfiguration on their end. **Do NOT**
  patch `api/feedback.ts` to short-circuit (would be a code change to a
  non-Phase-15 file — option C was rejected).

- **D-13:** No `.env.example` file in Phase 15 (option B in the verify
  question was passed over). The README explains which env vars *would* be
  needed for deployed-state functionality (`RESEND_API_KEY`) and notes the
  dev server doesn't require them. If Phase 17 wants stronger contributor
  onboarding, it can introduce `.env.example` then.

### README structure (LAND-03)

- **D-14:** Strict LAND-03 minimal — 4 sections in this order:
  1. **What this is** — single paragraph: "This is the Astro source for
     [wrangleapp.dev](https://wrangleapp.dev), the marketing site for
     Wrangle. The app itself lives at
     [github.com/J-Krush/wrangle](https://github.com/J-Krush/wrangle)."
  2. **Develop** — `pnpm install` / `pnpm dev` / `pnpm build` table
     (preserve the existing `pnpm` command table from the current README —
     it's already correct). Note that the dev server runs without `.env`
     (the feedback API will warn about missing `RESEND_API_KEY`).
  3. **Deploy** — single sentence: "Deploys to Vercel; configured via
     `@astrojs/vercel`." No project IDs, no env-var instructions, no
     `vercel.json` deep-link. Just enough to orient.
  4. **See also** + **License** (combined footer block) — link back to
     `github.com/J-Krush/wrangle` and a one-line "MIT — see
     [LICENSE](./LICENSE)."

  No story snippet, no PH/Reddit narrative, no "Why OSS" section. That
  content lives in the app repo's README (REPO-02). Visitors who landed in
  the *landing* repo want to build/deploy the site; the orientation
  paragraph + footer link is enough to redirect to the product story.

- **D-15:** Link-back placement — top of README (in the "What this is"
  paragraph) AND in the "See also" footer block. Two mentions so a casual
  scroller can't miss that the *app* is the main product. (Phase 14's app
  README is the inverse — story-rich; landing repo is the lean cousin.)

- **D-16:** License section in README — one line at the bottom:
  `## License\n\nMIT — see [LICENSE](./LICENSE).` Mirrors what Phase 14's
  README will do for the app repo. GitHub auto-detects the MIT LICENSE in
  the sidebar regardless, but having a section keeps the convention
  symmetric across both repos.

### Claude's Discretion

- Exact `LICENSE` file formatting — use the canonical SPDX MIT template
  (`https://spdx.org/licenses/MIT.html` text or the GitHub-default template).
  Header line: `MIT License` followed by `Copyright (c) 2026 J Krush`.
- Exact README headings (`## What this is` vs `## About` vs `## Wrangle
  Landing Page`) — match the symmetric tone of Phase 14's app-repo README.
  Use sentence case (`## What this is`), not title case.
- Order of git operations within the phase (LICENSE add commit vs. file-delete
  commits vs. README rewrite commit) — atomic-commit conventions per GSD
  defaults. Suggested ordering: (1) deletions (private content + dead
  endpoints + cached `.astro/`); (2) `.gitignore` update; (3) LICENSE add;
  (4) README rewrite; (5) audit + verify run, results recorded in SUMMARY.
- Whether to delete the `scripts/` directory when only `send-survey.mjs`
  lives there. If `scripts/` is empty after the `git rm`, remove it (`git
  rm` removes the file but Git doesn't track empty dirs; nothing to do).
- Whether the planner produces 2 plans (per ROADMAP "expected: 2 plans —
  LICENSE+README; secrets sweep+`.gitignore`") or 1 (the deletions+audit+
  hygiene are tightly coupled; LICENSE+README is light). Either shape is
  acceptable; the work is small enough that one plan with two waves is fine.
- Whether to dry-run `git filter-repo` once locally and inspect the diff
  before locking D-09 in. The audit results in D-11 might surface something
  unexpected that flips the posture decision; planner should not assume D-09
  is irrevocable.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone requirements

- `.planning/REQUIREMENTS.md` §LAND — `LAND-01` through `LAND-05` (the 5
  requirements this phase satisfies, 1-to-1 with Phase 15).
- `.planning/ROADMAP.md` §Phase 15 — Goal, Depends-on (nothing in v1.3 —
  parallel-eligible with 13/14/16), Success Criteria (4 rows), Plans
  (expected: 2).
- `.planning/PROJECT.md` §Current Milestone v1.3 — milestone narrative;
  paragraph on "Landing-page repo OSS surface" target features.

### Prior-phase context that flows through

- `.planning/phases/13-app-de-commercialization/13-CONTEXT.md` — Phase 13
  D-09/D-10/D-11 (UpdateChecker repoint to GitHub Releases — explains why
  `src/pages/api/version.json.ts` has zero remaining clients) and the entire
  app-side trial strip (APP-01..15 — explains why `/api/trial/*` is also
  client-less). Phase 15 inherits the "strip wholesale" philosophy.
- `.planning/phases/12-section-parity-polish/12-CONTEXT.md` — code-style
  conventions (small focused files; `@MainActor` + `@Observable` where
  applicable — N/A here since this is TypeScript/Astro, not Swift, but the
  *terseness* and *no-comment* discipline carry over to the README/LICENSE
  drafts).

### Repo on disk (the actual phase 15 working surface)

- `/Users/krush/Projects/Krush-Dev/Wrangle/Landing Page/` — repo root for
  `J-Krush/wrangle-landing` (remote: `git@github.com:J-Krush/wrangle-landing.git`).
- `Landing Page/README.md` — current 30-line dev-focused README; gets
  rewritten per D-14.
- `Landing Page/.gitignore` — current ignores: `node_modules`, `.next/`,
  `/out/`, `/build`, `.DS_Store`, `*.pem`, `npm-debug.log*`, `.env*`,
  `.vercel`, `dist/*`. Add `.astro/` per D-06.
- `Landing Page/.agents/{ad-copy-plan,community-posts,product-marketing-context}.md`
  — delete per D-01.
- `Landing Page/scripts/send-survey.mjs` — delete per D-02.
- `Landing Page/src/pages/refund.astro`, `terms.astro` — delete per D-08.
- `Landing Page/src/pages/api/trial/{activate,validate}.ts` — delete per D-07.
- `Landing Page/src/pages/api/version.json.ts` — delete per D-07.
- `Landing Page/src/pages/api/feedback.ts`, `src/pages/feedback.astro` —
  KEEP per D-03.
- `Landing Page/pencil/wrangle-landing-1.pen` — KEEP per D-04.
- `Landing Page/.astro/{content-assets.mjs,content-modules.mjs,content.d.ts,
  data-store.json,settings.json,types.d.ts}` — untrack per D-05.
- `Landing Page/src/layouts/Layout.astro` — currently references "$19 one-time
  purchase" in default meta description. Planner determines whether Phase 15
  edits this (probably yes — the default `description` prop default value
  needs a non-paid-product fallback even if Phase 17 will set explicit per-page
  descriptions). Consider neutral default: "A native macOS markdown editor for
  developers."
- `Landing Page/src/data/use-cases.json` — content data for `compare/*`
  pages; Phase 15 does NOT touch (Phase 17's reposition territory).

### Templates and conventions

- Phase 14's planned `LICENSE` file (REPO-01) — copy the same MIT template
  and same "Copyright (c) 2026 J Krush" attribution into the landing repo so
  both repos render consistently.
- GitHub's default MIT LICENSE text (`https://github.com/licenses/MIT`) is
  the canonical wording; both repos use it verbatim.

### Documents to (NOT) write in this phase

- `SECURITY.md` — Phase 14 (REPO-10) — the app repo gets one; the landing
  repo does not need one (no security surface beyond Vercel-managed deploy).
- `CONTRIBUTING.md` / `.github/ISSUE_TEMPLATE/*` / `.github/PULL_REQUEST_TEMPLATE.md`
  — Phase 14 (REPO-03..06). Not the landing repo's scope.
- Standalone `SECRETS-AUDIT.md` inside the landing repo — explicitly rejected
  per D-10.
- `.env.example` — explicitly rejected per D-13 (option for Phase 17 to add).

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- **Existing `pnpm` command table in README.md** — the current README has a
  clean `| Command | Description |` table for `pnpm dev` / `pnpm build` /
  `pnpm preview`. Preserve verbatim — the writer reuses these rows under the
  new "Develop" heading.
- **`Landing Page/.gitignore`** — already covers most of what LAND-04
  requires (`.env*`, `node_modules`, `dist/*`, `.DS_Store`, `.vercel`).
  Phase 15 only adds `.astro/`. Confirm no offenders currently tracked
  beyond the `.astro/*` files identified in scout (no tracked `.env*`,
  no tracked `node_modules/*`, no tracked `dist/*` — confirmed via
  `git ls-files | grep -E '^\.env|^node_modules/|^dist/'`).

### Established Patterns

- **Atomic commits per logical change** — Phase 13's 28 commits over 3
  plans set the cadence. Phase 15 follows: one commit per logical deletion
  bundle, one for `.gitignore`, one for LICENSE, one for README, one
  documenting the audit.
- **Pre-execution grep audit** — Phase 13's APP-13 grep audit established
  the pattern (recorded surviving hits with category labels: env-var name,
  public URL, framework type, etc.). Phase 15 mirrors that pattern for
  LAND-05.
- **Atomic `git rm` for whole-directory deletions** — when removing
  `.agents/`, use `git rm -r .agents/` so the empty dir auto-drops.

### Integration Points

- **No SwiftData / no schema** — this is an Astro/TypeScript repo. The
  Swift conventions in `CLAUDE.md` don't apply. Use vanilla Markdown for
  README/LICENSE; preserve existing `.astro` / `.ts` files as-is unless
  explicitly deleted.
- **Vercel adapter (`@astrojs/vercel`)** stays in `package.json` and
  `astro.config.mjs`. Don't touch. Phase 17 owns any deploy reconfiguration.
- **History rewrite would force-push** — even though the remote is private,
  a force-push affects local clones (collaborators don't exist for this repo
  but the developer's other machines might). D-09 avoids this complication
  entirely by NOT rewriting history.

### Pre-execution grep findings (informs the audit)

Run by the discussion phase against the working tree:

- **`lemonsqueezy`**: 1 logical surface — `scripts/send-survey.mjs`
  references LemonSqueezy customer CSV ("Survey email to … LemonSqueezy
  customers" comment). Will be gone after D-02. Plus `.agents/ad-copy-plan.md`
  references LemonSqueezy thank-you redirect. Will be gone after D-01.
- **`api[-_]key`**: `process.env.RESEND_API_KEY` references inside
  `api/feedback.ts` and `scripts/send-survey.mjs`. After D-02, only the
  feedback route reference remains, which is an env-var *name* not a value.
- **`KV_REST_API_URL` / `KV_REST_API_TOKEN`**: only in `scripts/send-survey.mjs`
  (gone after D-02) and `src/pages/api/trial/*` (gone after D-07). After
  Phase 15's working-tree changes, zero hits remain.
- **`secret` / `token` / `password`**: zero working-tree hits beyond the
  above env-var name references.
- **`plausible|fathom|posthog`**: zero hits in any commit.
- **`jkrush.lemonsqueezy.com`**: appears in `.astro/data-store.json` build
  cache (a `/buy` redirect target) — gone after D-05's untrack.
- **`$24` / `$19`**: in `src/layouts/Layout.astro` default description and
  in commit history. Layout.astro: edit during Phase 15 per the canonical-refs
  note (neutralize the default description). History: preserved per D-09.

</code_context>

<specifics>
## Specific Ideas

- **LICENSE attribution is `Copyright (c) 2026 J Krush`** — exact string,
  same as Phase 14's planned LICENSE per REPO-01. Locked.
- **README orientation paragraph mentions `wrangleapp.dev` explicitly** — the
  domain is the *purpose* of the landing repo, so naming it isn't a leak; it
  is the description. Do not redact the domain from the README.
- **Layout.astro default description** — current: "A native macOS markdown
  editor for developers working with Claude Code, Gemini, and AI agents.
  Embedded terminals, smart notifications, token counting. $19 one-time."
  Suggested neutral replacement (do NOT rewrite the OSS positioning here —
  Phase 17 owns that): "A native macOS markdown editor for developers
  working with Claude Code, Gemini, and AI agents. Embedded terminals, smart
  notifications, token counting." — i.e., just drop the "$19 one-time"
  sentence. The Phase 17 SITE-05 will rewrite this comprehensively.
- **README's `pnpm` table preserved verbatim** — the current `| Command |
  Description |` table is correct; only the headings around it change.
- **README does NOT mention the trial endpoints or `/api/feedback`** —
  feedback form is a leaf page that doesn't need README documentation.
- **README development section names the expected stderr** — when running
  `pnpm dev` without `.env`, the `RESEND_API_KEY` warning is normal. One
  sentence: "The dev server runs without a `.env` file. The `/feedback`
  form POST route will warn about a missing `RESEND_API_KEY` — this is
  expected for local development."
- **`See also` section heading is `## See also`** (sentence case) followed
  by a markdown bullet linking to `J-Krush/wrangle`. Symmetric with the
  app-repo README, which will have its own `## See also` pointing back.
- **No badges in this README** (no CI badge, no version badge, no license
  badge) — the repo isn't on CI; the License section + the GitHub-rendered
  sidebar suffice.

</specifics>

<deferred>
## Deferred Ideas

- **`/api/feedback` route reskin / removal** — Phase 17. If Phase 17's
  OSS-positioned site doesn't surface a feedback CTA, the route can go.
- **`.env.example` for contributor onboarding** — Phase 17 may add it if
  the deploy/contribute story becomes more interesting after the OSS flip.
- **Hard-skip in `api/feedback.ts` when `RESEND_API_KEY` is missing** —
  rejected for Phase 15 (would be a code change to a non-Phase-15 file).
  Reconsider in Phase 17 alongside any other feedback-form changes.
- **`pencil/wrangle-landing-1.pen` removal** — kept in Phase 15; revisit
  only if a public visitor confusion case emerges (extremely unlikely).
- **`/refund` and `/terms` page replacements** — deleted in Phase 15 (D-08).
  If Phase 17 decides the OSS site needs a "Terms" page (boilerplate "as-is,
  no warranty"), Phase 17 writes a fresh one. Phase 15 doesn't reserve the
  URL.
- **`src/pages/compare/*` (5 competitor-comparison pages: cursor, ia-writer,
  obsidian, typora, vs-code) + `src/data/use-cases.json`** — Phase 15 does
  NOT touch. Phase 17 (SITE-07 "feature pages reviewed for Pro / Trial /
  Premium copy") owns the audit and reposition. Surfaced here so the planner
  knows the comparison pages are a deliberate Phase 17 carve-out.
- **`src/pages/use-cases/[slug].astro` dynamic route** — same. Phase 17.
- **`public/videos/wrangle-1.2-sizzle.mp4`** + the old `browser-feature.mp4`
  — Phase 17 (assets review for the reposition).
- **`scripts/og-image` (mentioned in SITE-05)** — Phase 17.
- **Vercel adapter swap to static** — Phase 17 if it decides to drop the
  feedback form.
- **GitHub Actions / CI** — out of milestone (deferred to v1.4 per
  REQUIREMENTS.md "Future Requirements").

### History posture revisit triggers

Reconsider D-09 (preserve history) ONLY if:
- The audit (D-11) surfaces an actual secret VALUE in any historical commit.
- A future contributor (or the user) files an issue saying the old commits
  embarrass them in a portfolio-review context.

Neither is anticipated; D-09 stands.

</deferred>

---

*Phase: 15-landing-repo-oss-surface*
*Context gathered: 2026-05-20*
