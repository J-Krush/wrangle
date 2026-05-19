---
id: 13-03-test-target-wireup
phase: 13-app-de-commercialization
plan: 03
type: execute
wave: 3
depends_on: [13-02-oss-note-residue-cleanup-and-update-repoint]
files_modified:
  - Wrangle.xcodeproj/project.pbxproj
files_created:
  - Wrangle.xcodeproj/xcshareddata/xcschemes/Wrangle.xcscheme
autonomous: false
requirements: []
objective: >
  Wire up a `WrangleTests` Swift Testing target in `Wrangle.xcodeproj` so the
  seven existing test files (5 pre-existing + 2 from Plan 13-02) actually run
  under `xcodebuild test`. Closes the test-execution gap surfaced by Plan
  13-02 and satisfies the user's `feedback_testing_priority` memory before
  v1.3 ships.

must_haves:
  truths:
    - "`xcodebuild test -project Wrangle.xcodeproj -scheme Wrangle -destination 'platform=macOS,arch=arm64'` exits 0."
    - "All 7 test files in `WrangleTests/` (EditorDocumentTests, FileTypeTests, LicenseResidueCleanupTests, LinkRouterTests, MarkdownParserTests, TokenCounterTests, WhatsNewManagerTests) build into the target and execute."
    - "The 4 WhatsNewManagerTests tests and 4 LicenseResidueCleanupTests tests added in Plan 13-02 pass."
    - "The 5 pre-existing tests (EditorDocument, FileType, LinkRouter, MarkdownParser, TokenCounter) either pass or have their failures triaged in SUMMARY — any non-trivial fix is out of scope and gets logged as a follow-up."
    - "The shared scheme `Wrangle.xcscheme` is committed to `Wrangle.xcodeproj/xcshareddata/xcschemes/` with the Test action wired to `WrangleTests`."
  artifacts:
    - path: "Wrangle.xcodeproj/project.pbxproj"
      provides: "Project file with a `WrangleTests` PBXNativeTarget (productType `com.apple.product-type.bundle.unit-test`), host application `Wrangle`, bundle identifier `Wrangle.WrangleTests`, deployment target macOS 15.0, Swift Testing capability enabled"
      contains: "WrangleTests"
    - path: "Wrangle.xcodeproj/xcshareddata/xcschemes/Wrangle.xcscheme"
      provides: "Shared scheme with TestAction.Testables referencing WrangleTests"
      contains: "WrangleTests"
  key_links:
    - from: "WrangleTests/WhatsNewManagerTests.swift"
      to: "wrangle/App/WhatsNewManager.swift"
      via: "@testable import Wrangle + WhatsNewManager().visibleEntries"
      pattern: "@testable import Wrangle"
    - from: "WrangleTests/LicenseResidueCleanupTests.swift"
      to: "wrangle/App/LicenseResidueCleanup.swift"
      via: "@testable import Wrangle + LicenseResidueCleanup.run()"
      pattern: "@testable import Wrangle"

truths:
  - "The `WrangleTests/` directory has existed since at least March 2026 with 5 untargeted test files (EditorDocument, FileType, LinkRouter, MarkdownParser, TokenCounter). Plan 13-02 added 2 more (WhatsNewManager, LicenseResidueCleanup). None have ever run via `xcodebuild test` — this plan closes that pre-existing gap, not just the Phase 13 portion."
  - "The current `Wrangle.xcodeproj` has no shared schemes — `Wrangle.xcodeproj/xcshareddata/xcschemes/` does not exist. Sharing the scheme is part of this plan so the test target is reproducibly accessible to CI / other contributors."
  - "All 7 test files use Swift Testing (`@Suite` / `@Test` / `#expect`), not XCTestCase. The target must enable the Swift Testing framework (Xcode 16+ default for new unit-test bundles)."
  - "Pre-existing tests may have bit-rotted across the v1.2 / v1.3 refactors — triage in SUMMARY, fix only trivially-broken assertions in scope, defer non-trivial fixes to a follow-up."
