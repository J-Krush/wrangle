# Plan: File Tree UI Tightening

**Goal:** Make Wrangle's file tree sidebar feel like Xcode/VS Code — tight, dense, fast to scan. Power-user density, not consumer spacing.

**Key insight from research:** The main culprit is SwiftUI List's default row padding inflating rows to ~28px. Every major IDE uses 20-22px rows. We need to constrain icon sizes, set explicit font sizes, and tune row insets. The existing SwiftUI List approach is fine — no need to rewrite to NSOutlineView.

**Files to modify:**
- `Wrangle/Sidebar/FileTreeNode.swift` — row rendering (nodeLabel, row insets)
- `Wrangle/Sidebar/SidebarView.swift` — List environment settings
- `Wrangle/Sidebar/BookmarkListView.swift` or `RoomBookmarkListView.swift` — if row insets are set there

---

## Task 1: Add `.sidebarRowSize(.small)` to the List

**File:** `SidebarView.swift:80`

Currently has:
```swift
.environment(\.defaultMinListRowHeight, 22)
```

Add:
```swift
.environment(\.defaultMinListRowHeight, 20)
.environment(\.sidebarRowSize, .small)
```

This tells macOS to use the compact sidebar row size (same as Xcode's "small" navigator). Dropping from 22 to 20 as the minimum since `.sidebarRowSize(.small)` will handle the rest.

**Why:** This is the single highest-impact change. It's Apple's official API for sidebar density and what CodeEdit used to fix the exact same 28px→22px problem.

---

## Task 2: Constrain icon size and set explicit font on nodeLabel

**File:** `FileTreeNode.swift:326-335`

Current:
```swift
private var nodeLabel: some View {
    HStack(spacing: 6) {
        Image(systemName: node.icon)
            .foregroundStyle(node.iconColor)
        Text(node.name)
            .lineLimit(1)
            .truncationMode(.middle)
        Spacer()
    }
}
```

Change to:
```swift
private var nodeLabel: some View {
    HStack(spacing: 5) {
        Image(systemName: node.icon)
            .font(.system(size: 13))
            .frame(width: 16, height: 16, alignment: .center)
            .foregroundStyle(node.iconColor)
        Text(node.name)
            .font(.system(size: 12))
            .lineLimit(1)
            .truncationMode(.middle)
        Spacer()
    }
}
```

**Why:**
- Icon at 13pt SF Symbol renders at ~16px optical size — matches Xcode/VS Code
- `.frame(width: 16, height: 16)` prevents larger icons from inflating row height
- Font at 12pt matches Xcode's small sidebar and is the sweet spot for density without sacrificing readability
- Spacing reduced from 6→5 to match Xcode's tighter icon-text gap

---

## Task 3: Set tight listRowInsets on file tree rows

**File:** `FileTreeNode.swift` — on directoryView, openableFileView, unopenableFileView

Add to each view:
```swift
.listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 4))
```

**Why:** Removes the default vertical and leading padding that SwiftUI List adds to each row. The trailing 4pt keeps text from touching the scrollbar. This works with the `defaultMinListRowHeight` to achieve true 22px rows.

---

## Task 4: Use system accent color for selection instead of white opacity

**File:** `FileTreeNode.swift:278, 304` and `Wrangle/Utilities/Theme.swift` (`sidebarSelectionBackground`)

Current selection is `Color.white.opacity(0.10)` with a 0.25 border — this looks custom rather than native.

Change `Theme.sidebarSelectionBackground` to use the system accent color:
```swift
static func sidebarSelectionBackground(isSelected: Bool) -> some View {
    Rectangle()
        .fill(isSelected ? Color.accentColor.opacity(0.2) : Color.clear)
}
```

**Why:** Every native macOS sidebar (Xcode, Finder, Nova) uses the system accent color for selection. This makes Wrangle feel native rather than custom-themed. Users who change their system accent color will see it reflected.

---

## Task 5: Tighten section headers and list section spacing

**File:** `SidebarView.swift` — the Section declarations

Investigate if SwiftUI Section headers are adding extra vertical space. If so, add:
```swift
.listSectionSpacing(.compact)  // macOS 15+
```

to the List, or use custom section headers with smaller fonts.

**Why:** Section headers ("Locations", "Browsers", etc.) may be adding vertical padding that compounds with row padding to create the spacious feeling in the screenshots.

---

## Task 6: Test and tune empirically

After applying Tasks 1-5, build and measure:
- [ ] Row height should be ~22px (use Xcode View Hierarchy debugger)
- [ ] Compare side-by-side with Xcode's navigator on the same project
- [ ] Verify keyboard navigation (arrow keys expand/collapse) still works
- [ ] Verify drag & drop still works
- [ ] Verify disclosure triangles still render correctly
- [ ] Check deep nesting (5+ levels) doesn't truncate file names too aggressively
- [ ] Verify the file tree still looks good at sidebar widths from 140-400pt

---

## Execution Order

1. **Task 1** (sidebarRowSize) — biggest impact, one line
2. **Task 2** (icon + font sizing) — second biggest impact
3. **Task 3** (row insets) — fine tuning
4. **Task 4** (selection color) — visual polish
5. **Task 5** (section spacing) — if still needed after 1-3
6. **Task 6** (verify) — always last

## What This Does NOT Change

- File tree data model (FileNode struct) — untouched
- Filtering logic — untouched
- File watcher — untouched
- Drag & drop — untouched
- Context menus — untouched
- DisclosureGroup pattern — kept (it's correct)
- Double-click behavior — kept

## Risk Assessment

- **Low risk:** All changes are visual/styling. No logic changes.
- **Reversible:** Every change is a CSS-equivalent tweak, easily reverted.
- **One unknown:** Exact achievable minimum row height with SwiftUI List on macOS 15 — may need empirical tuning between 20-22pt in `defaultMinListRowHeight`.
