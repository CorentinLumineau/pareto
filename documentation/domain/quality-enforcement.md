# Quality Enforcement - Requirements

> **Zero-regression quality gates for the Pareto Comparator project**

## Business Value

- **Problem**: Code quality can degrade over time without enforcement
- **Solution**: Automated quality gates at every stage (local, pre-commit, CI)
- **Impact**: Maintain high-quality, maintainable codebase that never regresses

## Core Principle

**Quality Ratchet**: Once a quality metric is achieved, it can never go down. The codebase only moves forward.

---

## Quality Metrics

### 1. Test Coverage: >90% Hard Fail

| Component | Tool | Threshold | Enforcement |
|-----------|------|-----------|-------------|
| Go API | `go test -cover` | 90% | Per-package |
| Python Workers | `pytest-cov` | 90% | Per-module |
| TypeScript (Web) | `vitest --coverage` | 90% | Per-package |
| TypeScript (Mobile) | `jest --coverage` | 90% | Per-package |
| Shared Packages | `vitest --coverage` | 90% | Per-package |

**Rules:**
- Coverage calculated on lines (not branches)
- Test files excluded from coverage calculation
- Generated code excluded (e.g., OpenAPI clients)
- New code must have 100% coverage (diff coverage)

### 2. Type Safety: Maximum Strictness

#### TypeScript (Web, Mobile, Packages)
```json
{
  "compilerOptions": {
    "strict": true,
    "noImplicitAny": true,
    "strictNullChecks": true,
    "strictFunctionTypes": true,
    "strictBindCallApply": true,
    "strictPropertyInitialization": true,
    "noImplicitThis": true,
    "useUnknownInCatchVariables": true,
    "alwaysStrict": true,
    "noUncheckedIndexedAccess": true,
    "noImplicitReturns": true,
    "noFallthroughCasesInSwitch": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true
  }
}
```

#### Python
- **mypy** with `--strict` mode
- All functions must have type annotations
- No `# type: ignore` without justification comment
- `py.typed` marker for all packages

#### Go
- `go vet` for static analysis
- `staticcheck` for additional checks
- No `//nolint` without justification

### 3. SOLID & Best Practices

#### Cyclomatic Complexity
| Language | Tool | Max Complexity |
|----------|------|----------------|
| Go | `gocyclo` | 10 per function |
| Python | `radon` | 10 per function |
| TypeScript | `eslint-plugin-sonarjs` | 10 per function |

#### Function Length
| Language | Max Lines |
|----------|-----------|
| Go | 50 lines |
| Python | 50 lines |
| TypeScript | 50 lines |

#### Dependency Rules
- No circular dependencies (enforced by linters)
- Layer violations blocked:
  - `internal/` cannot import from `cmd/`
  - `domain/` cannot import from `infrastructure/`
  - Shared packages cannot import from apps

#### Code Duplication
- **Tool**: `jscpd` (cross-language)
- **Threshold**: Max 3% duplication
- **Min tokens**: 50 (ignore small patterns)

### 4. Security Scanning

| Tool | Purpose | Languages |
|------|---------|-----------|
| `govulncheck` | Vulnerability scan | Go |
| `pip-audit` | Dependency vulnerabilities | Python |
| `pnpm audit` | Dependency vulnerabilities | Node.js |
| `trivy` | Container scanning | Docker |

---

## Tooling Stack

### Go (`apps/api/`)

```yaml
tools:
  - golangci-lint  # Meta-linter (includes all below)
    - govet        # Official Go vet
    - staticcheck  # Advanced static analysis
    - errcheck     # Unchecked errors
    - gosimple     # Code simplification
    - gocritic     # Opinionated checks
    - gocyclo      # Cyclomatic complexity
    - funlen       # Function length
    - dupl         # Code duplication
    - gosec        # Security issues
  - govulncheck    # Vulnerability scanning
  - go test -cover # Coverage
```

### Python (`apps/workers/`)

```yaml
tools:
  - ruff           # Fast linter (replaces flake8, isort, etc.)
  - mypy --strict  # Type checking
  - pytest-cov     # Coverage
  - radon          # Complexity metrics
  - pip-audit      # Security vulnerabilities
  - bandit         # Security linter
```

### TypeScript (`apps/web/`, `apps/mobile/`, `packages/`)

```yaml
tools:
  - tsc --noEmit           # Type checking
  - eslint                 # Linting
    - @typescript-eslint   # TS-specific rules
    - eslint-plugin-sonarjs # SOLID/complexity
    - eslint-plugin-import # Import rules
  - vitest --coverage      # Testing + coverage (web)
  - jest --coverage        # Testing + coverage (mobile)
  - pnpm audit             # Security
```

### Cross-Language

```yaml
tools:
  - jscpd          # Code duplication detection
  - trivy          # Container security scanning
```

---

## Enforcement Points

### 1. `make verify` (Manual)

Developer runs before committing:

