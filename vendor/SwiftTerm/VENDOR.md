# Vendored SwiftTerm

Local copy of [migueldeicaza/SwiftTerm](https://github.com/migueldeicaza/SwiftTerm),
consumed by the Xcode project as a local Swift package instead of a remote
dependency so Wrangle can carry two bug fixes that Claude Code's alt-screen
TUI exposed.

- **Upstream version:** v1.11.2 (commit `b1262db`)
- **Trimmed:** only `Sources/SwiftTerm`, `Package.swift` (library target
  only), `LICENSE`, and `README.md` are kept. Upstream's sample apps,
  tests, benchmarks, fuzzer, and CLI tools are omitted, along with their
  remote dependencies.

## Local patches (candidates for upstreaming)

1. **`EscapeSequenceParser.swift`** — bytes `0x80-0x9f` arriving at a
   feed-chunk boundary while collecting an OSC/APC string are now treated
   as string payload (matching the in-chunk fast path) instead of C1
   controls. Previously a chunk boundary inside a multi-byte UTF-8
   character (e.g. the `0x9c` inside Claude Code's title spinner glyphs)
   terminated the OSC early and spilled the rest of the title into the
   screen buffer.

2. **`Terminal.swift` (`sendEvent`)** — SGR/SGR-pixel mouse "release"
   detection (`flags & 3 == 3`) now excludes motion events (bit 32).
   Previously hover motion reports were encoded as left-button releases,
   which made mouse-reporting TUIs treat hovering as clicking.

Regression coverage: `WrangleTests/SwiftTermVendorPatchTests.swift`.

## Updating

Diff `Sources/SwiftTerm` against the upstream tag you're moving to,
re-apply (or drop, if upstreamed) the two patches above, and keep
`SwiftTermVendorPatchTests` green. If both patches land upstream, delete
this directory and restore a pinned remote package dependency.
