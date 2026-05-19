# Phase 13: App De-Commercialization - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-19
**Phase:** 13-app-de-commercialization
**Areas discussed:** OSS note surface, First-launch trigger, wrangleapp.dev disposition, License keychain residue

---

## OSS note surface

### Q1 — How should the one-time "now free + open source — star us on GitHub" surface ship in v1.3?

| Option | Description | Selected |
|--------|-------------|----------|
| Extend WhatsNew + CTA | Add an optional CTA button per ChangelogEntry. v1.3.0 entry uses it; existing entries don't. ~10 LOC. | ✓ |
| Bespoke one-off sheet | New OSSReleaseNoteView struct, separate overlay, separate @AppStorage. | |
| Inline GitHub URL only | v1.3.0 entry's bullet contains plain-text github URL, no clickable button. | |
| Extend WhatsNew + Link bullet | Upgrade WhatsNewEntryView so bullet items can be tappable Links. | |

**User's choice:** Extend WhatsNew + CTA (Recommended).
**Notes:** Reuses the existing overlay z-stack and version-bump gating. Preserves the pattern for future per-entry CTAs.

### Q2 — When the user taps the v1.3.0 entry's CTA, where should github.com/J-Krush/wrangle open?

| Option | Description | Selected |
|--------|-------------|----------|
| Default browser | SwiftUI Link / NSWorkspace.shared.open. Standard external-link behavior. | ✓ |
| Embedded Wrangle browser tab | appState.openBrowser(url:) — opens new WKWebView tab in-app. | |
| User decides at runtime | Two buttons: "Open in Browser" + "Open in Default Browser". | |

**User's choice:** Default browser (Recommended).
**Notes:** Gets the user into the browser session where they're already signed into GitHub.

### Q3 — What should the v1.3.0 WhatsNew entry contain when an existing v1.2 user upgrades?

| Option | Description | Selected |
|--------|-------------|----------|
| OSS-only entry, single line | One bullet: "Wrangle is now free and open source." CTA: "Star on GitHub". | ✓ |
| OSS entry + a couple v1.3 release notes | OSS bullet + 1–2 "removed trial / removed License preferences" supporting bullets. | |
| Full release-note entry | Treat v1.3.0 like every other release: New/Improved/Fixed sections. | |

**User's choice:** OSS-only entry, single line (Recommended).
**Notes:** The entry exists to deliver the announcement, not list internal refactors.

### Q4 — What should a brand-new v1.3 user (downloads DMG, never ran prior version) see on first launch?

| Option | Description | Selected |
|--------|-------------|----------|
| Only v1.3.0 entry | Suppress legacy v1.1.x / v1.2.0 entries when lastSeen == "0.0.0". | ✓ |
| Suppress modal entirely on fresh install | If lastSeen == "0.0.0", skip the modal completely. | |
| Show everything as before | lastSeen "0.0.0" fires full v1.1.x → v1.3.0 backlog. | |
| Only v1.3.0 + delete old entries from code | Cleaner code; loses changelog history backfill. | |

**User's choice:** Only v1.3.0 entry (Recommended).
**Notes:** Older entries stay in WhatsNewChangelog.entries for "Help → What's New (showAll)" backfill; only auto-shown modal is filtered.

---

## First-launch trigger

### Q5 — What gates the first-launch OSS surface for a v1.2 user upgrading to v1.3?

| Option | Description | Selected |
|--------|-------------|----------|
| Reuse WhatsNew lastSeenVersion | No new UserDefaults key, no schema bump, no new manager. | ✓ |
| Dedicated UserDefaults flag | New key OSSNoteShown.1.3.0 — independent from WhatsNew. | |
| SwiftData schema bump trigger | Bump currentSchemaVersion 3 → 4 — destroys unrelated SwiftData. | |

**User's choice:** Reuse WhatsNew lastSeenVersion (Recommended).
**Notes:** APP-11's "first launch against an upgraded SwiftData store" reinterpreted semantically — license data is in Keychain, not SwiftData; bumping schema for a cosmetic version trigger is unjustified collateral damage.

### Q6 — After the user taps "Star on GitHub" (opens external browser), what happens to the modal?

| Option | Description | Selected |
|--------|-------------|----------|
| Stays open until Continue | Modal persists; user dismisses via Continue. dismiss() writes lastSeenVersion. | ✓ |
| Auto-dismiss on CTA tap | CTA opens GitHub AND calls dismiss(). | |
| User decides per click | Three buttons including "Star + Dismiss". | |

**User's choice:** Stays open until Continue (Recommended).
**Notes:** Lets the user star + come back + re-read the bullet.

### Q7 — If both WhatsNew (v1.3.0 entry) and NotificationPermission modals could fire on the same launch, which wins?

