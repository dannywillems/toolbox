#!/usr/bin/env bash
# Check that a PR does not exceed a configurable line-change threshold.
#
# Excludes generated files (lock files, etc.) from the count.
# Exits 0 on success, 1 on failure, and prints a warning when the
# soft threshold is exceeded but the hard threshold is not.
#
# Environment variables (optional):
#   PR_SIZE_WARN   - soft threshold (default: 300)
#   PR_SIZE_FAIL   - hard threshold (default: 500)
#
# Usage: check-pr-size.sh <base-sha>
set -euo pipefail

base="${1:?Usage: check-pr-size.sh <base-sha>}"
warn_threshold="${PR_SIZE_WARN:-300}"
fail_threshold="${PR_SIZE_FAIL:-500}"

# Patterns for generated/vendored files to exclude from the count.
exclude_patterns=(
    "*.lock"
    "uv.lock"
    "poetry.lock"
    "package-lock.json"
    "yarn.lock"
    "pnpm-lock.yaml"
    "Cargo.lock"
)

# Build the pathspec exclusion arguments.
pathspec_args=()
for pattern in "${exclude_patterns[@]}"; do
    pathspec_args+=(":(exclude)${pattern}")
done

# Count added + removed lines, excluding generated files.
diff_stat=$(git diff --numstat "${base}...HEAD" -- . "${pathspec_args[@]}")

total=0
while IFS=$'\t' read -r added removed _path; do
    # Binary files show "-" for added/removed; skip them.
    if [ "$added" = "-" ] || [ "$removed" = "-" ]; then
        continue
    fi
    total=$((total + added + removed))
done <<< "$diff_stat"

echo "Total lines changed (excluding generated files): $total"

if [ "$total" -gt "$fail_threshold" ]; then
    echo "::error::PR is too large ($total lines changed, threshold: $fail_threshold)."
    echo "Consider splitting into smaller, focused PRs."
    exit 1
fi

if [ "$total" -gt "$warn_threshold" ]; then
    echo "::warning::PR is getting large ($total lines changed, warn threshold: $warn_threshold)."
    echo "Consider whether this can be split into smaller PRs."
fi

echo "PR size check passed."
