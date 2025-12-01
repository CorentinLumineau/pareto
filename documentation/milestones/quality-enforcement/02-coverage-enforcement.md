# M2: Coverage Enforcement

> **Enforce >90% test coverage across all languages**

```
╔════════════════════════════════════════════════════════════════╗
║  Milestone: Coverage Enforcement                                ║
║  Status:    ✅ COMPLETE                                         ║
║  Effort:    2 days                                              ║
║  ROI:       🟢🟢 High                                           ║
╚════════════════════════════════════════════════════════════════╝
```

## Objective

Enforce >90% test coverage with hard failure. Once achieved, coverage can never decrease (ratchet mechanism).

## Tasks

### 1. Go Coverage Configuration

Update `scripts/verify/go.sh`:

```bash
#!/bin/bash
cd apps/api

THRESHOLD=90

echo "[Go API]"

# Coverage with threshold
echo -n "  Coverage... "
COVERAGE=$(go test -cover ./... 2>&1 | grep -oP 'coverage: \K[0-9.]+' | head -1)
if [ -z "$COVERAGE" ]; then
    COVERAGE=0
fi

if (( $(echo "$COVERAGE >= $THRESHOLD" | bc -l) )); then
    echo "✅ ${COVERAGE}% (threshold: ${THRESHOLD}%)"
else
    echo "❌ ${COVERAGE}% < ${THRESHOLD}%"
    exit 1
fi
```

### 2. Python Coverage Configuration

Update `apps/workers/pyproject.toml`:

```toml
[tool.pytest.ini_options]
testpaths = ["tests"]
asyncio_mode = "auto"
addopts = "--cov=src --cov-report=term-missing --cov-fail-under=90"

[tool.coverage.run]
source = ["src"]
omit = ["*/__pycache__/*", "*/tests/*"]

[tool.coverage.report]
fail_under = 90
show_missing = true
exclude_lines = [
    "pragma: no cover",
    "if TYPE_CHECKING:",
    "raise NotImplementedError",
]
```

Update `scripts/verify/python.sh`:

```bash
#!/bin/bash
cd apps/workers

echo "[Python Workers]"

# Tests with coverage (--cov-fail-under=90 in pyproject.toml)
echo -n "  Tests + Coverage... "
OUTPUT=$(pytest --cov=src --cov-report=term-missing 2>&1)
if [ $? -eq 0 ]; then
    COVERAGE=$(echo "$OUTPUT" | grep "TOTAL" | awk '{print $4}' | tr -d '%')
    echo "✅ ${COVERAGE}% (threshold: 90%)"
else
    COVERAGE=$(echo "$OUTPUT" | grep "TOTAL" | awk '{print $4}' | tr -d '%')
    echo "❌ ${COVERAGE}% < 90%"
    exit 1
fi
```

### 3. TypeScript Coverage Configuration

Create/update `vitest.config.ts` in packages and apps/web:

```typescript
import { defineConfig } from 'vitest/config'

export default defineConfig({
  test: {
    coverage: {
      provider: 'v8',
      reporter: ['text', 'json', 'html'],
      thresholds: {
        lines: 90,
        branches: 90,
        functions: 90,
        statements: 90,
      },
    },
  },
})
```

Update `scripts/verify/typescript.sh`:

```bash
#!/bin/bash

THRESHOLD=90

echo "[TypeScript]"

# Tests with coverage
echo -n "  Tests + Coverage... "
OUTPUT=$(pnpm test --coverage 2>&1)
if [ $? -eq 0 ]; then
    echo "✅ >=${THRESHOLD}%"
else
    echo "❌ <${THRESHOLD}%"
    exit 1
fi
```

### 4. Coverage Ratchet Mechanism

Create `.coverage-baseline` files:

```bash
# Create baseline files
echo "90" > .coverage-baseline-go
echo "90" > .coverage-baseline-python
echo "90" > .coverage-baseline-typescript
```

Add ratchet check to CI:

```bash
#!/bin/bash
# scripts/verify/ratchet.sh

check_ratchet() {
    local name=$1
    local baseline_file=$2
    local current=$3

    if [ -f "$baseline_file" ]; then
        baseline=$(cat "$baseline_file")
        if (( $(echo "$current < $baseline" | bc -l) )); then
            echo "❌ $name coverage decreased: $current% < $baseline%"
            return 1
        fi
        # Auto-update if increased
        if (( $(echo "$current > $baseline" | bc -l) )); then
            echo "$current" > "$baseline_file"
            echo "📈 $name coverage increased: $baseline% → $current%"
        fi
    fi
    return 0
}
```

## Success Criteria

- [x] Go coverage >90% enforced
- [x] Python coverage >90% enforced (via pytest-cov)
- [x] TypeScript coverage >90% enforced (via vitest)
- [x] Coverage ratchet prevents decrease
- [x] Clear coverage percentage in output

## Deliverables

```
.coverage-baseline-go
.coverage-baseline-python
.coverage-baseline-typescript
apps/workers/pyproject.toml (updated)
vitest.config.ts (new or updated)
scripts/verify/ratchet.sh (new)
```

## Testing

```bash
make verify

# Expected output includes:
# [Go API]
#   Coverage... ✅ 94.2% (threshold: 90%)
#
# [Python Workers]
#   Tests + Coverage... ✅ 91.5% (threshold: 90%)
#
# [TypeScript]
#   Tests + Coverage... ✅ >=90%
```

---

**Previous**: [M1: make verify Skeleton](./01-verify-skeleton.md)
**Next**: [M3: Type Safety Maximum](./03-type-safety.md)
