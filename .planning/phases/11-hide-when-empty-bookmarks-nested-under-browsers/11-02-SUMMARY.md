---
phase: 11-hide-when-empty-bookmarks-nested-under-browsers
plan: 02
subsystem: ui
tags: [swiftui, overview, appstorage, macos, empty-state]

requires:
  - phase: 11-hide-when-empty-bookmarks-nested-under-browsers
    plan: 01
    provides: Sidebar hide-when-empty + nested Bookmarks sub-section under Browsers; established the one-card-two-chevrons pattern that this plan mirrors on the Project Overview
provides:
  - Project Overview hides empty Sessions / Browsers / Documents / Locations cards; Todos always renders at top (UIX-14)
  - Centered empty-hero below Todos when every non-Todos source is empty — glyph square.grid.2x2 at 48pt, headline "Nothing here yet", D-14 subheadline verbatim (UIX-14)
  - Standalone Bookmarks card deleted; populated bookmarks LazyVGrid lives inside browsersSection as a nested CollapsibleVStackSection (UIX-15)
  - Browsers card visibility widened: renders when !browserTabs.isEmpty || !projectBrowserBookmarks.isEmpty (D-20)
  - New @AppStorage key overview.browsers.bookmarks.expanded.{projectID} for the inner Bookmarks chevron — independent from the outer overview.browsers.expanded.{projectID} (D-21)
  - Inline empty-state rows deleted from Project Overview ("No bookmarks yet…" and "No locations added yet…") — no section renders with placeholder copy (D-15)
  - Delete-last-item causes instant section disappearance — zero withAnimation/transition wrappers on show/hide (D-22, user memory feedback_no_slide_transitions)
affects: [phase-12 section-parity, phase-12 @AppStorage audit (orphan overview.bookmarks.expanded key)]

tech-stack:
  added: []
  patterns:
    - "Body-level hide-when-empty guard around each section call — mirrors SidebarView pattern from plan 11-01"
    - "Nested CollapsibleVStackSection inside parent CollapsibleVStackSection — verified by 11-RESEARCH §Pattern 3; second chevron signals hierarchy without indent"
    - "Compound boolean (isProjectContentEmpty) drives overview-level empty-hero — Todos excluded; hero renders below Todos when triggered"
    - "Passive empty-hero (no Button, no + affordance) preserves Phase-10 exactly-two-+-menus invariant"

key-files:
  created: []
  modified:
    - wrangle/Features/Dashboard/ProjectOverviewView.swift

key-decisions:
  - "emptyHero placed between // MARK: - Sessions and // MARK: - Browsers as a new private var (not inlined into body) — keeps body VStack readable and gives the hero a dedicated MARK for future edits"
  - "isProjectContentEmpty is a computed property on ProjectOverviewView (not hoisted to AppState) — all five terms are already in-view computed arrays; hoisting would require threading projectID into AppState which has no other overview-scoped state"
  - "locationsSection body-level guard uses `if !projectBookmarks.isEmpty { locationsSection }` exactly as the plan prescribes (verbatim string match) — enables the grep-based verification in the plan's acceptance criteria without ambiguity"
  - "Orphan @AppStorage key overview.bookmarks.expanded.{projectID} (from the deleted standalone bookmarksSection) intentionally left in UserDefaults — no user-visible effect; Phase 12 UIX-22 audit decides whether to clean up"
  - "Comment for the deleted inline locations empty-state rewritten from mentioning \"No locations added yet\" verbatim to a more generic \"inline empty-state row deleted\" — plan's acceptance criterion required the literal string to be absent file-wide, including comments"

patterns-established:
  - "Pattern: overview-level empty-hero via compound boolean on all non-Todos sources — passive VStack, 48pt glyph, two-line text, .padding(.vertical, 48); applicable wherever a multi-section surface needs a single unified blank state"
  - "Pattern: nested CollapsibleVStackSection for grouped related content — one outer card, two chevrons, no indent; second chevron is the visual hierarchy cue"

requirements-completed: [UIX-14, UIX-15]

duration: 3min 34s
completed: 2026-04-20
---

# Phase 11 Plan 02: Project Overview Hide-When-Empty + Nested Bookmarks Summary

**Project Overview now hides empty section cards entirely, shows a single centered empty-hero below Todos when the project is fresh, and the standalone Bookmarks card is folded into Browsers as a nested CollapsibleVStackSection — one card, two chevrons.**

## Performance

