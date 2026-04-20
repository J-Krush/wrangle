# Requirements: Wrangle v1.2 — Browser Support

**Defined:** 2026-04-19
**Core Value:** Every surface — editor, terminal, file tree, browser — serves a developer driving AI agents. Speed, density, and AI-file awareness win over breadth of consumer features.

## Milestone v1.2 Requirements

Requirements for the v1.2 Browser Support milestone. Each maps to exactly one roadmap phase (see Traceability).

### BR — Browser Restoration

- [ ] **BR-01**: User sees "New Browser" in the sidebar `+` menu and can click it to open a browser tab.
- [ ] **BR-02**: User sees "New Browser" in the tab-strip `+` menu and can click it to open a browser tab.
- [ ] **BR-03**: User sees "New Browser" in the Location header action menu and can click it to open a browser tab.
- [ ] **BR-04**: User can open a browser from the `File → New Browser` menu item with `Cmd+Option+B`.

### BH — Core Hardening

- [ ] **BH-01**: User can press `Cmd+F` inside a browser tab to show the native find-in-page bar (`WKWebView.findInteraction`, macOS 14+).
- [ ] **BH-02**: User can press `Cmd+T` to open a new internal tab inside the active browser session.
- [ ] **BH-03**: User can press `Cmd+W` to close the active browser tab; if it is the last tab in the session, the session closes.
- [ ] **BH-04**: User can press `Cmd+[` / `Cmd+]` inside a focused browser tab to go back / forward in page history without breaking global workspace-tab navigation.
- [ ] **BH-05**: Favicons load once per domain and are cached in memory and in SwiftData so subsequent renders avoid re-fetching.
- [ ] **BH-06**: Opening a browser with no URL lands on a "New Tab" page with a URL field and recent bookmarks.

### DT — Developer Tools

- [ ] **DT-01**: User can press `Cmd+Option+I` in a focused browser tab to toggle the in-app dev tools panel.
- [ ] **DT-02**: User can press `Cmd+Option+J` to toggle the panel and land on the Console tab.
- [ ] **DT-03**: User can press `Cmd+Option+C` to toggle the panel and arm the element picker (delegates to `ElementInspectorView.toggleSelectMode`).
- [ ] **DT-04**: User can right-click inside the WKWebView and choose "Inspect Element" to route into the element picker.

### BX — Browser Chrome & Security Indicators

- [ ] **BX-01**: URL bar shows a padlock status icon — green for valid HTTPS, warning for mixed content, red for certificate errors.
- [ ] **BX-02**: User can click the padlock to see a popover with certificate subject, issuer, expiry, and TLS version.
- [ ] **BX-03**: User can choose a user-agent preset (Safari default / Chrome-identical / Custom) in Preferences → Browser; selection persists and is applied via `WKWebView.customUserAgent`.
- [ ] **BX-04**: Active page title and origin appear in the internal tab bar (truncated title, favicon visible, tooltip shows full URL).

### BM — Bookmarks

- [ ] **BM-01**: User can bookmark the current page via a star toggle in `BrowserToolbar` (toggle off to remove).
- [ ] **BM-02**: User can view bookmarks in a dedicated sidebar section grouped by folder.
- [ ] **BM-03**: User can single-click a bookmark to open in the active browser tab, `Cmd`-click to open in a new tab; context menu offers Open in New Window / Copy URL / Edit / Delete.
- [ ] **BM-04**: User can edit bookmark title, URL, or folder via an edit dialog.
- [ ] **BM-05**: User can delete a bookmark via context menu or the Delete key.
- [ ] **BM-06**: Bookmarks persist across app launches and are scoped per project; a "Global" pseudo-folder stores project-agnostic bookmarks.

### BI — Bookmark Import

