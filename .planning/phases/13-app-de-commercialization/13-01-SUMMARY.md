---
phase: 13-app-de-commercialization
plan: 01
subsystem: app-de-commercialization
tags: [strip, license, trial, paywall, oss-conversion, v1.3]
requires: []
provides:
  - license-free app surface (no LicenseGateView, no TrialBannerView, no Preferences -> License tab)
  - WhatsNew predicate collapsed to single first-launch gate (D-07)
  - NotificationPermission predicate with WhatsNew-wins clause (D-08)
  - clean Info.plist verification (no entitlements files in tree)
affects:
  - wrangle/App/AppCoordinator.swift
  - wrangle/wrangleApp.swift
  - wrangle/ContentView.swift
  - wrangle/App/SettingsView.swift
  - wrangle/App/WhatsNewView.swift
  - wrangle/App/NotificationPermissionView.swift
tech-stack:
  added: []
  patterns:
    - "@MainActor @Observable AppCoordinator now owns fewer managers — licenseManager removed"
    - "Modal overlay z-stack collapses from 5 to 4 (LicenseGateView removed; FuzzyFinder/GlobalSearch/NotificationPermission/WhatsNew remain)"
key-files:
  created: []
  modified:
    - wrangle/App/AppCoordinator.swift
    - wrangle/wrangleApp.swift
    - wrangle/ContentView.swift
    - wrangle/App/SettingsView.swift
    - wrangle/App/WhatsNewView.swift
    - wrangle/App/NotificationPermissionView.swift
  deleted:
    - wrangle/App/LicenseManager.swift
    - wrangle/App/LicenseGateView.swift
    - wrangle/App/TrialBannerView.swift
    - wrangle/App/LicenseSettingsView.swift
    - scripts/reset-license.sh
decisions:
  - "Collapsed outer `VStack(spacing: 0)` in ContentView.swift (Claude discretion per D-15 list) — the wrapper had no remaining purpose once TrialBannerView was its only sibling. The HStack now sits directly under `body`, and the matching `} // outer VStack` close comment was removed. Forward-compat: a future banner can re-wrap the HStack in one line."
  - "Retained TabView wrapper in SettingsView.swift (Claude discretion) over collapsing to bare `GeneralSettingsView().frame(...)`. Forward-compat: when v1.3+ adds a second tab (e.g., Editor / Shortcuts / Themes), no scaffolding work is needed; AppKit Settings window also keeps a coherent multi-tab title bar."
  - "Kept body-indentation inside the now-bare HStack as-is (16-space inner instead of the canonical 12-space) — Swift is whitespace-insensitive and a reformat-only churn would muddy the strip-only diff; not in plan scope."
metrics:
  duration: ~10 minutes
  completed: 2026-05-19T14:11:43Z
---

# Phase 13 Plan 01: Strip License / Trial / Paywall Summary

Surgically removed every paid-trial / paywall / license surface from the v1.3
build: five source files deleted, six call-site edits applied, build clean,
APP-14 Info.plist verification passed (zero `.entitlements` files in tree),
APP-13 preliminary forbidden-token grep catalogued with all surviving hits
documented as either intentional repo-file pattern matching (FileTreeNode)
or PENDING-PLAN-02 surfaces (About panel + UpdateChecker).

## Files Deleted (5)

| File | Requirement | Commit |
| ---- | ----------- | ------ |
| `wrangle/App/LicenseManager.swift` | APP-01 | `535e766` |
| `wrangle/App/LicenseGateView.swift` | APP-02 | `535e766` |
| `wrangle/App/TrialBannerView.swift` | APP-03 | `535e766` |
| `wrangle/App/LicenseSettingsView.swift` | APP-04 | `535e766` |
| `scripts/reset-license.sh` | APP-05 | `535e766` |

D-13 Keychain constants confirmed verbatim in `LicenseManager.swift` before
deletion:

- `keychainService = "dev.wrangle.license"` (line 42)
- `keychainAccount = "license-key"` (line 43)
- `trialKeychainService = "dev.wrangle.trial"` (line 45)
- `trialKeychainAccount = "trial-data"` (line 46)
- `instanceIDKey = "LicenseManager.instanceID"` (line 41)

