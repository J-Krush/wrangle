---
phase: 13-app-de-commercialization
plan: 03
subsystem: testing
tags: [xcode-test-target, swift-testing, wrangletests, pbxfilesystemsynchronizedrootgroup, v1.3]
requires: [13-02-oss-note-residue-cleanup-and-update-repoint]
provides:
  - WrangleTests Swift Testing target wired into Wrangle.xcodeproj
  - Shared scheme Wrangle.xcscheme committed (TestAction wired to WrangleTests)
  - Test infrastructure operational — `xcodebuild test` exits 0
  - 106 test cases across 7 test files, all GREEN (no RED-defer remaining)
affects:
  - Wrangle.xcodeproj/project.pbxproj
  - Wrangle.xcodeproj/xcshareddata/xcschemes/Wrangle.xcscheme
  - WrangleTests/TokenCounterTests.swift (added SwiftUI import)
  - WrangleTests/EditorDocumentTests.swift (off-by-one assertion fix)
  - WrangleTests/WrangleTests.swift (Xcode-generated placeholder, deleted)
tech-stack:
  added:
    - "Xcode 26's PBXFileSystemSynchronizedRootGroup — folder-driven target membership (no per-file PBXFileReference/PBXBuildFile entries). Files in WrangleTests/ are auto-included by directory rather than enumerated in pbxproj."
  patterns:
    - "Swift Testing only (NOT XCTest). All 7 test files use `@Suite` / `@Test` / `#expect`."
    - "Shared scheme committed under xcshareddata/xcschemes/ so CI and other contributors get the Test action reproducibly."
key-files:
  created:
    - Wrangle.xcodeproj/xcshareddata/xcschemes/Wrangle.xcscheme
  modified:
    - Wrangle.xcodeproj/project.pbxproj
    - WrangleTests/TokenCounterTests.swift
    - WrangleTests/EditorDocumentTests.swift
  deleted:
    - WrangleTests/WrangleTests.swift  # Xcode-generated placeholder
key-decisions:
  - "Bundle identifier is `com.krush.WrangleTests`, not the plan-specified `Wrangle.WrangleTests`. The plan's Wave 2 inspection note (`app bundle is Wrangle`) was wrong — the real app bundle id is `com.krush.wrangle` (from PRODUCT_BUNDLE_IDENTIFIER in pbxproj), so Xcode's auto-computed `com.krush.WrangleTests` correctly matches the app namespace. No functional impact; documenting as a plan deviation."
  - "Plan Task 2's acceptance criteria (`grep -c <TestFile>.swift Wrangle.xcodeproj/project.pbxproj >= 2`) are obsolete under PBXFileSystemSynchronizedRootGroup (Xcode 26). File membership is implicit-by-folder via `fileSystemSynchronizedGroups = (WrangleTests)` on the target. Functional equivalent verified two ways: (a) the Xcode test plan GUI showed 64 tests detected before the trivial fixes, (b) `xcodebuild build-for-testing` succeeded after one trivial import fix."
  - "Triage outcome: both pre-existing failures were trivial in-scope fixes, NOT RED-defer. No `@Test(.disabled(...))` markers were needed — the suite is fully GREEN, no follow-up TODOs deferred."
requirements-completed: []
metrics:
  duration: ~15 min
  completed: 2026-05-20T18:55:00Z
---

# Phase 13 / Plan 03: WrangleTests Target Wireup

**Wired up the `WrangleTests` Swift Testing target — `xcodebuild test` now runs 106 test cases across 7 files, all green, closing a pre-existing test-execution gap that predated Phase 13.**

## Performance

- **Duration:** ~15 min (including manual Xcode GUI checkpoint)
- **Completed:** 2026-05-20T18:55:00Z
- **Tasks:** 3
- **Files modified:** 4 (1 pbxproj, 2 test source files trivially patched, 1 placeholder deleted) + 1 new shared scheme

## Accomplishments

### Task 1 — Manual Xcode GUI checkpoint (user-driven)

User performed the GUI steps:
1. File → New → Target → macOS Unit Testing Bundle with **Swift Testing** (not XCTest), Target to be Tested = Wrangle, Bundle Identifier = `com.krush.WrangleTests`.
2. Product → Scheme → Manage Schemes → checked **Shared** on `Wrangle` (created `Wrangle.xcodeproj/xcshareddata/xcschemes/Wrangle.xcscheme`).
3. Edit Scheme → Test → confirmed auto-created Test Plan `Wrangle (Autocreated)` contains `WrangleTests` (64 tests detected pre-fix).
4. Quit Xcode.

