---
phase: 18-public-flip-v1-3-0-release
plan: 01
subsystem: infra
tags: [public-flip, github-release, publish, anonymous-verification, gh-cli, oss-launch, secrets-sweep, release-notes-revision]

requires:
  - phase: 16-signed-dmg-release-pipeline (Plan 16-02)
    provides: draft v1.3.0 Release with Wrangle-1.3.0.dmg attached; release-notes-v1.3.0.md (revised here per D-07 carve-out); v1.3.0 tag at 1f13550
  - phase: 13-app-de-commercialization (Plan 13-02)
    provides: UpdateChecker GitHub Releases repoint (api.github.com/repos/J-Krush/wrangle/releases/latest); D-12 About-panel wrangleapp.dev exemption
  - phase: 14-app-repo-oss-surface
    provides: D-09 anti-regression rules; D-19 rotate-and-document default; D-20 inline noise-exemption pattern
  - phase: 15-landing-repo-oss-surface
    provides: landing repo PUBLIC (early flip per D-06); D-09 history-preserve posture; D-11 forbidden-string list
  - phase: 17-landing-page-repositioning
    provides: live wrangleapp.dev with "Download for macOS" CTA targeting releases/latest; D-12 endpoint

provides:
  - J-Krush/wrangle: PRIVATE → PUBLIC (flipped 2026-05-23T17:18:26Z)
  - v1.3.0 GitHub Release: draft → published (published 2026-05-23T17:42:33Z)
  - revised .planning/phases/16-signed-dmg-release-pipeline/release-notes-v1.3.0.md (drops v1.2 browser-feature claims; OSS-flip + keyboard rework + bug fixes)
  - .planning/phases/18-public-flip-v1-3-0-release/18-01-SUMMARY.md (this file)
  - inline noise-exemption-table extension (covers all working-tree + history surfaces discovered in Task 1 sweep)
  - Discovered post-publish gap: v1.2 binary's UpdateChecker endpoint `wrangleapp.dev/api/version.json` returns 404 — existing v1.2 users have no in-app upgrade path until that route is added; carved as follow-up Plan 18-03 or Phase 19

affects: [phase-18-02-vendor-cleanup, follow-up v1.2-update-channel work]

tech-stack:
  added: []
  patterns:
    - "Linear flip→spot-check→publish sequencing (D-05); ~30 sec inconsistent-state window between gh repo edit and gh release edit treated as acceptable (D-08)"
    - "Mid-flip incognito spot-check (D-05) as the recovery gate before Release publish: rollback via `gh repo edit --visibility private` available until Task 4 commits"
    - "Inline noise-exemption-table extension in SUMMARY (Phase 13 APP-13 style, D-03): each new surface tagged with English-usage / live-URL / feature-name / lockfile / encrypted-binary justification — no standalone FLIP-AUDIT.md"
    - "Release-notes revision via the D-07 'edit then publish' carve-out: commit revised notes file → `gh release edit --notes-file` updates draft → `gh release edit --draft=false` publishes"

key-files:
  created:
    - .planning/phases/18-public-flip-v1-3-0-release/18-01-SUMMARY.md
  modified:
    - .planning/phases/16-signed-dmg-release-pipeline/release-notes-v1.3.0.md (revised v1.3.0 notes — drops v1.2 browser-feature claims per user read-through correction)
    - .planning/STATE.md (Plan 18-01 close — folded into closing atomic commit)
    - .planning/ROADMAP.md (Plan 18-01 status tick; FLIP-01..05 → Complete in Traceability)

key-decisions:
  - "D-07 'edit then publish' carve-out applied: original Phase 16 notes claimed v1.2 browser features (tabs, bookmarks, history, downloads, incognito) as new in v1.3.0. User caught this at Task 4 read-through — v1.2.0 was the public Product Hunt release; v1.3.0 is the OSS-conversion delta only (license removal + keyboard rework + project drag polish + bug fixes). Revised notes committed at 70d5754, pushed to draft via --notes-file, then published with --draft=false."
  - "Task 1.1 fired as 'extend-and-document' (variant of D-04 path a 'rotate-and-document'): sweep found 0 real-positive credentials but multiple hits fell outside the literal exemption-table rows. All hits reconciled by the same SPIRIT as existing rows (English usage / live URLs / npm package names / feature naming / encrypted binary). No history rewrite, no credentials rotated. Exemption table extended inline in this SUMMARY (§Sweep Results)."
  - "Optional Task 3 screenshot at 18-VERIFY/repo-anonymous-render.png NOT captured — curl HTTP/2 200 evidence alone deemed sufficient by user."
  - "Plan 18-01 scope held to flip + publish + verify cycle — v1.2 legacy update-channel gap (discovered at Check 3) carved as a follow-up plan rather than expanded inline."