- **Duration:** 3 min 34 s
- **Started:** 2026-04-20T03:29:58Z
- **Completed:** 2026-04-20T03:33:32Z
- **Tasks:** 3 (two with file edits, one build verification)
- **Files modified:** 1 (`wrangle/Features/Dashboard/ProjectOverviewView.swift`)

## Accomplishments

- Standalone `bookmarksSection` + `bookmarksContent` computed properties deleted (and the `// MARK: - Bookmarks` header with them). The populated bookmarks `LazyVGrid` migrated verbatim into `browsersSection` as a nested `CollapsibleVStackSection` titled "Bookmarks" — card layout, `.prefix(12)` cap, "Showing 12 of N" overflow caption all preserved unchanged (UIX-15 / D-16-D-18).
- New `@AppStorage("overview.browsers.bookmarks.expanded.\(projectID)")` key (default true) governs the inner Bookmarks chevron, independent from the outer `overview.browsers.expanded.\(projectID)` (D-21).
- Browsers card visibility broadened in the body to `if !browserTabs.isEmpty || !projectBrowserBookmarks.isEmpty { browsersSection }` — the card now renders when either tabs OR bookmarks are present (D-20).
- Inline "No bookmarks yet. Star a page or import from another browser." row deleted alongside `bookmarksContent` (D-15).
- `locationsSection` rewritten: the `if projectBookmarks.isEmpty { inline HStack } else { grid }` split collapsed to grid-only; body-level guard `if !projectBookmarks.isEmpty { locationsSection }` replaces the inline empty branch. "No locations added yet. Add a folder to get started." removed from the codebase entirely (D-15).
- New `isProjectContentEmpty` computed property on `ProjectOverviewView` encapsulates the D-12 compound boolean (`terminalSessions && browserTabs && documentTabs && projectBrowserBookmarks && projectBookmarks` all `.isEmpty`). Todos are intentionally NOT factored in — they always render at top as the primary capture surface.
- New `emptyHero` private var: centered VStack with `square.grid.2x2` at 48pt, "Nothing here yet" headline (.title3 semibold secondary), and the verbatim D-14 subheadline "Press + to add your first Scratch Pad, Browser, Bookmark, or Location." (subheadline tertiary, multiline-centered). Framed `.frame(maxWidth: .infinity)` with `.padding(.vertical, 48)`.
- Body VStack rewritten: `if isProjectContentEmpty { emptyHero }` sits right below `todosSection` and above the four non-Todos section calls. No section call wraps the hero; the hero's `if` is peer to the section guards.
- Zero `withAnimation { }` / `.transition(…)` / `.animation(…, value: …)` wrappers introduced on any section show/hide or on the hero's appearance (D-22 / user memory `feedback_no_slide_transitions`). Section disappearance on delete-last-item is therefore instant.
- `xcodebuild -scheme Wrangle -destination 'platform=macOS,arch=arm64' -configuration Debug build` → **BUILD SUCCEEDED**.

## Task Commits

1. **Task 1: Restructure browsersSection to absorb nested Bookmarks grid; delete standalone bookmarksSection + bookmarksContent** — `1264fe5` (refactor)
2. **Task 2: Body empty-hero + hide-when-empty guards for browsersSection and locationsSection; delete inline "No locations" empty row** — `6c53898` (feat)
3. **Task 3: xcodebuild verification** — no commit (verification-only task, no file edits; matches 11-01 precedent)

## Files Created/Modified

- `wrangle/Features/Dashboard/ProjectOverviewView.swift`
  - Added: `isProjectContentEmpty` computed property (after `projectBrowserBookmarks`), `emptyHero` private var (between Sessions and Browsers), nested `CollapsibleVStackSection("Bookmarks", …)` inside `browsersSection`.
  - Modified: `browsersSection` body split into `if !browserTabs.isEmpty { tabGrid }` + `if !projectBrowserBookmarks.isEmpty { nestedBookmarks }`; `locationsSection` body reduced to populated-grid-only; body VStack gains four new guards (`if isProjectContentEmpty`, broadened browsers `||`, `if !projectBookmarks.isEmpty` wrapper around locations) and loses the unconditional `bookmarksSection` call.
  - Deleted: `bookmarksSection` computed property, `bookmarksContent` computed property, `// MARK: - Bookmarks` header, inline `HStack` "No bookmarks yet. Star a page or import from another browser.", inline `HStack` "No locations added yet. Add a folder to get started." with its `folder.badge.plus` glyph + `.padding(16)`.

## Decisions Made

