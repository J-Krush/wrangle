# Milestones

Shipped milestones. Newest first.

---

## v1.2 — "Browser Support"

**Shipped:** May 2026 (tag anchor: `10feb35 feat: version 1.2`; ship commit: `9539afe feat: browsers!`; subsequent landing-page tweaks through `3cea463 feat: add script for generating og image`).

### What shipped

- **Browser entry points restored** (Phase 1) — sidebar `+`, tab-strip `+`, File menu shortcut, BookmarkListView wired through `wrangleApp`.
- **Core hardening** (Phase 2) — `BrowserFindBar.swift`, `NewTabPage.swift`, `FaviconCache.swift`, tab keyboard shortcuts, HTTPS padlock, user-agent setting.
- **Dev tools shortcuts** (Phase 3) — Cmd+Opt+I/J/C toggles in-app DevToolsPanel via NSEvent local monitor inside `BrowserTabContentView`; right-click Inspect Element routes to Safari Web Inspector (`isInspectable=true`).
- **Browser chrome + security indicators** (Phase 4) — `PadlockView`, `BrowserUserAgent`, SSL/TLS cert popover, browser settings surface.
- **Bookmark foundations** (Phase 5) — new SwiftData `@Model`s (`BrowserBookmark`, `BrowserBookmarkFolder`), `BookmarkStore`, `StarButton`, `BookmarkSidebarSection`, `BookmarkEditSheet`. Star toggle in the toolbar.
- **Bookmark import** (Phase 6) — Safari (`Bookmarks.plist`, TCC-protected), Chromium-based (Chrome/Brave/Edge via JSON), Firefox (`places.sqlite`). One-way, re-runnable, with dedupe.
- **Browsing history** (Phase 7) — `BrowsingHistoryEntry` @Model, `HistoryStore`, `HistoryView` (grouped by day), `URLSuggestionPopover` for URL-bar autocomplete, clear-all and clear-by-range actions.
- **Downloads** (Phase 8) — `BrowserDownloadRecord` @Model, `DownloadManager` (WKDownloadDelegate), `DownloadsPopover` with progress, persistence across launches.
- **Private / incognito mode** (Phase 9) — `isPrivate` flag on `BrowserSession`, `WKWebsiteDataStore.nonPersistent()` per private session, history suppression, visual distinction.
- **SwiftData schema bump 2→3** — four new @Models land in a single additive/lightweight migration. Schema-version check wipes the store on first launch of v1.2 (established migration strategy).
- **UIX polish (Phases 10–11)** — unified `+` creation menus via `UnifiedAddMenu` (sidebar + tab-strip + Project Overview), per-section creation chrome stripped from headers, sidebar hide-when-empty + Bookmarks nested under Browsers, overview empty-hero + nested Bookmarks card.
- **UIX polish (Phase 12 — partial, with planned design pivot)** — count badges on overview cards via extended `SidebarSectionHeader` + `CollapsibleVStackSection`, Scratch Pad delete moves to Trash via `NSWorkspace.shared.recycle()` (not unlink), keyboard Delete confirmation alert on Scratch Pad + Bookmark rows, hide-when-empty + storage-key conventions documented in `CLAUDE.md`. **Mid-phase the sidebar pivoted to static section headers** (no chevron, no expansion state) — `f8e4a8a refactor(12-01): static sidebar headers, reorder, always-on book icon`. This superseded UIX-20's collapsible-with-persisted-state spec and made `SidebarStorageKeys.swift` redundant (created then removed). Final result: simpler sidebar, all functional intent of UIX-20/21/22/23 satisfied by a different design.

### Commits (anchor → freeze)

```
3cea463 feat: add script for generating og image
10feb35 feat: version 1.2
9539afe feat: browsers!
f8e4a8a refactor(12-01): static sidebar headers, reorder, always-on book icon
ea8f2a2 fix(12-01): StarButton tracks external bookmark changes via @Query
8c71f87 feat(12-01): Remove All bookmarks + scope new terminal locations to project
b88a4e8 refactor(12-01): replace nested Bookmarks with book-icon popover accessory
c550f68 fix(12-01): stop silent hard-delete on Trash failure; document conventions
8d7055a feat(12-01): symmetric keyboard parity for Scratch Pad + Bookmark rows
dd4ac4c feat(12-01): rewire overview cards to canonical header + storage keys
76d798d feat(12-01): rewire sidebar sections to canonical header + storage keys
e8f19ce feat(12-01): extend SidebarSectionHeader + CollapsibleVStackSection with optional count
19796bf docs(11-02): complete Project Overview hide-when-empty + nested Bookmarks plan
fab8568 refactor(11-01): hide empty sidebar sections + nest Bookmarks under Browsers
```

(Phases 1–9 ship commits collapsed into `9539afe feat: browsers!` and the preceding work tree.)

