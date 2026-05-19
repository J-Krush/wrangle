---
id: 13-02-oss-note-residue-cleanup-and-update-repoint
phase: 13-app-de-commercialization
plan: 02
type: execute
wave: 2
depends_on: [13-01-strip-license-trial-paywall]
files_modified:
  - wrangle/App/WhatsNewChangelog.swift
  - wrangle/App/WhatsNewView.swift
  - wrangle/App/WhatsNewManager.swift
  - wrangle/App/UpdateChecker.swift
  - wrangle/wrangleApp.swift
files_created:
  - wrangle/App/LicenseResidueCleanup.swift
  - wrangleTests/WhatsNewManagerTests.swift
  - wrangleTests/LicenseResidueCleanupTests.swift
autonomous: true
requirements: [APP-10, APP-11, APP-13]
objective: >
  Wire the one-time "Wrangle is now free and open source — star us on GitHub"
  WhatsNew note (CTA → GitHub), add the v1.3 first-launch Keychain residue
  cleanup helper, repoint UpdateChecker from wrangleapp.dev to GitHub
  Releases, rewrite the About-panel credits with dual `wrangleapp.dev` +
  `github.com/J-Krush/wrangle` links, ship unit tests for the two new
  units, and run the final APP-13 grep audit with the documented exemption
  list.

must_haves:
  truths:
    - "First launch where `WhatsNewManager.lastSeenVersion < \"1.3.0\"` surfaces the OSS note via the existing WhatsNew modal; subsequent launches do NOT re-surface it."
    - "The OSS note carries a 'Star on GitHub' link that opens `https://github.com/J-Krush/wrangle` in the user's default browser (not the embedded WKWebView)."
    - "Tapping the CTA opens GitHub externally; the modal dismisses ONLY when the user taps Continue (which writes `lastSeenVersion = currentVersion`)."
    - "On the same first launch, `LicenseResidueCleanup.run()` silently deletes the two known Keychain entries (`dev.wrangle.license`/`license-key`, `dev.wrangle.trial`/`trial-data`) and removes the `LicenseManager.instanceID` UserDefaults key."
    - "`UpdateChecker.versionEndpoint` resolves to `https://api.github.com/repos/J-Krush/wrangle/releases/latest`; `wrangleapp.dev` no longer appears in `UpdateChecker.swift`."
    - "About panel renders 'Made by Krush' plus two clickable links: `wrangleapp.dev` and `github.com/J-Krush/wrangle`."
    - "Final APP-13 grep audit produces zero hits for `$24`, `Buy`, `Trial`, `trial`, `License`, `license`, `LemonSqueezy` (with the documented exemption list); `wrangleapp.dev` survives only in the About-panel NSAttributedString."
  artifacts:
    - path: "wrangle/App/LicenseResidueCleanup.swift"
      provides: "One-shot helper that idempotently deletes v1.2 Keychain license + trial entries and the LicenseManager.instanceID UserDefaults key"
      contains: "enum LicenseResidueCleanup"
      exports: ["run"]
    - path: "wrangle/App/WhatsNewChangelog.swift"
      provides: "ChangelogEntry with optional CTA, plus a v1.3.0 entry carrying the Star on GitHub CTA"
      contains: "version: \"1.3.0\""
    - path: "wrangle/App/UpdateChecker.swift"
      provides: "GitHub Releases-shaped response decoding"
      contains: "api.github.com/repos/J-Krush/wrangle/releases/latest"
    - path: "wrangleTests/WhatsNewManagerTests.swift"
      provides: "Fresh-install filter unit test for visibleEntries D-05 invariant"
      min_lines: 30
    - path: "wrangleTests/LicenseResidueCleanupTests.swift"
      provides: "Idempotency unit test for LicenseResidueCleanup.run()"
      min_lines: 30
  key_links:
    - from: "wrangle/App/WhatsNewView.swift"
      to: "ChangelogEntry.cta.url"
      via: "SwiftUI Link(\"Star on GitHub\", destination: cta.url)"
      pattern: "Link\\(.*destination: .*cta"
    - from: "wrangle/wrangleApp.swift"
      to: "LicenseResidueCleanup.run()"
      via: "onAppear call before whatsNewManager.checkOnLaunch()"
      pattern: "LicenseResidueCleanup\\.run\\(\\)"
    - from: "wrangle/App/UpdateChecker.swift"
      to: "https://api.github.com/repos/J-Krush/wrangle/releases/latest"
      via: "static versionEndpoint constant"
      pattern: "api\\.github\\.com/repos/J-Krush/wrangle/releases/latest"

truths:
  - "After this phase no symbol named `licenseManager`, `LicenseManager`, `LicenseGateView`, `TrialBannerView`, `LicenseSettingsView`, or `reset-license.sh` exists in `wrangle/` or `scripts/`. (Carried from Plan 01.)"
  - "`WhatsNewManager.lastSeenVersion` is the single first-launch gate for both the OSS WhatsNew note (D-06) and `LicenseResidueCleanup` (D-13/D-14). No new UserDefaults / Keychain keys introduced."
  - "Apple-framework type names containing `License` / `Trial` substrings (e.g., none currently in scope) are excluded from APP-13 grep — exemption list documented in SUMMARY."
---

<objective>
Deliver the OSS announcement surface and the Keychain residue cleanup that
together fulfill APP-10 and APP-11; repoint `UpdateChecker` to GitHub
Releases and rewrite the About-panel credits to satisfy the D-09/D-10/D-11
and D-12 decisions; ship two small unit tests for the new units per the
user's `feedback_testing_priority` memory; close out the phase by running
the final APP-13 grep audit and documenting the exemption list.

Purpose: This plan finishes the v1.3 de-commercialization by:
1. Replacing the dead license-trial gate with a one-time "free + open
   source" announcement that drives the user to GitHub (APP-11).
2. Wiping the v1.2 Keychain / UserDefaults residue on the same first launch
   so an upgraded user has no lingering license state on disk (D-13/D-14 —
   additional cleanup beyond the APP-01..15 strip).
3. Pointing the in-app updater at the real future Release source on GitHub
   (D-09/D-10/D-11). The endpoint returns 404 until Phase 18 makes the repo
   public; manual "Check for Updates..." behaves as "Up to date" until then
   per D-10 — acceptable for the upgrade window.
4. Acknowledging the OSS source repo in the About panel alongside the
   surviving landing-page link (D-12).
5. Running the final APP-13 grep audit with the documented exemption list.

Output: The user's first launch of v1.3 shows the OSS note exactly once,
silently cleans Keychain residue, and lands the user in the editor with an
About-panel link to the source repo. Subsequent launches behave as
license-free as if the trial code had never existed.
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/phases/13-app-de-commercialization/13-CONTEXT.md
@.planning/phases/13-app-de-commercialization/13-01-SUMMARY.md
@.planning/ROADMAP.md
@.planning/REQUIREMENTS.md
@./CLAUDE.md
@docs/coding-patterns.md

