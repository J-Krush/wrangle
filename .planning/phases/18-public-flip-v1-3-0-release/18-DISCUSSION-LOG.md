# Phase 18: Public Flip + v1.3.0 Release - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-23
**Phase:** 18-public-flip-v1-3-0-release
**Areas discussed:** Secrets sweep — scope + recovery, Flip & publish sequencing, Anonymous-viewer verification evidence, Vendor / external-system cleanup

---

## Secrets sweep — scope + recovery

### Sweep depth

| Option | Description | Selected |
|--------|-------------|----------|
| Just the current files | Working tree only on both repos. Fast (~30 sec). Matches Phase 14/15 pattern. | |
| Current files AND every old commit | `git rev-list --all | xargs git grep` for full history. Catches anything that ever existed in any commit. Literal ROADMAP FLIP-01 text. | ✓ |
| Current files + history since v1.2 only | Working tree + history grep limited to milestone commits. Skips already-audited ancient history. | |

**User's choice:** Current files AND every old commit (full history sweep).
**Notes:** Matches the literal ROADMAP success-criteria #1 wording. Belt-and-suspenders before the irreversible flip.

### Known-noise recording

| Option | Description | Selected |
|--------|-------------|----------|
| List them inline in the plan + SUMMARY | Phase 13 APP-13 exemption pattern. After-sweep clean check = total hits minus exempted noise must be empty. Lives only inside `.planning/`. | ✓ |
| Separate audit file inside the phase dir | Stand up `18-FLIP-AUDIT.md` with full grep output. Phase 15 D-10 explicitly chose against this shape. | |
| Whichever feels cleaner at execution time | Defer to executor. | |

**User's choice:** Inline list in the plan + SUMMARY.
**Notes:** Consistent with Phase 13 APP-13 + Phase 14/15 patterns. No audit log inside the public repo (Phase 15 D-10 rationale carried forward).

### Recovery on a real positive

| Option | Description | Selected |
|--------|-------------|----------|
| Stop and ask before doing anything | Pause, show hit + commit, ask filter-repo vs rotate-and-document. Phase 14 D-19 deferral pattern. | ✓ |
| Default to rotate-and-document, no history rewrite | Revoke credential, document as known-rotated, continue. D-09 preserved. | |
| Block the flip until resolved out-of-band | Halt entirely, resume only after clean re-sweep. | |

**User's choice:** Stop and ask before doing anything (interactive checkpoint).
**Notes:** Keeps both options live — most positives will rotate-and-document, but high-blast-radius secrets can still get history-rewrite consideration without pre-committing.

### Repo scope

| Option | Description | Selected |
|--------|-------------|----------|
| Both repos, equal scrutiny | Re-run full history sweep on both. Strictest reading of FLIP-01. | |
| Light pass only on landing | Working-tree grep on landing (already public + Phase 15 already audited history). App repo gets the deep sweep. | ✓ |
| Skip landing entirely | Trust Phase 15/17 work; focus budget on app repo. | |

**User's choice:** Light pass on landing, deep sweep on app repo.
**Notes:** Landing repo is already public — history rewrite would be wasted effort. Working-tree grep catches anything added post-Phase-15 (Phase 17 deploys 2026-05-20 → 2026-05-23).

---

## Flip & publish sequencing

### Order of irreversible moves

| Option | Description | Selected |
|--------|-------------|----------|
| App repo public → Release publish → verify | Open the door, put out the welcome sign, walk in. Reads linearly. | ✓ |
| Release publish → app repo public → verify | Publish first; flip second; no inconsistent-state window after the flip. | |
| Atomic-feeling — both back-to-back | Minimize inconsistent window; no checkpoint between. | |

**User's choice:** App-repo flip first, then Release publish, then verify.
**Notes:** Natural reading order. ~30 sec inconsistent-state window (repo public, Release still draft) is acceptable — anonymous visitors in that window see a public repo with no release, which is a normal GitHub state.

### Mid-flip pause

