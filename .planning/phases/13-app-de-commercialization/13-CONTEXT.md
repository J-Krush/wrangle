# Phase 13: App De-Commercialization - Context

**Gathered:** 2026-05-19
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 13 strips every paid-trial / paywall / license surface from the Wrangle app
binary and replaces the gated-launch experience with a one-time, dismissable
"Wrangle is now free and open source — star us on GitHub" surface delivered via
the existing `WhatsNewView` mechanism.

After this phase the app:

1. Opens directly to the editor on launch with no gate, no banner, no nag — no
   `LicenseGateView`, no `TrialBannerView`, no Preferences → License tab.
2. Surfaces a one-time v1.3.0 "free + open source" note via `WhatsNewView` on
   the first launch where `WhatsNewManager.lastSeenVersion < "1.3.0"`. The note
   carries a "Star on GitHub" CTA that opens
   `https://github.com/J-Krush/wrangle` in the user's default browser. The
   modal stays open until the user taps "Continue".
3. Contains no `LicenseManager`, `LicenseGateView`, `TrialBannerView`,
   `LicenseSettingsView`, `scripts/reset-license.sh`, `wrangleapp.dev/api/trial/*`
   references, or `LemonSqueezy` references in product copy or runtime code
   paths. APP-13 grep passes.
4. Actively wipes the residue v1.2 left behind: Keychain services
   `dev.wrangle.license` and `dev.wrangle.trial`, plus the
   `LicenseManager.instanceID` UserDefaults key, on the same lastSeenVersion
   trigger that gates the OSS note. Idempotent — first v1.3 launch only.
5. Repoints `UpdateChecker` from `wrangleapp.dev/api/version.json` to
   `https://api.github.com/repos/J-Krush/wrangle/releases/latest`. The About
   panel surfaces both `wrangleapp.dev` and `github.com/J-Krush/wrangle` as
   clickable credits links.

What Phase 13 does NOT deliver:

- **Repo OSS surface** (`LICENSE`, `README.md`, `CONTRIBUTING.md`, issue / PR
  templates, screenshots, secrets sweep) — Phase 14.
- **Signed-DMG release pipeline** — Phase 16.
- **Landing-page repositioning** — Phase 17.
- **Public flip** — Phase 18.
- **No new product features**, no schema migrations, no UI redesign. This is a
  surgical strip + a tiny new modal entry.

</domain>

<decisions>
## Implementation Decisions

### OSS one-time surface (APP-11)

- **D-01**: Reuse `WhatsNewView`. Extend `ChangelogEntry` in
  `wrangle/App/WhatsNewChangelog.swift` with an optional CTA value
  (label + URL). Existing v1.1.x / v1.2.0 entries leave it `nil`; v1.3.0
  uses it.

- **D-02**: Add a v1.3.0 entry to `WhatsNewChangelog.entries` with **one bullet
  only**: `"Wrangle is now free and open source."` Category is `.new`. Date
  string follows existing format (e.g., `"May 19, 2026"` or the actual ship
  date). No "Improved" or "Fixed" sections — the entry exists to deliver the
  OSS announcement, not summarize internal refactors.

- **D-03**: CTA on the v1.3.0 entry: label `"Star on GitHub"`, URL
  `https://github.com/J-Krush/wrangle`. Rendered via SwiftUI `Link` (which uses
  `NSWorkspace.shared.open` under the hood) — opens the URL in the user's
  default browser, NOT in Wrangle's embedded WKWebView. Suggested visual:
  `.buttonStyle(.borderedProminent)` next to (not replacing) the existing
  "Continue" button at the bottom of the entry. Planner picks exact layout.

- **D-04**: Modal dismissal — tapping the CTA opens the URL externally but
  does NOT auto-close the WhatsNew modal. The user dismisses by tapping
  "Continue", which routes through the existing `WhatsNewManager.dismiss()`
  and writes `lastSeenVersion = currentVersion`.

- **D-05**: Fresh-install filter — `WhatsNewManager.checkOnLaunch()` /
  `visibleEntries` must filter auto-shown entries to `version >= "1.3.0"` when
  `lastSeenVersion == "0.0.0"`. Older entries (v1.1.x, v1.2.0) stay in
  `WhatsNewChangelog.entries` so the existing "Help → What's New" command
  (which sets `showAll = true`) can still backfill them on demand. The filter
  applies only to the launch-triggered modal, not to `showAll` mode.