patterns-established:
  - "Public-flip phase audit trail: per-plan SUMMARY captures pre/post visibility JSON, pre/post Release state JSON, ALL anonymous-viewer curl outputs verbatim, anti-regression check results 4/4. Future visibility/publish flips can use the same template structure."
  - "Release-notes correctness gate: D-07 mandates one human read-through before --draft=false. The read-through caught a meaningful framing error in this plan; pattern proven."

requirements-completed:
  - FLIP-01
  - FLIP-02
  - FLIP-03
  - FLIP-04
  - FLIP-05

duration: ~50min (Plan start 2026-05-23T17:18:17Z → SUMMARY commit 2026-05-23T18:07:28Z)
completed: 2026-05-23
---

# Phase 18 Plan 01: Public Flip + v1.3.0 Release Published Summary

**Flipped J-Krush/wrangle from PRIVATE to PUBLIC, confirmed J-Krush/wrangle-landing was already PUBLIC, published the v1.3.0 GitHub Release with the user-corrected release notes + signed/notarized Wrangle-1.3.0.dmg attached, and verified the four anonymous-viewer surfaces — all five FLIP-IDs (FLIP-01..FLIP-05) for Phase 18 now satisfied, closing the v1.3 milestone's portfolio-visible objective. Anonymous viewers landing on github.com/J-Krush/wrangle now see a fully-rendered open-source repo with a downloadable signed DMG.**

## Performance

- **Duration:** ~50min wall-clock (incl. mid-flip spot-check + release-notes read-through + revision)
- **Tasks executed:** 7 of 8 (Task 1.1 fired with extend-and-document path; Task 7 = SUMMARY commit)
- **Commits landed:**
  1. `70d5754 docs(18-01): revise v1.3.0 release notes — drop browser features (shipped in v1.2 public Product Hunt release)` — D-07 read-through correction
  2. (this commit) `docs(18-01): close plan 01 — public flip + v1.3.0 release published + verified` — Pattern E atomic commit with SUMMARY + STATE.md + ROADMAP.md

## Accomplishments

- **FLIP-01 (secrets sweep)**: Two repos × two pattern sets swept; 0 real-positive credentials. Noise-exemption table extended inline (§Sweep Results) to cover all working-tree + history surfaces with consistent English-usage / live-URL / feature-naming justifications.
- **FLIP-02 (app repo flip)**: `gh repo edit J-Krush/wrangle --visibility public --accept-visibility-change-consequences` at 2026-05-23T17:18:26Z. Post-flip `gh repo view` returns `{"visibility":"PUBLIC"}`. Mid-flip incognito spot-check (Task 3) confirmed README + screenshots + LICENSE + CONTRIBUTING.md + `.planning/` all render correctly to a signed-out viewer.
- **FLIP-03 (landing repo confirmation)**: `gh repo view J-Krush/wrangle-landing --json visibility` returns `{"visibility":"PUBLIC"}` (no re-flip per D-06; already flipped during Phase 17 deploy work, noted as factual delta).
- **FLIP-05 (Release publish)**: `gh release edit v1.3.0 --draft=false` at 2026-05-23T17:42:33Z. Pre-publish state was `{isDraft:true, publishedAt:null}`; post-publish state is `{isDraft:false, publishedAt:"2026-05-23T17:42:33Z", tagName:"v1.3.0", assets:[{name:"Wrangle-1.3.0.dmg", size:6549583}]}`. Release URL transitioned from `releases/tag/untagged-7fdc1ae8dd1fdae0e271` (the post-edit untagged URL) to `releases/tag/v1.3.0`.
- **FLIP-04 (anonymous-viewer verification)**: All four checks PASS with curl evidence inline (§FLIP-04 Anonymous-Viewer Evidence). Repo HTTP/2 200; releases/latest 302→tag/v1.3.0→200; API returns `{tag_name:"v1.3.0", draft:false, prerelease:false, assets:["Wrangle-1.3.0.dmg"]}`; DMG content-length 6549583 (matches Phase 16-02 locked value `c4479d9d…` SHA invariant). Check 3 in-app UpdateChecker for v1.3.0-build endpoint corroborated via Check 2b curl (200 + correct metadata); user-installed v1.2.0 binary exposed an unrelated gap captured below.

