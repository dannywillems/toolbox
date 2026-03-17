#!/usr/bin/env bash
# Check that commit titles do not exceed 80 characters.
# Skips merge commits.
#
# Usage: check-title-length.sh <base-sha>
set -euo pipefail

base="${1:?Usage: check-title-length.sh <base-sha>}"
errors=0

for commit in $(git log --no-merges --format=%H "${base}..HEAD"); do
    subject=$(git log -1 --format=%s "$commit")
    short=$(git log -1 --format=%h "$commit")

    title_len=${#subject}
    if [ "$title_len" -gt 80 ]; then
        echo "::error::Commit $short: title is $title_len chars (max 80)."
        echo "  Title: $subject"
        errors=$((errors + 1))
    fi
done

if [ "$errors" -gt 0 ]; then
    echo "Found $errors title length error(s)."
    exit 1
fi

echo "All commit titles are within 80 characters."
