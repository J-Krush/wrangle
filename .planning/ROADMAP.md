# Roadmap: Wrangle

## Milestones

- ✓ **v1.0.x** — Pre-planning baseline (editor, AI-file awareness, terminal, multi-tab workspace)
- ✓ **v1.1.0** — "Bigger IDE" (Project structure, density pass, Todos, license/trial plumbing)
- ✓ **v1.2** — "Browser Support" (Phases 1–12; browser stack + UX polish)
- 🚧 **v1.3 Open Source Release** — Phases 13–18 (in progress)

## Overview

v1.3 converts Wrangle from a paid trial-gated app into a free, MIT-licensed open-source portfolio project. Phase 13 rips the commercial surface out of the app (LicenseManager, LicenseGateView, TrialBannerView, LicenseSettingsView, `wrangleapp.dev/api/trial/*`, LemonSqueezy, all plumbing) and replaces it with a one-time "now free + open source" note. Phases 14 and 15 stand up the public-facing surfaces of the two repos (`J-Krush/wrangle` and `J-Krush/wrangle-landing`) — LICENSE, story-driven README, CONTRIBUTING, issue/PR templates, screenshots, secrets sweep. Phase 16 documents and executes the local signed-DMG → notarize → tagged GitHub Release pipeline. Phase 17 repositions the Astro landing page from "Buy $24" to "Free + open source" with a real download link to the v1.3.0 Release. Phase 18 is the small final flip: one last secrets sweep, both repos go public, the Release is published.

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3, …): Planned milestone work.
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED).

Decimal phases appear between their surrounding integers in numeric order. v1.3 continues from v1.2's last phase (12), so v1.3 starts at Phase 13.

- [ ] **Phase 13: App De-Commercialization** — Strip `LicenseManager` / `LicenseGateView` / `TrialBannerView` / `LicenseSettingsView` / trial endpoints; replace with one-time "free + open source" note.
- [x] **Phase 14: App Repo OSS Surface** — `J-Krush/wrangle`: MIT `LICENSE`, story-driven `README.md`, `CONTRIBUTING.md`, issue + PR templates, screenshots/GIF, `SECURITY.md`, full repo secrets audit. (completed 2026-05-20)
- [x] **Phase 15: Landing Repo OSS Surface** — `J-Krush/wrangle-landing`: secrets sweep, MIT `LICENSE`, public-facing `README.md`, `.gitignore` audit. (completed 2026-05-20)
- [x] **Phase 16: Signed-DMG Release Pipeline** — Local build → sign (Developer ID) → notarize (`notarytool`) → staple → signed DMG; attach to `v1.3.0` GitHub Release tag. (completed 2026-05-21)
- [ ] **Phase 17: Landing Page Repositioning** — Astro site reframes from "Buy $24" to "Free + open source": new CTA, story section, GitHub link, real DMG download link, SEO/OG updates, deploy.
- [ ] **Phase 18: Public Flip + v1.3.0 Release** — Final secrets sweep across both repos; flip both private → public; publish the `v1.3.0` Release.

## Phase Details

### Phase 13: App De-Commercialization
**Goal**: A fresh launch of the v1.3 build opens directly to the editor with no gate, no banner, no nag, and no license / trial / pricing code left in the binary.
**Depends on**: Nothing (first phase of v1.3; clean tree from v1.2).
**Requirements**: APP-01, APP-02, APP-03, APP-04, APP-05, APP-06, APP-07, APP-08, APP-09, APP-10, APP-11, APP-12, APP-13, APP-14, APP-15
**Success Criteria** (what must be TRUE):
  1. Launching the app lands the user directly in the editor — no `LicenseGateView` sheet, no `TrialBannerView` strip in `ContentView` chrome, no Preferences → License tab.
  2. A grep of the source tree for `"$24"`, `"Buy"`, `"Trial"` / `"trial"`, `"License"` / `"license"`, `wrangleapp.dev`, and `LemonSqueezy` returns zero matches in product copy or runtime code (excluding the new repo-root `LICENSE` file and Apple-framework type names).
  3. On first launch of v1.3 against an upgraded SwiftData store, a one-time "Wrangle is now free and open source — star us on GitHub" surface appears, links to `https://github.com/J-Krush/wrangle`, is dismissable, and does not re-appear on subsequent launches.
  4. The app builds clean with no warnings or compilation errors after the strip; basic smoke test passes (open app → editor loads → create a Scratch Pad → open a Browser tab).
  5. `scripts/reset-license.sh`, `LicenseManager.swift`, `LicenseGateView.swift`, `TrialBannerView.swift`, `LicenseSettingsView.swift` are all deleted from the repo working tree (`git status` confirms removal).