Plan 02's `LicenseResidueCleanup` consumes these strings — the constants
are pinned in `13-CONTEXT.md` D-13 and no longer require sourcing the
deleted file.

## Call-Site Edits (6)

| # | File | Symbol(s) Stripped | Requirement | Commit |
| - | ---- | ------------------ | ----------- | ------ |
| 1 | `wrangle/App/AppCoordinator.swift` | `var licenseManager = LicenseManager()` | APP-06 | `8cd648f` |
| 2 | `wrangle/wrangleApp.swift` | `coordinator.licenseManager.loadOnLaunch()` in `onAppear` | APP-07 | `8cd648f` |
| 3 | `wrangle/ContentView.swift` | `TrialBannerView()` + outer `VStack(spacing: 0)` wrapper + `LicenseGateView()` overlay | APP-02, APP-03 | `8cd648f` |
| 4 | `wrangle/App/SettingsView.swift` | `case license` + `LicenseSettingsView()` tab block | APP-04 | `8cd648f` |
| 5 | `wrangle/App/WhatsNewView.swift` | `!coordinator.licenseManager.needsLicense &&` prefix → predicate now reads `if manager.shouldShowModal` | D-07 / APP-15 | `8cd648f` |
| 6 | `wrangle/App/NotificationPermissionView.swift` | `!coordinator.licenseManager.needsLicense &&` prefix stripped AND `&& !coordinator.whatsNewManager.shouldShowModal` clause added → predicate now reads `if manager.shouldShowModal && !coordinator.whatsNewManager.shouldShowModal` | D-08 / APP-15 | `8cd648f` |

Acceptance grep results (Task 2):

- `grep -c 'licenseManager'` on all five edited Swift files: **0** each
- `grep -c 'TrialBannerView' wrangle/ContentView.swift`: **0**
- `grep -c 'LicenseGateView' wrangle/ContentView.swift`: **0**
- `grep -c 'LicenseSettingsView' wrangle/App/SettingsView.swift`: **0**
- `grep -c 'case license' wrangle/App/SettingsView.swift`: **0**
- `grep -c 'loadOnLaunch' wrangle/wrangleApp.swift`: **0**
- `grep -c 'if manager.shouldShowModal {' wrangle/App/WhatsNewView.swift`: **1** (positive assertion)
- `grep -c '&& !coordinator.whatsNewManager.shouldShowModal' wrangle/App/NotificationPermissionView.swift`: **1** (positive assertion)
- Tree-wide sweep `grep -rn 'licenseManager\|LicenseManager\|LicenseGateView\|TrialBannerView\|LicenseSettingsView' wrangle/ scripts/`: **no matches**

## Build Outcome

```
xcodebuild -project Wrangle.xcodeproj -scheme Wrangle \
  -configuration Debug -destination 'platform=macOS,arch=arm64' build
```

**Result: BUILD SUCCEEDED**

Built app: `Wrangle.app` (Debug, arm64, signed with Developer ID
`John Kreisher (3DEKQ7GUK6)`). Final binary at
`~/Library/Developer/Xcode/DerivedData/Wrangle-.../Build/Products/Debug/Wrangle.app`.

### Warnings

One warning surfaced, classified as **pre-existing baseline (not introduced
by this plan)**:

```
Wrangle.xcodeproj: warning: The Copy Bundle Resources build phase contains
this target's Info.plist file '.../Wrangle/Info.plist'.
```

This is a long-standing project-level configuration warning (Info.plist is
listed in Copy Bundle Resources) and is unrelated to the symbol strip.
It existed in the pre-strip baseline and is preserved exactly. Zero NEW
warnings were introduced by Task 1 or Task 2 edits.

### `project.pbxproj` Membership

No edits required. `grep -n 'LicenseManager\|LicenseGateView\|TrialBannerView\|LicenseSettingsView\|reset-license' Wrangle.xcodeproj/project.pbxproj` returned no matches — the Wrangle Xcode target uses folder-reference / file-system membership for the `wrangle/App/` directory rather than explicit per-file `PBXBuildFile` / `PBXFileReference` entries, so `git rm` cleaned everything up on its own. The build picked up the new file list automatically.

## Info.plist + Entitlements Verification (APP-14)

`Wrangle/Info.plist` is the source-of-truth; `build/` Info.plists are products
and excluded from the sweep.