### First-launch trigger (APP-11)

- **D-06**: Reuse the existing `WhatsNewManager.lastSeenVersion`
  (UserDefaults key `"WhatsNewManager.lastSeenVersion"`) as the single gate.
  No new UserDefaults key, no schema bump, no new manager. APP-11's
  "first launch of v1.3 against an upgraded SwiftData store" is interpreted
  semantically as "first launch where `lastSeenVersion < "1.3.0"`" — schema
  bumping is rejected because the SwiftData schema (Bookmarks, Projects,
  history, downloads) is orthogonal to license data and bumping it destroys
  unrelated user content.

- **D-07**: WhatsNewView's existing predicate
  `if !coordinator.licenseManager.needsLicense && manager.shouldShowModal`
  has the `!licenseManager.needsLicense` clause **removed** — collapses to
  `if manager.shouldShowModal`.

- **D-08**: NotificationPermissionView's existing predicate
  `if !coordinator.licenseManager.needsLicense && manager.shouldShowModal`
  has the license clause removed AND gains a
  `&& !coordinator.whatsNewManager.shouldShowModal` clause so WhatsNew wins
  when both could fire on the same launch. NotificationPermission fires next
  launch after WhatsNew dismisses (or on session foreground refresh if
  WhatsNew was dismissed mid-session).

### `wrangleapp.dev` disposition

- **D-09**: `UpdateChecker.versionEndpoint` switches from
  `"https://wrangleapp.dev/api/version.json"` to
  `"https://api.github.com/repos/J-Krush/wrangle/releases/latest"`. Response
  parsing changes from the bespoke `VersionInfo` struct (`version` /
  `downloadURL` / `releaseNotes`) to a GitHub Releases shape: `tag_name`
  (strip leading `v` if present), `html_url` (used as download URL — the
  Release page itself), and `body` (Markdown release notes). The DMG itself
  lives under `assets[]` — finding the `.dmg` asset's `browser_download_url`
  is OPTIONAL; opening the Release `html_url` is sufficient for v1.3.

- **D-10**: Pre-public-flip (Phases 13–17), `api.github.com/repos/J-Krush/wrangle`
  returns 404 because the repo is still private. `UpdateChecker.performCheck`
  already swallows network errors silently for the non-manual path. Manual
  "Check for Updates..." in About menu will set `showUpToDate = true` (because
  the catch falls through). This is acceptable — the manual command is mostly
  used by the developer, who already knows what's available. Phase 18 makes
  the endpoint live.

- **D-11**: `UpdateChecker.openDownloadPage` opens the Release `html_url`
  directly. No fallback to `wrangleapp.dev/download` — that constant is
  deleted.

- **D-12**: About panel credits (in `wrangleApp.swift:165-183`) — the
  NSAttributedString gains a second link line. Layout:
  ```
  Made by Krush
  wrangleapp.dev  •  github.com/J-Krush/wrangle
  ```
  Both clickable via `NSAttributedString.Key.link`. Spacing / separator
  character is Claude's discretion (· or • or `\n`); follow the existing
  `.font: NSFont.systemFont(ofSize: 11)` styling.

### License Keychain residue cleanup (additional clean-up beyond APP-01..15)

- **D-13**: A new helper performs a one-time wipe of:
  - `SecItemDelete` for service `"dev.wrangle.license"` / account
    `"license-key"` (matches the previous `LicenseManager.keychainService` /
    `LicenseManager.keychainAccount` constants).
  - `SecItemDelete` for service `"dev.wrangle.trial"` / account
    `"trial-data"` (matches `LicenseManager.trialKeychainService` /
    `LicenseManager.trialKeychainAccount`).
  - `UserDefaults.standard.removeObject(forKey: "LicenseManager.instanceID")`.

  Gated by the same `WhatsNewManager.lastSeenVersion < "1.3.0"` predicate as
  the OSS note — runs once, on the first v1.3 launch for a v1.2 user, and is
  a no-op for fresh installs (no Keychain entries to remove). Both
  `SecItemDelete` calls treat `errSecItemNotFound` as success.