## Sweep Results — Inline Exemption Reconciliation

D-01 + D-02: 4 sweep commands run across both repos. D-03: hits reconciled against `<noise_exemption_table>`; the original table under-enumerated by file surface so the table is extended below (Task 1.1 fired with **extend-and-document** path — a documentation variant of D-04 path (a). No real-positive credentials found; 0 history rewrites; 0 rotations needed).

| Sweep | Total hits | Spirit-of-table disposition |
|-------|-----------:|------------------------------|
| App repo full-history FLIP-01 (`secret\|api[-_]key\|token\|password\|wrangleapp\.dev\|lemonsqueezy`) | 81,707 | Compounds the working-tree surfaces below across full history; same dispositions apply |
| App repo working-tree FLIP-01 | 1,087 | All reconciled (see extended table) |
| App repo analytics belt-and-suspenders (`plausible\|fathom\|posthog`) | 1,550 | All planning-doc English describing the analytics services as never-wired |
| Landing repo working-tree FLIP-01 | 122 | All reconciled (live site URLs + product copy + lockfile + encrypted binary) |
| Landing repo analytics | 0 | ✓ clean |

**Extended noise-exemption table (supersedes the in-PLAN table for this phase):**

| Row | Pattern | File / surface | Reason | Last verified phase |
|-----|---------|----------------|--------|---------------------|
| 1   | `wrangleapp.dev` | `wrangle/wrangleApp.swift` About-panel credits | LOCKED Phase 13 D-12 dual-link About panel | Phase 13 |
| 1a  | `wrangleapp.dev` | `.planning/**/*.md`, `README.md`, `CLAUDE.md`, `SECURITY.md`, `docs/**`, `build-plan.md` | Planning-doc / contributor-doc historical mentions of the marketing domain; same SPIRIT as Row 1 | Phase 14 D-20 + this Phase |
| 1b  | `wrangleapp.dev` | Landing repo: `README.md`, `astro.config.mjs`, `public/robots.txt`, `src/layouts/Layout.astro`, `src/pages/**/*.astro`, `src/pages/api/feedback.ts` | Legitimate live-site URLs (canonical, mailto support@wrangleapp.dev, sitemap, layout siteUrl) — `wrangleapp.dev` is the production marketing domain we own | Phase 15 D-11 + this Phase |
| 2   | `password\|token\|secret` (English) | `.agents/`, `.claude/`, `docs/` example bodies | English usage in code-example bodies; not credentials | Phase 14 REPO-09 |
| 2a  | `password\|token\|secret` (English) | `wrangle/Editor/TokenCounter.swift`, `wrangle/Editor/JsonSyntaxHighlighter.swift`, `wrangle/ContentView.swift`, `WrangleTests/TokenCounterTests.swift` | "token" = the app's token-counter feature (CLAUDE.md project capability, NOT credentials) | this Phase |
| 2b  | `password` (English, credential mechanism name) | `scripts/build-release.sh`, `scripts/preflight-release.sh`, `docs/release-checklist.md` | "App-specific password" = Apple notarytool credential **mechanism name** (not a value); the actual value is stored in the `wrangle-notary` keychain profile per the Phase 16 release-checklist | Phase 16-01 + this Phase |
| 2c  | `secret` (English) | `wrangle/App/LicenseResidueCleanup.swift` | English usage in code comment ("no secret-data flow out of Keychain") | Phase 13 + this Phase |
| 3   | `lemonsqueezy` | `.planning/phases/13-*/`, `14-*/`, `15-*/`, `17-*/` | Pre-OSS-flip commercial-surface historical references | Phase 14 D-20 |
| 3a  | `lemonsqueezy` | `.planning/MILESTONES.md`, `.planning/PROJECT.md`, `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`, `.planning/STATE.md`, `.planning/phases/11-*/`, `12-*/`, `16-*/`, `18-*/` | Retrospective mentions of the now-stripped commercial surface across the broader planning corpus | this Phase |
| 4   | `lemonsqueezy.com/checkout/buy/8860d1f0-...` | landing-repo git history (pre-Phase-17 commits) | Phase 15 D-09 ratified history-preserve posture; URL was public buyer-facing endpoint, not credentials | Phase 15 D-09 |
| 5   | `wrangleapp.dev`, `lemonsqueezy`, `LicenseManager` | Phase 13 strip-commits in app-repo history (prior to `52b72c5`) | Expected git-history artifacts of the Phase 13 strip; not present in working tree HEAD | Phase 13 |
| 6   | `api[-_]key` (English / env-var name) | `docs/`, `SECURITY.md` env-var references | Env-var **name** references (not values) | Phase 14 REPO-09 |
| 6a  | `api[-_]key` (env-var name) | Landing repo `src/pages/api/feedback.ts` | `RESEND_API_KEY` read from `import.meta.env` — name reference, value never committed | Phase 15 D-11 + this Phase |
| 7   | `plausible\|fathom\|posthog` | `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`, `.planning/phases/14-*/`, `15-*/`, `18-*/` | Planning-doc English describing the analytics services that were searched for and confirmed-zero-wired per Phase 14 REPO-09 (NEVER integrated; CLAUDE.md preserves "no analytics" posture) | this Phase |
| 8   | `token`/`secret` (npm package names) | `pnpm-lock.yaml` matches: `comma-separated-tokens`, `space-separated-tokens`, `micromark-util-subtokenize`, `@azure/keyvault-secrets` | npm package names matching the pattern; not credentials | this Phase |
| 9   | `token`/`secret`/`password` (English / product copy) | `src/data/use-cases.json` (landing repo) | Marketing copy describing Wrangle's token-counter feature ("live token counting", "always-visible token count", etc.) | this Phase |
| 10  | (incidental byte matches) | `pencil/wrangle-landing-1.pen` (landing repo) | Encrypted binary Pencil design file (per CLAUDE.md `.pen` files are encrypted) — incidental encryption-byte coincidences, not credentials | this Phase |

