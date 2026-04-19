# Wrangle

## What This Is

Wrangle is a native macOS markdown editor purpose-built for developers working with AI agents, skills, system prompts, and configuration files. It treats the file patterns unique to AI development — `CLAUDE.md`, `SKILL.md`, `AGENTS.md`, system prompts, MCP configs — as first-class citizens, with rich rendered editing, XML-tag awareness, and live token counting. Think "Typora meets AI development."

## Core Value

Every surface — editor, terminal, file tree, browser — serves a developer driving AI agents. Speed, density, and AI-file awareness win over breadth of consumer features.

## Current Milestone: v1.2 Browser Support

**Goal:** Re-expose the embedded browser and make it a first-class, developer-friendly browser surface — bookmarks, cross-browser import, browsing history, downloads, private mode, security indicators, and standard dev-tools keyboard shortcuts.

**Target features:**
- Restore "New Browser" entry points in every relevant `+` / "new" menu.
- Harden the existing WKWebView wrapper: find-in-page, tab shortcuts, favicon cache, New Tab page, HTTPS padlock, user-agent setting.
- Bookmark storage + sidebar UI (SwiftData) with star-button toggle in the browser toolbar.
- One-way, re-runnable bookmark import from Safari, Brave, Chrome, Firefox.
- Browsing history with grouped view, clear actions, and URL-bar suggestions.
- Downloads with `WKDownloadDelegate`, progress popover, and persistence.
- Private / incognito tabs using `WKWebsiteDataStore.nonPersistent()`.
- Dev-tools keyboard shortcuts (Cmd+Option+I/J/C) targeting the in-app panel.
- **Pre-release UX polish pass (Phases 10–12):** collapse scattered creation affordances into two unified `+` menus (sidebar + overview); hide empty sections; nest browser bookmarks under Browsers; normalize section-header chrome.

## Requirements

### Validated

Inferred from shipped v1.0 → v1.1 code; these are the capabilities the app already delivers and relies on.

