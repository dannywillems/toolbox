# toolbox

Reusable CI/CD and development scripts. Download any script with `curl` and
use it in your projects.

## Scripts

| Script | Description |
| --- | --- |
| [changelog/check-commit.sh](changelog/check-commit.sh) | Enforce changelog hygiene in PRs |
| [pr-hygiene/check-pr-size.sh](pr-hygiene/check-pr-size.sh) | Fail PRs that exceed a line-change threshold |
| [pr-hygiene/check-title-length.sh](pr-hygiene/check-title-length.sh) | Enforce commit title length (max 80 chars) |
| [pr-hygiene/check-no-fixup.sh](pr-hygiene/check-no-fixup.sh) | Reject fixup/squash/WIP commits |
| [pr-hygiene/check-commit-body.sh](pr-hygiene/check-commit-body.sh) | Require commit body for large changes |

## Usage

### Download and run

```bash
curl -sSLO https://raw.githubusercontent.com/dannywillems/toolbox/main/changelog/check-commit.sh
chmod +x check-commit.sh
./check-commit.sh origin/main
```

### Pin to exact commit

Replace `main` with a specific commit SHA to pin to an exact version.

Documentation for each script (usage, environment variables, examples) is in
the header comments of the script files themselves.

## License

MIT
