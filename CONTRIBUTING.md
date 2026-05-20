# Contributing to Wrangle

Thanks for your interest in Wrangle. A few honest expectations up front, then the
practical bits.

## What this project is (and isn't)

Wrangle is a **personal portfolio project** that recently flipped from a paid
macOS app to free and open source. It is maintained on a **best-effort** basis
by one person in between other work — please expect response times measured in
**days to weeks, not hours**, and assume any non-trivial PR will sit in the
review queue for a while before it gets attention.

Small, focused contributions that fix bugs or polish existing features are most
likely to land quickly. **Major architectural changes are unlikely to be
accepted** — the project has a deliberate shape (NSTextView-backed editor,
SwiftTerm-embedded terminal, SwiftData persistence, `@Observable` + `@MainActor`
MVVM) and breaking from that shape is almost always more disruptive than
helpful. If you're not sure whether something falls in that bucket, please open
a feature request first and ask before investing time.

This isn't an open-collaboration project trying to grow a contributor community.
It's a real tool I use myself, shared publicly because doing so is more
interesting than letting it sit in a private repo.

## Dev environment setup

Wrangle is a native macOS application targeting Apple Silicon and macOS 15+
(Sequoia).

1. Install **Xcode 16** or newer.
2. Clone the repo and open the project:
   ```
   git clone https://github.com/J-Krush/wrangle.git
   cd wrangle
   open Wrangle.xcodeproj
   ```
3. Build and run with **Cmd+R**.

A few things worth knowing:

- **SwiftTerm** (the embedded terminal) is the only third-party dependency and
  resolves automatically via Swift Package Manager the first time Xcode opens
  the project — no manual install step.
- The **App Sandbox entitlement is intentionally disabled**. The embedded
  terminal launches child shell processes, which sandboxing forbids; the trade
  is correctness over Mac App Store eligibility. If you change this, the
  terminal will silently stop working.
- Tests run with **Cmd+U**. There's no CI yet — please run the suite locally
  before opening a PR.

## Filing issues

There are two issue templates, both under [`.github/ISSUE_TEMPLATE/`](.github/ISSUE_TEMPLATE/):

- **[Bug report](.github/ISSUE_TEMPLATE/bug_report.md)** — use this when
  something doesn't work as expected. Please include steps to reproduce, your
  macOS version, and your Wrangle version. A screenshot helps almost every
  time.
- **[Feature request](.github/ISSUE_TEMPLATE/feature_request.md)** — use this
  to propose new capabilities. Wrangle is purpose-built for AI development
  workflows, so the template asks you to ground the proposal in that context.

## Pull request process

1. Fork the repo and create a topic branch off `main`.
2. Make your changes in small, reviewable commits.
3. Open a PR using the [pull request template](.github/PULL_REQUEST_TEMPLATE.md).
4. Expect best-effort review — see "What this project is" above.

Please don't open a PR that mixes unrelated changes. Each PR should solve one
problem.

## Coding conventions

Wrangle uses modern Swift concurrency (`async/await`, `@Observable`,
`@MainActor`), SwiftUI for the UI layer, and a custom `NSTextView`-backed
editor for the rendered-markdown surface. The full set of conventions and the
constraints that flow from those choices live in two places:

- **[CLAUDE.md](CLAUDE.md)** at the repo root — project-wide conventions,
  including the `@Observable` + `@MainActor` rule, sidebar/overview section
  invariants, NSTextView constraints, and the AI-aware file-handling pattern.
- **[docs/coding-patterns.md](docs/coding-patterns.md)** — modern-concurrency
  rules with worked code examples (Task-based debouncing, cached
  `NSRegularExpression`, why `MainActor.run` over `DispatchQueue.main.async`,
  etc.).

Please read both before opening a non-trivial PR. CLAUDE.md is the source of
truth when the two ever drift.

## How work gets planned (the `.planning/` workflow)

This repo uses a structured planning workflow rooted in [`.planning/`](.planning/),
and that directory is intentionally public — it's part of the project, not
internal scaffolding hidden from contributors.

- High-level project shape lives in [`.planning/PROJECT.md`](.planning/PROJECT.md)
  and [`.planning/ROADMAP.md`](.planning/ROADMAP.md).
- Numbered milestone requirements live in [`.planning/REQUIREMENTS.md`](.planning/REQUIREMENTS.md).
- Each phase has its own directory under [`.planning/phases/`](.planning/phases/)
  containing a `CONTEXT.md` (what was known + decided going in), one or more
  `PLAN.md` files (the executable plan), and a matching `SUMMARY.md` (what
  actually shipped).

Maintainer work flows through that loop: gather context → plan → execute →
summarize. **External contributors do not need to author `.planning/` files** —
issues and PRs go through the normal GitHub flow described above. The
`.planning/` tree is here as transparency, so anyone reading the repo can see
how decisions were made (including the OSS pivot decided in Phase 13), not as
bureaucracy you have to opt into.

## Security disclosures

For vulnerabilities, please follow the private disclosure flow described in
[SECURITY.md](SECURITY.md) — don't file security issues on the public tracker.

## License

All contributions are licensed under the MIT License — see [LICENSE](LICENSE).
By opening a pull request you confirm you have the right to release your
contribution under those terms.