<interfaces>
Pinned values from Plan 01 hand-off (no need to re-derive — these are CONTEXT.md decisions, not artifacts of Plan 01):

- Keychain residue constants (D-13) — pinned in `13-CONTEXT.md` lines 144-150:
  - Service: `"dev.wrangle.license"`, Account: `"license-key"`
  - Service: `"dev.wrangle.trial"`, Account: `"trial-data"`
  - UserDefaults key: `"LicenseManager.instanceID"`
- WhatsNewManager UserDefaults key (existing in current code):
  - `"WhatsNewManager.lastSeenVersion"` (private static `lastSeenVersionKey`)
- WhatsNewManager `dismiss()` writes `lastSeenVersion = currentVersion` —
  reading `Bundle.main.infoDictionary?["CFBundleShortVersionString"]`.
- Existing `ChangelogEntry` shape (current WhatsNewChangelog.swift lines 3-7):
  `struct ChangelogEntry { let version: String; let date: String; let sections: [ChangelogSection] }` — Plan 02 extends with an optional `cta`.
- About-panel launch slot in `wrangleApp.swift`:
  - Pre-Plan-01: lines 117-119 ran updateChecker → licenseManager.loadOnLaunch → whatsNewManager.checkOnLaunch.
  - Post-Plan-01: lines around 117-118 run updateChecker → whatsNewManager.checkOnLaunch (loadOnLaunch removed).
  - This plan inserts `LicenseResidueCleanup.run()` between those two calls, per D-14.
- About-panel NSAttributedString block: `wrangleApp.swift:165-183` (one URL, `wrangleapp.dev`). Plan 02 rewrites it per D-12.
- UpdateChecker GitHub Releases response shape (per D-09): GitHub's JSON returns `tag_name` (string, may be prefixed with `"v"`), `html_url` (string — the Release page URL), `body` (string, Markdown release notes), and `assets[]` (array — OPTIONAL for v1.3 per CONTEXT.md `<deferred>`, just open `html_url`).
</interfaces>
</context>

<tasks>

