# Phase 16: Signed-DMG Release Pipeline — Research

**Researched:** 2026-05-20
**Domain:** macOS Developer ID signing + Apple notarization + DMG packaging + GitHub Release drafting
**Confidence:** HIGH on the Apple-side command surface (cross-verified across Apple man pages, multiple practitioner walkthroughs, and live local probes); HIGH on `gh release create` mechanics (verified against the official cli.github.com manual); MEDIUM on notary failure-mode coverage (failure messages drawn from third-party debug writeups, not Apple's official table).

## Summary

Phase 16 is a verify-and-fill-gaps phase against an already-functional pipeline (last successful production notarization: `Wrangle-1.2.0.dmg`, 2026-04-21, per `xcrun notarytool history --keychain-profile wrangle-notary` run during this research session). The CONTEXT.md decisions are sound and align with current Apple practice — the only invariant worth re-anchoring is the **codesign-before-notarize-before-staple** ordering for DMGs (D-02): `codesign --sign "Developer ID Application: …" --timestamp --options runtime <dmg>` MUST run BEFORE `xcrun notarytool submit <dmg>`, which MUST run BEFORE `xcrun stapler staple <dmg>`. The inner `.app` is already stapled before DMG packaging by `scripts/build-release.sh`, which is the correct order.

The REL-04 verification command `spctl -a -t open --context context:primary-signature <dmg>` is the **canonical Apple-blessed test** for a notarized DMG's primary signature (not a substitute for `spctl --assess --type exec` on the inner `.app` — both are needed and `build-release.sh` already runs the `.app` form). Expected accepted output: `<file>: accepted` plus `source=Notarized Developer ID` in verbose mode.

Several environmental facts surprised on probe and should reshape Plan 1's pre-flight: (a) **only `Wrangle.xcodeproj` exists** on disk — the CONTEXT.md "both `wrangle.xcodeproj` and `Wrangle.xcodeproj` exist on APFS" claim is stale; case-insensitive APFS may report both via globbing but only the canonical Capital-W path is real, (b) **`create-dmg` is NOT installed** via Homebrew on this machine, so the `hdiutil` fallback branch is *the live path* — D-02's codesign patch lands directly on the executing code path, not the unused branch, (c) **`wrangle-notary` profile is already configured AND the Developer ID Application cert is valid in Keychain** — Plan 1's pre-flight should verify this state, not assume the user needs to set it up, and (d) **macOS 26.2 / Xcode 26.2** is the host — newer than the macOS 15+ minimum the requirements assume, which means there are no Tahoe-era notarization regressions to worry about (historical regressions per the search results all predate macOS 15).

**Primary recommendation:** Plan 1 should be structured as five sequential tasks — (1) pre-flight credential gate, (2) patch `create-dmg.sh` per D-02, (3) expand `docs/release-checklist.md` per D-04, (4) execute the pipeline end-to-end, (5) capture verification artifacts and SUMMARY. Plan 2 is two tasks — (1) second-Mac Gatekeeper verify with artifact capture, (2) `git tag v1.3.0` + `git push origin v1.3.0` + `gh release create v1.3.0 --draft … build/Wrangle-1.3.0.dmg`. No CI/automation work this phase.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01: Local-build only.** Signed + notarized DMG attached to a GitHub Release. GitHub Actions release automation explicitly stays deferred to v1.4 (its own portfolio milestone: "automated the production release pipeline with secrets, signing, and notarization in CI"). Reasserted in CONTEXT.md after a discussion question. Locked: not now.

- **D-02: DMG signing gap fix.** Add `codesign --sign "Developer ID Application" --timestamp <dmg>` between `hdiutil create` and `notarytool submit DMG --wait` in `scripts/create-dmg.sh`. The brew `create-dmg` fallback path already signs via `--identity` and stays — the codesign patch only fills the `hdiutil` branch where the current script ships an unsigned DMG into notarization. After this, `spctl -a -t open --context context:primary-signature <dmg>` is expected to return "accepted" — REL-04 verifies this command explicitly.

- **D-03: Audit + minimal-fix existing scripts.** Keep `build-release.sh` and `create-dmg.sh` as separate scripts. Patch only the DMG codesign gap (D-02), strengthen prereq checks (cert in keychain? notary profile present? Developer ID Application cert findable via `security find-identity -v -p codesigning`?), and improve error handling where weak. NO consolidation into a single `release.sh`; NO rewrite from scratch. Working code is left working.

- **D-04: Expand `docs/release-checklist.md` in place** — no rename, no split. New sections:
  1. **Prereqs** — Developer ID Application cert in Keychain (Team `3DEKQ7GUK6`); one-time `xcrun notarytool store-credentials wrangle-notary` setup with Apple ID + app-specific password + Team ID; Xcode command-line tools present.
  2. **Build / sign / notarize / staple the .app** — invoke `scripts/build-release.sh`; expected output (`build/export/Wrangle.app` stapled + Gatekeeper-clean per `spctl --assess --type exec`).
  3. **DMG packaging + DMG sign + notarize + staple** — invoke `scripts/create-dmg.sh`; expected output (`build/Wrangle-${VERSION}.dmg` signed + stapled); REL-04 verify command `spctl -a -t open --context context:primary-signature <dmg>`.
  4. **Gatekeeper verification** — copy DMG to second Apple Silicon Mac on macOS 15+, open cold, confirm no right-click/Open prompt (D-05).
  5. **Draft GitHub Release** — `git tag v1.3.0`, `git push origin v1.3.0`, `gh release create v1.3.0 --draft --title "v1.3.0" --notes "..." build/Wrangle-1.3.0.dmg`. Explicit `--draft` flag — Phase 18 publishes.
  6. The existing **version bump + WhatsNewChangelog + Debug smoke test** sections are preserved verbatim.

- **D-05: Gatekeeper verification via second physical Apple Silicon Mac running macOS 15+** (user has access). Copy the signed DMG over (AirDrop / USB / external drive), open it cold without `xattr -d`, without right-click → Open; confirm the DMG mounts and the drag-to-Applications layout appears with no Gatekeeper interruption. Capture screenshot + optional `spctl -a -v` output from the second Mac for the Plan 2 SUMMARY.

- **Notary keychain profile name (locked):** `wrangle-notary` — already embedded in both `build-release.sh` and `create-dmg.sh`. Do not rename.
- **Team ID (locked):** `3DEKQ7GUK6` — already in `ExportOptions.plist` and `build-release.sh`. Do not introduce a new team string.
- **Signing identity (locked):** `Developer ID Application` (canonical Apple identity name; full descriptor in Keychain is `Developer ID Application: John Kreisher (3DEKQ7GUK6)` — verified by `security find-identity -v -p codesigning` during research).
- **REL-04 verification command (locked verbatim):** `spctl -a -t open --context context:primary-signature <dmg>` — stricter than `spctl --assess --type exec`. Agents MUST test the exact REL-04 form, not a substitute.
- **GH Release tag convention (locked):** `v` + semver (`v1.3.0`). Matches `UpdateChecker`'s parse rule and `release-checklist.md`.
- **GH Release state (locked):** `--draft` only — Phase 18 publishes via FLIP-05.
- **D-09 reaffirmed:** NO `git filter-repo`, NO `git push --force`, NO `git reset --hard` anywhere in Phase 16. Every Plan's acceptance criteria includes a `git reflog` zero-rewrite check.

### Claude's Discretion

- **DMG filename:** `Wrangle-${VERSION}.dmg` (matches what `create-dmg.sh` already produces — `Wrangle-1.3.0.dmg`).
- **Release notes content:** 4–6 bullets, leading with OSS flip narrative; include v1.2 headline browser-support features (Browsers, Bookmarks, History, Downloads, Private Mode) so the v1.3.0 Release reads as the cumulative product.
- **Notarization timeout:** rely on `notarytool submit … --wait` (no custom polling). Typical 1–15 minutes; if past ~30 minutes, surface to user; do not auto-cancel.
- **Plan boundary:** Plan 1 = patch + doc + execute end-to-end through DMG `spctl` PASS. Plan 2 = second-Mac verify + draft GH Release. Planner can re-split if a cleaner cut emerges.
- **Optional quarantine-attribute verification on draft DMG:** secondary evidence path only; the user re-downloads the uploaded DMG via browser and exercises `xattr -p com.apple.quarantine`. Not required for REL-06 closure.

### Deferred Ideas (OUT OF SCOPE)

- **GitHub Actions release automation** — deferred to v1.4 as its own portfolio milestone. Tag-triggered signing/notarization in CI is ~1 day of additional work and a new secret-management surface area. Not in Phase 16.
- **Re-download Gatekeeper sanity check** — surface as "Task N (optional)" in Plan 2 with no acceptance-criteria dependency. D-05 second-Mac is the canonical REL-06 evidence.
- **`CODE_SIGN_STYLE` switch to manual provisioning** — current `ExportOptions.plist` uses `signingStyle=automatic`. Phase 16 does not switch styles. If pre-flight fails because of automatic-signing weirdness, surface to user.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| REL-01 | `scripts/build-release.sh` (or `docs/release.md`) builds a Release-configuration `.app` for Apple Silicon (arm64) macOS 15+. | `scripts/build-release.sh` already does this (`xcodebuild archive` → `-exportArchive` with `ExportOptions.plist`). Research §"Existing pipeline audit" confirms it builds Release + invokes Developer ID signing path. Plan 1 audit task should run the script end-to-end to prove it still works under Xcode 26.2. |
| REL-02 | Valid Developer ID Application cert in local Keychain; used to sign `.app` + all bundled binaries (SwiftTerm, any embedded frameworks). | Verified locally during research: `security find-identity -v -p codesigning` returns `Developer ID Application: John Kreisher (3DEKQ7GUK6)` as identity #2 of 2 valid identities. xcodebuild's automatic signing flow signs embedded binaries recursively as part of the archive step — no manual per-binary codesign needed. |
| REL-03 | `xcrun notarytool submit … --wait` + `xcrun stapler staple` against the notarized `.app`. | Both commands already in `build-release.sh` lines 45–50. Verified `wrangle-notary` profile is configured (history shows successful Wrangle-1.2.0.dmg notarization on 2026-04-21). Plan 1 doc-expansion captures the keychain-profile setup prereqs. |
| REL-04 | DMG produced from notarized `.app`, signed with same Developer ID, verifiable via `spctl -a -t open --context context:primary-signature <dmg>`. | **D-02 is the fix.** Current `create-dmg.sh` hdiutil branch ships an unsigned DMG straight to notarization — Apple's notary may accept it (DMG signing isn't strictly required for the notary service itself) but `spctl --assess --context context:primary-signature` will reject because there's no primary signature to assess. The codesign step closes the gap. Verified canonical sequence: `codesign --sign … --timestamp <dmg>` → `notarytool submit <dmg> --wait` → `stapler staple <dmg>` → `spctl -a -t open --context context:primary-signature <dmg>` returns `accepted`. |
| REL-05 | GH Release tag convention documented (`v1.3.0`); DMG attached to a tagged Release on `J-Krush/wrangle`. | Tag format already documented in `docs/release-checklist.md` §4. Research confirms `gh release create v1.3.0 --draft --title "…" --notes "…" build/Wrangle-1.3.0.dmg` is the correct invocation; `gh` auto-creates the git tag at HEAD of default branch if it doesn't already exist (but D-04's checklist explicitly creates the tag separately via `git tag` + `git push origin v1.3.0` first, which is the safer pattern — verifies the user is on the intended commit). |
| REL-06 | Release DMG opens cleanly on fresh-eyes Mac without Gatekeeper warnings (no right-click → Open). | D-05's second-Mac procedure. Research confirms a stapled + notarized DMG opens silently on first launch even offline (the ticket is embedded in the DMG; Gatekeeper validates the ticket locally — no network round-trip required). If the second Mac is online, Gatekeeper will also do the online check as a belt-and-suspenders pass. |
</phase_requirements>

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Archive + export the .app | Local build host (Xcode CLI) | — | `xcodebuild archive` + `-exportArchive`; no other tier participates. |
| Code-sign .app + bundled binaries | Local build host (codesign + automatic signing) | Apple ID trust chain (cert issuance) | Automatic signing inside xcodebuild handles recursive signing of frameworks (incl. SwiftTerm). |
| Notarize .app | Apple Notary service | Local Keychain (credentials) | `xcrun notarytool submit --wait` uploads to Apple; credentials retrieved from local Keychain via `--keychain-profile wrangle-notary`. |
| Staple .app ticket | Local build host (stapler) | Apple ticketing service (fetch) | `xcrun stapler staple` downloads the ticket and writes it into the bundle for offline Gatekeeper verification. |
| Package DMG (hdiutil) | Local build host (hdiutil) | — | Pure-local UDIF disk-image creation. |
| Code-sign DMG (D-02 fix) | Local build host (codesign) | Apple cert chain | Same Developer ID Application identity, with `--timestamp` for RFC-3161 timestamp. |
| Notarize DMG | Apple Notary service | Local Keychain (credentials) | Same notary flow, applied to the DMG. |
| Staple DMG ticket | Local build host (stapler) | Apple ticketing service | Without DMG stapling, Gatekeeper falls back to online check on first DMG open. |
| Verify DMG (REL-04) | Local build host (spctl) | — | `spctl -a -t open --context context:primary-signature <dmg>` is a local check against the Gatekeeper assessment engine. |
| Gatekeeper second-Mac verify (REL-06) | Second physical Mac (Finder + Gatekeeper) | Apple revocation/notary infra | Real-user-equivalent path on a machine that never built the artifact. |
| Tag + draft GH Release | Local (git + gh CLI) | GitHub.com (private repo) | `git tag` + `git push origin <tag>` + `gh release create <tag> --draft … <dmg>` — three local commands; one round-trip per command. |