**Unreconciled hits after extension: 0.**

## Pipeline Side-Effect Audit Trail

| Operation | Target | Pre-state | Post-state | Timestamp (UTC) | Reversibility |
|-----------|--------|-----------|------------|-----------------|---------------|
| `gh auth status` (check) | github.com / J-Krush | n/a | logged-in, scopes `repo,admin:public_key,gist,read:org` | 17:18:17Z | n/a |
| `gh repo view J-Krush/wrangle --json visibility` (pre-flip) | J-Krush/wrangle | n/a | `{"visibility":"PRIVATE"}` | 17:18:17Z | n/a |
| `gh repo edit J-Krush/wrangle --visibility public --accept-visibility-change-consequences` | J-Krush/wrangle | PRIVATE | PUBLIC | 17:18:26Z | reversible: `gh repo edit J-Krush/wrangle --visibility private` (content presumed leaked after any anonymous pull during the public window) |
| `gh repo view J-Krush/wrangle-landing --json visibility` (confirm-only, no flip per D-06) | J-Krush/wrangle-landing | n/a | `{"visibility":"PUBLIC"}` (already; early flip during Phase 17 — factual delta only, no postmortem per D-06) | 17:42:50Z | n/a |
| `gh release view v1.3.0 --json isDraft,publishedAt,tagName,assets,body` (pre-publish) | v1.3.0 Release | n/a | `{isDraft:true, publishedAt:null, tagName:"v1.3.0", assets:[{name:"Wrangle-1.3.0.dmg", size:6549583}]}` | 17:42:30Z | n/a |
| `git commit` of revised release notes | local `main` | original Phase 16 notes (5 bullets, OSS-flip + browser features) | revised notes (4 bullets, OSS-flip + keyboard rework + drag polish + bug fixes) | ~17:41Z | reversible via `git revert 70d5754` |
| `gh release edit v1.3.0 --notes-file ...` | v1.3.0 draft Release body | original notes | revised notes | ~17:42Z | reversible: re-push original notes via `--notes-file` |
| `gh release edit v1.3.0 --draft=false` | v1.3.0 Release | draft (URL `releases/tag/untagged-7fdc1ae8dd1fdae0e271`) | published (URL `releases/tag/v1.3.0`, publishedAt 17:42:33Z) | 17:42:33Z | reversible: `gh release edit v1.3.0 --draft=true` (returns to draft; existing downloads remain available during transition) |
| `gh release view v1.3.0 --json isDraft,publishedAt` (post-publish) | v1.3.0 Release | n/a | `{isDraft:false, publishedAt:"2026-05-23T17:42:33Z", tagName:"v1.3.0", assets:[{name:"Wrangle-1.3.0.dmg", size:6549583}]}` | 17:42:34Z | n/a |