<task type="auto" tdd="true">
  <name>Task 1: Extend ChangelogEntry with CTA + v1.3.0 entry + WhatsNew filter</name>
  <files>
    wrangle/App/WhatsNewChangelog.swift,
    wrangle/App/WhatsNewView.swift,
    wrangle/App/WhatsNewManager.swift,
    wrangleTests/WhatsNewManagerTests.swift
  </files>
  <read_first>
    - .planning/phases/13-app-de-commercialization/13-CONTEXT.md (decisions D-01, D-02, D-03, D-04, D-05, plus Claude's discretion on `ChangelogCTA` struct vs tuple property and CTA button styling)
    - wrangle/App/WhatsNewChangelog.swift (current source — 68 lines; existing entries v1.2.0 and v1.1.1; the v1.3.0 entry must be PREPENDED to the array so it's the newest)
    - wrangle/App/WhatsNewView.swift (current source — `WhatsNewEntryView` private struct lines 48-89 renders each entry; the CTA Link is rendered here when `entry.cta != nil`. Note the top-level WhatsNewView body's predicate was already updated by Plan 01 to `if manager.shouldShowModal {`. The "Continue" button at line 33-36 stays; the per-entry CTA is in addition to it.)
    - wrangle/App/WhatsNewManager.swift (current source — `visibleEntries` at lines 35-39. D-05 fresh-install filter applies only in the `!showAll` branch; existing `showAll` short-circuit at line 36 stays as-is.)
    - wrangleTests/MarkdownParserTests.swift (existing test pattern — use this as the XCTestCase template for the new test file)
  </read_first>
  <behavior>
    - **D-01 contract:** `ChangelogEntry` gains an optional CTA. Claude's
      discretion: implement as a `ChangelogCTA` nested struct with two
      properties (`label: String`, `url: URL`) for type-safety and to keep
      the call-site readable; alternative `(label: String, url: URL)?` tuple
      is also acceptable per D-01.
    - **D-02/D-03 contract:** The v1.3.0 entry exists in
      `WhatsNewChangelog.entries` as the FIRST element (newest version
      prepended), category `.new`, single bullet item
      `"Wrangle is now free and open source."`, date string in the existing
      `"Month DD, YYYY"` format. CTA label: `"Star on GitHub"`. CTA URL:
      `URL(string: "https://github.com/J-Krush/wrangle")!` — exact string.
    - **D-05 contract (testable, gates Task 1's unit test):**
      `WhatsNewManager.visibleEntries` is the filter that drives the
      launch-modal contents. When `showAll == true`, it returns
      `WhatsNewChangelog.entries` unchanged (existing behavior — DO NOT
      modify). When `showAll == false` AND `lastSeen == "0.0.0"` (fresh
      install, no prior `WhatsNewManager.lastSeenVersion` key), filter
      additionally requires `version >= "1.3.0"` so older v1.1.x / v1.2.0
      entries are NOT auto-shown on a clean first run. When
      `showAll == false` AND `lastSeen != "0.0.0"` (upgrading v1.2 user),
      retain the existing semver-newer filter only (do NOT apply the
      `>= "1.3.0"` floor — a v1.2 user upgrading to v1.3 still sees the
      v1.3.0 entry through the normal `isVersion(_:newerThan:)` path).
    - **CTA rendering (D-03/D-04):** `WhatsNewEntryView` renders a SwiftUI
      `Link(cta.label, destination: cta.url)` when `entry.cta != nil`,
      below the per-entry sections. Use `.buttonStyle(.bordered)` (with
      `.tint(.purple)` to match the `.new` category color) so the per-entry
      CTA is visually distinct from the modal-level `.borderedProminent`
      Continue button. Tapping the Link opens externally via
      `NSWorkspace.shared.open` (SwiftUI Link default) — modal does NOT
      auto-close per D-04. The existing `Continue` button at WhatsNewView.swift
      lines 33-36 remains the only dismissal path.
    - **Unit-test behavior (gates the implementation):**
      - Test 1: `WhatsNewManager.visibleEntries` with `showAll = false` and
        a UserDefaults `lastSeen = "0.0.0"` returns only entries whose
        version >= "1.3.0" — verified against a `WhatsNewChangelog.entries`
        that contains v1.3.0 + v1.2.0 + v1.1.1 (the actual entries set).
      - Test 2: Same manager with `showAll = false` and `lastSeen = "1.2.0"`
        returns only entries with version > "1.2.0" (i.e., v1.3.0 only).
      - Test 3: Same manager with `showAll = true` returns ALL entries
        regardless of lastSeen.
      - Test 4: After calling `dismiss()`, the next read of
        `UserDefaults.standard.string(forKey: "WhatsNewManager.lastSeenVersion")`
        equals the current bundle version (existing behavior — regression
        guard).
      - Note: `WhatsNewManager` reads `UserDefaults.standard` directly, so
        the test uses a unique suite (e.g., `UserDefaults(suiteName: "WhatsNewManagerTests-\(UUID())")` — BUT the manager is hard-coded to `.standard`. Workaround: set and clear keys on `.standard` with a randomized prefix per test using `setValue:forKey:` directly on a known key, and clean up in `tearDown`. Document this constraint in the test file's header comment. If the executor finds the test fragile, they may inject a `UserDefaults` dependency into `WhatsNewManager` via a default-parameter `init(defaults: UserDefaults = .standard)` — that refactor is acceptable per Claude's discretion.)
  </behavior>
  <action>
    Apply three Swift edits + create one unit-test file, in this order
    (RED → GREEN per the tdd flag):

    1. **Test scaffold first (RED):** Create
       `wrangleTests/WhatsNewManagerTests.swift` containing the four
       behavior tests described above. Initial run MUST fail because
       `WhatsNewManager` does not yet apply the fresh-install filter (Tests
       1 expects exactly the v1.3.0-only result against a `lastSeen="0.0.0"`
       state which today returns all entries).

       Use existing test patterns from `wrangleTests/MarkdownParserTests.swift`
       (XCTest with `@MainActor` test methods since `WhatsNewManager` is
       `@MainActor`). File header comment must explain that
       `WhatsNewManager` reads `UserDefaults.standard` directly, so tests
       carefully set/clear the `"WhatsNewManager.lastSeenVersion"` key in
       `setUp` and `tearDown` to avoid pollution.

    2. **Extend `ChangelogEntry`** in `wrangle/App/WhatsNewChangelog.swift`
       (per D-01):
       - Add a nested struct `ChangelogCTA` at file scope (above
         `ChangelogEntry`) with two properties: `let label: String`
         and `let url: URL`. (Claude's discretion: tuple property
         `(label: String, url: URL)?` is also acceptable; prefer the
         struct for call-site clarity per Wrangle's value-types-preferred
         coding-patterns rule.)
       - Add a new optional stored property to `ChangelogEntry`:
         `let cta: ChangelogCTA?`. Existing initializers in
         `WhatsNewChangelog.entries` will not compile until they are
         updated to pass `cta: nil` — do so for both existing entries
         (v1.2.0 at line 22 and v1.1.1 at line 45).

    3. **Prepend the v1.3.0 entry** to `WhatsNewChangelog.entries` (per
       D-02 + D-03):
       - Version: `"1.3.0"`
       - Date: `"May 19, 2026"` (ship date; matches CONTEXT.md gathered date.
         If the executor knows a later actual ship date, use that instead —
         minor wording is Claude's discretion per CONTEXT.md.)
       - Single section, category `.new`, single bullet item:
         `"Wrangle is now free and open source."`
       - CTA: `ChangelogCTA(label: "Star on GitHub", url: URL(string: "https://github.com/J-Krush/wrangle")!)`
       - The existing v1.2.0 and v1.1.1 entries are passed `cta: nil`.

    4. **Render the CTA Link** in `wrangle/App/WhatsNewView.swift`
       `WhatsNewEntryView.body` (private struct at lines 48-89). After the
       `ForEach(entry.sections, id: \.category)` loop closes (around the
       current line 78-79), append an `if let cta = entry.cta { Link(cta.label, destination: cta.url).buttonStyle(.bordered).tint(.purple).padding(.top, 4) }`
       block. Match SwiftUI's existing indentation. The link uses
       SwiftUI's default `Link` which routes to `NSWorkspace.shared.open`
       and opens in the user's default browser (D-03 — NOT the embedded
       WKWebView). Tapping it does NOT call `manager.dismiss()` — modal
       stays open until Continue is tapped (D-04).

    5. **Add fresh-install filter** to
       `wrangle/App/WhatsNewManager.swift` `visibleEntries` computed
       property (per D-05). Today it reads:
       ```
       var visibleEntries: [ChangelogEntry] {
           if showAll { return WhatsNewChangelog.entries }
           let lastSeen = UserDefaults.standard.string(forKey: Self.lastSeenVersionKey) ?? "0.0.0"
           return WhatsNewChangelog.entries.filter { isVersion($0.version, newerThan: lastSeen) }
       }
       ```
       Add a fresh-install branch: when `lastSeen == "0.0.0"`, the filter
       additionally drops entries whose version is older than `"1.3.0"`
       (use `isVersion("1.3.0", newerThan: $0.version) == false` — i.e.,
       `$0.version >= "1.3.0"`). The existing semver-newer filter still
       applies for upgrading users. `showAll` short-circuit at the top stays
       unchanged (per D-05's note: filter applies only to launch-triggered
       modal, NOT to `Help → What's New` which sets `showAll = true`).

       Implementation pattern preserving `@MainActor`/`@Observable` style:
       compute `let isFreshInstall = lastSeen == "0.0.0"` and combine with
       the existing filter predicate.

    6. **Run the test file** (`xcodebuild test`) — confirm Tests 1, 2, 3, 4
       now PASS (GREEN). If any test still fails, debug the filter logic
       OR the test setup/teardown for `lastSeenVersionKey` pollution.

    DO NOT touch:
    - `WhatsNewView` body's outer predicate (already collapsed to
      `if manager.shouldShowModal {` by Plan 01).
    - The Continue button at WhatsNewView.swift lines 33-36.
    - `NotificationPermissionView.swift` (Plan 01 already added the
      WhatsNew-wins clause).
  </action>
  <verify>
    <automated>xcodebuild test -project Wrangle.xcodeproj -scheme Wrangle -destination 'platform=macOS,arch=arm64' -only-testing:wrangleTests/WhatsNewManagerTests 2>&1 | grep -E 'Test Suite .* passed|Test Suite .* failed|error:' | head -5</automated>
  </verify>
  <acceptance_criteria>
    - `grep -c 'struct ChangelogCTA' wrangle/App/WhatsNewChangelog.swift` returns 1 (OR the tuple-property alternative is documented in SUMMARY)
    - `grep -c 'version: "1.3.0"' wrangle/App/WhatsNewChangelog.swift` returns 1
    - `grep -c 'Wrangle is now free and open source' wrangle/App/WhatsNewChangelog.swift` returns 1
    - `grep -c 'label: "Star on GitHub"' wrangle/App/WhatsNewChangelog.swift` returns 1
    - `grep -c 'https://github.com/J-Krush/wrangle' wrangle/App/WhatsNewChangelog.swift` returns 1
    - `grep -c 'Link(' wrangle/App/WhatsNewView.swift` returns >= 1 (the CTA Link)
    - `grep -c 'cta' wrangle/App/WhatsNewView.swift` returns >= 1
    - `grep -c '"0.0.0"' wrangle/App/WhatsNewManager.swift` returns >= 1 (the fresh-install branch references it)
    - `test -f wrangleTests/WhatsNewManagerTests.swift` exits 0
    - `wc -l wrangleTests/WhatsNewManagerTests.swift` shows >= 30 lines
    - `xcodebuild test ... -only-testing:wrangleTests/WhatsNewManagerTests` exits 0 with all four tests passing
    - `xcodebuild ... build` exits 0 (project still compiles after the new property is added with `cta: nil` on existing entries)
  </acceptance_criteria>
  <done>
    `ChangelogEntry` carries an optional CTA. v1.3.0 entry exists with the
    Star on GitHub CTA. `WhatsNewView` renders the CTA Link.
    `WhatsNewManager.visibleEntries` applies the fresh-install filter per
    D-05. Four unit tests pass.
  </done>
</task>

<task type="auto" tdd="true">
  <name>Task 2: LicenseResidueCleanup helper + launch wiring + idempotency test</name>
  <files>
    wrangle/App/LicenseResidueCleanup.swift (new),
    wrangle/wrangleApp.swift,
    wrangleTests/LicenseResidueCleanupTests.swift (new)
  </files>
  <read_first>
    - .planning/phases/13-app-de-commercialization/13-CONTEXT.md (decisions D-13, D-14, plus Claude's discretion on enum-vs-function and ownership of its own UserDefaults gate vs reading `lastSeenVersion` directly)
    - wrangle/wrangleApp.swift (current state post-Plan-01 — the launch slot at the spot vacated by `licenseManager.loadOnLaunch()` removal. `LicenseResidueCleanup.run()` slots in between `coordinator.updateChecker.checkForUpdate()` and `coordinator.whatsNewManager.checkOnLaunch()` — D-14 ordering. Confirm exact line numbers post-Plan-01 strip — likely lines 117-118.)
    - wrangle/App/WhatsNewManager.swift (after Task 1 edit — the manager reads the same `WhatsNewManager.lastSeenVersion` UserDefaults key that `LicenseResidueCleanup` also reads to gate its run-once predicate)
    - CLAUDE.md (project Swift/SwiftUI conventions — `@MainActor` for state-touching helpers; value types preferred; `Result` / `throws` not force-unwraps; never sync file I/O on main thread — but Keychain SecItemDelete is acceptable on main since it's a fast, in-memory ACL check, not blocking I/O)
  </read_first>
  <behavior>
    - **D-13 contract:** `LicenseResidueCleanup.run()` performs three
      operations:
      1. `SecItemDelete` for `kSecClassGenericPassword` with
         `kSecAttrService = "dev.wrangle.license"` and
         `kSecAttrAccount = "license-key"`. Treat `errSecItemNotFound`
         (status code `-25300`) as success.
      2. `SecItemDelete` for `kSecClassGenericPassword` with
         `kSecAttrService = "dev.wrangle.trial"` and
         `kSecAttrAccount = "trial-data"`. Same `errSecItemNotFound`
         success path.
      3. `UserDefaults.standard.removeObject(forKey: "LicenseManager.instanceID")`.
    - **Gating contract (D-14, Claude's discretion section):** Cleanup runs
      ONLY when `WhatsNewManager.lastSeenVersion < "1.3.0"`. Implementation
      choice: read the UserDefaults key directly via
      `UserDefaults.standard.string(forKey: "WhatsNewManager.lastSeenVersion") ?? "0.0.0"`,
      compare semver against `"1.3.0"` using the same logic as
      `WhatsNewManager.isVersion(_:newerThan:)`. No new UserDefaults key is
      written — `WhatsNewManager.dismiss()` (called when user taps Continue)
      writes `lastSeenVersion = currentVersion`, which then prevents
      subsequent launches from re-running cleanup. Fresh installs see
      `lastSeen == "0.0.0"`, which is `< "1.3.0"`, so cleanup runs once and
      is a no-op (Keychain entries don't exist → `errSecItemNotFound` is
      treated as success).
    - **File layout (D-14):** `wrangle/App/LicenseResidueCleanup.swift` is a
      single `@MainActor enum` with a static `run()` method. Claude's
      discretion options also include a `@MainActor` free function or an
      extension on `AppCoordinator`. Pick the enum-with-static-method form
      to match the `WhatsNewChangelog` namespace-as-enum pattern already in
      the codebase. Target ~15-25 lines per CONTEXT.md.
    - **Idempotency test (gates this task):**
      - Test 1: Calling `LicenseResidueCleanup.run()` twice in a row
        succeeds both times (no thrown errors; second call hits
        `errSecItemNotFound` for both Keychain deletes — confirmed
        idempotent).
      - Test 2: After `run()`, `UserDefaults.standard.object(forKey: "LicenseManager.instanceID")` is `nil`.
      - Test 3: When `lastSeenVersion >= "1.3.0"`, `run()` is a no-op (does
        NOT attempt the deletes — verified by setting a sentinel UserDefaults
        value before and confirming it survives). NOTE: the gating semver
        check lives INSIDE `run()` per D-14 ownership of its own gate; if
        the executor moves the gate to the call site instead, this test
        needs to be deleted because `run()` would unconditionally delete.
        Prefer keeping the gate INSIDE `run()` for testability — the test's
        existence is justified by that placement.
      - Test 4: Test 3's reverse — when `lastSeenVersion = "0.0.0"` (fresh
        install), `run()` proceeds with the deletes (no exception,
        UserDefaults `instanceID` ends up nil).
  </behavior>
  <action>
    Two new files + one edit. Order: scaffold tests RED, implement helper,
    wire into launch, tests GREEN.

    1. **Test scaffold first (RED):** Create
       `wrangleTests/LicenseResidueCleanupTests.swift` with the four
       behavior tests above. Initial run MUST fail because
       `LicenseResidueCleanup` does not exist yet. Use XCTest +
       `@MainActor` test methods. Tests carefully manage
       `UserDefaults.standard` keys `"WhatsNewManager.lastSeenVersion"` and
       `"LicenseManager.instanceID"` in `setUp` / `tearDown` to avoid
       pollution.

    2. **Create `wrangle/App/LicenseResidueCleanup.swift`** matching this
       contract:
       - File header comment explaining purpose: "One-time cleanup of v1.2
         license/trial Keychain entries + LicenseManager UserDefaults key.
         Gated by `WhatsNewManager.lastSeenVersion < \"1.3.0\"`. Idempotent
         — re-runs treat `errSecItemNotFound` as success." Reference D-13
         and D-14 from `.planning/phases/13-app-de-commercialization/13-CONTEXT.md`.
       - `import Foundation` + `import Security`.
       - `@MainActor enum LicenseResidueCleanup` with a static `run()`
         method.
       - Inside `run()`:
         - Read `UserDefaults.standard.string(forKey: "WhatsNewManager.lastSeenVersion") ?? "0.0.0"`
           into `lastSeen`.
         - Compare semver: if `lastSeen >= "1.3.0"`, return early
           (no-op). Implement a private `private static func isAtLeast130(_ s: String) -> Bool`
           that splits on `.` and compares integer components vs `[1, 3, 0]`.
         - Build the license Keychain query dictionary and call
           `SecItemDelete`. Discard the result (any value, including
           `errSecItemNotFound`, is fine).
         - Build the trial Keychain query dictionary and call
           `SecItemDelete`. Discard the result.
         - Call `UserDefaults.standard.removeObject(forKey: "LicenseManager.instanceID")`.
       - Keep the file under ~40 lines per CLAUDE.md "Keep views under ~80
         lines — extract subviews beyond that" — this is not a view but
         the same spirit applies for single-responsibility helpers.

       Exact Keychain query shapes (pinned from D-13 + the deleted
       `LicenseManager.swift` Keychain usage pattern):
       - License: `kSecClass: kSecClassGenericPassword`,
         `kSecAttrService: "dev.wrangle.license"`,
         `kSecAttrAccount: "license-key"`.
       - Trial: `kSecClass: kSecClassGenericPassword`,
         `kSecAttrService: "dev.wrangle.trial"`,
         `kSecAttrAccount: "trial-data"`.

    3. **Wire `LicenseResidueCleanup.run()` into the launch path** in
       `wrangle/wrangleApp.swift`. Find the launch slot vacated by Plan 01
       (where `coordinator.licenseManager.loadOnLaunch()` was removed —
       between `coordinator.updateChecker.checkForUpdate()` and
       `coordinator.whatsNewManager.checkOnLaunch()`). Insert
       `LicenseResidueCleanup.run()` on its own line at that slot. Per D-14
       ordering: cleanup runs FIRST, then WhatsNew gets to surface the OSS
       note. Both gate off the same `lastSeenVersion < "1.3.0"` snapshot —
       cleanup reads the UserDefault, runs, returns; WhatsNew then reads
       the same UserDefault (still unchanged because `dismiss()` hasn't
       been called yet), sets `shouldShowModal = true`. User eventually
       taps Continue, which writes `lastSeenVersion = "1.3.0"` and gates
       both surfaces for future launches.

    4. **Run the test file** — confirm all four tests PASS (GREEN). If
       Test 3 fails because the executor moved the gate to the call site
       instead of keeping it inside `run()`, refactor the test or move the
       gate back inside `run()` per the behavior contract.

    DO NOT:
    - Add a new UserDefaults key for run-once tracking — the cleanup gate
      is `WhatsNewManager.lastSeenVersion < "1.3.0"` per D-14.
    - Make `LicenseResidueCleanup` `@Observable` — it has no state to
      publish (per CONTEXT.md `<code_context>` Established Patterns).
    - Touch `WhatsNewManager` again — Task 1 owns those edits.
    - Touch the About-panel block in `wrangleApp.swift:165-183` — Task 3
      owns that edit.
  </action>
  <verify>
    <automated>test -f wrangle/App/LicenseResidueCleanup.swift && grep -c 'LicenseResidueCleanup.run()' wrangle/wrangleApp.swift && xcodebuild test -project Wrangle.xcodeproj -scheme Wrangle -destination 'platform=macOS,arch=arm64' -only-testing:wrangleTests/LicenseResidueCleanupTests 2>&1 | grep -E 'Test Suite .* passed|Test Suite .* failed|error:' | head -5</automated>
  </verify>
  <acceptance_criteria>
    - `test -f wrangle/App/LicenseResidueCleanup.swift` exits 0
    - `grep -c 'enum LicenseResidueCleanup' wrangle/App/LicenseResidueCleanup.swift` returns 1
    - `grep -c 'static func run' wrangle/App/LicenseResidueCleanup.swift` returns 1
    - `grep -c 'dev.wrangle.license' wrangle/App/LicenseResidueCleanup.swift` returns 1
    - `grep -c 'dev.wrangle.trial' wrangle/App/LicenseResidueCleanup.swift` returns 1
    - `grep -c '"license-key"' wrangle/App/LicenseResidueCleanup.swift` returns 1
    - `grep -c '"trial-data"' wrangle/App/LicenseResidueCleanup.swift` returns 1
    - `grep -c 'LicenseManager.instanceID' wrangle/App/LicenseResidueCleanup.swift` returns 1
    - `grep -c '"WhatsNewManager.lastSeenVersion"' wrangle/App/LicenseResidueCleanup.swift` returns 1
    - `grep -c 'LicenseResidueCleanup.run()' wrangle/wrangleApp.swift` returns 1
    - `test -f wrangleTests/LicenseResidueCleanupTests.swift` exits 0
    - `wc -l wrangleTests/LicenseResidueCleanupTests.swift` shows >= 30 lines
    - `xcodebuild test ... -only-testing:wrangleTests/LicenseResidueCleanupTests` exits 0 with all four tests passing
    - `xcodebuild ... build` exits 0
  </acceptance_criteria>
  <done>
    `LicenseResidueCleanup.swift` exists, wired into `wrangleApp.onAppear`
    at the correct launch slot per D-14, idempotent and gated by
    `WhatsNewManager.lastSeenVersion < "1.3.0"`. Four unit tests pass.
  </done>
</task>

<task type="auto" tdd="false">
  <name>Task 3: UpdateChecker GitHub Releases repoint + About-panel dual-link credits</name>
  <files>
    wrangle/App/UpdateChecker.swift,
    wrangle/wrangleApp.swift
  </files>
  <read_first>
    - .planning/phases/13-app-de-commercialization/13-CONTEXT.md (decisions D-09, D-10, D-11, D-12, plus Claude's discretion on `Decodable` init vs `JSONDecoder.keyDecodingStrategy` and whether to parse `assets[]` for a `.dmg` URL — keep it simple per CONTEXT.md `<deferred>`: just open the Release `html_url`)
    - wrangle/App/UpdateChecker.swift (current source — 91 lines; lines 12 = endpoint constant, line 27 = openDownloadPage fallback, lines 79-91 = VersionInfo struct; all three blocks change per D-09/D-11)
    - wrangle/wrangleApp.swift (current source post-Plan-01 — About-panel NSAttributedString block at lines 165-183 — single `wrangleapp.dev` link; rewrite per D-12 to add a second `github.com/J-Krush/wrangle` link)
  </read_first>
  <action>
    Two coordinated edits — UpdateChecker repoint and About-panel rewrite.

    1. **Repoint `UpdateChecker.swift` `versionEndpoint`** (line 12 — exact
       value verified):
       Replace `"https://wrangleapp.dev/api/version.json"` with
       `"https://api.github.com/repos/J-Krush/wrangle/releases/latest"`.

    2. **Rewrite `UpdateChecker.swift` `VersionInfo` struct** (lines 79-91)
       to match GitHub's Releases API JSON shape per D-09:
       - GitHub returns: `tag_name` (string, may be prefixed with `"v"`),
         `html_url` (string — the Release page URL, used as the download
         landing page), `body` (string — Markdown release notes).
         Other fields (`assets[]`, `prerelease`, `draft`, etc.) are
         ignored for v1.3 per CONTEXT.md `<deferred>` (parsing `assets[]`
         for a `.dmg` URL is deferred to Phase 18).
       - Rename the private `VersionInfo` struct to `GitHubRelease` (or
         keep `VersionInfo` — Claude's discretion per CONTEXT.md; pick
         `GitHubRelease` for clarity at the call site).
       - Use `Decodable` with explicit `CodingKeys` mapping `tag_name`,
         `html_url`, `body`. Alternative `JSONDecoder.keyDecodingStrategy
         = .convertFromSnakeCase` is acceptable per CONTEXT.md.
       - In `performCheck`, after decoding, strip a leading `"v"` from
         `tag_name` if present (e.g., `"v1.3.0"` → `"1.3.0"`) so the
         semver comparison logic at line 65-76 works unchanged. Map
         `release.tag_name.hasPrefix("v") ? String(release.tag_name.dropFirst()) : release.tag_name`
         into the existing `versionInfo.version` slot.
       - Assign `release.html_url` to the `downloadURL` private property
         and `release.body ?? ""` to `releaseNotes`.

    3. **Drop the `wrangleapp.dev/download` fallback** in
       `UpdateChecker.openDownloadPage` (line 27 — exact text verified —
       per D-11). Today:
       ```
       let urlString = downloadURL.isEmpty ? "https://wrangleapp.dev/download" : downloadURL
       ```
       Replace with a guard that opens nothing when `downloadURL` is
       empty (no fallback). Pattern:
       ```
       guard !downloadURL.isEmpty, let url = URL(string: downloadURL) else { return }
       NSWorkspace.shared.open(url)
       updateAvailable = false
       ```

    4. **Acknowledge the D-10 behavior in a comment**: Add a brief inline
       comment in `performCheck` near the `catch` block noting that pre-
       public-flip (Phases 13-17) `api.github.com/repos/J-Krush/wrangle`
       returns 404 because the repo is private, so manual "Check for
       Updates..." will set `showUpToDate = true` via the existing catch
       fall-through path. Phase 18 makes the endpoint live. (Don't add a
       runtime workaround — the existing silent-swallow for the non-manual
       path is intentional per D-10.)

    5. **Rewrite the About-panel NSAttributedString** in
       `wrangle/wrangleApp.swift` (lines 165-183 — exact block verified)
       per D-12. The new credits NSAttributedString builds three pieces:
       - `"Made by Krush\n"` (existing styling: `NSFont.systemFont(ofSize: 11)`)
       - `"wrangleapp.dev"` with `.link: URL(string: "https://wrangleapp.dev")`
         and `.foregroundColor: NSColor.linkColor`
       - A separator (Claude's discretion per D-12): `"  •  "` (preferred —
         spaces-bullet-spaces; matches D-12's example) OR `"\n"` for a
         line break. Use the bullet inline separator: `"  •  "`.
       - `"github.com/J-Krush/wrangle"` with
         `.link: URL(string: "https://github.com/J-Krush/wrangle")`
         and `.foregroundColor: NSColor.linkColor`

       Keep the surrounding `Button("About Wrangle") { ... }` and
       `NSApplication.shared.orderFrontStandardAboutPanel(options: [.credits: credits])`
       structure unchanged.

    DO NOT:
    - Parse `assets[]` for a `.dmg` URL (deferred per CONTEXT.md `<deferred>`).
    - Add cert pinning to `URLSession` (the standard Foundation TLS chain
      handling is sufficient per threat model below).
    - Touch any other test file or runtime file in this task — Tasks 1
      and 2 own those.
  </action>
  <verify>
    <automated>grep -c 'api.github.com/repos/J-Krush/wrangle/releases/latest' wrangle/App/UpdateChecker.swift && grep -c 'github.com/J-Krush/wrangle' wrangle/wrangleApp.swift && xcodebuild -project Wrangle.xcodeproj -scheme Wrangle -configuration Debug -destination 'platform=macOS,arch=arm64' build 2>&1 | grep -E 'BUILD SUCCEEDED|BUILD FAILED' | head -1</automated>
  </verify>
  <acceptance_criteria>
    - `grep -c 'wrangleapp.dev/api/version.json' wrangle/App/UpdateChecker.swift` returns 0
    - `grep -c 'wrangleapp.dev/download' wrangle/App/UpdateChecker.swift` returns 0
    - `grep -c 'api.github.com/repos/J-Krush/wrangle/releases/latest' wrangle/App/UpdateChecker.swift` returns 1
    - `grep -c 'tag_name' wrangle/App/UpdateChecker.swift` returns 1
    - `grep -c 'html_url' wrangle/App/UpdateChecker.swift` returns 1
    - `grep -c 'github.com/J-Krush/wrangle' wrangle/wrangleApp.swift` returns 1 (in the About-panel NSAttributedString)
    - `grep -c 'wrangleapp.dev' wrangle/wrangleApp.swift` returns 1 (the surviving About-panel link per D-12)
    - `xcodebuild build` exits 0 with `BUILD SUCCEEDED`
    - No new warnings introduced by the UpdateChecker rewrite
  </acceptance_criteria>
  <done>
    UpdateChecker hits the GitHub Releases endpoint, decodes the GitHub
    shape, and opens the Release `html_url` directly (no
    `wrangleapp.dev/download` fallback). About panel surfaces both
    `wrangleapp.dev` and `github.com/J-Krush/wrangle` as clickable
    links.
  </done>
</task>

<task type="auto" tdd="false">
  <name>Task 4: Final APP-13 grep audit + exemption list + phase smoke test</name>
  <files>
    (no source edits — verification + documentation in
    `.planning/phases/13-app-de-commercialization/13-02-SUMMARY.md`)
  </files>
  <read_first>
    - .planning/phases/13-app-de-commercialization/13-CONTEXT.md (`<specifics>` section — APP-13 forbidden tokens, the Apple-framework type-name exemption, the deliberate `wrangleapp.dev` About-panel survival per D-12)
    - .planning/phases/13-app-de-commercialization/13-01-SUMMARY.md (Plan 01's preliminary APP-13 audit results — the one PENDING-PLAN-02 `wrangleapp.dev` hit must now be re-counted as INTENTIONAL surviving per D-12)
  </read_first>
  <action>
    Three verifications, all read-only:

    1. **Final APP-13 forbidden-token sweep** across `wrangle/` and
       `scripts/`:

       Token sweep commands (run each individually so the executor can
       inspect each result):

       ```
       grep -rnE '\$24' wrangle/ scripts/ 2>/dev/null
       grep -rn 'Buy' wrangle/ scripts/ 2>/dev/null
       grep -rn 'Trial' wrangle/ scripts/ 2>/dev/null
       grep -rn 'trial' wrangle/ scripts/ 2>/dev/null
       grep -rn 'License' wrangle/ scripts/ 2>/dev/null
       grep -rn 'license' wrangle/ scripts/ 2>/dev/null
       grep -rniE 'lemon[ -]?squeezy' wrangle/ scripts/ 2>/dev/null
       grep -rn 'wrangleapp.dev' wrangle/ scripts/ 2>/dev/null
       ```

       Expected counts:
       - `$24`, `Buy`, `Trial`, `trial`, `LemonSqueezy`: ZERO each.
       - `License` / `license`: zero in `wrangle/` and `scripts/`. (No
         Apple-framework type names currently containing these substrings
         are in the codebase — verified during Plan 01 Task 3.)
       - `wrangleapp.dev`: ONE hit, in `wrangle/wrangleApp.swift` About-panel
         NSAttributedString (per D-12 — INTENTIONAL survival).

       If any unexpected hit appears, catalog it in SUMMARY. Either:
       (a) it's a legitimate Apple-framework type-name match → add to the
       exemption list, OR
       (b) it's leaked source we need to strip → flag the violation and
       open a follow-up task to fix it before phase completion.

    2. **Document the explicit APP-13 exemption list** in
       `.planning/phases/13-app-de-commercialization/13-02-SUMMARY.md`:
       - `wrangleapp.dev` in `wrangle/wrangleApp.swift` About-panel
         NSAttributedString (per D-12) — INTENTIONAL.
       - `LICENSE` repo-root file — does not exist in Phase 13; lands in
         Phase 14 and is exempt from APP-13 then (per CONTEXT.md
         `<specifics>`).
       - Apple-framework type names containing `License` / `Trial`
         substrings (e.g., none currently in scope) — EXEMPT by APP-13's
         text. List any that appear in future Apple API references.

    3. **Full-phase smoke test** (manual, executor records outcome in
       SUMMARY):
       - Clean build the Debug target.
       - Reset UserDefaults to simulate a fresh install:
         `defaults delete dev.wrangle.Wrangle` or set the bundle ID
         match (the executor confirms via `defaults read dev.wrangle.Wrangle`
         post-launch).
       - Launch the app fresh.
       - Confirm: editor opens with no gate, no banner, no nag.
       - Confirm: WhatsNew modal appears showing the v1.3.0 entry with
         the "Star on GitHub" CTA.
       - Click the CTA — confirm the user's default browser opens
         `https://github.com/J-Krush/wrangle`. The Wrangle WhatsNew modal
         REMAINS open per D-04.
       - Click Continue — modal dismisses.
       - Quit Wrangle, relaunch — WhatsNew modal does NOT re-appear on
         second launch.
       - Open About Wrangle from the app menu — confirm credits show
         "Made by Krush" + the two clickable links.
       - File menu → Help → Report Bug — confirm the menu still works
         (unrelated to Phase 13 — sanity check).
       - Create a Scratch Pad (⇧⌘N) — confirm editor handles it.
       - Open a Browser tab (⌥⌘B) — confirm browser loads.

    Record all results in SUMMARY (PASS / FAIL per step) and a
    PENDING/RESOLVED column for any hits in the APP-13 sweep.
  </action>
  <verify>
    <automated>EXP=$(grep -rnE '\$24|\bBuy\b|\bTrial\b|\btrial\b|[Ll]emon[Ss]queezy' wrangle/ scripts/ 2>/dev/null | wc -l | tr -d ' '); WAD=$(grep -rn 'wrangleapp.dev' wrangle/ scripts/ 2>/dev/null | wc -l | tr -d ' '); echo "forbidden=$EXP, wrangleapp_dev=$WAD"</automated>
  </verify>
  <acceptance_criteria>
    - `grep -rnE '\\$24|\\bBuy\\b|\\bTrial\\b|\\btrial\\b|[Ll]emon[Ss]queezy' wrangle/ scripts/ 2>/dev/null | wc -l | tr -d ' '` returns 0
    - `grep -rnE '\\bLicense\\b|\\blicense\\b' wrangle/ scripts/ 2>/dev/null | wc -l | tr -d ' '` returns 0 (OR all hits are catalogued in SUMMARY as exempt Apple-framework type names)
    - `grep -rn 'wrangleapp.dev' wrangle/ scripts/ 2>/dev/null | wc -l | tr -d ' '` returns exactly 1
    - `grep -rn 'wrangleapp.dev' wrangle/ scripts/ 2>/dev/null` shows the single hit in `wrangle/wrangleApp.swift` (About-panel NSAttributedString)
    - SUMMARY contains a "## APP-13 Final Audit" section with the exemption list and verification commands run
    - SUMMARY contains a "## Phase 13 Smoke Test" section with PASS/FAIL outcomes for all 8 manual steps (clean build → editor open → WhatsNew modal → CTA → Continue → relaunch → About → Scratch/Browser smoke)
    - Manual smoke test passes (no license/trial blocker; WhatsNew shows v1.3.0 entry with CTA; CTA opens external browser; Continue dismisses; relaunch does NOT re-show modal; About shows both links)
  </acceptance_criteria>
  <done>
    Final APP-13 grep audit is documented with the exemption list. Phase
    13 smoke test passes end-to-end. Phase 13 is ready for `/gsd:verify-phase`.
  </done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

This plan introduces two boundary changes:
1. A new outbound HTTPS request to `api.github.com` (replacing the prior
   request to `wrangleapp.dev`). Both are TLS-secured HTTPS endpoints
   reached via `URLSession.shared`.
2. A new local-only Keychain mutation surface (`LicenseResidueCleanup`)
   that executes `SecItemDelete` against two hard-coded service/account
   pairs.

No new authentication paths, no new data storage, no new IPC, no new
URL handlers.

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-13-05 | Information Disclosure | `LicenseResidueCleanup` Keychain delete helper | mitigate | Helper deletes ONLY two hard-coded service/account pairs (`dev.wrangle.license` + `license-key`; `dev.wrangle.trial` + `trial-data`). No user input flows into the Keychain query — strings are compile-time constants in the file. `errSecItemNotFound` is treated as success (idempotent). No Keychain READ is performed — only DELETE — so no secret data flows out of Keychain through this helper. |
| T-13-06 | Tampering | `LicenseResidueCleanup` helper invocation surface | mitigate | The helper is `@MainActor` and called only from `wrangleApp.onAppear` (single call site, line confirmed by Task 2 acceptance). Gating predicate (`lastSeenVersion < "1.3.0"`) ensures it runs at most once per upgrade. Idempotent semantics (errSecItemNotFound = success) means even multiple invocations cannot cause data loss beyond the two known v1.2 entries. |
| T-13-07 | Tampering / Repudiation | `UpdateChecker` GitHub HTTPS endpoint | mitigate | URL is hard-coded HTTPS (`https://api.github.com/repos/J-Krush/wrangle/releases/latest`). Foundation's URLSession enforces TLS by default (App Transport Security; certificate validation via the system trust store). Response parsing is a whitelisted `Decodable` struct accepting only `tag_name` (String), `html_url` (String), `body` (String?). No code execution from response content — release notes are stored in a String and surfaced as text in the existing update-available alert. No shell-out, no path manipulation, no eval. |
| T-13-08 | Denial of Service | `UpdateChecker.performCheck` 404 swallow | accept | Pre-public-flip (Phases 13-17), the endpoint returns 404 because the repo is private. Existing behavior (silent swallow for non-manual path; `showUpToDate = true` for manual path) is intentional per D-10 and is unchanged. Slight DoS by GitHub rate-limiting is also accepted — the app degrades to "no update found" silently. |
| T-13-09 | Tampering | About-panel NSAttributedString rewrite | accept | The new dual-link NSAttributedString uses hard-coded URLs (`https://wrangleapp.dev`, `https://github.com/J-Krush/wrangle`). No user input flows into the credits string. AppKit's About panel renders the NSAttributedString in a sandboxed text view; clicking a link delegates to `NSWorkspace.shared.open` which routes to the user's default browser. No attack surface change. |
| T-13-10 | Information Disclosure | `WhatsNewView` CTA Link | mitigate | The CTA `Link` opens `URL(string: "https://github.com/J-Krush/wrangle")!` (hard-coded compile-time constant) via SwiftUI's default `NSWorkspace.shared.open` path. No user input flows into the URL. No referrer / cookie leakage from the app — the user's default browser handles the request from its own context. |

**No new authentication, no new authorization, no new persistent data
storage.** New flows are: (a) local Keychain DELETIONS scoped to two
known service/account pairs, (b) a one-shot HTTPS GET to GitHub's public
Releases API, and (c) reads/writes of the existing
`"WhatsNewManager.lastSeenVersion"` and `"LicenseManager.instanceID"`
UserDefaults keys.

**Block-on:** high severity threats. None identified for this plan.
</threat_model>

<verification>
- Maps to ROADMAP §Phase 13 **Success Criterion 1** — App opens directly to
  editor with no LicenseGateView / TrialBannerView / License tab (carried
  from Plan 01; Plan 02 does not regress this). Verified by Task 4 smoke
  test.
- Maps to ROADMAP §Phase 13 **Success Criterion 2** — Final APP-13 grep
  audit returns zero hits for `$24`, `Buy`, `Trial`/`trial`, `License`/
  `license`, `LemonSqueezy`. `wrangleapp.dev` survives only in the
  About-panel per D-12 (intentional, exempt). Verified by Task 4.
- Maps to ROADMAP §Phase 13 **Success Criterion 3** — First-launch OSS
  surface fires once, links to `https://github.com/J-Krush/wrangle`, is
  dismissable, does not re-appear. Verified by Task 4 smoke test + Task 1
  unit test (D-05 fresh-install filter regression guard).
- Maps to ROADMAP §Phase 13 **Success Criterion 4** — App builds clean
  with no warnings. Verified by Tasks 1, 2, 3 acceptance criteria
  (xcodebuild build exits 0; xcodebuild test exits 0 for both unit-test
  targets).
- Maps to ROADMAP §Phase 13 **Success Criterion 5** — All five license
  files deleted (verified in Plan 01; carried into Plan 02 SUMMARY).
</verification>

<success_criteria>
- v1.3.0 entry exists in `WhatsNewChangelog.entries` with single bullet
  `"Wrangle is now free and open source."` and CTA `(label: "Star on GitHub", url: https://github.com/J-Krush/wrangle)`.
- `WhatsNewView` renders the CTA `Link` only when `entry.cta != nil`.
- `WhatsNewManager.visibleEntries` applies the D-05 fresh-install filter
  (verified by 4 unit tests).
- `LicenseResidueCleanup.swift` exists, wired into `wrangleApp.onAppear`
  at the correct slot, idempotent, gated by
  `WhatsNewManager.lastSeenVersion < "1.3.0"` (verified by 4 unit tests).
- `UpdateChecker.versionEndpoint` is the GitHub Releases URL; response
  decoding is GitHub-shaped (`tag_name`, `html_url`, `body`).
- About-panel credits show both `wrangleapp.dev` and
  `github.com/J-Krush/wrangle` as clickable NSAttributedString links.
- APP-13 final audit confirms zero hits for forbidden tokens; exemption
  list documented in SUMMARY (with the one expected `wrangleapp.dev`
  About-panel survival).
- Phase 13 manual smoke test passes all 8 steps.
- Build clean: `xcodebuild build` exits 0, no new warnings introduced.
</success_criteria>

<output>
Create `.planning/phases/13-app-de-commercialization/13-02-SUMMARY.md` documenting:
- New files: `wrangle/App/LicenseResidueCleanup.swift`,
  `wrangleTests/WhatsNewManagerTests.swift`,
  `wrangleTests/LicenseResidueCleanupTests.swift`
- Edited files: `WhatsNewChangelog.swift`, `WhatsNewView.swift`,
  `WhatsNewManager.swift`, `UpdateChecker.swift`, `wrangleApp.swift`
- Test results: 8 tests passed (4 in WhatsNewManagerTests, 4 in
  LicenseResidueCleanupTests)
- APP-13 final audit results with the exemption list:
  - `wrangleapp.dev` (1 hit in `wrangleApp.swift` About-panel — D-12)
  - Apple-framework type names with `License`/`Trial` substrings (none
    currently present)
  - `LICENSE` repo-root file (exempt when Phase 14 lands)
- Phase 13 smoke test PASS/FAIL log for all 8 manual steps
- UpdateChecker behavior note: `api.github.com/repos/J-Krush/wrangle`
  returns 404 until Phase 18 makes the repo public; manual "Check for
  Updates..." will display "Up to date" until then per D-10 — DOCUMENTED
  for the user's awareness.
- Phase 13 completion declaration: all 15 APP-* requirements satisfied;
  ready for `/gsd:verify-phase 13`.
</output>
