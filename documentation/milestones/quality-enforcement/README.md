# Quality Enforcement Initiative

> **Zero-regression quality gates with `make verify` command**

```
╔══════════════════════════════════════════════════════════════════════════════╗
║                      QUALITY ENFORCEMENT INITIATIVE                           ║
╠══════════════════════════════════════════════════════════════════════════════╣
║  Status:     ✅ COMPLETE                                                       ║
║  Priority:   P0 - Critical (Quality Foundation)                              ║
║  Effort:     1-2 weeks (6 milestones)                                        ║
║  Impact:     High - Prevents regression forever                              ║
║  Owner:      @clumineau                                                      ║
╚══════════════════════════════════════════════════════════════════════════════╝
```

## Problem Statement

Code quality can degrade over time without enforcement. Currently:
- No unified `make verify` command
- No coverage thresholds enforced
- Type checking not strict enough
- No pre-commit hooks
- No CI quality gates

## Business Value

- **Never regress**: Once quality is achieved, it stays
- **Confidence**: Every PR meets quality standards
- **Speed**: Catch issues early, before code review
- **Consistency**: Same standards across Go, Python, TypeScript

## Goals & Success Criteria

| Metric | Target | Enforcement |
|--------|--------|-------------|
| Test Coverage | >90% all packages | Hard fail |
| Type Errors | 0 | Hard fail |
| Lint Errors | 0 | Hard fail |
| Cyclomatic Complexity | <10 per function | Hard fail |
| Function Length | <50 lines | Hard fail |
| Code Duplication | <3% | Hard fail |
| Security Vulnerabilities | 0 critical/high | Hard fail |
| `make verify` Time | <60 seconds | Soft target |

---

## Pareto ROI Breakdown (6 Milestones)

```
═══════════════════════════════════════════════════════════════
Milestones ordered by Value/Effort ratio (ROI)
═══════════════════════════════════════════════════════════════

M1 (1d) → 🟢🟢🟢 Very High ROI  | make verify skeleton
M2 (2d) → 🟢🟢   High ROI       | Coverage enforcement
M3 (1d) → 🟢🟢   High ROI       | Type safety maximum strict
M4 (2d) → 🟡🟢   Medium-High    | SOLID/complexity checks
M5 (1d) → 🟡     Medium ROI     | Security scanning
M6 (1d) → 🟡     Medium ROI     | Pre-commit + CI gates

Total: 8 days (~1.5 weeks)

Production-ready baseline: After M3 (4 days)
Complete enforcement: After M6 (8 days)
```

---

## Progress Tracking

| # | Milestone | Effort | ROI | Status | Completion |
|---|-----------|--------|-----|--------|------------|
| M1 | make verify Skeleton | 1 day | 🟢🟢🟢 | ✅ Complete | 100% |
| M2 | Coverage Enforcement | 2 days | 🟢🟢 | ✅ Complete | 100% |
| M3 | Type Safety Maximum | 1 day | 🟢🟢 | ✅ Complete | 100% |
| M4 | SOLID/Complexity Checks | 2 days | 🟡🟢 | ✅ Complete | 100% |
| M5 | Security Scanning | 1 day | 🟡 | ✅ Complete | 100% |
| M6 | Pre-commit + CI Gates | 1 day | 🟡 | ✅ Complete | 100% |

**Overall Progress**: 100% complete (6/6 milestones)

---

## Milestone Details

### M1: make verify Skeleton (HIGHEST ROI)

**Effort**: 1 day | **ROI**: 🟢🟢🟢 Very High
**File**: [01-verify-skeleton.md](./01-verify-skeleton.md)

Create the unified `make verify` command that runs all checks in parallel.

**Scope**:
- Create `scripts/verify/` directory structure
- Implement parallel runner with summary output
- Add Go verification script
- Add Python verification script
- Add TypeScript verification script
- Unified exit code handling

**Deliverables**:
- [x] `make verify` command works
- [x] Parallel execution with summary
- [x] Clear pass/fail output
- [x] Exit code 1 on any failure

---

### M2: Coverage Enforcement (HIGH ROI)

**Effort**: 2 days | **ROI**: 🟢🟢 High
**File**: [02-coverage-enforcement.md](./02-coverage-enforcement.md)

