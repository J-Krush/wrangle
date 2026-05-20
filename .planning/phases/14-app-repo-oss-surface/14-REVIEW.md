---
phase: 14-app-repo-oss-surface
reviewed: 2026-05-20T23:45:00Z
depth: standard
files_reviewed: 11
files_reviewed_list:
  - LICENSE
  - CONTRIBUTING.md
  - SECURITY.md
  - README.md
  - CLAUDE.md
  - .gitignore
  - .github/ISSUE_TEMPLATE/bug_report.md
  - .github/ISSUE_TEMPLATE/feature_request.md
  - .github/PULL_REQUEST_TEMPLATE.md
  - screenshots/raw/ (5 visual assets, presence-only)
  - docs/ (D-10 untracking verification only)
findings:
  critical: 0
  high: 0
  medium: 2
  low: 2
  info: 5
  warning: 4
  total: 9
status: issues_found
---

# Phase 14: Code Review Report

**Reviewed:** 2026-05-20T23:45:00Z
**Depth:** standard
**Files Reviewed:** 11 (10 markdown / config + 1 directory presence check)
**Status:** issues_found

## Summary

Phase 14 stood up the documentation / OSS-scaffold layer (LICENSE, README, CONTRIBUTING, SECURITY, `.github/` templates, `.gitignore` rewrite, CLAUDE.md surgical edit, 5 visual assets, `docs/` redaction). Most of the work is correct: required REPO-01..REPO-12 fields are present, no Phase-13 forbidden tokens (Krush LLC / LemonSqueezy paid CTA / $24 / Buy / trial-gated) have been reintroduced, all internal markdown links to `docs/`, `.planning/`, `CONTRIBUTING.md`, `LICENSE`, `SECURITY.md` resolve, all 5 embedded screenshot paths resolve to on-disk assets, and the `.gitignore` does not accidentally ignore any Phase 14 deliverable (verified via `git check-ignore` against LICENSE / README.md / CONTRIBUTING.md / SECURITY.md / .github/ / screenshots/).

The two highest-impact findings are not strictly correctness bugs but they degrade the OSS surface in ways a first-time public visitor will hit:

1. **Case-sensitive-filesystem build break (MD-01).** Both README and CONTRIBUTING instruct contributors to `open Wrangle.xcodeproj` (capital W), but the path that git actually tracks is `wrangle.xcodeproj` (lowercase). On macOS HFS/APFS this is masked by case-insensitive resolution; on a case-sensitive APFS volume or any case-sensitive CI filesystem the command fails. CLAUDE.md line 109 has carried this mismatch since before Phase 14, but Phase 14 propagated the same wrong casing into the two newly-public-facing docs.

