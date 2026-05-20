---
phase: 13
slug: app-de-commercialization
status: partial
nyquist_compliant: false
wave_0_complete: true
created: 2026-05-20
---

# Phase 13 — Validation Strategy

> Per-phase validation contract. Most Phase 13 requirements are
> grep-verifiable deletions / audits / build assertions and are COVERED
> via Phase 13's own self-check machinery. The two behavior tests for
> the WhatsNew flow (APP-10, APP-11) are PARTIAL — Swift Testing files
> exist on disk but cannot run until Plan 13-03 wires up the
> `WrangleTests` target in `Wrangle.xcodeproj`. The UAT pass in
> `13-UAT.md` (11/11) provides bridging manual coverage in the interim.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Swift Testing (`@Suite` / `@Test` / `#expect`) |
| **Config file** | None — Xcode-driven; awaiting `WrangleTests` target in `Wrangle.xcodeproj` (Plan 13-03) |
| **Quick run command** | `xcodebuild test -project Wrangle.xcodeproj -scheme Wrangle -destination 'platform=macOS,arch=arm64' -only-testing:WrangleTests/WhatsNewManagerTests` (will be runnable after 13-03) |
| **Full suite command** | `xcodebuild test -project Wrangle.xcodeproj -scheme Wrangle -destination 'platform=macOS,arch=arm64'` (will be runnable after 13-03) |
| **Estimated runtime** | TBD — all 7 test files combined are well under 1s of compute; estimate <10s wall-clock incl. build |

**Current state:** `xcodebuild -list` reports only the `Wrangle` target.
The seven test files in `WrangleTests/` (`EditorDocumentTests`,
`FileTypeTests`, `LicenseResidueCleanupTests`, `LinkRouterTests`,
`MarkdownParserTests`, `TokenCounterTests`, `WhatsNewManagerTests`) are
on disk but unregistered. Plan 13-03 (`13-03-test-target-wireup-PLAN.md`)
is the chartered closer.

---

## Sampling Rate

- **After every task commit:** N/A — Phase 13 used `xcodebuild build` + targeted grep as feedback
- **After every plan wave:** Full grep audit per plan SUMMARY
- **Before `/gsd:verify-work`:** Build green + per-plan grep audit clean
- **Max feedback latency:** ~30s (full `xcodebuild build` on M-series)

After Plan 13-03 lands, sampling rate flips to `xcodebuild test` per task.

---

## Per-Requirement Verification Map

| Requirement | Behavior | Verification | File / Command | Status |
|-------------|----------|--------------|----------------|--------|
| APP-01 | `wrangle/App/LicenseManager.swift` removed | File-existence assertion | `test ! -f wrangle/App/LicenseManager.swift` (13-01 self-check) | ✅ COVERED |
| APP-02 | `LicenseGateView.swift` removed + no overlay in `ContentView` | File + grep assertion | `test ! -f wrangle/App/LicenseGateView.swift && grep -c 'LicenseGateView' wrangle/ContentView.swift` (== 0) | ✅ COVERED |
| APP-03 | `TrialBannerView.swift` removed + no header in `ContentView` | File + grep assertion | `test ! -f wrangle/App/TrialBannerView.swift && grep -c 'TrialBannerView' wrangle/ContentView.swift` (== 0) | ✅ COVERED |
| APP-04 | `LicenseSettingsView.swift` removed + no License tab | File + grep assertion | `test ! -f wrangle/App/LicenseSettingsView.swift && grep -c 'case license' wrangle/App/SettingsView.swift` (== 0) | ✅ COVERED |
| APP-05 | `scripts/reset-license.sh` removed | File-existence assertion | `test ! -f scripts/reset-license.sh` | ✅ COVERED |
| APP-06 | `AppCoordinator.licenseManager` field stripped | Grep assertion | `grep -c 'licenseManager' wrangle/App/AppCoordinator.swift` (== 0) | ✅ COVERED |
| APP-07 | `loadOnLaunch()` no longer called from `onAppear` | Grep assertion | `grep -c 'loadOnLaunch' wrangle/wrangleApp.swift` (== 0) | ✅ COVERED |
| APP-08 | `wrangleapp.dev/api/trial` request removed | Grep assertion | `grep -c 'wrangleapp.dev/api/trial' wrangle/` (== 0) | ✅ COVERED |
| APP-09 | `WhatsNew` / `NotificationPermission` predicate edits | Positive-assertion grep | `grep -c 'if manager.shouldShowModal {' wrangle/App/WhatsNewView.swift` (== 1) + `grep -c '&& !coordinator.whatsNewManager.shouldShowModal' wrangle/App/NotificationPermissionView.swift` (== 1) | ✅ COVERED |
| APP-10 | WhatsNew v1.3.0 entry with Star-on-GitHub CTA renders | Swift Testing | `WrangleTests/WhatsNewManagerTests.swift::freshInstallFiltersOlderEntries` (test exists, awaits 13-03 target wireup) | ⚠️ PARTIAL |
| APP-11 | First-launch trigger fires for v1.3 upgraders; dismiss writes lastSeenVersion | Swift Testing | `WrangleTests/WhatsNewManagerTests.swift::dismissWritesCurrentVersion` + `upgradingUserSeesOnlyNewer` (tests exist, await 13-03) | ⚠️ PARTIAL |
| APP-12 | `NotificationPermissionView` body copy audit — no commercial-license language | Documentation | 13-01-SUMMARY confirms zero edits required; copy was already license-free | ✅ COVERED |
| APP-13 | Tree-wide forbidden-token sweep clean (with documented exemptions) | Grep audit | `grep -rnE '\$24\|Buy\|Trial\|trial\|License\|license\|LemonSqueezy\|wrangleapp.dev' wrangle/ scripts/` — every hit catalogued in 13-02-SUMMARY exemption list | ✅ COVERED |
| APP-14 | `Wrangle/Info.plist` free of license/trial/URL-scheme entries; 0 `.entitlements` files | Grep audit | `grep -iE 'license\|trial\|URLSchemes' Wrangle/Info.plist` → 4 LSHandlerRank hits (Apple-standard); `find . -name '*.entitlements'` → 0 | ✅ COVERED |
| APP-15 | Clean `xcodebuild build`, zero new warnings | xcodebuild | `xcodebuild -project Wrangle.xcodeproj -scheme Wrangle -configuration Debug build` → `BUILD SUCCEEDED`, only pre-existing baseline warnings (Info.plist copy-resources + DownloadManager nearly-matches) | ✅ COVERED |

