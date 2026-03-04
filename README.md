# Wrangle

A native macOS markdown editor purpose-built for developers working with AI agents, skills, system prompts, and configuration files.

## Overview

Wrangle brings Typora-style inline rendering to AI development workflows. Instead of a split preview pane, markdown is rendered in-place as you type — headings scale up, code blocks get highlighted, and XML tags are color-coded — while the underlying file stays plain `.md` on disk. It's a file editor, not a note-taking app.

Built for developers who spend their day in `CLAUDE.md`, `SKILL.md`, system prompts, and MCP configs, Wrangle understands these file patterns natively and provides an embedded terminal so you can stay in one window.

## Key Features

- **Inline markdown rendering** — Rich formatting displayed as you type, raw syntax revealed at the cursor
- **XML-in-markdown highlighting** — First-class rendering for `<tools>`, `<instructions>`, and other XML tags common in AI prompts
- **Embedded terminal** — Full terminal via SwiftTerm, launch shells or Claude Code sessions without leaving the editor
- **Token counting** — Approximate token counts in the status bar for prompt files
- **Fuzzy finder** — `Cmd+P` to quickly open any file across all bookmarked projects
- **File tree with bookmarks** — Bookmark directories for fast access with security-scoped persistence
- **AI file recognition** — Distinct icons and behavior for `CLAUDE.md`, `SKILL.md`, `AGENTS.md`, and system prompt files

## Getting Started

### Prerequisites

- macOS 14.0+ (Sonoma)
- Xcode 16+
- Apple Silicon (native target)

### Build & Run

```bash
git clone <repo-url>
open Wrangle.xcodeproj
# Build & Run with Cmd+R
```

Dependencies (SwiftTerm) are resolved automatically via Swift Package Manager on first build.

> **Note:** The App Sandbox entitlement is disabled. This is required for the embedded terminal to launch child processes.

## Project Structure

```
Wrangle/
├── App/              # App entry point, global state, main layout
├── Editor/           # NSTextView-based markdown editor, parser, tab strip
├── Sidebar/          # File tree, bookmarks, terminal list
├── Terminal/          # SwiftTerm integration, session management
├── Features/         # Fuzzy finder, global search, external editor launch
├── Models/           # SwiftData models (bookmarks, recents, tabs)
├── Utilities/        # Theme, file watcher, security-scoped bookmarks
└── Resources/        # Asset catalog
```

## Scripts

All scripts live in `scripts/` and should be run from the project root.

| Script | Purpose |
|--------|---------|
| `scripts/bump-version.sh <version>` | Update version number across all files (Xcode project, landing page, version API) |
| `scripts/build-release.sh` | Archive, code sign, notarize, and staple the app |
| `scripts/create-dmg.sh` | Package the stapled app into a notarized DMG installer |
| `scripts/polish-screenshot.py` | Add gradient background, rounded corners, and shadow to a screenshot |
| `scripts/polish-all-screenshots.sh` | Batch process all `screenshots/raw/*.png` into polished marketing images |
| `scripts/polish-video.sh` | Post-process raw screen recordings into polished MP4 + GIF |

---

## Release Guide

### One-Time Setup (done once per machine)

These steps only need to happen once before the first release.

**1. Install Developer ID certificate**

