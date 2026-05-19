---
id: 13-01-strip-license-trial-paywall
phase: 13-app-de-commercialization
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - wrangle/App/AppCoordinator.swift
  - wrangle/wrangleApp.swift
  - wrangle/ContentView.swift
  - wrangle/App/SettingsView.swift
  - wrangle/App/WhatsNewView.swift
  - wrangle/App/NotificationPermissionView.swift
files_deleted:
  - wrangle/App/LicenseManager.swift
  - wrangle/App/LicenseGateView.swift
  - wrangle/App/TrialBannerView.swift
  - wrangle/App/LicenseSettingsView.swift
  - scripts/reset-license.sh
autonomous: true
requirements: [APP-01, APP-02, APP-03, APP-04, APP-05, APP-06, APP-07, APP-08, APP-09, APP-12, APP-14, APP-15]
objective: >
  Delete all five license/trial/paywall source files and strip every call site,
  predicate, and reference from the runtime app. After this plan, the v1.3 build
  compiles with no LicenseManager, LicenseGateView, TrialBannerView, or
  LicenseSettingsView symbols. SettingsView shows General only. WhatsNew and
  NotificationPermission predicates no longer reference licenseManager.
  Info.plist is verified clean.

must_haves:
  truths:
    - "App opens directly to editor — no LicenseGateView sheet renders, no TrialBannerView strip renders, no Preferences → License tab exists."
    - "No symbol named `LicenseManager`, `licenseManager`, `LicenseGateView`, `TrialBannerView`, `LicenseSettingsView`, or `SettingsTab.license` remains in `wrangle/`."
    - "`scripts/reset-license.sh` no longer exists in the working tree."
    - "App builds with zero warnings and zero errors after the strip."
  artifacts:
    - path: "wrangle/App/AppCoordinator.swift"
      provides: "AppCoordinator without licenseManager property"
      contains_not: "licenseManager"
    - path: "wrangle/App/SettingsView.swift"
      provides: "Settings scene with General tab only (TabView retained or collapsed per Claude's discretion D-15)"
      contains_not: "LicenseSettingsView"
    - path: "wrangle/ContentView.swift"
      provides: "ContentView with no TrialBannerView and no LicenseGateView"
      contains_not: "TrialBannerView"
    - path: "wrangle/wrangleApp.swift"
      provides: "wrangleApp.onAppear without loadOnLaunch()"
      contains_not: "licenseManager.loadOnLaunch"
  key_links:
    - from: "wrangle/App/WhatsNewView.swift:9"
      to: "WhatsNewManager.shouldShowModal"
      via: "predicate `if manager.shouldShowModal`"
      pattern: "if manager.shouldShowModal"
    - from: "wrangle/App/NotificationPermissionView.swift:9"
      to: "WhatsNewManager.shouldShowModal AND NotificationPermissionManager.shouldShowModal"
      via: "predicate `if manager.shouldShowModal && !coordinator.whatsNewManager.shouldShowModal`"
      pattern: "&& !coordinator.whatsNewManager.shouldShowModal"

truths:
  - "After this plan no symbol named `licenseManager`, `LicenseManager`, `LicenseGateView`, `TrialBannerView`, `LicenseSettingsView`, or `reset-license.sh` exists in `wrangle/` or `scripts/`."
  - "`WhatsNewManager.lastSeenVersion` is the single first-launch gate for both the OSS WhatsNew note (D-06) and `LicenseResidueCleanup` (D-13/D-14) — this plan removes the redundant licenseManager.needsLicense clause from both modal predicates."
  - "Info.plist (`Wrangle/Info.plist`) is verified clean of license/trial/URL-scheme/feature-flag entries per APP-14 — no edits expected."
---

<objective>
Delete `LicenseManager.swift`, `LicenseGateView.swift`, `TrialBannerView.swift`,
`LicenseSettingsView.swift`, and `scripts/reset-license.sh`. Strip every
remaining reference from `AppCoordinator.swift`, `wrangleApp.swift`,
`ContentView.swift`, `SettingsView.swift`, `WhatsNewView.swift`, and
`NotificationPermissionView.swift`. Verify `Wrangle/Info.plist` is clean.

