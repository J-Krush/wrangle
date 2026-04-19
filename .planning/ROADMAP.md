# Roadmap: Wrangle

## Milestones

- 🚧 **v1.2 Browser Support** — Phases 1–9 (in progress)

## Overview

v1.2 re-exposes and hardens Wrangle's embedded browser. Phase 1 unblocks everything by restoring "New Browser" entry points in `+`/File menus. Phases 2–4 harden the existing WKWebView wrapper (find-in-page, tab shortcuts, favicon cache, New Tab page, dev-tools shortcuts, security indicators, user-agent). Phases 5–6 deliver bookmarks (local SwiftData + star button, then import from Safari/Brave/Chrome/Firefox). Phases 7–9 complete the "real browser" feel with browsing history, downloads, and private / incognito mode. Phases 10–12 are a pre-release UX polish pass: collapse the five scattered creation affordances into two unified `+` menus, hide empty sections, nest browser bookmarks inside the Browsers section, and normalize section-header chrome.

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work.
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED).

Decimal phases appear between their surrounding integers in numeric order. v1.2 starts at Phase 1 — no prior milestone numbering to continue from.

- [ ] **Phase 1: Restore Entry Points** — Uncomment "New Browser" buttons and add File-menu shortcut.
- [ ] **Phase 2: Core Hardening** — Find-in-page, tab shortcuts, favicon cache, New Tab page.
- [ ] **Phase 3: Dev Tools Shortcuts** — Cmd+Option+I/J/C bound to the in-app panel; right-click "Inspect Element".
- [ ] **Phase 4: Browser Chrome & Security** — HTTPS padlock, cert popover, user-agent setting, tab-bar polish.
- [ ] **Phase 5: Bookmark Foundations** — `BrowserBookmark` SwiftData, sidebar section, star button, CRUD.
- [ ] **Phase 6: Bookmark Import** — Safari / Brave / Chrome / Firefox importers with preview, dedupe, re-runnability.
- [ ] **Phase 7: Browsing History** — Auto-recording, grouped view, clear actions, URL-bar suggestions.
- [ ] **Phase 8: Downloads** — WKDownloadDelegate, progress popover, `BrowserDownloadRecord` persistence.
- [ ] **Phase 9: Private / Incognito Mode** — `WKWebsiteDataStore.nonPersistent()`, visual distinction, history suppression.
- [ ] **Phase 10: Unified Creation Pattern** — Collapse 5 scattered add affordances into two unified `+` menus (sidebar bottom-bar + overview header); remove `New` pill.
- [ ] **Phase 11: Hide-When-Empty + Bookmarks Nested Under Browsers** — Sections disappear when empty; top-level Bookmarks folds into Browsers as a sub-section in both sidebar and overview.
- [ ] **Phase 12: Section Parity & Polish** — Canonical `SidebarSectionHeader` treatment, Scratch Pad rename/delete parity with Bookmarks, consistent `@AppStorage` expansion keys.

## Phase Details

### Phase 1: Restore Entry Points
**Goal**: Every "new" menu surface in the app exposes "New Browser" and the File menu gets a keyboard shortcut.
**Depends on**: Nothing (first phase).
**Requirements**: BR-01, BR-02, BR-03, BR-04
**Success Criteria** (what must be TRUE):
  1. User opens the sidebar `+` menu and sees "New Browser"; clicking it opens a browser tab.
  2. User opens the tab-strip `+` menu and sees "New Browser"; clicking it opens a browser tab.
  3. User opens the Location header action menu and sees "New Browser"; clicking it opens a browser tab.
  4. User presses `Cmd+Option+B` from anywhere in the app and a browser tab opens.
**Plans**: TBD (expected: 1 plan).

Plans:
- [ ] 01-01: Uncomment existing "New Browser" blocks + add Location header entry + File menu shortcut.

### Phase 2: Core Hardening
**Goal**: Close user-visible gaps in the existing WKWebView wrapper so the browser behaves like a real browser for common keyboard workflows.
**Depends on**: Phase 1
**Requirements**: BH-01, BH-02, BH-03, BH-04, BH-05, BH-06
**Success Criteria** (what must be TRUE):
  1. User presses `Cmd+F` in a browser tab and a native find-in-page bar appears with working match navigation.
  2. User presses `Cmd+T` / `Cmd+W` and new-tab / close-tab behavior matches a real browser within a browser session.
  3. User presses `Cmd+[` / `Cmd+]` in a browser tab and navigates page history, without breaking global workspace-tab navigation outside the browser.
  4. Visiting the same domain across multiple tabs fetches the favicon only once; relaunching the app shows cached favicons without refetching.
  5. Opening a browser with no URL lands on a usable New Tab page with a URL field and recent-bookmarks grid.