- **D-14**: File layout — new file `wrangle/App/LicenseResidueCleanup.swift`
  (one `@MainActor` enum or static helper function). Called from
  `wrangleApp.swift` `onAppear` in the same setup block that already calls
  `licenseManager.loadOnLaunch()` (which is being removed in this phase).
  Specifically: after `coordinator.updateChecker.checkForUpdate()` and before
  `coordinator.whatsNewManager.checkOnLaunch()` — so cleanup runs FIRST, then
  WhatsNew gets to surface the OSS note. WhatsNew check must NOT dismiss
  lastSeenVersion until the user explicitly taps Continue, so the cleanup
  happening before the modal appears is fine — both keyed on the same
  `lastSeenVersion < "1.3.0"` snapshot.

### Claude's Discretion

- Exact CTA button styling in `WhatsNewEntryView` — `.buttonStyle(.borderedProminent)`
  vs `.bordered` vs a custom tinted style; whether it appears inline at the
  bottom of the entry or absolutely positioned. Match the existing modal's
  visual weight (the current "Continue" button uses `.borderedProminent`; a
  per-entry CTA could be `.bordered` with a tint so it reads as distinct).
- Whether the optional CTA on `ChangelogEntry` is a single property
  (`cta: (label: String, url: URL)?`) or a small `ChangelogCTA` struct.
- Exact wording of the v1.3.0 bullet — Decision D-02 fixes it as
  `"Wrangle is now free and open source."` but planner may inflate to
  `"Wrangle is now free and open source — thank you for the support."` if
  that reads better next to the CTA. Stay one line; do not list paywall
  removals.
- Exact NSAttributedString layout for the About panel credits — D-12 fixes
  the content (both links present) and the font; line break vs. inline
  separator is the planner's call.
- `UpdateChecker` GitHub response struct naming, decoding strategy (custom
  `Decodable` init vs `JSONDecoder` keyDecodingStrategy), and whether to
  parse `assets[]` for a `.dmg`-specific URL or just open the Release page.
- Whether `LicenseResidueCleanup` is an `enum` with a static `run()` method,
  a free function, or extends `AppCoordinator` — pick what fits the codebase
  style. Single call site, ~15 lines.
- Whether the LicenseResidueCleanup module owns its own UserDefaults gate
  (independent of WhatsNew's `lastSeenVersion`) or reads `lastSeenVersion`
  directly. If the latter, comment why: a v1.2 user's lastSeen is "1.1.1" or
  "1.2.0"; running cleanup just before `WhatsNewManager.checkOnLaunch` reads
  the same UserDefault — both make their decision off the same snapshot,
  then dismiss() updates it.
- SettingsView TabView wrapper after License tab removal — keep TabView (now
  with only General) for forward-compat, or collapse to bare
  `GeneralSettingsView`. Either is acceptable; collapsing is slightly cleaner
  but TabView preserves the menu-bar title that AppKit gives to multi-tab
  Settings windows.
- Whether the outer `VStack(spacing: 0)` in `ContentView.swift:42-187` —
  which wraps `TrialBannerView()` + the main `HStack` — collapses to just the
  `HStack` after `TrialBannerView` is removed, or stays as-is for future
  banner insertion. No correctness issue either way.
- Whether to write a smoke unit test for `WhatsNewManager` fresh-install
  filter (D-05) and `LicenseResidueCleanup.run()` idempotency. User
  preference is unit-test priority (`feedback_testing_priority`); planner
  budgets one small test file for these two units.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone requirements

- `.planning/REQUIREMENTS.md` §APP-01 through §APP-15 — the 15 requirements this
  phase satisfies (1-to-1 with Phase 13).
- `.planning/ROADMAP.md` §Phase 13 — Goal, Depends-on (none), Success Criteria
  (5 rows), Plans (2 expected).
- `.planning/PROJECT.md` §Current Milestone v1.3 — the milestone-level narrative
  (OSS conversion as a portfolio piece; Product Hunt + Reddit ads context).

### Prior-phase decisions that flow through (Wrangle context, not v1.3)

- `.planning/phases/12-section-parity-polish/12-CONTEXT.md` — most recent
  `discuss-phase` output. Establishes the prevailing code style for new
  Swift files (e.g., `Storage Keys`-style constant enums in
  `wrangle/Components/`). This phase doesn't directly touch those surfaces
  but follows the established `@MainActor` + `@Observable` + small focused
  file pattern.

### Code surfaces the phase must touch

**Files to delete outright (APP-01..05)**
- `wrangle/App/LicenseManager.swift` — deletion (APP-01).
- `wrangle/App/LicenseGateView.swift` — deletion (APP-02).
- `wrangle/App/TrialBannerView.swift` — deletion (APP-03).
- `wrangle/App/LicenseSettingsView.swift` — deletion (APP-04).
- `scripts/reset-license.sh` — deletion (APP-05).

**Files to edit — license plumbing strip**
- `wrangle/App/AppCoordinator.swift:12` — remove
  `var licenseManager = LicenseManager()` (APP-06).
- `wrangle/wrangleApp.swift:118` — remove
  `coordinator.licenseManager.loadOnLaunch()` (APP-07).
- `wrangle/wrangleApp.swift:173-177` — replace the `wrangleapp.dev`
  NSAttributedString credits with dual-link layout per D-12.
- `wrangle/ContentView.swift:43` — remove `TrialBannerView()`. Outer
  `VStack(spacing: 0)` may collapse; see Claude's discretion (D-15? no — see
  list above).