- Go to [developer.apple.com](https://developer.apple.com) > Certificates
- Create a **"Developer ID Application"** certificate
- Download and double-click to install into Keychain

**2. Store notary credentials in Keychain**

Generate an app-specific password at [appleid.apple.com](https://appleid.apple.com), then:

```bash
xcrun notarytool store-credentials "wrangle-notary" \
  --apple-id YOUR_APPLE_ID \
  --team-id 3DEKQ7GUK6 \
  --password APP_SPECIFIC_PASSWORD
```

**3. Create `ExportOptions.plist`**

Already committed to the repo root. Contains:
- `method`: `developer-id`
- `teamID`: `3DEKQ7GUK6`
- `signingStyle`: `automatic`

**4. Install `create-dmg` (optional, for pretty DMGs)**

```bash
brew install create-dmg
```

Falls back to `hdiutil` if not installed, but the Homebrew version produces a nicer installer window.

**5. Set up Cloudflare R2 bucket**

- Create an R2 bucket for hosting DMGs
- Configure DNS CNAME so `dl.wrangeapp.dev` points to the R2 bucket
- Install `wrangler` CLI if you want to upload via command line

**6. Set up LemonSqueezy**

- Create store and product at [lemonsqueezy.com](https://www.lemonsqueezy.com)
- Product ID `866499` is configured in `astro.config.mjs` (`/buy` redirect) and in `LicenseGateView.swift`

**7. Deploy landing page**

- Landing page lives in `../Landing Page/` (Astro + Tailwind)
- Hosted at `wrangleapp.dev`
- Serves the version API at `/api/version.json` (used by the in-app update checker)

---

### Releasing a New Version

Run these steps in order every time you ship an update.

**Step 1 — Bump the version**

```bash
./scripts/bump-version.sh 1.0.6
```

This updates all 9 places across 3 files:
- `wrangle.xcodeproj/project.pbxproj` — `MARKETING_VERSION` (x2) + `CURRENT_PROJECT_VERSION` auto-incremented (x2)
- `../Landing Page/src/pages/index.astro` — DMG download links (x3)
- `../Landing Page/public/api/version.json` — `version` + `download_url`

**Step 2 — Commit the version bump**

```bash
git add wrangle.xcodeproj/project.pbxproj
git add "../Landing Page/src/pages/index.astro"
git add "../Landing Page/public/api/version.json"
git commit -m "chore: bump version to 1.0.6"
```

**Step 3 — Build, sign, and notarize the app**

```bash
./scripts/build-release.sh
```

This archives the Xcode project, exports with Developer ID signing, submits to Apple for notarization, staples the ticket, and verifies with `spctl`. Output: `build/export/Wrangle.app`

**Step 4 — Create the DMG**

```bash
./scripts/create-dmg.sh
```

Packages the stapled app into a DMG with an Applications symlink, notarizes the DMG itself, and staples it. Output: `build/Wrangle-1.0.6.dmg`

**Step 5 — Upload DMG to Cloudflare R2**

```bash
# Via wrangler CLI:
wrangler r2 object put wrangle-downloads/Wrangle-1.0.6.dmg --file build/Wrangle-1.0.6.dmg

# Or upload manually via the Cloudflare dashboard
```

The DMG should be accessible at `https://dl.wrangeapp.dev/Wrangle-1.0.6.dmg`.

**Step 6 — Deploy the landing page**

```bash
cd "../Landing Page"
pnpm build
# Deploy to hosting (push to deploy branch, or upload dist/)
```

This publishes the updated download links and `version.json` so the in-app update checker picks up the new version.

**Step 7 — Verify everything**

- [ ] `https://wrangleapp.dev` loads correctly
- [ ] `https://wrangleapp.dev/buy` redirects to LemonSqueezy checkout
- [ ] `https://dl.wrangeapp.dev/Wrangle-1.0.6.dmg` downloads the DMG
- [ ] `https://wrangleapp.dev/api/version.json` returns the new version
- [ ] DMG mounts, app drags to Applications, launches correctly
- [ ] In-app update checker detects the new version (test from an older build)

**Step 8 — Tag the release**

```bash
git tag v1.0.6
git push origin main --tags
```

---

## Documentation

- [Architecture & Structure](docs/architecture.md)
- [Coding Patterns](docs/coding-patterns.md)
- [Pre-Launch Todo](docs/pre-launch-todo.md)

## Architecture

- **SwiftUI + NSTextView hybrid** — SwiftUI for layout and navigation, a custom `NSViewRepresentable` wrapping `NSTextView` for the editor core (full control over attributed string rendering, keyboard shortcuts, and cursor behavior)
- **MVVM with `@Observable`** — All view models use the `@Observable` macro with `@MainActor` isolation
- **SwiftData** — Persistence for bookmarks, recent files, and preferences
- **Swift concurrency** — `async/await` throughout, task-based debouncing, no GCD unless required by system APIs