---

<objective>
Add a `WrangleTests` Swift Testing target to `Wrangle.xcodeproj`, include all
seven `.swift` files currently in the `WrangleTests/` directory as target
members, share the `Wrangle.xcscheme` so the Test action is reproducible,
and verify `xcodebuild test` exits 0 with the WhatsNewManager + LicenseResidueCleanup
tests green.

Purpose: Plan 13-02 shipped 8 unit tests that cannot currently execute because
`Wrangle.xcodeproj` lists only the `Wrangle` app target. Five additional test
files have been sitting unrun in `WrangleTests/` since at least March 2026.
Per the user's `feedback_testing_priority` memory ("prioritize unit tests and
plan for e2e/integration testing on all work"), shipping v1.3 with a
non-functional test infrastructure is unacceptable. This plan wires up the
target so future plans can land tests that actually verify behavior.

Output: A runnable `xcodebuild test` invocation that executes the 7 test
files, with at minimum the 8 Plan-13-02 tests passing.
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/phases/13-app-de-commercialization/13-CONTEXT.md
@.planning/phases/13-app-de-commercialization/13-02-SUMMARY.md
@.planning/STATE.md
@./CLAUDE.md

<interfaces>
Existing test files in `WrangleTests/` (all use Swift Testing, all use
`@testable import Wrangle`):

- `EditorDocumentTests.swift` (Mar 6, 4449 bytes)
- `FileTypeTests.swift` (Mar 6, 3391 bytes)
- `LicenseResidueCleanupTests.swift` (May 19, 6099 bytes — from Plan 13-02)
- `LinkRouterTests.swift` (Apr 21, 5681 bytes)
- `MarkdownParserTests.swift` (Mar 6, 7235 bytes)
- `TokenCounterTests.swift` (Mar 6, 1914 bytes)
- `WhatsNewManagerTests.swift` (May 19, 5015 bytes — from Plan 13-02)

No Xcode test target currently exists. No shared schemes currently exist
(only user-local `xcuserdata` schemes). Both gaps land in this plan.

Bundle identifier convention from Wave 2 inspection: app bundle is `Wrangle`,
so the test bundle is `Wrangle.WrangleTests`. Deployment target matches the
app: macOS 15.0 (per `MACOSX_DEPLOYMENT_TARGET` in `project.pbxproj`).
</interfaces>
</context>

<tasks>