- ✓ **EDIT-01** — NSTextView-based markdown editor with rich rendered view (EditorDocument + custom NSViewRepresentable). — v1.0
- ✓ **EDIT-02** — XML-tag awareness: `<tools>`, `<instructions>`, `<system>` highlighted and collapsible. — v1.0
- ✓ **EDIT-03** — Token count always visible in status bar. — v1.0
- ✓ **FILE-01** — AI-specific file recognition: `CLAUDE.md`, `.claude.md`, `SKILL.md`, `AGENTS.md`, system prompt files get distinct icons via `FileType` enum. — v1.0
- ✓ **FILE-02** — Native file open/save via `NSOpenPanel` / `NSSavePanel` with security-scoped bookmarks (`SecurityScopedBookmark.swift`). — v1.0
- ✓ **TERM-01** — Embedded terminal via SwiftTerm's `LocalProcessTerminalView`. — v1.0
- ✓ **TERM-02** — Multiple terminal sessions per workspace, per-project scoping. — v1.0
- ✓ **PROJ-01** — Project (formerly "Room") is the top-level container above Locations, stored via SwiftData `@Model Project`. — v1.0
- ✓ **PROJ-02** — Bookmarked directories (`BookmarkedDirectory` @Model) per project with security-scoped access. — v1.0
- ✓ **NAV-01** — `NavigationSplitView`-based workspace: sidebar (projects + locations + intents + todos + recent files) + tab-strip editor. — v1.0
- ✓ **NAV-02** — Multi-tab workspace with `TabContent` enum (document / terminal / browser / projectOverview). Per-project scoping of visible tabs. — v1.0
- ✓ **AI-01** — Claude Code and Gemini Code session launchers baked in (Cmd+Shift+` / Cmd+Shift+G). — v1.0
- ✓ **TODO-01** — Per-project todos (`TodoItem` @Model) surfaced in sidebar. — v1.1
- ✓ **UPD-01** — "What's New" modal on version bumps with changelog. — v1.1
- ✓ **DENSE-01** — File tree sidebar uses `.sidebarRowSize(.small)` for Xcode/VS Code density. — v1.1

### Active

v1.2 Browser Support — requirements detailed in `.planning/REQUIREMENTS.md`. Summary:

- [ ] **BR-01…04** — Browser restoration (uncomment entry points + File menu shortcut).
- [ ] **BH-01…06** — Core hardening (find-in-page, tab shortcuts, favicon cache, New Tab page).
- [ ] **DT-01…04** — Dev-tools keyboard shortcuts + right-click "Inspect Element".
- [ ] **BX-01…04** — Browser chrome & security indicators (padlock, cert popover, user-agent).
- [ ] **BM-01…06** — Bookmark foundations (star button, sidebar section, CRUD, project-scoped).
- [ ] **BI-01…07** — Bookmark import (Safari/Brave/Chrome/Firefox, dedupe, re-runnable).
- [ ] **BW-01…04** — Browsing history (auto-record, grouped view, clear actions, URL suggestions).
- [ ] **BD-01…05** — Downloads (WKDownloadDelegate, progress popover, persistence).
- [ ] **BP-01…04** — Private / incognito mode (non-persistent data store, visual distinction).
- [ ] **UIX-01…23** — Interaction polish pass: unified `+` menus, hide-when-empty sections, bookmarks nested under Browsers, section-header parity. (Phases 10–12.)

### Out of Scope

- **Bidirectional browser sync** — not feasible without in-browser extensions in Safari/Chrome/etc. Import is one-way and re-runnable.
- **HTML-export fallback for Safari import** — decided to read `~/Library/Safari/Bookmarks.plist` directly, guarded by macOS Full Disk Access TCC prompt. Avoids dual-path UI.
- **iOS / iPadOS** — macOS 15+ (Sequoia) only. Apple Silicon primary target.
- **Document-based app template** — we manage files ourselves; `NSDocument` not used.
- **Browser extensions (WebExtension API)** — WKWebView doesn't support this; not a developer-workflow priority.
- **Multi-account / cross-device sync for bookmarks** — local SwiftData only for v1.2.

## Context

- **Stack:** Swift 5.9+, SwiftUI, `@Observable` + `@MainActor`, SwiftData, WKWebView, SwiftTerm.
- **Platform:** macOS 15 (Sequoia) minimum. Apple Silicon primary. App **not sandboxed** (no `*.entitlements` in repo).
- **Editor core:** custom `NSTextView` via `NSViewRepresentable` + `NSAttributedString` — not `TextEditor`.
- **Architecture:** MVVM with `@Observable` classes (all `@MainActor`). DI via `@Environment(AppState.self)` and `@FocusedValue(\.appState)`.
- **Xcode structure:** `fileSystemSynchronizedRootGroup` — every `.swift` file in `Wrangle/` auto-compiles. No manual project-member-management per file.
- **Docs:** `CLAUDE.md`, `docs/architecture.md`, `docs/coding-patterns.md`, `docs/audit-report.md` authored before this milestone; `.planning/` is new as of v1.2.

## Constraints

- **Tech stack:** Swift 5.9+ / SwiftUI / macOS 15+. No UIKit. No AppDelegate. `SwiftUI.App` lifecycle only.
- **Compatibility:** No sandboxing today. If sandboxing is added later, `SecurityScopedBookmark.swift` is already sandbox-aware. Bookmark-import paths for Chrome/Firefox live under `~/Library/Application Support/...` (readable without TCC); Safari's `Bookmarks.plist` lives under `~/Library/Safari/` (TCC-protected even without sandbox — Full Disk Access required).
- **Performance:** Cache `NSRegularExpression` as `static let`. No sync file I/O on main thread. No `DispatchQueue.main.async` — use `MainActor.run` / `Task { @MainActor in }`.
- **UI:** `Button` over `onTapGesture`. `.clipShape()` over `.cornerRadius()`. Views under ~80 lines; extract subviews past that. `@State` must be `private`.
- **Memory (user preference):** instant state swaps, no slide/animated transitions for navigation. (See memory `feedback_no_slide_transitions.md`.)
- **Testing (user preference):** prioritize unit tests; plan for e2e/integration coverage. (See memory `feedback_testing_priority.md`.)

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Browser is re-enabled via uncommenting two buttons (not rewritten) | Full stack (`Browser/` + `DevTools/`) already compiles and is integrated into `TabContent`. Only entry points are gated. | — Pending (validated after Phase 1) |
| Bookmark-import model is one-way + re-runnable, never bidirectional | True sync requires browser extensions we aren't distributing. User confirmed the realistic scope. | — Pending |
| Safari import reads `Bookmarks.plist` directly (requires Full Disk Access) | User chose direct-read-only path. Matches Chrome/Firefox "import from Safari" UX. | — Pending |
| Bookmarks / history / downloads use SwiftData `@Model`, not UserDefaults | First-class user data with query, dedupe, project-scoping needs. `BrowserStateStore` UserDefaults pattern is for transient session state only. | — Pending |
| Keyboard-shortcut collision on `Cmd+[/]`: scope to focus | BH-04 wants browser-history nav on `Cmd+[/]`; global tab-nav currently uses those. `.focused`-scoped binding routes correctly. | ⚠️ Revisit — SwiftUI focus scoping can be fragile |
| Single SwiftData schema bump `2 → 3` for all new models | Four new `@Model` types (BrowserBookmark, BrowserBookmarkFolder, BrowsingHistoryEntry, BrowserDownloadRecord) land in one migration. Lightweight migration (additive only). | — Pending |
| Private tabs use `WKWebsiteDataStore.nonPersistent()` per session | Canonical Apple pattern for incognito. Requires `isPrivate` flag threaded through `BrowserSession` → `BrowserWebView.Coordinator.getOrCreateWebView`. | — Pending |

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `/gsd-transition`):
1. Requirements invalidated? → Move to Out of Scope with reason.
2. Requirements validated? → Move to Validated with phase reference.
3. New requirements emerged? → Add to Active.
4. Decisions to log? → Add to Key Decisions.
5. "What This Is" still accurate? → Update if drifted.

**After each milestone** (via `/gsd-complete-milestone`):
1. Full review of all sections.
2. Core Value check — still the right priority?
3. Audit Out of Scope — reasons still valid?
4. Update Context with current state.

---

*Last updated: 2026-04-19 — UIX polish phases (10–12) appended to v1.2*