`grep -iE 'license|trial|URLSchemes|LSHandlerRank' Wrangle/Info.plist` returned **4 hits, all `LSHandlerRank`**:

| Line | Key | Value | Category |
| ---- | --- | ----- | -------- |
| 12 | `LSHandlerRank` | `Alternate` | Markdown doc-type association |
| 25 | `LSHandlerRank` | `Alternate` | JSON doc-type association |
| 37 | `LSHandlerRank` | `Alternate` | YAML doc-type association |
| 49 | `LSHandlerRank` | `Alternate` | Plain Text doc-type association |

**Exemption rationale:** these four hits are NOT license / trial / URL-scheme
/ feature-flag entries — they are Apple's standard `LSHandlerRank` keys
under `CFBundleDocumentTypes`, ranking Wrangle as an `Alternate` editor for
the four document types it can open. The APP-14 grep pattern is overbroad
relative to its semantic intent (CONTEXT.md APP-14: *"no license / trial /
URL-scheme / feature-flag entries"*). `LSHandlerRank` is the **document-type
rank** key, not a URL-scheme or feature-flag. URL-scheme registration would
be `CFBundleURLTypes` / `CFBundleURLSchemes` — neither exists in
`Wrangle/Info.plist`. APP-14 satisfied semantically.

**Entitlements file count:** 0 `.entitlements` files in
`./**` (excluding `.git`, `.planning`, `build`). APP-14 entitlements clause
is vacuously satisfied — no entitlements file exists to grep.

## APP-13 Preliminary Forbidden-Token Audit

`grep -rn` sweep over `wrangle/` and `scripts/` against the CONTEXT.md
forbidden token list:

| Token | Pattern | Hits | Status |
| ----- | ------- | ---- | ------ |
| `$24` | literal | 0 | PASS |
| `Buy` | `\bBuy\b` | 0 | PASS |
| `Trial` | `\bTrial\b` | 0 | PASS |
| `trial` | `\btrial\b` | 0 | PASS |
| `License` | `\bLicense\b` | 0 | PASS |
| `license` | `\blicense\b` | 1 | EXEMPT (see below) |
| `LemonSqueezy` / `lemonsqueezy` | case-insensitive | 0 | PASS |
| `wrangleapp.dev/api/trial` (APP-08 explicit) | literal | 0 | PASS |
| `wrangleapp.dev` | literal | 4 | PENDING-PLAN-02 (see below) |

### Exemption: `license` (1 hit)

```
wrangle/Sidebar/FileTreeNode.swift:49:        "license", "licence", "readme", "changelog", "contributing",
```

This is a **filename-pattern matcher** used by the file-tree to recognize
common repo-metadata file basenames (`license`, `licence`, `readme`,
`changelog`, `contributing`) for special icon/styling treatment. It is the
exact pattern CONTEXT.md `<canonical_refs>` APP-13 calls out as exempt:
*"excluding the future repo-root LICENSE file"*. When Phase 14 (REPO-01)
ships the MIT `LICENSE` file at the repo root, this matcher is what gives
that file a recognized icon in the file tree. It is the OPPOSITE of a
commercial-license surface — it's repo-metadata file detection that
**enables** the OSS conversion. **Exempt; leave as-is.**

### Pending Plan 02: `wrangleapp.dev` (4 hits)

```
wrangle/wrangleApp.swift:172:                        string: "wrangleapp.dev",
wrangle/wrangleApp.swift:175:                            .link: URL(string: "https://wrangleapp.dev")! as Any,
wrangle/App/UpdateChecker.swift:12:    private static let versionEndpoint = "https://wrangleapp.dev/api/version.json"
wrangle/App/UpdateChecker.swift:27:        let urlString = downloadURL.isEmpty ? "https://wrangleapp.dev/download" : downloadURL
```

All four are PENDING-PLAN-02 — Plan 02 is the contractual owner of the
About-panel D-12 dual-link rewrite (adds `github.com/J-Krush/wrangle` next
to the existing `wrangleapp.dev` link; both survive) AND the `UpdateChecker`
D-09 / D-11 endpoint repoint (swaps `wrangleapp.dev/api/version.json` for
`api.github.com/repos/J-Krush/wrangle/releases/latest` and drops the
`/download` fallback). Plan 01's `<read_first>` for Task 2 explicitly
forbids touching either of these files.

**Plan 01 forecast vs. reality:** Plan 01's Task 3 acceptance predicted
"exactly 1 hit in `wrangleApp.swift`" — the actual count is 4 because
(a) the About panel's NSAttributedString writes `wrangleapp.dev` twice
(once as the displayed string, once inside the `.link` URL attribute), and
(b) Plan 01's forecast neglected `UpdateChecker.swift`'s two `wrangleapp.dev`
constants which Plan 02 explicitly rewrites. All four matches are
plan-handoff residue, not violations. The expected post-Plan-02 count is
**2 hits** (just the About-panel's display string + `.link` URL, both
surviving deliberately per D-12).

### Final Exemption List (rolled forward to Plan 02 audit)

| Surface | Token | Rationale | Resolution Plan |
| ------- | ----- | --------- | --------------- |
| `wrangle/Sidebar/FileTreeNode.swift:49` | `"license", "licence"` | Repo-metadata filename matcher; enables Phase 14's MIT LICENSE file to render with a known icon in the file tree | Permanent — exempt forever |
| `wrangle/wrangleApp.swift:172,175` (About panel) | `wrangleapp.dev` | Landing-page credits link (D-12); a sibling `github.com/J-Krush/wrangle` link is added by Plan 02 — both survive | Plan 02 rewrites the block; both URLs survive intentionally |
| `wrangle/App/UpdateChecker.swift:12,27` | `wrangleapp.dev/api/version.json`, `wrangleapp.dev/download` | Update-endpoint constants (D-09, D-11) | Plan 02 repoints to `api.github.com/repos/J-Krush/wrangle/releases/latest` and drops the `/download` fallback |
| Future `LICENSE` at repo root (Phase 14) | filename `LICENSE` | MIT license file for OSS | Phase 14 REPO-01 |
| Apple-framework type names containing `License` / `Trial` | (none currently in wrangle/) | Apple's framework substring conflicts | None present today; check at every Phase 13+ audit |

## Manual Smoke Test

Status: **Deferred to user-side verification post-execution** (autonomous
execution environment cannot drive AppKit GUI). Build artifact
(`Wrangle.app`) is signed and ready at the DerivedData Debug path.

What the launch path looks like after this plan, derived from the code:

1. `WrangleApp.body.onAppear` fires once (`coordinator.isSetupComplete`
   guards re-entry).
2. `registerWithLaunchServices()` → `setupNotifications()` →
   `setupForegroundTracking()` → `updateSystemScheme()` →
   `coordinator.updateChecker.checkForUpdate()` → `coordinator.whatsNewManager.checkOnLaunch()` →
   `removeSystemCloseMenuItems()`. The deleted `coordinator.licenseManager.loadOnLaunch()`
   line is now a contiguous gap between `checkForUpdate()` and
   `checkOnLaunch()`. Plan 02 inserts `LicenseResidueCleanup.run()` here.
3. `ContentView` renders. The outer `VStack(spacing: 0)` has collapsed
   to a bare `HStack(spacing: 0)`. `TrialBannerView()` is gone — no
   header strip renders. The `LicenseGateView()` overlay is gone — no
   modal blocks the editor on first paint.
4. Editor opens directly. No modal blocker (license / trial / paywall).
   `NotificationPermissionView` and `WhatsNewView` overlays still mount;
   `WhatsNewView` will fire on first launch only if
   `manager.shouldShowModal` returns true (i.e., `lastSeenVersion <
   currentVersion`); `NotificationPermissionView` defers to WhatsNew via
   the new D-08 clause.

**User-side smoke checklist** (run after pulling this commit and opening
in Xcode):

- [ ] Launch app from Xcode (Debug arm64).
- [ ] Confirm editor opens directly on first paint — no `LicenseGateView`
      sheet, no `TrialBannerView` strip at the top, no Preferences →
      License tab in Settings (Cmd+,).
- [ ] Create a Scratch Pad (File → New Scratch Pad / Cmd+Shift+N) — opens.
- [ ] Open a Browser tab (File → New Browser / Cmd+Option+B) — opens.
- [ ] Open Settings (Cmd+,) — single "General" tab, no "License" tab.
- [ ] About panel still shows `wrangleapp.dev` link (deliberate; Plan 02
      adds the GitHub link next to it).
- [ ] `Check for Updates...` in About menu still calls the (currently
      `wrangleapp.dev`) endpoint — Plan 02 repoints to GitHub.

## Pending Hand-off to Plan 02

Plan 02 owns the following items that interact with surfaces this plan
deliberately did NOT touch:

1. **`WhatsNewChangelog.swift` v1.3.0 entry + OSS announcement** (D-01,
   D-02, D-03, D-05) — the new "Wrangle is now free and open source" note
   with "Star on GitHub" CTA.
2. **`WhatsNewManager.swift` fresh-install filter** (D-05) — `lastSeen ==
   "0.0.0"` → `version >= "1.3.0"` guard for the launch-triggered modal.
3. **`UpdateChecker.swift` GitHub Releases repoint** (D-09, D-10, D-11) —
   `versionEndpoint` swap + `VersionInfo` -> GitHub Releases shape +
   `wrangleapp.dev/download` fallback removal.
4. **`wrangleApp.swift:165-183` About-panel dual-link rewrite** (D-12) —
   add `github.com/J-Krush/wrangle` as a second clickable credit line
   while keeping `wrangleapp.dev`.
5. **`wrangle/App/LicenseResidueCleanup.swift` new file** (D-13, D-14) —
   one-time Keychain + UserDefaults wipe inserted at the
   `wrangleApp.swift` launch slot vacated by APP-07 (between
   `updateChecker.checkForUpdate()` and `whatsNewManager.checkOnLaunch()`).
6. **Final APP-13 audit pass** — after items 3 and 4 land, the
   `wrangleapp.dev` count drops from 4 to **2** (just the About-panel
   display string + `.link` URL surviving per D-12).

## Self-Check: PASSED

- Files deleted (5/5):
  - `test ! -f wrangle/App/LicenseManager.swift` PASS
  - `test ! -f wrangle/App/LicenseGateView.swift` PASS
  - `test ! -f wrangle/App/TrialBannerView.swift` PASS
  - `test ! -f wrangle/App/LicenseSettingsView.swift` PASS
  - `test ! -f scripts/reset-license.sh` PASS
- Commits exist:
  - `535e766` (Task 1) FOUND in `git log`
  - `8cd648f` (Task 2) FOUND in `git log`
- Build: BUILD SUCCEEDED, zero new warnings
- Info.plist: clean of license / trial / URL-handler entries; 0 `.entitlements` files in tree
- APP-13 sweep: 0 hits on `$24` / `Buy` / `Trial` / `trial` / `License` / `LemonSqueezy`; `license` and `wrangleapp.dev` hits all catalogued as exempt or PENDING-PLAN-02

## Deviations from Plan

**None significant.** Three Claude's-discretion choices were made (documented
under `decisions:` above):

