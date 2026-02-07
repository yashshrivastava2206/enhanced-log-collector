#!/bin/bash
################################################################################
# Basic Functionality Tests
################################################################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
LOG_SCRIPT="${REPO_DIR}/bin/logCollector.sh"
TEST_OUTPUT="${SCRIPT_DIR}/output/basic"

# Setup
mkdir -p "$TEST_OUTPUT"
export BASE_LOG_DIR="$TEST_OUTPUT"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

TESTS_PASSED=0
TESTS_FAILED=0

test_result() {
    if [[ $1 -eq 0 ]]; then
        echo -e "${GREEN}✓ $2${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗ $2${NC}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# Test 1: Script exists and is executable
[[ -x "$LOG_SCRIPT" ]]
test_result $? "Script is executable"

# Test 2: Basic INFO log
"$LOG_SCRIPT" 'test-basic' 'test.sh' 'INFO' 'Test message' 2>/dev/null
[[ -f "${TEST_OUTPUT}/test-basic/current/test.sh_$(date +%Y-%m-%d).log" ]]
test_result $? "INFO log created"

# Test 3: Log contains correct message
grep -q "Test message" "${TEST_OUTPUT}/test-basic/current/test.sh_$(date +%Y-%m-%d).log" 2>/dev/null
test_result $? "Log contains message"

# Test 4: All log levels work
for level in DEBUG INFO NOTICE WARNING ERROR CRITICAL FATAL; do
    "$LOG_SCRIPT" 'test-levels' 'test.sh' "$level" "Test $level" 2>/dev/null
    grep -q "Test $level" "${TEST_OUTPUT}/test-levels/current/test.sh_$(date +%Y-%m-%d).log" 2>/dev/null
    test_result $? "Log level $level works"
done

# Test 5: Directory structure created
[[ -d "${TEST_OUTPUT}/test-basic/current" ]] && [[ -d "${TEST_OUTPUT}/test-basic/archive" ]]
test_result $? "Directory structure created"

# Test 6: Invalid log level rejected
"$LOG_SCRIPT" 'test-invalid' 'test.sh' 'INVALID' 'Test' 2>/dev/null
[[ $? -ne 0 ]]
test_result $? "Invalid log level rejected"

# Test 7: Missing arguments rejected
"$LOG_SCRIPT" 2>/dev/null
[[ $? -ne 0 ]]
test_result $? "Missing arguments rejected"

# Cleanup
rm -rf "$TEST_OUTPUT"

# Results
echo ""
echo "Basic Tests: $TESTS_PASSED passed, $TESTS_FAILED failed"
[[ $TESTS_FAILED -eq 0 ]] && exit 0 || exit 1
