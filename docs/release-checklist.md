# Wrangle Release Checklist

Steps to ship a new version of Wrangle. The bundle version, the
What's New entry, and the GitHub Release tag must all move together —
when they drift, the launch-time What's New modal silently fails to fire
for upgrading users.

## 1. Bump the bundle version

Edit `Wrangle.xcodeproj/project.pbxproj`. Two settings live in **both**
the Debug and Release config blocks (4 occurrences total):

| Setting | What it is | Bump rule |
| ------- | ---------- | --------- |
| `MARKETING_VERSION` | The semver shown in About / Check-for-Updates / WhatsNew dismiss sentinel | Every release |
| `CURRENT_PROJECT_VERSION` | Monotonic build number | Every release |

Example:

```diff
-CURRENT_PROJECT_VERSION = 5;
+CURRENT_PROJECT_VERSION = 6;
-MARKETING_VERSION = 1.2.0;
+MARKETING_VERSION = 1.3.0;
```

Verify all four lines changed:

```bash
grep -nE 'MARKETING_VERSION|CURRENT_PROJECT_VERSION' Wrangle.xcodeproj/project.pbxproj
```

Both `MARKETING_VERSION` lines must match. Both `CURRENT_PROJECT_VERSION`
lines must match.

## 2. Add a top entry to `WhatsNewChangelog.entries`

Edit `wrangle/App/WhatsNewChangelog.swift`. Insert a new `ChangelogEntry`
at **index 0** of `changelog`. Its `version` must exactly equal the new
`MARKETING_VERSION`. Add `New` / `Improved` / `Fixed` sections as needed,
and an optional `ChangelogCTA` if the release has a banner action.

The DEBUG runtime guard `WhatsNewChangelog.assertTopEntryMatchesBundle`
fail-fasts on the first launch if step 1 and step 2 disagree — so a clean
Debug build that boots without an `assert(...)` trap is the proof these
two are in sync.

## 3. Build & smoke test the Debug target

```bash
xcodebuild -project Wrangle.xcodeproj -scheme Wrangle \
  -configuration Debug -destination 'platform=macOS,arch=arm64' build
```

Then launch the built app. With UserDefaults cleared the WhatsNew modal
should fire showing the new entry:

```bash
defaults delete com.krush.wrangle WhatsNewManager.lastSeenVersion 2>/dev/null
```

Without clearing UserDefaults, an upgrade-path simulation requires planting
the previous version:

```bash
defaults write com.krush.wrangle WhatsNewManager.lastSeenVersion "1.2.0"
```

Verify: About panel shows the new version, WhatsNew modal renders the new
entry, Continue dismisses it, and relaunch does not re-show it.

## 4. Tag the release on GitHub

The in-app **Check for Updates...** command hits
`api.github.com/repos/J-Krush/wrangle/releases/latest`. It expects a
GitHub Release whose `tag_name` parses as the new semver:

```bash
git tag v1.3.0
git push origin v1.3.0
# Then draft a GitHub Release pointing at the tag.
```

Until the repo is public and a Release exists, the endpoint returns 404
and the manual command flips to the "You're up to date" alert
(this is the documented `D-10` behavior).

## 5. Quick verification grep

After the release commit lands, this single command confirms steps 1 and 2
agree:

```bash
TOP_ENTRY=$(grep -E 'version: "[0-9]+\.[0-9]+\.[0-9]+"' \
  wrangle/App/WhatsNewChangelog.swift | head -1 | \
  sed -E 's/.*"([0-9]+\.[0-9]+\.[0-9]+)".*/\1/')
MARKETING=$(grep -E 'MARKETING_VERSION = ' \
  Wrangle.xcodeproj/project.pbxproj | head -1 | \
  sed -E 's/.*MARKETING_VERSION = ([0-9]+\.[0-9]+\.[0-9]+);/\1/')
test "$TOP_ENTRY" = "$MARKETING" && echo "OK: $TOP_ENTRY" || \
  echo "MISMATCH: changelog=$TOP_ENTRY marketing=$MARKETING"
```

## Why this checklist exists

Phase 13 added the v1.3.0 WhatsNew entry without bumping
`MARKETING_VERSION`. The bundle stayed on 1.2.0 while the changelog
claimed 1.3.0. `WhatsNewManager.dismiss()` writes
`Bundle.main.CFBundleShortVersionString` to `lastSeenVersion` — which
in that broken state was 1.2.0, so the very next `checkOnLaunch` hit
the `lastSeen == currentVersion` guard and the OSS announcement never
fired for v1.2 → v1.3 upgraders. The DEBUG assert in
`WhatsNewChangelog` exists to catch this class of drift before it
ships; this checklist documents the corresponding manual steps.
