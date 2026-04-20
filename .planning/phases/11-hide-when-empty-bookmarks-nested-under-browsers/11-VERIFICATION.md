---
phase: 11-hide-when-empty-bookmarks-nested-under-browsers
verified: 2026-04-19T12:00:00Z
status: human_needed
score: 5/5 must-haves verified (automated)
overrides_applied: 0
human_verification:
  - test: "Fresh project shows Overview row + bottom-bar only in sidebar"
    expected: "Select a project with zero scratch pads, zero browser tabs, zero bookmarks, zero locations. Sidebar renders: Overview row, OrphanedSessionsSection (self-hides when empty), and the + bottom bar. No Scratch Pads, Browsers, Bookmarks, or Locations section headers visible."
    why_human: "SC#1 — visual sidebar rendering. Code shows all four sections are gated by `if !xs.isEmpty`, but the final rendered absence requires observing the running app."
  - test: "Fresh project Overview shows centered empty-hero below Todos"
    expected: "Open the project overview tab on a fresh project. Top of VStack shows: project header, Todos section (always), then a centered VStack with 48pt `square.grid.2x2` glyph, 'Nothing here yet' headline, and subheadline 'Press + to add your first Scratch Pad, Browser, Bookmark, or Location.' No Sessions/Browsers/Documents/Locations cards. No + button inside the hero."
    why_human: "SC#2 — visual appearance of the hero and its positioning below Todos. Code has verbatim copy, correct glyph, no Button inside hero. Visual centering/spacing require rendered confirmation."
  - test: "First browser tab surfaces Browsers section; first bookmark surfaces nested Bookmarks (n)"
    expected: "Open a browser tab — Browsers section header + tab row appear in sidebar. Star a page — a `Bookmarks (1)` nested sub-header appears UNDER the browser row (same Browsers section), with chevron-right glyph. Never appears as top-level section. Toggling that chevron collapses/expands bookmark rows independently from the outer Browsers chevron."
    why_human: "SC#3 — real-time @Query reactivity + correct visual hierarchy. Code shows NestedBookmarkSubSection rendered inside BrowserSessionsSection body after ForEach(browsers). Runtime observation required to confirm the nested chevron positioning and independent toggling."
  - test: "Delete-last-item removes section instantly with no animated transition"
    expected: "With exactly one browser bookmark in a nested Bookmarks sub-section, delete it via context menu. Sub-section disappears instantly on the next render tick — no slide, no fade, no height-collapse animation. If 0 tabs + the only bookmark was deleted, the whole Browsers section vanishes in the same tick. Repeat for: last scratch pad, last location, last browser tab (all sections should vanish instantly, no animation)."
    why_human: "SC#4 — animation absence is a behavioral property that requires visual observation. Code scan confirms zero `withAnimation` calls wrap section show/hide in SidebarView.swift and ProjectOverviewView.swift; `@Query` reactivity is automatic."
  - test: "Overview Bookmarks is nested inside Browsers card and collapses independently"
    expected: "With ≥1 browser tab AND ≥1 bookmark: Project Overview shows a single 'Browsers' CollapsibleVStackSection card containing a LazyVGrid of tab cards, then a nested 'Bookmarks' CollapsibleVStackSection card (with its own chevron) containing the bookmark cards grid. Collapsing the outer Browsers chevron hides both tabs and nested Bookmarks together. Collapsing the inner Bookmarks chevron hides only bookmarks; tab grid stays visible. Collapse state for each persists across app relaunch (different @AppStorage keys)."
    why_human: "SC#5 — visual nesting hierarchy (one card, two chevrons) and independent collapse behavior. Code confirms nested CollapsibleVStackSection with distinct storageKey values. Runtime required to confirm visual grouping and independent expansion."
---

# Phase 11: Hide-When-Empty + Bookmarks Nested Under Browsers — Verification Report

**Phase Goal:** Sidebar and overview show only non-empty sections. Browser bookmarks live inside Browsers, not as a top-level peer. Discovery moves to the `+` menu.

