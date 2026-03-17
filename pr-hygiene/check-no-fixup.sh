#!/usr/bin/env bash
# Check that no fixup/squash/WIP commits remain in the PR.
# Skips merge commits.
#
# Usage: check-no-fixup.sh <base-sha>
set -euo pipefail

base="${1:?Usage: check-no-fixup.sh <base-sha>}"
errors=0

for commit in $(git log --no-merges --format=%H "${base}..HEAD"); do
    subject=$(git log -1 --format=%s "$commit")
    short=$(git log -1 --format=%h "$commit")

    case "$subject" in
        fixup!*|squash!*|WIP:*|WIP\ *|wip:*|wip\ *)
            echo "::error::Commit $short: fixup/squash/WIP commits must be cleaned up before merge."
            echo "  Title: $subject"
            errors=$((errors + 1))
            ;;
    esac
done

if [ "$errors" -gt 0 ]; then
    echo "Found $errors fixup/WIP commit(s)."
    exit 1
fi

echo "No fixup/squash/WIP commits found."
