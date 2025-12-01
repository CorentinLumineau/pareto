#!/bin/bash
# =============================================================================
# Python Workers Verification
# =============================================================================
# Checks: lint (ruff), typecheck (mypy), test (pytest), coverage
# =============================================================================

set -e

cd "$(dirname "${BASH_SOURCE[0]}")/../.."
cd apps/workers

# Determine python command
PYTHON=""
if command -v python3 &> /dev/null; then
    PYTHON="python3"
elif command -v python &> /dev/null; then
    PYTHON="python"
else
    echo "[Python Workers]"
    echo "  ✗ Python not found"
    exit 1
fi

echo "[Python Workers]"

# Lint with ruff
echo -n "  Lint (ruff)... "
if command -v ruff &> /dev/null; then
    if ruff check src/ > /dev/null 2>&1; then
        echo "✓"
    else
        echo "✗"
        ruff check src/ 2>&1 | head -30
        exit 1
    fi
else
    # Try via python module
    if $PYTHON -m ruff check src/ > /dev/null 2>&1; then
        echo "✓"
    else
        echo "○ (ruff not available)"
    fi
fi

# Format check with ruff
echo -n "  Format (ruff format)... "
if command -v ruff &> /dev/null; then
    if ruff format --check src/ > /dev/null 2>&1; then
        echo "✓"
    else
        echo "⚠ (formatting issues)"
    fi
else
    if $PYTHON -m ruff format --check src/ > /dev/null 2>&1; then
        echo "✓"
    else
        echo "○ (ruff not available)"
    fi
fi

# Type check with mypy
echo -n "  Type check (mypy)... "
if command -v mypy &> /dev/null; then
    if mypy src/ > /dev/null 2>&1; then
        echo "✓"
    else
        echo "✗"
        mypy src/ 2>&1 | head -30
        exit 1
    fi
else
    if $PYTHON -m mypy src/ > /dev/null 2>&1; then
        echo "✓"
    else
        echo "✗"
        $PYTHON -m mypy src/ 2>&1 | head -30
        exit 1
    fi
fi

# Run tests with coverage
echo -n "  Tests... "
THRESHOLD=90
BASELINE_FILE="$(dirname "${BASH_SOURCE[0]}")/../../.coverage-baseline-python"

if [ -d "tests" ] && [ "$(ls -A tests/*.py 2>/dev/null)" ]; then
    # pytest with --cov-fail-under from pyproject.toml
    if command -v pytest &> /dev/null; then
        TEST_OUTPUT=$(pytest --cov=src --cov-report=term-missing -q 2>&1)
        TEST_RESULT=$?
    else
        TEST_OUTPUT=$($PYTHON -m pytest --cov=src --cov-report=term-missing -q 2>&1)
        TEST_RESULT=$?
    fi

    # Extract coverage percentage
    COVERAGE=$(echo "$TEST_OUTPUT" | grep "TOTAL" | awk '{print $NF}' | tr -d '%')
    if [ -z "$COVERAGE" ]; then
        COVERAGE="0"
    fi

    if [ $TEST_RESULT -eq 0 ]; then
        echo "✓"
    else
        echo "✗"
        echo "$TEST_OUTPUT" | head -30
        exit 1
    fi

    # Coverage check with threshold (hard fail)
    echo -n "  Coverage... "
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
    echo "○ (no tests found)"
    echo -n "  Coverage... "
    echo "○ (no tests)"
fi

# Security scan with pip-audit (if available)
echo -n "  Security (pip-audit)... "
if command -v pip-audit &> /dev/null; then
    OUTPUT=$(pip-audit 2>&1)
    if [ $? -eq 0 ]; then
        echo "✓"
    else
        CRITICAL=$(echo "$OUTPUT" | grep -c "CRITICAL\|HIGH" || true)
        if [ "$CRITICAL" -gt 0 ]; then
            echo "✗ $CRITICAL critical/high vulnerabilities"
            echo "$OUTPUT" | head -20
            exit 1
        else
            echo "⚠ Low/medium vulnerabilities (not blocking)"
        fi
    fi
else
    if $PYTHON -m pip_audit --help > /dev/null 2>&1; then
        OUTPUT=$($PYTHON -m pip_audit 2>&1)
        if [ $? -eq 0 ]; then
            echo "✓"
        else
            echo "⚠ (vulnerabilities found, see pip-audit)"
        fi
    else
        echo "○ (not installed)"
    fi
fi

echo ""