**Plans**: TBD (expected: 2 plans — keyboard + focus scoping is substantial enough to split).

Plans:
- [ ] 02-01: Find-in-page, new-tab / close-tab, back/forward focus-scoped shortcuts.
- [ ] 02-02: Favicon cache + New Tab page.

### Phase 3: Dev Tools Shortcuts
**Goal**: Standard web-developer keyboard shortcuts open the in-app DevTools panel on the correct sub-tab; right-click menu route matches.
**Depends on**: Phase 1
**Requirements**: DT-01, DT-02, DT-03, DT-04
**Success Criteria** (what must be TRUE):
  1. `Cmd+Option+I` in a focused browser tab toggles the in-app dev tools panel.
  2. `Cmd+Option+J` toggles the panel with the Console tab selected.
  3. `Cmd+Option+C` toggles the panel and arms the element picker (`ElementInspectorView.toggleSelectMode`).
  4. Right-click in the WKWebView surfaces "Inspect Element" which routes to the element picker.
**Plans**: TBD (expected: 1 plan).

Plans:
- [ ] 03-01: Focus-scoped keyboard shortcuts + WKUIDelegate context menu routing.

### Phase 4: Browser Chrome & Security
**Goal**: Browser chrome communicates page security clearly and gives the user control over user-agent identification.
**Depends on**: Phase 1
**Requirements**: BX-01, BX-02, BX-03, BX-04
**Success Criteria** (what must be TRUE):
  1. User visits an HTTPS site and sees a green padlock; mixed content or cert errors surface warning / red states.
  2. User clicks the padlock and sees a popover with certificate subject, issuer, expiry, and TLS version.
  3. User can set a user-agent preset in Preferences → Browser; reloading a page confirms the new UA in `navigator.userAgent`.
  4. The internal tab bar shows favicon + truncated title; tooltip on hover shows the full URL.
**Plans**: TBD (expected: 2 plans).

Plans:
- [ ] 04-01: Padlock view + cert popover from `WKWebView.serverTrust`.
- [ ] 04-02: User-agent preference setting + tab-bar chrome polish.

### Phase 5: Bookmark Foundations
**Goal**: Persistent, project-scoped bookmarks with a sidebar section, star-button toolbar toggle, edit dialog, and full CRUD.
**Depends on**: Phase 1 (needs a working browser surface to bookmark from).
**Requirements**: BM-01, BM-02, BM-03, BM-04, BM-05, BM-06
**Success Criteria** (what must be TRUE):
  1. User taps the star in the browser toolbar; page appears in the sidebar "Unfiled" folder and star stays filled.
  2. User single-clicks a sidebar bookmark and it opens in the active browser tab; Cmd-click opens in a new tab.
  3. User can rename, edit URL, or reassign folder via the edit dialog; changes persist across app relaunch.
  4. User can delete a bookmark via context menu or the Delete key.
  5. Project-scoped bookmarks follow the selected project; the "Global" folder remains visible regardless of project.
**Plans**: TBD (expected: 3 plans — model, sidebar + star button, CRUD dialog).

Plans:
- [ ] 05-01: Define `BrowserBookmark` / `BrowserBookmarkFolder` @Model + schema bump 2→3.
- [ ] 05-02: Sidebar bookmark section + folder tree rendering.
- [ ] 05-03: Star-button toggle + edit dialog + delete flows.

### Phase 6: Bookmark Import
**Goal**: One-way, re-runnable bookmark import from Safari, Brave, Chrome, Firefox with folder-preview, dedupe, and TCC-aware Safari handling.
**Depends on**: Phase 5 (writes into `BrowserBookmark` model).
**Requirements**: BI-01, BI-02, BI-03, BI-04, BI-05, BI-06, BI-07
**Success Criteria** (what must be TRUE):
  1. User can open `File → Import Bookmarks…` and pick any of the four supported browsers; a sheet appears.
  2. Sheet shows a folder-tree preview + bookmark count; user can deselect folders before committing.
  3. Chrome / Brave import succeeds when installed, with a profile picker when multiple Chromium profiles exist.
  4. Firefox import succeeds even while Firefox is running (temp-copy `places.sqlite` avoids WAL lock).
  5. Safari import succeeds when Full Disk Access is granted; without FDA, a clear dialog explains how to grant it.
  6. Re-running an import on the same source does not create duplicate bookmarks (normalized-URL dedupe).