**Verified:** 2026-04-19
**Status:** human_needed (all automated checks pass; behavioral smoke-test is deferred per project cadence)
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths (ROADMAP Success Criteria)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Fresh project shows no Scratch Pads / Browsers / Bookmarks / Locations sections in sidebar — just Overview row + `+` bottom bar | ✓ VERIFIED | `SidebarView.swift:57` Scratch Pads guard `if !appState.scratchPadManager.scratchPads(forProject: projectID).isEmpty`; `:72` `if !projectLocations.isEmpty`; `:549` `if !browsers.isEmpty \|\| !visibleBookmarks.isEmpty`; top-level `BookmarkSidebarSection()` call removed (0 matches); `NestedBookmarkSubSection` self-hides via `if !visibleBookmarks.isEmpty` at `NestedBookmarkSubSection.swift:37`. All four sections have proper hide-when-empty guards. |
| 2 | Fresh project Overview shows single centered empty-state with "Press + to add your first…" subheadline; no empty section cards | ✓ VERIFIED | `ProjectOverviewView.swift:78-84` defines `isProjectContentEmpty` (terminals && browserTabs && documentTabs && projectBrowserBookmarks && projectBookmarks — all `.isEmpty`); `:92-94` renders `emptyHero` under that guard; `:361-377` emptyHero is a passive VStack with `square.grid.2x2` glyph (48pt), "Nothing here yet" headline, verbatim D-14 subheadline; body-level guards on `sessionsSection`, `browsersSection`, `documentsSection`, `locationsSection` all present. |
| 3 | First Browser tab surfaces Browsers section; first bookmark surfaces nested `Bookmarks (n)` inside Browsers — not as top-level | ✓ VERIFIED | `SidebarView.swift:54` calls `BrowserSessionsSection()` (no other BookmarkSidebarSection call remains); `:534-564` BrowserSessionsSection body has outer guard `!browsers.isEmpty \|\| !visibleBookmarks.isEmpty` (D-07), renders browser rows then `NestedBookmarkSubSection()` inside its Section body. `NestedBookmarkSubSection.swift:37-68` — inline sub-header shows "Bookmarks" always; when `!isExpanded`, appends `Text("\(visibleBookmarks.count)")` at 10pt tertiary (D-04 count-only-when-collapsed). |
| 4 | Deleting last item in any section removes the section from sidebar AND overview on next render tick (no animation) | ✓ VERIFIED | No `withAnimation` anywhere in `SidebarView.swift` (0 matches); no `withAnimation` anywhere in `ProjectOverviewView.swift` (0 matches). `@Query` reactivity is automatic — SwiftData emits updates on `modelContext.save()` and the `if !isEmpty` guards re-evaluate on next tick. Chevron-toggle `withAnimation` in `NestedBookmarkSubSection.swift:40` and inside `BookmarkFolderNode:156` is bound to Button taps, not to section appearance. Honors D-22 + user memory `feedback_no_slide_transitions`. |
| 5 | Overview Bookmarks card nested inside Browsers (shared chrome) and collapses/expands independently | ✓ VERIFIED | `ProjectOverviewView.swift:381-474` — single outer `CollapsibleVStackSection("Browsers", storageKey: "overview.browsers.expanded.\(projectID)")` contains (a) the tab `LazyVGrid` guarded by `if !browserTabs.isEmpty`, then (b) a nested `CollapsibleVStackSection("Bookmarks", storageKey: "overview.browsers.bookmarks.expanded.\(projectID)")` guarded by `if !projectBrowserBookmarks.isEmpty`. Two independent `@AppStorage`-backed storage keys → independent collapse. Standalone `bookmarksSection`/`bookmarksContent` symbols removed (0 matches). |

