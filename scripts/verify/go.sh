#!/bin/bash
# =============================================================================
# Go API Verification
# =============================================================================
# Checks: lint, typecheck, test, coverage
# =============================================================================

set -e

cd "$(dirname "${BASH_SOURCE[0]}")/../.."
cd apps/api

echo "[Go API]"

# Build check (type safety via compilation)
echo -n "  Build check... "
if go build -o /dev/null ./cmd/api 2>&1; then
    echo "✓"
else
    echo "✗"
    exit 1
fi

# Lint with golangci-lint (if available)
echo -n "  Lint (golangci-lint)... "
if command -v golangci-lint &> /dev/null; then
    if golangci-lint run --timeout 5m ./... > /dev/null 2>&1; then
        echo "✓"
    else
        echo "✗"
        golangci-lint run --timeout 5m ./... 2>&1 | head -30
        exit 1
    fi
else
    echo "○ (not installed)"
fi

# Run tests with coverage
echo -n "  Tests... "
TEST_OUTPUT=$(go test -race -coverprofile=coverage.out ./... 2>&1)
if [ $? -eq 0 ]; then
    echo "✓"
else
    echo "✗"
    echo "$TEST_OUTPUT" | head -30
    exit 1
fi

# Check coverage (extract percentage)
echo -n "  Coverage... "
THRESHOLD=90
BASELINE_FILE="$(dirname "${BASH_SOURCE[0]}")/../../.coverage-baseline-go"

if [ -f coverage.out ]; then
    COVERAGE=$(go tool cover -func=coverage.out | grep total | awk '{print $3}' | tr -d '%')
    if [ -z "$COVERAGE" ]; then
        COVERAGE="0"
    fi

    # Check against threshold (hard fail)
    if (( $(echo "$COVERAGE >= $THRESHOLD" | bc -l 2>/dev/null || echo 0) )); then
        echo "✓ ${COVERAGE}% (threshold: ${THRESHOLD}%)"

        # Ratchet: check against baseline
        if [ -f "$BASELINE_FILE" ]; then
            BASELINE=$(cat "$BASELINE_FILE")
            if (( $(echo "$COVERAGE < $BASELINE" | bc -l 2>/dev/null || echo 0) )); then
                echo "    ✗ Coverage decreased: ${COVERAGE}% < baseline ${BASELINE}%"
                rm -f coverage.out
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
        rm -f coverage.out
        exit 1
    fi

    # Clean up
    rm -f coverage.out
else
    echo "○ (no tests found)"
fi

# Security scan with govulncheck (if available)
echo -n "  Security (govulncheck)... "
if command -v govulncheck &> /dev/null; then
    OUTPUT=$(govulncheck ./... 2>&1)
    if echo "$OUTPUT" | grep -q "No vulnerabilities found"; then
        echo "✓"
    elif echo "$OUTPUT" | grep -q "Vulnerability"; then
        echo "✗ Vulnerabilities found"
        echo "$OUTPUT" | head -20
        exit 1
    else
        echo "✓"
    fi
else
    echo "○ (not installed)"
fi

echo ""