- `wrangle/ContentView.swift:187` — remove the trailing `} // outer VStack`
  comment if the VStack collapses; leave it if VStack stays.
- `wrangle/ContentView.swift:203` — remove `LicenseGateView()` (APP-02).
- `wrangle/App/SettingsView.swift:20-25` — remove the License tab
  declaration (`LicenseSettingsView()` + its `.tabItem` + `.tag(.license)`).
  Also remove `case license` from the `SettingsTab` enum at line 5 (APP-04).
- `wrangle/App/AppCoordinator.swift` — remove `var selectedSettingsTab`
  references to `.license` (the property stays; only the enum case
  goes — `case license` removal cascades).
- `wrangle/App/WhatsNewView.swift:9` — remove
  `!coordinator.licenseManager.needsLicense &&` from the predicate (D-07).
- `wrangle/App/NotificationPermissionView.swift:9` — remove the license
  clause and add `&& !coordinator.whatsNewManager.shouldShowModal` (D-08).

**Files to edit — OSS note surface (APP-10, APP-11)**
- `wrangle/App/WhatsNewChangelog.swift` — extend `ChangelogEntry` with the
  optional CTA (D-01), prepend a v1.3.0 entry per D-02 + D-03.
- `wrangle/App/WhatsNewView.swift:48-89` (`WhatsNewEntryView`) — render the
  CTA `Link` when `entry.cta != nil`.
- `wrangle/App/WhatsNewManager.swift:35-39` — add the fresh-install filter to
  `visibleEntries` per D-05 (only when `lastSeen == "0.0.0"` — apply the
  `>= "1.3.0"` guard).

**Files to edit — `wrangleapp.dev` repoint**
- `wrangle/App/UpdateChecker.swift:12` — swap `versionEndpoint` to
  `https://api.github.com/repos/J-Krush/wrangle/releases/latest`.
- `wrangle/App/UpdateChecker.swift:27` — open `downloadURL` (the Release
  `html_url`) directly; drop the `wrangleapp.dev/download` fallback (D-11).
- `wrangle/App/UpdateChecker.swift:79-91` — replace `VersionInfo` struct with
  the GitHub Releases response shape (`tag_name`, `html_url`, `body`, etc.)
  per D-09.

**New file**
- `wrangle/App/LicenseResidueCleanup.swift` — one-time wipe per D-13 / D-14.

**Files to verify (APP-13 grep)**
- Grep the full `wrangle/` and `scripts/` trees for: `"$24"`, `"Buy"`,
  `"Trial"` / `"trial"`, `"License"` / `"license"` (excluding the future
  repo-root `LICENSE` file and Apple-framework type names like
  `WKWebsiteDataStore`), `"wrangleapp.dev"`, `"LemonSqueezy"` /
  `"lemonsqueezy"`. Document remaining hits in SUMMARY (expected: `LICENSE`
  file at repo root once Phase 14 lands; `wrangleapp.dev` in About panel
  credits per D-12 — counted as a deliberate post-strip survival).

**Files audited but no change required (APP-12)**
- `wrangle/App/NotificationPermissionView.swift` body copy — "Stay in the
  Loop" / Claude Code notification messaging is unrelated to trial / paywall;
  no edits needed beyond D-08's predicate change.

### Documents to (NOT) write in this phase

