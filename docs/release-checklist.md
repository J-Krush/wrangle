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

## 4. Prereqs (signed-release pipeline)

The signed-DMG release pipeline depends on three host-local resources.
`scripts/preflight-release.sh` runs all of these automatically before
`scripts/build-release.sh` does any work; this table is the manual
fallback when setting up a new build host.

| Resource | Verify command | Set-up |
| -------- | -------------- | ------ |
| Developer ID Application certificate in Keychain (Team `3DEKQ7GUK6`) | `security find-identity -v -p codesigning \| grep "Developer ID Application"` | <https://developer.apple.com/account> → Certificates → Developer ID Application |
| `wrangle-notary` keychain profile (notarytool credentials) | `xcrun notarytool history --keychain-profile wrangle-notary` | `xcrun notarytool store-credentials wrangle-notary` (prompts for Apple ID + app-specific password + Team ID `3DEKQ7GUK6`) |
| Xcode command-line tools | `xcode-select -p` | `xcode-select --install` |

Sanity-check the whole gate in one command:

```bash
bash scripts/preflight-release.sh
```

Expected output: `All pre-flight checks passed. Ready to build.` On the
first failure, the script prints `FAIL: <message>` plus an actionable
next step and exits 1.

## 5. Build / sign / notarize / staple the .app

```bash
bash scripts/build-release.sh
```

The script invokes the pre-flight gate first, then runs
`xcodebuild archive` → `xcodebuild -exportArchive` → `xcrun notarytool
submit --wait` → `xcrun stapler staple` → `spctl --assess`. The
notarization round trip is the long step (typically 1–15 minutes).

Verify the produced `.app`:

```bash
[ -d build/export/Wrangle.app ] && echo "exists"
codesign -dv --verbose=4 build/export/Wrangle.app 2>&1 | grep "Developer ID Application"
xcrun stapler validate -v build/export/Wrangle.app
spctl --assess --type exec --verbose build/export/Wrangle.app
```

Pass criteria: the directory exists; `codesign -dv` reports a Developer
ID Application authority; `stapler validate` prints `The validate action
worked!`; `spctl --assess` prints `accepted source=Notarized Developer
ID`.

## 6. DMG packaging + DMG sign + notarize + staple

```bash
bash scripts/create-dmg.sh
```

The script stages `Wrangle.app` + an `/Applications` alias into
`build/dmg/`, builds `build/Wrangle-${VERSION}.dmg` via `hdiutil`
(or the brew `create-dmg` fallback if installed), signs the DMG with
Developer ID Application + RFC-3161 secure timestamp + hardened runtime
(REL-04 / D-02), submits it to Apple Notary, staples the resulting
ticket, then runs the REL-04 verification command as its final step.

Verify the produced DMG:

```bash
[ -f build/Wrangle-1.3.0.dmg ] && echo "exists"
codesign -dv --verbose=4 build/Wrangle-1.3.0.dmg 2>&1 | grep -E "Developer ID Application|Timestamp="
xcrun stapler validate -v build/Wrangle-1.3.0.dmg
spctl -a -t open --context context:primary-signature -v build/Wrangle-1.3.0.dmg
```

The last command is the REL-04 LOCKED assessment — verbatim across the
script, this checklist, and the plan. Expected output:
`build/Wrangle-1.3.0.dmg: accepted` and `source=Notarized Developer ID`.
If this fails, the DMG is not safe to ship — the D-02 signing step in
`scripts/create-dmg.sh` is the fix.

## 7. Gatekeeper verification (second Mac)

The build host signed the DMG, so its local trust cache already knows
the certificate. To exercise the real Gatekeeper path — Apple's stapled
ticket validating offline against an arbitrary user's machine — copy
the DMG to a second physical Apple Silicon Mac running macOS 15+.

1. Transfer `build/Wrangle-1.3.0.dmg` via AirDrop (preferred — exercises
   the `com.apple.quarantine` extended attribute the same way a web
   download would), USB external drive, or a network share. Do NOT
   pre-treat with `xattr -d com.apple.quarantine`.
2. On the second Mac, double-click `Wrangle-1.3.0.dmg` in Finder.
   Expected: DMG mounts immediately (sub-second) and the
   drag-to-Applications layout window appears with `Wrangle.app` and an
   `Applications` alias. There must be no "macOS cannot verify the
   developer" dialog, no right-click → Open prompt, no
   "unidentified developer" warning, no `verifying...` spinner.
3. Capture a screenshot of the mounted DMG window (`Cmd+Shift+4`) for
   the audit trail; the Phase 16 Plan 02 SUMMARY commits it under
   `.planning/phases/16-signed-dmg-release-pipeline/16-02-VERIFY/`.
4. Optional secondary evidence: on the second Mac terminal, run
   `spctl -a -v /Volumes/Wrangle/Wrangle.app` — expected
   `accepted source=Notarized Developer ID`.
5. Drag `Wrangle.app` to the `Applications` alias, then launch from
   Spotlight or `/Applications`. The app must open directly to the
   editor with no "downloaded from internet" first-launch dialog.

This step closes REL-06 (D-05 locked protocol).

## 8. Draft GitHub Release

```bash
TAG="v1.3.0"
DMG="build/Wrangle-1.3.0.dmg"

[ -f "$DMG" ] || { echo "FAIL: $DMG missing"; exit 1; }
codesign -dv "$DMG" 2>&1 | grep -q "Developer ID Application" \
    || { echo "FAIL: $DMG not signed"; exit 1; }
xcrun stapler validate "$DMG" \
    || { echo "FAIL: $DMG not stapled"; exit 1; }
spctl -a -t open --context context:primary-signature -v "$DMG" \
    || { echo "FAIL: $DMG fails REL-04 assessment"; exit 1; }

git tag "$TAG"
git push origin "$TAG"

gh release create "$TAG" \
    --repo J-Krush/wrangle \
    --draft \
    --verify-tag \
    --title "$TAG" \
    --notes-file .planning/phases/16-signed-dmg-release-pipeline/release-notes-v1.3.0.md \
    "$DMG"

gh release view "$TAG" --repo J-Krush/wrangle
```

`--draft` is mandatory — Phase 18 (FLIP-05) publishes; Phase 16 only
prepares the artifact. `--verify-tag` aborts if the tag was not pushed
(belt-and-suspenders for the manual-tag-first pattern). `--notes-file`
consumes the Phase 16 Plan 02 release-notes file, which lives outside
the app source tree.

Expected after success: `gh release view v1.3.0 --repo J-Krush/wrangle`
reports `Status: Draft` and lists `Wrangle-1.3.0.dmg` as an asset.
Confirm the draft is NOT publicly visible —
`curl -s -o /dev/null -w "%{http_code}" https://api.github.com/repos/J-Krush/wrangle/releases/latest`
returns `404` (private repo + draft state; the locked D-10 behavior
from Phase 13).

This step closes REL-05.

## 9. Tag the release on GitHub

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

## 10. Quick verification grep

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
