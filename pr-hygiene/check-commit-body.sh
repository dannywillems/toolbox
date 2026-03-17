#!/usr/bin/env bash
# Check that commits with 20+ lines changed include a non-empty body.
# Skips merge commits.
#
# Usage: check-commit-body.sh <base-sha>
set -euo pipefail

base="${1:?Usage: check-commit-body.sh <base-sha>}"
errors=0

for commit in $(git log --no-merges --format=%H "${base}..HEAD"); do
    short=$(git log -1 --format=%h "$commit")
    body=$(git log -1 --format=%b "$commit")

    lines_changed=$(git diff-tree --no-commit-id --numstat -r "$commit" \
        | awk '{ s += $1 + $2 } END { print s+0 }')
    body_trimmed=$(echo "$body" | sed '/^$/d' | head -1)

    if [ "$lines_changed" -ge 20 ] && [ -z "$body_trimmed" ]; then
        echo "::error::Commit $short: $lines_changed lines changed but no commit body."
        echo "  Commits with 20+ lines changed should include a description."
        errors=$((errors + 1))
    fi
done

if [ "$errors" -gt 0 ]; then
    echo "Found $errors commit(s) missing a body."
    exit 1
fi

echo "All large commits have a body."
