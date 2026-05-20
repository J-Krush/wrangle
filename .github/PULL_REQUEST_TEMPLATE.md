<!--
Thanks for opening a PR. Please review CONTRIBUTING.md before submitting —
in particular, expect best-effort review on the order of days-to-weeks, and
note that major architectural changes are unlikely to be accepted without
an upfront discussion in an issue.

Keep each PR focused on one problem. Mixed-purpose PRs will be asked to
split before review.
-->

## Description

<!-- What does this PR do, and why? Link any related issues with
"Fixes #123" / "Refs #123". -->

## Screenshots (if UI)

<!-- For any change that touches user-visible UI, drag and drop a before /
after screenshot or a short screen recording here. Rendered-markdown and
editor changes are particularly hard to review without visuals. Delete this
section if the change has no UI surface. -->

## Tests

- [ ] Tests pass locally (Cmd+U in Xcode)
- [ ] Added or updated unit tests for the changed behavior, where practical
- [ ] Verified manually on macOS 15+ (Sequoia) Apple Silicon
- [ ] If the change touches the embedded terminal or NSTextView editor,
      sanity-checked across a multi-window session

## Checklist

- [ ] Follows [CLAUDE.md](../CLAUDE.md) conventions (`@Observable` +
      `@MainActor`, SwiftUI lifecycle, sidebar/overview invariants)
- [ ] Follows [docs/coding-patterns.md](../docs/coding-patterns.md)
      (modern-concurrency rules, cached regex, no sync I/O on main)
- [ ] No new build warnings introduced
- [ ] Updated documentation if behavior changed (CLAUDE.md, docs/, or
      inline comments where the *why* isn't obvious)
- [ ] PR is scoped to a single problem (split mixed changes before review)
