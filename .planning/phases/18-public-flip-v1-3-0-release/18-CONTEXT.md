# Phase 18: Public Flip + v1.3.0 Release - Context

**Gathered:** 2026-05-23
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 18 is the small, irreversible final step of the v1.3 milestone. It does five things and no more:

1. A final secrets sweep across both repos (FLIP-01) — `secret|api[-_]key|token|password|wrangleapp.dev|lemonsqueezy` pattern set, full git history on `J-Krush/wrangle` and working-tree on `J-Krush/wrangle-landing`.
2. Flip `J-Krush/wrangle` from PRIVATE → PUBLIC (FLIP-02). Brief incognito-browser spot-check before proceeding.
3. Confirm `J-Krush/wrangle-landing` is PUBLIC (FLIP-03 — already satisfied; the repo flipped early during Phase 17 deploy work). No re-flip; one `gh repo view` check and a note in SUMMARY.
4. Publish the existing `v1.3.0` GitHub Release: draft → live (FLIP-05). Uses the already-attached `Wrangle-1.3.0.dmg` and the already-authored `release-notes-v1.3.0.md`.
5. Anonymous-viewer end-to-end verification (FLIP-04): signed-out browser sees the repo page render, can download the DMG, the in-app UpdateChecker returns 200 with v1.3.0, and the live `wrangleapp.dev` "Download for macOS" CTA round-trips to the published Release.

Post-flip housekeeping (after verification PASSes, not gating it): LemonSqueezy Wrangle-product deactivation (Phase 17 D-05 carryover) + `dl.wrangleapp.dev` DNS record deletion (Phase 17 D-12 carryover).

What Phase 18 does NOT deliver:

- **Any code changes to the app or landing site.** No new commits to either repo's working tree (besides the `.planning/` artifacts for this phase, which live in the app repo). Phase 13–17 already delivered every code surface this milestone needs.
- **DMG rebuild or re-notarization.** Phase 16 produced the signed/notarized/stapled DMG (SHA `c4479d9df030c8b2292c258d2a1a6c9b2798a21f7f030dbfe6934b836c84fe27`) and it's already attached to the draft Release. Phase 18 only publishes.
- **Release notes rewrite.** `release-notes-v1.3.0.md` was authored in Phase 16 (5 bullets, OSS-flip leading + v1.2 browser features, macOS 15 + Sequoia + Apple Silicon). One human read-through before `gh release edit --draft=false`; edits only if the user explicitly flags something.
- **Git history rewrite.** D-09 anti-regression stands: no `git filter-repo`, no `git push --force`, no `git reset --hard`. If a true secret surfaces in the sweep, the interactive checkpoint may carve a D-09 exception, but the default is rotate-and-document (Phase 14 D-19).
- **Announcement / social / Product Hunt v2 / sponsorship surfaces.** None of these are in REQUIREMENTS.md and the project posture has explicitly held them out of v1.3 (PROJECT.md "Out of Scope"). Phase 18 is silent — the flip itself is the launch.
- **GitHub Actions / release automation.** Deferred to v1.4 (Phase 16 D-01 reaffirmed).
- **Second-Mac re-verify.** Phase 16 D-05 already provided REL-06 attestation on a MacBook Pro M1 Pro running macOS Sequoia 15.6.1. The DMG hasn't changed; no second-Mac re-test needed for FLIP.
- **Investigating exactly when/how the landing repo flipped public earlier than the planned Phase 18 step.** Noted as a delta, not a blocker.

</domain>

<decisions>
## Implementation Decisions

### Secrets sweep — depth, noise, recovery (FLIP-01)