- [ ] **BI-01**: User can open `File → Import Bookmarks…` and select a source (Safari / Brave / Chrome / Firefox).
- [ ] **BI-02**: User sees a preview of folders and bookmark count before committing and can deselect folders.
- [ ] **BI-03**: Chrome importer reads `~/Library/Application Support/Google/Chrome/<Profile>/Bookmarks` (JSON), with a profile picker when multiple profiles exist.
- [ ] **BI-04**: Brave importer reads `~/Library/Application Support/BraveSoftware/Brave-Browser/<Profile>/Bookmarks` (same JSON format as Chrome).
- [ ] **BI-05**: Firefox importer reads `places.sqlite`, copying the file to a temp directory first to avoid WAL lock issues, and queries `moz_bookmarks` + `moz_places`.
- [ ] **BI-06**: Safari importer reads `~/Library/Safari/Bookmarks.plist` directly; on TCC denial (NSFileReadNoPermissionError), UI surfaces a clear "Full Disk Access required" dialog with a deep link to System Settings → Privacy & Security → Full Disk Access.
- [ ] **BI-07**: Import deduplicates by normalized URL; re-running an import is additive, not duplicative.

### BW — Browsing History

- [ ] **BW-01**: URL visits are recorded automatically (url, title, dateVisited, favicon snapshot) via the navigation-delegate `didFinish` hook — except in private tabs.
- [ ] **BW-02**: User can view history grouped by Today / Yesterday / Past Week / Older.
- [ ] **BW-03**: User can clear history: last hour / last day / last week / all time.
- [ ] **BW-04**: URL bar shows history and bookmark suggestions as the user types (simple prefix match initially).

### BD — Downloads

- [ ] **BD-01**: Link-initiated downloads are intercepted via `WKDownloadDelegate`; default save location is `~/Downloads/` (configurable in Preferences).
- [ ] **BD-02**: In-progress downloads show a progress bar and bytes-received/total in a downloads popover anchored to a toolbar button.
- [ ] **BD-03**: Completed downloads appear in the popover list with actions: Show in Finder / Open / Remove from list.
- [ ] **BD-04**: Downloads persist across app restarts (`BrowserDownloadRecord` @Model); downloads in progress at the time of a crash show as "Incomplete" on next launch.
- [ ] **BD-05**: User can cancel an in-progress download; the partial file is deleted.

### BP — Private / Incognito Mode

- [ ] **BP-01**: User can open a private browser via `File → New Private Browser` or `Cmd+Shift+Option+B`.
- [ ] **BP-02**: Private tabs use `WKWebsiteDataStore.nonPersistent()` — no cookies, cache, or history persisted to disk for the session.
- [ ] **BP-03**: Private tabs are visually distinct (purple accent on tab chrome, "Private" label in URL bar, Private glyph on workspace tab).
- [ ] **BP-04**: Private sessions do not record history (BW-01); explicit bookmark actions still save, tagged "from private".

### UIX — Interaction Polish (v1.2 UX pass)

A consistency pass across sidebar + Project Overview. Collapses five scattered creation affordances into two unified '+' menus, hides empty sections, nests browser bookmarks under Browsers, and normalizes section-header chrome.

**UIX-01…05 — Unified creation pattern**

- [x] **UIX-01**: Sidebar bottom-bar `+` is the sole creation entry point in the sidebar chrome; its menu exposes every creatable type: Scratch Pad, Browser, Bookmark (current page, only when a browser tab is focused), Terminal…, Location…, File…, Import Bookmarks…. _(Plan 10-01: menu in place. Per-section `…` / `+` / `Import…` accessories removal is plan 10-02; until then, duplicate affordances still visible.)_
- [x] **UIX-02**: Project Overview header `+` is the sole creation entry point in the overview; its menu content and ordering match UIX-01. _(Plan 10-01: menu in place. Card-level accessories removal is plan 10-02.)_
- [x] **UIX-03**: All sidebar section headers (Browsers, Locations, Scratch Pads, Orphaned Sessions, and any Bookmarks subsection) are navigation-only — no `+`, `…`, or inline `Import…` buttons remain on section headers. _(Plan 10-02: Locations `...` + BookmarkSidebarSection `...` removed; SidebarSectionHeader `accessory` ViewBuilder dropped entirely.)_
- [x] **UIX-04**: Project Overview section cards show no inline `+`, `…`, or `Import…` buttons on card headers; the overview header `+` is the sole add entry in the overview. _(Plan 10-02: Bookmarks card `Import…` and Locations card `+` accessories removed.)_
- [x] **UIX-05**: The blue "New" pill beside the Project title in `ProjectOverviewView.header` is removed; creation from the Overview header uses a single `+` IconButton whose visual treatment matches the sidebar `+`. _(Plan 10-01.)_