Enforce >90% test coverage across all languages with hard fail.

**Scope**:
- Go: Configure `go test -cover` with threshold
- Python: Configure `pytest-cov` with `--cov-fail-under=90`
- TypeScript: Configure `vitest --coverage` with threshold
- Add coverage baseline files for ratchet mechanism

**Deliverables**:
- [x] Go coverage >90% enforced
- [x] Python coverage >90% enforced
- [x] TypeScript coverage >90% enforced
- [x] Coverage ratchet mechanism (never decrease)

---

### M3: Type Safety Maximum (HIGH ROI)

**Effort**: 1 day | **ROI**: 🟢🟢 High
**File**: [03-type-safety.md](./03-type-safety.md)

Maximum strictness for all type systems.

**Scope**:
- TypeScript: Enable all strict flags + `noUncheckedIndexedAccess`
- Python: Ensure `mypy --strict` in pyproject.toml
- Go: Configure `go vet` + `staticcheck`
- Ban `any` types, require annotations

**Deliverables**:
- [x] TypeScript strict mode (all flags)
- [x] Python mypy --strict (already configured)
- [x] Go staticcheck configured
- [x] Zero type errors policy

---

### M4: SOLID/Complexity Checks (MEDIUM-HIGH ROI)

**Effort**: 2 days | **ROI**: 🟡🟢 Medium-High
**File**: [04-solid-complexity.md](./04-solid-complexity.md)

Enforce code quality metrics for maintainability.

**Scope**:
- Go: Add `gocyclo`, `funlen`, `dupl` to golangci-lint
- Python: Add `radon` for complexity, configure in ruff
- TypeScript: Add `eslint-plugin-sonarjs` for complexity
- Configure `jscpd` for cross-language duplication detection

**Deliverables**:
- [x] Cyclomatic complexity <10 enforced
- [x] Function length <50 lines enforced
- [x] Code duplication <3% enforced
- [x] `.golangci.yml` configured

---

### M5: Security Scanning (MEDIUM ROI)

**Effort**: 1 day | **ROI**: 🟡 Medium
**File**: [05-security-scanning.md](./05-security-scanning.md)

Scan for vulnerabilities in dependencies and code.

**Scope**:
- Go: Add `govulncheck` to verify pipeline
- Python: Add `pip-audit` to verify pipeline
- Node.js: Add `pnpm audit` to verify pipeline
- Configure severity thresholds (block critical/high)

**Deliverables**:
- [x] Go vulnerability scanning
- [x] Python dependency audit
- [x] Node.js dependency audit
- [x] Block on critical/high vulnerabilities

---

### M6: Pre-commit + CI Gates (MEDIUM ROI)

**Effort**: 1 day | **ROI**: 🟡 Medium
**File**: [06-precommit-ci.md](./06-precommit-ci.md)

Automated enforcement at every stage.

**Scope**:
- Configure `lefthook` for pre-commit hooks
- Create GitHub Actions workflow for PR quality gates
- Configure branch protection rules
- Add coverage reporting to PRs

**Deliverables**:
- [x] Pre-commit hooks running on commit
- [x] GitHub Actions quality workflow
- [ ] Branch protection requiring quality pass (requires repo admin)
- [ ] Coverage report comments on PRs (requires CODECOV_TOKEN)

---

## Technical Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           make verify ARCHITECTURE                           │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   make verify                                                               │
│       │                                                                     │
│       ├──▶ scripts/verify/go.sh        (parallel)                          │
│       │       ├── golangci-lint run                                        │
│       │       ├── go test -cover (>90%)                                    │
│       │       ├── go vet                                                   │
│       │       └── govulncheck                                              │
│       │                                                                     │
│       ├──▶ scripts/verify/python.sh    (parallel)                          │
│       │       ├── ruff check                                               │
│       │       ├── mypy --strict                                            │
│       │       ├── pytest --cov (>90%)                                      │
│       │       └── pip-audit                                                │
│       │                                                                     │
│       ├──▶ scripts/verify/typescript.sh (parallel)                         │
│       │       ├── pnpm lint (eslint)                                       │
│       │       ├── pnpm typecheck (tsc)                                     │
│       │       ├── pnpm test --coverage (>90%)                              │
│       │       └── pnpm audit                                               │
│       │                                                                     │
│       └──▶ scripts/verify/cross.sh     (parallel)                          │
│               └── jscpd (duplication <3%)                                  │
│                                                                             │
│   Output: Unified summary with pass/fail per check                          │
│   Exit: 0 if all pass, 1 if any fail                                       │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Tooling Stack

