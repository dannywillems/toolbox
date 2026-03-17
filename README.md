# toolbox

Reusable CI/CD and development scripts. Download any script with `curl` and
use it in your projects.

## Scripts

| Script | Description |
| --- | --- |
| [changelog/check-commit.sh](#changelogcheck-commitsh) | Enforce changelog hygiene in PRs |
| [pr-hygiene/check-pr-size.sh](#pr-hygienecheck-pr-sizesh) | Fail PRs that exceed a line-change threshold |
| [pr-hygiene/check-title-length.sh](#pr-hygienecheck-title-lengthsh) | Enforce commit title length (max 80 chars) |
| [pr-hygiene/check-no-fixup.sh](#pr-hygienecheck-no-fixupsh) | Reject fixup/squash/WIP commits |
| [pr-hygiene/check-commit-body.sh](#pr-hygienecheck-commit-bodysh) | Require commit body for large changes |

## Usage

### Download and run

```bash
curl -sSLO https://raw.githubusercontent.com/dannywillems/toolbox/main/changelog/check-commit.sh
chmod +x check-commit.sh
./check-commit.sh origin/main
```

### Pin to exact commit

Replace `main` with a specific commit SHA to pin to an exact version.

## Scripts Reference

### changelog/check-commit.sh

Verifies CHANGELOG.md hygiene in pull requests:

1. CHANGELOG.md changes are in their own dedicated commit (not mixed with code)
2. Commit hashes referenced in changelog entries exist in the repository
3. Commit link URLs match their reference keys

**Usage:**

```bash
check-commit.sh <base-ref>
```

**Environment variables:**

| Variable | Default | Description |
| --- | --- | --- |
| `CHANGELOG_FILE` | `CHANGELOG.md` | Path to the changelog file |

**GitHub Actions example:**

```yaml
jobs:
  changelog:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
      - name: Check changelog commits
        run: |
          curl -sSLO https://raw.githubusercontent.com/dannywillems/toolbox/main/changelog/check-commit.sh
          chmod +x check-commit.sh
          ./check-commit.sh "${{ github.event.pull_request.base.sha }}"
```

**Local usage:**

```bash
# Check current branch against main
./check-commit.sh origin/main

# Check against a specific commit
./check-commit.sh abc1234
```

### pr-hygiene/check-pr-size.sh

Checks that a PR does not exceed a configurable line-change threshold.
Excludes generated files (lock files) from the count.

**Usage:**

```bash
check-pr-size.sh <base-sha>
```

**Environment variables:**

| Variable | Default | Description |
| --- | --- | --- |
| `PR_SIZE_WARN` | `300` | Soft threshold (warning, does not fail) |
| `PR_SIZE_FAIL` | `500` | Hard threshold (fails the check) |

### pr-hygiene/check-title-length.sh

Checks that all commit titles (first line) are at most 80 characters.
Skips merge commits.

**Usage:**

```bash
check-title-length.sh <base-sha>
```

### pr-hygiene/check-no-fixup.sh

Checks that no `fixup!`, `squash!`, or `WIP` commits remain in the PR.
These must be cleaned up (rebased/squashed) before merge. Skips merge commits.

**Usage:**

```bash
check-no-fixup.sh <base-sha>
```

### pr-hygiene/check-commit-body.sh

Checks that commits with 20 or more lines changed include a non-empty commit
body. Small commits can have a title-only message. Skips merge commits.

**Usage:**

```bash
check-commit-body.sh <base-sha>
```

### PR hygiene: GitHub Actions example

Use all four PR hygiene scripts together in a single workflow. The PR size
check runs as a separate job, while commit message checks run sequentially
in one job.

```yaml
name: PR hygiene checks
on:
  pull_request:
    types: [assigned, opened, synchronize, reopened]
    branches:
      - main
  merge_group:
    types: [checks_requested]

jobs:
  check-pr-size:
    name: Check PR size
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v6
        with:
          fetch-depth: 0
      - name: Download script
        run: |
          curl -sSLO "https://raw.githubusercontent.com/dannywillems/toolbox/main/pr-hygiene/check-pr-size.sh"
          chmod +x check-pr-size.sh
      - name: Check PR size
        run: ./check-pr-size.sh "${{ github.event.pull_request.base.sha }}"

  check-commit-messages:
    name: Check commit messages
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v6
        with:
          fetch-depth: 0
      - name: Download scripts
        run: |
          for script in check-title-length.sh check-no-fixup.sh check-commit-body.sh; do
            curl -sSLO "https://raw.githubusercontent.com/dannywillems/toolbox/main/pr-hygiene/${script}"
            chmod +x "${script}"
          done
      - name: Check title length
        run: ./check-title-length.sh "${{ github.event.pull_request.base.sha }}"
      - name: Check no fixup/WIP commits
        run: ./check-no-fixup.sh "${{ github.event.pull_request.base.sha }}"
      - name: Check commit body on large changes
        run: ./check-commit-body.sh "${{ github.event.pull_request.base.sha }}"
```

## License

MIT