2. **SECURITY.md transparency section is incomplete (MD-02).** The new `## Known historical URLs in git history` section enumerates two URL families (wrangleapp.dev/api/trial/*, api.lemonsqueezy.com/v1/licenses/*) but omits `WRANGLE-DEV-PREVIEW`, a hardcoded dev-bypass key present in pre-v1.3 `wrangle/App/LicenseManager.swift` (visible to anyone running `git log -p` against pre-v1.3 commits). Phase 14-03's "0 actual credentials" sweep claim is technically defensible (operational risk is zero — the paywall it bypassed is deleted) but a transparency section that elsewhere invites readers to "report actual credential leaks" should either enumerate this artifact or explicitly scope itself to URLs.

The remaining findings are lower-severity polish (working-tree noise, narrative awkwardness about Phase 18, a couple of stale comments in `.gitignore`).

No BLOCKER-class issues found. Two MD-severity findings should be fixed before the Phase 18 public flip; the rest can wait.

## Medium

### MD-01: README/CONTRIBUTING instruct `open Wrangle.xcodeproj` but git tracks `wrangle.xcodeproj` (case-sensitive FS hazard)

**Files:** `README.md:112`, `CONTRIBUTING.md:36` (also pre-existing in `CLAUDE.md:109`, untouched by Phase 14)
**Severity rationale:** WARNING (degrades cross-platform contributor experience; not a correctness bug on the maintainer's machine).
**Issue:** Both newly-public docs include shell snippets like:

```bash
git clone https://github.com/J-Krush/wrangle.git
cd wrangle
open Wrangle.xcodeproj   # <-- capital W
```

But `git ls-tree HEAD | grep -i xcodeproj` reports `wrangle.xcodeproj` (lowercase) as the tracked path. On macOS HFS+/APFS (`core.ignorecase=true`, default) both casings resolve to the same directory, which is why the maintainer's local checkout works. On a case-sensitive filesystem — Linux CI, case-sensitive APFS volumes some developers use, Docker checkouts, archived ZIP downloads on case-sensitive hosts — the `open Wrangle.xcodeproj` invocation fails with "directory not found." The same hazard applies to `CLAUDE.md:109`'s `MACOSX_DEPLOYMENT_TARGET in Wrangle.xcodeproj/project.pbxproj` reference, though that line was not touched by Phase 14.
**Fix (lowest-risk):** change the three docs to match the tracked path:

```bash
open wrangle.xcodeproj
```

**Fix (alternative, more invasive):** rename the tracked directory to match the canonical filesystem casing via `git mv wrangle.xcodeproj _temp && git mv _temp Wrangle.xcodeproj` (two-step rename required because of `core.ignorecase`). This is more invasive (changes Xcode-project tracking, may surprise the user's existing checkout) and should be a separate phase, not a Phase 14 retro-fix.
**Recommended action:** update the three references in `README.md:112`, `CONTRIBUTING.md:36`, and `CLAUDE.md:109` to lowercase `wrangle.xcodeproj` before the Phase 18 public flip.

### MD-02: SECURITY.md transparency section omits `WRANGLE-DEV-PREVIEW` dev-bypass key in pre-v1.3 history

**File:** `SECURITY.md:19-37`
**Severity rationale:** WARNING (transparency-section completeness; no operational security impact because the paywall it bypassed has been deleted).
**Issue:** The new `## Known historical URLs in git history` section (added in Plan 14-03 Task 6 as the option-2 rotate-and-document outcome) enumerates only two URL families. A `git log --pickaxe-regex -S "WRANGLE-DEV-PREVIEW"` against pre-v1.3 history surfaces a hardcoded dev-bypass token at `wrangle/App/LicenseManager.swift:44` (`private static let devBypassKey = "WRANGLE-DEV-PREVIEW"`) — a literal string that, when entered as a license key against the historical paywall code, unlocked the paid features client-side. This is exactly the kind of artifact the transparency section purports to enumerate: a reader running `git log -p` against pre-v1.3 commits will see it, and the section's closing line ("If you discover an actual credential leak in any commit, please report it via GitHub Security Advisories") will plausibly bait a well-intentioned reporter into filing a duplicate advisory.

Phase 14-03's SUMMARY claims "0 actual credentials" after the canonical sweep + D-20 + planning-noise + token-counting filters. That claim is defensible if "credential" is scoped to "server-side secret that grants access to a live system" — but a hardcoded dev-bypass key is at minimum a credential-shaped artifact, and the transparency section's heading + invitation-to-report framing implies a broader scope.
**Fix:** add one bullet to the section under `SECURITY.md:32`:

```markdown
- **`WRANGLE-DEV-PREVIEW` (hardcoded dev-bypass key)** — A literal
  bypass string present in pre-v1.3 `wrangle/App/LicenseManager.swift`.
  Entering it as a license key unlocked the paid features client-side
  against the v1.0.x paywall code. The paywall and the bypass check
  were both deleted with the v1.3 OSS pivot; the string has no effect
  against current source. Documented here so readers who find it in
  `git log -p` do not need to file a vulnerability report.
```

**Alternative fix:** narrow the section heading to `## Known historical URLs in git history (URL-only sweep)` and add a one-line note that other identifier-shaped strings in deleted source are out of scope. Less honest, but acceptable if the section is intentionally URL-scoped.

## Low

### LO-01: README explicitly references "Phase 18 of the OSS conversion" in install-blocking note

**File:** `README.md:103`
**Severity rationale:** INFO bordering on WARNING (degrades first-impression for a public visitor, but is technically accurate and aligns with the Phase 14-02 plan).
**Issue:**

```markdown
> **Note:** The DMG download link goes live with the `v1.3.0` GitHub Release published in Phase 18 of the OSS conversion. Until then, the release is drafted on a private repo; once published, the `releases/latest` link resolves automatically to a signed, notarized installer.
```

The phrasing leaks the project's internal phase-numbering vocabulary into the public README. A first-time anonymous visitor reading top-to-bottom will hit the Install section, see the Releases link, then read "Phase 18 of the OSS conversion" and need to context-switch into the `.planning/ROADMAP.md` to understand what "Phase 18" means. The transparency-as-feature framing (D-06, D-07) does support phase-talk being legible to readers — but a polished install section ideally would not require a planning-doc round-trip just to confirm "is this thing actually downloadable yet?"
**Fix (optional):** soften the wording without losing the planning-doc pointer:

```markdown
> **Note:** A signed, notarized DMG goes live with the first public GitHub Release. Until then, the [Releases](https://github.com/J-Krush/wrangle/releases/latest) link returns a 404. See [.planning/ROADMAP.md](.planning/ROADMAP.md) for the release-phase schedule.
```

This preserves the transparency callout while reading less like an internal planning note.

### LO-02: `screenshots/raw/walkthrough-short-2.gif` is unresolved working-tree noise

**File:** `screenshots/raw/walkthrough-short-2.gif` (untracked, 1.8 MB, on disk)
**Severity rationale:** INFO (does not break any deliverable; just leaves the working tree dirty).
**Issue:** Plan 14-02's SUMMARY flagged this as a "Plan 14-03 tracked-or-deleted decision," and Plan 14-03's SUMMARY moved it to "Open Follow-ups" instead of resolving it ("Leave as-is unless user wants it tracked or deleted"). The file is now a 1.8 MB untracked artifact that:

- Shows up in `git status` indefinitely (working-tree noise).
- Is not covered by `.gitignore` (so a future `git add .` could accidentally commit it).
- Has no documented purpose in the repo.

**Fix (pick one):**
1. Delete: `rm screenshots/raw/walkthrough-short-2.gif`.
2. Track as an alternate demo asset: `git add screenshots/raw/walkthrough-short-2.gif && git commit`. README is not required to embed it.
3. Gitignore: add `screenshots/raw/walkthrough-short-2.gif` to `.gitignore` if the user wants to keep it locally but never commit it.

The current "leave indefinitely" outcome is the worst of the three options because it preserves the recurring `git status` noise without explaining why.

## Info

### IN-01: `.gitignore:21` comment is stale post-Plan-14-03 Task 3

**File:** `.gitignore:21`
**Issue:** The comment reads `# Local-only docs (D-10 redaction list — git rm --cached happens in Task 3)`. Plan 14-03 Task 3 has already completed; the `git rm --cached` "happens in" wording was accurate during the plan and is now stale. A future contributor reading this comment with no Plan 14-03 context will be confused about whether this is a TODO or done work.
**Fix:**

```gitignore
# Local-only docs (D-10 redaction list — files kept on disk, dropped from git index in Phase 14-03 Task 3)
```

Or simpler:

```gitignore
# Local-only docs (D-10 redaction list — not tracked; remain on disk)
```

### IN-02: `.gitignore:28` `engine/target/` references a near-empty legacy directory

**File:** `.gitignore:28`
**Issue:** The `# Legacy / obsolete` entry covers `engine/target/`. On disk there's a top-level `engine/` directory containing only an empty `target/` subdirectory (last touched 2026-04-02, long before Phase 13). Neither is tracked, neither will be tracked, and there's no `engine/` source code in the repo. The line is harmless but unnecessary clutter.
**Fix (optional):** remove the line if the `engine/` directory has no chance of being repopulated, or document its purpose in a one-line comment if it's a known build artifact location from a previous experiment.

### IN-03: `.gitignore` does not ignore `.planning/config.json`

**File:** `.gitignore`
**Issue:** `git status` shows `.planning/config.json` as untracked (56 bytes). Plan 14-03's SUMMARY explicitly calls this out as "Safe per the planning workflow's default behavior (per-machine config; the planning workflow does not track it)." Fine as-is, but the file shows up in `git status` indefinitely. Same UX-noise concern as LO-02 but lower stakes.
**Fix (optional):** add `.planning/config.json` to `.gitignore` to silence the recurring status entry, or leave as-is if the planning workflow intentionally surfaces it.

### IN-04: README's "Highlights from recent releases" v1.3 bullet references unfinished work

**File:** `README.md:54`
**Issue:** The v1.3 bullet reads:

```markdown
- **v1.3 — Open source release.** This release. License flip to MIT, repo OSS surface, signed-DMG release pipeline, landing-page repositioning. All scoped and tracked under `.planning/phases/13-app-de-commercialization/` through `.planning/phases/18-public-flip/`.
```

Two minor issues: (a) the bullet lists "signed-DMG release pipeline" and "landing-page repositioning" as if they are part of "this release," but per ROADMAP they ship in Phases 16 and 17 — not yet done. (b) Once Phases 15-18 close, this bullet will be accurate; until then it claims work that hasn't happened. Coupled with LO-01, a first-time visitor sees both the "v1.3 ships landing-page repositioning" claim and the "Phase 18 hasn't happened yet" install note, and the two pieces don't square.
**Fix (optional):** either weaken the v1.3 bullet to enumerate only what's done at the moment of the public flip, or accept that this bullet is forward-looking and add a "v1.3 wraps with Phase 18" qualifier.

### IN-05: Issue templates do not gate AI-dev-workflow context as required

**File:** `.github/ISSUE_TEMPLATE/feature_request.md:33-47`
**Issue:** The "AI-dev-workflow context" section is well-written (REPO-05 satisfies the AI-dev-grounding mandate). However, the wording "Requests that are not grounded in an AI-dev workflow may be closed without discussion — Wrangle is intentionally scoped" lives inside an HTML comment (`<!-- ... -->`). On GitHub's issue creation UI, HTML comments are stripped before the issue is filed — but they DO render in the template-author's view as Markdown rendered text. A user reading the template form-fill will see the warning, but the warning has no chance of surviving into the filed issue itself. Likely intentional (templates conventionally use comments for guidance text), no action needed unless the maintainer wants the gating warning to also appear in the rendered issue.

## Structural Findings (fallow)

No `<structural_findings>` block was provided to this review. Skipping section per instructions.

## Out of Scope (per phase calibration)

- Swift code review — no Swift files modified in Phase 14.
- Test coverage — Phase 14 is a docs/scaffold phase, no tests expected.
- Performance — Phase 14 changes have no runtime surface.
- Git-history rewrite for the `git rm --cached` files — Phase 18 decision per D-11.
- Phase 14-02 / Phase 14-03 SUMMARY accuracy claims (e.g., the "D-20 exemption extended to `wrangle/wrangleApp.swift`" note in Plan 14-03 — that exact filename does NOT exist under `wrangle/App/`; the actual file is `wrangle/wrangleApp.swift` at the top of `wrangle/`. Confirmed at `/Users/krush/Projects/Krush-Dev/Wrangle/Wrangle/wrangle/wrangleApp.swift` — not a Phase 14 deliverable, so flagged here for STATE.md / SUMMARY auditability only).

---

_Reviewed: 2026-05-20T23:45:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