- **No hoist of `isProjectContentEmpty` to `AppState`.** All five terms (`terminalSessions`, `browserTabs`, `documentTabs`, `projectBrowserBookmarks`, `projectBookmarks`) are already in-view computed properties backed by `@Query` + per-project filters. Hoisting would duplicate that filtering in `AppState` and require threading `projectID` in — `AppState` has no other per-project reactive state. Kept it local.
- **Nested CollapsibleVStackSection, not a lighter inline chevron.** Research §Pattern 3 verified CollapsibleVStackSection nests cleanly (plain `VStack`, no re-entrance issues). Using it keeps the inner chrome consistent with other overview sections (same chevron treatment, same `@AppStorage` semantics, same `.snappy(0.18)` collapse animation). A lighter inline variant would introduce a second chevron style on the overview for no gain.
- **No indent on the inner Bookmarks CollapsibleVStackSection** — the second chevron is the hierarchy cue (per D-17 + UI-SPEC §Pattern B "Indent inside the Browsers card: NONE").
- **Empty-hero below Todos, not above.** Plan + UI-SPEC Pattern C explicit: Todos always renders at top (primary capture surface); hero sits below when compound boolean triggers. Since `isProjectContentEmpty` only fires when every non-Todos source is empty, no hero ever co-exists with a populated section — the ordering (`todosSection` → `emptyHero` → [guards] → sections) makes this self-evident.
- **Comment adjusted to avoid false grep-positive.** Original explanatory comment in `locationsSection` quoted "No locations added yet" literally; plan acceptance required the string to be absent file-wide. Rewrote comment to "inline empty-state row deleted" — same meaning, no grep hit.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Comment containing verbatim "No locations added yet" violated plan's file-wide-absent acceptance criterion**
- **Found during:** Task 2 acceptance verification after Edit 4 (`locationsSection` simplification)
- **Issue:** Added a `D-15: inline "No locations added yet" row deleted` explanatory comment inside `locationsSection`. `grep -c "No locations added yet" wrangle/Features/Dashboard/ProjectOverviewView.swift` returned 1 — plan required 0.
- **Fix:** Rewrote the comment to "D-15: inline empty-state row deleted. Section is gated at the body level by `if !projectBookmarks.isEmpty` — reaching here means non-empty." Same intent, no literal match on the forbidden string.
- **Files modified:** `wrangle/Features/Dashboard/ProjectOverviewView.swift` (comment only).
- **Verification:** `grep -c -F "No locations added yet" wrangle/Features/Dashboard/ProjectOverviewView.swift` → 0.
- **Committed in:** `6c53898` (same commit as Task 2 — the comment fix was folded before staging).

---

**Total deviations:** 1 (Rule 3 — blocking the acceptance criterion).
**Impact on plan:** None on behavior, copy, or generated code paths. Cosmetic comment edit only.

## Verification Commands Run

```
# Phase-level grep checks (from 11-02-PLAN.md §verification) — all PASS:
grep -c "bookmarksSection"                 wrangle/Features/Dashboard/ProjectOverviewView.swift  → 0
grep -c "bookmarksContent"                 wrangle/Features/Dashboard/ProjectOverviewView.swift  → 0
grep -c "No bookmarks yet"                 wrangle/Features/Dashboard/ProjectOverviewView.swift  → 0
grep -c "No locations added yet"           wrangle/Features/Dashboard/ProjectOverviewView.swift  → 0
grep -c "overview.browsers.bookmarks.expanded"                                                    → 1
grep -c "Nothing here yet"                                                                        → 1
grep -c "Press + to add your first Scratch Pad, Browser, Bookmark, or Location."                  → 1
grep -c "square.grid.2x2"                                                                         → 1
grep -c "!browserTabs.isEmpty || !projectBrowserBookmarks.isEmpty"                                → 1
grep -c "if !projectBookmarks.isEmpty { locationsSection }"                                       → 1
grep -c "isProjectContentEmpty"                                                                   → 2
grep -c "private var emptyHero"                                                                   → 1
grep -c "withAnimation("                                                                          → 0

# Build (Task 3):
xcodebuild -scheme Wrangle -destination 'platform=macOS,arch=arm64' -configuration Debug build   → BUILD SUCCEEDED
```

## Orphan @AppStorage Key Note

The old `@AppStorage("overview.bookmarks.expanded.\(projectID)")` key — formerly used by the now-deleted standalone `bookmarksSection` — becomes orphaned. Acceptable per UI-SPEC §Pattern B deprecation note: this is a localStorage-style preference key; leaving it stranded doesn't affect users (nothing reads it anymore, no stale UI surface appears). **Phase 12 UIX-22 (`@AppStorage` expansion-state key audit) will decide whether to delete-on-migration or leave alone.** Not a blocker for this phase.