**Plans**: 3 plans
- [x] 13-01-strip-license-trial-paywall-PLAN.md — Wave 1: Delete the 5 license/trial files; strip plumbing from AppCoordinator, wrangleApp, ContentView, SettingsView, WhatsNewView, NotificationPermissionView; verify Info.plist clean; preliminary APP-13 grep audit. Covers APP-01..APP-09, APP-12, APP-14, APP-15.
- [x] 13-02-oss-note-residue-cleanup-and-update-repoint-PLAN.md — Wave 2: Extend ChangelogEntry with CTA, add v1.3.0 entry + Star on GitHub link, add D-05 fresh-install filter; create LicenseResidueCleanup helper and wire into launch path; repoint UpdateChecker to GitHub Releases endpoint; rewrite About-panel credits with dual-link layout; ship 2 unit-test files; final APP-13 grep audit with exemption list. Covers APP-10, APP-11, APP-13.
- [x] 13-03-test-target-wireup-PLAN.md — Wave 3 (added 2026-05-19): Add the `WrangleTests` Swift Testing target to `Wrangle.xcodeproj`, include all 7 test files (5 pre-existing + 2 from Plan 13-02), share the Wrangle scheme, run the suite, triage any pre-existing test failures. Closes the test-execution gap surfaced by Plan 13-02 before v1.3 ships.