**Plans**: TBD (expected: 4 plans — one per importer, sheet shared).

Plans:
- [ ] 06-01: Import sheet + dedupe infrastructure.
- [ ] 06-02: Chromium (Chrome / Brave) importer.
- [ ] 06-03: Firefox SQLite importer.
- [ ] 06-04: Safari plist importer + FDA failure UX.

### Phase 7: Browsing History
**Goal**: Automatically record URL visits, offer a grouped history view, support clear actions, and surface history + bookmarks as URL-bar suggestions.
**Depends on**: Phase 5 (URL-bar suggestions merge history with bookmarks).
**Requirements**: BW-01, BW-02, BW-03, BW-04
**Success Criteria** (what must be TRUE):
  1. User visits pages and they appear in the history view grouped by Today / Yesterday / Past Week / Older.
  2. User types in the URL bar and sees combined history + bookmark suggestions (prefix match).
  3. User can clear history for last hour / last day / last week / all time.
  4. Private tabs (Phase 9) do not write history entries.
**Plans**: TBD (expected: 2 plans).

Plans:
- [ ] 07-01: `BrowsingHistoryEntry` @Model + navigation-delegate recording.
- [ ] 07-02: History view + URL-bar suggestion popover.

### Phase 8: Downloads
**Goal**: File downloads are intercepted, show progress, persist across restarts, and are manageable from a toolbar popover.
**Depends on**: Phase 1 (needs a browser surface); independent of 5–7.
**Requirements**: BD-01, BD-02, BD-03, BD-04, BD-05
**Success Criteria** (what must be TRUE):
  1. User clicks a file link and a download starts; progress appears in the downloads popover.
  2. User can cancel an in-progress download and the partial file is removed.
  3. User can "Show in Finder" / "Open" a completed download from the popover.
  4. Completed downloads persist across app restarts; in-flight downloads at crash time show as "Incomplete" after restart.
**Plans**: TBD (expected: 2 plans).

Plans:
- [ ] 08-01: `WKDownloadDelegate` + `BrowserDownloadRecord` @Model.
- [ ] 08-02: Downloads toolbar button + popover UI + Preferences default location.

### Phase 9: Private / Incognito Mode
**Goal**: First-class private-browsing tab surface with non-persistent data store, visual distinction, and history suppression.
**Depends on**: Phase 7 (history suppression logic shared with recording path).
**Requirements**: BP-01, BP-02, BP-03, BP-04
**Success Criteria** (what must be TRUE):
  1. `File → New Private Browser` (or `Cmd+Shift+Option+B`) opens a private browser tab with clear visual distinction (purple accent, "Private" label, glyph).
  2. Cookies / cache / auth do not persist between private sessions (login in private → close → new private → still logged out).
  3. Visits made inside a private tab do not appear in the history view.
  4. Explicit bookmarks created from a private tab are saved (and tagged "from private" where useful).
**Plans**: TBD (expected: 1 plan).

Plans:
- [ ] 09-01: Thread `isPrivate` through `BrowserSession` → `BrowserWebView.Coordinator`, set `nonPersistent()` data store, add visual distinctions and entry point.

### Phase 10: Unified Creation Pattern
**Goal**: Two — and only two — `+` menus exist in the app: the sidebar bottom-bar `+` and the Project Overview header `+`. Every per-section `…` / `+` / `Import…` affordance is removed. The blue `New` pill is replaced by a single `+` IconButton.
**Depends on**: Phases 1–9 (entire browser surface shipped; polish pass runs over real content).
**Requirements**: UIX-01, UIX-02, UIX-03, UIX-04, UIX-05
**Success Criteria** (what must be TRUE):
  1. User looking at a project sees exactly two `+` buttons on the main workspace: one at the sidebar bottom, one in the Project Overview header. No other `+`, `…`, or `Import…` buttons appear on section headers.
  2. User clicks the sidebar `+` and sees Scratch Pad, Browser, Bookmark (enabled only when a browser tab is focused), Terminal…, Location…, File…, Import Bookmarks….
  3. User clicks the overview `+` and sees the identical menu (same items, same order).
  4. User looking at the Project Overview no longer sees a blue `New` pill beside the project title; the `+` button sits in its place with consistent visual weight to the sidebar `+`.
  5. Existing keyboard shortcuts (File → New …, Cmd+Option+B, etc.) continue to work unchanged.
**Plans**: 2 plans.

