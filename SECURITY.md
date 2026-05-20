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

<!-- rotated-tokens-section -->
