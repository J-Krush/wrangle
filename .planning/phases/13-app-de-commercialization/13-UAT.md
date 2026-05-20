---
status: complete
phase: 13-app-de-commercialization
source: [13-01-SUMMARY.md, 13-02-SUMMARY.md]
started: 2026-05-19T21:28:03Z
updated: 2026-05-20T00:00:00Z
---

## Current Test

[testing complete]

## Tests

### 1. Cold Start Smoke Test
expected: Quit any running Wrangle. From Xcode (or the Debug build artifact), launch the app from a cold start. App boots without crash or error dialog; the main editor window appears; no startup-time exception is logged to the console.
result: pass

### 2. Editor opens directly — no license gate or trial banner
expected: On first paint after launch, the editor opens immediately. No LicenseGateView modal blocks the window. No TrialBannerView strip appears at the top of the content area.
result: pass

### 3. Settings has no License tab
expected: Open Settings (Cmd+,). The Settings window shows only a "General" tab — no "License" tab is present in the toolbar.
result: pass

### 4. WhatsNew v1.3.0 modal appears on fresh launch
expected: On a fresh install (no prior `lastSeenVersion` in UserDefaults for `com.krush.wrangle`), launching shows the WhatsNew modal with a v1.3.0 entry titled around "Wrangle is now free and open source" and a "Star on GitHub" call-to-action button.
result: pass

### 5. Star on GitHub CTA opens browser, modal stays open
expected: With the WhatsNew modal showing, click the "Star on GitHub" CTA. Your default browser opens to `https://github.com/J-Krush/wrangle`. The Wrangle WhatsNew modal remains open in the app.
result: pass

### 6. Continue dismisses WhatsNew modal
expected: Click the "Continue" button in the WhatsNew modal. The modal closes and the editor is fully interactive.
result: pass

### 7. Relaunch — WhatsNew does not re-appear
expected: Quit and relaunch the app. The WhatsNew modal does NOT appear again — `lastSeenVersion` is now pinned to the current bundle version.
result: pass

### 8. About panel — dual links
expected: Open the About panel (Wrangle menu → About Wrangle). The credits show "Made by Krush" on one line, and on a second line both `wrangleapp.dev` and `github.com/J-Krush/wrangle` as clickable links separated by a bullet. Clicking each opens the respective URL in your browser.
result: issue
reported: "links work but I want them stacked vertically instead of horizontal with a bullet separator; also version shows v1.2.0 (5) instead of v1.3.0"
severity: major

### 9. Scratch Pad opens (regression check)
expected: File → New Scratch Pad (or Cmd+Shift+N). A new Scratch Pad opens normally — Phase 13's strip did not regress this flow.
result: pass
note: "User reported: works when a project is selected; no-op when no project selected (pre-existing design, not a Phase 13 regression)"

### 10. Browser tab opens (regression check)
expected: File → New Browser (or Cmd+Option+B). A new Browser tab opens normally — Phase 13's strip did not regress this flow.
result: pass

### 11. Check for Updates — manual command
expected: Wrangle menu → "Check for Updates...". Because the GitHub repo is not yet public (until Phase 18), the GitHub Releases endpoint returns 404 — the manual command shows a "You're up to date" alert. No `wrangleapp.dev` request is made; no crash.
result: pass
note: "Up-to-date alert displayed without crash and without wrangleapp.dev request, confirming GitHub Releases endpoint 404 path. Alert text reads 'v1.2.0' — same Bundle.main version-string source already tracked under Test 8's MARKETING_VERSION gap; not a new issue."

## Summary

total: 11
passed: 10
issues: 1
pending: 0
skipped: 0
blocked: 0

## Gaps

- truth: "About panel credits display both wrangleapp.dev and github.com/J-Krush/wrangle as stacked vertical links (one per line)"
  status: fixed
  reason: "User reported: links work but appear inline on one line with a bullet separator; user wants them stacked vertically"
  severity: cosmetic
  test: 8
  root_cause: "Bullet separator '  •  ' between the two link NSAttributedString fragments in wrangleApp.swift About-panel block. Trivial layout choice."
  artifacts:
    - path: "wrangle/wrangleApp.swift"
      issue: "About-panel credits used inline bullet separator"
  missing:
    - "Replace '  •  ' separator with trailing '\\n' on the first link"
  debug_session: ""
  fixed_in: "0f1d620"

- truth: "App version reflects the v1.3.0 release in About panel and CFBundleShortVersionString"
  status: fixed
  reason: "User reported: About panel shows 'Version 1.2.0 (5)' — MARKETING_VERSION in Wrangle.xcodeproj/project.pbxproj is still 1.2.0 and was never bumped for Phase 13. WhatsNewManager.dismiss() therefore writes '1.2.0' to lastSeenVersion, which means v1.2.0 upgraders will hit checkOnLaunch's lastSeen == currentVersion guard and never see the OSS announcement modal — only fresh-install paths with deleted defaults fire it. Tests 4–7 passed only because we manually deleted lastSeenVersion before launch."
  severity: major
  test: 8
  root_cause: "Phase 13 added a v1.3.0 ChangelogEntry but didn't bump MARKETING_VERSION (still 1.2.0 in both Debug and Release configs) or CURRENT_PROJECT_VERSION (still 5). The bundle version and changelog version drifted with no automated guard."
  artifacts:
    - path: "Wrangle.xcodeproj/project.pbxproj"
      issue: "MARKETING_VERSION=1.2.0 and CURRENT_PROJECT_VERSION=5 in both Debug and Release configs"
    - path: "wrangle/App/WhatsNewChangelog.swift"
      issue: "Top entry version='1.3.0' but no invariant tying it to bundle version"
  missing:
    - "Bump MARKETING_VERSION 1.2.0 → 1.3.0 (Debug + Release)"
    - "Bump CURRENT_PROJECT_VERSION 5 → 6 (Debug + Release)"
    - "Add DEBUG runtime assert in WhatsNewChangelog comparing top entry to Bundle.main.CFBundleShortVersionString"
    - "Document the release contract in docs/release-checklist.md and link from CLAUDE.md"
  debug_session: ""
  fixed_in: "a2cfa2c, 35fe007, 2810d67"