## Build Result

```
** BUILD SUCCEEDED **
```

## Issues Encountered

- **Case-insensitive filesystem vs git tracking** (same as 11-01): macOS treats `Wrangle/` and `wrangle/` as the same path, but git tracks the lowercase form. First `git add Wrangle/Features/…` silently matched nothing against the index; retried with `git add wrangle/Features/…` and succeeded. No code change; noted for future renames.
- **PreToolUse Edit hook READ-BEFORE-EDIT reminders** fired on five successive Edit calls — the hook appears to reset its "file has been read" tracker after each Edit, not the session's Read history. Each edit still succeeded; the reminders are advisory. Added intervening `Read` calls to appease the hook but did not alter the edit flow.

## User Setup Required

None — no external service configuration, no new @AppStorage migration action required. The orphan key `overview.bookmarks.expanded.{projectID}` is left in UserDefaults and is simply no longer read; the new key `overview.browsers.bookmarks.expanded.{projectID}` gets its default value (true) on first open after the update.

## Phase 11 Readiness

**Phase 11 is COMPLETE** (both plans shipped):
- [x] 11-01 — Sidebar hide-when-empty + nested Bookmarks under Browsers (UIX-10 / UIX-11 / UIX-12 / UIX-13)
- [x] 11-02 — Project Overview hide-when-empty + nested Bookmarks under Browsers (UIX-14 / UIX-15)

**Phase-level Success Criteria (from ROADMAP.md §Phase 11):**
1. Fresh project with no content shows no section cards in sidebar — just Overview row + `+` bottom bar. (11-01 — verified green build)
2. Fresh project's Overview page shows centered empty-hero below Todos; no empty section cards. (11-02 — this plan)
3. Creating a first Browser tab surfaces the Browsers section in sidebar; creating a bookmark surfaces nested `Bookmarks (N)` sub-section. (11-01)
4. Deleting the last item in any section removes the section on the next render tick — no animation. (both plans — `@Query` reactivity + instant swap)
5. Overview's Bookmarks card visually grouped with Browsers via nested `CollapsibleVStackSection`; independent collapse/expand. (11-02 — this plan)

**Next:** Phase 12 — Section Parity & Polish (canonical `SidebarSectionHeader`, Scratch Pad rename/delete parity, `@AppStorage` key audit including the orphan left by this plan).

**Manual UAT deferred:** Behavioral smoke check (fresh project shows hero only; adding a terminal hides hero + reveals Sessions; starring a page reveals nested Bookmarks inside Browsers; deleting the only bookmark vanishes the sub-section instantly; etc.) — matches project testing cadence (unit tests for logic, manual UAT for rendering).

## Self-Check: PASSED

- [x] `wrangle/Features/Dashboard/ProjectOverviewView.swift` exists — confirmed present via filesystem read.
- [x] Commit `1264fe5` (Task 1) exists on main — `git log --oneline | grep 1264fe5` matches.
- [x] Commit `6c53898` (Task 2) exists on main — `git log --oneline | grep 6c53898` matches.
- [x] `grep -c "private var bookmarksSection"` → 0.
- [x] `grep -c "bookmarksContent"` → 0.
- [x] `grep -c "No bookmarks yet"` → 0.
- [x] `grep -c "No locations added yet"` → 0.
- [x] `grep -c "overview.browsers.bookmarks.expanded"` → 1.
- [x] `grep -c "Nothing here yet"` → 1.
- [x] `grep -c "Press + to add your first Scratch Pad, Browser, Bookmark, or Location."` → 1.
- [x] `grep -c "square.grid.2x2"` → 1.
- [x] `grep -c "!browserTabs.isEmpty || !projectBrowserBookmarks.isEmpty"` → 1.
- [x] `grep -c "if !projectBookmarks.isEmpty { locationsSection }"` → 1.
- [x] `grep -c "isProjectContentEmpty"` → 2.
- [x] `grep -c "private var emptyHero"` → 1.
- [x] `grep -c "withAnimation("` → 0 (no new animation wrappers on section show/hide; D-22 honored).
- [x] `xcodebuild -scheme Wrangle -destination 'platform=macOS,arch=arm64' -configuration Debug build` → **BUILD SUCCEEDED**.

---
*Phase: 11-hide-when-empty-bookmarks-nested-under-browsers*
*Completed: 2026-04-20*
