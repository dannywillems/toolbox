#!/usr/bin/env bash
# check-commit.sh — Verify CHANGELOG.md hygiene in pull requests.
#
# Checks:
#   1. CHANGELOG.md changes are in their own dedicated commit
#   2. Commit hashes referenced in new entries exist in the repo
#   3. Commit link URLs match their reference keys
#
# Usage:
#   check-commit.sh <base-ref>
#   check-commit.sh origin/main
#   check-commit.sh abc1234
#
# Environment variables:
#   CHANGELOG_FILE  Path to the changelog file (default: CHANGELOG.md)
#
# Exit codes:
#   0  All checks passed
#   1  One or more checks failed
#   2  Invalid arguments
#
# Examples:
#   # In CI (GitHub Actions):
#   check-commit.sh "${{ github.event.pull_request.base.sha }}"
#
#   # Locally, check current branch against main:
#   check-commit.sh origin/main
#
# Download:
#   curl -sSLO https://raw.githubusercontent.com/dannywillems/toolbox/v1/changelog/check-commit.sh
#   chmod +x check-commit.sh
#
# License: MIT

set -euo pipefail

CHANGELOG_FILE="${CHANGELOG_FILE:-CHANGELOG.md}"

# ---------- help ----------

usage() {
    sed -n '2,/^$/{ s/^# //; s/^#$//; p }' "$0"
}

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
    usage
    exit 0
fi

# ---------- args ----------

if [[ $# -lt 1 ]]; then
    echo "Error: missing base ref." >&2
    echo "Usage: check-commit.sh <base-ref>" >&2
    exit 2
fi

base="$1"
errors=0

# Helper: emit error in GitHub Actions annotation format if running in CI,
# otherwise plain stderr.
err() {
    if [[ -n "${GITHUB_ACTIONS:-}" ]]; then
        echo "::error::$1"
    else
        echo "ERROR: $1" >&2
    fi
    errors=$((errors + 1))
}

# ---------- check 1: dedicated commits ----------

for commit in $(git log --format=%H "${base}..HEAD"); do
    files=$(git diff-tree --no-commit-id --name-only -r "$commit")
    if echo "$files" | grep -q "^${CHANGELOG_FILE}$"; then
        file_count=$(echo "$files" | wc -l | tr -d ' ')
        if [[ "$file_count" -gt 1 ]]; then
            short=$(git rev-parse --short "$commit")
            err "Commit ${short} modifies ${CHANGELOG_FILE} alongside other files. Changelog changes must be in their own dedicated commit."
        fi
    fi
done

# ---------- check 2: referenced commit hashes exist ----------

changelog_diff=$(git diff "${base}..HEAD" -- "$CHANGELOG_FILE" \
    | grep "^+" | grep -v "^+++" || true)

inline_hashes=$(echo "$changelog_diff" \
    | grep -oE '\(\[([0-9a-f]{7,})\]' \
    | grep -oE '[0-9a-f]{7,}' | sort -u || true)

for hash in $inline_hashes; do
    if ! git cat-file -t "$hash" >/dev/null 2>&1; then
        err "Commit ${hash} referenced in ${CHANGELOG_FILE} does not exist in the repository."
    fi
done

# ---------- check 3: link URLs match keys ----------

link_lines=$(echo "$changelog_diff" \
    | grep -E '^\+\[[0-9a-f]{7,}\]: https://.*commit/' || true)

while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    key=$(echo "$line" \
        | grep -oE '\[([0-9a-f]{7,})\]' | head -1 \
        | tr -d '[]')
    url_hash=$(echo "$line" \
        | grep -oE 'commit/[0-9a-f]{7,}' \
        | sed 's|commit/||')
    if [[ -n "$key" && -n "$url_hash" && "$key" != "$url_hash" ]]; then
        err "Link [${key}] points to commit/${url_hash} but should point to commit/${key}."
    fi
done <<< "$link_lines"

# ---------- summary ----------

if [[ "$errors" -gt 0 ]]; then
    echo "Found ${errors} changelog error(s)."
    exit 1
fi

echo "All changelog checks passed."