### Late-fix coverage (post-UAT commits a2cfa2c..a28da0b)

| Late Fix | Behavior | Verification | Status |
|----------|----------|--------------|--------|
| Bundle version drift guard | `WhatsNewChangelog.entries.first?.version == Bundle.main.CFBundleShortVersionString` | DEBUG runtime `assert(...)` in `wrangle/App/WhatsNewChangelog.swift:assertTopEntryMatchesBundle`. A Debug build that boots without trapping IS the test. | ✅ COVERED |
| `LicenseResidueCleanup` Keychain delete | Idempotent SecItemDelete + instanceID clear + version gate | `WrangleTests/LicenseResidueCleanupTests.swift` (4 tests: idempotentRuns, clearsInstanceID, gateRespectedWhenAtCurrentVersion, gateOpenOnFreshInstall) — file exists, awaits 13-03 | ⚠️ PARTIAL |
| About-panel dual link (vertical layout) | Two clickable URLs stacked, hard-coded | Manual UAT (13-UAT.md Test 8 pass) | MANUAL-ONLY |
| Marketing version 1.3.0 / build 6 | Bundle reads correctly | Manual UAT (13-UAT.md Test 8 + Test 11 pass) | MANUAL-ONLY |
| Krush → J-Krush credit + copyright | Strings updated in 3 places | Manual UAT (13-UAT.md Test 8 pass) | MANUAL-ONLY |

*Status: ✅ COVERED · ⚠️ PARTIAL · MANUAL-ONLY*

---

## Wave 0 Requirements

*All Phase 13 requirements have either an automated verification (grep,
file-existence, build, runtime assert) or an in-repo Swift Testing
specification awaiting Plan 13-03.*

The structural blocker is `Wrangle.xcodeproj` lacking a `WrangleTests`
target — explicitly owned by Plan 13-03. No additional Wave 0 tests
should be authored before 13-03 lands, since they would compound the
on-disk-only state.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| About panel renders dual links vertically with bundle version 1.3.0 and J-Krush credit/copyright | Phase 13 late fixes | Visual/layout rendering not asserted in code | 13-UAT.md Test 8 — pass on 2026-05-20 |
| Cold-start launch produces no license gate, no trial banner, no License tab | Phase 13 success criteria #1 | AppKit GUI cannot be driven from CI | 13-UAT.md Tests 1, 2, 3 — pass on 2026-05-20 |
| WhatsNew modal shows v1.3.0 entry on fresh install, CTA opens browser, Continue dismisses, relaunch does not re-show | Phase 13 success criteria #3 | UserDefaults manipulation + GUI rendering | 13-UAT.md Tests 4, 5, 6, 7 — pass on 2026-05-20 |
| `Check for Updates...` reports up-to-date when GitHub Releases endpoint 404s pre-public-flip | D-10 | Network behavior + alert rendering | 13-UAT.md Test 11 — pass on 2026-05-20 |

The 4 manual entries are bridging coverage. After Plan 13-03 lands, the
2 PARTIAL Swift Testing rows above flip to COVERED and the manual UAT
remains as user-acceptance evidence (not duplicative).

---

## Validation Audit 2026-05-20

| Metric | Count |
|--------|-------|
| Phase 13 requirements (APP-*) | 15 |
| COVERED via grep / build / runtime / spec | 13 |
| PARTIAL (test on disk, target missing) | 2 (APP-10, APP-11) |
| Late fixes COVERED via DEBUG runtime | 1 (drift invariant) |
| Late fixes PARTIAL (test on disk, target missing) | 1 (LicenseResidueCleanup tests) |
| Late fixes MANUAL-ONLY (visual / layout) | 3 |
| Open requirement gaps | 0 |
| Open infrastructure gaps | 1 (Xcode test target — chartered to Plan 13-03) |

**Verdict:** `nyquist_compliant: false` until Plan 13-03 executes and
`xcodebuild test` runs the 8 Swift Testing entries green.

---

## Validation Sign-Off

- [x] All requirements have an automated verification OR an in-repo test spec awaiting 13-03
- [x] Sampling continuity: every plan wave used grep + xcodebuild as feedback
- [x] No additional Wave 0 tests required (would compound 13-03 gap)
- [x] No watch-mode flags
- [x] Build-feedback latency ~30s on M-series
- [ ] `nyquist_compliant: true` — blocked on Plan 13-03 executing the test target wireup

**Approval:** partial 2026-05-20 — re-run `/gsd:validate-phase 13` after
Plan 13-03 lands to flip APP-10, APP-11, and LicenseResidueCleanupTests
from PARTIAL to COVERED.