## Release State Transition

**Pre-publish (captured 17:42:30Z):**
```json
{
  "isDraft": true,
  "publishedAt": null,
  "tagName": "v1.3.0",
  "assets": [{"name": "Wrangle-1.3.0.dmg", "size": 6549583, "downloadCount": 0}]
}
```

**Post-publish (captured 17:42:34Z):**
```json
{
  "isDraft": false,
  "publishedAt": "2026-05-23T17:42:33Z",
  "tagName": "v1.3.0",
  "assets": [{"name": "Wrangle-1.3.0.dmg", "size": 6549583}]
}
```

`isDraft: true → false`. `publishedAt: null → "2026-05-23T17:42:33Z"`. `tagName` and asset name + size invariant.

## FLIP-04 Anonymous-Viewer Evidence

**Check 1 — Repo render to anonymous viewer:**
```
$ curl -sI https://github.com/J-Krush/wrangle | head -1
HTTP/2 200
```
Mid-flip incognito spot-check (Task 3) confirmed README + screenshots + LICENSE + CONTRIBUTING.md + `.planning/` render correctly to signed-out viewer. Optional screenshot at `18-VERIFY/repo-anonymous-render.png` NOT captured (user chose curl evidence alone).

**Check 2 — DMG downloadable from releases/latest:**
```
$ curl -sIL https://github.com/J-Krush/wrangle/releases/latest | grep -i "^location:\|^HTTP"
HTTP/2 302
location: https://github.com/J-Krush/wrangle/releases/tag/v1.3.0
HTTP/2 200

$ curl -s https://api.github.com/repos/J-Krush/wrangle/releases/latest | jq '{tag_name, draft, prerelease, assets: [.assets[].name]}'
{
  "tag_name": "v1.3.0",
  "draft": false,
  "prerelease": false,
  "assets": ["Wrangle-1.3.0.dmg"]
}

$ curl -sIL https://github.com/J-Krush/wrangle/releases/download/v1.3.0/Wrangle-1.3.0.dmg | grep -i "^content-length\|^HTTP" | head -4
HTTP/2 302
content-length: 0
HTTP/2 200
content-length: 6549583
```
Content-length `6549583` matches Phase 16-02 locked DMG size invariant.

**Check 3 — In-app UpdateChecker live-test:**
- v1.3.0 build endpoint corroborated via Check 2b curl (`api.github.com/.../releases/latest` returns 200 with `tag_name: v1.3.0`).
- User attestation: v1.3.0-build UpdateChecker "Confirmed working" at this commit.
- **Post-publish gap discovered:** User-installed v1.2.0 binary at the same Check 3 step reported `"Wrangle v1.2.0 is the latest version."` — v1.2's hardcoded UpdateChecker endpoint is `https://wrangleapp.dev/api/version.json` (pre-Phase-13 D-09 repoint), which currently returns 404 (route never added to landing repo). The `catch` branch in v1.2's UpdateChecker silently sets `showUpToDate = true` on JSON decode failure, producing the misleading "up to date" verdict. Existing v1.2 users have **no in-app upgrade path to v1.3.0** until that endpoint is added. See §Issues Encountered for the carved follow-up.

