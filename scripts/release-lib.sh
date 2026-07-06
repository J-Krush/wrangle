#!/bin/bash
# Shared helpers for the release scripts (build-release.sh, create-dmg.sh).
#
# Signature/Gatekeeper *reads* run immediately after an artifact is written
# (export, codesign --sign, stapler staple) can transiently fail while the
# bundle's metadata is still settling on disk — codesign/spctl print an error
# instead of the expected output, and a one-shot `grep` check then fails a
# perfectly valid artifact. These helpers retry such reads a few times before
# giving up, so a not-yet-settled read never halts a long build or forces a
# re-notarization cycle.

# retry MAX DELAY LABEL -- CMD [ARGS...]
#   Run CMD until it succeeds or MAX attempts are exhausted, sleeping DELAY
#   seconds between tries. Returns CMD's last exit status. Progress goes to
#   stderr so it never pollutes a value being captured from stdout.
retry() {
    local max=$1 delay=$2 label=$3
    shift 3
    [[ "${1:-}" == "--" ]] && shift
    local attempt=1 rc=0
    while true; do
        # Capture the command's status in the else branch: reading $? *after*
        # an `if cmd; then ...; fi` yields the if-statement's status (always 0
        # when no then-branch runs), not the command's — which would make a
        # genuinely failed check look like success.
        if "$@"; then
            return 0
        else
            rc=$?
        fi
        if (( attempt >= max )); then
            return "$rc"
        fi
        echo "   ${label}: not settled (attempt ${attempt}/${max}), retrying in ${delay}s..." >&2
        sleep "$delay"
        attempt=$((attempt + 1))
    done
}

# has_team_identifier ARTIFACT TEAM
#   True when ARTIFACT's code signature carries TeamIdentifier=TEAM. Pipefail in
#   the callers makes a transient codesign read (non-zero exit) propagate as a
#   failure so retry() will try again.
has_team_identifier() {
    codesign -dv --verbose=4 "$1" 2>&1 | grep -q "TeamIdentifier=$2"
}

# assert_team_identifier ARTIFACT TEAM
#   Verify (with retries) that ARTIFACT is signed by TEAM, or exit 1.
assert_team_identifier() {
    local artifact=$1 team=$2
    if ! retry 5 1 "signature for $artifact" -- has_team_identifier "$artifact" "$team"; then
        echo "FAIL: $artifact signature does not carry the expected TeamIdentifier=$team."
        echo "      Inspect with: codesign -dv --verbose=4 $artifact"
        exit 1
    fi
}
