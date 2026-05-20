# Security Policy

Thanks for taking the time to responsibly disclose security issues in Wrangle.

## How to report

Please use GitHub's private vulnerability reporting flow. Open the repository's **Security** tab and click **Report a vulnerability**, or go directly to [github.com/J-Krush/wrangle/security/advisories/new](https://github.com/J-Krush/wrangle/security/advisories/new) to file a GitHub Security Advisories report. Reports stay private between you and the maintainer until a fix is published.

Please do not file security issues in the public issue tracker.

## What counts as a vulnerability

- Remote code execution triggered by opening a markdown, configuration, or workspace file.
- Sandbox escape or unintended access to files outside the user-granted security-scoped bookmarks.
- Credential, token, or API-key leakage through logs, exports, the embedded terminal, or rendered content.
- Persistent XSS or script injection in rendered markdown / HTML preview surfaces.
- Privilege escalation via SwiftTerm-hosted child processes or shell integration.

## Known historical URLs in git history

The pre-v1.3 commit history contains references to two URL families that no
longer appear in the current source tree:

- **`wrangleapp.dev/api/trial/activate` and `/validate`** — Endpoints used by
  the v1.0.x trial flow. These were public URLs; the trial check used
  machine-ID + server-side validation with no client-side credential. The
  server-side flow was retired when v1.3 removed the trial gate.
- **`api.lemonsqueezy.com/v1/licenses/activate` and `/validate`** — The
  LemonSqueezy public license-validation API. The Wrangle binary never
  embedded a bearer token; all auth was server-side and has been retired with
  the v1.3 OSS pivot.

Neither family contained client-side credentials. They are documented here
for transparency: a reader running `git log -p` against pre-v1.3 commits will
see these URLs, and this section explains why they are not a security
concern. If you discover an actual credential leak in any commit, please
report it via [GitHub Security Advisories](https://github.com/J-Krush/wrangle/security/advisories/new).