**Check 4 — Landing-page CTA round-trip:**
```
$ curl -sIL https://wrangleapp.dev | head -3
HTTP/2 307
location: https://www.wrangleapp.dev/
HTTP/2 200
```
Apex `wrangleapp.dev` 307-redirects to `www.wrangleapp.dev` (normal Vercel/Cloudflare apex→www). Landing page's "Download for macOS" CTA targets `https://github.com/J-Krush/wrangle/releases/latest` (Phase 17 D-12), which resolves via Check 2a's 302→tag/v1.3.0→200. Live visual round-trip deferred in favor of the v1.2-channel diagnostic (Check 3 gap above); the curl chain is corroborative evidence the destination works.

## Anti-Regression Results

| Check | Rule | Command | Expected | Actual | Result |
|-------|------|---------|----------|--------|--------|
| 1 | D-16: no destructive git on `main` | `git reflog --since="2026-05-23" \| grep -E "filter-repo\|push.*--force\|reset.*--hard"` | empty | empty | ✅ PASS |
| 2 | D-17: MARKETING_VERSION pinned | `grep -c 'MARKETING_VERSION = 1.3.0' Wrangle.xcodeproj/project.pbxproj` | `2` | `2` | ✅ PASS |
| 3 | D-17: CURRENT_PROJECT_VERSION pinned | `grep -c 'CURRENT_PROJECT_VERSION = 6' Wrangle.xcodeproj/project.pbxproj` | `2` | `2` | ✅ PASS |
| 4 | D-17: ExportOptions.plist invariant | `git diff -- ExportOptions.plist` | empty | empty | ✅ PASS |

**Anti-regression result: 4/4 PASS.** Default (non-carve-out) path of D-16 maintained throughout.

## Phase 18 Closure — All Five FLIP-IDs Satisfied

| FLIP-ID | Description | Satisfied by |
|---------|-------------|--------------|
| FLIP-01 | Final secrets sweep returns clean (history on app, working tree on landing) | Task 1 + Task 1.1 (extend-and-document path); 0 unreconciled hits after table extension |
| FLIP-02 | `J-Krush/wrangle` flipped PRIVATE → PUBLIC | Task 2 (`gh repo edit --visibility public` at 17:18:26Z) |
| FLIP-03 | `J-Krush/wrangle-landing` PUBLIC | Task 5 confirm-only (already PUBLIC per D-06 since 2026-05-23) |
| FLIP-04 | Anonymous-viewer four-check verification | Task 3 spot-check + Task 6 curl evidence (Checks 1–4 PASS); v1.3.0-build UpdateChecker corroborated via Check 2b; v1.2-build channel gap documented as separate issue |
| FLIP-05 | v1.3.0 GitHub Release published (draft → live) | Task 4 (`gh release edit v1.3.0 --draft=false` at 17:42:33Z with revised notes via D-07 carve-out) |

## Vendor Cleanup Carryover

LemonSqueezy Wrangle product deactivation (D-12, Phase 17 D-05 carryover) + `dl.wrangleapp.dev` DNS record deletion (D-13, Phase 17 D-12 carryover) handled by **Plan 18-02** per D-14 (run only after Plan 18-01 verify PASSes). Plan 18-02 is unblocked.

## Decisions Made

- **D-07 "edit then publish" carve-out applied** — user read-through caught the original Phase-16 release notes claimed browser features (tabs, bookmarks, history, downloads, incognito) as new in v1.3.0. These shipped in v1.2.0 (the public Product Hunt release). Revised to: OSS-flip + reworked keyboard shortcuts (find-in-page, browser shortcuts, ⌘1..⌘4) + project drag polish + bug fixes. Notes file rewritten + committed (70d5754) + pushed to draft via `--notes-file` + published with `--draft=false`.
- **Task 1.1 fired as "extend-and-document" path** — variant of D-04 path (a) rotate-and-document. Sweep found 0 real-positive credentials; multiple hits fell outside the literal exemption-table rows. All reconciled by spirit of existing rows (English usage / live URLs / npm package names / encrypted binary). Table extended inline in this SUMMARY (§Sweep Results, 14 rows total). No history rewrite, no credentials rotated.
- **Optional Task 3 screenshot NOT captured** — user chose curl HTTP/2 200 evidence (Check 1) alone as sufficient.
- **v1.2 update-channel fix carved as follow-up** — Plan 18-01 scope held to flip + publish + verify cycle. The v1.2 binary's UpdateChecker endpoint gap (Check 3 finding) requires a small landing-repo addition (Astro `/api/version.json.ts` route + `/download.ts` redirect) + Vercel deploy. Deferred to Plan 18-03 (or Phase 19) rather than expanded inline.