- `LICENSE` (repo root MIT) — Phase 14, NOT this phase.
- `README.md`, `CONTRIBUTING.md`, `SECURITY.md`, `.github/` templates —
  Phase 14, NOT this phase.
- `docs/release.md` / `scripts/build-release.sh` — Phase 16.

### Info.plist / entitlements (APP-14)

- `Wrangle/Info.plist` and `wrangle/Info.plist` — grep confirmed clean of
  license / trial / URL-scheme / feature-flag entries. APP-14 is satisfied
  by verification (read both, confirm). No edits expected.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- **`WhatsNewView` overlay pattern** — already mounted in `ContentView.swift`
  `.overlay { … WhatsNewView() … }` at line 205. The OSS note rides on this
  exact path. Modal + scrim + .regularMaterial card + Continue button all
  reusable; only the per-entry CTA is new.
- **`WhatsNewManager.checkOnLaunch()` + lastSeenVersion gating** —
  already implements semantic version comparison (`isVersion(_:newerThan:)`)
  and one-shot dismiss. The OSS note inherits this for free; only the
  fresh-install filter (D-05) is added.
- **`Bundle.main.infoDictionary?["CFBundleShortVersionString"]`** — already
  used by WhatsNewManager + UpdateChecker. The v1.3 build's bundle version
  drives both surfaces.
- **`SecItemDelete` + Keychain query dictionaries** — pattern already
  established in `LicenseManager.removeKeyFromKeychain` /
  `removeTrialFromKeychain`. `LicenseResidueCleanup` lifts the same
  pattern with the same service + account keys.
- **`NSAttributedString` link-bearing credits** — `wrangleApp.swift:166-183`
  already shows the pattern for clickable About-panel links. D-12 just adds
  one more `append(NSAttributedString(string: ..., attributes: [.link: ...]))`.

### Established Patterns

- **`@MainActor` `@Observable` managers** owned by `AppCoordinator`:
  `updateChecker`, `licenseManager` (removed), `notificationManager`,
  `whatsNewManager`. `LicenseResidueCleanup` is intentionally a one-shot
  helper, NOT a long-lived `@Observable` — it has no state to publish.
- **`WhatsNewManager.lastSeenVersion`** is the canonical first-launch /
  version-bump signal in the codebase. New first-launch surfaces (including
  cleanup-once) read it directly rather than introducing parallel
  UserDefaults keys, per the prior pattern.
- **Modal overlay z-stacking** — `ContentView.swift:196-206` overlay order
  is `FuzzyFinder` → `GlobalSearch` → `LicenseGateView` (removed) →
  `NotificationPermissionView` → `WhatsNewView`. With LicenseGateView gone
  and D-08's predicate, WhatsNew renders above NotificationPermission both
  by z-order and by predicate gating.

### Integration Points

- `wrangleApp.swift` `onAppear` block (lines 110-121) is the launch-once
  setup point. `LicenseResidueCleanup.run()` slots in there, before
  `whatsNewManager.checkOnLaunch()` (D-14). `coordinator.licenseManager.loadOnLaunch()`
  line goes away with `LicenseManager` deletion.
- `AppCoordinator` shrinks by one property (`licenseManager`). Other call
  sites (`WhatsNewView`, `NotificationPermissionView`, `LicenseSettingsView`)
  all stop referencing it.
- `SettingsView` `selectedSettingsTab` binding now only has `.general` as a
  valid case after `.license` is removed from the enum; default
  initialization at `AppCoordinator.swift:15` already uses `.general`.

### Code Hotspots / Complexity

- **`UpdateChecker` GitHub response parsing** — minor risk: GitHub's
  Releases API returns 404 for private repos (current state through
  Phase 17), so the manual "Check for Updates..." command will say "Up to
  date" even when there might be a draft Release. Acceptable for the
  upgrade window; document the behavior in SUMMARY.
- **`WhatsNewManager.visibleEntries` fresh-install filter** — must apply
  ONLY to the launch-triggered modal, NOT to `showAll` mode (`Help →
  What's New`). Existing flow: `showAll = true` short-circuits the version
  filter and returns all entries. D-05's new filter sits inside the
  `!showAll` branch.