### Go (`apps/api/`)

| Tool | Purpose | Config |
|------|---------|--------|
| golangci-lint | Meta-linter | `.golangci.yml` |
| go test -cover | Coverage | threshold 90% |
| govulncheck | Security | block critical |
| gocyclo | Complexity | max 10 |
| funlen | Function length | max 50 |

### Python (`apps/workers/`)

| Tool | Purpose | Config |
|------|---------|--------|
| ruff | Linting | `pyproject.toml` |
| mypy --strict | Type checking | `pyproject.toml` |
| pytest-cov | Coverage | threshold 90% |
| pip-audit | Security | block critical |
| radon | Complexity | max 10 |

### TypeScript (`apps/web/`, `apps/mobile/`, `packages/`)

| Tool | Purpose | Config |
|------|---------|--------|
| eslint | Linting | `.eslintrc.js` |
| tsc --noEmit | Type checking | `tsconfig.json` |
| vitest --coverage | Coverage | threshold 90% |
| pnpm audit | Security | block critical |
| sonarjs | Complexity | max 10 |

### Cross-Language

| Tool | Purpose | Config |
|------|---------|--------|
| jscpd | Duplication | `.jscpd.json` |
| lefthook | Pre-commit | `lefthook.yml` |

---

## Files to Create/Modify

```
pareto/
├── Makefile                          # Add verify target
├── .golangci.yml                     # NEW - Go linter config
├── .eslintrc.js                      # NEW - TypeScript linter
├── .jscpd.json                       # NEW - Duplication config
├── lefthook.yml                      # NEW - Pre-commit hooks
├── .github/
│   └── workflows/
│       └── quality.yml               # NEW - CI quality gates
├── scripts/
│   └── verify/
│       ├── main.sh                   # NEW - Parallel runner
│       ├── go.sh                     # NEW - Go checks
│       ├── python.sh                 # NEW - Python checks
│       ├── typescript.sh             # NEW - TS checks
│       └── summary.sh                # NEW - Summary output
└── packages/
    └── typescript-config/
        └── strict.json               # MODIFY - Add strict flags
```

---

## Quality Ratchet Mechanism

Once a quality metric is achieved, it can never decrease:

```bash
# Coverage baseline stored in .coverage-baseline
echo "90" > .coverage-baseline

# CI checks new coverage >= baseline
CURRENT=$(cat .coverage-baseline)
NEW=$(make coverage-report)
if [ "$NEW" -lt "$CURRENT" ]; then
  echo "Coverage decreased from $CURRENT% to $NEW%"
  exit 1
fi

# When coverage increases, auto-update baseline
if [ "$NEW" -gt "$CURRENT" ]; then
  echo "$NEW" > .coverage-baseline
  git add .coverage-baseline
fi
```

---

## Dependencies

| Dependency | Type | Status |
|------------|------|--------|
| Foundation | Initiative | ✅ Complete |
| Existing Makefile | Technical | ✅ Exists |
| pyproject.toml | Technical | ✅ Exists |
| tsconfig.json | Technical | ✅ Exists |

---

## Risks & Mitigation

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Existing code doesn't meet 90% coverage | High | Medium | Gradual enforcement or write tests first |
| False positives from linters | Medium | Low | Configure exceptions where needed |
| Slow verify time | Medium | Medium | Parallel execution, caching |
| Team resistance | Low | Medium | Clear documentation, gradual rollout |

---

## Related Documentation

- [Requirements](../../domain/quality-enforcement.md) - Full requirements doc
- [Development Setup](../../development/README.md) - Dev environment
- [MASTERPLAN](../MASTERPLAN.md) - Project roadmap

---

**Created**: 2025-12-01
**Completed**: 2025-12-01
**Status**: ✅ Complete
**Next Steps**: Configure branch protection in GitHub settings, set up CODECOV_TOKEN
