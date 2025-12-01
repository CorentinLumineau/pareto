# M1: make verify Skeleton

> **Create unified quality verification command**

```
╔════════════════════════════════════════════════════════════════╗
║  Milestone: make verify Skeleton                                ║
║  Status:    ✅ COMPLETE                                         ║
║  Effort:    1 day                                               ║
║  ROI:       🟢🟢🟢 Very High                                    ║
╚════════════════════════════════════════════════════════════════╝
```

## Objective

Create the `make verify` command that runs all quality checks in parallel with a unified summary output.

## Why This First?

- Foundation for all other milestones
- Enables immediate developer feedback
- Small, focused, low risk
- Provides framework for adding checks

## Tasks

### 1. Create Directory Structure

```bash
mkdir -p scripts/verify
```

### 2. Create Parallel Runner (`scripts/verify/main.sh`)

```bash
#!/bin/bash
set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "═══════════════════════════════════════════════════════════════"
echo "                    QUALITY VERIFICATION"
echo "═══════════════════════════════════════════════════════════════"
echo ""

# Run all checks in parallel, capture exit codes
pids=()
results=()

# Go checks
./scripts/verify/go.sh &
pids+=($!)

# Python checks
./scripts/verify/python.sh &
pids+=($!)

# TypeScript checks
./scripts/verify/typescript.sh &
pids+=($!)

# Wait for all and collect results
for pid in "${pids[@]}"; do
    wait $pid
    results+=($?)
done

# Summary
echo ""
echo "═══════════════════════════════════════════════════════════════"

failed=0
for result in "${results[@]}"; do
    if [ $result -ne 0 ]; then
        failed=1
    fi
done

if [ $failed -eq 0 ]; then
    echo -e "                    ${GREEN}✅ ALL CHECKS PASSED${NC}"
else
    echo -e "                    ${RED}❌ SOME CHECKS FAILED${NC}"
fi

echo "═══════════════════════════════════════════════════════════════"

exit $failed
```

### 3. Create Go Verification (`scripts/verify/go.sh`)

```bash
#!/bin/bash
cd apps/api

echo "[Go API]"

# Lint
echo -n "  Lint (golangci-lint)... "
if golangci-lint run --timeout 2m > /dev/null 2>&1; then
    echo "✅"
else
    echo "❌"
    exit 1
fi

# Tests
echo -n "  Tests... "
if go test ./... > /dev/null 2>&1; then
    echo "✅"
else
    echo "❌"
    exit 1
fi

echo ""
```

### 4. Create Python Verification (`scripts/verify/python.sh`)

```bash
#!/bin/bash
cd apps/workers

echo "[Python Workers]"

# Lint
echo -n "  Lint (ruff)... "
if ruff check src/ > /dev/null 2>&1; then
    echo "✅"
else
    echo "❌"
    exit 1
fi

# Type check
echo -n "  Type check (mypy)... "
if mypy src/ > /dev/null 2>&1; then
    echo "✅"
else
    echo "❌"
    exit 1
fi

# Tests
echo -n "  Tests (pytest)... "
if pytest > /dev/null 2>&1; then
    echo "✅"
else
    echo "❌"
    exit 1
fi

echo ""
```

### 5. Create TypeScript Verification (`scripts/verify/typescript.sh`)

```bash
#!/bin/bash

echo "[TypeScript]"

# Lint
echo -n "  Lint (eslint)... "
if pnpm lint > /dev/null 2>&1; then
    echo "✅"
else
    echo "❌"
    exit 1
fi

# Type check
echo -n "  Type check (tsc)... "
if pnpm typecheck > /dev/null 2>&1; then
    echo "✅"
else
    echo "❌"
    exit 1
fi

# Tests
echo -n "  Tests... "
if pnpm test > /dev/null 2>&1; then
    echo "✅"
else
    echo "❌"
    exit 1
fi

echo ""
```

### 6. Update Makefile

Add to Makefile:

```makefile
# Quality verification (all checks)
verify:
	@chmod +x scripts/verify/*.sh
	@./scripts/verify/main.sh
```

## Success Criteria

- [x] `make verify` runs all checks
- [x] Parallel execution works
- [x] Clear pass/fail output per check
- [x] Exit code 1 if any check fails
- [x] Exit code 0 if all pass
- [x] Execution time shown

## Deliverables

```
scripts/
└── verify/
    ├── main.sh          # Parallel runner
    ├── go.sh            # Go checks
    ├── python.sh        # Python checks
    └── typescript.sh    # TypeScript checks
```

## Testing

```bash
# Run verification
make verify

# Expected output:
# ═══════════════════════════════════════════════════════════════
#                     QUALITY VERIFICATION
# ═══════════════════════════════════════════════════════════════
#
# [Go API]
#   Lint (golangci-lint)... ✅
#   Tests... ✅
#
# [Python Workers]
#   Lint (ruff)... ✅
#   Type check (mypy)... ✅
#   Tests (pytest)... ✅
#
# [TypeScript]
#   Lint (eslint)... ✅
#   Type check (tsc)... ✅
#   Tests... ✅
#
# ═══════════════════════════════════════════════════════════════
#                     ✅ ALL CHECKS PASSED
# ═══════════════════════════════════════════════════════════════
```

---

**Next**: [M2: Coverage Enforcement](./02-coverage-enforcement.md)