1. Outer `VStack(spacing: 0)` in `ContentView.swift` was collapsed to a
   bare `HStack(spacing: 0)` (planner offered either; chose collapse).
2. `TabView` wrapper in `SettingsView.swift` was retained over collapsing
   to bare `GeneralSettingsView()` (planner offered either; chose retain
   for forward-compat).
3. Inside the now-bare HStack in `ContentView.swift`, body-content
   indentation (16-space inner instead of canonical 12-space) was left
   as-is to avoid a reformat-only churn delta outside Phase 13's strip-only
   scope. Swift is whitespace-insensitive; no functional impact.

**Plan forecast under-counted `wrangleapp.dev` hits.** Plan 01's Task 3
acceptance criterion predicted "exactly 1 hit" but reality is 4 — fully
explained as 2 lines from the About-panel `NSAttributedString` (display
string + `.link` URL attribute; one logical surface, two grep lines) plus
2 from `UpdateChecker.swift` constants that Plan 02 explicitly owns
(D-09, D-11). All 4 hits are PENDING-PLAN-02 surfaces per CONTEXT.md
`<canonical_refs>`. The forecast is corrected in the "Pending Hand-off to
Plan 02" section above (post-Plan-02 count: 2, not 0). No corrective action
required — this is a planner-side forecast slip, not an execution
deviation.