**Score:** 5/5 truths verified by automated code inspection

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `Wrangle/Browser/Bookmarks/NestedBookmarkSubSection.swift` | Sub-section view owning `@Query<BrowserBookmark>` + `@Query<BrowserBookmarkFolder>`, inline chevron sub-header with count-only-when-collapsed, self-hides when `visibleBookmarks.isEmpty` | ✓ VERIFIED | File exists (350 lines). Contains `struct NestedBookmarkSubSection` exactly once. `@AppStorage("sidebar.browsers.bookmarks.expanded")` present (D-05). Uses correct filter `projectID == projectID \|\| projectID == nil`. Count-only-when-collapsed logic at `:50-54`. Four helper structs (`BookmarkFolderNode`, `BookmarkFolderDropDelegate`, `BookmarkRow`, `DeleteKeyHandler`) preserved verbatim. |
| `Wrangle/Browser/Bookmarks/BookmarkSidebarSection.swift` | Should NOT exist (deleted/renamed) | ✓ VERIFIED | File does not exist. `grep BookmarkSidebarSection Wrangle/` returns 0 matches. |
| `Wrangle/Sidebar/SidebarView.swift` | `projectLocations` computed prop added; Locations wrapped in `if !projectLocations.isEmpty`; top-level `BookmarkSidebarSection()` call removed; `BrowserSessionsSection` widened guard + nested `NestedBookmarkSubSection()` call | ✓ VERIFIED | `:31-34` `projectLocations` computed prop present. `:72` guard present. `:54` single `BrowserSessionsSection()` call (no BookmarkSidebarSection). `:549` `!browsers.isEmpty \|\| !visibleBookmarks.isEmpty` guard. `:557` `NestedBookmarkSubSection()` called inside `isExpanded` block after browser rows ForEach. |
| `Wrangle/Features/Dashboard/ProjectOverviewView.swift` | `isProjectContentEmpty` + `emptyHero` added; `browsersSection` absorbs nested Bookmarks `CollapsibleVStackSection`; standalone `bookmarksSection`/`bookmarksContent` deleted; `locationsSection` empty branch deleted | ✓ VERIFIED | `:78-84` `isProjectContentEmpty` present. `:361-377` `emptyHero` present with verbatim copy + glyph. `:381-474` browsersSection with two nested CollapsibleVStackSection calls. `:520-533` locationsSection is grid-only. `grep bookmarksSection` → 0, `grep bookmarksContent` → 0. |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|----|--------|---------|
| `SidebarView.BrowserSessionsSection` | `NestedBookmarkSubSection` | Body renders `NestedBookmarkSubSection()` after `ForEach(browsers) { LocationBrowserRow… }` inside `if isExpanded` | ✓ WIRED | `SidebarView.swift:552-557` — correct placement inside outer Section body, inside isExpanded guard. |
| `NestedBookmarkSubSection` | `@AppStorage sidebar.browsers.bookmarks.expanded` | `@AppStorage` property for nested chevron state | ✓ WIRED | `NestedBookmarkSubSection.swift:21` — exactly one declaration, default `true`. |
| `SidebarView.body` | `projectLocations.count` | `if !projectLocations.isEmpty` guard around Locations Section | ✓ WIRED | `SidebarView.swift:72` — guard wraps the entire Section at :73-93. |
| `BrowserSessionsSection` outer guard | bookmarks reachability | OR check `!browsers.isEmpty \|\| !visibleBookmarks.isEmpty` with parallel `@Query` | ✓ WIRED | `SidebarView.swift:534-549` — second `@Query<BrowserBookmark>` + `visibleBookmarks` filter added for outer-guard test. Documented intentional duplication per threat model T-11-03. |
| `ProjectOverviewView.body` | Empty hero (Pattern C) | Compound boolean `isProjectContentEmpty` (terminalSessions && browserTabs && documentTabs && projectBrowserBookmarks && projectBookmarks all .isEmpty) | ✓ WIRED | `:78-84` computes the boolean; `:92-94` gates `emptyHero`. Todos excluded per D-12. |
| `ProjectOverviewView.browsersSection` | Nested `CollapsibleVStackSection("Bookmarks", ...)` | Second `CollapsibleVStackSection` inside outer one's content closure with storageKey `overview.browsers.bookmarks.expanded.{projectID}` | ✓ WIRED | `:412-472` — nested section correctly inside outer, with own storage key, own collapse state, and migrated bookmark card grid. |
| `ProjectOverviewView.body` | `browsersSection` | Widened guard `!browserTabs.isEmpty \|\| !projectBrowserBookmarks.isEmpty` | ✓ WIRED | `:97` body-level guard matches D-20 exactly. |
| `ProjectOverviewView.body` | `locationsSection` | `if !projectBookmarks.isEmpty { locationsSection }` | ✓ WIRED | `:100` body-level guard present. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|---------------|--------|---------------------|--------|
| `NestedBookmarkSubSection` | `visibleBookmarks` / `visibleFolders` | SwiftData `@Query<BrowserBookmark>` + `@Query<BrowserBookmarkFolder>`, filtered by active project ID | ✓ Yes — real DB query via @Query | ✓ FLOWING |
| `BrowserSessionsSection` | `browsers` + `visibleBookmarks` | `appState.projectBrowserSessions` (computed from AppState) + `@Query<BrowserBookmark>` filtered by active project | ✓ Yes — real reactive data | ✓ FLOWING |
| `ProjectOverviewView.browsersSection` | `browserTabs` + `projectBrowserBookmarks` | `appState.tabs` filtered to `isBrowser` + `@Query<BrowserBookmark>` filtered to project | ✓ Yes — both flow from app state / SwiftData | ✓ FLOWING |
| `ProjectOverviewView.locationsSection` | `projectBookmarks` | `@Query(sort: \BookmarkedDirectory.displayOrder)` + project/isFile filter | ✓ Yes — real DB query | ✓ FLOWING |
| `ProjectOverviewView.emptyHero` | Static text (no dynamic data) | n/a — intentionally passive | n/a — passive view | ✓ FLOWING (by design) |