**UIX-10…15 — Hide-when-empty + Bookmarks nested under Browsers**

- [ ] **UIX-10**: Sidebar Scratch Pads section renders only when the active project has ≥1 scratch pad.
- [ ] **UIX-11**: Sidebar Browsers section renders only when the active project has ≥1 open browser tab OR ≥1 browser bookmark.
- [ ] **UIX-12**: Sidebar Locations section renders only when the active project has ≥1 location.
- [ ] **UIX-13**: The sidebar top-level "Bookmarks" section is removed; browser bookmarks render as a collapsible sub-section inside Browsers, which renders only when ≥1 bookmark exists for the active project.
- [ ] **UIX-14**: Project Overview hides empty section cards entirely; a single overview-level empty state ("Press + to add your first Scratch Pad, Browser, Bookmark, or Location.") replaces per-section empty rows.
- [ ] **UIX-15**: Project Overview Bookmarks card is visually nested under (or directly adjacent to) the Browsers card, mirroring the sidebar hierarchy, using the existing `CollapsibleVStackSection` pattern.

**UIX-20…23 — Section parity + polish**

- [ ] **UIX-20**: All sidebar section headers use a single `SidebarSectionHeader` treatment (font size, foreground color, chevron size, row height, horizontal insets) — no per-section visual overrides remain.
- [ ] **UIX-21**: Scratch Pads rows support the same rename (Return) and delete (Delete / context-menu) affordances already available on Bookmarks rows.
- [ ] **UIX-22**: Expansion state for every collapsible sidebar section (Scratch Pads, Browsers, Bookmarks-within-Browsers, Locations) is persisted via `@AppStorage` using the `sidebar.<section>.expanded` key convention.
- [ ] **UIX-23**: No section renders both a header row and an inline empty-state row — sections either hide (when empty, per UIX-10…13) or show their contents with no empty-state placeholder row.

## Future Requirements (v1.3+)

Deferred from v1.2 — acknowledged, not in current roadmap.

