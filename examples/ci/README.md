# CI/CD Security Templates

Automated checks to catch security regressions in your agentic AI configuration.

## Available Templates

### `security-lint.yml` — GitHub Actions Workflow

Runs on every push and PR to check:
- No plaintext secrets in tracked files
- Protected config files haven't been modified without review
- Prompt integrity hashes match baseline
- No dangerous patterns in hook configurations
- Claude/agent config files are present and valid

### `prompt-integrity-check.sh` — Standalone Script

Can be run locally or in any CI system:

```bash
# Generate baseline (run once, commit the output)
./prompt-integrity-check.sh --baseline

# Check against baseline (run in CI)
./prompt-integrity-check.sh --check
```

## Setup

### GitHub Actions

```bash
mkdir -p .github/workflows
cp examples/ci/security-lint.yml .github/workflows/
cp examples/ci/prompt-integrity-check.sh scripts/
chmod +x scripts/prompt-integrity-check.sh

# Generate initial baseline
./scripts/prompt-integrity-check.sh --baseline
git add .prompt-integrity-baseline
git commit -m "chore: add prompt integrity baseline"
```

### Other CI Systems

The `prompt-integrity-check.sh` script is CI-agnostic. Call it from your pipeline:

```yaml
# GitLab CI example
security-check:
  script:
    - ./scripts/prompt-integrity-check.sh --check
```
