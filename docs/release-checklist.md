# Wrangle Release Checklist

Steps to ship a new version of Wrangle. The bundle version, the
What's New entry, and the GitHub Release tag must all move together —
when they drift, the launch-time What's New modal silently fails to fire
for upgrading users.

## 1. Bump the bundle version

Edit `Wrangle.xcodeproj/project.pbxproj`. Two settings need to be bumped
on the **main `Wrangle` target** (Debug + Release configs — 2 occurrences
of each, 4 lines total to edit):

| Setting | What it is | Bump rule |
| ------- | ---------- | --------- |
| `MARKETING_VERSION` | The semver shown in About / Check-for-Updates / WhatsNew dismiss sentinel | Every release |
| `CURRENT_PROJECT_VERSION` | Monotonic build number | Every release |

The `WrangleTests` target (added in Plan 13-03) has its own
`MARKETING_VERSION` + `CURRENT_PROJECT_VERSION` lines that do **NOT** need
to track the release version — the test target ships as a separate
testing-only product and is not part of the user-facing build. The
`scripts/bump-version.sh` helper does a global `sed` replace, which only
hits the main target's lines because the test target is at its own
default version (currently `1.0` / build `1`).

Example bump (main target only):

```diff
-CURRENT_PROJECT_VERSION = 5;
+CURRENT_PROJECT_VERSION = 6;
-MARKETING_VERSION = 1.2.0;
+MARKETING_VERSION = 1.3.0;
```

Verify all 8 version lines (4 main + 4 test) and that the two main-target
configs match each other:

```bash
grep -nE 'MARKETING_VERSION|CURRENT_PROJECT_VERSION' Wrangle.xcodeproj/project.pbxproj
# Expect 8 lines: 4 with MAIN values (the new release), 4 with TEST defaults
# (MARKETING_VERSION = 1.0 / CURRENT_PROJECT_VERSION = 1).

# Strict main-target check (both Debug + Release should match the new version):
grep -c "MARKETING_VERSION = $NEW_VERSION;" Wrangle.xcodeproj/project.pbxproj  # expect 2
grep -c "CURRENT_PROJECT_VERSION = $NEW_BUILD;" Wrangle.xcodeproj/project.pbxproj  # expect 2
```

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
# --verbose=4 is required to expose the Authority chain; `codesign -dv` alone
# omits it (only prints Identifier / Format / Timestamp / TeamIdentifier).
codesign -dv --verbose=4 "$DMG" 2>&1 | grep -q "Developer ID Application" \
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

## 9. UpdateChecker / `releases/latest` behavior

§8 above is the canonical procedure for creating the tag + draft Release.
This section documents the runtime behavior of the in-app
**Check for Updates...** command, which depends on what §8 left in place.

`Check for Updates...` calls
`api.github.com/repos/J-Krush/wrangle/releases/latest` and expects a
published (NOT draft) GitHub Release whose `tag_name` parses as a semver.

| Repo + release state | `releases/latest` returns | UpdateChecker behavior |
|-----------------------|---------------------------|------------------------|
| Private + no Release | `404 Not Found` | "You're up to date" alert (D-10 fallback) |
| Private + draft Release (Phase 16 end-state) | `404 Not Found` | "You're up to date" alert (D-10 fallback) |
| Public + draft Release | `404 Not Found` | "You're up to date" alert (D-10 fallback) |
| Public + published Release with later semver | `200 OK` with `tag_name` | "Update available" sheet with download link |

Phase 16 ends in row 2 (private + draft). Phase 18 (FLIP-05) publishes
the draft AND flips the repo public, moving to row 4 for the v1.3.0
release.

The 404-as-fallback behavior is the locked D-10 outcome from Phase 13 —
not a bug. Tested live during Phase 16 Plan 02 Task 3.

## 10. Quick verification grep

After the release commit lands, this single command confirms steps 1 and 2
agree:

```bash
TOP_ENTRY=$(grep -E 'version: "[0-9]+\.[0-9]+\.[0-9]+"' \
  wrangle/App/WhatsNewChangelog.swift | head -1 | \
  sed -E 's/.*"([0-9]+\.[0-9]+\.[0-9]+)".*/\1/')
# `grep -c MARKETING_VERSION = <ver>;` counts matches across all targets.
# The main Wrangle app has Debug + Release configs (2), WrangleTests has its
# own MARKETING_VERSION (currently 1.0) that does NOT need to track the
# release version. So MAIN_COUNT == 2 means both main-app configs agree on
# TOP_ENTRY. `grep -m1 / head -1` cannot be used here: the test target
# appears before the main target in project.pbxproj.
MAIN_COUNT=$(grep -c "MARKETING_VERSION = $TOP_ENTRY;" \
  Wrangle.xcodeproj/project.pbxproj)
if [ "$MAIN_COUNT" -eq 2 ]; then
  echo "OK: $TOP_ENTRY (2 matches on main Wrangle target)"
else
  echo "MISMATCH: changelog top entry = $TOP_ENTRY; main-target match count = $MAIN_COUNT (expected 2)"
fi
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
