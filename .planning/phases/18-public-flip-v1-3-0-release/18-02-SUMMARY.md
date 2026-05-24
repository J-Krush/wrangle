---
phase: 18-public-flip-v1-3-0-release
plan: 02
subsystem: infra
tags: [vendor-cleanup-deferred, lemonsqueezy, dns, post-flip, housekeeping, milestone-close, v12-update-channel-fix]

requires:
  - phase: 18-public-flip-v1-3-0-release (Plan 18-01)
    provides: PUBLIC J-Krush/wrangle repo; published v1.3.0 Release; FLIP-01..05 satisfied; D-14 rollback-preservation gate cleared
  - phase: 17-landing-page-repositioning
    provides: live wrangleapp.dev with apex pointed at Vercel; D-05/D-12 carry-over surfaces identified for Phase 18 cleanup

provides:
  - Plan 18-02 SUMMARY (this file) — vendor cleanup decisions captured; both D-12 and D-13 deferred with rationale
  - Out-of-scope safety fix: v1.2 in-app UpdateChecker channel restored via landing-repo additions (public/api/version.json + vercel.json /download redirect; commit 230bcc4 on J-Krush/wrangle-landing main)
  - v1.3 milestone marked complete in STATE.md + ROADMAP.md

affects: [milestone-v1.3 (complete), follow-up-vendor-cleanup-when-decided]

tech-stack:
  added: []
  patterns:
    - "Discovery-driven plan re-scope: a Plan 18-01 Check 3 finding surfaced a paid-user-blast-radius risk in D-12 (LS deactivation may demote license-key holders to .invalid via LemonSqueezy validate endpoint behavior). User scope-down: keep LS product active; rely on Phase 17 removal of the buy CTA to gate new traffic instead."
    - "User-driven D-13 deferral with no replacement action — dl.wrangleapp.dev DNS record stays in place; reversible if/when user decides to clean it."
    - "Out-of-scope safety fix landed during Plan 18-02 execution: two-file landing-repo addition (public/api/version.json + vercel.json) wires existing v1.2 binaries onto the in-app upgrade path. Live within ~10 sec of push via Vercel auto-deploy."

key-files:
  created:
    - .planning/phases/18-public-flip-v1-3-0-release/18-02-SUMMARY.md
    - (in landing repo) public/api/version.json + vercel.json — landed in commit 230bcc4 on J-Krush/wrangle-landing
  modified:
    - .planning/STATE.md (Phase 18 + v1.3 milestone complete)
    - .planning/ROADMAP.md (Phase 18 [x]; both plans [x]; v1.3 milestone marked complete in top milestone list)

key-decisions:
  - "D-12 (LS product deactivation) SKIPPED per user override after Plan 18-01 Check 3 analysis surfaced the paid-user risk. v1.2's LicenseManager.validate() at validate-URL https://api.lemonsqueezy.com/v1/licenses/validate decodes the LS response and on `valid:false` sets `licenseStatus = .invalid`, demoting paid users to the LicenseGateView trial screen. Without empirical evidence that LS's deactivation preserves existing-key validation, the cleanest posture is: leave the product active. Phase 17 already removed the buy CTA from wrangleapp.dev so no new buyers arrive. Existing paid users keep validating cleanly. Zero risk; D-12 carries forward as a follow-up if/when the user gets LS deactivation behavior confirmed."
  - "D-13 (dl.wrangleapp.dev DNS deletion) DEFERRED per user choice. Pre-state confirmed: dl resolves to Cloudflare IPs 104.21.14.202 + 172.67.160.137 (same as apex; likely wildcard or duplicate A). Apex wrangleapp.dev still resolvable + HTTP/2 307 (normal www-redirect) verified post-decision. No DNS edits made."
  - "Out-of-scope addition during Plan 18-02 execution: v1.2 in-app UpdateChecker channel fix. The v1.2 binary hardcodes versionEndpoint = https://wrangleapp.dev/api/version.json (pre-Phase-13 D-09 repoint to GitHub Releases API); the route never existed in the landing repo so v1.2 users always saw bogus 'You're up to date.' Added public/api/version.json (static JSON with snake_case keys matching v1.2's VersionInfo CodingKeys) + vercel.json /download 302-redirect (covers v1.2's fallback path when downloadURL is empty). Landed in landing-repo commit 230bcc4; live at https://wrangleapp.dev/api/version.json within ~10 sec via Vercel auto-deploy. User-confirmed end-to-end: v1.2 binary's Check for Updates now correctly sees v1.3.0 prompt."
  - "Trial-screen root-cause analysis performed (response to user question): the LicenseGateView in v1.2 is shown when LicenseManager.loadOnLaunch finds neither a license key nor an unexpired trial in keychain. Paid users with `dev.wrangle.license` keychain entry never see the trial screen (loadOnLaunch optimistically sets `.valid`, validate is silent on network errors). Affected v1.2 population is small: expired-trial users + fresh installs since the trial endpoints went 404. The version-channel fix above gives all v1.2 users an in-app upgrade prompt; trial users who upgrade get LicenseResidueCleanup which permanently strips trial state. Trial-activate/validate safety endpoints intentionally NOT added at this time (the trial screen + buy CTA are no longer surface concerns once paid users keep validating and trial users can upgrade)."