## Standard Stack

### Core

| Tool | Version (host) | Purpose | Why Standard |
|------|---------------|---------|--------------|
| `xcodebuild` | Xcode 26.2 (build 17C52) [VERIFIED: local probe] | Archive + export the `.app` from `Wrangle.xcodeproj`. | The only supported way to drive a Release-config archive with the project's signing settings. |
| `xcrun codesign` | bundled with Xcode 26.2 [VERIFIED: local probe] | Sign the DMG with Developer ID Application + timestamp (D-02). | Apple's canonical signing tool — no alternatives. |
| `xcrun notarytool` | bundled with Xcode 26.2 [VERIFIED: local probe — `wrangle-notary` profile already configured, history contains successful 2026-04-21 Wrangle-1.2.0.dmg submission] | Submit `.app` and `.dmg` to Apple Notary service. | Replaced the deprecated `altool` in Xcode 13+; the only supported notarization driver as of macOS 15+. |
| `xcrun stapler` | bundled with Xcode 26.2 [VERIFIED: local probe] | Attach notarization ticket to `.app` and `.dmg` for offline Gatekeeper. | Apple's only ticket-attachment tool. |
| `spctl` | macOS system tool [VERIFIED: local probe at `/usr/sbin/spctl`] | Local Gatekeeper assessment for both `.app` (`--type exec`) and `.dmg` (`-t open --context context:primary-signature`). | Apple's reference Gatekeeper assessment client. |
| `hdiutil` | macOS system tool [VERIFIED: local probe at `/usr/bin/hdiutil`] | DMG creation (UDZO format) in the fallback branch of `create-dmg.sh`. | **This is the LIVE path** on this machine — `create-dmg` (brew) is NOT installed. |
| `security` | macOS system tool [VERIFIED: local probe] | Pre-flight `find-identity -v -p codesigning` to confirm cert presence. | Standard Keychain query interface. |
| `git` | system git [VERIFIED: local probe] | Create + push the `v1.3.0` tag. | — |
| `gh` | 2.86.0 (2026-01-21) [VERIFIED: local probe at `/opt/homebrew/bin/gh`] | Draft the GitHub Release and upload the DMG asset. | Official GitHub CLI. |

### Supporting

