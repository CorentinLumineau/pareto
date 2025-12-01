#!/bin/bash
# =============================================================================
# Coverage Ratchet Mechanism
# =============================================================================
# Ensures coverage never decreases. Updates baselines when coverage increases.
# Usage: ./ratchet.sh [language] [current_coverage]
# =============================================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

cd "$(dirname "${BASH_SOURCE[0]}")/../.."

check_ratchet() {
    local name=$1
    local baseline_file=$2
    local current=$3

    if [ -z "$current" ]; then
        echo -e "${YELLOW}○${NC} $name: no coverage data"
        return 0
    fi

    if [ -f "$baseline_file" ]; then
        baseline=$(cat "$baseline_file")

        if (( $(echo "$current < $baseline" | bc -l 2>/dev/null || echo 0) )); then
            echo -e "${RED}✗${NC} $name coverage DECREASED: ${current}% < baseline ${baseline}%"
            return 1
        elif (( $(echo "$current > $baseline" | bc -l 2>/dev/null || echo 0) )); then
            echo "$current" > "$baseline_file"
            echo -e "${GREEN}↑${NC} $name coverage INCREASED: ${baseline}% → ${current}%"
            echo "  Baseline updated in $baseline_file"
        else
            echo -e "${GREEN}✓${NC} $name coverage maintained: ${current}%"
        fi
    else
        echo "$current" > "$baseline_file"
        echo -e "${GREEN}↑${NC} $name initial baseline set: ${current}%"
    fi

    return 0
}

# If called with arguments, check single language
if [ $# -eq 2 ]; then
    language=$1
    coverage=$2
    baseline_file=".coverage-baseline-${language}"
    check_ratchet "$language" "$baseline_file" "$coverage"
    exit $?
fi

# Otherwise, verify all baselines exist and are valid
echo "Coverage Ratchet Status:"
echo "========================"

failed=0

for lang in go python typescript; do
    baseline_file=".coverage-baseline-${lang}"
    if [ -f "$baseline_file" ]; then
        baseline=$(cat "$baseline_file")
        echo -e "${GREEN}✓${NC} $lang baseline: ${baseline}%"
    else
        echo -e "${YELLOW}○${NC} $lang baseline: not set"
    fi
done

echo ""
echo "Baselines are updated automatically by verify scripts when coverage increases."
echo "Coverage can never decrease once a baseline is set."
