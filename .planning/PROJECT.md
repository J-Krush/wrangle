# Wrangle

## What This Is

Wrangle is a native macOS markdown editor purpose-built for developers working with AI agents, skills, system prompts, and configuration files. It treats the file patterns unique to AI development — `CLAUDE.md`, `SKILL.md`, `AGENTS.md`, system prompts, MCP configs — as first-class citizens, with rich rendered editing, XML-tag awareness, and live token counting. Think "Typora meets AI development."

## Core Value

Every surface — editor, terminal, file tree, browser — serves a developer driving AI agents. Speed, density, and AI-file awareness win over breadth of consumer features.

## Current Milestone: v1.3 Open Source Release

**Goal:** Convert Wrangle from a paid trial-gated macOS app into a free, MIT-licensed open-source project shipped as a portfolio piece — strip the commercial surface from the app, rewrite the landing page for OSS positioning, and stand up both the app repo (`J-Krush/wrangle`) and landing-page repo (`J-Krush/wrangle-landing`) as public GitHub repositories that tell the product's story (Product Hunt launch, Reddit ads, native-for-AI-devs thesis).

**Target features:**
- **App de-commercialization:** delete `LicenseManager`, `LicenseGateView`, `TrialBannerView`, `LicenseSettingsView`, `scripts/reset-license.sh`, the `wrangleapp.dev/api/trial/*` endpoints, and all license/trial plumbing in `AppCoordinator` / `ContentView` / `wrangleApp`. Replace the `LicenseGateView` + `TrialBannerView` surfaces with a one-time "Wrangle is now free and open source — star us on GitHub" What's-New-style note (dismissable, removable in a later release).
- **Signed-DMG release pipeline:** local build + sign + notarize workflow producing a DMG that gets manually attached to a tagged GitHub Release. No GitHub Actions automation this milestone (deferred to v1.4).
- **App repo OSS surface (`J-Krush/wrangle`):** `LICENSE` (MIT), `README.md` telling the product story (Wrangle's positioning as native macOS markdown for AI developers, the PH launch, the Reddit-ads channel experiment, why it's now free and open source), `CONTRIBUTING.md`, GitHub issue + PR templates, screenshots / GIF, link to landing page.
- **Landing-page repo OSS surface (`J-Krush/wrangle-landing`):** strip any private analytics keys or internal notes, add `LICENSE` (MIT), update `README.md` to be public-facing.
- **Landing page repositioning:** existing Astro site at `Landing Page/` reframes from "Buy Wrangle for $24" → "Free + open source macOS markdown editor for AI devs." New CTA, story section, GitHub link, DMG download link to the GitHub Release. Pricing page either removed or rewritten.
- **Public flip:** both GitHub repos go from private to public as the final milestone step, only after all of the above has been built and reviewed in private.

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
- ✓ **BR-01…04** — Browser entry points restored (sidebar `+`, tab-strip `+`, File menu shortcut, BookmarkListView). — v1.2 Phase 1
- ✓ **BH-01…06** — Core hardening: find-in-page (`BrowserFindBar`), tab shortcuts, favicon cache, New Tab page, HTTPS padlock, user-agent setting. — v1.2 Phase 2
- ✓ **DT-01…04** — Dev-tools keyboard shortcuts (Cmd+Opt+I/J/C) and right-click Inspect Element. — v1.2 Phase 3
- ✓ **BX-01…04** — Browser chrome + security indicators (padlock, cert popover, user-agent settings). — v1.2 Phase 4
- ✓ **BM-01…06** — Bookmark foundations (`BrowserBookmark`/`BrowserBookmarkFolder` @Models, `BookmarkStore`, star button, sidebar section, CRUD, project-scoped). — v1.2 Phase 5
- ✓ **BI-01…07** — Bookmark import from Safari/Brave/Chrome/Firefox (one-way, re-runnable, TCC-aware). — v1.2 Phase 6
- ✓ **BW-01…04** — Browsing history (auto-record, grouped view, clear actions, URL-bar suggestions). — v1.2 Phase 7
- ✓ **BD-01…05** — Downloads (`WKDownloadDelegate`, progress popover, SwiftData persistence). — v1.2 Phase 8
- ✓ **BP-01…04** — Private / incognito tabs (`WKWebsiteDataStore.nonPersistent()`, visual distinction, history suppression). — v1.2 Phase 9
- ✓ **UIX-01…19** — Pre-release polish: unified `+` menus, hide-when-empty sections, bookmarks nested under Browsers. — v1.2 Phases 10–11
- ✓ **UIX-20…23** — Section parity & polish: count badges on overview cards, Scratch Pad → Trash (`NSWorkspace.recycle`), keyboard Delete confirmation alert on Scratch Pads + Bookmarks, hide-when-empty regression guard documented in CLAUDE.md. Sidebar headers pivoted to **static (always-rendered, no chevron / no expansion state)** mid-phase — superseding the original UIX-20 collapsible-with-persisted-state spec; `SidebarStorageKeys.swift` constants were created then removed because there was no expansion state left to centralize. — v1.2 Phase 12

### Active

v1.3 Open Source Release — requirements detailed in `.planning/REQUIREMENTS.md`. Summary:

