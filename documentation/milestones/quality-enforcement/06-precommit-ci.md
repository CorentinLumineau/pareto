# M6: Pre-commit + CI Gates

> **Automated enforcement at every stage**

```
╔════════════════════════════════════════════════════════════════╗
║  Milestone: Pre-commit + CI Gates                               ║
║  Status:    ✅ COMPLETE                                         ║
║  Effort:    1 day                                               ║
║  ROI:       🟡 Medium                                           ║
╚════════════════════════════════════════════════════════════════╝
```

## Objective

Automate quality enforcement at every stage:
1. Pre-commit hooks (local, fast feedback)
2. CI/CD pipeline (PR quality gates)
3. Branch protection (block merges on failure)

## Tasks

### 1. Pre-commit Hooks with Lefthook

Install Lefthook:

```bash
pnpm add -D lefthook
```

Create `lefthook.yml`:

```yaml
# Lefthook configuration for pre-commit hooks

pre-commit:
  parallel: true
  commands:
    # TypeScript/JavaScript
    lint-ts:
      glob: "*.{ts,tsx,js,jsx}"
      run: pnpm eslint --fix {staged_files}
      stage_fixed: true

    typecheck-ts:
      glob: "*.{ts,tsx}"
      run: pnpm typecheck

    # Python
    lint-python:
      glob: "*.py"
      run: cd apps/workers && ruff check --fix {staged_files}
      stage_fixed: true

    typecheck-python:
      glob: "*.py"
      run: cd apps/workers && mypy {staged_files}

    # Go
    lint-go:
      glob: "*.go"
      run: cd apps/api && golangci-lint run --new-from-rev=HEAD~1

    # Format checks
    prettier:
      glob: "*.{json,md,yaml,yml}"
      run: pnpm prettier --check {staged_files}

pre-push:
  parallel: false
  commands:
    # Run full verification before push
    verify:
      run: make verify

commit-msg:
  commands:
    # Validate commit message format
    conventional:
      run: |
        MSG=$(cat {1})
        if ! echo "$MSG" | grep -qE '^(feat|fix|docs|style|refactor|test|chore|perf|ci|build|revert)(\(.+\))?: .+'; then
          echo "❌ Commit message must follow Conventional Commits format"
          echo "   Example: feat(api): add user authentication"
          exit 1
        fi
```

Initialize Lefthook:

```bash
pnpm lefthook install
```

### 2. GitHub Actions Quality Workflow

Create `.github/workflows/quality.yml`:

```yaml
name: Quality Gates

on:
  pull_request:
    branches: [main, develop]
  push:
    branches: [main, develop]

concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

jobs:
  verify:
    name: Quality Verification
    runs-on: ubuntu-latest

    services:
      postgres:
        image: postgres:18
        env:
          POSTGRES_USER: pareto
          POSTGRES_PASSWORD: pareto
          POSTGRES_DB: pareto_test
        ports:
          - 5432:5432
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5

      redis:
        image: redis:8
        ports:
          - 6379:6379
        options: >-
          --health-cmd "redis-cli ping"
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '22'
          cache: 'pnpm'

      - name: Setup pnpm
        uses: pnpm/action-setup@v4
        with:
          version: 9

      - name: Setup Go
        uses: actions/setup-go@v5
        with:
          go-version: '1.24'
          cache: true
          cache-dependency-path: apps/api/go.sum

      - name: Setup Python
        uses: actions/setup-python@v5
        with:
          python-version: '3.14'
          cache: 'pip'
          cache-dependency-path: apps/workers/pyproject.toml

      - name: Install dependencies
        run: make install

      - name: Install security tools
        run: |
          go install golang.org/x/vuln/cmd/govulncheck@latest
          pip install pip-audit bandit

      - name: Run quality verification
        run: make verify

      - name: Upload coverage reports
        if: always()
        uses: codecov/codecov-action@v4
        with:
          token: ${{ secrets.CODECOV_TOKEN }}
          fail_ci_if_error: false
          files: |
            apps/api/coverage.out
            apps/workers/coverage.xml
            apps/web/coverage/coverage-final.json
          flags: unittests
          verbose: true

  coverage-check:
    name: Coverage Ratchet
    runs-on: ubuntu-latest
    needs: verify

    steps:
      - name: Checkout
        uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Check coverage ratchet
        run: |
          # Ensure coverage never decreases
          ./scripts/verify/ratchet.sh

  security-scan:
    name: Security Scan
    runs-on: ubuntu-latest

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Run Trivy vulnerability scanner
        uses: aquasecurity/trivy-action@master
        with:
          scan-type: 'fs'
          ignore-unfixed: true
          severity: 'CRITICAL,HIGH'
          exit-code: '1'

      - name: Run CodeQL Analysis
        uses: github/codeql-action/analyze@v3
        with:
          languages: go, javascript, python
```

