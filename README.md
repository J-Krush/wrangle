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
| `scripts/polish-screenshot.py` | Add rounded corners and optional notification overlay to a screenshot |
| `scripts/polish-all-screenshots.sh` | Batch process all `screenshots/raw/*.png` into polished marketing images |
| `scripts/polish-video.sh` | Post-process raw screen recordings into polished MP4 + GIF with gradient background |

### Marketing Screenshots

#### Prerequisites

```bash
pip3 install Pillow
```

#### Window setup

Set the app window to a consistent size before capturing (~1200×750pt produces good @2x images):

```applescript
tell application "System Events"
    set frontmost of process "Wrangle" to true
    tell process "Wrangle"
        set position of window 1 to {100, 100}
        set size of window 1 to {1200, 750}
    end tell
end tell
```

Find the window ID with `GetWindowID` or:

```bash
osascript -e 'tell app "Wrangle" to id of window 1'
```

#### Capture

```bash
# -l <windowID> captures specific window; -o suppresses system shadow
screencapture -l <windowID> -o screenshots/raw/shot-name.png
```

#### Shot list

| # | Filename | Stage in app | Key feature |
|---|----------|-------------|-------------|
| 1 | `editor-markdown.png` | Open a CLAUDE.md with headings, code blocks, lists | Inline markdown rendering |
| 2 | `editor-xml.png` | Open a system prompt with `<tools>` / `<instructions>` tags | XML-in-markdown highlighting |
| 3 | `terminal.png` | Terminal panel open running a Claude Code session | Embedded terminal |
| 4 | `fuzzy-finder.png` | Cmd+P open with partial filename typed | Fuzzy finder overlay |
| 5 | `file-tree.png` | Sidebar expanded with bookmarked projects, AI file icons visible | File tree + AI file recognition |
| 6 | `notification.png` | Editor with a notification banner composited | Notification overlay (polish step) |

#### Polish a single screenshot

```bash
python3 scripts/polish-screenshot.py <input> <output> [options]
```

| Option | Default | Description |
|--------|---------|-------------|
| `--radius N` | `24` | Corner radius in px |
| `--notification` | off | Add macOS notification banner overlay |
| `--notification-title TEXT` | `Wrangle` | Notification title |
| `--notification-body TEXT` | *(empty)* | Notification body text |
| `--notification-icon PATH` | auto-detect | Icon PNG (falls back to `Assets.xcassets/AppIcon`) |

```bash
# Basic — rounded corners only
python3 scripts/polish-screenshot.py screenshots/raw/editor-markdown.png screenshots/polished/editor-markdown.png

# With notification banner
python3 scripts/polish-screenshot.py screenshots/raw/editor-markdown.png screenshots/polished/notification.png \
    --notification --notification-body "New version available"
```

Output is PNG with transparent corners (RGBA), same dimensions as input.

#### Batch processing

```bash
# Process all screenshots/raw/*.png → screenshots/polished/
./scripts/polish-all-screenshots.sh

# Custom radius
./scripts/polish-all-screenshots.sh --radius 16
```

### Marketing Videos

#### Prerequisites

```bash
brew install ffmpeg
pip3 install Pillow
```

#### Recording

```bash
# Record window to .mov — press Ctrl+C to stop
screencapture -v -l <windowID> recordings/raw/feature-name.mov
```

#### Shot list

| # | Filename | Duration | What to show |
|---|----------|----------|-------------|
| 1 | `inline-editing.mov` | 15–20s | Type markdown, watch headings/code blocks render inline |
| 2 | `xml-highlighting.mov` | 10–15s | Scroll through a prompt file with XML tags expanding/collapsing |
| 3 | `terminal-session.mov` | 15–20s | Open terminal panel, run a command or Claude Code session |
| 4 | `fuzzy-finder.mov` | 8–12s | Cmd+P, type partial name, open file |
| 5 | `file-navigation.mov` | 10–15s | Browse file tree, open different AI file types, show icons |
| 6 | `full-workflow.mov` | 25–30s | End-to-end: open project, edit prompt, run in terminal |

#### Polish command

```bash
./scripts/polish-video.sh <input.mov> <output-basename> [options]
```

| Option | Default | Values | Description |
|--------|---------|--------|-------------|
| `--size` | `hero` | `hero` (2560×1600), `blog` (1920×1200), `social` (1280×800), `all` | Canvas size preset |
| `--gradient` | `dark` | `dark`, `subtle`, `deep` | Background gradient style |
| `--format` | `both` | `mp4`, `gif`, `both` | Output format |
| `--radius` | `20` | integer | Corner radius in px |
| `--fps` | `15` | integer | GIF framerate |
| `--no-shadow` | *(shadow on)* | flag | Disable drop shadow |
| `--quality` | `18` | 0–51 | H.264 CRF (lower = better quality, bigger file) |

```bash
# Default — hero size, dark gradient, MP4 + GIF
./scripts/polish-video.sh recordings/raw/inline-editing.mov videos/polished/inline-editing

# Social-optimized GIF only
./scripts/polish-video.sh recordings/raw/fuzzy-finder.mov videos/polished/fuzzy-finder \
    --size social --format gif --fps 12

# All sizes at once
./scripts/polish-video.sh recordings/raw/full-workflow.mov videos/polished/full-workflow \
    --size all --gradient deep
```

#### Output notes

- **MP4** — Use for website hero, Twitter/X. Expect 2–8 MB for 15–20s clips at hero size.
- **GIF** — Use for README badges, docs, GitHub PR descriptions. Expect 5–20 MB depending on duration/complexity.
- `--size all` outputs `<basename>-hero.mp4`, `<basename>-blog.mp4`, `<basename>-social.mp4` (and GIFs).

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
- Product ID `8860d1f0-c122-4ab6-8528-ee727d3065e3` is configured in `astro.config.mjs` (`/buy` redirect) and in `LicenseGateView.swift`

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

## Dev & Internal Builds

### Debug builds (Xcode)

The license gate is automatically bypassed in Debug builds. Just hit Cmd+R — no license key needed.

### Signed builds for colleagues

For Release/Archive builds shared with colleagues, enter this key in the activation screen:

```
WRANGLE-DEV-PREVIEW
```

This activates the app locally without calling the LemonSqueezy API. Share this key privately with trusted colleagues. If it leaks, update the `devBypassKey` constant in `LicenseManager.swift` and distribute a new build.

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