<task type="manual" tdd="false">
  <name>Task 1: User adds the WrangleTests target via Xcode GUI (interactive checkpoint)</name>
  <files>
    Wrangle.xcodeproj/project.pbxproj (Xcode rewrites)
  </files>
  <read_first>
    - This PLAN.md (this section — confirm exact settings before clicking)
  </read_first>
  <action>
    The executor PAUSES at this task and surfaces an `AskUserQuestion` (or
    equivalent interactive checkpoint) asking the user to perform the
    following Xcode GUI steps. Hand-editing `project.pbxproj` to add a new
    `PBXNativeTarget` is fragile — Xcode's "File → New → Target" path is
    safer and produces a canonical project structure that survives future
    Xcode upgrades.

    User-driven steps (executor confirms in SUMMARY after the user reports done):

    1. Open `Wrangle.xcodeproj` in Xcode.
    2. **File → New → Target…** (or Project Navigator → Wrangle (project node)
       → Targets → "+" at the bottom).
    3. Pick the **macOS** tab → **Unit Testing Bundle** template → Next.
    4. Configure the target with these exact settings:
       - Product Name: `WrangleTests`
       - Team: (leave default — same as Wrangle app target)
       - Organization Identifier: (auto-fills to match Wrangle)
       - Bundle Identifier: `Wrangle.WrangleTests` (Xcode usually computes this)
       - Language: **Swift**
       - Testing System: **Swift Testing** (NOT XCTest — the existing files
         all use `@Suite` / `@Test`)
       - Target to be Tested: **Wrangle** (the app target)
       - Project: Wrangle
       - Finish.
    5. Xcode creates a `WrangleTests/` group in the navigator (or merges
       into the existing one) and may add a placeholder `WrangleTests.swift`
       inside. Leave the placeholder for now — Task 2 deletes it.
    6. **Product → Scheme → Manage Schemes…**
       Check the "Shared" checkbox next to `Wrangle`. This creates
       `Wrangle.xcodeproj/xcshareddata/xcschemes/Wrangle.xcscheme` on
       disk. Close the sheet.
    7. **Product → Scheme → Edit Scheme… → Test → Info tab → "+" under Test
       targets → WrangleTests → Add**. (Xcode usually auto-adds this when
       a new test target is created, but verify.) Close the sheet.
    8. Quit Xcode (or just close the project). Return to the terminal and
       run `git status` — you should see:
       - `Wrangle.xcodeproj/project.pbxproj` modified
       - `Wrangle.xcodeproj/xcshareddata/xcschemes/Wrangle.xcscheme` new
       - Possibly a new `WrangleTests/WrangleTests.swift` placeholder file
       - Possibly Xcode-private files in `Wrangle.xcodeproj/xcuserdata/`
         (these are git-ignored or should be — leave them out of the commit)
    9. Tell the executor "done" (or equivalent). The executor proceeds to
       Task 2.

    The executor's role in this task is purely to validate that the
    expected files appeared and the target was created with Swift Testing
    selected. Validation commands:

    - `xcodebuild -project Wrangle.xcodeproj -list 2>&1 | grep -E '^\s+(WrangleTests|Wrangle)$'`
      should show both `Wrangle` and `WrangleTests` under Targets.
    - `test -f Wrangle.xcodeproj/xcshareddata/xcschemes/Wrangle.xcscheme`
      should exit 0.
    - `xcodebuild test -project Wrangle.xcodeproj -scheme Wrangle -destination 'platform=macOS,arch=arm64' -dry-run 2>&1 | head -5`
      should NOT error with "Scheme Wrangle is not currently configured
      for the test action" — if it does, the user missed the
      "Edit Scheme → Test → Add WrangleTests" step.
  </action>
  <verify>
    <automated>xcodebuild -project Wrangle.xcodeproj -list 2>&1 | grep -c WrangleTests</automated>
  </verify>
  <acceptance_criteria>
    - `xcodebuild -project Wrangle.xcodeproj -list` shows `WrangleTests` under Targets
    - `Wrangle.xcodeproj/xcshareddata/xcschemes/Wrangle.xcscheme` exists
    - `xcodebuild test ... -dry-run` does not error on "scheme not configured for test"
    - User has confirmed (via the executor's checkpoint) that they followed steps 1-9
  </acceptance_criteria>
  <done>
    `WrangleTests` target exists in the project. Shared scheme committed.
    The test target may or may not include the right files yet — Task 2
    fixes the file membership.
  </done>
</task>

<task type="auto" tdd="false">
  <name>Task 2: Fix WrangleTests target membership (include all 7 real tests, drop placeholder)</name>
  <files>
    Wrangle.xcodeproj/project.pbxproj,
    WrangleTests/WrangleTests.swift (delete if Xcode created a placeholder)
  </files>
  <read_first>
    - Wrangle.xcodeproj/project.pbxproj (current state post-Task-1 — locate
      the new `WrangleTests` PBXNativeTarget block, its `PBXSourcesBuildPhase`,
      and the file references for the 7 real test files)
    - WrangleTests/WhatsNewManagerTests.swift (confirm `@testable import Wrangle` works)
    - WrangleTests/LicenseResidueCleanupTests.swift
    - WrangleTests/EditorDocumentTests.swift
    - WrangleTests/FileTypeTests.swift
    - WrangleTests/LinkRouterTests.swift
    - WrangleTests/MarkdownParserTests.swift
    - WrangleTests/TokenCounterTests.swift
  </read_first>
  <action>
    1. **Confirm file references.** Search `project.pbxproj` for each test
       file by basename. If Xcode added them all to the target during
       Task 1 (likely — Xcode's "Add to target" defaults work in our favor
       when the files already exist in `WrangleTests/`), skip to step 3.
       Otherwise:

    2. **Add missing files to target membership.** The safest path is to
       open Xcode again, select each missing test file in the Project
       Navigator, and in the File Inspector (right panel) check the
       `WrangleTests` checkbox under "Target Membership". Alternatively,
       hand-edit `project.pbxproj`:
       - Add a `PBXFileReference` entry for each missing file (mirror the
         shape Xcode used for the placeholder).
       - Add a matching `PBXBuildFile` entry referencing that file ref.
       - Add the `PBXBuildFile` UUID to the `WrangleTests` target's
         `PBXSourcesBuildPhase` `files` array.
       Pbxproj UUIDs are 24-char uppercase hex — generate with
       `uuidgen | tr -d '-' | head -c 24 | tr '[:lower:]' '[:upper:]'`.

    3. **Delete the placeholder.** If Xcode generated
       `WrangleTests/WrangleTests.swift` during Task 1, `git rm` it. Also
       remove its `PBXFileReference` + `PBXBuildFile` + `PBXSourcesBuildPhase`
       entries from `project.pbxproj`.

    4. **Validate file membership.** Run:
       ```
       xcodebuild -project Wrangle.xcodeproj -scheme Wrangle -destination 'platform=macOS,arch=arm64' build-for-testing 2>&1 | tail -20
       ```
       This builds the test bundle without running tests. Expected:
       `** BUILD SUCCEEDED **`. If any test file fails to compile, the
       failure points to either (a) a missing `@testable import Wrangle`
       (fix it), (b) an outdated API reference in a pre-existing test
       (triage — see Task 3), or (c) a `private`/`internal` access
       mismatch (most likely fix: change the source to `internal` if the
       test legitimately needs it).
  </action>
  <verify>
    <automated>xcodebuild -project Wrangle.xcodeproj -scheme Wrangle -destination 'platform=macOS,arch=arm64' build-for-testing 2>&1 | grep -E 'BUILD SUCCEEDED|BUILD FAILED' | head -1</automated>
  </verify>
  <acceptance_criteria>
    - `xcodebuild build-for-testing` exits 0 with `BUILD SUCCEEDED`
    - `grep -c WhatsNewManagerTests.swift Wrangle.xcodeproj/project.pbxproj` returns >= 2 (PBXFileReference + PBXBuildFile)
    - `grep -c LicenseResidueCleanupTests.swift Wrangle.xcodeproj/project.pbxproj` returns >= 2
    - `grep -c EditorDocumentTests.swift Wrangle.xcodeproj/project.pbxproj` returns >= 2
    - `grep -c FileTypeTests.swift Wrangle.xcodeproj/project.pbxproj` returns >= 2
    - `grep -c LinkRouterTests.swift Wrangle.xcodeproj/project.pbxproj` returns >= 2
    - `grep -c MarkdownParserTests.swift Wrangle.xcodeproj/project.pbxproj` returns >= 2
    - `grep -c TokenCounterTests.swift Wrangle.xcodeproj/project.pbxproj` returns >= 2
    - `test ! -f WrangleTests/WrangleTests.swift` exits 0 (placeholder removed if it existed)
  </acceptance_criteria>
  <done>
    All 7 real test files are members of the `WrangleTests` target. Test
    bundle compiles. No placeholder file remains in `WrangleTests/`.
  </done>
</task>

<task type="auto" tdd="false">
  <name>Task 3: Run the suite + triage pre-existing failures + commit</name>
  <files>
    (no source edits unless trivial fixes are needed for pre-existing tests)
  </files>
  <read_first>
    - .planning/phases/13-app-de-commercialization/13-02-SUMMARY.md (the
      `UserDefaults` pollution caveat for WhatsNewManagerTests — if those
      tests fail intermittently, the plan's escape hatch is to inject a
      `UserDefaults` parameter into `WhatsNewManager.init`)
  </read_first>
  <action>
    1. **Run the full test suite:**
       ```
       xcodebuild test -project Wrangle.xcodeproj -scheme Wrangle -destination 'platform=macOS,arch=arm64' 2>&1 | tee /tmp/wrangle-test-13-03.log | grep -E '^Test Suite|^Test Case|^Test [Ss]uite.*passed|^Test [Ss]uite.*failed|error:' | head -100
       ```

    2. **Classify each test file's outcome** in SUMMARY:
       - **GREEN**: passes — expected for the 4 WhatsNewManager + 4
         LicenseResidueCleanup tests (Plan 13-02 ships them with passing
         reasoning).
       - **RED-fix-in-scope**: a trivial assertion fix (one or two lines)
         to bring it green. Apply it; capture the diff in SUMMARY. Only
         in-scope when the fix is a clear adjustment to match current
         behavior (e.g., a renamed enum case, a moved file path constant).
       - **RED-defer**: a non-trivial failure (logic change required, or
         the test is testing removed behavior). Document in SUMMARY with
         the failure message and a follow-up TODO. Mark the test as
         `.disabled` via Swift Testing's `@Test(.disabled("..."))` so the
         suite remains green overall.

    3. **Handle WhatsNewManager UserDefaults fragility** (if it surfaces):
       If `WhatsNewManagerTests` fail intermittently due to test-order
       pollution on `UserDefaults.standard`, refactor
       `wrangle/App/WhatsNewManager.swift`:
       - Add `private let defaults: UserDefaults`
       - Add `init(defaults: UserDefaults = .standard) { self.defaults = defaults }`
       - Replace all `UserDefaults.standard.xxx(forKey: Self.lastSeenVersionKey)`
         with `defaults.xxx(forKey: Self.lastSeenVersionKey)`
       - Update tests to pass `WhatsNewManager(defaults: UserDefaults(suiteName: "WhatsNewManagerTests-\(UUID().uuidString)")!)`
       - LicenseResidueCleanup may need a similar refactor — its tests have
         the same `UserDefaults.standard` constraint. Skip the refactor if
         the existing key-snapshot pattern (per-test `defer` reset)
         already produces green runs.

    4. **Commit + SUMMARY.** Single commit covering Task 1's pbxproj
       changes + scheme + Task 2's file membership + Task 3's triage and
       any source fixes. Suggested commit message:
       ```
       chore(13-03): wire up WrangleTests target — 7 test files, 8 Phase-13 tests green
       ```

       Write `.planning/phases/13-app-de-commercialization/13-03-SUMMARY.md`
       documenting:
       - The 7 test files and their status (GREEN / RED-fix-in-scope / RED-defer)
       - Total test-case count and pass/fail breakdown
       - Any source files modified during triage (e.g., `WhatsNewManager`
         dependency injection if needed)
       - Outstanding follow-ups for any RED-defer tests
       - Final declaration: Phase 13 test infrastructure operational.
  </action>
  <verify>
    <automated>xcodebuild test -project Wrangle.xcodeproj -scheme Wrangle -destination 'platform=macOS,arch=arm64' 2>&1 | grep -E '^Test Suite .* (passed|failed)' | tail -1</automated>
  </verify>
  <acceptance_criteria>
    - `xcodebuild test ...` exits 0
    - SUMMARY shows the per-file outcome breakdown (GREEN / RED-fix / RED-defer)
    - The 4 `WhatsNewManagerTests` and 4 `LicenseResidueCleanupTests` cases are GREEN
    - Any RED-defer tests are explicitly `@Test(.disabled("..."))` so they don't break the overall run, with the reason captured in SUMMARY and a follow-up TODO logged
    - Single commit lands all three tasks' changes + the SUMMARY file
  </acceptance_criteria>
  <done>
    `xcodebuild test` runs the 7 test files. At least the 8 Phase-13 tests
    pass. Pre-existing tests are triaged (in-scope fixes applied, non-trivial
    failures disabled with documented follow-ups). Phase 13 test
    infrastructure is operational and ready for v1.3 shipping.
  </done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

This plan introduces no new trust boundaries. All changes are to project
configuration (`project.pbxproj`, `Wrangle.xcscheme`) and possibly one
minor source refactor (DI for `UserDefaults` in `WhatsNewManager` if test
fragility forces it). No new runtime code paths, no new network endpoints,
no new persisted data.

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-13-11 | Tampering | `Wrangle.xcodeproj/project.pbxproj` edits | accept | Pbxproj edits in this plan are additive (new target, new file refs, new scheme). Format is well-known; Xcode's GUI path produces canonical output. The executor only hand-edits pbxproj if Xcode's "Add to target" misses a file — in which case the edit follows the existing UUID/structure pattern verbatim. |
| T-13-12 | Information Disclosure | `WrangleTests/LicenseResidueCleanupTests.swift` | accept | The test runs `LicenseResidueCleanup.run()` against `UserDefaults.standard` + Keychain. Since Plan 13-02's helper is idempotent and the tests use a unique sentinel value pattern, no production secrets can leak into the test bundle. Test bundle is sandboxed to the developer's local Keychain access group; nothing crosses out. |
| T-13-13 | Denial of Service | Adding a test target | accept | Test target adds ~5s to a full `xcodebuild test` run. No CI impact today (no CI configured). When CI lands in v1.4 (per ROADMAP, GH Actions notarization deferred), test-target build time becomes a budgetable item. |

**No new authentication, no new authorization, no new data storage. All
changes are project-configuration / test-infrastructure additive.**
**Block-on:** high severity threats. None identified for this plan.
</threat_model>

<verification>
- Maps to user's `feedback_testing_priority` memory — Plan 13-02's 8 unit
  tests + 5 pre-existing unit tests can finally execute. Verified by
  `xcodebuild test` exit 0.
- Maps to ROADMAP §Phase 13 implicit quality gate (build clean + tests
  passing) — Phase 13 ships with a green test suite as well as a green
  build.
- Maps to v1.3 "Open Source Release" milestone goal — credible OSS
  projects ship with runnable test suites; an open-source release that
  ships seven untargeted test files would be embarrassing.
</verification>

<success_criteria>
- `WrangleTests` target exists in `Wrangle.xcodeproj`.
- `Wrangle.xcodeproj/xcshareddata/xcschemes/Wrangle.xcscheme` is committed
  with the Test action wired to `WrangleTests`.
- All 7 test files in `WrangleTests/` are members of the target.
- `xcodebuild test -project Wrangle.xcodeproj -scheme Wrangle -destination 'platform=macOS,arch=arm64'` exits 0.
- The 8 tests authored in Plan 13-02 (4 WhatsNewManager + 4 LicenseResidueCleanup)
  pass.
- Any pre-existing tests that fail are either trivially fixed in-scope or
  explicitly `@Test(.disabled("..."))` with a documented follow-up TODO.
</success_criteria>

<output>
Create `.planning/phases/13-app-de-commercialization/13-03-SUMMARY.md` documenting:
- Xcode GUI steps confirmed by the user (Task 1 manual checkpoint)
- Final pbxproj diff summary (target added, file refs added, placeholder removed)
- Shared scheme committed
- Per-test-file outcome: 7 files × {GREEN | RED-fix-in-scope | RED-defer}
- Test-case count: 8+ Phase-13 tests passing; total suite count
- Any source-file refactors performed (e.g., `WhatsNewManager` DI for
  UserDefaults isolation)
- Outstanding follow-ups for any RED-defer tests, with file:line refs
- Phase 13 completion declaration: test infrastructure operational; ready
  for `/gsd:verify-phase 13` and `/gsd:ship`.
</output>