Validation (post-Xcode-quit):
- `xcodebuild -project Wrangle.xcodeproj -list` shows both `Wrangle` and `WrangleTests`.
- `test -f Wrangle.xcodeproj/xcshareddata/xcschemes/Wrangle.xcscheme` → exit 0.
- `git status` showed the expected: `project.pbxproj` modified, `xcshareddata/` untracked, `WrangleTests/WrangleTests.swift` placeholder added.

### Task 2 — Target membership

**Plan deviation: PBXFileSystemSynchronizedRootGroup.** Xcode 26 uses the new folder-synced group model — `fileSystemSynchronizedGroups = (WrangleTests)` on the `WrangleTests` target auto-includes every `.swift` file under `WrangleTests/`. There are no per-file `PBXFileReference` / `PBXBuildFile` entries to grep for, which makes the plan's `grep -c >= 2` acceptance checks structurally inapplicable. The functional equivalent (`xcodebuild build-for-testing` succeeds) is the contract that matters.

Actions:
- Deleted the Xcode-generated placeholder `WrangleTests/WrangleTests.swift`.
- `xcodebuild build-for-testing` initially failed: `TokenCounterTests.swift` referenced `.green` (a SwiftUI `Color`) without importing SwiftUI. Added `import SwiftUI` — trivial RED-fix-in-scope, single line.
- Re-ran `build-for-testing` → `** TEST BUILD SUCCEEDED **`.

### Task 3 — Run suite, triage, commit

First run: **1 failure** — `EditorDocumentTests/cachedStats()`. Diagnosis: the assertion `#expect(doc.cachedCharCount == 33)` was a stale literal — `"Hello world\nSecond line\nThird line"` is 34 chars (11 + 1 + 11 + 1 + 10). Pure off-by-one in the test, not a regression in `EditorDocument.updateCachedStats`. Fixed `33` → `34`.

Second run: **`** TEST SUCCEEDED **`** — all 106 cases green.

## Per-test-file outcomes

| File | Cases | Status | Notes |
|------|-------|--------|-------|
| `EditorDocumentTests.swift` | 14 | GREEN | 1 RED-fix-in-scope: off-by-one in `cachedStats()` literal (`33` → `34`). |
| `FileTypeTests.swift` | 37 | GREEN | All parameterised cases pass unchanged. |
| `LicenseResidueCleanupTests.swift` | 4 | GREEN | All 4 Phase-13-02 tests pass (`gateOpenOnFreshInstall`, `gateRespectedWhenAtCurrentVersion`, `clearsInstanceID`, `idempotentRuns`). |
| `LinkRouterTests.swift` | 10 | GREEN | All pass unchanged. |
| `MarkdownParserTests.swift` | 20 | GREEN | All pass unchanged. |
| `TokenCounterTests.swift` | 17 | GREEN | 1 RED-fix-in-scope: missing `import SwiftUI` for `.green` Color reference. |
| `WhatsNewManagerTests.swift` | 4 | GREEN | All 4 Phase-13-02 tests pass (`freshInstallFiltersOlderEntries`, etc.). UserDefaults pollution caveat from 13-02 SUMMARY did NOT surface — the existing key-snapshot pattern produced clean runs without needing the `defaults` DI refactor. |

**Total: 106 cases, 0 failures, 0 RED-defer.** Both pre-existing failures were one-line trivial fixes, so no `@Test(.disabled(...))` markers were applied and no follow-up TODOs deferred.

## Outstanding follow-ups

None for the test infrastructure itself. Phase 13 is functionally complete:

- ✓ `WrangleTests` target exists in `Wrangle.xcodeproj`.
- ✓ Shared scheme committed.
- ✓ `xcodebuild test -project Wrangle.xcodeproj -scheme Wrangle -destination 'platform=macOS,arch=arm64'` exits 0.
- ✓ All 8 Phase-13-02 tests (4 WhatsNewManager + 4 LicenseResidueCleanup) GREEN.
- ✓ All 5 pre-existing test files GREEN after 2 trivial in-scope fixes.

Phase 13 test infrastructure operational and ready for `/gsd:verify-phase 13` and `/gsd:ship`.