### Browser Expansion
- **BX-FUT-01**: Tab grouping / tab groups within a browser session.
- **BX-FUT-02**: Session restore for crashed tabs (current `BrowserStateStore` handles normal shutdown).
- **BX-FUT-03**: Per-site zoom level persistence.
- **BX-FUT-04**: Reader mode toggle.
- **BX-FUT-05**: Web Inspector remote-debugging hook-up doc (Safari's inspector already works via `isInspectable = true`).

### Bookmark Expansion
- **BM-FUT-01**: Bookmark folders with drag-to-reorder and nested folders.
- **BM-FUT-02**: Bookmark tags / arbitrary categorization.
- **BM-FUT-03**: Bookmark search within sidebar section.
- **BM-FUT-04**: Export bookmarks to HTML (mirror of import).

### Sync & Multi-Device
- **SYNC-FUT-01**: iCloud-backed bookmark sync across Wrangle installs.
- **SYNC-FUT-02**: Cross-device history sync.

## Out of Scope

Explicitly excluded from v1.2 and beyond unless reprioritized.

| Feature | Reason |
|---------|--------|
| Bidirectional browser sync (Safari/Chrome/etc.) | Requires in-browser extensions we don't ship; not feasible without per-browser plumbing. User-confirmed. |
| HTML-export fallback for Safari import | User chose direct plist read with Full Disk Access. Dual-path UI adds complexity without meaningful user benefit. |
| iOS / iPadOS browser surface | Wrangle is macOS-only (macOS 15+ Sequoia). |
| WebExtension API | Not supported by WKWebView; not aligned with Wrangle's AI-developer focus. |
| Plugin/extension marketplace | Out of scope for an editor-first tool. |
| Browser-level password manager | Sensitive surface; defer; users have Keychain / 1Password / Bitwarden. |
| Replacing built-in DevTools with Chromium DevTools | Would pull in a separate engine; WKWebView + custom panel is the intentional choice. |
| Making the app sandboxed | Deferred; `SecurityScopedBookmark.swift` is sandbox-aware should this change. |

## Traceability

Mapping of each requirement to its roadmap phase. Updated during roadmap creation; status updated by execution workflows.

| Requirement | Phase | Status |
|-------------|-------|--------|
| BR-01 | Phase 1 | Pending |
| BR-02 | Phase 1 | Pending |
| BR-03 | Phase 1 | Pending |
| BR-04 | Phase 1 | Pending |
| BH-01 | Phase 2 | Pending |
| BH-02 | Phase 2 | Pending |
| BH-03 | Phase 2 | Pending |
| BH-04 | Phase 2 | Pending |
| BH-05 | Phase 2 | Pending |
| BH-06 | Phase 2 | Pending |
| DT-01 | Phase 3 | Pending |
| DT-02 | Phase 3 | Pending |
| DT-03 | Phase 3 | Pending |
| DT-04 | Phase 3 | Pending |
| BX-01 | Phase 4 | Pending |
| BX-02 | Phase 4 | Pending |
| BX-03 | Phase 4 | Pending |
| BX-04 | Phase 4 | Pending |
| BM-01 | Phase 5 | Pending |
| BM-02 | Phase 5 | Pending |
| BM-03 | Phase 5 | Pending |
| BM-04 | Phase 5 | Pending |
| BM-05 | Phase 5 | Pending |
| BM-06 | Phase 5 | Pending |
| BI-01 | Phase 6 | Pending |
| BI-02 | Phase 6 | Pending |
| BI-03 | Phase 6 | Pending |
| BI-04 | Phase 6 | Pending |
| BI-05 | Phase 6 | Pending |
| BI-06 | Phase 6 | Pending |
| BI-07 | Phase 6 | Pending |
| BW-01 | Phase 7 | Pending |
| BW-02 | Phase 7 | Pending |
| BW-03 | Phase 7 | Pending |
| BW-04 | Phase 7 | Pending |
| BD-01 | Phase 8 | Pending |
| BD-02 | Phase 8 | Pending |
| BD-03 | Phase 8 | Pending |
| BD-04 | Phase 8 | Pending |
| BD-05 | Phase 8 | Pending |
| BP-01 | Phase 9 | Pending |
| BP-02 | Phase 9 | Pending |
| BP-03 | Phase 9 | Pending |
| BP-04 | Phase 9 | Pending |
| UIX-01 | Phase 10 | Complete (10-01) |
| UIX-02 | Phase 10 | Complete (10-01) |
| UIX-03 | Phase 10 | Complete (10-02) |
| UIX-04 | Phase 10 | Complete (10-02) |
| UIX-05 | Phase 10 | Complete (10-01) |
| UIX-10 | Phase 11 | Pending |
| UIX-11 | Phase 11 | Pending |
| UIX-12 | Phase 11 | Pending |
| UIX-13 | Phase 11 | Pending |
| UIX-14 | Phase 11 | Pending |
| UIX-15 | Phase 11 | Pending |
| UIX-20 | Phase 12 | Pending |
| UIX-21 | Phase 12 | Pending |
| UIX-22 | Phase 12 | Pending |
| UIX-23 | Phase 12 | Pending |

**Coverage:**
- v1.2 requirements: 57 total (42 browser core + 15 UX polish)
- Mapped to phases: 57
- Unmapped: 0 ✓

---

*Requirements defined: 2026-04-19*
*Last updated: 2026-04-19 — UIX polish category added (Phases 10–12)*
