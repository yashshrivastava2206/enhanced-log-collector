#!/bin/bash
################################################################################
# Run All Tests
################################################################################

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m'

PASSED=0
FAILED=0

echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║              Running Test Suite                            ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Setup
export TEST_OUTPUT_DIR="${SCRIPT_DIR}/output"
mkdir -p "$TEST_OUTPUT_DIR"

# Run each test
TESTS=(
    "test_basic.sh"
    "test_rotation.sh"
    "test_compression.sh"
    "test_formats.sh"
)

for test in "${TESTS[@]}"; do
    echo -e "${YELLOW}Running ${test}...${NC}"
    if bash "${SCRIPT_DIR}/${test}"; then
        echo -e "${GREEN}✓ ${test} PASSED${NC}"
        PASSED=$((PASSED + 1))
    else
        echo -e "${RED}✗ ${test} FAILED${NC}"
        FAILED=$((FAILED + 1))
    fi
    echo ""
done

# Summary
TOTAL=$((PASSED + FAILED))
echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                    Test Summary                            ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
echo -e "  Total Tests:  ${TOTAL}"
echo -e "  ${GREEN}Passed:       ${PASSED}${NC}"
echo -e "  ${RED}Failed:       ${FAILED}${NC}"
echo ""

if [[ $FAILED -eq 0 ]]; then
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}Some tests failed!${NC}"
    exit 1
fi