Plans:
- [ ] 10-01-PLAN.md — Create `UnifiedAddMenu` shared view, wire into sidebar bottom-bar `+`, tab strip `+`, and Project Overview header (replacing blue `New` pill). Extend `NewBookmarkSheet` with optional prefill.
- [ ] 10-02-PLAN.md — Strip per-section chrome: Locations `...` (sidebar), Bookmarks `...` (sidebar), Bookmarks `Import…` + Locations `+` (overview cards). Audit `SidebarSectionHeader` accessory parameter.

### Phase 11: Hide-When-Empty + Bookmarks Nested Under Browsers
**Goal**: Sidebar and overview show only non-empty sections. Browser bookmarks live inside Browsers, not as a top-level peer. Discovery moves to the `+` menu.
**Depends on**: Phase 10 (unified `+` must exist before empty-state fallback rows are removed).
**Requirements**: UIX-10, UIX-11, UIX-12, UIX-13, UIX-14, UIX-15
**Success Criteria** (what must be TRUE):
  1. A fresh project with no content shows no Scratch Pads, Browsers, Bookmarks, or Locations sections in the sidebar — just the Overview row and the `+` bottom bar.
  2. A fresh project's Overview page shows a single centered empty state with a "Press + to add your first…" message; no empty section cards are rendered.
  3. Creating a first Browser tab makes the Browsers section appear in the sidebar; creating a first bookmark from that browser makes a `Bookmarks (n)` sub-section appear nested under Browsers — not as a top-level section.
  4. Deleting the last item in any section removes the section from the sidebar and overview on the next render tick.
  5. Project Overview's Bookmarks card is visually grouped with Browsers (either nested inside or stacked immediately below with shared chrome) and collapses/expands independently.
**Plans**: TBD (expected: 2 plans — (a) sidebar hide-when-empty + nesting, (b) overview hide-when-empty + card regrouping).

Plans:
- [ ] 11-01: Sidebar — hide-when-empty logic for Scratch Pads, Browsers, Locations; remove top-level `BookmarkSidebarSection`, inline it under `BrowserSessionsSection` as a collapsible child.
- [ ] 11-02: Project Overview — hide empty section cards; introduce project-level empty hero; regroup bookmarks card under browsers card.

### Phase 12: Section Parity & Polish
**Goal**: Remaining visual + interaction parity across section types — canonical header styling, Scratch Pad CRUD parity, and consistent expansion-state persistence.
**Depends on**: Phase 11 (section structure settled before visual normalization).
**Requirements**: UIX-20, UIX-21, UIX-22, UIX-23
**Success Criteria** (what must be TRUE):
  1. Every sidebar section header (Browsers, Bookmarks-within-Browsers, Locations, Scratch Pads, Orphaned Sessions) uses the same `SidebarSectionHeader` and looks pixel-identical (font, color, chevron, row height) across the four sections.
  2. User can rename a Scratch Pad row by pressing Return, and delete via Delete key or context menu — matching the Bookmarks row affordances already present in the codebase.
  3. Toggling collapse/expand on any section persists across app relaunch; all expansion-state keys follow the `sidebar.<section>.expanded` convention.
  4. No section ever renders both a header row AND an inline empty-state row simultaneously (contradicts UIX-10…13).
**Plans**: TBD (expected: 1 plan).

Plans:
- [ ] 12-01: Canonicalize `SidebarSectionHeader` usage; Scratch Pad row rename/delete; `@AppStorage` key audit; assert no residual empty-state rows survive.

## Progress

**Execution Order:**
Phases 1 → 9 execute in numeric order (browser core; already shipped per STATE.md). Phases 10 → 11 → 12 are the polish pass and execute strictly sequentially after 9. Phases 2, 3, 4, 8 are independent of each other and can be parallelized after Phase 1. Phase 6 requires Phase 5. Phase 9 requires Phase 7. Phase 11 requires Phase 10. Phase 12 requires Phase 11.

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Restore Entry Points | 0/1 | Not started | - |
| 2. Core Hardening | 0/2 | Not started | - |
| 3. Dev Tools Shortcuts | 0/1 | Not started | - |
| 4. Browser Chrome & Security | 0/2 | Not started | - |
| 5. Bookmark Foundations | 0/3 | Not started | - |
| 6. Bookmark Import | 0/4 | Not started | - |
| 7. Browsing History | 0/2 | Not started | - |
| 8. Downloads | 0/2 | Not started | - |
| 9. Private / Incognito Mode | 0/1 | Not started | - |
| 10. Unified Creation Pattern | 0/2 | Not started | - |
| 11. Hide-When-Empty + Bookmarks Nested | 0/2 | Not started | - |
| 12. Section Parity & Polish | 0/1 | Not started | - |
