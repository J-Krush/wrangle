# Phase 16: Signed-DMG Release Pipeline - Context

**Gathered:** 2026-05-20
**Status:** Ready for planning

<domain>
## Phase Boundary

A documented, repeatable local-build procedure produces a signed and notarized
DMG that opens cleanly on a fresh-eyes Mac without Gatekeeper warnings,
attached to a `v1.3.0` tagged GitHub Release on `J-Krush/wrangle` (still
private at this point — Phase 18 flips the repo public and publishes the
Release).

**Requirements addressed:** REL-01, REL-02, REL-03, REL-04, REL-05, REL-06.

**Phase 16 is verify-and-fill-gaps, not greenfield.** The repo already has
`scripts/build-release.sh` (57 lines: archive → export → notarize → staple
the `.app`), `scripts/create-dmg.sh` (69 lines: `hdiutil`/brew `create-dmg`
DMG packaging → notarize → staple DMG), `scripts/bump-version.sh`,
`ExportOptions.plist` (Developer ID, Team `3DEKQ7GUK6`, automatic signing),
and `docs/release-checklist.md` (version-bump + WhatsNew + tagging + Debug
smoke test). MARKETING_VERSION is already at `1.3.0`, build `6`. UpdateChecker
is already repointed to `api.github.com/repos/J-Krush/wrangle/releases/latest`
(Phase 13). Phase 16 patches a DMG-signing gap, expands the release doc to
cover build/sign/notarize/DMG/Gatekeeper, runs the procedure end-to-end, and
drafts (does NOT publish — that's Phase 18) the GH Release.

</domain>

<decisions>
## Implementation Decisions

### Distribution Model (carrying forward; reaffirmed)
- **D-01:** Local-build signed + notarized DMG attached to a GitHub Release.
  GitHub Actions release automation explicitly stays deferred to **v1.4** and
  is now framed as v1.4's first standalone portfolio milestone ("automated
  the production release pipeline with secrets, signing, and notarization in
  CI" — a writeup-worthy story on its own). Reaffirms the PROJECT.md Key
  Decision; reasserted in this discussion when the user asked whether to add
  CI now or later. Locked: not now.

### DMG Signing Gap (REL-04)
- **D-02:** Add `codesign --sign "Developer ID Application" --timestamp <dmg>`
  between `hdiutil create` and `notarytool submit DMG --wait` in
  `scripts/create-dmg.sh`. The brew `create-dmg` fallback path already signs
  via `--identity` and stays — the codesign patch only fills the `hdiutil`
  branch where the current script ships an unsigned DMG into notarization.
  After this, `spctl -a -t open --context context:primary-signature <dmg>`
  is expected to return "accepted" — REL-04 verifies this command explicitly.

### Script Strategy
- **D-03:** Audit + minimal-fix existing scripts. Keep `build-release.sh` and
  `create-dmg.sh` as separate scripts. Patch only the DMG codesign gap (D-02),
  strengthen prereq checks (cert in keychain? notary profile present?
  Developer ID Application cert findable via `security find-identity -v -p
  codesigning`?), and improve error handling where weak. NO consolidation
  into a single `release.sh`; NO rewrite from scratch. Working code is left
  working.

### Documentation Home (REL-01)
- **D-04:** Expand `docs/release-checklist.md` (in place — no rename, no
  split). New sections to add:
  1. **Prereqs** — Developer ID Application cert in Keychain
     (Team `3DEKQ7GUK6`); one-time `xcrun notarytool store-credentials
     wrangle-notary` setup with Apple ID + app-specific password + Team ID;
     Xcode command-line tools present.
  2. **Build / sign / notarize / staple the .app** — invoke
     `scripts/build-release.sh`; expected output (`build/export/Wrangle.app`
     stapled + Gatekeeper-clean per `spctl --assess --type exec`).
  3. **DMG packaging + DMG sign + notarize + staple** — invoke
     `scripts/create-dmg.sh`; expected output (`build/Wrangle-${VERSION}.dmg`
     signed + stapled); REL-04 verify command
     `spctl -a -t open --context context:primary-signature <dmg>`.
  4. **Gatekeeper verification** — copy DMG to second Apple Silicon Mac on
     macOS 15+, open cold, confirm no right-click/Open prompt (D-05).
  5. **Draft GitHub Release** — `git tag v1.3.0`, `git push origin v1.3.0`,
     `gh release create v1.3.0 --draft --title "v1.3.0" --notes "..."
     build/Wrangle-1.3.0.dmg`. Explicit `--draft` flag — Phase 18 publishes.
  6. The existing **version bump + WhatsNewChangelog + Debug smoke test**
     sections are preserved verbatim; they remain the trigger for steps 2–5.

### Gatekeeper Verification (REL-06)
- **D-05:** Verify via a second physical Apple Silicon Mac running macOS 15+
  (user has access). Copy the signed DMG over (AirDrop / USB / external
  drive), open it cold without `xattr -d`, without right-click → Open;
  confirm the DMG mounts and the drag-to-Applications layout appears with no
  Gatekeeper interruption. Capture the result for the Plan 2 SUMMARY
  (screenshot of the mounted DMG window + `spctl -a -v` output from the
  second Mac if `spctl` is exercised there).

### Claude's Discretion
- **DMG filename**: `Wrangle-${VERSION}.dmg` (matches what `create-dmg.sh`
  already produces — `Wrangle-1.3.0.dmg`). NOT `Wrangle.dmg` (loses version
  info from the URL).
- **GH tag name**: `v1.3.0` (matches `MARKETING_VERSION`; matches the
  `UpdateChecker` endpoint's tag-name parse rule documented in
  `release-checklist.md`).
- **GH Release state**: `--draft` only — Phase 18 publishes via FLIP-05.
- **Release notes content**: 4–6 bullets summarizing OSS flip + headline
  v1.2 browser-support features (Phase 18 FLIP-05 references the same
  release-notes line per ROADMAP).
- **Notarization timeout**: rely on `notarytool submit … --wait` (no
  custom polling). Apple-side typical 1–15 minutes; the `--wait` flag
  blocks until terminal status — acceptable for a manual release run.
  If submission stalls past ~30 minutes, surface to user; do not auto-cancel.
- **Plan boundary**: Per ROADMAP "TBD (expected: 2 plans)" — Plan 1 = patch
  scripts + expand release-checklist.md + run end-to-end build/sign/notarize/
  staple/DMG/spctl-verify; Plan 2 = second-Mac Gatekeeper verify + draft GH
  Release tag + upload DMG. Planner can re-split if it finds a cleaner cut.
- **Quarantine-attribute verification on draft DMG**: optional secondary
  evidence; if the user uploads the DMG to the draft Release and re-downloads
  it via the browser, that exercises the actual `com.apple.quarantine`
  attribute path. Not required for REL-06 closure (D-05 second-Mac is the
  primary path), but a low-cost extra signal — note for the planner.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase 16 scope and requirements
- `.planning/REQUIREMENTS.md` §REL-01..REL-06 — six requirements, success
  criteria, and explicit `spctl`/Gatekeeper verification commands.
- `.planning/ROADMAP.md` §"Phase 16: Signed-DMG Release Pipeline" — phase
  goal, depends-on (Phase 13), success criteria (5 items), plan-count
  expectation ("TBD; expected: 2 plans").
- `.planning/PROJECT.md` §Key Decisions — locks "local-build signed DMG, no
  GH Actions automation this milestone."
- `.planning/STATE.md` §Blockers/Concerns — Apple notarization credentials
  prereq warning (cert + app-specific password + Team ID) restated.

### Existing release pipeline (in-tree, MUST audit)
- `scripts/build-release.sh` — current archive/export/notarize/staple flow
  for the `.app`. Uses scheme `Wrangle`, Team `3DEKQ7GUK6`, profile
  `wrangle-notary`. Has `xcpretty` fallback. 57 lines.
- `scripts/create-dmg.sh` — current DMG packaging. Tries brew `create-dmg`
  first, falls back to `hdiutil create`. Notarizes DMG via `wrangle-notary`,
  staples DMG. **Missing explicit DMG `codesign` on the hdiutil branch — D-02
  closes this gap.** 69 lines.
- `scripts/bump-version.sh` — version bumping. Not in Phase 16 critical path
  (MARKETING_VERSION already at 1.3.0) but the release-checklist.md prose
  references it.
- `ExportOptions.plist` — `method=developer-id`, `teamID=3DEKQ7GUK6`,
  `signingStyle=automatic`. Consumed by `build-release.sh` via
  `-exportOptionsPlist`.
- `docs/release-checklist.md` — version bump + WhatsNewChangelog sync +
  Debug smoke test + tagging procedure. 114 lines. **D-04 expands this in
  place; do not rename or split.**

### App-side wiring that touches release flow
- `wrangle/App/WhatsNewChangelog.swift` — v1.3.0 entry already added in
  Phase 13. DEBUG assert `assertTopEntryMatchesBundle` enforces
  MARKETING_VERSION ↔ top-entry version sync.
- `wrangle/Components/UpdateChecker.swift` (or equivalent — Phase 13 work) —
  hits `api.github.com/repos/J-Krush/wrangle/releases/latest`. Expects tag
  parseable as semver. Behavior on 404 (no Release yet): "You're up to date"
  alert. Documented as `D-10` behavior in Phase 13.
- `Wrangle.xcodeproj/project.pbxproj` — `MARKETING_VERSION = 1.3.0`,
  `CURRENT_PROJECT_VERSION = 6` in Release + Debug blocks. Test target
  `WrangleTests` exists (Phase 13-03). Scheme `Wrangle` is shared.

### Prior phase outcomes that gate Phase 16
- `.planning/phases/13-app-de-commercialization/13-SUMMARY.md` — confirms
  the de-commercialized binary is what gets signed (REL-02 invariant —
  Phase 16 must build the post-Phase-13 codebase, not the v1.2 license-gated
  one).
- `.planning/phases/14-app-repo-oss-surface/14-SUMMARY.md` (if present) —
  confirms LICENSE + README + screenshots are in place so the GH Release
  page renders correctly when Phase 18 flips. Not strictly Phase 16's
  problem, but the draft Release notes can link to README sections.

### Out-of-tree references
- Apple Developer notarization docs (notarytool, stapler) — public Apple
  docs at `developer.apple.com/documentation/security/notarizing-macos-software-before-distribution`.
  Not a repo doc but the canonical authority for REL-03 / REL-04 commands.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **`scripts/build-release.sh`**: Already does `xcodebuild archive` (Release
  configuration, Apple Silicon implied by the host) → `xcodebuild
  -exportArchive` with `ExportOptions.plist` → `xcrun notarytool submit
  "$APP_PATH" --keychain-profile "wrangle-notary" --wait` → `xcrun stapler
  staple "$APP_PATH"` → `spctl --assess --type exec --verbose "$APP_PATH"`.
  D-03 says audit and minimal-fix; the structure is sound.
- **`scripts/create-dmg.sh`**: Already produces `build/Wrangle-${VERSION}.dmg`
  from a stapled `.app`. Reads `CFBundleShortVersionString` from
  `Info.plist` for the version suffix. Notarizes DMG via `wrangle-notary`,
  staples DMG. **Gap (D-02):** the `hdiutil` branch ships an unsigned DMG to
  notarize; needs explicit `codesign` step. The brew `create-dmg` branch can
  already sign — see its `--identity` flag in upstream docs.
- **`ExportOptions.plist`**: Reusable as-is. Developer ID, team `3DEKQ7GUK6`,
  automatic signing.
- **`docs/release-checklist.md`**: Reusable as the expansion target (D-04).
  Its "Why this checklist exists" footer (the Phase 13 drift story about
  MARKETING_VERSION ↔ WhatsNewChangelog out-of-sync) is valuable narrative
  to preserve verbatim.

### Established Patterns
- **`set -euo pipefail`** at the top of every script (both existing scripts
  follow this). New release.sh additions / patches must keep this.
- **`SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"`** + `PROJECT_DIR`-relative
  paths so scripts run from any cwd. New patches MUST follow this idiom.
- **Atomic-commit cadence** (carried from Phase 13 / Phase 14 / Phase 15):
  one commit per logical change. D-03's "patch only the codesign gap" means
  one focused commit, not a sweeping refactor.
- **`xcpretty` graceful fallback** — `xcodebuild ... | xcpretty || xcodebuild
  ...` so the script works whether or not xcpretty is installed. New
  xcodebuild invocations should follow.
- **D-09 (carried from Phase 15)**: NO `git filter-repo`, NO `git push
  --force`, NO `git reset --hard` anywhere in this phase. The Phase 15
  audit confirmed zero secret VALUES in either repo's history; Phase 16 has
  no reason to revisit the history-rewrite question.

### Integration Points
- **Tag → UpdateChecker**: Once the `v1.3.0` tag + Release is drafted (not
  published), `api.github.com/repos/J-Krush/wrangle/releases/latest` may
  still return 404 if `--draft` Releases don't surface to the unauthenticated
  endpoint. UpdateChecker handles 404 with the "You're up to date" alert
  (D-10 from Phase 13). After Phase 18 publishes, the endpoint returns 200
  with the tag and the in-app check starts firing correctly. Phase 16 does
  NOT need to verify the publish-side behavior — only that the tag is
  drafted correctly.
- **WhatsNewChangelog ↔ MARKETING_VERSION**: The DEBUG-assert at
  `WhatsNewChangelog.assertTopEntryMatchesBundle` will trap if the build
  is run with a mismatched MARKETING_VERSION ↔ top-entry version. Phase 16
  needs neither to change MARKETING_VERSION (already 1.3.0) nor to touch
  WhatsNewChangelog — just don't break the invariant.
- **Both xcodeproj path-cases exist** (`wrangle.xcodeproj`,
  `Wrangle.xcodeproj`) on the case-insensitive APFS. The live canonical is
  `Wrangle.xcodeproj` (used by `build-release.sh` and matching CLAUDE.md
  "Xcode project name: Wrangle"). Do not introduce a third casing.

### Pre-execution credential check expected to run
Before any executor work, the planner SHOULD include a pre-flight task in
Plan 1 that confirms:
- `security find-identity -v -p codesigning | grep -i "Developer ID Application"` returns ≥1 match for Team `3DEKQ7GUK6`
- `xcrun notarytool history --keychain-profile wrangle-notary 2>&1` returns
  a non-error response (proves the profile exists)
- The Apple Developer cert is not expired (`security find-certificate -c
  "Developer ID Application" -p | openssl x509 -enddate -noout`)

If any check fails, halt and surface to user — this is the STATE.md "Apple
notarization credentials" blocker becoming concrete.

</code_context>

<specifics>
## Specific Ideas

- **Notary keychain profile name is locked:** `wrangle-notary` — already
  embedded in both `build-release.sh` and `create-dmg.sh`. Do not rename.
- **Team ID is locked:** `3DEKQ7GUK6` — already in `ExportOptions.plist`
  and `build-release.sh`. Do not introduce a new team string.
- **Signing identity string is locked:** `Developer ID Application`
  (Apple's canonical identity name; the build script also passes
  `CODE_SIGN_IDENTITY="Developer ID Application"` to `xcodebuild`). The
  D-02 codesign patch uses the same string verbatim.
- **REL-04 verification command is locked verbatim:**
  `spctl -a -t open --context context:primary-signature <dmg>` — this exact
  command must PASS in Plan 1 before the DMG is uploaded to the draft GH
  Release. It's stricter than `spctl --assess --type exec`; agents must
  test the exact REL-04 form, not a substitute.
- **Existing app-level Gatekeeper test is also kept** (already in
  build-release.sh): `spctl --assess --type exec --verbose "$APP_PATH"`.
  This proves the `.app` is Gatekeeper-clean; the REL-04 DMG check is the
  parallel proof for the DMG.
- **GH Release tag convention is locked:** `v` prefix + semver
  (`v1.3.0`). Matches what `UpdateChecker` parses; matches what
  `release-checklist.md` documents.
- **GH Release notes content** (Claude's discretion, but specific): 4–6
  bullets, leading with the OSS flip narrative; include the v1.2 headline
  browser-support features (Browsers, Bookmarks, History, Downloads, Private
  Mode) so the v1.3.0 Release reads as the cumulative product, not just
  "we removed the paywall."
- **D-09 reaffirmed:** no `git filter-repo`, no `git push --force`, no
  `git reset --hard` in either repo at any point in Phase 16. The
  acceptance criteria for every Plan in Phase 16 includes a `git reflog`
  zero-rewrite check, mirrored from Phase 15.
- **Plan 2 second-Mac verification artifacts to capture** for the SUMMARY:
  (a) screenshot of the mounted DMG window on the second Mac, (b) optional
  `spctl -a -v` output from the second Mac's terminal, (c) a one-line
  attestation in plain prose ("opened cleanly on [Model], macOS [version],
  no right-click required").

</specifics>

<deferred>
## Deferred Ideas

### GitHub Actions release automation (deferred to v1.4)
The user surfaced this during the D-01 discussion. Locked rationale:
- v1.3's critical path is "ship a public, signed OSS Mac app + portfolio
  narrative." Adding tag-triggered GH Actions signing/notarization is ~1
  day of additional work and a new secret-management surface area (cert +
  app-specific password as encrypted GH secrets) right before the public
  flip.
- Sequencing v1.4 as a dedicated CI/CD-portfolio milestone gives a
  separate writeup-worthy story: "automated the production release
  pipeline." Combined into v1.3 it just looks like noise in a 50-file PR.
- Tracked in `.planning/REQUIREMENTS.md` "Future Requirements" and in
  PROJECT.md key decisions. No action required in Phase 16.

### Optional re-download Gatekeeper sanity check (Claude's discretion)
If the user wants extra evidence beyond D-05's second-Mac test, the Plan 2
task list can include an optional secondary check: upload the signed DMG
to the draft GH Release, re-download via the browser to a fresh path,
confirm `xattr -p com.apple.quarantine <dmg>` returns a value (proves
internet-quarantine path was exercised), open without right-click. This
is OPTIONAL — D-05 second-Mac is the canonical REL-06 evidence. Note for
the planner: if including, surface as a "Task N (optional)" with no
acceptance-criteria dependency on its outcome.

### CODE_SIGN_STYLE / provisioning-profile churn (not in scope)
The current `ExportOptions.plist` uses `signingStyle=automatic`, which has
historically been a source of "no provisioning profile" failures on fresh
machines. Phase 16 does not switch to manual provisioning — the working
configuration stays. If the executor's pre-flight cert check fails because
of automatic-signing weirdness, surface to user; do not switch styles
inside this phase.

</deferred>

---

*Phase: 16-signed-dmg-release-pipeline*
*Context gathered: 2026-05-20*