Purpose: Wrangle is converting to free + open source for v1.3 — the
commercial surface (paywall, trial, license entry) is being torn out wholesale
per the locked decisions in `.planning/phases/13-app-de-commercialization/13-CONTEXT.md`.
This plan handles the strip; Plan 02 wires up the OSS announcement and
Keychain residue cleanup that depends on `LicenseManager`'s constants being
captured before the file is deleted (constants are pinned verbatim in
`13-CONTEXT.md` D-13 — no need to read `LicenseManager.swift` for them in
Plan 02).

Output: A compiling, license-free build with the editor opening directly on
launch.
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/phases/13-app-de-commercialization/13-CONTEXT.md
@.planning/ROADMAP.md
@.planning/REQUIREMENTS.md
@./CLAUDE.md
@docs/coding-patterns.md
</context>

<tasks>

<task type="auto" tdd="false">
  <name>Task 1: Delete the five license/trial/paywall files</name>
  <files>
    wrangle/App/LicenseManager.swift (delete),
    wrangle/App/LicenseGateView.swift (delete),
    wrangle/App/TrialBannerView.swift (delete),
    wrangle/App/LicenseSettingsView.swift (delete),
    scripts/reset-license.sh (delete)
  </files>
  <read_first>
    - .planning/phases/13-app-de-commercialization/13-CONTEXT.md (canonical decision contract — read in full)
    - wrangle/App/LicenseManager.swift (current source — confirm the four Keychain constants match D-13 verbatim before deletion: keychainService `"dev.wrangle.license"`, keychainAccount `"license-key"`, trialKeychainService `"dev.wrangle.trial"`, trialKeychainAccount `"trial-data"`, instanceIDKey `"LicenseManager.instanceID"`. If any value differs, STOP and surface the discrepancy — Plan 02's LicenseResidueCleanup depends on these exact strings.)
    - wrangle/App/LicenseGateView.swift (current source — confirm no symbols outside this file depend on it before deletion)
    - wrangle/App/TrialBannerView.swift (current source — confirm no symbols outside this file depend on it)
    - wrangle/App/LicenseSettingsView.swift (current source — confirm no symbols outside this file depend on it; SettingsView holds the only reference)
    - scripts/reset-license.sh (current source — confirm script is the orphan dev-utility CONTEXT.md describes)
  </read_first>
  <action>
    Delete five files via `git rm`:
    1. `wrangle/App/LicenseManager.swift` (per APP-01)
    2. `wrangle/App/LicenseGateView.swift` (per APP-02)
    3. `wrangle/App/TrialBannerView.swift` (per APP-03)
    4. `wrangle/App/LicenseSettingsView.swift` (per APP-04)
    5. `scripts/reset-license.sh` (per APP-05)

    Use `git rm <path>` (NOT `rm`) so the deletion is staged for the eventual commit.

    Do NOT remove the files from `Wrangle.xcodeproj/project.pbxproj` by hand —
    Xcode regenerates the file membership on next open; the executor confirms
    the build in Task 3 (the build will fail until Task 2 strips the call
    sites, then succeed). If `xcodebuild` reports "no such file" referencing
    a deleted Swift file, the executor edits `project.pbxproj` to remove the
    file reference (search for the basename, delete the `PBXBuildFile` and
    `PBXFileReference` entries, and the membership entry in `PBXSourcesBuildPhase`).

    No edits to runtime Swift in this task — call sites are handled in Task 2.
  </action>
  <verify>
    <automated>test ! -f wrangle/App/LicenseManager.swift && test ! -f wrangle/App/LicenseGateView.swift && test ! -f wrangle/App/TrialBannerView.swift && test ! -f wrangle/App/LicenseSettingsView.swift && test ! -f scripts/reset-license.sh && git status --porcelain | grep -E '^D\s+(wrangle/App/(LicenseManager|LicenseGateView|TrialBannerView|LicenseSettingsView)\.swift|scripts/reset-license\.sh)' | wc -l | tr -d ' '</automated>
  </verify>
  <acceptance_criteria>
    - `test ! -f wrangle/App/LicenseManager.swift` exits 0
    - `test ! -f wrangle/App/LicenseGateView.swift` exits 0
    - `test ! -f wrangle/App/TrialBannerView.swift` exits 0
    - `test ! -f wrangle/App/LicenseSettingsView.swift` exits 0
    - `test ! -f scripts/reset-license.sh` exits 0
    - `git status --porcelain` shows five `D` lines, one per deleted file
    - `find scripts -name 'reset-license*'` returns no output
  </acceptance_criteria>
  <done>
    All five files are removed from the working tree and staged for deletion
    in git. No edits made to remaining Swift files yet — the build is
    intentionally broken until Task 2 strips the call sites.
  </done>
</task>

<task type="auto" tdd="false">
  <name>Task 2: Strip license plumbing from runtime files</name>
  <files>
    wrangle/App/AppCoordinator.swift,
    wrangle/wrangleApp.swift,
    wrangle/ContentView.swift,
    wrangle/App/SettingsView.swift,
    wrangle/App/WhatsNewView.swift,
    wrangle/App/NotificationPermissionView.swift
  </files>
  <read_first>
    - .planning/phases/13-app-de-commercialization/13-CONTEXT.md (decisions D-07, D-08, plus the `<canonical_refs>` line-number map)
    - wrangle/App/AppCoordinator.swift (current source — see line 12 `var licenseManager = LicenseManager()` for removal per APP-06; line 15 `var selectedSettingsTab: SettingsTab = .general` stays as-is)
    - wrangle/wrangleApp.swift (current source — see line 118 `coordinator.licenseManager.loadOnLaunch()` for removal per APP-07; About-panel NSAttributedString block at lines 167-183 is OUT OF SCOPE for this plan and changed in Plan 02 D-12)
    - wrangle/ContentView.swift (current source — see line 43 `TrialBannerView()` removal per APP-03 and line 203 `LicenseGateView()` removal per APP-02; outer VStack at line 42 is Claude's discretion per CONTEXT.md — either collapse to bare HStack or keep VStack for future banner insertion; either is acceptable, NO correctness issue. Match line 187 comment update if VStack collapses.)
    - wrangle/App/SettingsView.swift (current source — see line 5 `case license` for removal and lines 20-25 LicenseSettingsView tab block for removal per APP-04; TabView wrapper retention is Claude's discretion — keep TabView with only General for forward-compat OR collapse to bare `GeneralSettingsView()`, either acceptable)
    - wrangle/App/WhatsNewView.swift (current source — see line 9 predicate `if !coordinator.licenseManager.needsLicense && manager.shouldShowModal` per D-07 → collapse to `if manager.shouldShowModal`)
    - wrangle/App/NotificationPermissionView.swift (current source — see line 9 predicate per D-08 → strip `!coordinator.licenseManager.needsLicense &&` AND add `&& !coordinator.whatsNewManager.shouldShowModal` so the new predicate reads `if manager.shouldShowModal && !coordinator.whatsNewManager.shouldShowModal`)
  </read_first>
  <action>
    Apply six edits, each tied to a specific decision/requirement:

    1. **`wrangle/App/AppCoordinator.swift` line 12** — Delete the line
       `var licenseManager = LicenseManager()` (per D-canonical_refs and APP-06).
       Do NOT touch line 15 `var selectedSettingsTab: SettingsTab = .general` —
       the property survives; only the `.license` enum case is removed in
       step 4 below.

    2. **`wrangle/wrangleApp.swift` line 118** — Delete the line
       `coordinator.licenseManager.loadOnLaunch()` (per APP-07). The lines
       immediately surrounding stay as-is. NOTE: Plan 02 inserts
       `LicenseResidueCleanup.run()` at this same slot per D-14; this plan
       deletes the LicenseManager call without yet adding the cleanup line.
       The launch path between line 117 (`coordinator.updateChecker.checkForUpdate()`)
       and line 119 (`coordinator.whatsNewManager.checkOnLaunch()`) becomes
       contiguous after this edit.

    3. **`wrangle/ContentView.swift`** — Two deletions:
       - Line 43: delete the `TrialBannerView()` invocation (per APP-03).
       - Line 203: delete the `LicenseGateView()` invocation (per APP-02).
       Outer `VStack(spacing: 0)` at line 42 and trailing `} // outer VStack`
       comment at line 187: Claude's discretion — collapse VStack to bare
       HStack OR retain VStack with only the HStack child. Either passes
       acceptance. If collapsed, update the line 187 comment accordingly.

    4. **`wrangle/App/SettingsView.swift`** — Two deletions:
       - Line 5: delete `case license` from the `SettingsTab` enum
         (the enum becomes single-case `case general`; per APP-04).
       - Lines 20-25: delete the `LicenseSettingsView()` tab declaration
         (the entire block including `.tabItem`, `.tag(.license)`).
       TabView wrapper retention: Claude's discretion per CONTEXT.md — either
       keep `TabView { GeneralSettingsView()... }` for forward-compat OR
       replace the TabView with bare `GeneralSettingsView().frame(minWidth: 450, minHeight: 300)`.

    5. **`wrangle/App/WhatsNewView.swift` line 9** — Replace
       `if !coordinator.licenseManager.needsLicense && manager.shouldShowModal {`
       with
       `if manager.shouldShowModal {`
       (per D-07).

    6. **`wrangle/App/NotificationPermissionView.swift` line 9** — Replace
       `if !coordinator.licenseManager.needsLicense && manager.shouldShowModal {`
       with
       `if manager.shouldShowModal && !coordinator.whatsNewManager.shouldShowModal {`
       (per D-08 — license clause stripped AND WhatsNew-wins clause added so
       both can't fire on the same launch).

    Do not introduce any new symbols, properties, or files in this task.
    Do not touch the About-panel NSAttributedString block in `wrangleApp.swift`
    (Plan 02 owns the D-12 dual-link update).
    Do not touch `UpdateChecker.swift` (Plan 02 owns the D-09/D-10/D-11 repoint).
    Do not touch `WhatsNewChangelog.swift` / `WhatsNewManager.swift` (Plan 02
    owns the v1.3.0 entry + fresh-install filter D-01/D-02/D-03/D-05).
  </action>
  <verify>
    <automated>grep -c 'licenseManager' wrangle/App/AppCoordinator.swift wrangle/wrangleApp.swift wrangle/ContentView.swift wrangle/App/WhatsNewView.swift wrangle/App/NotificationPermissionView.swift | awk -F: '{s+=$2} END {print s}'</automated>
  </verify>
  <acceptance_criteria>
    - `grep -c 'licenseManager' wrangle/App/AppCoordinator.swift` returns 0
    - `grep -c 'licenseManager' wrangle/wrangleApp.swift` returns 0
    - `grep -c 'licenseManager' wrangle/ContentView.swift` returns 0
    - `grep -c 'licenseManager' wrangle/App/WhatsNewView.swift` returns 0
    - `grep -c 'licenseManager' wrangle/App/NotificationPermissionView.swift` returns 0
    - `grep -c 'TrialBannerView' wrangle/ContentView.swift` returns 0
    - `grep -c 'LicenseGateView' wrangle/ContentView.swift` returns 0
    - `grep -c 'LicenseSettingsView' wrangle/App/SettingsView.swift` returns 0
    - `grep -c 'case license' wrangle/App/SettingsView.swift` returns 0
    - `grep -c 'loadOnLaunch' wrangle/wrangleApp.swift` returns 0
    - `grep -c 'if manager.shouldShowModal {' wrangle/App/WhatsNewView.swift` returns 1
    - `grep -c '&& !coordinator.whatsNewManager.shouldShowModal' wrangle/App/NotificationPermissionView.swift` returns 1
    - `grep -rn 'licenseManager\|LicenseManager\|LicenseGateView\|TrialBannerView\|LicenseSettingsView' wrangle/ scripts/` returns no matches (only files containing these symbols are deleted in Task 1)
  </acceptance_criteria>
  <done>
    All six call-site edits applied; no `licenseManager` / `LicenseGateView`
    / `TrialBannerView` / `LicenseSettingsView` references remain in
    `wrangle/`. SettingsTab enum has only `.general`. WhatsNewView and
    NotificationPermissionView predicates are updated per D-07/D-08.
  </done>
</task>

<task type="auto" tdd="false">
  <name>Task 3: Build clean + Info.plist verification + APP-13 grep audit (preliminary)</name>
  <files>
    Wrangle/Info.plist (read-only verification)
  </files>
  <read_first>
    - Wrangle/Info.plist (current contents — confirm no entries matching `license` / `trial` / URL-scheme / feature-flag patterns; per APP-14 this file is expected clean — no edits)
    - .planning/phases/13-app-de-commercialization/13-CONTEXT.md (see `<specifics>` section — APP-13 forbidden tokens and the explicit exemption list for Apple-framework type names and the deliberate `wrangleapp.dev` About-panel survival; note that Plan 02 changes the About-panel content, so this preliminary grep run will still show one `wrangleapp.dev` hit in `wrangleApp.swift:173-176` — that hit is the OLD About-panel content awaiting Plan 02's rewrite, so this task documents it as EXPECTED-pending-Plan-02 rather than failing)
  </read_first>
  <action>
    Three verifications, no source edits:

    1. **Build clean (APP-15)**: Run a Debug build for the `Wrangle` scheme on
       an arm64 macOS 15+ destination and confirm:
       - Exit code 0
       - No new warnings introduced by this plan (compare to the pre-strip
         baseline — any warning that existed before Phase 13 is acceptable to
         carry; new warnings caused by Task 1+2 edits are not)
       - Smoke-test the binary manually: launch, confirm editor loads with no
         modal blocking, create a Scratch Pad, open a Browser tab. Document
         the smoke-test outcome in SUMMARY.

       Build command:
       `xcodebuild -project Wrangle.xcodeproj -scheme Wrangle -configuration Debug -destination 'platform=macOS,arch=arm64' build`

       If the build fails due to dangling `LicenseManager` / `LicenseGateView`
       / `TrialBannerView` / `LicenseSettingsView` references in
       `Wrangle.xcodeproj/project.pbxproj`, manually remove those file
       references from the pbxproj (search for the basenames; delete the
       associated `PBXBuildFile`, `PBXFileReference`, and `PBXSourcesBuildPhase`
       membership entries) and re-run the build.

    2. **Info.plist + entitlements verification (APP-14)**: Read
       `Wrangle/Info.plist` and confirm no entries match `license`, `trial`,
       `Trial`, `License`, `URL-scheme`, `LSHandlerRank`, or feature-flag
       patterns. Per CONTEXT.md `<canonical_refs>` APP-14 is satisfied by
       verification only — no edits expected. Note there is only one
       Info.plist (`Wrangle/Info.plist`); the lowercase `wrangle/` source
       directory has no Info.plist.

       APP-14 also explicitly covers `.entitlements` files. Sweep the repo
       for entitlements files and grep them for the same forbidden patterns:

       Verification commands:
       - `grep -iE 'license|trial|URLSchemes|LSHandlerRank' Wrangle/Info.plist`
       - `find . -name '*.entitlements' -not -path './.planning/*' -not -path './.git/*' -exec grep -iE 'license|trial|URLSchemes|LSHandlerRank' {} + 2>/dev/null`

       Document in SUMMARY: whether any `.entitlements` files were found and
       the count of forbidden-pattern hits (expected: 0 hits regardless of
       whether entitlements files exist).

    3. **APP-13 preliminary grep audit (PARTIAL — final pass runs in Plan 02
       after the About-panel D-12 rewrite)**: Run the forbidden-token sweep
       across `wrangle/` and `scripts/`:

       Forbidden tokens (per CONTEXT.md `<specifics>` + ROADMAP success
       criterion 2):
       - `\$24`
       - `Buy` (case-sensitive)
       - `Trial` (case-sensitive)
       - `trial` (case-sensitive)
       - `License` (case-sensitive — exclude `LICENSE` repo-root file when
         it lands in Phase 14)
       - `license` (case-sensitive — exclude `LICENSE` repo-root file)
       - `LemonSqueezy` (case-insensitive)

       Sweep command:
       `grep -rnE '\$24|Buy|Trial|trial|License|license|[Ll]emon[Ss]queezy' wrangle/ scripts/ 2>/dev/null`

       Expected after this plan:
       - Zero hits for `\$24`, `Buy`, `Trial`, `trial`, `LemonSqueezy`
       - Zero hits for `License` / `license` in `wrangle/` (no Apple-framework
         type names containing these substrings are in the current codebase —
         verified by reading current `wrangle/` source). If new hits appear,
         catalog them in SUMMARY as an "exemption list" per
         `<security_threat_model_requirement>` quality gate.
       - ONE hit for `wrangleapp.dev` in `wrangle/wrangleApp.swift:173-176`
         (the About-panel NSAttributedString — Plan 02 rewrites this block
         per D-12 to add `github.com/J-Krush/wrangle` as a second link; the
         `wrangleapp.dev` link DELIBERATELY survives per D-12). Document this
         as PENDING-PLAN-02 in SUMMARY.

       Note: `wrangleapp.dev` is NOT in the APP-13 forbidden list (per
       `<specifics>` in CONTEXT.md) — its About-panel survival is intentional
       and consistent with APP-13.

       Final exemption list documented in SUMMARY:
       - `wrangleapp.dev` in About-panel credits (line 173-176 pre-Plan-02;
         line will shift slightly post-Plan-02 when the second link is added)
         — INTENTIONAL per D-12
       - `LICENSE` repo-root file — does not exist yet in Phase 13; will
         appear in Phase 14 and is exempt then
       - Apple-framework type names containing `License` / `Trial` substrings
         — none currently present in `wrangle/` (verified empty)
  </action>
  <verify>
    <automated>xcodebuild -project Wrangle.xcodeproj -scheme Wrangle -configuration Debug -destination 'platform=macOS,arch=arm64' build 2>&1 | grep -E 'BUILD SUCCEEDED|BUILD FAILED' | head -1</automated>
  </verify>
  <acceptance_criteria>
    - `xcodebuild -project Wrangle.xcodeproj -scheme Wrangle -configuration Debug -destination 'platform=macOS,arch=arm64' build` exits 0
    - Build output contains `BUILD SUCCEEDED`
    - `xcodebuild ... build 2>&1 | grep -iE 'warning:' | grep -vE '^(ld|--- xcodebuild|note:)' | wc -l` returns 0 new warnings introduced by this plan (baseline warnings allowed; new symbol-removal warnings are not)
    - `grep -iE 'license|trial|URLSchemes|LSHandlerRank' Wrangle/Info.plist | wc -l | tr -d ' '` returns 0
    - `find . -name '*.entitlements' -not -path './.planning/*' -not -path './.git/*' -exec grep -iE 'license|trial|URLSchemes|LSHandlerRank' {} + 2>/dev/null | wc -l | tr -d ' '` returns 0 (APP-14 entitlements clause — vacuously true if no entitlements files exist)
    - `grep -rn 'wrangleapp.dev/api/trial' wrangle/ scripts/ 2>/dev/null | wc -l | tr -d ' '` returns 0 (APP-08 explicit trial-endpoint sweep — implicitly covered by the `wrangleapp.dev` count assertion below, but explicit assertion documents the requirement)
    - `grep -rnE '\$24|\\bBuy\\b|\\bTrial\\b|\\btrial\\b|[Ll]emon[Ss]queezy' wrangle/ scripts/ 2>/dev/null | wc -l | tr -d ' '` returns 0
    - `grep -rnE '\\bLicense\\b|\\blicense\\b' wrangle/ scripts/ 2>/dev/null` returns no matches OR all matches are documented in SUMMARY as exempt Apple-framework type names (none expected as of this plan)
    - `grep -rn 'wrangleapp.dev' wrangle/ scripts/ 2>/dev/null | wc -l | tr -d ' '` returns exactly 1 (the About-panel NSAttributedString in `wrangleApp.swift` — PENDING-PLAN-02 D-12)
    - SUMMARY documents: (a) build clean confirmation, (b) Info.plist + entitlements clean confirmation (with entitlements file count, even if 0), (c) APP-13 preliminary grep results with the one expected `wrangleapp.dev` hit catalogued as PENDING-PLAN-02
  </acceptance_criteria>
  <done>
    Build clean, no new warnings, Info.plist verified clean (APP-14), APP-13
    preliminary grep audit catalogued (final pass in Plan 02 after D-12
    rewrite). Editor opens with no license/trial blockers on a manual smoke
    launch.
  </done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

This plan introduces no new trust boundaries. All changes are deletions or
edits to existing in-process Swift code. No new network endpoints, no new
authentication paths, no new data storage, no new IPC.

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-13-01 | Information Disclosure | Deleted `LicenseManager.swift` Keychain code paths | accept | The four Keychain service/account constants are pinned in `13-CONTEXT.md` D-13 before deletion; Plan 02's `LicenseResidueCleanup` uses those constants verbatim — no information lost in the deletion. No PII flows through any of the deleted files at the moment of deletion. |
| T-13-02 | Tampering | Deleted `scripts/reset-license.sh` | accept | Dev-only utility script with no production code path; deletion has no security impact. |
| T-13-03 | Denial of Service | `WhatsNewView` / `NotificationPermissionView` predicate edits | accept | Predicates collapse from compound boolean to simpler boolean (or extend by one clause for NotificationPermissionView). No new failure modes introduced; semantic is "show modal IFF the underlying manager flag is set, with WhatsNew winning if both compete." |
| T-13-04 | Spoofing / Tampering / Elevation | Info.plist (APP-14) | accept | Verification-only read; no edits to entitlements or URL schemes. No attack surface change. |

This plan covers strip-only work — Plan 02's `<threat_model>` covers the
Keychain deletion helper (`LicenseResidueCleanup`) and the new GitHub HTTPS
endpoint (`UpdateChecker` repoint).

**No new authentication, no new authorization, no new data storage. All
changes are subtractive or constant-time predicate edits.**
**Block-on:** high severity threats. None identified for this plan.
</threat_model>

<verification>
- Maps to ROADMAP §Phase 13 **Success Criterion 1** — App opens directly to
  editor, no LicenseGateView sheet, no TrialBannerView strip, no Preferences →
  License tab. Verified by Task 2 grep + Task 3 manual smoke launch.
- Maps to ROADMAP §Phase 13 **Success Criterion 2** (partial) — Grep for
  `$24`, `Buy`, `Trial`/`trial`, `License`/`license`, `LemonSqueezy` returns
  zero. `wrangleapp.dev` reduced to one expected hit (Plan 02 finishes).
- Maps to ROADMAP §Phase 13 **Success Criterion 4** — App builds clean with
  no new warnings. Smoke test (editor → Scratch Pad → Browser tab) passes.
- Maps to ROADMAP §Phase 13 **Success Criterion 5** — `git status` shows
  `D` for all five deleted files.
</verification>

<success_criteria>
- All five files deleted from working tree and staged in git.
- All six call-site edits applied with concrete grep evidence (zero hits for
  the stripped symbols in the remaining `wrangle/` tree).
- Build succeeds for arm64 macOS 15+ Debug configuration with no new
  warnings caused by this plan.
- `Wrangle/Info.plist` verified clean of license/trial/URL-scheme/feature-flag
  entries — APP-14 satisfied.
- APP-13 preliminary grep audit catalogues all forbidden-token hits as zero
  except the one deliberate `wrangleapp.dev` survival in About-panel credits
  (handled by Plan 02 D-12).
- Manual smoke launch confirms editor opens with no modal blocker.
</success_criteria>

<output>
Create `.planning/phases/13-app-de-commercialization/13-01-SUMMARY.md` documenting:
- Files deleted (5) and call-site edits applied (6)
- Build outcome (BUILD SUCCEEDED, no new warnings)
- Info.plist verification result (clean)
- APP-13 preliminary grep results with the documented exemption list
- Manual smoke-test outcome (editor opens → Scratch Pad created → Browser
  tab opened, with no license/trial modal blocker)
- Pending hand-off to Plan 02: About-panel D-12 rewrite still needed before
  the final APP-13 audit can declare zero `wrangleapp.dev` hits → zero;
  Plan 02 also adds `LicenseResidueCleanup` at the wrangleApp.swift launch
  slot vacated by APP-07.
</output>