patterns-established:
  - "Vendor-cleanup-as-housekeeping is structurally separate from the user-facing phase Goal — deferring D-12/D-13 does not block phase completion when the Goal (both repos PUBLIC + v1.3.0 Release published + anonymous-viewer rendering) is satisfied by Plan 18-01."
  - "Pivot pattern: an inline discovery during execution (Plan 18-01 Check 3 v1.2-channel gap) can spawn an immediate out-of-scope safety fix without re-planning, provided the fix is small (2 files, 14 lines) and the existing deploy pipeline (Vercel auto-deploy) makes verification cheap."

requirements-completed: []  # Plan 18-02 closes no FLIP-IDs directly; vendor cleanup is housekeeping, not REQUIREMENTS-mandated

duration: ~20min (incl. v1.2-channel pivot + decision-tree on D-12 risk + DNS pre-state + SUMMARY write)
completed: 2026-05-24
---

# Phase 18 Plan 02: Vendor Cleanup Decisions + v1.2 Update Channel Restored Summary

**Plan 18-02 closed with both vendor cleanups deferred and a bonus out-of-scope safety fix landed. D-12 (LemonSqueezy product deactivation) was scoped out after a discovered paid-user risk: v1.2's LicenseManager treats LS validate `valid:false` responses as a downgrade to `.invalid`, which would push paid v1.2 users into the trial-gate screen on next launch. D-13 (dl.wrangleapp.dev DNS deletion) was user-deferred with no replacement action. While diagnosing the v1.2 trial-screen behavior the team discovered that v1.2's in-app UpdateChecker had been silently failing because its hardcoded endpoint (wrangleapp.dev/api/version.json) returned 404; a two-file landing-repo addition restored that channel and is now serving v1.3.0 update prompts to v1.2 binaries. Phase 18 is closed; v1.3 milestone (Open Source Release) is complete.**

## Performance

- **Duration:** ~20 min wall-clock (incl. discovery, decision-tree on D-12, v1.2-channel safety fix, DNS pre-state capture)
- **Tasks executed:** 3 of 3 (Task 0 pre-flight PASS; Task 1 LS scoped-out via user override; Task 2 DNS user-deferred; Task 3 this SUMMARY + atomic close-out)
- **Commits landed:**
  1. (landing repo) `230bcc4 feat: add /api/version.json + /download routes for v1.2 in-app UpdateChecker` — out-of-scope safety fix
  2. (this commit) `docs(18-02): close plan 02 — vendor cleanup deferred + v1.2 channel restored; v1.3 milestone complete` — Pattern E atomic close

## Accomplishments

