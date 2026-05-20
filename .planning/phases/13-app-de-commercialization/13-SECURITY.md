---
phase: 13
slug: app-de-commercialization
status: verified
threats_open: 0
asvs_level: 1
created: 2026-05-20
---

# Phase 13 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.
> Register authored at plan time (13-01-PLAN.md + 13-02-PLAN.md) and verified
> against implementation by inline code-level checks during /gsd:secure-phase 13.

---

## Trust Boundaries

Plan 13-01 (strip-only) introduced **no new** trust boundaries.

Plan 13-02 introduced two:

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| `api.github.com/repos/J-Krush/wrangle/releases/latest` | New outbound HTTPS GET replacing the prior `wrangleapp.dev/api/version.json` endpoint. Reached via `URLSession.shared`; TLS + ATS + system trust store enforced. | Response only: `tag_name`, `html_url`, `body` — parsed via private `Decodable` whitelist. No request body, no auth header. |
| `LicenseResidueCleanup` Keychain DELETE surface | Local-only one-shot wipe of two hard-coded `(service, account)` pairs left by the deleted v1.2 LicenseManager. | None outbound; in-process `SecItemDelete` calls only. No Keychain READ. |

---

## Threat Register

| Threat ID | Category | Component | Disposition | Mitigation | Status |
|-----------|----------|-----------|-------------|------------|--------|
| T-13-01 | Information Disclosure | Deleted `LicenseManager.swift` Keychain code paths | accept | Service / account / UserDefault constants pinned in `13-CONTEXT.md` D-13 before deletion; reused verbatim by 13-02 `LicenseResidueCleanup`. No PII flowed through the deleted file at the moment of deletion. | closed |
| T-13-02 | Tampering | Deleted `scripts/reset-license.sh` | accept | Dev-only utility; no production code path. | closed |
| T-13-03 | Denial of Service | `WhatsNewView` / `NotificationPermissionView` predicate edits | accept | Predicates collapsed to simpler boolean shape (or extended by one clause for NotificationPermissionView). No new failure modes; `WhatsNew`-wins precedence locked in D-08. | closed |
| T-13-04 | Spoofing / Tampering / Elevation | `Wrangle/Info.plist` (APP-14) | accept | Verification-only read; zero `.entitlements` files in tree; 4 `LSHandlerRank` hits are Apple-standard document-type rank, not URL-scheme registration. | closed |
| T-13-05 | Information Disclosure | `LicenseResidueCleanup` Keychain delete helper | mitigate | Verified `wrangle/App/LicenseResidueCleanup.swift:24-27` — hard-coded `licenseService = "dev.wrangle.license"`, `licenseAccount = "license-key"`, `trialService = "dev.wrangle.trial"`, `trialAccount = "trial-data"` as `private static let`. No user input flows into the Keychain query. Only `SecItemDelete` called — no Keychain READ. `errSecItemNotFound` treated as success (idempotent). | closed |
| T-13-06 | Tampering | `LicenseResidueCleanup` invocation surface | mitigate | Verified single call site at `wrangle/wrangleApp.swift:118` (between `coordinator.updateChecker.checkForUpdate()` and `coordinator.whatsNewManager.checkOnLaunch()`). Helper is `@MainActor`; gate (`!isAtLeast130(lastSeenVersion)`) ensures at-most-once execution per upgrade. Idempotent semantics tolerate accidental multi-invocation. | closed |
| T-13-07 | Tampering / Repudiation | `UpdateChecker` GitHub HTTPS endpoint | mitigate | Verified `wrangle/App/UpdateChecker.swift:12` — `versionEndpoint = "https://api.github.com/repos/J-Krush/wrangle/releases/latest"` as `private static let` (HTTPS, hard-coded). ATS + URLSession.shared enforce TLS + system trust store. Response parsing scoped to `private struct GitHubRelease: Decodable` (lines 102-106) with exactly three fields: `tag_name: String`, `html_url: String`, `body: String?`. No shell-out, no path manipulation, no `eval`. Release notes surfaced as text in the existing update-available alert. | closed |
| T-13-08 | Denial of Service | `UpdateChecker.performCheck` 404 swallow | accept | Pre-public-flip (Phases 13–17) the endpoint returns 404 because the repo is private. Silent swallow for background `checkForUpdate()`; `showUpToDate = true` for manual command per D-10. GitHub rate-limit DoS is also accepted — app degrades to "no update found" silently. | closed |
| T-13-09 | Tampering | About-panel `NSAttributedString` rewrite (dual link) | accept | All URLs hard-coded (`https://wrangleapp.dev`, `https://github.com/J-Krush/wrangle`). No user input in credits string. Link taps delegate to `NSWorkspace.shared.open` → user's default browser. | closed |
| T-13-10 | Information Disclosure | `WhatsNewView` Star-on-GitHub CTA `Link` | mitigate | Verified `wrangle/App/WhatsNewChangelog.swift:52` — CTA URL `URL(string: "https://github.com/J-Krush/wrangle")!` is a compile-time constant. SwiftUI `Link` routes via `NSWorkspace.shared.open`; no app-side cookie/referrer leakage. | closed |