| Option | Description | Selected |
|--------|-------------|----------|
| Yes — short pause to spot-check the repo | Interactive checkpoint after `gh repo edit --visibility public`. User opens public repo URL in incognito, confirms render, then we proceed. | ✓ |
| No pause — run straight through | Flip + publish back-to-back. If something's wrong we can re-private within seconds. | |

**User's choice:** Yes — short mid-flip pause + incognito spot-check.
**Notes:** Tiny safety margin. ~30 sec cost. If the repo looks broken post-flip (unlikely after Phase 14's work), we re-private without having compounded the issue with a published Release.

### Landing repo treatment

| Option | Description | Selected |
|--------|-------------|----------|
| Mark FLIP-03 satisfied, add a 'verify only' step | `gh repo view` confirms PUBLIC; note unexpected early flip in SUMMARY; no other action. | ✓ |
| Investigate when/how it flipped before treating FLIP-03 done | Look at audit log to understand timeline. ~5 min forensics. | |
| Just confirm it's public, move on | `gh repo view` and done. Skip investigation. | |

**User's choice:** Mark FLIP-03 satisfied, add a 'verify only' step (note in SUMMARY).
**Notes:** No re-flip; no forensics. The early flip likely happened during Phase 17 Vercel deploy work.

### Release notes final touch

| Option | Description | Selected |
|--------|-------------|----------|
| Use the locked notes as-is | Phase 16 5-bullet notes; publish without edits. | |
| Final read-through before publishing | Open `release-notes-v1.3.0.md` one more time; edit if needed. | ✓ |
| Quick patch — add a one-liner pointing back at landing | Pull visitors back to the story page deployed in Phase 17. | |

**User's choice:** Final human read-through before publishing.
**Notes:** Edits only if the user explicitly flags something at the read-through. Default path is publish-verbatim with zero changes.

---

## Anonymous-viewer verification evidence

### Verification surface

| Option | Description | Selected |
|--------|-------------|----------|
| Read the repo page + download the DMG + UpdateChecker works | Three checks covering repo render, DMG accessibility, in-app UpdateChecker live-test (404 → 200). | ✓ |
| Just the repo + DMG download | Skip UpdateChecker live-test. Tightest scope. | |
| Repo + DMG + UpdateChecker + landing-page CTA end-to-end | Add a fourth check: round-trip from `wrangleapp.dev` "Download for macOS" → public Release page. | |

**User's choice:** Read the repo page + download the DMG + UpdateChecker works (3 checks initially).
**Notes:** The landing-page CTA was added as a 4th check via the follow-up question below. Final: 4 checks (repo + DMG + UpdateChecker + landing CTA round-trip).

### Evidence format

| Option | Description | Selected |
|--------|-------------|----------|
| Inline in SUMMARY.md | Curl output, command transcripts directly in `18-SUMMARY.md`. Phase 16-02 template. | ✓ |
| Separate 18-VERIFY/ directory | Drop binary artifacts in `18-VERIFY/`. Matches Phase 16-02 second-mac screenshot shape. | |
| Mix — inline curl outputs, screenshots in a sub-dir | Best of both. | |

**User's choice:** Inline in SUMMARY.md.
**Notes:** Self-contained; no extra dirs unless an optional screenshot of the repo render is added (Claude's discretion).

### Logged-out test method

| Option | Description | Selected |
|--------|-------------|----------|
| Incognito / private window | Cmd+Shift+N. User drives, screenshot if useful. Same as a never-visited-before user. | ✓ |
| Pure curl/HTTP, no browser | Machine-readable evidence only. No screenshots. | |
| Both — curl primary, browser screenshot as backup | Text evidence + 1 incognito screenshot for skim-readers. | |

**User's choice:** Incognito / private window.
**Notes:** Driven live by user. Curl checks complement the browser-driven UI checks.

### Landing-page CTA round-trip

| Option | Description | Selected |
|--------|-------------|----------|
| Yes — visit `wrangleapp.dev` incognito, click Download, confirm Release lands | Closes Phase 17 D-10 LOCKED 404 loop. ~30 sec. | ✓ |
| No — GH-side verification is enough | Trust transitivity. | |

**User's choice:** Yes — add landing-page CTA round-trip as a 4th check.
**Notes:** Closes the Phase 17 D-10 LOCKED behavior loop in one observable user journey.

---

## Vendor / external-system cleanup

### LemonSqueezy scope

| Option | Description | Selected |
|--------|-------------|----------|
| Deactivate the Wrangle product only | LS dashboard → Products → Wrangle → deactivate. Keep store + account alive. | ✓ |
| Archive the entire store | Archive `jkrush.lemonsqueezy.com` store. | |
| Delete the LS account entirely | Full account closure. Irreversible. | |
| Note as out-of-band, don't gate the flip | Document as follow-up TODO. | |

**User's choice:** Deactivate the Wrangle product only.
**Notes:** Lowest-risk, reversible. Store + account stay alive.

### dl.wrangleapp.dev DNS

| Option | Description | Selected |
|--------|-------------|----------|
| Delete the CNAME / A record now | Remove from DNS provider. Reversible. | ✓ |
| Let it dangle | Leave the record alone. | |
| Point it at the GH Release URL via redirect | 308 redirect for old bookmarks. | |
| Note as out-of-band, don't gate the flip | Document as follow-up TODO. | |

**User's choice:** Delete the CNAME / A record now.
**Notes:** Clean cut. Old bookmarks rare enough that a clean NXDOMAIN is acceptable.

### Cleanup timing

| Option | Description | Selected |
|--------|-------------|----------|
| After the successful flip | Sweep → flip → verify → THEN LS deactivation + DNS deletion. Preserves easy rollback. | ✓ |
| Before the flip | Tighter "closed loop" story but loses rollback leverage. | |
| Parallel to verification | Save a few minutes; introduces in-flight contradictions. | |

**User's choice:** After the successful flip.
**Notes:** Vendor cleanups are tidy-up, not gating. Run only after verify PASSes so rollback leverage stays intact.

### Other cleanup

| Option | Description | Selected |
|--------|-------------|----------|
| Nothing else — close discussion | LS + DNS cover the surface. | ✓ |
| Yes — something else | Another external account or surface. | |

**User's choice:** Nothing else — close discussion.
**Notes:** No analytics keys, no monitoring, no sponsorship surface to retire. Phase 18 is clean.

---

## Claude's Discretion

Listed in CONTEXT.md `<decisions>` → "Claude's Discretion" section. Highlights:
- Exact wording of the noise-exemption table (Phase 13 APP-13 shape).
- Whether to also grep analytics keys (`plausible|fathom|posthog`) — recommended yes, costs nothing.
- Whether to capture an optional incognito screenshot at `18-VERIFY/repo-anonymous-render.png`.
- Plan boundary — 1 plan or 2; planner picks based on cohesion.
- Whether the SUMMARY commit folds in STATE.md + ROADMAP.md tracking writes (recommended yes, Phase 16-02 pattern).
- Wording of the "noted unexpected early flip" line in SUMMARY for the landing-repo confirmation.
- Whether to capture `gh release view --json` before AND after `--draft=false` (recommended yes).

## Deferred Ideas

Listed in CONTEXT.md `<deferred>`. Highlights:
- Investigating when/how the landing repo flipped public early (delta noted, not investigated).
- Public social/PH/Reddit announcement of v1.3.0 (out of scope per PROJECT.md posture).
- GitHub Actions CI for release automation (v1.4).
- Filter-repo strip of legacy LS / `wrangleapp.dev` history references (held at D-09; only opens at D-04 checkpoint).
- LS full account closure / store archive (default is product-only).
- Redirect `dl.wrangleapp.dev` to GH Release URL (rejected per D-13).
- Second-Mac re-verify (Phase 16 D-05 already attested).
- GitHub Sponsors / Buy Me a Coffee surface (PROJECT.md out-of-scope).
- `docs/release-checklist.md` post-Phase-18 publish-step doc update (v1.4 docs sweep).
