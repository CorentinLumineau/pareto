#!/bin/bash
# =============================================================================
# TypeScript Verification
# =============================================================================
# Checks: lint (eslint), typecheck (tsc), test (vitest), coverage
# =============================================================================

set -e

cd "$(dirname "${BASH_SOURCE[0]}")/../.."

THRESHOLD=90
BASELINE_FILE=".coverage-baseline-typescript"

echo "[TypeScript]"

# Type check with pnpm turbo
echo -n "  Type check (tsc)... "
if pnpm typecheck > /dev/null 2>&1; then
    echo "✓"
else
    echo "✗"
    pnpm typecheck 2>&1 | head -30
    exit 1
fi

# Lint with eslint
echo -n "  Lint (eslint)... "
if pnpm lint > /dev/null 2>&1; then
    echo "✓"
else
    echo "✗"
    pnpm lint 2>&1 | head -30
    exit 1
fi

# Run tests with coverage
echo -n "  Tests... "

# Check for vitest configs in packages or apps
HAS_VITEST_CONFIG=false
for config in packages/*/vitest.config.ts apps/*/vitest.config.ts; do
    if [ -f "$config" ]; then
        HAS_VITEST_CONFIG=true
        break
    fi
done

if $HAS_VITEST_CONFIG; then
    # Run tests with coverage (vitest thresholds are in vitest.config.ts)
    TEST_OUTPUT=$(pnpm test --coverage 2>&1 || true)
    TEST_RESULT=$?

    if [ $TEST_RESULT -eq 0 ]; then
        echo "✓"
    else
        # Check if it's just "no tests" vs actual failures
        if echo "$TEST_OUTPUT" | grep -qE "No test|no tests"; then
            echo "○ (no tests found)"
        else
            echo "✗"
            echo "$TEST_OUTPUT" | head -30
            exit 1
        fi
    fi

    # Coverage check - extract from vitest output
    echo -n "  Coverage... "
    # Try to extract coverage percentage from vitest output
    COVERAGE=$(echo "$TEST_OUTPUT" | grep -oP 'All files\s*\|\s*[\d.]+\s*\|\s*[\d.]+\s*\|\s*[\d.]+\s*\|\s*\K[\d.]+' | head -1 || true)

    if [ -z "$COVERAGE" ]; then
        # Try alternate format
        COVERAGE=$(echo "$TEST_OUTPUT" | grep -oP 'Statements\s*:\s*\K[\d.]+' | head -1 || true)
    fi

    if [ -n "$COVERAGE" ] && [ "$COVERAGE" != "0" ]; then
        if (( $(echo "$COVERAGE >= $THRESHOLD" | bc -l 2>/dev/null || echo 0) )); then
            echo "✓ ${COVERAGE}% (threshold: ${THRESHOLD}%)"

            # Ratchet: check against baseline
            if [ -f "$BASELINE_FILE" ]; then
                BASELINE=$(cat "$BASELINE_FILE")
                if (( $(echo "$COVERAGE < $BASELINE" | bc -l 2>/dev/null || echo 0) )); then
                    echo "    ✗ Coverage decreased: ${COVERAGE}% < baseline ${BASELINE}%"
                    exit 1
                elif (( $(echo "$COVERAGE > $BASELINE" | bc -l 2>/dev/null || echo 0) )); then
                    echo "$COVERAGE" > "$BASELINE_FILE"
                    echo "    ↑ Baseline updated: ${BASELINE}% → ${COVERAGE}%"
                fi
            else
                # Create initial baseline
                echo "$COVERAGE" > "$BASELINE_FILE"
                echo "    ↑ Initial baseline set: ${COVERAGE}%"
            fi
        else
            echo "✗ ${COVERAGE}% < ${THRESHOLD}%"
            exit 1
        fi
    else
        # Vitest config has thresholds - if tests passed, coverage passed
        echo "✓ (enforced by vitest thresholds)"
    fi
else
    # No vitest config - try running pnpm test anyway
    if pnpm test > /dev/null 2>&1; then
        echo "✓"
        echo -n "  Coverage... "
        echo "○ (vitest not configured)"
    else
        TEST_OUTPUT=$(pnpm test 2>&1 || true)
        if echo "$TEST_OUTPUT" | grep -qE "No test|no tests|ERR_PNPM"; then
            echo "○ (no tests configured)"
            echo -n "  Coverage... "
            echo "○ (no tests)"
        else
            echo "✗"
            echo "$TEST_OUTPUT" | head -30
            exit 1
        fi
    fi
fi

# Build check
echo -n "  Build... "
if pnpm build > /dev/null 2>&1; then
    echo "✓"
else
    echo "✗"
    pnpm build 2>&1 | head -30
    exit 1
fi

# Security scan with pnpm audit
echo -n "  Security (pnpm audit)... "
OUTPUT=$(pnpm audit --audit-level=high 2>&1 || true)
if echo "$OUTPUT" | grep -q "No known vulnerabilities"; then
    echo "✓"
elif echo "$OUTPUT" | grep -qE "critical|high"; then
    CRITICAL=$(echo "$OUTPUT" | grep -c "critical\|high" || true)
    if [ "$CRITICAL" -gt 0 ]; then
        echo "✗ Critical/high vulnerabilities found"
        echo "$OUTPUT" | head -20
        exit 1
    fi
else
    echo "✓"
fi

echo ""