All render paths are connected to real data sources. No HOLLOW, STATIC, or DISCONNECTED artifacts.

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Project builds clean on macOS arm64 | `xcodebuild -scheme Wrangle -destination 'platform=macOS,arch=arm64' -configuration Debug build` | `** BUILD SUCCEEDED **` (final tail line) | ✓ PASS |
| BookmarkSidebarSection.swift deleted | `find Wrangle -name "BookmarkSidebarSection.swift"` | 0 matches | ✓ PASS |
| NestedBookmarkSubSection.swift present + correct struct | `grep -c "struct NestedBookmarkSubSection" NestedBookmarkSubSection.swift` | 1 | ✓ PASS |
| Top-level BookmarkSidebarSection() call removed from SidebarView | `grep -c "BookmarkSidebarSection" Wrangle/Sidebar/SidebarView.swift` | 0 | ✓ PASS |
| `sidebar.browsers.bookmarks.expanded` storage key present exactly once | `grep -c "sidebar.browsers.bookmarks.expanded" NestedBookmarkSubSection.swift` | 1 | ✓ PASS |
| Old `sidebar.bookmarks.expanded` key gone | `grep -r "sidebar.bookmarks.expanded" Wrangle/` | 0 matches | ✓ PASS |
| `projectLocations` computed prop + guard present | `grep -c "private var projectLocations\|if !projectLocations.isEmpty" SidebarView.swift` | 2 | ✓ PASS |
| Widened Browsers outer guard | `grep -c "!browsers.isEmpty \|\| !visibleBookmarks.isEmpty" SidebarView.swift` | 1 | ✓ PASS |
| `bookmarksSection` / `bookmarksContent` deleted from overview | `grep -cE "bookmarksSection\|bookmarksContent" ProjectOverviewView.swift` | 0 | ✓ PASS |
| `isProjectContentEmpty` definition + use | `grep -c "isProjectContentEmpty" ProjectOverviewView.swift` | 2 | ✓ PASS |
| `emptyHero` definition + trigger | `grep -c "private var emptyHero\|emptyHero$" ProjectOverviewView.swift` | 2 | ✓ PASS |
| Glyph `square.grid.2x2` used | `grep -c "square.grid.2x2" ProjectOverviewView.swift` | 1 | ✓ PASS |
| Verbatim D-14 subheadline | `grep "Press + to add your first Scratch Pad, Browser, Bookmark, or Location."` | 1 match | ✓ PASS |
| No "No bookmarks yet" / "No locations added yet" copy | grep both | 0 + 0 | ✓ PASS |
| No `withAnimation` around section show/hide (SidebarView) | `grep -c "withAnimation" SidebarView.swift` | 0 | ✓ PASS |
| No `withAnimation` around section show/hide (Overview) | `grep -c "withAnimation" ProjectOverviewView.swift` | 0 | ✓ PASS |
| Two overview AppStorage keys (outer + nested, both per-project) | `grep -E "overview.browsers.(bookmarks.)?expanded"` | outer once, nested once | ✓ PASS |
| No `+` Button inside emptyHero | Read `:361-377` | VStack with Image + Text + Text only, no Button | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| UIX-10 | 11-01 | Sidebar Scratch Pads renders only when ≥1 scratch pad | ✓ SATISFIED | `SidebarView.swift:57` `if !appState.scratchPadManager.scratchPads(forProject: projectID).isEmpty` — preserved from pre-Phase-11. |
| UIX-11 | 11-01 | Sidebar Browsers renders only when ≥1 tab OR ≥1 bookmark | ✓ SATISFIED | `SidebarView.swift:549` widened guard. |
| UIX-12 | 11-01 | Sidebar Locations renders only when ≥1 location | ✓ SATISFIED | `SidebarView.swift:72` new guard. |
| UIX-13 | 11-01 | Top-level Bookmarks gone; renders as sub-section inside Browsers | ✓ SATISFIED | BookmarkSidebarSection removed; NestedBookmarkSubSection called at `SidebarView.swift:557`. |
| UIX-14 | 11-02 | Overview hides empty cards; single empty-hero replaces per-section empty rows | ✓ SATISFIED | All 4 non-Todos sections body-gated; `emptyHero` rendered when `isProjectContentEmpty`; inline empty-row helpers deleted. |
| UIX-15 | 11-02 | Overview Bookmarks nested under Browsers card using existing `CollapsibleVStackSection` | ✓ SATISFIED | Nested `CollapsibleVStackSection("Bookmarks", ...)` at `ProjectOverviewView.swift:413` inside outer Browsers card. |

