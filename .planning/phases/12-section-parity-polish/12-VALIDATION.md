---
phase: 12
slug: section-parity-polish
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-20
---

# Phase 12 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Phase 12 is a refactor + UX-polish pass over existing shipped surfaces —
> no new models, no migrations, no data mutations. Verification is dominated
> by build-green + manual UAT on macOS since the project has no wired-in
> test target today (see RESEARCH.md §Test Infrastructure Gap).

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Swift Testing (`import Testing`) — orphaned (test files exist in `WrangleTests/` but no test target in `Wrangle.xcodeproj`) |
| **Config file** | none — test target not present in `project.pbxproj` |
| **Quick run command** | `xcodebuild -project Wrangle.xcodeproj -scheme Wrangle -destination 'platform=macOS' build` |
| **Full suite command** | same as quick (no test target to run; manual UAT covers the behavioral path) |
| **Estimated runtime** | ~45s (clean build ~2min) |

**Pre-existing gap, NOT in scope for Phase 12:** The absence of a wired-in test target is a longstanding project condition that every prior phase (1–11) accepted. Adding the test target to the Xcode project belongs to a dedicated infrastructure phase. Phase 12 follows the established convention: build-green + manual UAT per success-criteria checklist.

---

## Sampling Rate

- **After every task commit:** Run `xcodebuild ... build` (quick command above)
- **After every plan wave:** Same build; plus targeted grep verification of acceptance criteria
- **Before `/gsd-verify-work`:** Build green + full UAT walkthrough of UIX-20 through UIX-23 (see Manual-Only Verifications below)
- **Max feedback latency:** 45s (build) / 3–5 min (manual UAT pass)

---

## Per-Task Verification Map

Task IDs below are provisional — actual IDs assigned by gsd-planner. Structure mirrors the four requirement groups.