*Status: open · closed*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-13-01 | T-13-01 | Strip-only deletion of in-process Swift code; the four Keychain constants needed for residue cleanup were pre-extracted to 13-CONTEXT.md D-13 before the file was deleted. | J-Krush (phase author) | 2026-05-19 |
| AR-13-02 | T-13-02 | Dev-only `scripts/reset-license.sh` had no production path; deletion is non-load-bearing. | J-Krush | 2026-05-19 |
| AR-13-03 | T-13-03 | Predicate edits collapse / extend by one clause; no new failure modes; WhatsNew-wins precedence is the desired ordering. | J-Krush | 2026-05-19 |
| AR-13-04 | T-13-04 | Info.plist sweep is verification-only; the `LSHandlerRank` hits are Apple-standard document-type rank metadata, not URL-scheme registration. | J-Krush | 2026-05-19 |
| AR-13-08 | T-13-08 | Pre-public-flip 404 swallow is intentional per D-10. GitHub-API rate-limit DoS degrades to a benign "no update found" — non-load-bearing. | J-Krush | 2026-05-19 |
| AR-13-09 | T-13-09 | About-panel `NSAttributedString` rewrite uses hard-coded URLs; no user-input surface in the credits string. AppKit handles link delegation. | J-Krush | 2026-05-19 |

*Accepted risks do not resurface in future audit runs.*

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-05-20 | 10 | 10 | 0 | /gsd:secure-phase (Claude orchestrator, inline code verification per short-circuit rule — register authored at plan time, no auditor subagent spawned) |

### Inline verification checks performed (T-13-05/06/07/10)

```
T-13-05: grep -nE 'dev.wrangle.(license|trial)|"license-key"|"trial-data"' wrangle/App/LicenseResidueCleanup.swift
  → 4 matches at lines 24-27 (hard-coded constants confirmed)

T-13-06: grep -rn 'LicenseResidueCleanup\.run' wrangle/
  → 1 match: wrangle/wrangleApp.swift:118 (single call site confirmed)

T-13-07: grep -nE 'https://(api\.github\.com|github\.com)' wrangle/App/UpdateChecker.swift
  → 1 match at line 12: versionEndpoint constant (HTTPS hard-coded)
  grep 'struct GitHubRelease|tag_name|html_url'
  → struct GitHubRelease: Decodable (line 102) with tag_name, html_url, body (whitelist confirmed)

T-13-10: grep -nE 'https://github\.com/J-Krush/wrangle' wrangle/App/WhatsNewChangelog.swift
  → 1 match at line 52: CTA URL constant (hard-coded confirmed)
```

### Phase 13 late-fix commits — no new threat surface

The following fix commits applied during UAT closure introduce no new
attack surface and were inspected against the threat register:

| Commit | Scope | New surface? |
|--------|-------|--------------|
| `a2cfa2c` | `MARKETING_VERSION` 1.2.0 → 1.3.0 in `project.pbxproj` | none |
| `0f1d620` | About-panel link separator (bullet → newline) | none — both URLs remain hard-coded |
| `35fe007` | `WhatsNewChangelog.assertTopEntryMatchesBundle` DEBUG-only assert | DEBUG-only; reads `Bundle.main.infoDictionary` (in-process, no external input) |
| `2810d67` | `docs/release-checklist.md` + `CLAUDE.md` cross-reference | docs only |
| `52b72c5` | "Krush" → "J-Krush" credit and copyright string | cosmetic; affects About panel + Info.plist copyright key only |
| `a28da0b` | UAT.md gap closure metadata | docs only |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-05-20