### Phase 14: App Repo OSS Surface
**Goal**: A first-time visitor to `J-Krush/wrangle` lands on a README that tells the product's story (PH launch, Reddit ads, native-for-AI-devs thesis), can find the LICENSE, the contributing guide, the issue/PR templates, screenshots, and is confident no committed secrets exist in the repo's history.
**Depends on**: Phase 13 (so the README's "this is the source for the app" claim matches a de-commercialized codebase; so the secrets audit and content review reflect the v1.3 reality).
**Requirements**: REPO-01, REPO-02, REPO-03, REPO-04, REPO-05, REPO-06, REPO-07, REPO-08, REPO-09, REPO-10, REPO-11, REPO-12
**Success Criteria** (what must be TRUE):
  1. Repo root contains `LICENSE` (MIT, attributed to "Copyright (c) 2026 J Krush"), `README.md`, `CONTRIBUTING.md`, and `SECURITY.md`; the `.github/` directory contains `ISSUE_TEMPLATE/bug_report.md`, `ISSUE_TEMPLATE/feature_request.md`, and `PULL_REQUEST_TEMPLATE.md`.
  2. `README.md` includes — in order — a hero pitch with screenshot/GIF, a "What this is" section, a "Why it's free and open source now" story section covering the 2026-04-22 Product Hunt launch and the Reddit ads channel experiment, a "Built with" list, install (DMG download) instructions, "Build from source," and a "Contributing" / "License" link block.
  3. At least 3 screenshots (editor with rendered markdown, browser tab, project overview) plus an animated demo GIF are committed and visibly embedded in `README.md` when rendered on GitHub.
  4. A repo-wide history audit (`git rev-list --all | xargs git grep -i 'secret\|api[-_]key\|token\|password\|wrangleapp.dev\|lemonsqueezy'`) returns clean — or any hit found is rotated and documented as such.
  5. `.gitignore` is updated and no `.DS_Store`, `DerivedData/`, `.build/`, or `*.xcuserstate` files remain tracked; `docs/architecture.md` / `docs/coding-patterns.md` / `docs/audit-report.md` are reviewed and `CLAUDE.md` has a header note that the project is now open source plus a "Contributors" pointer to `CONTRIBUTING.md`.
**Plans**: TBD (expected: 3 plans — LICENSE + templates scaffold; story-driven README + screenshots/GIF; full repo secrets/history audit + `.gitignore` + docs review).
**UI hint**: yes

### Phase 15: Landing Repo OSS Surface
**Goal**: A first-time visitor to `J-Krush/wrangle-landing` lands on a clear, public-facing README explaining the repo is the Astro source for `wrangleapp.dev` with working build/dev instructions, finds an MIT `LICENSE`, and the repo's history contains no committed analytics tokens or private notes.
**Depends on**: Nothing in v1.3 (can run in parallel with Phase 13 and Phase 14; touches a separate repo on disk at `/Users/krush/Projects/Krush-Dev/Wrangle/Landing Page/`).
**Requirements**: LAND-01, LAND-02, LAND-03, LAND-04, LAND-05
**Success Criteria** (what must be TRUE):
  1. Repo root contains `LICENSE` (MIT, attributed to "Copyright (c) 2026 J Krush") and a rewritten `README.md` covering: what the repo is, dev commands (`pnpm install`, `pnpm dev`, `pnpm build`), deploy target, and a link back to `J-Krush/wrangle`.
  2. A full working-tree and history audit (`git log -p`, `git rev-list --all | xargs git grep -i 'secret\|api[-_]key\|token\|plausible\|fathom\|posthog'`) finds zero committed analytics keys, Slack URLs, private feedback emails, dev-only notes, or hardcoded credentials.
  3. `.gitignore` excludes `node_modules/`, `dist/`, `.env*`, `.DS_Store`; any previously-committed offenders are removed from the working tree.
  4. Running `pnpm install && pnpm dev` from a clean checkout (no `.env`) successfully boots the dev server, confirming the README's instructions are accurate and no required secret is missing from the public surface.
**Plans**: 2 plans
- [x] 15-01-PLAN.md — Deletions, `.gitignore` hardening, Layout.astro neutralization, D-11 audit (LAND-01, LAND-04, LAND-05; D-01..D-11)
- [x] 15-02-PLAN.md — LICENSE add, README rewrite (D-14/D-15/D-16), clean-checkout verification, phase SUMMARY (LAND-02, LAND-03; D-12..D-16)

### Phase 16: Signed-DMG Release Pipeline
**Goal**: A documented, repeatable local-build procedure produces a signed and notarized DMG that opens cleanly on a fresh-eyes Mac without Gatekeeper warnings, attached to a tagged `v1.3.0` GitHub Release on `J-Krush/wrangle` (still private at this point).
**Depends on**: Phase 13 (the build being signed must be the de-commercialized binary, not a license-gated one).
**Requirements**: REL-01, REL-02, REL-03, REL-04, REL-05, REL-06
**Success Criteria** (what must be TRUE):
  1. A documented procedure (`scripts/build-release.sh` or `docs/release.md`) produces a Release-configuration `.app` for Apple Silicon (arm64) macOS 15+, signed with a valid `Developer ID Application` certificate across the `.app` and every bundled binary including SwiftTerm.
  2. The notarization flow (`xcrun notarytool submit … --wait` then `xcrun stapler staple`) completes successfully against the signed `.app`, and the documented Apple ID / app-specific password / Team ID requirements are listed in the release doc.
  3. A DMG is produced from the stapled `.app`, is itself signed with the same Developer ID, and `spctl -a -t open --context context:primary-signature <dmg>` reports the DMG as accepted.
  4. The DMG opens on a second Mac (or after `xattr -d com.apple.quarantine`) without prompting the user to right-click → Open — Gatekeeper passes silently.
  5. The DMG is attached to a `v1.3.0` tagged GitHub Release on `J-Krush/wrangle` (drafted; not yet published to anonymous viewers since the repo is still private — published in Phase 18), and the tag convention is documented in the release doc.
**Plans**: 2 plans
- [x] 16-01-PLAN.md — Wave 1: Pre-flight credential gate (`scripts/preflight-release.sh`), D-02 codesign patch on `scripts/create-dmg.sh` + REL-04 spctl verification, D-03 preflight invocation wire-up on `scripts/build-release.sh`, D-04 six-section expansion of `docs/release-checklist.md`, end-to-end build/sign/notarize/staple/DMG/spctl-PASS execution on the build host. Covers REL-01, REL-02, REL-03, REL-04.
- [x] 16-02-PLAN.md — Wave 2 (depends on 16-01): `release-notes-v1.3.0.md` authoring (4-6 bullets per CONTEXT.md discretion), D-05 second-Mac Gatekeeper verification with screenshot capture, Pattern 3a manual-tag-first `git tag v1.3.0` + `git push origin v1.3.0` + `gh release create v1.3.0 --draft --verify-tag` with DMG asset upload, draft confirmed NOT publicly visible (D-10 404 behavior). Covers REL-05, REL-06.

### Phase 17: Landing Page Repositioning
**Goal**: The live `wrangleapp.dev` site presents Wrangle as a free, open-source macOS markdown editor for AI devs — with a working "Download for macOS" CTA pointing at the real v1.3.0 GitHub Release DMG, a "Star on GitHub" CTA, a story section, and zero remaining "Buy $24" / pricing surface.
**Depends on**: Phase 15 (landing repo is public-ready) and Phase 16 (real GitHub Release URL exists for the DMG download CTA).
**Requirements**: SITE-01, SITE-02, SITE-03, SITE-04, SITE-05, SITE-06, SITE-07, SITE-08, SITE-09, SITE-10
**Success Criteria** (what must be TRUE):
  1. Hero section presents the OSS positioning with a dual CTA: "Download for macOS" (links to the v1.3.0 GitHub Release DMG or `https://github.com/J-Krush/wrangle/releases/latest`) and "Star on GitHub" (links to `https://github.com/J-Krush/wrangle`); no "$24" / "Buy Wrangle" copy survives in the hero or anywhere on the site.
  2. The pricing page is either deleted (with a `404.astro` / fallback handling old inbound links) or rewritten to say "Free and open source — no pricing"; no internal nav link still says "Pricing" or "Buy."
  3. A new "Story" / "About" section (homepage section or its own page) covers the 2026-04-22 Product Hunt launch, the Reddit ads channel experiment, the native-for-AI-devs thesis, and the decision to convert to OSS as a portfolio piece.
  4. SEO + social metadata (page title, meta description, Open Graph, Twitter/X cards) all reflect the OSS positioning; OG image is OSS-appropriate; feature pages have no remaining "Pro" / "Trial limit" / "Premium" copy.
  5. The repositioned site is deployed to the same production host that serves `wrangleapp.dev` (deploy is reversible), and clicking "Download for macOS" successfully resolves to the actual DMG file from the GitHub Release.
**Plans**: TBD (expected: 3 plans — hero + nav + pricing teardown; story section + OG/SEO; download wiring + deploy).
**UI hint**: yes

### Phase 18: Public Flip + v1.3.0 Release
**Goal**: Both GitHub repos go from private to public, the `v1.3.0` Release is published, and an anonymous viewer landing on `J-Krush/wrangle` sees a fully-rendered README with screenshots, an MIT LICENSE, and a downloadable signed DMG.
**Depends on**: Phases 13–17 (everything must be in place before the flip; this is the smallest, last, irreversible-feeling phase).
**Requirements**: FLIP-01, FLIP-02, FLIP-03, FLIP-04, FLIP-05
**Success Criteria** (what must be TRUE):
  1. A final secrets sweep across both repos (`git rev-list --all | xargs git grep -i 'secret\|api[-_]key\|token\|password\|wrangleapp.dev\|lemonsqueezy'`) returns clean; anything found is rotated and history-rewritten before the flip.
  2. `J-Krush/wrangle` is flipped from private to public on GitHub; the repo page renders correctly to an anonymous (signed-out) viewer with README screenshots loading, LICENSE displayed as "MIT," and `CONTRIBUTING.md` accessible.
  3. `J-Krush/wrangle-landing` is flipped from private to public on GitHub and renders cleanly for an anonymous viewer.
  4. The `v1.3.0` GitHub Release is published (drafted → published), with the signed/notarized DMG attached and release notes summarizing the OSS flip plus the headline browser-support features shipped in v1.2.
  5. An anonymous viewer can download the DMG from the public Release page and the landing page's "Download for macOS" CTA (now hitting the public Release URL) works end-to-end.
**Plans**: TBD (expected: 1 plan — secrets sweep + flip sequence + Release publish).

## Progress

**Execution Order:**
Phase 13 must precede Phases 14 and 16 (REPO audit and signed-binary work both depend on the de-commercialized codebase). Phase 15 is independent of Phases 13–14–16 and can run in parallel with any of them — it touches a separate repo on disk. Phase 17 requires both Phase 15 (landing repo is publish-ready) and Phase 16 (real GitHub Release URL for the download CTA). Phase 18 requires all prior phases — it's the single irreversible flip. Critical path: 13 → 16 → 17 → 18, with 14 and 15 parallel-eligible against that spine.

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 13. App De-Commercialization | 3/3 | Plans complete (awaiting verify-phase) | 2026-05-20 |
| 14. App Repo OSS Surface | 3/3 | Complete    | 2026-05-20 |
| 15. Landing Repo OSS Surface | 3/2 | Complete   | 2026-05-20 |
| 16. Signed-DMG Release Pipeline | 2/2 | Complete   | 2026-05-21 |
| 17. Landing Page Repositioning | 0/3 | Not started | - |
| 18. Public Flip + v1.3.0 Release | 0/1 | Not started | - |
