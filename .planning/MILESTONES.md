# Milestones

Shipped milestones. Newest first.

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