- [ ] **OSS-App** — Strip `LicenseManager`, `LicenseGateView`, `TrialBannerView`, `LicenseSettingsView`, `scripts/reset-license.sh`, plumbing in `AppCoordinator`/`ContentView`/`wrangleApp`; replace gated surface with "now free + open source" one-time note.
- [ ] **OSS-Rel** — Local-build signed-DMG → tagged GitHub Release workflow (manual upload). GitHub Actions automation deferred to v1.4.
- [x] **OSS-Repo** — `J-Krush/wrangle` repo OSS surface: `LICENSE` (MIT), story-driven `README.md` (PH launch, Reddit ads, native-for-AI-devs thesis), `CONTRIBUTING.md`, issue + PR templates, screenshots/GIF. — Validated in Phase 14 (REPO-01..REPO-12 all complete; secrets sweep option-2 rotate-and-document; 12/12 must-haves verified).
- [ ] **OSS-Landing-Repo** — `J-Krush/wrangle-landing` repo OSS surface: secrets sweep, `LICENSE` (MIT), public-facing `README.md`.
- [ ] **OSS-Site** — Astro landing page repositioned from "Buy $24" → "Free + open source"; new CTA, story section, GitHub link, DMG download link to GitHub Release; pricing page removed or rewritten.
- [ ] **OSS-Flip** — Final step: flip both repos from private to public.

### Out of Scope

- **Bidirectional browser sync** — not feasible without in-browser extensions in Safari/Chrome/etc. Import is one-way and re-runnable.
- **HTML-export fallback for Safari import** — decided to read `~/Library/Safari/Bookmarks.plist` directly, guarded by macOS Full Disk Access TCC prompt. Avoids dual-path UI.
- **iOS / iPadOS** — macOS 15+ (Sequoia) only. Apple Silicon primary target.
- **Document-based app template** — we manage files ourselves; `NSDocument` not used.
- **Browser extensions (WebExtension API)** — WKWebView doesn't support this; not a developer-workflow priority.
- **Multi-account / cross-device sync for bookmarks** — local SwiftData only for v1.2.
- **GitHub Actions release automation** — deferred to v1.4. v1.3 ships signed DMGs via local build + manual upload to GitHub Releases. Reason: keep v1.3 scope tight and prioritize the public flip over CI ceremony.
- **Sponsorship / donation surface** — v1.3 replaces the "Buy $24" CTA with a plain "star us on GitHub" note; no GitHub Sponsors / Buy Me a Coffee in this milestone. Can be added later if there's signal it matters.
- **Migrating existing paid customers** — license-key flow is being torn out wholesale. There is no migration path because there is no remaining licensing surface. If anyone holds a license, the v1.3 build simply opens to the editor.
- **Renaming the project / repo / bundle ID** — "Wrangle" name stays. Bundle ID stays. Repo names (`wrangle`, `wrangle-landing`) stay.
- **Source-available / dual-license schemes** — MIT picked deliberately; no BSL/AGPL/Elastic gating.

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
| Private tabs use `WKWebsiteDataStore.nonPersistent()` per session | Canonical Apple pattern for incognito. Requires `isPrivate` flag threaded through `BrowserSession` → `BrowserWebView.Coordinator.getOrCreateWebView`. | ✓ Validated (v1.2 Phase 9) |
| Phase 12 sidebar pivot: static section headers (no chevron / no expansion state) supersede the planned collapsible-with-persisted-state UIX-20 contract | User preference for density and zero-friction surfaced mid-execution; collapsing a sidebar section that's always sparse was friction the spec didn't account for. `SidebarStorageKeys.swift` constants got reverted as a result (nothing left to centralize). | ✓ Validated (v1.2 Phase 12) |
| Wrangle goes open source under MIT for v1.3 (portfolio piece, not revenue play) | Recognizable, professional, zero friction for contributors and recruiters. Niche macOS-AI-dev audience makes the "someone forks and commercializes" risk vanishingly small. Goal is signal, not protection. | — Pending |
| Strip the commercial surface wholesale (no migration path for paid users) | Trial enforcement *was* live in v1.2 (`LicenseGateView` at `ContentView.swift:203`, `TrialBannerView` at `:43`); making it conditional would mean carrying dead code. Cleaner to delete and ship a free build. | — Pending |
| Both `J-Krush/wrangle` + `J-Krush/wrangle-landing` flip public at milestone end, not earlier | Lower stakes if something needs to be yanked; cleaner narrative for the PH/Reddit retrospective; lets the README + LICENSE + CONTRIBUTING land before the world sees the repo. | — Pending |
| Signed-DMG release pipeline: local build + manual upload (no GitHub Actions this milestone) | GH Actions signing/notarization is ~1 day of work and not on the critical path for a public launch. Manual local builds produce the same signed binary; defer automation to v1.4. | — Pending |

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

*Last updated: 2026-05-20 — Phase 14 (App Repo OSS Surface) complete: LICENSE + README rewrite + CONTRIBUTING + SECURITY + .github/ templates + .gitignore + secrets-sweep documented. REPO-01..REPO-12 satisfied.*