### Requirements validated

All v1.2 categories — BR, BH, DT, BX, BM, BI, BW, BD, BP, UIX-01…23 — moved to PROJECT.md Validated section. UIX-20/21/22 are recorded as validated despite the design pivot: the *functional intent* (parity, keyboard affordances, drift prevention) is satisfied by the static-sidebar simplification; the *originally-specified mechanism* (collapsible + persisted state + storage-key constants) was deemed unnecessary mid-flight.

### Known carry-over into v1.3

- **Trial / paywall surface is still wired** — `LicenseGateView` (ContentView.swift:203), `TrialBannerView` (ContentView.swift:43), `LicenseManager` owned by `AppCoordinator`. v1.3 strips all of it as part of the open-source release.
- **Pricing endpoint hardcoded** — `https://wrangleapp.dev/api/trial/{activate,validate}` + LemonSqueezy stub references in `LicenseManager.swift`. Deleted in v1.3.
- **Phase 12 leftovers** — `SidebarStorageKeys.swift` / `OverviewStorageKeys.swift` were planned, created, then removed; the 6 overview `@AppStorage` literals remain inline. Not scoped into v1.3 (functional intent satisfied; would only be a cosmetic refactor).
- **Multi-window NSEvent monitors** — process-scoped; filtered by session ID so behavior is correct but more monitors fire than necessary. Noted in v1.2 STATE.md "Blockers/Concerns"; no v1.3 work planned.

---

## v1.1.0 — "Bigger IDE"

**Shipped:** April 2026 (tag anchor: `ed91132 feat: version 1.1.0`; subsequent polish commits through `b293faf`).
**Marketing version at freeze:** 1.1.1 (bug-fix bump from 1.1.0).

### What shipped

- **Project structure** — renamed from "Room" to "Project" as the top-level container above Locations. Settled `@Model Project`, per-project scoping for tabs, bookmarks, terminals, todos.
- **Room/project browser sessions** — `Browser/` stack landed (WKWebView, multi-tab sessions, DevTools panel) but entry-point buttons intentionally gated pending UX polish. Feeds directly into v1.2.
- **Bigger-IDE posture** — density pass across sidebar, tab strip, status bars; `.sidebarRowSize(.small)`, Xcode-style row heights, tightened padding.
- **Todos** — per-project todo list with SwiftData `@Model TodoItem`, sidebar surface.
- **System metrics titlebar accessory** — optional CPU/RAM/disk glyphs in the titlebar.
- **Session context bar** — shows active intent/location context across the workspace.
- **What's New modal** — version-bump changelog via `WhatsNewChangelog.swift`.
- **Back/forward routing** + navigation history stack for project switching.
- **License, update-check, trial-handling plumbing** — launch-readiness work from the v1.0.x → v1.1.0 line.

### Commits (anchor → freeze)

```
b293faf refactor: sidebar spacing, md table spacing, button alignment
bd6089e fix: todos not showing up
53d2154 Merge pull request #1 from J-Krush/bigger-ide
b90d2f2 fix: whats new modal
ed91132 feat: version 1.1.0
7684e32 refactor: project overview page and back/forward routing
f0963e6 feat: restore system metrics titlebar accessory and settings toggle
d892ebd feat: bigger-ide features without timeline/engine
4dcc15b feat: room switcher with browsers
```

### Requirements validated

See `.planning/PROJECT.md` Validated section. Inferred from shipped code — no formal REQ-IDs existed pre-v1.2, so v1.0/v1.1 capabilities were back-filled into PROJECT.md at v1.2 kickoff.

### Known carry-over into v1.2

- Browser stack is fully implemented but entry points (sidebar `+`, tab-strip `+`) were commented out awaiting UX + hardening. v1.2 re-exposes and extends.
- Sidebar will grow to accommodate bookmarks / history / downloads sections — density work from v1.1 needs to extend to new sections.

---

## v1.0.x — Pre-planning baseline

**Shipped:** prior to 2026-04. No GSD artifacts captured at the time; v1.0 capabilities are inferred into PROJECT.md Validated section.

### What shipped (summary)

- Native macOS markdown editor (NSTextView + SwiftUI wrapper).
- AI-specific file recognition (`CLAUDE.md`, `SKILL.md`, `AGENTS.md`, system-prompt files).
- XML-tag awareness and token counting.
- Multi-tab workspace with `TabContent` enum (document / terminal / browser scaffolding / project overview).
- Embedded terminal via SwiftTerm.
- Claude Code + Gemini Code session launchers.
- Bookmarked-directory model with security-scoped access.
- SwiftUI `NavigationSplitView` workspace layout.

Capabilities rolled into v1.0 spanned multiple release commits (e.g. `dc367ca release: 1.0.8`, `d5171ee release: v1.0.7`, `de466f6 feat: license stuff, check for updates`, etc.).