### 3. Branch Protection Rules

Configure in GitHub repository settings:

**Settings → Branches → Branch protection rules → Add rule**

For `main` and `develop`:

```
Branch name pattern: main

☑️ Require a pull request before merging
  ☑️ Require approvals: 1
  ☑️ Dismiss stale pull request approvals when new commits are pushed
  ☑️ Require review from Code Owners

☑️ Require status checks to pass before merging
  ☑️ Require branches to be up to date before merging
  Status checks:
    - verify
    - coverage-check
    - security-scan

☑️ Require conversation resolution before merging

☑️ Do not allow bypassing the above settings
```

### 4. PR Coverage Comments

Add coverage comments to PRs. Update `.github/workflows/quality.yml`:

```yaml
  coverage-comment:
    name: Coverage Comment
    runs-on: ubuntu-latest
    needs: verify
    if: github.event_name == 'pull_request'

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Download coverage artifacts
        uses: actions/download-artifact@v4
        with:
          name: coverage-reports

      - name: Add coverage comment
        uses: MishaKav/pytest-coverage-comment@main
        with:
          pytest-coverage-path: apps/workers/coverage.xml
          title: Python Coverage Report
          badge-title: Coverage
          hide-badge: false
          hide-report: false
```

### 5. Update Makefile

Add hook installation to Makefile:

```makefile
# Install development environment including hooks
install:
	@echo "Installing dependencies..."
	pnpm install
	cd apps/api && go mod download
	cd apps/workers && pip install -e ".[dev]"
	@echo "Installing pre-commit hooks..."
	pnpm lefthook install
	@echo "Dependencies and hooks installed!"

# Reinstall hooks if needed
hooks:
	pnpm lefthook install
```

## Success Criteria

- [x] Pre-commit hooks run on every commit
- [x] Pre-push hooks run full verification
- [x] GitHub Actions workflow created
- [ ] Branch protection blocks failing PRs (requires repo admin setup)
- [ ] Coverage comments on PRs (requires CODECOV_TOKEN)
- [x] Security scanning in CI (Trivy)

## Deliverables

```
lefthook.yml (new)
.github/workflows/quality.yml (new)
Makefile (updated)
scripts/verify/ratchet.sh (new)
```

## Testing

```bash
# Test pre-commit hooks
git add .
git commit -m "feat: test commit"
# Should run lint + typecheck on staged files

# Test pre-push hooks
git push
# Should run full make verify

# Test CI
# Create a PR and verify workflow runs
```

## Branch Protection Checklist

After CI is working:

- [ ] Enable branch protection on `main`
- [ ] Enable branch protection on `develop`
- [ ] Require `verify` status check
- [ ] Require `coverage-check` status check
- [ ] Require `security-scan` status check
- [ ] Require at least 1 approval
- [ ] Require conversation resolution

---

**Previous**: [M5: Security Scanning](./05-security-scanning.md)
**Back to**: [Initiative README](./README.md)
