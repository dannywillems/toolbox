# zcash-dep-policy

Keep a consumer repo's governed Zcash crate pins aligned with their upstream
libraries, and warn in CI when they drift. Reusable as a **composite action** or
a **curl-downloaded script**.

## How it works

The source of truth for a library's version is the library's own upstream
repository at its default-branch HEAD; there is no separate central version
manifest. A pin is checked one of two ways:

- **Registry version pin** (e.g. `orchard = "0.14"`): compared against the
  library's `[package] version` on its `ref` branch.
- **Git pin via `[patch.crates-io]`** (e.g. librustzcash pinned to a `rev`):
  the pinned commit is compared against the `ref` branch HEAD commit, so a pin
  that has fallen behind `main` is reported as drift.

One script, `dep_policy.py` (stdlib only: `tomllib` + `urllib` + the `git` CLI
for `ls-remote`), driven by a per-repo `governed-libs.toml`. Subcommands:

- `check` — report drift; emit `::warning::` / `::error::` annotations.
- `rewrite-to-head` — repoint governed pins to branch HEAD so a follow-up
  `cargo check` builds against upstream HEAD.

## Use as an action

```yaml
- uses: actions/checkout@v6
  with:
    persist-credentials: false
- uses: dannywillems/toolbox/zcash-dep-policy@main # pin to a commit SHA
  with:
    command: check # or: rewrite-to-head
    # config:   .github/dep-policy/governed-libs.toml  (default)
    # manifest: <override consumer_manifest>           (optional)
    # allow:    .github/dep-policy/allow.toml           (default)
```

See [`examples/`](examples/) for full job-1 (consistency) and job-2
(HEAD-compatibility) workflows.

## Run locally

The same logic the action runs is available locally through one wrapper,
`zcash-dep-policy.sh`. Run it from your repo root so it finds
`.github/dep-policy/governed-libs.toml`:

```bash
# If you have the toolbox checked out:
path/to/toolbox/zcash-dep-policy/zcash-dep-policy.sh check
path/to/toolbox/zcash-dep-policy/zcash-dep-policy.sh rewrite-to-head

# Without a checkout (downloads the pinned script into ~/.cache, then runs it):
curl -fsSL https://raw.githubusercontent.com/dannywillems/toolbox/main/zcash-dep-policy/zcash-dep-policy.sh \
  | sh -s -- check
```

Pin the version with `ZCASH_DEP_POLICY_REF=<commit-sha>`. The wrapper uses the
`dep_policy.py` next to it when present (clone / action checkout), otherwise
downloads it. Requires `python3` (>= 3.11) and `git`; `curl` only when
downloading.

A consumer repo that inlines the script can run it directly instead:

```bash
python3 .github/dep-policy/dep_policy.py check
```

## Use via curl (script only)

```bash
curl -sSLO https://raw.githubusercontent.com/dannywillems/toolbox/main/zcash-dep-policy/dep_policy.py
python3 dep_policy.py check --config .github/dep-policy/governed-libs.toml
```

## Per-repo config (`governed-libs.toml`)

Place at `.github/dep-policy/governed-libs.toml` in the consumer repo.

| Key | Meaning |
| --- | --- |
| `consumer_manifest` | Manifest to read (e.g. `Cargo.toml` or `backend-lib/Cargo.toml`). |
| `consumer_tables` | Dependency tables to scan (`["dependencies"]` default, or `["workspace.dependencies"]`). |
| `head_rewrite_deps` | If `true`, `rewrite-to-head` also converts registry pins to git deps; if `false`, it only repoints `[patch.crates-io]` pins. |
| `[[library]]` | One per governed crate: `crate`, `repo` (`owner/name`), `ref` (branch), `manifest` (path within the repo), `severity` (`warn`/`error`). |

Two ready-to-edit configs:

- [`examples/governed-libs.workspace-patch.toml`](examples/governed-libs.workspace-patch.toml)
  — workspace + `[patch.crates-io]` (e.g. `zcash/wallet`).
- [`examples/governed-libs.simple.toml`](examples/governed-libs.simple.toml)
  — single crate with plain `[dependencies]` version pins.

## Allowlist (optional)

`.github/dep-policy/allow.toml` downgrades a crate from `error` to `warn`:

```toml
[[allow]]
crate = "zcash_primitives"
reason = "Holding at the current pin until PR #1234 lands"
```

## Limitations

- Version-pin comparison is against the declared requirement, not the resolved
  `Cargo.lock` graph, so transitive drift is not covered.
- `rewrite-to-head` builds against upstream HEAD; incompatible in-development
  requirements between sibling upstream crates can make `cargo check` fail for
  resolution reasons unrelated to the consumer's code.
