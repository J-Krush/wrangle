# Requirements: Wrangle v1.3 — Open Source Release

**Defined:** 2026-05-19
**Core Value:** Every surface — editor, terminal, file tree, browser — serves a developer driving AI agents. Speed, density, and AI-file awareness win over breadth of consumer features.
**Milestone-specific framing:** Convert Wrangle from a paid trial-gated macOS app into a free, MIT-licensed open-source project — strip the commercial surface from the app, reposition the landing page, and stand up both the app repo (`J-Krush/wrangle`) and landing-page repo (`J-Krush/wrangle-landing`) as public GitHub repositories that tell the product's story. Goal: portfolio piece for a job search.

## Milestone v1.3 Requirements

Each requirement maps to exactly one roadmap phase (see Traceability).

### APP — App De-Commercialization

Strip every trial / paywall / license surface from the app so opening v1.3 lands the user directly in the editor with no gate, no banner, no nag.

- [ ] **APP-01**: `wrangle/App/LicenseManager.swift` is deleted; no references remain in the project.
- [ ] **APP-02**: `wrangle/App/LicenseGateView.swift` is deleted; the `LicenseGateView()` call site at `ContentView.swift:203` is removed (gating presentation is removed entirely — the editor opens unconditionally on launch).
- [ ] **APP-03**: `wrangle/App/TrialBannerView.swift` is deleted; the `TrialBannerView()` call site at `ContentView.swift:43` is removed. No replacement banner ships in the editor chrome.
- [ ] **APP-04**: `wrangle/App/LicenseSettingsView.swift` is deleted; the corresponding Preferences tab is removed from the Settings scene.
- [ ] **APP-05**: `scripts/reset-license.sh` is deleted.
- [ ] **APP-06**: `wrangle/App/AppCoordinator.swift` no longer instantiates or owns `LicenseManager`; its `var licenseManager = LicenseManager()` property is removed along with any downstream propagation.
- [ ] **APP-07**: `wrangle/wrangleApp.swift` startup path runs no license check, no trial check, and no `wrangleapp.dev/api/trial/*` call.
- [ ] **APP-08**: All references to `wrangleapp.dev/api/trial/activate` and `wrangleapp.dev/api/trial/validate` (and any sibling endpoints) are removed from the codebase. No `URLRequest` to those hosts compiles.
- [ ] **APP-09**: All references to LemonSqueezy (URLs, comments, placeholder constants) are removed from the codebase.
- [ ] **APP-10**: `wrangle/App/WhatsNewView.swift` and `wrangle/App/WhatsNewChangelog.swift` have any trial / paywall / "Buy"-related copy stripped. The v1.3 entry in the changelog reads as a release note focused on the open-source flip (exact copy: TBD by the user during execution, but the entry exists).
- [ ] **APP-11**: A one-time "Wrangle is now free and open source — star us on GitHub" surface appears on the first launch of v1.3 against an upgraded SwiftData store, links to `https://github.com/J-Krush/wrangle`, and is dismissable. It does NOT re-appear on subsequent launches and does NOT block the editor. Implementation: reuse the existing `WhatsNewView` mechanism if compatible; otherwise a one-off sheet keyed off the version bump.
- [ ] **APP-12**: `wrangle/App/NotificationPermissionView.swift` is audited for any trial-related nag copy; trial-related code paths are removed (the permission prompt itself can stay if it serves a non-trial purpose).
- [ ] **APP-13**: A grep of the codebase for `"$24"`, `"Buy"`, `"Trial"`, `"trial"`, `"License"`, `"license"` (excluding the new `LICENSE` file at repo root and Apple-framework type names like `WKWebsiteDataStore`) returns zero matches in product copy or runtime code paths.
- [ ] **APP-14**: `Info.plist` and any `.entitlements` files have any trial / pricing / URL-scheme / feature-flag entries related to licensing removed.
- [ ] **APP-15**: The app builds clean (no warnings, no compilation errors) after the strip, and basic smoke test passes: open the app → editor loads → can create a Scratch Pad and a Browser tab without any gate appearing.

