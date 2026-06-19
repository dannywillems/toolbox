#!/usr/bin/env sh
# Run the Zcash dependency-version policy locally or in CI.
#
# Single entrypoint shared by the composite action and by local developers, so
# both run exactly the same logic. It locates dep_policy.py next to this script
# (the clone / action checkout case); if absent, it downloads the script from
# the toolbox into a cache directory. All arguments are forwarded verbatim to
# dep_policy.py and executed against the current working directory, so the local
# repo's .github/dep-policy/governed-libs.toml and manifest are used.
#
# Usage (run from your repo root):
#   zcash-dep-policy.sh check
#   zcash-dep-policy.sh rewrite-to-head
#   zcash-dep-policy.sh check --config path/to/governed-libs.toml
#
# Pin the downloaded script with ZCASH_DEP_POLICY_REF=<commit-sha-or-branch>
# (default: main). Requires python3 (>= 3.11) and git on PATH; curl is needed
# only when the script must be downloaded.
set -eu

ref="${ZCASH_DEP_POLICY_REF:-main}"
raw_url="https://raw.githubusercontent.com/dannywillems/toolbox/${ref}/zcash-dep-policy/dep_policy.py"

CDPATH=''
script_dir=$(cd -- "$(dirname -- "$0")" && pwd)
py="${script_dir}/dep_policy.py"

if [ ! -f "$py" ]; then
    cache_dir="${XDG_CACHE_HOME:-${HOME}/.cache}/zcash-dep-policy"
    mkdir -p "$cache_dir"
    py="${cache_dir}/dep_policy-${ref}.py"
    if [ ! -f "$py" ]; then
        echo "zcash-dep-policy: downloading dep_policy.py (ref ${ref})" >&2
        curl -fsSL "$raw_url" -o "$py"
    fi
fi

exec python3 "$py" "$@"