```bash
make verify
# Runs ALL checks in parallel
# Outputs summary at end
# Exit code 1 if ANY check fails
```

**Output format:**
```
═══════════════════════════════════════════════════════════════
                    QUALITY VERIFICATION
═══════════════════════════════════════════════════════════════

[Go API]
  ✅ Lint (golangci-lint)         2.3s
  ✅ Type check (go vet)          0.8s
  ✅ Tests                        4.2s
  ✅ Coverage: 94.2%              (threshold: 90%)
  ✅ Security (govulncheck)       1.1s

[Python Workers]
  ✅ Lint (ruff)                  0.4s
  ✅ Type check (mypy)            1.2s
  ✅ Tests                        3.8s
  ✅ Coverage: 91.5%              (threshold: 90%)
  ✅ Security (pip-audit)         0.9s

[TypeScript Web]
  ✅ Lint (eslint)                1.8s
  ✅ Type check (tsc)             2.1s
  ✅ Tests                        5.4s
  ✅ Coverage: 92.1%              (threshold: 90%)
  ✅ Security (pnpm audit)        0.6s

[TypeScript Mobile]
  ✅ Lint (eslint)                1.2s
  ✅ Type check (tsc)             1.8s
  ✅ Tests                        4.1s
  ✅ Coverage: 90.3%              (threshold: 90%)

[Cross-Language]
  ✅ Duplication (jscpd)          1.4s  (2.1% < 3%)

═══════════════════════════════════════════════════════════════
                    ✅ ALL CHECKS PASSED
═══════════════════════════════════════════════════════════════
```

### 2. Pre-Commit Hooks

Automatic check before each commit:

```yaml
# .husky/pre-commit (or lefthook.yml)
hooks:
  - lint-staged      # Only check changed files
  - type-check       # Full type check (fast)
  - test-affected    # Only tests for changed code
```

**Staged file checks:**
- Go: `golangci-lint run --new`
- Python: `ruff check --diff`
- TypeScript: `eslint --cache`

### 3. CI/CD Pipeline (GitHub Actions)

Block merges that fail quality gates:

```yaml
# .github/workflows/quality.yml
name: Quality Gates

on:
  pull_request:
    branches: [main, develop]

jobs:
  verify:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run quality checks
        run: make verify
      - name: Upload coverage
        uses: codecov/codecov-action@v4
```

**Branch protection rules:**
- Require `verify` job to pass
- Require coverage not to decrease
- Require all conversations resolved

---

## Directory Structure

```
pareto/
├── Makefile                    # make verify entry point
├── .golangci.yml              # Go linter config
├── pyproject.toml             # Python tool config (ruff, mypy, pytest)
├── .eslintrc.js               # TypeScript linter config
├── tsconfig.json              # TypeScript strict config
├── .jscpd.json                # Duplication detection config
├── lefthook.yml               # Pre-commit hooks
├── .github/
│   └── workflows/
│       └── quality.yml        # CI quality gates
└── scripts/
    └── verify/
        ├── go.sh              # Go verification script
        ├── python.sh          # Python verification script
        ├── typescript.sh      # TypeScript verification script
        └── summary.sh         # Parallel runner + summary
```

---

## Success Criteria

| Metric | Target | Enforcement |
|--------|--------|-------------|
| Test coverage | >90% all packages | Hard fail |
| Type errors | 0 | Hard fail |
| Lint errors | 0 | Hard fail |
| Cyclomatic complexity | <10 per function | Hard fail |
| Function length | <50 lines | Hard fail |
| Code duplication | <3% | Hard fail |
| Security vulnerabilities | 0 critical/high | Hard fail |
| `make verify` time | <60 seconds | Soft target |

---

## Ratchet Mechanism

The quality ratchet ensures metrics never regress:

1. **Coverage baseline**: Store current coverage in `.coverage-baseline`
2. **CI check**: New PR coverage must be >= baseline
3. **Auto-update**: When coverage increases, update baseline
4. **Block decrease**: PRs that decrease coverage are blocked

```bash
# Example ratchet check
CURRENT=$(cat .coverage-baseline)
NEW=$(make coverage-report | grep "Total" | awk '{print $2}')
if [ "$NEW" -lt "$CURRENT" ]; then
  echo "❌ Coverage decreased from $CURRENT% to $NEW%"
  exit 1
fi
```

---

## Out of Scope (Future)

- [ ] Mutation testing (e.g., `go-mutesting`, `mutmut`)
- [ ] Performance regression tests
- [ ] API contract testing
- [ ] Visual regression testing
- [ ] Load testing gates

---

## Next Steps

1. **Design**: `/x:design "quality enforcement"` - Technical implementation
2. **Plan**: `/x:plan` - Implementation breakdown
3. **Implement**: `/x:implement` - Build the quality gates

---

**Created**: 2025-12-01
**Status**: Requirements Complete
**Owner**: @clumineau