- **Plan 18-01 D-14 gating verified** (Task 0): 18-01-SUMMARY.md exists; FLIP-01..05 in frontmatter; anti-regression 4/4 PASS in 18-01 SUMMARY; live state J-Krush/wrangle PUBLIC + v1.3.0 isDraft:false / publishedAt:2026-05-23T17:42:33Z. Wave 2 cleared to proceed.
- **D-12 paid-user-risk discovered + scope-down decided**: v1.2's LicenseManager.validate() endpoint behavior under LS product deactivation is undefined; chosen posture is keep-LS-product-active (Phase 17's CTA removal already gates new traffic). LemonSqueezy account + store + Wrangle product remain alive and reversible if user later confirms safe deactivation behavior.
- **D-13 user-deferred**: dl.wrangleapp.dev DNS record stays in place. Pre-state captured (A records to 104.21.14.202, 172.67.160.137 — same Cloudflare IPs as apex). Apex invariant verified intact post-decision (still resolvable + HTTP/2 307 to www).
- **v1.2 in-app update channel restored (out-of-scope)**: `wrangleapp.dev/api/version.json` now returns 200 with snake-case JSON matching v1.2's VersionInfo Codable; `wrangleapp.dev/download` now 302-redirects to `releases/latest`. v1.2 binaries' UpdateChecker.performCheck() succeeds, `isVersion("1.3.0", newerThan: "1.2.0")` returns true, the in-app update prompt fires. User-confirmed end-to-end with their own v1.2 binary.
- **Anti-regression check table 4/4 PASS** at final re-run (no filter-repo / push --force / reset --hard; MARKETING_VERSION 2x; CURRENT_PROJECT_VERSION 2x; ExportOptions.plist diff empty).

## Vendor Cleanup Attestations

### D-12: LemonSqueezy product deactivation — SCOPED OUT

- **Pre-state evidence (captured 2026-05-24T00:07:00Z):**
  ```
  curl -sI -o /dev/null -w "HTTP %{http_code}\n" https://jkrush.lemonsqueezy.com/checkout/buy/8860d1f0-c122-4ab6-8528-ee727d3065e3
  HTTP 302
  ```
  Checkout URL active (LS-managed 302 redirect).

- **Post-state evidence:** Not captured — user chose to skip the deactivation entirely.

- **User attestation:** "Skip LS deactivation entirely (override D-12)" — selected after the orchestrator surfaced the paid-user risk in v1.2's LicenseManager.validate() codepath (lines 217-228 of v1.2's LicenseManager.swift: `if response.valid { licenseStatus = .valid } else { licenseStatus = .invalid }`). Decision timestamp: 2026-05-24T00:23Z.

- **Scope status:** D-12 unresolved; LS product stays active; LS account + store stay alive. Phase 17 already removed the buy CTA from wrangleapp.dev so the product surface is no longer findable. Zero new buyers; zero existing-user disruption.

- **Reversibility:** D-12 can be re-attempted at any time once LS deactivation behavior against existing license keys is empirically confirmed (test: deactivate, run `curl https://api.lemonsqueezy.com/v1/licenses/validate -d "license_key=<known-paid-key>"`; if returns 200 + valid:true, proceed with full D-12 closure).

### D-13: dl.wrangleapp.dev DNS deletion — DEFERRED

- **Pre-state evidence (captured 2026-05-24T00:24:30Z):**
  ```
  dig +short dl.wrangleapp.dev
  104.21.14.202
  172.67.160.137

  dig dl.wrangleapp.dev | grep -E "status:|ANSWER SECTION"
  ;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 8056
  ;; ANSWER SECTION:
  dl.wrangleapp.dev.	300	IN	A	172.67.160.137
  dl.wrangleapp.dev.	300	IN	A	104.21.14.202
  ```
  Two A records pointing at Cloudflare IPs identical to the apex IPs (consistent with a wildcard CNAME flattened by Cloudflare, or literal duplicate A records).

- **Post-state evidence:** Not captured — user deferred the deletion.

- **Apex invariant verification (post-decision, 2026-05-24T00:25:19Z):**
  ```
  dig +short wrangleapp.dev → 104.21.14.202, 172.67.160.137 (unchanged)
  curl -sI https://wrangleapp.dev → HTTP/2 307 (normal apex-to-www redirect; landing page intact)
  ```

- **User attestation:** "Skipping" — selected at 2026-05-24T00:25Z.

