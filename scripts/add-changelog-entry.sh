#!/bin/bash
set -euo pipefail

# Insert a new ChangelogEntry at the top of WhatsNewChangelog.changelog.
# Used by the "Prepare Release" workflow so a release's What's New entry is
# created from form inputs, but also runnable locally.
#
# Usage:
#   scripts/add-changelog-entry.sh \
#     --version 1.3.2 \
#     --date "July 7, 2026" \
#     --category fixed \            # new | improved | fixed
#     --notes-file bullets.txt \    # one bullet per line (blank lines ignored)
#     [--file wrangle/App/WhatsNewChangelog.swift]

VERSION=""; DATE=""; CATEGORY="fixed"; NOTES_FILE=""
FILE="wrangle/App/WhatsNewChangelog.swift"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --version)    VERSION="$2"; shift 2;;
        --date)       DATE="$2"; shift 2;;
        --category)   CATEGORY="$2"; shift 2;;
        --notes-file) NOTES_FILE="$2"; shift 2;;
        --file)       FILE="$2"; shift 2;;
        *) echo "Unknown argument: $1"; exit 1;;
    esac
done

[[ -n "$VERSION" ]]    || { echo "Error: --version required"; exit 1; }
[[ -n "$DATE" ]]       || { echo "Error: --date required"; exit 1; }
[[ -n "$NOTES_FILE" && -f "$NOTES_FILE" ]] || { echo "Error: --notes-file must point to an existing file"; exit 1; }
[[ -f "$FILE" ]]       || { echo "Error: $FILE not found"; exit 1; }

case "$CATEGORY" in
    new)      CASE=".new";;
    improved) CASE=".improved";;
    fixed)    CASE=".fixed";;
    *) echo "Error: --category must be new|improved|fixed (got '$CATEGORY')"; exit 1;;
esac

# Build the items list. Each non-empty line becomes a Swift string literal;
# backslashes and double-quotes are escaped for the literal.
ITEMS=""
while IFS= read -r line || [[ -n "$line" ]]; do
    [[ -z "${line//[[:space:]]/}" ]] && continue
    esc=$(printf '%s' "$line" | sed 's/\\/\\\\/g; s/"/\\"/g')
    ITEMS+="                    \"${esc}\","$'\n'
done < "$NOTES_FILE"
[[ -n "$ITEMS" ]] || { echo "Error: no non-empty bullet lines in $NOTES_FILE"; exit 1; }

ENTRY="        ChangelogEntry(
            version: \"${VERSION}\",
            date: \"${DATE}\",
            sections: [
                ChangelogSection(category: ${CASE}, items: [
${ITEMS}                ]),
            ],
            cta: nil
        ),"

ANCHOR="    private static let changelog: [ChangelogEntry] = ["
grep -qF "$ANCHOR" "$FILE" || { echo "Error: anchor line not found in $FILE"; exit 1; }

# Insert ENTRY on the line after the anchor. Pure-bash line walk — portable
# across BSD (macOS) and GNU (Linux) awk/sed, which disagree on multi-line
# handling. `read -r` keeps backslashes literal; the trailing `|| [[ -n ]]`
# emits a final line with no newline.
inserted=""
{
    while IFS= read -r current || [[ -n "$current" ]]; do
        printf '%s\n' "$current"
        if [[ -z "$inserted" && "$current" == *"$ANCHOR"* ]]; then
            printf '%s\n' "$ENTRY"
            inserted=1
        fi
    done < "$FILE"
} > "$FILE.tmp"
[[ -n "$inserted" ]] || { rm -f "$FILE.tmp"; echo "Error: failed to insert (anchor not matched during walk)"; exit 1; }
mv "$FILE.tmp" "$FILE"

echo "Inserted v${VERSION} (${CATEGORY}) changelog entry into $FILE"