| Option | Description | Selected |
|--------|-------------|----------|
| Both can show; WhatsNew priority | NotificationPermissionView checks `&& !whatsNewManager.shouldShowModal`. | ✓ |
| Both can show simultaneously | No ordering; z-stack via overlay declaration order. | |
| Only WhatsNew on first v1.3 launch; defer notif prompt | Suppress notif modal when WhatsNew has shouldShowModal AND lastSeen < current. | |

**User's choice:** Both can show; WhatsNew priority (Recommended).
**Notes:** Notification prompt fires next launch (or on session foreground refresh) after WhatsNew dismisses.

---

## wrangleapp.dev disposition

### Q8 — UpdateChecker today pings `wrangleapp.dev/api/version.json` on launch. What should v1.3 do?

| Option | Description | Selected |
|--------|-------------|----------|
| Switch to GitHub Releases API | api.github.com/repos/J-Krush/wrangle/releases/latest. Removes wrangleapp.dev dep. | ✓ |
| Leave UpdateChecker pointed at wrangleapp.dev | Tight phase boundary; binary still has a non-OSS dependency. | |
| Delete UpdateChecker entirely | OSS apps typically don't ship in-app updaters. | |

**User's choice:** Switch to GitHub Releases API (Recommended).
**Notes:** Pre-flip (Phases 13–17), the endpoint returns 404 — graceful silent fail. Post-flip works.

### Q9 — What replaces the About panel's 'wrangleapp.dev' clickable link?

| Option | Description | Selected |
|--------|-------------|----------|
| Both: website + GitHub | Credits get two lines: wrangleapp.dev + github.com/J-Krush/wrangle. | ✓ |
| GitHub only | Replace wrangleapp.dev with github URL — sharpens OSS identity, bypasses landing page. | |
| wrangleapp.dev only (unchanged) | Leave About panel as-is. | |

**User's choice:** Both: website + GitHub (Recommended).
**Notes:** Landing page survives Phase 17 as marketing surface; About surfaces source repo too.

---

## License keychain residue

### Q10 — v1.2 wrote license keys + trial data to Keychain (services `dev.wrangle.license` + `dev.wrangle.trial`). v1.3 has no LicenseManager to read them. What do we do?

| Option | Description | Selected |
|--------|-------------|----------|
| Active one-time wipe on launch | New KeychainCleanup helper; SecItemDelete both services; gated on lastSeen < 1.3.0. | ✓ |
| Leave residue (no code) | v1.2 entries are orphaned bytes; macOS Keychain Access still shows them. | |
| Delete trial data only | Wipe `dev.wrangle.trial` (had email/expiry) but keep license keys (user-owned). | |

**User's choice:** Active one-time wipe on launch (Recommended).
**Notes:** ~15 LOC; aligns with "open source from the ground up" identity; idempotent (SecItemDelete on missing is no-op success).

### Q11 — Wipe the UserDefaults key `LicenseManager.instanceID` (random LemonSqueezy device UUID) too?

| Option | Description | Selected |
|--------|-------------|----------|
| Wipe instanceID too | Same cleanup path — removeObject(forKey: "LicenseManager.instanceID"). | ✓ |
| Leave it (harmless UUID) | Random UUID, no PII; ignore. | |

**User's choice:** Wipe instanceID too (Recommended).
**Notes:** Total cleanup surface: 2 Keychain services + 1 UserDefaults key.

---

## Claude's Discretion

User explicitly declined to lock the following during the "I'm ready for context" check; they are noted in CONTEXT.md `<decisions>` → Claude's Discretion for planner-level resolution:

- Plan split (2 vs 1) — ROADMAP suggests 2; planner can collapse if dependency analysis justifies.
- KeychainCleanup helper file layout (enum vs static fn vs AppCoordinator extension).
- Test scope (smoke unit tests for WhatsNewManager fresh-install filter and LicenseResidueCleanup idempotency suggested but not mandated).
- SettingsView TabView wrapper after License tab removal (keep vs collapse).
- ContentView outer VStack collapse after TrialBannerView removal.
- Exact NSAttributedString layout for About panel dual link (separator, line break).
- CTA button styling in WhatsNewEntryView (borderedProminent vs bordered + tint).
- ChangelogEntry CTA modeling (tuple vs small struct).
- UpdateChecker GitHub response decoding strategy.

## Deferred Ideas

All deferred ideas captured in CONTEXT.md `<deferred>`. Highlights:

- Repo-root LICENSE, README, CONTRIBUTING, .github/ templates → Phase 14
- Signed-DMG pipeline + build-release.sh + docs/release.md → Phase 16
- Landing-page reposition → Phase 17
- Public flip (private → public) → Phase 18
- GitHub Actions release automation → v1.4
- Direct-DMG asset URL parsing in UpdateChecker → revisit Phase 18
- Removing UpdateChecker entirely → considered, rejected this phase