- **D-01:** Sweep depth is **full git history on `J-Krush/wrangle`** (literal ROADMAP success-criteria #1 text — `git rev-list --all | xargs git grep -i 'secret\|api[-_]key\|token\|password\|wrangleapp\.dev\|lemonsqueezy'`) **and working-tree only on `J-Krush/wrangle-landing`** (Phase 15 D-09 already audited the landing-repo history and ratified it; repo is already public; a working-tree-only re-grep catches anything added during Phase 17 deploys 2026-05-20 → 2026-05-23).

- **D-02:** Pattern set is the FLIP-01 literal: `secret|api[-_]key|token|password|wrangleapp.dev|lemonsqueezy`. No expansion. Phase 14 REPO-09 added analytics keys (`plausible|fathom|posthog`) — those were never wired in either repo, but the planner may grep them as a belt-and-suspenders pass; zero hits expected.

- **D-03:** Noise / exemption handling is **inline in the plan + SUMMARY**, Phase 13 APP-13 style. Enumerate each known surface — About-panel `wrangleapp.dev` (Phase 13 D-12 LOCKED), `.agents/` and `.claude/` skill reference files using `password`/`token`/`secret` as legitimate English in code-example bodies, planning-doc historical references to `lemonsqueezy` in `.planning/phases/13-*` / `15-*`, the Phase 13 strip commits that show LicenseManager/wrangleapp.dev/lemonsqueezy in history but not in working tree, the `https://jkrush.lemonsqueezy.com/checkout/buy/8860d1f0-...` URL in landing-repo history (Phase 15 D-09 ratified). Sweep output minus the exemption list must be empty. No standalone `FLIP-AUDIT.md` (Phase 15 D-10 — audit logs inside the public repo are not load-bearing).

- **D-04:** Recovery posture on a real positive is **interactive stop-and-ask checkpoint**, Phase 14 D-19 pattern. If a hit is genuine (not on the exemption list), execution halts; the executor surfaces the hit (file + commit + literal match) and asks: (a) rotate-the-credential-only + document as "known-rotated" in SUMMARY (default — preserves D-09), or (b) `git filter-repo` with explicit D-09 carve-out (rewrites history, breaks any existing clones, only justified for an unrotatable / high-blast-radius secret). Decision logged before continuing.

### Flip & publish sequencing (FLIP-02, FLIP-03, FLIP-05)

- **D-05:** Sequencing is linear: secrets sweep → app-repo flip → **mid-flip incognito spot-check** → Release publish → end-to-end anonymous-viewer verification → post-flip vendor cleanup. The mid-flip pause is an interactive checkpoint after `gh repo edit J-Krush/wrangle --visibility public`: user opens the public repo URL in a logged-out browser (Cmd+Shift+N), confirms README renders + screenshots load + LICENSE shows "MIT" + `.planning/` is visible + nothing looks broken; then we proceed to publish. ~30 sec pause; lets us re-private quickly if the render is wrong instead of compounding into a published Release on a broken-looking repo.

- **D-06:** Landing-repo treatment: `gh repo view J-Krush/wrangle-landing --json visibility` returns `PUBLIC` as of 2026-05-23 — **FLIP-03 is already satisfied**. Phase 18's Plan only confirms via `gh repo view` and notes the unexpected early flip in SUMMARY. No re-flip; no investigation into when/how it flipped (likely Phase 17 deploy work). No code changes to the landing repo as part of Phase 18.

- **D-07:** Release publish is `gh release edit v1.3.0 --draft=false --repo J-Krush/wrangle`. Uses the existing tag (`1f135507f63d852e2d2d1cb6649edc36350aa5dc`), the existing attached asset (`Wrangle-1.3.0.dmg`, 7.2 MB, SHA `c4479d9d…`), and the existing notes file (`release-notes-v1.3.0.md`). One human read-through of the notes file before publishing — if the user wants an edit, it commits + amends via `gh release edit --notes-file …`; otherwise zero changes. Expected: the draft URL `releases/tag/untagged-a12004e1af184cd154ed` becomes `releases/tag/v1.3.0`, and `releases/latest` API starts returning 200 with v1.3.0 metadata.

- **D-08:** No atomic-feeling "flip + publish in one command" attempt. The two `gh` operations stay separate so the mid-flip pause can sit between them (D-05). Practically, the inconsistent-state window — repo public but Release still draft — lasts the ~30 sec of the spot-check. During that window, the repo page renders correctly but `releases/latest` still 404s (D-10 LOCKED Phase 13 behavior). This is acceptable: any anonymous visitor arriving in those 30 sec sees a public repo with no Release yet, which is a normal GitHub state.

### Anonymous-viewer verification (FLIP-04)

- **D-09:** Verification surface is **four checks**:
  1. **Repo page renders signed-out** — incognito visit to `https://github.com/J-Krush/wrangle`; README displays with embedded screenshots, MIT LICENSE badge appears in the right sidebar, `CONTRIBUTING.md` accessible, `.planning/` directory visible and browseable.
  2. **DMG downloadable from the Release page** — incognito visit to `https://github.com/J-Krush/wrangle/releases/latest` (or `releases/tag/v1.3.0`); `Wrangle-1.3.0.dmg` asset visible and the download initiates on click. Full re-download not required; visible + initiates is enough evidence.
  3. **In-app UpdateChecker live-test** — launch the locally-installed Wrangle build; UpdateChecker fires its `api.github.com/repos/J-Krush/wrangle/releases/latest` GET (Phase 13 D-09 repoint) and now returns 200 with `tag_name: v1.3.0` instead of the prior 404. Closes the v1.2 → v1.3 UpdateChecker loop.
  4. **Landing-page CTA round-trip** — incognito visit to `https://wrangleapp.dev`; click "Download for macOS" (Phase 17 D-12 → `releases/latest`); browser lands on the public Release page. Phase 17 D-10 LOCKED behavior (404 unauth between Phase 17 deploy and Phase 18 publish) flips to 200/working.

- **D-10:** Evidence format is **inline in SUMMARY.md**, Phase 16-02 Pipeline Side-Effect Audit Trail template. Curl outputs go into a fenced code block inline (`curl -sI ... releases/latest` → `HTTP 200`; `curl -s ... api.github.com/.../releases/latest | jq .tag_name` → `"v1.3.0"`). One optional incognito screenshot of the rendered repo page goes into `.planning/phases/18-public-flip-v1-3-0-release/18-VERIFY/repo-anonymous-render.png` if the user wants visual proof (otherwise text-only is acceptable).

- **D-11:** Browser is **incognito / private window** (Cmd+Shift+N in Chrome/Brave, Cmd+Shift+P in Firefox/Safari). User drives the browser-based checks live; executor runs the curl checks. No need for a second-Mac re-verify (Phase 16 D-05 already attested the DMG opens cleanly on a fresh host; nothing about the DMG has changed since).

### Vendor / external-system cleanup (post-flip)

- **D-12:** LemonSqueezy cleanup scope is **deactivate the Wrangle product only**. Log into the LS dashboard (`jkrush.lemonsqueezy.com/dashboard`), navigate to Products → Wrangle, deactivate the product so the checkout URL `https://jkrush.lemonsqueezy.com/checkout/buy/8860d1f0-c122-4ab6-8528-ee727d3065e3` returns deactivated/gone. Do NOT archive the entire store; do NOT close the LS account. Lowest-risk, reversible if needed later. Phase 17 D-05 deferred this to Phase 18 and it's now in scope.

- **D-13:** `dl.wrangleapp.dev` DNS cleanup: **delete the CNAME/A record** from the DNS provider. Phase 17 D-12 stopped referencing `dl.wrangleapp.dev` in the landing code; the subdomain currently points at nothing useful (old storage or stale alias). Delete cleanly. Reversible — the record can be re-added later if needed. No redirect to the new GH Release URL (rejected — anyone with the old URL bookmarked is rare enough that a clean 404/NXDOMAIN is acceptable; a redirect adds Vercel/`vercel.json` complexity for low value).

- **D-14:** Both vendor cleanups happen **after** the full flip-verify cycle has PASSED. Order: sweep → app-flip → spot-check → publish → verify → LS deactivation → DNS deletion → SUMMARY commit. Reason: if verification fails and we need to re-private the repo or unpublish the Release, having LS and DNS still in their current state preserves the easiest rollback. After verify PASSes, we know the public surface works and can clean up the dead vendor surfaces safely.

- **D-15:** Both vendor cleanups are recorded in SUMMARY but executed via the user's hands (LS dashboard click-through; DNS-provider record-delete UI). Executor surfaces the exact step-by-step instructions + the URLs to navigate to; user confirms completion; executor logs the timestamp + a "confirmed by user" line in SUMMARY. Same pattern as Phase 16 D-05 second-Mac verification.

### Anti-regression (carried forward)

- **D-16:** D-09 anti-regression rules stand — no `git filter-repo`, no `git push --force`, no `git reset --hard` against either repo's `main` branch during Phase 18, except the D-04 interactive carve-out IF a real secret surfaces AND the user explicitly approves history rewrite at the checkpoint. Default path uses zero of these.

- **D-17:** Version invariants stand — `MARKETING_VERSION = 1.3.0` (2 hits) and `CURRENT_PROJECT_VERSION = 6` (2 hits) in `Wrangle.xcodeproj/project.pbxproj` are immutable through Phase 18. `ExportOptions.plist` diff stays empty. Anti-regression checks (Phase 16-02 §"Anti-Regression Results") re-run before the closing SUMMARY commit.

### Claude's Discretion

- **Exact wording of the noise-exemption table in the plan + SUMMARY** — per D-03's pattern (Phase 13 APP-13 style), planner enumerates the known surfaces; exact phrasing and ordering is planner's call. Format suggestion: one row per surface, columns = `pattern`, `file/commit`, `reason`, `last verified phase`.
- **Whether to grep the analytics-key set (`plausible|fathom|posthog`) alongside the FLIP-01 set** — both repos never wired these; zero hits expected. Planner's call whether to include as belt-and-suspenders. Default recommend: yes, costs nothing.
- **Whether to grab a screenshot of the rendered anonymous repo page** — D-10 offered it as optional. Planner's call based on whether the inline curl evidence alone is sufficiently legible. Default recommend: yes, one screenshot at `18-VERIFY/repo-anonymous-render.png`.
- **Plan boundary** — ROADMAP estimates "1 plan." Planner can keep it as a single plan (sweep + flip + verify + vendor cleanup in one) or split into 2 if the sweep alone warrants a self-contained step. Both are acceptable; the natural seam is between "sweep + flip + verify" (REQUIREMENTS-gated) and "vendor cleanup" (housekeeping).
- **Exact text of the SUMMARY's "Phase 18 Closure" section** — Phase 16-02 §"Phase 16 Closure" is the structural template (table of FLIP-IDs × satisfied-by); wording is planner's call.
- **Whether the SUMMARY commit folds in `.planning/STATE.md` + `.planning/ROADMAP.md` tracking updates** (Phase 16-02 D-3 pattern) — recommended yes; this is interactive mode, the orchestrator and executor are the same context, and a separate tracking-only commit adds noise.
- **The "noted unexpected early flip" wording for the landing-repo confirmation in SUMMARY** — short factual line is enough; no postmortem needed.
- **Whether to capture the `gh release view v1.3.0 --json` output before AND after `--draft=false` to show the state transition** — recommended yes; one-line evidence that the publish moved `isDraft: true` → `isDraft: false` and `publishedAt: null` → ISO timestamp.
- **Whether to also screenshot the LS dashboard post-deactivation and the DNS provider's post-delete confirmation** — recommended NO; the user's "confirmed by user" attestation is enough; these are vendor-account surfaces not subject to FLIP-01..05 acceptance criteria.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone requirements

- `.planning/REQUIREMENTS.md` §FLIP-01..05 — the 5 requirements this phase satisfies (1-to-1 with Phase 18).
- `.planning/ROADMAP.md` §"Phase 18: Public Flip + v1.3.0 Release" — Goal, Depends-on (Phases 13–17, all complete), Success Criteria (5 rows), Plans (estimated 1).
- `.planning/PROJECT.md` §"Current Milestone v1.3 Open Source Release" — milestone narrative; the "Public flip" bullet is the last target feature. §"Out of Scope" — no announcement / sponsorship / migration surfaces in scope.

### Prior-phase context that flows through

- `.planning/phases/13-app-de-commercialization/13-CONTEXT.md` — D-09/D-10/D-11 (UpdateChecker repoint to `api.github.com/.../releases/latest`, `/api/version.json` retirement). D-10 LOCKED behavior — `releases/latest` returns 404 unauth while repo is private + draft. Phase 18 publishing flips this to 200. D-12 LOCKED — About-panel `wrangleapp.dev` is intentional surface, exemption-list entry.
- `.planning/phases/14-app-repo-oss-surface/14-CONTEXT.md` — D-09 anti-regression (no filter-repo / force-push / reset-hard). D-19 recovery default (rotate-and-document over history rewrite). D-20 exemption-list pattern (Phase 13 APP-13 style — inline in plan, no public audit doc).
- `.planning/phases/15-landing-repo-oss-surface/15-CONTEXT.md` — D-09 history-preserve posture (ratified the landing repo's lineage). D-10 no public-audit-doc preference. D-11 forbidden-string list expanded with repo-specific surface (`RESEND_API|KV_REST_API`). Phase 15 also surfaced the working-tree-clean state landing repo was in pre-Phase 17.
- `.planning/phases/16-signed-dmg-release-pipeline/16-CONTEXT.md` — D-01 reaffirmed (local-build signed DMG, no CI in v1.3). D-04 release-checklist.md as the procedure source-of-truth. D-09 GH Release state — `--draft` flag intentional, Phase 18 publishes.
- `.planning/phases/16-signed-dmg-release-pipeline/16-02-SUMMARY.md` — REL-05/REL-06 done; full audit trail of the draft Release (tag `v1.3.0` at `1f13550…`, DMG SHA `c4479d9d…`, Apple notary IDs `76fcee46-…` + `47d8aae4-…`, draft URL `releases/tag/untagged-a12004e1af184cd154ed`). D-10 unauth 404 verification command verbatim.
- `.planning/phases/16-signed-dmg-release-pipeline/release-notes-v1.3.0.md` — locked release notes content (5 bullets, OSS-flip leading, v1.2 browser features). Phase 18 publishes verbatim unless user requests an edit at the final read-through.
- `.planning/phases/17-landing-page-repositioning/17-CONTEXT.md` — D-05 LemonSqueezy deferral to Phase 18 (FLIP) → fulfilled here per D-12. D-10/D-12 LOCKED — landing-page download CTA target is `releases/latest`; expected to 404 unauth between Phase 17 deploy and Phase 18 publish (resolved by FLIP-05 here).

### Existing pipeline artifacts

- `docs/release-checklist.md` (in `J-Krush/wrangle` repo working tree, public after flip) — Phase 16 expanded procedure (§1–§10). Phase 18 doesn't modify this file; it references §"Draft GitHub Release" → §"Publish" as the step source.
- `scripts/build-release.sh` + `scripts/create-dmg.sh` + `scripts/preflight-release.sh` — Phase 16 build pipeline. Phase 18 does NOT invoke these (DMG is already built, signed, notarized, attached).
- Existing tag `v1.3.0` on `origin/refs/tags/v1.3.0` → commit `1f135507f63d852e2d2d1cb6649edc36350aa5dc`. Phase 18 does NOT re-tag; only publishes.

### Live-system state (verified 2026-05-23 during context gathering)

- `gh repo view J-Krush/wrangle` → `{"visibility": "PRIVATE"}` — Phase 18 target for FLIP-02.
- `gh repo view J-Krush/wrangle-landing` → `{"visibility": "PUBLIC"}` — FLIP-03 already satisfied (delta noted).
- `gh release view v1.3.0 --repo J-Krush/wrangle` → `{"isDraft": true, "publishedAt": null, "assets": [{"name": "Wrangle-1.3.0.dmg", "digest": "sha256:c4479d9d…"}]}` — Phase 18 target for FLIP-05.
- `curl -s -o /dev/null -w "%{http_code}" https://api.github.com/repos/J-Krush/wrangle/releases/latest` → `404` (D-10 LOCKED) — expected to flip to 200 after FLIP-02 + FLIP-05.
- `git ls-remote origin refs/tags/v1.3.0` → `1f135507f63d852e2d2d1cb6649edc36350aa5dc` — tag is on origin, immutable.

### External systems referenced (not modified except via Phase 18 vendor cleanup)

- LemonSqueezy dashboard at `https://jkrush.lemonsqueezy.com/dashboard` — D-12 deactivates the Wrangle product (account / store stay alive).
- DNS provider for `wrangleapp.dev` — D-13 deletes the `dl.wrangleapp.dev` CNAME/A record. Apex domain `wrangleapp.dev` stays pointed at Vercel (carries the live landing page).
- `https://wrangleapp.dev` — Phase 17 deploy; D-09 check #4 round-trips through this surface.

### Documents NOT to write in this phase

- No `SECURITY.md` changes — Phase 14 REPO-10 covers the app repo's disclosure channel; Phase 18 doesn't touch it.
- No `CONTRIBUTING.md` changes — Phase 14 REPO-03 covers the app repo; landing repo doesn't have one and Phase 18 doesn't add it.
- No standalone `18-FLIP-AUDIT.md` inside either public repo (D-03; mirrors Phase 15 D-10).
- No new files inside `J-Krush/wrangle` working tree as part of FLIP — only `.planning/phases/18-*/` artifacts get committed in this phase.
- No edits to `J-Krush/wrangle-landing` — Phase 17 closed that repo for v1.3; Phase 18 only confirms its state.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- **`release-notes-v1.3.0.md`** — Phase 16 authored a 5-bullet file at `.planning/phases/16-signed-dmg-release-pipeline/release-notes-v1.3.0.md`. Phase 18 uses verbatim with `gh release edit --notes-file ...` (or doesn't pass `--notes-file` at all since it's already set on the draft).
- **`docs/release-checklist.md` §"Draft GitHub Release"** — Phase 16 expanded section includes the `--draft` step. Phase 18 effectively executes the inverse: the documented publish step (a one-line `gh release edit v1.3.0 --draft=false`).
- **Phase 16-02 SUMMARY's "Pipeline Side-Effect Audit Trail"** — the table-of-operations + curl evidence + GH Release metadata sections are a direct template for Phase 18's SUMMARY.

### Established Patterns

- **Inline noise-exemption list pattern** (Phase 13 APP-13 → Phase 14 REPO-09 → Phase 18 D-03). Each phase that runs a forbidden-token sweep documents the exempt surfaces inline in the plan/SUMMARY rather than in a public audit doc. Phase 18 inherits.
- **Interactive checkpoint pattern for irreversible / high-blast-radius decisions** (Phase 14 D-19 strategy-deferral → Phase 18 D-04 recovery-on-real-positive, D-05 mid-flip spot-check, D-15 user-driven vendor cleanup). When a step would be expensive to undo, halt and surface evidence + options to the user before proceeding.
- **Atomic-commits-per-logical-change (Pattern E)** — Phase 14/15/16/17 cadence. Phase 18's plan-level commits follow the same shape: sweep result commit + flip + Release publish recorded in SUMMARY commit + vendor cleanup logged in SUMMARY commit.
- **D-09 anti-regression check table** — Phase 16-02 §"Anti-Regression Results" runs four `git reflog` / `grep` / `git diff` checks before SUMMARY commit. Phase 18 re-runs the same four; expected outcomes identical.

### Integration Points

- **In-app `UpdateChecker`** (Phase 13 D-09 repoint) — the only piece of running app code that depends on the GH Release being published. Lives in `wrangle/Services/UpdateChecker.swift` (per Phase 13's `13-02-SUMMARY.md`). D-09 check #3 exercises this path live by launching the local v1.3.0 build and confirming the call resolves to 200 v1.3.0 instead of 404.
- **Landing-page "Download for macOS" CTA** (Phase 17 D-12 → `releases/latest`) — sits at `https://wrangleapp.dev` hero (and footer / 404 page / use-cases pages / compare pages via Phase 17 sweep). D-09 check #4 round-trips this.
- **Anonymous-API surface for the GH Release** — `https://api.github.com/repos/J-Krush/wrangle/releases/latest` and the underlying `https://github.com/J-Krush/wrangle/releases/latest` redirect. Both should flip from 404 → 200 after FLIP-02 + FLIP-05. The `curl -sI ... releases/latest` check is the cheapest evidence.

</code_context>

<specifics>
## Specific Ideas

- **gh repo public-flip command (verbatim):** `gh repo edit J-Krush/wrangle --visibility public --accept-visibility-change-consequences`. The `--accept-visibility-change-consequences` flag is required by `gh` since the visibility change is treated as a destructive-by-default action.
- **gh release publish command (verbatim):** `gh release edit v1.3.0 --draft=false --repo J-Krush/wrangle`. No `--latest` flag needed (GH auto-marks the newest non-prerelease as latest).
- **Verification curls (verbatim):**
  - Repo render: `curl -sI https://github.com/J-Krush/wrangle | head -1` → expect `HTTP/2 200`.
  - Release latest redirect: `curl -sIL https://github.com/J-Krush/wrangle/releases/latest | grep -i "^location:\|^HTTP"` → expect a `Location:` to `/releases/tag/v1.3.0` and final `HTTP/2 200`.
  - Release API: `curl -s https://api.github.com/repos/J-Krush/wrangle/releases/latest | jq '{tag_name, draft, prerelease, assets: [.assets[].name]}'` → expect `{"tag_name": "v1.3.0", "draft": false, "prerelease": false, "assets": ["Wrangle-1.3.0.dmg"]}`.
  - DMG direct: `curl -sIL https://github.com/J-Krush/wrangle/releases/download/v1.3.0/Wrangle-1.3.0.dmg | grep -i "^content-length\|^HTTP" | head -2` → expect `200` + `content-length: 6549583`.
- **LemonSqueezy product ID (for the dashboard URL):** product UUID is part of the checkout URL `8860d1f0-c122-4ab6-8528-ee727d3065e3`. User navigates LS dashboard → Products → Wrangle → deactivate.
- **DNS provider:** apex `wrangleapp.dev` is on Vercel per Phase 17. `dl.wrangleapp.dev` subdomain is likely on the same DNS provider (whichever registrar/DNS the user uses). User-driven step.
- **Tag commit (verbatim):** `1f135507f63d852e2d2d1cb6649edc36350aa5dc`. No re-tag.
- **DMG SHA-256 (verbatim):** `c4479d9df030c8b2292c258d2a1a6c9b2798a21f7f030dbfe6934b836c84fe27`. No re-sign / re-notarize.
- **Release notes file (verbatim path):** `.planning/phases/16-signed-dmg-release-pipeline/release-notes-v1.3.0.md`. Already loaded into the draft Release.
- **App repo (verbatim path):** `/Users/krush/Projects/Krush-Dev/Wrangle/Wrangle` (this directory; `git@github.com:J-Krush/wrangle.git`).
- **Landing repo (verbatim path):** `/Users/krush/Projects/Krush-Dev/Wrangle/Landing Page` (`git@github.com:J-Krush/wrangle-landing.git`).
- **Phase artifact dir (verbatim path):** `.planning/phases/18-public-flip-v1-3-0-release/`.
- **Anti-regression check verbatim** (per Phase 16-02 template):
  - `git reflog --since="2026-05-23" | grep -E "filter-repo|push.*--force|reset.*--hard"` → expect empty.
  - `grep -c 'MARKETING_VERSION = 1.3.0' Wrangle.xcodeproj/project.pbxproj` → expect 2.
  - `grep -c 'CURRENT_PROJECT_VERSION = 6' Wrangle.xcodeproj/project.pbxproj` → expect 2.
  - `git diff -- ExportOptions.plist` → expect empty.

</specifics>

<deferred>
## Deferred Ideas

- **Investigating exactly when/how `J-Krush/wrangle-landing` flipped public earlier than Phase 18.** Noted in CONTEXT (D-06) as a delta; not a blocker; SUMMARY captures the surprise factually but doesn't postmortem.
- **Public-friendly social/PH/Reddit announcement of v1.3.0.** Out of scope per PROJECT.md posture; v1.3 is silent flip-and-publish. Future milestone may add announcement-coordination if signal warrants.
- **GitHub Actions / CI for release automation.** Deferred to v1.4 (Phase 16 D-01 reaffirmed). Phase 18 is the last manual-pipeline step in v1.3.
- **Filter-repo strip of legacy LemonSqueezy / wrangleapp.dev references from history.** Held at D-09 anti-regression; only opens at the D-04 checkpoint IF a real secret surfaces AND the user approves. Default not taken.
- **`docs/release-checklist.md` post-Phase-18 update** to add a "Publish" section with the `--draft=false` command + verification curls — small docs follow-up; consider in v1.4 milestone or a docs sweep when the next release ramps.
- **Closing the LemonSqueezy account entirely / archiving the full store.** Default per D-12 is product-only deactivation; full store cleanup is a later-personal-finance-tidying decision, not Phase 18's call.
- **Redirecting `dl.wrangleapp.dev` to the GH Release URL.** Rejected per D-13 (low value, adds Vercel/`vercel.json` complexity); deleting the record outright is cleaner. Reconsider only if someone reports a stale bookmark loop.
- **Second-Mac re-verification of the published DMG.** Phase 16 D-05 already attested; the DMG bytes haven't changed. Phase 18 re-verify on second Mac would be paranoia; deferred indefinitely.
- **Verifying the App Store / Mac App Store distribution paths.** Not a target in v1.3 (Wrangle ships outside MAS; PROJECT.md "Out of Scope" implicitly). Permanent.
- **GitHub Sponsors / Buy-Me-a-Coffee surface.** PROJECT.md "Out of Scope" — v1.3 is the star-on-GitHub posture only. v1.4+ may add if signal warrants.

### Posture revisit triggers

Reconsider D-09 (anti-regression / no history rewrite) ONLY if:
- A real credential surfaces in the sweep AND rotation isn't possible AND the user explicitly opts in at the D-04 checkpoint.

Reconsider D-13 (delete DNS record outright) ONLY if:
- Telemetry / friend feedback reports broken bookmarks pointing at `dl.wrangleapp.dev` after the flip.
- The DNS record turns out to still serve traffic at some non-trivial volume that warrants a redirect.

Reconsider D-12 (LS product-only deactivation) ONLY if:
- LS terms-of-service / billing later requires full archival.
- The user changes their mind on future LS use.

</deferred>

---

*Phase: 18-public-flip-v1-3-0-release*
*Context gathered: 2026-05-23*