All 6 requirements SATISFIED by shipped code. No orphaned requirements mapped to Phase 11 in REQUIREMENTS.md.

### Anti-Patterns Found

None.

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| — | — | No blockers, warnings, or info-level anti-patterns detected | — | — |

Specific checks that PASSED:
- No TODO/FIXME/PLACEHOLDER in any touched file
- No "coming soon" / "not yet implemented" copy
- No `return null` / empty render paths
- No hardcoded empty arrays feeding rendered sections (all data flows through @Query)
- No `withAnimation` wrapping section show/hide branches
- No embedded `+` Button inside emptyHero (Phase 10 exactly-two-+-menus invariant honored)

### User-Preference Invariants

| Invariant | Source | Status | Evidence |
|-----------|--------|--------|----------|
| No animated transition on section show/hide | D-22 + memory `feedback_no_slide_transitions` | ✓ HONORED | 0 `withAnimation` calls in SidebarView.swift or ProjectOverviewView.swift. Section appearance is instant on `@Query` reactivity. |
| No embedded `+` inside overview empty hero | D-13 (preserves Phase 10 "exactly two `+` menus") | ✓ HONORED | `emptyHero` (`ProjectOverviewView.swift:361-377`) is a passive VStack with Image + 2 Text elements only. No Button. |
| Hero subheadline verbatim D-14 copy | D-14 | ✓ HONORED | `ProjectOverviewView.swift:370` contains the exact literal "Press + to add your first Scratch Pad, Browser, Bookmark, or Location." (single match). |
| No inline "No bookmarks yet" / "No locations added yet" empty rows | D-15 | ✓ HONORED | Both strings return 0 matches file-wide in ProjectOverviewView.swift. |

### Human Verification Required

Phase 11 is a structural refactor of existing visual surfaces. All automated code-structure checks pass. The following items require a human to run the app and observe rendered behavior. This matches the project's established testing cadence (unit tests for logic, manual UAT for rendering) and was explicitly deferred by both SUMMARY documents.

