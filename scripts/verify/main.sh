#!/bin/bash
# =============================================================================
# Pareto Comparator - Quality Verification Runner
# =============================================================================
# Runs all quality checks in parallel and reports unified results.
# Exit codes: 0 = all passed, 1 = failures detected
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Results directory
RESULTS_DIR="/tmp/pareto-verify-$$"
mkdir -p "$RESULTS_DIR"

START_TIME=$(date +%s)

# Print header
print_header() {
    echo ""
    echo -e "${BOLD}${CYAN}╔══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${CYAN}║           PARETO COMPARATOR - QUALITY VERIFICATION              ║${NC}"
    echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# Print section header
print_section() {
    echo -e "${BOLD}${BLUE}▶ $1${NC}"
}

# Run a verification script and save result to file
run_verify() {
    local name=$1
    local script=$2
    local start=$(date +%s)
    local status="skipped"

    if [ -f "$SCRIPT_DIR/$script" ]; then
        if bash "$SCRIPT_DIR/$script" > "$RESULTS_DIR/${name}.log" 2>&1; then
            status="passed"
        else
            status="failed"
        fi
    fi

    local end=$(date +%s)
    local duration=$((end - start))

    # Write result to file
    echo "$status" > "$RESULTS_DIR/${name}.status"
    echo "$duration" > "$RESULTS_DIR/${name}.duration"
}

# Print results summary
print_summary() {
    local end_time=$(date +%s)
    local total_duration=$((end_time - START_TIME))
    local failed=0

    echo ""
    echo -e "${BOLD}${CYAN}═══════════════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}                         VERIFICATION SUMMARY${NC}"
    echo -e "${BOLD}${CYAN}═══════════════════════════════════════════════════════════════════${NC}"
    echo ""

    local passed_count=0
    local failed_count=0
    local skipped_count=0

    for name in "go" "python" "typescript"; do
        local status="not run"
        local duration=0

        if [ -f "$RESULTS_DIR/${name}.status" ]; then
            status=$(cat "$RESULTS_DIR/${name}.status")
        fi
        if [ -f "$RESULTS_DIR/${name}.duration" ]; then
            duration=$(cat "$RESULTS_DIR/${name}.duration")
        fi

        case $status in
            "passed")
                echo -e "  ${GREEN}✓${NC} ${BOLD}$name${NC} (${duration}s)"
                ((passed_count++))
                ;;
            "failed")
                echo -e "  ${RED}✗${NC} ${BOLD}$name${NC} (${duration}s)"
                ((failed_count++))
                failed=1
                # Show failure details
                if [ -f "$RESULTS_DIR/${name}.log" ]; then
                    echo -e "    ${RED}─────────────────────────────────────────${NC}"
                    tail -20 "$RESULTS_DIR/${name}.log" | sed 's/^/    /'
                    echo -e "    ${RED}─────────────────────────────────────────${NC}"
                fi
                ;;
            "skipped")
                echo -e "  ${YELLOW}○${NC} ${BOLD}$name${NC} (skipped)"
                ((skipped_count++))
                ;;
            *)
                echo -e "  ${YELLOW}?${NC} ${BOLD}$name${NC} (not run)"
                ;;
        esac
    done

    echo ""
    echo -e "${CYAN}───────────────────────────────────────────────────────────────────${NC}"
    echo -e "  Total: ${BOLD}$passed_count passed${NC}, ${BOLD}$failed_count failed${NC}, ${BOLD}$skipped_count skipped${NC}"
    echo -e "  Duration: ${BOLD}${total_duration}s${NC}"
    echo -e "${CYAN}───────────────────────────────────────────────────────────────────${NC}"
    echo ""

    if [ $failed -eq 0 ]; then
        echo -e "${GREEN}${BOLD}  ✓ ALL CHECKS PASSED${NC}"
    else
        echo -e "${RED}${BOLD}  ✗ $failed_count CHECK(S) FAILED${NC}"
    fi
    echo ""

    # Clean up
    rm -rf "$RESULTS_DIR"

    return $failed
}

# Main execution
main() {
    cd "$PROJECT_ROOT"

    print_header

    # Check which components exist
    HAS_GO=false
    HAS_PYTHON=false
    HAS_TYPESCRIPT=false

    [ -d "apps/api" ] && [ -f "apps/api/go.mod" ] && HAS_GO=true
    [ -d "apps/workers" ] && [ -f "apps/workers/pyproject.toml" ] && HAS_PYTHON=true
    [ -f "package.json" ] && HAS_TYPESCRIPT=true

    print_section "Running verification checks in parallel..."
    echo ""

    # Run checks in parallel using background jobs
    pids=()

    if $HAS_GO; then
        run_verify "go" "go.sh" &
        pids+=($!)
    else
        echo "skipped" > "$RESULTS_DIR/go.status"
        echo "0" > "$RESULTS_DIR/go.duration"
    fi

    if $HAS_PYTHON; then
        run_verify "python" "python.sh" &
        pids+=($!)
    else
        echo "skipped" > "$RESULTS_DIR/python.status"
        echo "0" > "$RESULTS_DIR/python.duration"
    fi

    if $HAS_TYPESCRIPT; then
        run_verify "typescript" "typescript.sh" &
        pids+=($!)
    else
        echo "skipped" > "$RESULTS_DIR/typescript.status"
        echo "0" > "$RESULTS_DIR/typescript.duration"
    fi

    # Wait for all parallel jobs
    for pid in "${pids[@]}"; do
        wait $pid 2>/dev/null || true
    done

    # Print summary and exit with appropriate code
    print_summary
    exit $?
}

main "$@"