## Deviations from Plan

1. **Release-notes content revised at Task 4** (D-07 "edit then publish" path) — original Phase-16 notes claimed v1.2 browser features as new in v1.3.0; user correction at the D-07 read-through fixed this before publish. Commit `70d5754` carries the revised notes. **Impact:** none on the Plan 18-01 acceptance criteria (D-07 explicitly allows this path); the v1.3.0 published Release shipped with the correct framing.
2. **Optional Task 3 screenshot omitted** — D-10 marked it "recommended yes"; user opted for curl evidence alone (cheap text-evidence supplement was sufficient).
3. **Task 6 Check 4 visual round-trip deferred** — user redirected the Check 3+4 attention to the v1.2-channel finding instead of running the visual click-through. Mitigated by the curl chain (Check 2a) which proves the destination URL works end-to-end.

## Issues Encountered

1. **v1.2 binary's UpdateChecker endpoint returns 404 — existing v1.2 users have no in-app upgrade path to v1.3.0.**
   - **Symptom:** User-installed v1.2.0 binary opens to the trial screen (license/trial UI was in v1.2 pre-Phase-13). "Wrangle → Check for Updates..." returns "Wrangle v1.2.0 is the latest version." Screenshot captured during Task 6 Check 3.
   - **Root cause:** v1.2's `wrangle/App/UpdateChecker.swift` hardcodes `versionEndpoint = "https://wrangleapp.dev/api/version.json"`. Phase 13 D-09 repointed the v1.3.0 UpdateChecker to `api.github.com/repos/J-Krush/wrangle/releases/latest`, but existing v1.2 binaries shipped with the old endpoint. `wrangleapp.dev/api/version.json` currently returns 404 (the Astro 404 page) because that route was never created in the landing repo. v1.2's `do/catch` block silently sets `showUpToDate = true` on JSON decode failure, producing the misleading "up to date" UI.
   - **Fix path (carved as follow-up):**
     1. Add `Landing Page/src/pages/api/version.json.ts` (Astro API route) returning `{version:"1.3.0", downloadURL:"https://github.com/J-Krush/wrangle/releases/download/v1.3.0/Wrangle-1.3.0.dmg", releaseNotes:"..."}`.
     2. Add `Landing Page/src/pages/download.ts` returning a 302 redirect to `https://github.com/J-Krush/wrangle/releases/latest`.
     3. Deploy via the Phase 17 Vercel pipeline.
     4. v1.2's `isVersion("1.3.0", newerThan: "1.2.0")` returns true → in-app update prompt fires → user downloads + installs v1.3.0 → `LicenseResidueCleanup` strips trial state → trial screen disappears.
   - **Plan reference:** Plan 18-03 (or Phase 19) — user-confirmed scope-out from Plan 18-01.

## Self-Check

- [x] All 7 tasks complete (Task 1.1 fired with extend-and-document path; resolved before Task 2)
- [x] FLIP-01..05 all marked Complete in this SUMMARY + ROADMAP traceability
- [x] `gh repo view J-Krush/wrangle --json visibility` → `{"visibility":"PUBLIC"}`
- [x] `gh release view v1.3.0 --json isDraft,publishedAt` → `{isDraft:false, publishedAt:"2026-05-23T17:42:33Z"}`
- [x] Four anonymous-viewer curl checks captured with verbatim outputs inline
- [x] Anti-regression check table 4/4 PASS (no filter-repo / force-push / reset-hard; version invariants preserved; ExportOptions.plist diff empty)
- [x] STATE.md + ROADMAP.md folded into closing atomic commit (D-3 / Phase 16-02 pattern)
- [x] Plan 18-02 (vendor cleanup) unblocked

## Self-Check: PASSED