#### 1. Fresh project shows Overview row + bottom-bar only in sidebar

**Test:** Select a project with zero scratch pads, zero browser tabs, zero bookmarks, zero locations.
**Expected:** Sidebar renders: Overview row, OrphanedSessionsSection (self-hides when empty), and the `+` bottom bar. No Scratch Pads, Browsers, Bookmarks, or Locations section headers visible.
**Why human:** SC#1 — visual sidebar rendering. Code shows all four sections are gated by `if !xs.isEmpty`, but final rendered absence requires observing the running app.

#### 2. Fresh project Overview shows centered empty-hero below Todos

**Test:** Open the project overview tab on a fresh project.
**Expected:** Top of VStack shows project header, Todos section (always), then a centered VStack with 48pt `square.grid.2x2` glyph, "Nothing here yet" headline, and the verbatim D-14 subheadline. No Sessions/Browsers/Documents/Locations cards. No `+` button inside the hero.
**Why human:** SC#2 — visual appearance and positioning below Todos. Code has correct copy + glyph + no Button; visual centering/spacing require rendered confirmation.

#### 3. First browser tab surfaces Browsers section; first bookmark surfaces nested Bookmarks (n)

**Test:** Open a browser tab. Then star a page.
**Expected:** Opening the tab surfaces Browsers section header + tab row in sidebar. Starring surfaces a `Bookmarks (1)` nested sub-header directly under the browser row (same Browsers section), with chevron-right glyph. Never appears as top-level section. Toggling the nested chevron collapses/expands bookmark rows independently from the outer Browsers chevron. Count updates when collapsed; label is plain "Bookmarks" when expanded.
**Why human:** SC#3 — real-time @Query reactivity + visual hierarchy + count-only-when-collapsed UX. Runtime observation required.

#### 4. Delete-last-item removes section instantly with no animated transition

**Test:** With exactly one browser bookmark in a nested Bookmarks sub-section, delete it via context menu → observe. Then: last scratch pad, last location, last browser tab.
**Expected:** Each section disappears instantly on the next render tick — no slide, no fade, no height-collapse animation. If 0 tabs + the only bookmark was deleted, the whole Browsers section vanishes in the same tick.
**Why human:** SC#4 — animation absence is a behavioral/visual property. Code scan confirms zero `withAnimation` on section appearance branches, but only runtime observation confirms the visual "snap to absent" behavior.

#### 5. Overview Bookmarks nested inside Browsers card, collapses independently

**Test:** With ≥1 browser tab AND ≥1 bookmark: view Project Overview. Toggle outer Browsers chevron. Toggle inner Bookmarks chevron. Relaunch app.
**Expected:** Single "Browsers" card containing tab grid + nested "Bookmarks" card. Outer collapse hides both. Inner collapse hides only bookmarks (tab grid remains visible). Each chevron state persists across relaunch (different `@AppStorage` keys: `overview.browsers.expanded.{projectID}` outer, `overview.browsers.bookmarks.expanded.{projectID}` inner).
**Why human:** SC#5 — visual nesting + independent collapse behavior + persistence across relaunch.

### Gaps Summary

No automated-detectable gaps. All 5 ROADMAP Success Criteria are structurally satisfied in the shipped code. All 6 requirements (UIX-10…UIX-15) have clear code evidence. Build is green on macOS arm64 Debug. All user-preference invariants (D-13, D-14, D-15, D-22) are honored.

The 5 human-verification items above are the standard "run-the-app UAT" pass that Phase 11 always expected (both SUMMARY documents explicitly deferred manual UAT). They represent the final sign-off step for a visual refactor phase — they are not gaps in implementation, but rather the inherent need for a human to confirm that rendered pixels match the contract.

**Recommended next step:** Run the app on a fresh project, work through the 5 human-verification tests above in order, and if all pass, Phase 11 graduates to `passed`. If any test reveals a visual regression not caught by automated checks, file the specific failing criterion as a gap and re-plan.

---

*Verified: 2026-04-19*
*Verifier: Claude (gsd-verifier)*
