# toolbox

Reusable CI/CD and development scripts. Download any script with `curl` and
use it in your projects.

## Scripts

| Script | Description |
| --- | --- |
| [changelog/check-commit.sh](#changelogcheck-commitsh) | Enforce changelog hygiene in PRs |

## Usage

### Download and run

```bash
curl -sSLO https://raw.githubusercontent.com/dannywillems/toolbox/v1/changelog/check-commit.sh
chmod +x check-commit.sh
./check-commit.sh origin/main
```

### Pin to exact version

Replace `v1` with a specific tag (e.g., `v1.0.0`) to pin to an exact release.

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
          curl -sSLO https://raw.githubusercontent.com/dannywillems/toolbox/v1/changelog/check-commit.sh
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

## Versioning

Scripts use major version tags (`v1`, `v2`) following the same convention as
GitHub Actions. The `v1` tag always points to the latest `v1.x.x` release.

- Use `v1` for automatic minor/patch updates
- Use `v1.0.0` for exact version pinning

## License

MIT