- **`LicenseResidueCleanup` ordering vs WhatsNew** — Both gate off
  `lastSeenVersion < "1.3.0"`. Cleanup runs first (line ~118 in
  `wrangleApp.swift`), then WhatsNew sets `shouldShowModal = true`, then
  user eventually taps Continue, which writes `lastSeenVersion = "1.3.0"`.
  If the app crashes between cleanup and WhatsNew dismiss, the next
  launch will re-run cleanup — but `SecItemDelete` on an already-deleted
  Keychain item returns `errSecItemNotFound`, which is the no-op success
  case. Idempotent.

</code_context>

<specifics>
## Specific Ideas

- **OSS note copy is deliberately one line** — D-02 fixes the bullet at
  `"Wrangle is now free and open source."` Planner / writer may tighten or
  loosen punctuation but should NOT inflate it into a list of paywall
  removals. The CTA is the action; the bullet is the announcement.
- **CTA label is "Star on GitHub"** — D-03. Not "View on GitHub", not
  "Open Repository". The verb is the desired action.
- **CTA URL is `https://github.com/J-Krush/wrangle` exactly** — the repo
  root, not `/stargazers` or `/blob/main/README.md`. GitHub's UI surfaces
  the star button prominently on the root page.
- **No new UserDefaults / Keychain keys introduced** — entire phase reuses
  `WhatsNewManager.lastSeenVersion`. The cleanup helper reads
  pre-existing keys to delete them, then never writes anything.
- **APP-13 grep — `wrangleapp.dev` is NOT in the forbidden list.** The grep
  forbids `$24`, `Buy`, `Trial`, `trial`, `License`, `license` (excluding
  `LICENSE` repo file + Apple-framework type names). `wrangleapp.dev`
  surviving in the About panel (D-12) is consistent with that requirement.
  Document the surviving instance in SUMMARY so the audit is auditable.
- **Apple-framework `License` / `license` exemption**: code-search may turn
  up `WKWebsiteDataStore`, `URLSessionConfiguration` Trial/License
  substrings inside Swift framework types. The grep exemption is
  intentional. Planner produces a manually-reviewed list.

</specifics>

<deferred>
## Deferred Ideas

- **`LICENSE` file at repo root + MIT attribution** — Phase 14 (REPO-01).
- **`README.md` story, screenshots, build-from-source, contributing block** —
  Phase 14 (REPO-02 / REPO-03 / REPO-07).
- **`.github/ISSUE_TEMPLATE/*` + `PULL_REQUEST_TEMPLATE.md`** — Phase 14
  (REPO-04 / REPO-05 / REPO-06).
- **`SECURITY.md`** — Phase 14 (REPO-10).
- **`CLAUDE.md` open-source header + Contributors pointer** — Phase 14
  (REPO-11).
- **Signed-DMG / notarize / staple pipeline + `scripts/build-release.sh` +
  `docs/release.md`** — Phase 16.
- **Landing page reposition / Buy → Free OSS CTA / Story section / GitHub
  link** — Phase 17.
- **Public flip (repos private → public, v1.3.0 Release published)** —
  Phase 18.
- **GitHub Actions release automation** — v1.4 milestone (already noted
  out-of-scope in REQUIREMENTS.md).
- **Removing `wrangleapp.dev` link from About panel entirely** — deferred;
  the landing page survives Phase 17 as the public-facing surface.
  Reconsider if Phase 17 redirects `wrangleapp.dev` away from a
  Wrangle-branded destination.
- **`UpdateChecker` parses `assets[]` for the specific `.dmg`
  `browser_download_url`** — D-09 leaves opening the Release `html_url`
  as the v1.3 behavior. Promote to direct-DMG-download if Phase 18's
  Release attaches a single canonical DMG name.
- **Custom in-app "OSS announcement" sheet separate from WhatsNew** —
  rejected (D-01). Revisit only if WhatsNew evolves in a direction that
  makes the dual-purpose use awkward.
- **Migrating existing paid customers** — out-of-scope per REQUIREMENTS.md
  / PROJECT.md. The v1.3 build's behavior for a v1.2 license-key holder
  is: editor opens, OSS note fires once, license-key Keychain entry is
  silently wiped. No refund flow, no notification.
- **Removing UpdateChecker entirely** — considered (more
  "GitHub-first OSS app" identity), rejected this phase to keep scope
  surgical. Existing in-app update prompt is a low-maintenance feature.

</deferred>

---

*Phase: 13-app-de-commercialization*
*Context gathered: 2026-05-19*