| Task ID | Plan | Wave | Requirement | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------------|-----------|-------------------|-------------|--------|
| 12-01-W0 | 01 | 0 | — | `List(selection:)` across heterogeneous Sections validated on macOS 15+ | spike | `xcodebuild ... build` + manual click-test | ❌ W0 | ⬜ pending |
| 12-01-01 | 01 | 1 | UIX-20 | SidebarSectionHeader gains optional `count:` param; count renders on collapse only | grep + build | `grep -nE 'count:\s*Int\?' wrangle/Components/SidebarSectionHeader.swift` | ✅ | ⬜ pending |
| 12-01-02 | 01 | 1 | UIX-20 | CollapsibleVStackSection gains optional `count:` param; same render rule | grep + build | `grep -nE 'count:\s*Int\?' wrangle/Components/CollapsibleSection.swift` | ✅ | ⬜ pending |
| 12-01-03 | 01 | 2 | UIX-20 | All 5 sidebar call sites pass their count (visiblePads, browsers, projectLocations, orphaned, visibleBookmarks) | grep + build | `grep -nE 'SidebarSectionHeader\(' wrangle/**/*.swift` | ✅ | ⬜ pending |
| 12-01-04 | 01 | 2 | UIX-20 | All 5 overview call sites pass their count (terminalSessions, browserTabs, projectBrowserBookmarks, documentTabs, projectBookmarks) | grep + build | `grep -nE 'CollapsibleVStackSection\(' wrangle/Features/Dashboard/ProjectOverviewView.swift` | ✅ | ⬜ pending |
| 12-01-05 | 01 | 2 | UIX-20 | NestedBookmarkSubSection bespoke header deleted; uses shared `SidebarSectionHeader` | grep + build | `! grep -q 'Image(systemName: "chevron.right").*"Bookmarks"' wrangle/Browser/Bookmarks/NestedBookmarkSubSection.swift` | ✅ | ⬜ pending |
| 12-02-01 | 01 | 2 | UIX-21 | SidebarSelection enum with .scratchPad(URL) / .bookmark(String) cases | grep + build | `grep -nE 'enum SidebarSelection' wrangle/Sidebar/*.swift` | ✅ | ⬜ pending |
| 12-02-02 | 01 | 3 | UIX-21 | ScratchPadRow gains `.tag(.scratchPad(pad.url))`; onSubmit triggers rename; .onDeleteCommand on List handles delete with alert | grep + build | `grep -nE '\.tag\(\.scratchPad' wrangle/Sidebar/ScratchPadSection.swift` | ✅ | ⬜ pending |
| 12-02-03 | 01 | 3 | UIX-21 | BookmarkRow gains `.tag(.bookmark(bookmark.id))`; Return opens BookmarkEditSheet; .onDeleteCommand handles delete with alert | grep + build | `grep -nE '\.tag\(\.bookmark' wrangle/Browser/Bookmarks/NestedBookmarkSubSection.swift` | ✅ | ⬜ pending |
| 12-02-04 | 01 | 3 | UIX-21 | Hover-based `DeleteKeyHandler` struct deleted | grep | `! grep -q 'struct DeleteKeyHandler' wrangle/**/*.swift` | ✅ | ⬜ pending |
| 12-02-05 | 01 | 3 | UIX-21 | Scratch Pad delete alert has specific title using pad name; "Move to Trash" destructive button | grep | `grep -nE 'Move .* to Trash' wrangle/Sidebar/ScratchPadSection.swift` | ✅ | ⬜ pending |
| 12-02-06 | 01 | 3 | UIX-21 | Bookmark delete alert has specific title using display name; "Delete" destructive button | grep | `grep -nE 'Delete bookmark' wrangle/Browser/Bookmarks/NestedBookmarkSubSection.swift` | ✅ | ⬜ pending |
| 12-02-07 | 01 | 3 | UIX-21 | `ScratchPadManager.deleteScratchPad` hard-delete fallback removed or replaced with log-only (per RESEARCH.md Pitfall 2) | grep | `! grep -nE 'try\? FileManager\.default\.removeItem' wrangle/**/ScratchPadManager.swift` | ✅ | ⬜ pending |
| 12-03-01 | 01 | 1 | UIX-22 | SidebarStorageKeys.swift created with 5 static lets | grep + build | `grep -nE 'static let (locations\|scratchPads\|browsers\|otherSessions\|browserBookmarks)Expanded' wrangle/Components/SidebarStorageKeys.swift` | ✅ | ⬜ pending |
| 12-03-02 | 01 | 1 | UIX-22 | OverviewStorageKeys.swift created with 6 static funcs taking projectID | grep + build | `grep -cE 'static func .*Expanded\(_\s+projectID:' wrangle/Components/OverviewStorageKeys.swift` (expected: 6) | ✅ | ⬜ pending |
| 12-03-03 | 01 | 2 | UIX-22 | All 11 @AppStorage call sites rewire to constants (no string literals remain for these keys) | grep | `! grep -rE '@AppStorage\("(sidebar\|overview)\.' wrangle/` (expected: 0 matches after refactor) | ✅ | ⬜ pending |
| 12-03-04 | 01 | 2 | UIX-22 | `CollapsibleVStackSection(storageKey:)` calls pass `OverviewStorageKeys.xxxExpanded(projectID)` | grep | `grep -nE 'storageKey:\s*OverviewStorageKeys\.' wrangle/Features/Dashboard/ProjectOverviewView.swift` (expected: 6) | ✅ | ⬜ pending |
| 12-04-01 | 01 | 3 | UIX-23 | CLAUDE.md updated with sidebar/overview section convention and hide-when-empty invariant | grep | `grep -nE 'hide when empty\|sidebar\.<section>\.expanded' CLAUDE.md` | ✅ | ⬜ pending |
| 12-04-02 | 01 | 3 | UIX-23 | No regressions: grep sweep confirms no section renders header + inline empty-state row | grep | `! grep -rE 'Text\("No .* yet\|Nothing .*yet\|Empty .*"\)' wrangle/Sidebar/ wrangle/Features/Dashboard/ProjectOverviewView.swift wrangle/Browser/Bookmarks/NestedBookmarkSubSection.swift` (false positives: ProjectListSection's "No projects yet" rail OK; ProjectOverviewView.emptyHero "Nothing here yet" OK — both pre-existing/approved) | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] **Spike: `List(selection:)` across heterogeneous Sections on macOS 15+** — 15-min empirical validation before wiring keyboard handlers. Create a minimal prototype with a `SidebarSelection` enum (`.scratchPad(URL)` / `.bookmark(String)`), two Sections each with their row type, and verify:
  - Clicking a Scratch Pad row clears any previous Bookmark selection (and vice-versa).
  - Selection survives view refreshes (SwiftData `@Query` re-fire).
  - No visual glitches (double-selected rows, flicker) when switching between Sections.
  - `.onDeleteCommand` fires on `⌫` with the correct selection value.
  - **Go signal:** single-selection works cleanly across both Sections.
  - **No-go signal:** falls back to per-section `@State` selection as documented in CONTEXT D-06.

*No other Wave 0 tasks — the phase has zero net-new models or schemas.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Sidebar header count appears only when section is collapsed | UIX-20 | Visual behavior; no headless API to assert chevron state + child visibility | 1. Open Wrangle, select a project with ≥2 browser tabs + ≥3 bookmarks. 2. Click Browsers chevron to collapse → header shows "Browsers (2)". 3. Expand → shows "Browsers" only. 4. Repeat for Scratch Pads, Locations, Other Sessions, nested Bookmarks. |
| Overview card count appears only on collapse | UIX-20 | Same as above, applied to `CollapsibleVStackSection` | 1. Open Project Overview. 2. Collapse Terminal Sessions / Open Files / Browsers / Locations. 3. Each header shows "(N)". 4. Expand each → count disappears. |
| Return on selected Scratch Pad enters inline rename; Esc cancels | UIX-21 | Keyboard + focus + SwiftUI TextField interaction — requires macOS 15 runtime | 1. Click a Scratch Pad row (selects). 2. Press Return → TextField appears with current name selected. 3. Type new name → press Return → rename commits; selection clears. 4. Repeat; press Esc mid-edit → rename cancels. |
| Return on selected Bookmark opens BookmarkEditSheet | UIX-21 | Same as above | 1. Click a bookmark row. 2. Press Return → edit sheet appears. 3. Close sheet → selection still on that row. |
| Delete on selected Scratch Pad prompts move-to-Trash alert | UIX-21 | Alert is a modal SwiftUI surface; dialog text verification requires visual inspection | 1. Select a Scratch Pad. 2. Press ⌫ → alert appears with title "Move '\<name\>' to Trash?". 3. Confirm → file moves to Finder Trash (open Finder Trash to verify). 4. Repeat; cancel → file stays. |
| Delete on selected Bookmark prompts delete-bookmark alert | UIX-21 | Same | 1. Select a bookmark. 2. Press ⌫ → alert with title "Delete bookmark '\<displayName\>'?". 3. Confirm → row disappears from sidebar. |
| Context-menu Delete on either row fires immediately (no confirmation) | UIX-21 | Modal behavior diff; per CONTEXT D-09 | 1. Right-click Scratch Pad → "Delete" → no alert; file trashed. 2. Right-click Bookmark → "Delete" → no alert; row gone. |
| Expansion state persists across app relaunch | UIX-22 | UserDefaults round-trip across process restart | 1. Collapse any section. 2. Quit Wrangle (⌘Q). 3. Relaunch → same section still collapsed. 4. Verify via `defaults read <bundleID> | grep sidebar.` — key still present with `false`. |
| No regression on Phase 10/11 hide-when-empty | UIX-23 | Visual assertion that empty sections stay hidden even after header refactor | 1. Create a fresh project with no content. 2. Verify sidebar shows only Overview row + bottom bar. 3. Verify Project Overview shows only Todos + centered empty-hero. 4. Create a browser tab → Browsers section appears. Delete it → Browsers disappears. |
| Chevron animation preserved (not instant) | UIX-20 / D-05 | Animation is perceptual; confirmed by eye | 1. Click any section chevron → smooth ~0.15s rotation (not hard snap). |

*Four of nine UAT checks map to existing manual success-criteria in ROADMAP §Phase 12.*

---

## Validation Sign-Off

- [ ] Wave 0 spike complete — `List(selection:)` validated OR documented fallback applied
- [ ] Build green after every task commit (`xcodebuild ... build`)
- [ ] All per-task grep acceptance criteria pass
- [ ] Manual UAT walkthrough (9 items above) complete pre-merge
- [ ] `nyquist_compliant: true` set in frontmatter upon completion

**Approval:** pending
