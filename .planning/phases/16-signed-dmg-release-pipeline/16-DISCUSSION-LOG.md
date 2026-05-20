# Phase 16: Signed-DMG Release Pipeline - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-20
**Phase:** 16-signed-dmg-release-pipeline
**Areas discussed:** DMG signing gap (REL-04), Script reuse strategy, Documentation home (REL-01), Gatekeeper verification approach (REL-06), Second-Mac access

---

## DMG signing gap (REL-04)

The user reframed the original technical question into a more fundamental one
("What makes sense here? Should I even sign locally, or add a GitHub Actions
workflow that does it?"). Claude responded with three honest paths covering
the entire distribution model, not just the DMG-codesign mechanic.

| Option | Description | Selected |
|--------|-------------|----------|
| Ship unsigned, "build from source" only | No DMG; Xcode setup instructions in README. Most OSS-pure but a Gatekeeper "unidentified developer" prompt is fatal for a 30-second portfolio evaluation. | |
| Local-build signed + notarized DMG (locked plan) | Reuses existing scripts; clean Gatekeeper experience; one-time `notarytool store-credentials` setup. Apple Developer Program already paid. | ✓ |
| GitHub Actions tag-triggered release | Strong portfolio signal but PROJECT.md explicitly defers to v1.4; ~1 day of work; new secret-management surface area right before public flip. | |

**User's choice:** Local-build signed + notarized DMG. ("Ok let's go with optino 2")
**Notes:** Claude recommended sequencing GitHub Actions automation into v1.4
as its own standalone portfolio milestone — "two portfolio milestones instead
of one tangled artifact." User accepted.

For the technical sub-question (how to actually sign the DMG), the implicit
follow-on choice is:

| Option | Description | Selected |
|--------|-------------|----------|
| codesign step after hdiutil | Smallest change to working script; brew create-dmg branch already signs via --identity, so we only patch the hdiutil fallback path. | ✓ |
| Make brew create-dmg the required path | Drops hdiutil fallback; adds brew dependency to the prereq list. | |
| Both paths sign, with spctl verify gate | Belt-and-braces; adds a fail-script-if-unsigned check. Slight over-engineering for the current single-developer release flow. | |

**User's choice:** codesign step after hdiutil (recommended option after user
locked in option 2 for the distribution-model question). Captured as D-02.

---

## Script reuse strategy

| Option | Description | Selected |
|--------|-------------|----------|
| Audit + minimal-fix (Recommended) | Keep build-release.sh and create-dmg.sh separate. Patch only the DMG codesign gap (D-02), strengthen prereq checks, fix weak error handling. Smallest blast radius. | ✓ |
| Consolidate into one release.sh | Merge into single end-to-end script. Single-command release; ~150 lines, more refactor work. | |
| Keep separate + add wrapper | Leave scripts alone; add thin scripts/release.sh that calls them in order. Single-command ergonomics without rewrite. | |

**User's choice:** Audit + minimal-fix.
**Notes:** Captured as D-03. Working code stays working.

---

## Documentation home (REL-01)

| Option | Description | Selected |
|--------|-------------|----------|
| Expand release-checklist.md (Recommended) | Add prereqs / build / sign / notarize / DMG / Gatekeeper verify / draft GH Release sections to the existing doc. One narrative; preserve "Why this checklist exists" footer. | ✓ |
| Rename to docs/release.md | `git mv` + every reference (CLAUDE.md, README) needs updating. Churn for a name change. | |
| Add a separate docs/release.md alongside | Two docs to maintain; "which doc do I need right now" gets annoying. | |

**User's choice:** Expand release-checklist.md.
**Notes:** Captured as D-04. The existing "Why this checklist exists" footer
(the Phase 13 MARKETING_VERSION/WhatsNewChangelog drift story) is valuable
narrative to preserve verbatim.

---

## Gatekeeper verification approach (REL-06)

| Option | Description | Selected |
|--------|-------------|----------|
| Upload-to-draft-Release, re-download, open (Recommended) | Exercise the real com.apple.quarantine path via browser download. Single machine. Doubles as a sanity-check on GH Release upload. | |
| Second physical Mac | Strongest evidence for a portfolio piece. Requires the second machine. | ✓ |
| Synthetic quarantine via xattr | Fastest. Less authentic — the synthetic attribute is constructed, not received from a network download. | |

**User's choice:** Second physical Mac.
**Notes:** Captured as D-05. The re-download path is preserved as an
**optional** secondary check in the deferred section — not required for
REL-06 closure but a low-cost extra signal.

---

## Second-Mac access

| Option | Description | Selected |
|--------|-------------|----------|
| Have one accessible now | Second Mac is ready or borrowable; verification runs as part of Plan 2 without waiting. | ✓ |
| Need to arrange access | Phase 16 still ships but REL-06 verify gets a checkpoint that pauses execution. | |
| Use re-download fallback for now, redo on second Mac before Phase 18 | Plan 2 does upload-to-draft-Release + re-download verification first; second-Mac becomes a Phase 18 pre-flip checkpoint. | |

**User's choice:** Have one accessible now.
**Notes:** Plan 2 can include the second-Mac verification task directly with
no checkpoint/pause logic. Practical execution is unblocked.

---

## Claude's Discretion

The following decisions were captured without asking the user — small enough
that they don't warrant a separate AskUserQuestion turn:

- **DMG filename**: `Wrangle-${VERSION}.dmg` (matches existing create-dmg.sh output)
- **GH tag**: `v1.3.0` (matches MARKETING_VERSION; matches UpdateChecker parse)
- **GH Release state**: `--draft` only (Phase 18 publishes via FLIP-05)
- **Release notes content**: 4–6 bullets, OSS flip narrative + v1.2 headline browser-support features
- **Notarization timeout**: rely on `notarytool submit … --wait`; surface to user if stalls past ~30 min
- **Plan boundary**: per ROADMAP "TBD; expected: 2 plans" — Plan 1 patches + build + DMG; Plan 2 verifies + drafts GH Release. Planner can re-split.

## Deferred Ideas

- **GitHub Actions release automation** — deferred to v1.4 as a standalone
  portfolio milestone. Re-discussed and re-locked during D-01.
- **Optional re-download Gatekeeper sanity check** — beyond D-05's second-Mac
  test. Plan 2 may include as optional, no acceptance-criteria dependency.
- **CODE_SIGN_STYLE / provisioning-profile churn** — Phase 16 does NOT
  switch from `signingStyle=automatic` to manual. If the executor's
  pre-flight check fails on automatic-signing, surface to user; do not
  change the style inside Phase 16.