- **Scope status:** D-13 unresolved; dl.wrangleapp.dev still resolves. No user-facing CTA or live code references dl.wrangleapp.dev since Phase 17 D-12 stripped them. Practical impact: subdomain is "dead-end resolvable" (anyone hitting it gets Cloudflare's default response for an unconfigured origin, likely a 404 from the same edge that serves the apex). Worst case is a stale bookmark from before Phase 17.

- **Reversibility:** D-13 can be closed at any future point via the DNS provider UI (delete the `dl` A record entries; verify NXDOMAIN; verify apex unaffected).

## Out-of-Scope: v1.2 In-App Update Channel Restored

This was not in Plan 18-02's original scope. It was discovered during Plan 18-01 Task 6 Check 3 when the user's v1.2 binary reported "Wrangle v1.2.0 is the latest version" instead of seeing the freshly-published v1.3.0. Root cause and fix landed during Plan 18-02 execution as a pivot before Task 1.

**Root cause:**
v1.2's `wrangle/App/UpdateChecker.swift` hardcodes `versionEndpoint = "https://wrangleapp.dev/api/version.json"`. The Phase 13 D-09 repoint to GitHub Releases API happened in commit `a02dbe8 feat(13-02): UpdateChecker GitHub Releases repoint + About panel dual link`, so v1.3.0 builds correctly query api.github.com/repos/J-Krush/wrangle/releases/latest. v1.2 binaries shipped with the old wrangleapp.dev endpoint, which never existed as a route in the landing repo. v1.2's URLSession.shared.data(from:) request to /api/version.json returns 200 with the Astro 404 HTML body, `JSONDecoder().decode(VersionInfo.self, from: data)` fails on the HTML, the catch block silently sets `showUpToDate = true`, and the user sees the misleading "up to date" UI.

**Fix (landed in J-Krush/wrangle-landing commit 230bcc4 at 2026-05-24T00:13Z, live at ~00:13:10Z):**
- `public/api/version.json` — static JSON file served by Astro/Vercel CDN. Snake-case keys (`version`, `download_url`, `release_notes`) match v1.2's VersionInfo CodingKeys exactly.
- `vercel.json` — adds a `/download` 302-redirect to `https://github.com/J-Krush/wrangle/releases/latest` for the fallback path v1.2 uses when `downloadURL` is empty.

**Verification (curl evidence, 2026-05-24T00:13Z):**
```
$ curl -sL https://wrangleapp.dev/api/version.json | jq '.'
{
  "version": "1.3.0",
  "download_url": "https://github.com/J-Krush/wrangle/releases/download/v1.3.0/Wrangle-1.3.0.dmg",
  "release_notes": "Wrangle is now MIT-licensed and free for everyone..."
}

$ curl -sIL https://wrangleapp.dev/download | grep -iE "^(HTTP|location)"
HTTP/2 307
location: https://www.wrangleapp.dev/download
HTTP/2 307
location: https://github.com/J-Krush/wrangle/releases/latest
HTTP/2 302
location: https://github.com/J-Krush/wrangle/releases/tag/v1.3.0
HTTP/2 200
```

**User end-to-end attestation:** "Tested, v1.2 now sees v1.3.0 update" — confirmed at 2026-05-24T00:14Z.

**Effect:** Every v1.2 user on next launch (auto-check via `wrangleApp.swift:117 coordinator.updateChecker.checkForUpdate()`) or next manual Check for Updates now sees the v1.3.0 in-app upgrade prompt. Click-through downloads the signed DMG; on first launch of v1.3.0, `LicenseResidueCleanup` strips any stale trial state. Affected cohort (expired-trial users + fresh-install v1.2 users since the trial endpoints went 404) gets a clean upgrade path. Paid v1.2 users with active keys never saw the trial screen and now also see the update prompt.

## Anti-Regression Results (final re-confirm)

| Check | Rule | Command | Expected | Actual | Result |
|-------|------|---------|----------|--------|--------|
| 1 | D-16: no destructive git on `main` | `git reflog --since="2026-05-23" \| grep -E "filter-repo\|push.*--force\|reset.*--hard"` | empty | empty | ✅ PASS |
| 2 | D-17: MARKETING_VERSION pinned | `grep -c 'MARKETING_VERSION = 1.3.0' Wrangle.xcodeproj/project.pbxproj` | `2` | `2` | ✅ PASS |
| 3 | D-17: CURRENT_PROJECT_VERSION pinned | `grep -c 'CURRENT_PROJECT_VERSION = 6' Wrangle.xcodeproj/project.pbxproj` | `2` | `2` | ✅ PASS |
| 4 | D-17: ExportOptions.plist invariant | `git diff -- ExportOptions.plist` | empty | empty | ✅ PASS |

**Anti-regression result: 4/4 PASS.**

**Plus live-state invariants (Plan 18-01 outputs STILL hold):**
- `gh repo view J-Krush/wrangle --json visibility` → `{"visibility":"PUBLIC"}` ✓
- `gh release view v1.3.0 --json isDraft,publishedAt` → `{"isDraft":false, "publishedAt":"2026-05-23T17:42:33Z"}` ✓
- `dig +short wrangleapp.dev` → 104.21.14.202, 172.67.160.137 (apex unchanged) ✓
- `curl -sI https://wrangleapp.dev` → HTTP/2 307 (Phase 17 landing page serving) ✓

## Phase 18 Final Closure — All Five FLIP-IDs Satisfied + Vendor Housekeeping Deferred

| FLIP-ID / Decision | Description | Satisfied by | Status |
|--------------------|-------------|--------------|--------|
| FLIP-01 | Final secrets sweep returns clean | Plan 18-01 Task 1 + Task 1.1 (extend-and-document; 0 real-positive credentials) | ✅ Complete |
| FLIP-02 | J-Krush/wrangle PRIVATE → PUBLIC | Plan 18-01 Task 2 (2026-05-23T17:18:26Z) | ✅ Complete |
| FLIP-03 | J-Krush/wrangle-landing PUBLIC | Plan 18-01 Task 5 confirm-only (already PUBLIC since 2026-05-23) | ✅ Complete |
| FLIP-04 | Anonymous-viewer four-check verification | Plan 18-01 Task 3 spot-check + Task 6 curl evidence + this Plan's bonus v1.2-channel fix | ✅ Complete |
| FLIP-05 | v1.3.0 GitHub Release published | Plan 18-01 Task 4 (2026-05-23T17:42:33Z, with D-07 carve-out for revised notes) | ✅ Complete |
| D-12 | LemonSqueezy Wrangle product deactivation | Scoped out per user override; paid-user risk in v1.2's LicenseManager.validate codepath | ⏸ Deferred |
| D-13 | dl.wrangleapp.dev DNS record deletion | User-deferred; apex invariant preserved | ⏸ Deferred |
| Bonus: v1.2 update channel | wrangleapp.dev/api/version.json + /download routes | Landing-repo commit 230bcc4 (out-of-scope safety fix landed during Plan 18-02) | ✅ Complete |

## Milestone v1.3 Closure

The v1.3 "Open Source Release" milestone (Phases 13–18) is **Complete** as of 2026-05-24. Final state:

- **App repo** `J-Krush/wrangle`: PUBLIC, MIT-licensed, story-driven README, screenshots + GIFs, contributing guide, issue + PR templates, transparent `.planning/` history
- **Landing repo** `J-Krush/wrangle-landing`: PUBLIC, MIT-licensed, free + open source positioning, working Download for macOS CTA, in-app version-check endpoint serving v1.3.0 updates to legacy v1.2 binaries
- **v1.3.0 GitHub Release**: published with signed + notarized + stapled `Wrangle-1.3.0.dmg` (size 6549583 bytes, SHA c4479d9d…)
- **Live site** wrangleapp.dev: serving the OSS-repositioned landing page (Phase 17), with `/api/version.json` + `/download` endpoints (Phase 18 Plan 02 bonus)
- **In-app UpdateChecker**: v1.3.0 build hits api.github.com/repos/J-Krush/wrangle/releases/latest (Phase 13 D-09 repoint); v1.2 builds hit wrangleapp.dev/api/version.json (Phase 18 Plan 02 bonus, restores their upgrade path)
- **Vendor surfaces** (deferred): LemonSqueezy Wrangle product active (no buyer-facing CTA), dl.wrangleapp.dev DNS record present (no live code references)

All six v1.3 phases marked complete:
- ✅ Phase 13: App De-Commercialization (2026-05-20)
- ✅ Phase 14: App Repo OSS Surface (2026-05-20)
- ✅ Phase 15: Landing Repo OSS Surface (2026-05-20)
- ✅ Phase 16: Signed-DMG Release Pipeline (2026-05-21)
- ✅ Phase 17: Landing Page Repositioning (2026-05-23)
- ✅ Phase 18: Public Flip + v1.3.0 Release (2026-05-24)

## Decisions Made

- **D-12 scope-out** (LS deactivation): user override after orchestrator surfaced paid-user risk. LS product stays active; account + store stay alive; reversible if user later confirms safe deactivation behavior. See Vendor Cleanup Attestations §D-12 for rationale + reversibility path.
- **D-13 deferral** (DNS deletion): user choice to skip. dl.wrangleapp.dev stays resolvable; apex invariant verified intact post-decision. See Vendor Cleanup Attestations §D-13.
- **v1.2 update channel fix** (out-of-scope addition): landed inline during Plan 18-02 execution as a pivot. Two-file landing-repo addition; live within ~10 sec via Vercel auto-deploy. End-to-end user-confirmed.
- **Trial-screen safety endpoints NOT added** (also out-of-scope): considered after user asked about silencing the v1.2 trial screen remotely. Root-cause analysis showed the trial screen only affects (a) expired-trial users and (b) fresh-install v1.2 users since the trial endpoints went 404 — both of which are now handled by the update prompt. Paid v1.2 users never saw the trial screen. Decision: ship the update-channel fix alone; trial-activate/validate safety endpoints can be added later if user feedback indicates the upgrade path isn't sufficient.

## Deviations from Plan

1. **D-12 SCOPED OUT** (vs PLAN expectation of "deactivated with user-attested timestamp"). Reason: paid-user risk discovered in v1.2's LicenseManager.validate() codepath. Plan 18-02 success_criteria explicitly allows skips with rationale; this is a sanctioned deviation, not a failure.
2. **D-13 USER-DEFERRED** (vs PLAN expectation of "deleted + user-attested + apex preserved"). Reason: user choice; no replacement action. Same success_criteria allowance applies.
3. **Out-of-scope landing-repo work landed during Plan 18-02 execution** — public/api/version.json + vercel.json. Justification: discovered during Plan 18-01 verification, fix was small (2 files, 14 lines), and the immediate user-population impact (v1.2 binaries returning misleading "up to date") warranted shipping before closing the phase. Landing repo commit `230bcc4` is the trail.

## Issues Encountered

1. **v1.2 in-app UpdateChecker silently failing** — surfaced during Plan 18-01 Check 3; root-caused to missing wrangleapp.dev/api/version.json route in landing repo. **RESOLVED in this plan** via out-of-scope landing-repo fix.

2. **LS product deactivation behavior under existing-key validation is undefined** — surfaced during Plan 18-02 Task 1 risk analysis. Without empirical evidence, the safer posture is to leave the product active. **DEFERRED**: D-12 carries forward as a follow-up if/when the user gets behavior confirmed.

3. **None of the deferred items block the user-facing Phase 18 Goal** — both repos are PUBLIC, v1.3.0 Release is LIVE, anonymous viewers see fully-rendered open-source content with downloadable signed DMG, AND legacy v1.2 binaries have a working upgrade path. Goal fully satisfied.

## Self-Check

- [x] Task 0 pre-flight PASS (18-01 closed cleanly; D-14 gate satisfied)
- [x] Task 1 LS deactivation: explicitly scoped out per user override; deviation logged; rationale captured (paid-user risk)
- [x] Task 2 DNS deletion: explicitly deferred per user choice; deviation logged; apex invariant preserved
- [x] Task 3 SUMMARY authored with all required Phase-16-02-template sections
- [x] §Vendor Cleanup Attestations (D-12 + D-13) with before-state evidence + user-attestation timestamps + reversibility paths
- [x] §Anti-Regression Results 4/4 PASS
- [x] §Phase 18 Final Closure cross-references both plans
- [x] §Milestone v1.3 Closure confirms milestone completion
- [x] STATE.md + ROADMAP.md folded into closing atomic commit (Phase 16-02 D-3 pattern)
- [x] Apex wrangleapp.dev invariant preserved throughout (verified by dig + curl pre + post decisions)
- [x] Bonus: v1.2 update channel restoration documented + user-confirmed end-to-end

## Self-Check: PASSED