| Tool | Status | Purpose | Notes |
|------|--------|---------|-------|
| `xcpretty` | NOT installed [VERIFIED: local probe] | Pretty-print xcodebuild output. | Existing scripts gracefully fall back via `\| xcpretty \|\| xcodebuild …` idiom. No action required, but Plan 1 docs can mention `gem install xcpretty` as an optional polish step. |
| `create-dmg` (brew) | NOT installed [VERIFIED: local probe — `command -v create-dmg` returns nothing] | Fancier DMG with background image, icon positioning. | The hdiutil fallback is the LIVE path. D-02 patch lands directly on the executing branch — this is *good news* for Phase 16 because the patched path is the only path that will run. If a future contributor `brew install create-dmg`s, the brew branch already supports signing via `--identity` (per upstream create-dmg docs). |
| `openssl` | macOS LibreSSL-bundled | Pre-flight cert-expiry check via `security find-certificate -c "Developer ID Application" -p \| openssl x509 -enddate -noout`. | Already drafted in CONTEXT.md §"Pre-execution credential check expected to run." |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `notarytool submit --wait` | `notarytool submit` (no `--wait`) + manual polling via `notarytool info <submission-id>` | The `--wait` flag has one documented stall mode (electron/notarize#179: submissions hanging without output) but is the simpler control flow for a one-shot manual release. CONTEXT.md locks `--wait` and adds the "surface to user past ~30 min" escape valve. |
| `spctl -a -t open --context context:primary-signature` | `spctl --assess --type install` (for pkg) or `spctl --assess -vv` (less strict) | REL-04 locks the exact form. The `--context context:primary-signature` form is the stricter check specific to assessing a DMG's primary signature — not the app inside it. |
| `gh release create … <dmg>` | `gh release create …` (release-only) + `gh release upload <tag> <dmg>` (separate upload) | Functionally equivalent; the inline-asset form is one fewer command. The separate `gh release upload` is useful if upload fails and needs retry without recreating the release. Plan 2 should know about both. |
| Manual `git tag` + `git push origin <tag>` then `gh release create <tag>` | `gh release create <tag>` alone (auto-creates tag from default-branch HEAD) | Manual tag is safer — pins the release to a specific commit you've verified, not "whatever default branch HEAD is when gh runs." CONTEXT.md's D-04 §5 specifies the manual-tag pattern explicitly. |

**Installation:**

No new installations required — every Core tool is already present on the build host. Optional:

```bash
# Optional polish (one-time):
gem install xcpretty                 # prettier xcodebuild output
brew install create-dmg              # nicer DMG layout (still optional; hdiutil path works)
```

**Version verification:** Performed during research session via `xcodebuild -version`, `gh --version`, `command -v` probes. All Apple-side tools ship with Xcode and are versioned together with the Xcode install. No registry-style version pinning applies (these are OS-bundled tools, not ecosystem packages).

## Package Legitimacy Audit

**N/A — no external packages are installed in this phase.** Every tool listed above is either OS-bundled (`hdiutil`, `spctl`, `security`, `git`), bundled with Xcode (`xcodebuild`, `codesign`, `notarytool`, `stapler`), or already installed and verified via `command -v` probe (`gh`). No `npm install`, `pip install`, `brew install`, `gem install`, or `cargo add` happens during Phase 16.

The optional `xcpretty` and `create-dmg` mentions in the Standard Stack are NOT phase requirements — the live pipeline runs without them. If a future plan wants them as polish, the planner can audit at that time.

## Architecture Patterns

### System Architecture Diagram

```
                       ┌─────────────────────┐
                       │  Local Dev Machine  │
                       │   (Apple Silicon)   │
                       └──────────┬──────────┘
                                  │
        ┌─────────────────────────┴──────────────────────────┐
        │                                                    │
        ▼                                                    ▼
   PRE-FLIGHT GATE                                  PIPELINE EXECUTION
        │                                                    │
        ├── security find-identity (cert in Keychain?)       │
        ├── notarytool history --keychain-profile            │
        │   wrangle-notary (profile configured?)             │
        ├── security find-certificate | openssl x509         │
        │   -enddate (cert not expired?)                     │
        ├── git status --porcelain (clean tree?)             │
        └── grep MARKETING_VERSION pbxproj (== 1.3.0?)       │
                                                             │
        ┌────────────────────────────────────────────────────┘
        │
        ▼
  ┌─────────────────────────┐
  │  scripts/build-release  │
  │  .sh                    │
  └──────────┬──────────────┘
             │
             ▼ xcodebuild archive (Release, arm64)
             ▼ xcodebuild -exportArchive (ExportOptions.plist)
             │   └─→ build/export/Wrangle.app (signed, embedded
             │       SwiftTerm + frameworks recursively signed)
             ▼ xcrun notarytool submit Wrangle.app
             │   --keychain-profile wrangle-notary --wait
             │   └─→ uploads to Apple Notary service
             │   └─→ waits 1–15 min (typical) for terminal status
             ▼ xcrun stapler staple Wrangle.app
             │   └─→ ticket attached to bundle for offline GK
             ▼ spctl --assess --type exec --verbose Wrangle.app
                 └─→ should print "accepted source=Notarized
                     Developer ID"
             │
             ▼
  ┌─────────────────────────┐
  │  scripts/create-dmg.sh  │
  └──────────┬──────────────┘
             │
             ▼ hdiutil create -volname Wrangle -format UDZO
             │   build/Wrangle-1.3.0.dmg
             │
             ▼ codesign --sign "Developer ID Application"        ◄── D-02 GAP FIX
             │   --timestamp --options runtime
             │   build/Wrangle-1.3.0.dmg
             │
             ▼ xcrun notarytool submit Wrangle-1.3.0.dmg
             │   --keychain-profile wrangle-notary --wait
             ▼ xcrun stapler staple Wrangle-1.3.0.dmg
             ▼ spctl -a -t open --context context:                ◄── REL-04 LOCKED
                 primary-signature build/Wrangle-1.3.0.dmg            VERIFICATION
                 └─→ MUST print "accepted source=Notarized
                     Developer ID"
             │
             ▼
  ┌─────────────────────────┐
  │  Manual / Plan 2        │
  └──────────┬──────────────┘
             │
             ▼ Copy DMG to second Apple Silicon Mac
             ▼ Open cold (no xattr -d, no right-click)             ◄── REL-06
             ▼ Capture screenshot + (optional) spctl -a -v
             │
             ▼ git tag v1.3.0
             ▼ git push origin v1.3.0
             ▼ gh release create v1.3.0 --draft
                 --title "v1.3.0" --notes-file release-notes.md
                 build/Wrangle-1.3.0.dmg
                 └─→ private repo, draft state — Phase 18 publishes
```

### Recommended Project Structure

No structural changes needed. The phase touches only:

```
Wrangle/
├── scripts/
│   ├── build-release.sh        # AUDIT (D-03) — add pre-flight checks
│   └── create-dmg.sh           # PATCH (D-02) — insert codesign step
└── docs/
    └── release-checklist.md    # EXPAND IN PLACE (D-04) — 6 new sections
```

### Pattern 1: codesign-before-notarize-before-staple (DMG)

**What:** The canonical sequence for signing + notarizing + stapling a DMG.

**When to use:** Always, for any DMG built from a stapled `.app`.

**Example:**

```bash
# Source: https://umurgdk.dev/articles/distribute-macos-applications-as-dmg-images/
#         + Apple's stapler(1) man page (https://keith.github.io/xcode-man-pages/stapler.1.html)
#         + electron-notarize practice + cross-verified across multiple practitioner walkthroughs.
# [VERIFIED: multiple authoritative sources agree on this sequence]

# 1) Sign the DMG with Developer ID Application + RFC-3161 timestamp + hardened runtime
codesign --sign "Developer ID Application: John Kreisher (3DEKQ7GUK6)" \
    --timestamp \
    --options runtime \
    "build/Wrangle-1.3.0.dmg"

# 2) Submit the signed DMG to Apple's notary service and wait for terminal status
xcrun notarytool submit "build/Wrangle-1.3.0.dmg" \
    --keychain-profile "wrangle-notary" \
    --wait

# 3) Attach the notarization ticket to the DMG (enables offline Gatekeeper verify)
xcrun stapler staple "build/Wrangle-1.3.0.dmg"

# 4) Locally verify the DMG is Gatekeeper-clean (REL-04 locked verification command)
spctl -a -t open --context context:primary-signature -v "build/Wrangle-1.3.0.dmg"
# Expected output:
#   build/Wrangle-1.3.0.dmg: accepted
#   source=Notarized Developer ID
```

**Note on `--options runtime` for DMGs:** Apple's hardened runtime is conceptually an executable-binary protection, but a *DMG* is a disk image, not an executable. In practice, practitioner guides (Medium/Yochen, dennisbabkin.com, multiple Apple Developer Forums answers) include `--options runtime` on the DMG codesign for parity with the `.app` signing settings and to avoid any inconsistency in the assessment surface. It is **safe to include and not strictly required for the DMG itself**. CONTEXT.md's D-02 spec quotes `codesign --sign "Developer ID Application" --timestamp <dmg>` without `--options runtime` — both forms work. **Recommended:** include `--options runtime` for consistency with `build-release.sh` (where xcodebuild's automatic signing always applies the hardened runtime to the `.app`). [CONFIDENCE: HIGH on safety; MEDIUM on "required" — multiple practitioner sources call it optional for DMGs.]

### Pattern 2: Inner-`.app`-stapled-before-DMG-packaging

**What:** The `.app` must be notarized and stapled BEFORE `hdiutil create` puts it in the DMG.

**When to use:** Always.

**Why:** If you build the DMG first and then notarize/staple, the ticket attaches to the DMG but NOT to the `.app` inside. Users who copy the `.app` out of the DMG (the normal install flow!) lose the embedded ticket and Gatekeeper falls back to an online check on first launch. If the user is offline at that moment, the app may take ~5–10 seconds to launch or hit a "verifying" spinner.

The current `scripts/build-release.sh` correctly notarizes + staples the `.app` BEFORE handing off to `create-dmg.sh`. No change needed; the order is right. This pattern is in the architecture diagram above (the `.app` flow finishes with stapler BEFORE create-dmg.sh starts).

[VERIFIED: Apple's stapler(1) man page — "stapling enables Gatekeeper to verify the ticket offline" — combined with the umurgdk.dev walkthrough and the keith.github.io/xcode-man-pages stapler reference, all consistent.]

### Pattern 3: gh release create with auto-tag-creation vs manual-tag-then-create

**What:** Two valid patterns for tagging + drafting a release.

**Pattern 3a (CONTEXT.md D-04 §5 — preferred):**

```bash
# Pin the tag to a verified commit BEFORE drafting the release.
git tag v1.3.0
git push origin v1.3.0
gh release create v1.3.0 \
    --draft \
    --title "v1.3.0" \
    --notes-file release-notes.md \
    build/Wrangle-1.3.0.dmg
```

**Pattern 3b (auto-tag — works but less safe):**

```bash
# gh creates the tag at default-branch HEAD if it doesn't exist.
# Source: https://cli.github.com/manual/gh_release_create
gh release create v1.3.0 \
    --draft \
    --target main \
    --title "v1.3.0" \
    --notes-file release-notes.md \
    build/Wrangle-1.3.0.dmg
```

**Why prefer 3a:** Pattern 3a lets you confirm `git log` shows the expected commit at the tag *before* gh creates the Release; pattern 3b races against any commits that land between "build" and "tag." Plan 2 should use 3a verbatim from CONTEXT.md.

[VERIFIED: cli.github.com/manual/gh_release_create — "If a matching git tag does not yet exist, one will automatically get created from the latest state of the default branch."]

### Anti-Patterns to Avoid

- **Don't `notarytool submit` an UNSIGNED DMG and assume `spctl --context context:primary-signature` will pass afterward.** This is the current `create-dmg.sh` hdiutil-branch bug. Apple's notary service does not require the DMG to be signed to *accept* the submission (it inspects the inner `.app` and stamps a ticket), but `spctl --context context:primary-signature` asks specifically about the DMG's *primary signature* — which is absent. The DMG opens fine because the inner `.app` is stapled, but the REL-04 verification command will report `rejected source=Unnotarized Developer ID`. D-02 closes this.
- **Don't `stapler staple` BEFORE `notarytool submit` succeeds.** Stapler downloads the ticket from Apple's ticketing service — if you call it before the submission reaches `Accepted`, it returns "Could not retrieve a ticket." The `--wait` flag on `notarytool submit` prevents this race in the existing scripts.
- **Don't run `codesign` AFTER `stapler staple`.** Re-signing invalidates the staple (codesign rewrites the signature, the staple is keyed to the old signature). If you need to re-sign for any reason, re-staple afterward.
- **Don't `git push --force` or `git filter-repo` anywhere in this phase.** D-09 reaffirmed by CONTEXT.md. The phase has no history-rewrite requirement.
- **Don't switch `CODE_SIGN_STYLE` from automatic to manual** to "fix" a cert problem. CONTEXT.md `<deferred>` is explicit: surface to user, do not switch styles inside this phase.
- **Don't auto-cancel a stuck `notarytool submit --wait`.** CONTEXT.md says surface past ~30 minutes. The submission continues server-side even if your local process exits.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| DMG creation | Custom dd / mkfs.hfsplus shell scripts | `hdiutil create -volname X -srcfolder Y -format UDZO output.dmg` | hdiutil produces the correct UDIF format Apple's stapler and Gatekeeper expect. UDZO is the standard compressed format. |
| Notarization polling | Custom HTTP polling against the App Store Connect API | `xcrun notarytool submit --wait` (or `submit` + `xcrun notarytool wait <submission-id>`) | notarytool handles the App Store Connect auth, rate limits, and terminal-status detection. Rolling your own is a multi-day project. |
| Apple ID credential storage | Plain-text password in script | `xcrun notarytool store-credentials wrangle-notary` → Keychain | Keychain encryption + access control. Already configured for this project. |
| GitHub Release creation | curl + api.github.com/repos/.../releases | `gh release create` | gh handles auth, asset multipart upload, draft/publish state, and async asset processing. |
| Cert validity check | Manual visual Keychain inspection | `security find-identity -v -p codesigning \| grep "Developer ID Application"` + `security find-certificate -c "Developer ID Application" -p \| openssl x509 -enddate -noout` | Scriptable, parseable, drops cleanly into pre-flight CI gates. |
| Ticket attachment | Custom xattr manipulation | `xcrun stapler staple` | The ticket format is internal to Apple's tooling; the xattr layout is not a documented public interface. |

**Key insight:** Apple's release-pipeline tooling (`notarytool`, `stapler`, `codesign`, `spctl`) is the ONLY supported surface for Developer ID distribution. Every alternative listed is either undocumented, internal, or a re-implementation of work Apple already did. The pre-existing `build-release.sh` + `create-dmg.sh` follow this discipline correctly — Phase 16's job is to fix the one gap (D-02) and document the existing flow, not to introduce new tooling.

## Runtime State Inventory

Phase 16 is a release-engineering phase. Per the rubric in this template, the categories apply:

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | **None** — no databases or datastores touched. The phase produces build artifacts (`build/Wrangle.xcarchive`, `build/export/Wrangle.app`, `build/Wrangle-1.3.0.dmg`) in the `build/` directory, which is `.gitignore`d and ephemeral. UserDefaults / SwiftData stores in the app are untouched. | None. |
| Live service config | **`wrangle-notary` keychain profile** is live state in the user's login Keychain (configured 2026-04 per `notarytool history`). NOT in git. NOT auto-recreatable from repo state. If the user reinstalls macOS or clears the login keychain, the profile must be re-created via `xcrun notarytool store-credentials wrangle-notary …`. **`Developer ID Application: John Kreisher (3DEKQ7GUK6)` identity** is live state in the user's login Keychain (verified during research). Same lifetime/recreation rules. | Plan 1 pre-flight task documents how to detect both states and instructions to set up if absent. |
| OS-registered state | **None** — no launchd, no Task Scheduler, no pm2, no systemd. The release pipeline is invoked manually via shell. | None. |
| Secrets / env vars | **Apple ID + app-specific password** are NOT in env vars — they live inside the `wrangle-notary` keychain profile (notarytool retrieves them via `--keychain-profile`). **Team ID `3DEKQ7GUK6`** is in code (`ExportOptions.plist`, `build-release.sh`) — public-ish; team IDs are not secrets per Apple's distribution model. | None. |
| Build artifacts | **`build/` directory** under repo root accumulates an `.xcarchive`, an exported `.app`, and the DMG. `scripts/build-release.sh` line 19–20 already does `rm -rf "$PROJECT_DIR/build" && mkdir -p "$PROJECT_DIR/build"` at the start of each run, so artifacts are not stale between runs. Verify `build/` is in `.gitignore` (Phase 14 audit work) so DMGs don't accidentally get committed. | Plan 1 audit task: confirm `build/` in `.gitignore`. |

## Common Pitfalls

### Pitfall 1: Stapler called before notarization completes
**What goes wrong:** `xcrun stapler staple` exits with "Could not retrieve a ticket; the ticket has not yet been generated for this app."
**Why it happens:** Stapler asks Apple's ticketing service for the ticket — but the submission's status hasn't propagated yet, OR the submission failed (status `Invalid`) and no ticket exists.
**How to avoid:** Always pair `xcrun notarytool submit` with `--wait` (current scripts do this). If running `submit` without `--wait`, follow with `xcrun notarytool wait <submission-id>` before stapling.
**Warning signs:** Stapler error message; `xcrun notarytool log <submission-id> --keychain-profile wrangle-notary` shows `"status": "Invalid"`.

### Pitfall 2: DMG unsigned at submit-time (current bug — D-02)
**What goes wrong:** `spctl -a -t open --context context:primary-signature <dmg>` returns `rejected source=Unnotarized Developer ID` even though the inner `.app` is notarized and the DMG is stapled.
**Why it happens:** `--context context:primary-signature` is a check on the DMG's own signature, not the inner content. Apple's notary service accepts unsigned DMGs (it doesn't *require* the wrapper to be signed to issue a ticket), but `spctl`'s primary-signature assessment has nothing to evaluate.
**How to avoid:** D-02 — insert `codesign --sign "Developer ID Application: …" --timestamp [--options runtime] <dmg>` between `hdiutil create` and `notarytool submit DMG`.
**Warning signs:** `codesign -dv "<dmg>"` reports "code object is not signed at all"; REL-04 verification fails.

### Pitfall 3: Hardened-runtime not enabled on embedded binaries
**What goes wrong:** Notarization fails with `"The executable does not have the hardened runtime enabled."` (status code 4000 family per Medium/jackymelb writeup).
**Why it happens:** SwiftTerm or another embedded binary was signed without `--options runtime`. xcodebuild's automatic signing path SHOULD apply `--options runtime` to all binaries in the bundle when `ENABLE_HARDENED_RUNTIME=YES` is set in the project, but a manually-signed binary in Frameworks/ that bypassed Xcode would fail.
**How to avoid:** Confirm `ENABLE_HARDENED_RUNTIME = YES` in both Debug and Release config blocks of `Wrangle.xcodeproj/project.pbxproj`. If absent, the audit task (D-03) should add it. (The 2026-04-21 Wrangle-1.2.0.dmg submission succeeded, so this is presumed-clean for the current project — but verify.)
**Warning signs:** `xcrun notarytool log <submission-id> --keychain-profile wrangle-notary <log.json>` shows "The executable does not have the hardened runtime enabled" for a specific path inside the bundle.

### Pitfall 4: Missing secure timestamp on codesign
**What goes wrong:** Notarization fails with `"The signature does not include a secure timestamp."`
**Why it happens:** `codesign --sign … <target>` was called without `--timestamp`. The DMG codesign step in particular is easy to forget this on.
**How to avoid:** The D-02 patch MUST include `--timestamp`. CONTEXT.md's lock specifies it verbatim.
**Warning signs:** Same notarytool log message as above.

### Pitfall 5: `notarytool submit --wait` stalls indefinitely
**What goes wrong:** Submission appears to upload, then the process hangs with no output for hours.
**Why it happens:** Documented in `electron/notarize#179`. Root cause unknown — appears to affect some submissions, possibly large-archive related (the linked issue's archive was 0.3GB).
**How to avoid:** CONTEXT.md's escape valve: "if submission stalls past ~30 minutes, surface to user; do not auto-cancel." If you do cancel, the submission continues server-side — query `xcrun notarytool history --keychain-profile wrangle-notary` to find the submission ID, then `xcrun notarytool info <id>` to check status.
**Warning signs:** No CLI output for > 30 minutes; Activity Monitor shows the `notarytool` process consuming low CPU.

### Pitfall 6: `gh release create` runs against the wrong default branch
**What goes wrong:** `gh release create v1.3.0` (without explicit `--target`) creates the tag at default-branch HEAD, which may not be the commit you built and verified.
**Why it happens:** gh's auto-tag-creation walks the default branch.
**How to avoid:** CONTEXT.md D-04 §5 specifies the manual-tag-first pattern: `git tag v1.3.0` (on the verified commit) → `git push origin v1.3.0` → `gh release create v1.3.0 --draft …`. The tag exists before gh runs, so gh uses it. Belt-and-suspenders: pass `--verify-tag` to abort if the tag is missing.
**Warning signs:** `gh release view v1.3.0` shows a commit SHA other than the one you built; the released DMG's `Info.plist` `CFBundleVersion` matches the build, but `git log` doesn't show that as the tagged commit.

### Pitfall 7: Drafts NOT visible via `releases/latest` on private repos
**What goes wrong:** After drafting v1.3.0, the in-app UpdateChecker hits `api.github.com/repos/J-Krush/wrangle/releases/latest` and gets 404. User worries the release "didn't take."
**Why it happens:** `releases/latest` only returns *published, non-draft, non-prerelease* releases to unauthenticated callers. On a private repo, unauthenticated callers get 404 for all release endpoints regardless. Both conditions apply here.
**How to avoid:** This is **expected and documented** as D-10 behavior from Phase 13 — UpdateChecker falls back to "You're up to date" alert on 404. CONTEXT.md's `<integration_points>` already calls this out. After Phase 18 publishes (the draft → published transition + the private → public flip), the endpoint starts returning 200.
**Warning signs:** Don't treat this as a bug.

### Pitfall 8: Re-signing the `.app` after staple invalidates the staple
**What goes wrong:** Some "fix" step re-runs `codesign` on the `.app` and breaks Gatekeeper.
**Why it happens:** codesign rewrites the bundle signature; the staple is bound to the OLD signature hash.
**How to avoid:** Don't re-sign after staple. If you must re-sign (e.g., changed an Info.plist value), re-submit to notary and re-staple. This is the same rule as Pitfall 1 in reverse.
**Warning signs:** `xcrun stapler validate "<app>"` reports "validation failed" after a `codesign` invocation.

## Code Examples

### Pre-flight credential gate (Plan 1 Task 1 source material)

```bash
# Source: CONTEXT.md <code_context> §"Pre-execution credential check expected to run"
# + local probe results from 2026-05-20 research session.
# [VERIFIED: each command run live during research]

set -euo pipefail

echo "==> Checking Developer ID Application certificate in Keychain..."
if ! security find-identity -v -p codesigning | grep -q "Developer ID Application"; then
    echo "FAIL: No 'Developer ID Application' identity in Keychain."
    echo "      Set up: https://developer.apple.com/account → Certificates → Developer ID Application"
    exit 1
fi

# Verify the expected Team ID is present (locked: 3DEKQ7GUK6)
if ! security find-identity -v -p codesigning | grep -q "3DEKQ7GUK6"; then
    echo "FAIL: Developer ID Application identity for Team 3DEKQ7GUK6 not found."
    exit 1
fi

echo "==> Checking certificate is not expired..."
CERT_ENDDATE=$(security find-certificate -c "Developer ID Application" -p | \
    openssl x509 -enddate -noout 2>/dev/null | cut -d= -f2)
if [[ -z "$CERT_ENDDATE" ]]; then
    echo "WARN: Could not parse cert expiry date — proceed with caution."
else
    EXPIRY_EPOCH=$(date -j -f "%b %d %T %Y %Z" "$CERT_ENDDATE" "+%s" 2>/dev/null || echo "0")
    NOW_EPOCH=$(date "+%s")
    if [[ "$EXPIRY_EPOCH" -lt "$NOW_EPOCH" ]]; then
        echo "FAIL: Developer ID Application certificate expired on $CERT_ENDDATE."
        exit 1
    fi
    echo "  OK — cert valid until $CERT_ENDDATE"
fi

echo "==> Checking notarytool keychain profile 'wrangle-notary' is configured..."
if ! xcrun notarytool history --keychain-profile wrangle-notary > /dev/null 2>&1; then
    echo "FAIL: notarytool profile 'wrangle-notary' not configured."
    echo "      Set up: xcrun notarytool store-credentials wrangle-notary"
    echo "              (prompts for Apple ID, app-specific password, Team ID)"
    exit 1
fi

echo "==> Checking working tree is clean..."
if [[ -n "$(git status --porcelain)" ]]; then
    echo "FAIL: Working tree has uncommitted changes. Commit or stash before releasing."
    git status --short
    exit 1
fi

echo "==> Checking MARKETING_VERSION matches expected (1.3.0)..."
MV=$(grep -m1 'MARKETING_VERSION = ' Wrangle.xcodeproj/project.pbxproj | sed -E 's/.*= ([0-9.]+);.*/\1/')
if [[ "$MV" != "1.3.0" ]]; then
    echo "FAIL: MARKETING_VERSION is '$MV', expected '1.3.0'."
    exit 1
fi

echo ""
echo "All pre-flight checks passed. Ready to build."
```

### D-02 patch site (verbatim — for Plan 1 Task 2)

```diff
--- a/scripts/create-dmg.sh
+++ b/scripts/create-dmg.sh
@@ -50,6 +50,14 @@ else
         "$DMG_FINAL"
 fi

+echo "==> Signing DMG..."
+# REL-04 / D-02: DMG must carry a primary signature for
+#   spctl -a -t open --context context:primary-signature to pass.
+codesign --sign "Developer ID Application: John Kreisher (3DEKQ7GUK6)" \
+    --timestamp \
+    --options runtime \
+    "$DMG_FINAL"
+
 echo "==> Notarizing DMG..."
 xcrun notarytool submit "$DMG_FINAL" \
     --keychain-profile "wrangle-notary" \
@@ -62,6 +70,10 @@ xcrun stapler staple "$DMG_FINAL"
 echo ""
 echo "DMG ready: $DMG_FINAL"

+echo "==> Verifying DMG (REL-04 canonical check)..."
+spctl -a -t open --context context:primary-signature -v "$DMG_FINAL"
+# Expected output: <dmg>: accepted  /  source=Notarized Developer ID
+
 # Clean up staging
 rm -rf "$DMG_DIR"
```

**Note for planner:** The signing identity hard-codes the full descriptor (`Developer ID Application: John Kreisher (3DEKQ7GUK6)`) for unambiguous matching. The shorter form `"Developer ID Application"` works when only one such identity exists in the Keychain — verified locally as the case. Either form is acceptable; the long form is defensive against future multi-team scenarios. Match the style of the existing `build-release.sh` which uses `CODE_SIGN_IDENTITY="Developer ID Application"` (short form) — for consistency, use the short form unless the planner has a reason to differ.

### Draft GH Release (Plan 2 Task 2 source material)

```bash
# Source: cli.github.com/manual/gh_release_create (verified verbatim)
# + CONTEXT.md D-04 §5 (manual-tag-first pattern)
# [VERIFIED: gh CLI manual + local gh --version 2.86.0 probe]

set -euo pipefail

TAG="v1.3.0"
DMG="build/Wrangle-1.3.0.dmg"

# Sanity: verify the DMG exists, is signed, is stapled
[[ -f "$DMG" ]] || { echo "FAIL: $DMG missing"; exit 1; }
codesign -dv "$DMG" 2>&1 | grep -q "Developer ID Application" \
    || { echo "FAIL: $DMG not signed with Developer ID"; exit 1; }
xcrun stapler validate "$DMG" \
    || { echo "FAIL: $DMG not stapled"; exit 1; }
spctl -a -t open --context context:primary-signature -v "$DMG" \
    || { echo "FAIL: $DMG fails REL-04 spctl assessment"; exit 1; }

# Pin the tag to the verified commit BEFORE drafting (Pattern 3a)
git tag "$TAG"
git push origin "$TAG"

# Draft the Release. --draft is locked by CONTEXT.md (Phase 18 publishes).
# Notes file authored by user; 4–6 bullets per CONTEXT.md discretion section.
gh release create "$TAG" \
    --draft \
    --verify-tag \
    --title "$TAG" \
    --notes-file .planning/phases/16-signed-dmg-release-pipeline/release-notes-v1.3.0.md \
    "$DMG"

# Confirm
gh release view "$TAG"
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `altool` for notarization | `xcrun notarytool` | Xcode 13 / 2021 — `altool` notarization features deprecated; removed in Xcode 14. | Already adopted in this project (`build-release.sh`, `create-dmg.sh`). |
| Apple ID + app-specific password on the CLI per-invocation | Keychain profile via `xcrun notarytool store-credentials` + `--keychain-profile` | Xcode 13 / 2021. | Already adopted as `wrangle-notary`. |
| `spctl --assess --type install` for pkg | `spctl -a -t open --context context:primary-signature` for DMG | Always — these are different file types. | REL-04 uses the DMG form correctly. |
| `gh` v1.x release upload via separate `gh release upload` | Inline `gh release create <tag> [assets…]` (v2.x) | gh 2.x stable since 2022. | Local gh is 2.86.0; inline-asset form works. |

**Deprecated/outdated:**
- `altool` — replaced by `notarytool`; do not reintroduce.
- Manual `notarization-info` API polling — replaced by `notarytool submit --wait` / `notarytool wait <id>`.
- Submitting `.zip` of `.app` for notarization — still works but you can't `staple` a zip; the prevailing pattern is staple-the-app-then-DMG-the-stapled-app. Phase 16 follows this.

## Validation Architecture

> Test framework probe: no shell-test framework (bats, shellcheck-as-test) in repo. `xcodebuild test -scheme Wrangle -only-testing:WrangleTests` exists for Swift code but is NOT exercised by this phase (Phase 16 is release-engineering, not app code change). Per Nyquist Dimension 8, validation here is via direct artifact-property assertions and Gatekeeper-equivalent checks.

### Pre-execution gates (Plan 1 Task 1 — pre-flight gate)

A `scripts/preflight-release.sh` (or inline at top of `build-release.sh`) MUST pass before any pipeline step runs.

| Gate | Command | Pass Criterion |
|------|---------|----------------|
| Developer ID cert in Keychain | `security find-identity -v -p codesigning \| grep "Developer ID Application"` | exit 0, ≥1 match |
| Team ID matches lock | `security find-identity -v -p codesigning \| grep "3DEKQ7GUK6"` | exit 0 |
| Cert not expired | `security find-certificate -c "Developer ID Application" -p \| openssl x509 -enddate -noout` | parsed date > today |
| Notary profile configured | `xcrun notarytool history --keychain-profile wrangle-notary` | exit 0 (any non-error response) |
| Working tree clean | `git status --porcelain` | empty output |
| MARKETING_VERSION matches expected tag | `grep -m1 'MARKETING_VERSION = ' Wrangle.xcodeproj/project.pbxproj` | `= 1.3.0;` |
| `Wrangle.xcodeproj` canonical path exists | `[ -d Wrangle.xcodeproj ]` | exit 0 |

### Build-output assertions (Plan 1 Task 4 — after build-release.sh)

| Assertion | Command | Pass Criterion |
|-----------|---------|----------------|
| `.app` exists at expected path | `[ -d build/export/Wrangle.app ]` | exit 0 |
| `.app` is signed with Developer ID | `codesign -dv --verbose=4 build/export/Wrangle.app 2>&1 \| grep "Developer ID Application"` | exit 0 |
| `.app` signature is valid | `codesign --verify --strict --verbose=2 build/export/Wrangle.app` | exit 0, prints `valid on disk` and `satisfies its Designated Requirement` |
| `.app` is stapled | `xcrun stapler validate -v build/export/Wrangle.app` | exit 0, prints `The validate action worked!` |
| `.app` is Gatekeeper-clean | `spctl --assess --type exec --verbose build/export/Wrangle.app` | exit 0, prints `accepted` + `source=Notarized Developer ID` |
| Bundled SwiftTerm is signed | `codesign -dv build/export/Wrangle.app/Contents/Frameworks/SwiftTerm.framework 2>&1 \| grep "Developer ID Application"` | exit 0 (this is XCFramework-dependent; if SwiftTerm is statically linked, skip) |

### DMG-output assertions (Plan 1 Task 4 — after create-dmg.sh)

| Assertion | Command | Pass Criterion |
|-----------|---------|----------------|
| DMG exists | `[ -f build/Wrangle-1.3.0.dmg ]` | exit 0 |
| DMG is signed (D-02 verification) | `codesign -dv build/Wrangle-1.3.0.dmg 2>&1 \| grep "Developer ID Application"` | exit 0 |
| DMG signature has secure timestamp | `codesign -dv --verbose=4 build/Wrangle-1.3.0.dmg 2>&1 \| grep "Timestamp="` | exit 0 |
| DMG is stapled | `xcrun stapler validate -v build/Wrangle-1.3.0.dmg` | exit 0, prints `The validate action worked!` |
| **REL-04 LOCKED**: DMG passes primary-signature assessment | `spctl -a -t open --context context:primary-signature -v build/Wrangle-1.3.0.dmg` | exit 0, prints `accepted` + `source=Notarized Developer ID` |
| Inner `.app` (post-mount) is also stapled | Mount DMG via `hdiutil attach`, then `xcrun stapler validate /Volumes/Wrangle/Wrangle.app` | exit 0 — proves the `.app`-staple survived DMG packaging |

### End-state assertions (Plan 2 — second-Mac + GH Release)

| Assertion | Method | Pass Criterion |
|-----------|--------|----------------|
| REL-06: DMG opens on second Mac with no Gatekeeper prompt | Manual: copy DMG to second Apple Silicon Mac (macOS 15+), double-click in Finder | DMG mounts immediately, drag-to-Applications layout renders, no right-click → Open prompt. Capture screenshot. |
| REL-06 evidence (optional): second-Mac spctl confirms | `spctl -a -v <dmg>` on second Mac terminal | `accepted` + `source=Notarized Developer ID`. Capture output. |
| `v1.3.0` tag exists on origin | `git ls-remote origin refs/tags/v1.3.0` | exit 0, returns one ref |
| Draft GH Release exists with DMG attached | `gh release view v1.3.0` | shows `Status: Draft`, lists `Wrangle-1.3.0.dmg` as asset |
| Draft is NOT publicly visible (confirms `--draft` worked) | `curl -s -o /dev/null -w "%{http_code}" https://api.github.com/repos/J-Krush/wrangle/releases/latest` | returns `404` (private repo + draft) — this is the locked-in D-10 behavior |
| Optional: quarantine attribute on re-downloaded DMG | Upload DMG to draft Release → re-download via browser → `xattr -p com.apple.quarantine <downloaded.dmg>` | returns a value (proves quarantine-path exercised); DMG still opens without right-click |

### Anti-regression checks (every Plan's acceptance criteria)

| Check | Command | Pass Criterion |
|-------|---------|----------------|
| D-09: No history rewrites this session | `git reflog --since="<phase start time>" \| grep -E "(filter-repo\|push.*--force\|reset.*--hard)"` | empty output |
| MARKETING_VERSION unchanged at 1.3.0 | `grep MARKETING_VERSION Wrangle.xcodeproj/project.pbxproj` | both occurrences `= 1.3.0;` |
| `CURRENT_PROJECT_VERSION` unchanged at 6 | `grep CURRENT_PROJECT_VERSION Wrangle.xcodeproj/project.pbxproj` | both occurrences `= 6;` |
| No `git push --force` in session history | `history \| grep "push.*--force"` (zsh: `fc -l 1 \| grep "push.*--force"`) | empty output |
| No provisioning-profile churn | `git diff --name-only HEAD~10..HEAD -- '*.mobileprovision' '*.provisionprofile'` | empty output (none touched) |
| `ExportOptions.plist` unchanged | `git diff HEAD~10..HEAD -- ExportOptions.plist` | empty (or only whitespace) |

### Sampling Rate

- **Per task commit (Plan 1 Tasks 2–3):** patch + doc-expand commits don't need build verification — the build runs at Task 4. After each commit: `git status` clean, message lints OK.
- **Per task commit (Plan 1 Task 4):** every output-producing step asserts on the next row of the Build-output / DMG-output assertion tables above. Task 4 is itself a multi-step task; planner may split into sub-tasks (4a `.app` build, 4b DMG build) if useful.
- **Per wave merge:** N/A — there are no waves in this phase (atomic-commit cadence per CONTEXT.md `<established_patterns>`).
- **Phase gate (before `/gsd:verify-work`):** all rows in Pre-execution gates + Build-output + DMG-output assertion tables PASS. All rows in End-state assertions PASS (Plan 2). All rows in Anti-regression PASS.

### Wave 0 Gaps

- [ ] `scripts/preflight-release.sh` — embeds the pre-execution gate as a script Plan 1 Task 1 can invoke. (Alternative: inline at top of `build-release.sh`; D-03's "patch only the codesign gap" leaves room for both. Planner choice.)
- [ ] `release-notes-v1.3.0.md` — 4–6 bullets per CONTEXT.md discretion; lives at `.planning/phases/16-signed-dmg-release-pipeline/release-notes-v1.3.0.md` until Plan 2 Task 2 consumes it via `gh release create --notes-file`.

*Test framework note:* `xcodebuild test -scheme Wrangle` exists from Phase 13-03 but tests Swift code, not the release pipeline. Phase 16 does not invoke it; the Validation Architecture above is the substitute test surface for a release-engineering phase.

## Security Domain

Per CONTEXT.md (security_enforcement is implicitly enabled), the relevant security surface:

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes (for Apple ID + GitHub) | `wrangle-notary` keychain profile (Apple ID + app-specific password); `gh auth status` (GitHub Personal Access Token) — both already configured. No new auth surface in Phase 16. |
| V3 Session Management | N/A | No web sessions. |
| V4 Access Control | yes (for cert + notary profile) | macOS Keychain access control (cert + notary profile are user-login-keychain items). |
| V5 Input Validation | yes (mild) | The release-notes content is user-written Markdown rendered by GitHub — standard GFM rules apply. No CLI argument-injection surface (commands take known file paths). |
| V6 Cryptography | yes — Developer ID signature is RFC-3161 timestamped + Apple cert chain | `codesign --timestamp` (RFC-3161 from Apple's TSA); never hand-rolled. |

### Known Threat Patterns for the release-pipeline stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Cert leakage (Developer ID private key exfiltration) | Information Disclosure | Cert lives in login Keychain (encrypted-at-rest, requires user password to export). Never copy `.p12` into the repo. CONTEXT.md `<deferred>` explicitly keeps Phase 16 local-only — no CI secrets to manage. |
| App-specific password leakage | Information Disclosure | Stored in `wrangle-notary` Keychain profile (Keychain-encrypted). NEVER logged by notarytool. Never `echo`'d in scripts. |
| Tag confusion / wrong-commit release | Tampering | D-04 §5 manual-tag-first pattern + Validation Architecture's "Build-output assertions" → planner-verified commit before tag-push. |
| DMG tampering after notarization | Tampering | The DMG signature + ticket bind the contents. Any modification invalidates the signature; Gatekeeper rejects. `spctl --assess` catches this. |
| Notarization-service compromise | Trust | Out of scope — Apple's trust chain. No mitigation at our layer. |
| Reused / replayed submission ID | N/A | Submission IDs are write-only artifacts; the ticket is what matters, and the ticket is bound to the specific binary hash. |
| `gh release create` against wrong repo | Tampering | `gh repo set-default` or `gh release create --repo J-Krush/wrangle …` — planner can decide whether to add explicit `--repo`. Recommended: yes, as belt-and-suspenders. |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `--options runtime` is safe to include on DMG codesign but not strictly required. | Pattern 1 (Code-sign-DMG) | If "required" were true, omitting it would cause notarytool to reject. Search results consistently call it optional for DMGs; multiple successful production pipelines (incl. this project's prior v1.2.0 ship per `notarytool history`) used it. Low risk. |
| A2 | The user's second Mac runs macOS 15+ and is Apple Silicon. | REL-06 (D-05) | If actually Intel, Apple Silicon-only build won't run there — but CONTEXT.md states "user has access" to a "second Apple Silicon Mac on macOS 15+." Confirm at execution time. |
| A3 | The `wrangle-notary` profile's stored Apple ID + app-specific password remain valid. | Pre-flight gate | Apple ID passwords don't expire on their own, but app-specific passwords can be revoked from appleid.apple.com. If revoked, `notarytool submit` will fail with a 401-class error. The pre-flight `notarytool history` call exercises the credentials — if they were revoked, it would fail. So the pre-flight catches this. Low risk. |
| A4 | The Developer ID Application cert is valid until a date past 2026-05-20. | Pre-flight gate | The 2026-04-21 successful Wrangle-1.2.0.dmg notarization confirms the cert was valid one month ago. Developer ID certs typically have 5-year validity. Probable expiry: 2028 or later (cert issued in 2023 or 2024 era based on identity hash style). The pre-flight openssl check covers this. Low risk. |
| A5 | `gh` is authenticated for the `J-Krush/wrangle` private repo. | Plan 2 Task 2 (gh release create) | If not, `gh release create` fails with auth error. Plan 2 should prepend `gh auth status` as a sanity check. Add this to the planner's task list. |
| A6 | `build/` is in `.gitignore`. | Runtime State Inventory | If not, a `git add .` after a build accidentally commits a 50MB DMG. Plan 1 audit task should verify; if missing, add. Low risk per Phase 14 audit work. |
| A7 | The hdiutil branch of `create-dmg.sh` is the live path (not the brew create-dmg branch). | Standard Stack supporting table | Verified `command -v create-dmg` returns nothing on this machine. If the user has create-dmg in a non-PATH location, the brew branch could fire — but the brew branch *already signs* the DMG via its `--identity` flag, so D-02 would be redundant-but-harmless. The patch lands correctly either way. Low risk. |
| A8 | `ENABLE_HARDENED_RUNTIME = YES` in Wrangle.xcodeproj Release config. | Pitfall 3 | The 2026-04-21 v1.2.0 notarization succeeded, which strongly implies the runtime is enabled (otherwise notarization would have failed with the documented error). Not directly verified during this research session — Plan 1 Task 1 / audit can grep the pbxproj for `ENABLE_HARDENED_RUNTIME`. Low risk; trivial to verify. |
| A9 | Notarytool's typical wait time of 1–15 minutes still holds in 2025-2026. | Stack supporting (notarytool `--wait`) | Source: practitioner writeups + CONTEXT.md's own discretion section. Apple does not publish an SLA. The 30-minute escape valve in CONTEXT.md covers tail latency. Low risk. |

If any of A2 / A3 / A5 fails at execution time, the appropriate task should halt and surface to the user — this is exactly the "Apple notarization credentials" STATE.md blocker becoming concrete. The pre-flight gate is the canonical place for this to surface.

## Open Questions

1. **Should `--options runtime` be included in the D-02 DMG codesign call?**
   - What we know: it's safe to include (Pattern 1 references); multiple practitioner sources call it optional for DMGs; CONTEXT.md's D-02 quote doesn't include it.
   - What's unclear: whether the planner / user prefers parity with `.app` signing settings or strict adherence to CONTEXT.md's quoted minimal form.
   - Recommendation: include `--options runtime` for consistency. If the user prefers the exact CONTEXT.md-quoted minimal form, drop it; the build still works.

2. **Should the pre-flight gate live in its own `scripts/preflight-release.sh` or be inlined at the top of `build-release.sh`?**
   - What we know: D-03 says "minimal-fix existing scripts" — a separate `preflight-release.sh` is a new file, which is on the edge of "minimal." Inlining keeps everything in `build-release.sh`.
   - What's unclear: whether the planner wants the pre-flight invocable independently (e.g., to run as a standalone sanity check before deciding to release).
   - Recommendation: inline at the top of `build-release.sh`. It's strictly inside D-03's "strengthen prereq checks" mandate. If a future phase wants it standalone, refactor then.

3. **Does the planner want a `release-notes-v1.3.0.md` task in Plan 1 or Plan 2?**
   - What we know: gh's `--notes-file` consumes a Markdown file; CONTEXT.md discretion section specifies 4–6 bullets + content guidance.
   - What's unclear: whether writing the notes belongs in Plan 1 (alongside the doc-expand) or Plan 2 (alongside the gh invocation).
   - Recommendation: Plan 2. Notes content depends on what was actually built — easier to author after Plan 1 confirms the build succeeded.

4. **Should Plan 1 include a `git tag -a v1.3.0` (annotated) vs `git tag v1.3.0` (lightweight)?**
   - What we know: CONTEXT.md D-04 §5 says `git tag v1.3.0` (lightweight). Annotated tags carry their own commit message and author/date.
   - What's unclear: GitHub Releases handle both; the in-app UpdateChecker only reads `tag_name`. Functionally equivalent.
   - Recommendation: follow CONTEXT.md's verbatim form (lightweight). No reason to deviate.

5. **Should the Plan 2 acceptance criteria mandate the `gh release create --verify-tag` flag, or accept either invocation?**
   - What we know: `--verify-tag` aborts if the tag doesn't already exist remotely. Pairs perfectly with Pattern 3a (manual-tag-then-create).
   - What's unclear: defensive vs flexible.
   - Recommendation: include `--verify-tag` in the example, but don't make it a hard acceptance criterion. The manual-tag step makes the verify implicit.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| `xcodebuild` (Xcode CLI) | REL-01, REL-02, build-release.sh | ✓ | 26.2 (build 17C52) | — |
| `xcrun` | All Apple tools | ✓ | 72 | — |
| `xcrun codesign` | D-02, REL-02 | ✓ | bundled Xcode 26.2 | — |
| `xcrun notarytool` | REL-03 | ✓ | bundled Xcode 26.2 | — |
| `xcrun stapler` | REL-03, REL-04 | ✓ | bundled Xcode 26.2 (also at /usr/bin/stapler) | — |
| `spctl` | REL-04, REL-06 | ✓ | macOS system at /usr/sbin/spctl | — |
| `hdiutil` | DMG creation (live path) | ✓ | macOS system at /usr/bin/hdiutil | — |
| `security` | Pre-flight cert check | ✓ | macOS system | — |
| `gh` | REL-05, draft Release | ✓ | 2.86.0 (2026-01-21) at /opt/homebrew/bin/gh | — |
| `git` | tag + push | ✓ | system git | — |
| `openssl` | Pre-flight cert-expiry parse | ✓ | macOS LibreSSL | — |
| `Developer ID Application` cert in login Keychain | REL-02 | ✓ | identity `Developer ID Application: John Kreisher (3DEKQ7GUK6)` (verified live) | — |
| `wrangle-notary` keychain profile | REL-03 | ✓ | history shows successful Wrangle-1.2.0.dmg submission on 2026-04-21 | — |
| `create-dmg` (brew) | OPTIONAL — fancier DMG layout | ✗ | NOT installed | `hdiutil` fallback branch IS the live path (this is fine; D-02 patch lands on this branch). |
| `xcpretty` (gem) | OPTIONAL — pretty xcodebuild output | ✗ | NOT installed | Scripts gracefully fall back via `\| xcpretty \|\| xcodebuild` idiom. |
| Second Apple Silicon Mac (macOS 15+) | REL-06 (D-05) | (per CONTEXT.md: ✓ user has access) | — | — |

**Missing dependencies with no fallback:** None.
**Missing dependencies with fallback:** `create-dmg` (hdiutil branch is live and patch-target), `xcpretty` (graceful fallback already in scripts).

**Host environment surprise:** macOS 26.2 (Tahoe-class) + Xcode 26.2 — *newer* than the macOS 15+ minimum in REL-01. This means:
- No known Tahoe-era notarization regressions (historical regressions all predate macOS 15).
- The DMG built on this host targets macOS 15+ per the project's `MACOSX_DEPLOYMENT_TARGET`, NOT macOS 26+. Gatekeeper on the second Mac (macOS 15+) will assess fine.
- `xcrun notarytool` and `xcrun stapler` behavior is unchanged from prior Xcode 15+ versions for the Developer ID flow.

## Sources

### Primary (HIGH confidence)

- **`stapler(1)` man page** — https://keith.github.io/xcode-man-pages/stapler.1.html — verbatim subcommand semantics, supported formats list, ordering invariant ("must be applied … after an executable or archive has been code-signed and notarized").
- **`notarytool(1)` man page** — https://keith.github.io/xcode-man-pages/notarytool.1.html — full SYNOPSIS, `store-credentials` / `submit` / `history` / `log` / `wait` subcommands, `--keychain-profile` semantics, `--wait` flag semantics + `--timeout` option.
- **gh CLI manual: `gh release create`** — https://cli.github.com/manual/gh_release_create — verbatim OPTIONS table, asset-upload syntax `gh release create [<tag>] [<filename>...]`, `--draft` / `--target` / `--verify-tag` / `--notes-file` flags, auto-tag-creation behavior.
- **Local probes (2026-05-20 research session):**
  - `xcodebuild -version` → Xcode 26.2 (build 17C52)
  - `gh --version` → 2.86.0 (2026-01-21)
  - `command -v create-dmg` → empty (not installed)
  - `command -v xcpretty` → empty (not installed)
  - `security find-identity -v -p codesigning` → `Developer ID Application: John Kreisher (3DEKQ7GUK6)` (identity 2/2)
  - `xcrun notarytool history --keychain-profile wrangle-notary` → "Successfully received submission history" + Wrangle-1.2.0.dmg listed as Accepted, 2026-04-21
  - `sw_vers` → macOS 26.2 / build 25C56
  - `find . -maxdepth 2 -iname '*.xcodeproj' -type d` → only `./Wrangle.xcodeproj` (single canonical path)
  - `grep MARKETING_VERSION pbxproj` → `1.3.0` (both Debug + Release blocks)

### Secondary (MEDIUM-HIGH confidence — multiple practitioner sources agree)

- **umurgdk.dev "Distribute macOS Applications as DMG Images"** — https://umurgdk.dev/articles/distribute-macos-applications-as-dmg-images/ — full DMG sign + notarize + staple + verify workflow with the exact REL-04 `spctl -a -t open --context context:primary-signature` command and expected output `accepted / source=Notarized Developer ID`.
- **scriptingosx.com "Notarize a Command Line Tool with notarytool"** (Armin Briegel) — https://scriptingosx.com/2021/07/notarize-a-command-line-tool-with-notarytool/ — `xcrun notarytool store-credentials` prompt sequence; `com.apple.gke.notary.tool` Keychain item name.
- **Apple Developer Forums thread 128683** — https://developer.apple.com/forums/thread/128683 — `spctl -a -t open --context context:primary-signature -v` rejection cases for notarized DMGs (Swift dylib issues, notarization propagation delay, stapling requirement).
- **Apple Developer Forums thread 675354** ("Checking DMG notarization. Rejected…") — https://developer.apple.com/forums/thread/675354 — DMG-rejection diagnostic patterns.
- **Mindovermiles262 "Making Sense of Apple's Notarization"** — https://mindovermiles262.medium.com/making-sense-of-apples-notarization-4571af960976 — spctl DMG verification command + acceptance output.
- **Apple Developer Forums thread 710678** ("notarytool: No Keychain password item found") — https://developer.apple.com/forums/thread/710678 — what happens when the `--keychain-profile` references a missing profile (error message form).

### Tertiary (LOWER confidence — useful but only one source)

- **Medium/Yochen "Effortless Mac Code Signing and Notarization"** — https://medium.com/@yo7chen/effortless-mac-code-signing-and-notarization-a-comprehensive-guide-using-terminal-b8285df9bf9c — codesign-DMG example with `-f -o runtime --timestamp -s "Developer ID Application: …"`.
- **Medium/Jie Zhang "Debug mac app notarize issue"** — https://medium.com/@jackymelb/debug-mac-app-notarize-issue-e612295c6f98 — notarytool log output JSON format including `"statusSummary": "Archive contains critical validation errors"` and statusCode 4000.
- **electron/notarize issue #179** — https://github.com/electron/notarize/issues/179 — `notarytool submit --wait` hanging behavior; workaround was dropping `--wait`. Source for the "30-minute escape valve" recommendation.
- **dennisbabkin.com "So You Want to Code-Sign macOS Binaries?"** — https://dennisbabkin.com/blog/?t=how-to-get-certificate-code-sign-notarize-macos-binaries-outside-apple-app-store — long-form DMG signing walkthrough confirming the codesign sequence.
- **Apple Support "Gatekeeper and runtime protection in macOS"** — https://support.apple.com/guide/security/gatekeeper-and-runtime-protection-sec5599b66df/web — Gatekeeper online/offline ticket-validation overview.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — every tool verified via local `command -v` + version probe; Apple-tool authority via man pages.
- Architecture & sequencing: HIGH — `codesign → notarize → staple → spctl` order cross-verified across Apple man pages + 4 independent practitioner walkthroughs + this project's own successful v1.2.0 ship.
- Pitfalls: MEDIUM-HIGH — failure-mode messages drawn from third-party debug writeups; Apple does not publish a comprehensive failure-code reference. The major patterns (hardened runtime, secure timestamp, unsigned DMG) are well-known and unambiguous.
- gh CLI: HIGH — official cli.github.com manual + local probe of installed version.
- Pre-flight credential gate: HIGH — verified live on this host.
- Notary `--wait` failure mode: MEDIUM — known stall case documented in electron/notarize#179 but root cause not isolated. CONTEXT.md's escape valve is the right defensive posture.

**Research date:** 2026-05-20
**Valid until:** 2026-06-20 (30 days for the stable Apple tooling surface). If Apple ships a notarytool/stapler update or changes the `spctl --context` semantics in a macOS point release before that, re-validate.