### REL — Signed Release Pipeline (Local Build)

Document and verify the local-build path that produces a signed, notarized DMG ready to attach to a tagged GitHub Release. No GitHub Actions automation this milestone.

- [x] **REL-01**: A `scripts/build-release.sh` (or equivalent documented procedure in `docs/release.md`) builds a Release-configuration `.app` bundle for Apple Silicon (arm64) macOS 15+.
- [x] **REL-02**: A valid `Developer ID Application` certificate is present in the local Keychain and is used by the build to sign the `.app` and all bundled binaries (SwiftTerm, any embedded frameworks).
- [x] **REL-03**: The build documents and executes the `xcrun notarytool submit … --wait` notarization flow (with the user's Apple ID / app-specific password / Team ID), and `xcrun stapler staple` is run against the notarized `.app`.
- [x] **REL-04**: A DMG is produced from the notarized `.app` (`create-dmg`, `hdiutil`, or equivalent), is itself signed with the same Developer ID, and is verifiable via `spctl -a -t open --context context:primary-signature <dmg>`.
- [x] **REL-05**: A GitHub Release-tag convention is documented (`v1.3.0` matching the app's marketing version), and the DMG is attached to a tagged Release on `J-Krush/wrangle`.
- [x] **REL-06**: The release DMG opens cleanly on a fresh-eyes Mac without Gatekeeper warnings (no right-click → Open required). Verified by either a second machine or by clearing the local quarantine attribute test.

### REPO — App Repo OSS Surface (`J-Krush/wrangle`)

Stand up the public-facing surface of the app repository — the README is the portfolio piece.

- [x] **REPO-01**: `LICENSE` file at repo root contains the MIT License, attributed to `Copyright (c) 2026 J Krush`.
- [x] **REPO-02**: `README.md` at repo root tells the product story. Required sections (in order): (a) one-paragraph hero pitch with screenshot/GIF, (b) "What this is" — native macOS markdown editor for AI devs, the AI-file-awareness angle, (c) "Why it's free and open source now" — the story of the Product Hunt launch on 2026-04-22, the Reddit ads channel experiment, the decision to convert to OSS as a portfolio piece, (d) "Built with" — Swift / SwiftUI / SwiftData / SwiftTerm / WKWebView, macOS 15+ Apple Silicon, (e) "Install" — download DMG from latest Release, (f) "Build from source" — Xcode setup, (g) "Contributing" — link to `CONTRIBUTING.md`, (h) "License" — MIT.
- [x] **REPO-03**: `CONTRIBUTING.md` at repo root documents how to set up the dev environment, how to file issues, the PR process, and coding conventions (links into `CLAUDE.md` and `docs/coding-patterns.md`).
- [x] **REPO-04**: `.github/ISSUE_TEMPLATE/bug_report.md` exists with structured fields (steps to reproduce, expected vs actual, macOS version, Wrangle version, screenshot).
- [x] **REPO-05**: `.github/ISSUE_TEMPLATE/feature_request.md` exists with structured fields (problem, proposed solution, alternatives, AI-dev-workflow context).
- [x] **REPO-06**: `.github/PULL_REQUEST_TEMPLATE.md` exists with checklist (description, screenshots if UI, tests run, CLAUDE.md conventions followed).
- [x] **REPO-07**: At least 3 screenshots (editor with rendered markdown, browser tab, project overview) plus an animated demo GIF are committed to the repo and embedded in `README.md`.
- [x] **REPO-08**: `.gitignore` is reviewed and updated to ensure no committed secrets, dev-only files, `.DS_Store` litter, or build artifacts (`.build/`, `DerivedData/`, `*.xcuserstate`) are tracked. Existing committed offenders are removed.
- [x] **REPO-09**: A full repo audit (`git log -p`, `git rev-list --all | xargs git grep -i …`) confirms no committed secrets: no API keys for LemonSqueezy / wrangleapp.dev / analytics / TestFlight / private feedback endpoints. Any found are removed via history rewrite (`git filter-repo`) OR documented as known-rotated.
- [x] **REPO-10**: `SECURITY.md` at repo root documents responsible disclosure (private email or GitHub Security Advisories).
- [x] **REPO-11**: `CLAUDE.md` is updated with a header note that the project is open source and a "Contributors" section pointing new contributors at `CONTRIBUTING.md`.
- [x] **REPO-12**: `docs/` directory existing contents (`architecture.md`, `coding-patterns.md`, `audit-report.md`) are reviewed for any private content or references that don't belong in a public repo.

### LAND — Landing Repo OSS Surface (`J-Krush/wrangle-landing`)

Stand up the public-facing surface of the landing-page repository.

- [x] **LAND-01**: A full audit of `Landing Page/` finds and removes any private analytics keys (e.g., Plausible / Fathom / GA / PostHog tokens), internal Slack URLs, private feedback emails, dev-only notes, hardcoded admin credentials.
- [x] **LAND-02**: `LICENSE` file at the landing-page repo root contains the MIT License, attributed to `Copyright (c) 2026 J Krush`.
- [x] **LAND-03**: `README.md` in the landing-page repo is rewritten as public-facing: (a) what this repo is (the Astro source for `wrangleapp.dev`), (b) build/dev instructions (`pnpm install`, `pnpm dev`, `pnpm build`), (c) deploy target (Vercel / Netlify / static hosting — whatever it actually is), (d) link to the app repo.
- [x] **LAND-04**: `.gitignore` correctly excludes `node_modules/`, `dist/`, `.env*`, `.DS_Store`. Existing committed offenders are removed.
- [x] **LAND-05**: Full repo audit confirms no committed secrets in history.

### SITE — Landing Page Repositioning

Rewrite the Astro landing page from "Buy Wrangle for $24" to "Free + open source macOS markdown editor for AI devs." Story-driven; portfolio-quality.

- [x] **SITE-01**: Hero section CTA changes from "Buy Wrangle ($24)" (or equivalent existing copy) to a dual CTA: "Download for macOS" (linking to the GitHub Release DMG) + "Star on GitHub" (linking to `https://github.com/J-Krush/wrangle`). Hero copy reframes the value proposition for the OSS positioning.
- [x] **SITE-02**: The pricing page / pricing section is either deleted entirely or rewritten to say "Free and open source — no pricing." Internal links from other pages to `/pricing` are updated or removed.
- [x] **SITE-03**: A new "Story" / "About" section is added (either as its own page or as a homepage section) covering: the Product Hunt launch on 2026-04-22, the Reddit ads channel experiment, the thesis (native macOS markdown for AI devs), and the decision to open-source it as a portfolio piece.
- [x] **SITE-04**: Top-nav links are updated: any "Buy" / "Pricing" entry is removed or relabeled, and a "GitHub" link is added (icon + label).
- [x] **SITE-05**: SEO metadata is updated: page title, meta description, and Open Graph tags reflect the OSS positioning. The existing OG image (or a new one generated via `scripts/og-image`) is OSS-appropriate.
- [x] **SITE-06**: Twitter / X social-card metadata is updated to match the new positioning.
- [x] **SITE-07**: Screenshots and copy on feature pages are reviewed; any "Pro feature" / "Trial limit" / "Premium" language is removed.
- [x] **SITE-08**: The "Download" CTA points at the actual GitHub Release URL for the v1.3.0 DMG (or a `https://github.com/J-Krush/wrangle/releases/latest` redirect target). Click works end-to-end against a real (private at the moment, public later) release.
- [x] **SITE-09**: The landing page is deployed to its production target (the same host that currently serves `wrangleapp.dev`), with the new copy live. Deploy is reversible.
- [x] **SITE-10**: A `404.astro` / fallback for the removed pricing page (if any) is in place so old inbound links don't dead-end.

### FLIP — Public Flip + v1.3.0 Release

The final milestone step — both repos go public and the DMG release ships.

- [ ] **FLIP-01**: A final secrets sweep is run across both repos: `git log -p` + `git rev-list --all | xargs git grep -i 'secret\|api[-_]key\|token\|password\|wrangleapp.dev\|lemonsqueezy'` returns clean. Anything found is rotated and history-rewritten as needed.
- [ ] **FLIP-02**: `J-Krush/wrangle` is flipped from private to public on GitHub.
- [ ] **FLIP-03**: `J-Krush/wrangle-landing` is flipped from private to public on GitHub.
- [ ] **FLIP-04**: The `J-Krush/wrangle` repo page renders correctly to an anonymous viewer: README displays with screenshots, LICENSE renders as "MIT," and the latest Release with the DMG is downloadable.
- [ ] **FLIP-05**: The `v1.3.0` GitHub Release is published (drafted → published), with the signed/notarized DMG attached, and release notes summarizing the OSS flip + headline browser-support features that shipped in v1.2.

## Future Requirements (deferred)

- **GitHub Actions release automation** — tag-triggered signed/notarized DMG builds via GH Actions. Cert + key + notarization creds as encrypted secrets. Deferred to v1.4.
- **Storage-key constants refactor (`SidebarStorageKeys` / `OverviewStorageKeys`)** — Phase 12 of v1.2 created and reverted these; the 6 overview `@AppStorage` literals remain inline. Cosmetic-only; revisit if drift incidents occur.
- **GitHub Sponsors / Buy Me a Coffee CTA** — could replace the simple GitHub-link CTA later if there's signal that anyone wants to fund the project.
- **CODE_OF_CONDUCT.md** — Contributor Covenant. Skipped for v1.3; add later only if contributor volume warrants it.
- **Community Discord / forum** — out of scope; not the goal of this milestone.

## Out of Scope (this milestone)

- **GitHub Actions release automation** (deferred — see Future Requirements).
- **Sponsorship / donation surface** — v1.3 ships "star us on GitHub," not a donation CTA. Honest signal for a portfolio piece, less to maintain.
- **Migrating existing paid customers** — the license-key flow is being torn out wholesale. Any holder of a v1.2 license simply opens v1.3 to the editor. No refund flow, no entitlement export.
- **Renaming the project / repo / bundle ID** — "Wrangle" name stays; bundle ID stays; repos stay as `wrangle` and `wrangle-landing`.
- **Source-available / dual-license schemes** — MIT picked deliberately; no BSL / AGPL / Elastic License / "non-commercial" gating.
- **Contributor onboarding automation (devcontainers, codespaces, etc.)** — README/CONTRIBUTING covers manual setup; deeper tooling can wait.
- **Internationalization of README / landing page** — English only for v1.3.
- **Static analysis / linter CI** — out of scope; the existing manual build/test loop ships v1.3.
- **Adding new app features** — v1.3 is a release-engineering milestone. No new product features. Bugs found during the audit are fixable; greenfield features are not.

## Traceability

53/53 v1.3 requirements mapped to phases. Coverage: 100%. No orphans.

| Requirement | Phase | Status |
|-------------|-------|--------|
| APP-01 | Phase 13 — App De-Commercialization | Pending |
| APP-02 | Phase 13 — App De-Commercialization | Pending |
| APP-03 | Phase 13 — App De-Commercialization | Pending |
| APP-04 | Phase 13 — App De-Commercialization | Pending |
| APP-05 | Phase 13 — App De-Commercialization | Pending |
| APP-06 | Phase 13 — App De-Commercialization | Pending |
| APP-07 | Phase 13 — App De-Commercialization | Pending |
| APP-08 | Phase 13 — App De-Commercialization | Pending |
| APP-09 | Phase 13 — App De-Commercialization | Pending |
| APP-10 | Phase 13 — App De-Commercialization | Pending |
| APP-11 | Phase 13 — App De-Commercialization | Pending |
| APP-12 | Phase 13 — App De-Commercialization | Pending |
| APP-13 | Phase 13 — App De-Commercialization | Pending |
| APP-14 | Phase 13 — App De-Commercialization | Pending |
| APP-15 | Phase 13 — App De-Commercialization | Pending |
| REPO-01 | Phase 14 — App Repo OSS Surface | Complete |
| REPO-02 | Phase 14 — App Repo OSS Surface | Complete |
| REPO-03 | Phase 14 — App Repo OSS Surface | Complete |
| REPO-04 | Phase 14 — App Repo OSS Surface | Complete |
| REPO-05 | Phase 14 — App Repo OSS Surface | Complete |
| REPO-06 | Phase 14 — App Repo OSS Surface | Complete |
| REPO-07 | Phase 14 — App Repo OSS Surface | Complete |
| REPO-08 | Phase 14 — App Repo OSS Surface | Complete |
| REPO-09 | Phase 14 — App Repo OSS Surface | Complete |
| REPO-10 | Phase 14 — App Repo OSS Surface | Complete |
| REPO-11 | Phase 14 — App Repo OSS Surface | Complete |
| REPO-12 | Phase 14 — App Repo OSS Surface | Complete |
| LAND-01 | Phase 15 — Landing Repo OSS Surface | Complete |
| LAND-02 | Phase 15 — Landing Repo OSS Surface | Complete |
| LAND-03 | Phase 15 — Landing Repo OSS Surface | Complete |
| LAND-04 | Phase 15 — Landing Repo OSS Surface | Complete |
| LAND-05 | Phase 15 — Landing Repo OSS Surface | Complete |
| REL-01 | Phase 16 — Signed-DMG Release Pipeline | Complete |
| REL-02 | Phase 16 — Signed-DMG Release Pipeline | Complete |
| REL-03 | Phase 16 — Signed-DMG Release Pipeline | Complete |
| REL-04 | Phase 16 — Signed-DMG Release Pipeline | Complete |
| REL-05 | Phase 16 — Signed-DMG Release Pipeline | Complete |
| REL-06 | Phase 16 — Signed-DMG Release Pipeline | Complete |
| SITE-01 | Phase 17 — Landing Page Repositioning | Complete |
| SITE-02 | Phase 17 — Landing Page Repositioning | Complete |
| SITE-03 | Phase 17 — Landing Page Repositioning | Complete |
| SITE-04 | Phase 17 — Landing Page Repositioning | Complete |
| SITE-05 | Phase 17 — Landing Page Repositioning | Complete |
| SITE-06 | Phase 17 — Landing Page Repositioning | Complete |
| SITE-07 | Phase 17 — Landing Page Repositioning | Complete |
| SITE-08 | Phase 17 — Landing Page Repositioning | Complete |
| SITE-09 | Phase 17 — Landing Page Repositioning | Complete |
| SITE-10 | Phase 17 — Landing Page Repositioning | Complete |
| FLIP-01 | Phase 18 — Public Flip + v1.3.0 Release | Pending |
| FLIP-02 | Phase 18 — Public Flip + v1.3.0 Release | Pending |
| FLIP-03 | Phase 18 — Public Flip + v1.3.0 Release | Pending |
| FLIP-04 | Phase 18 — Public Flip + v1.3.0 Release | Pending |
| FLIP-05 | Phase 18 — Public Flip + v1.3.0 Release | Pending |

**By phase totals:**

| Phase | REQ-IDs | Count |
|-------|---------|-------|
| 13. App De-Commercialization | APP-01…15 | 15 |
| 14. App Repo OSS Surface | REPO-01…12 | 12 |
| 15. Landing Repo OSS Surface | LAND-01…05 | 5 |
| 16. Signed-DMG Release Pipeline | REL-01…06 | 6 |
| 17. Landing Page Repositioning | SITE-01…10 | 10 |
| 18. Public Flip + v1.3.0 Release | FLIP-01…05 | 5 |
| **Total** | — | **53** |

---

*Requirements defined: 2026-05-19*
*Last updated: 2026-05-19 — v1.3 roadmap mapped (Phases 13–18; 53/53 REQ-IDs); Traceability section populated.*
