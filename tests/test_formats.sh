#!/bin/bash
################################################################################
# Output Format Tests
################################################################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
LOG_SCRIPT="${REPO_DIR}/bin/logCollector.sh"
TEST_OUTPUT="${SCRIPT_DIR}/output/formats"

mkdir -p "$TEST_OUTPUT"
export BASE_LOG_DIR="$TEST_OUTPUT"

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

# Test 1: Plain text format (default)
"$LOG_SCRIPT" 'test-plain' 'test.sh' 'INFO' 'Plain text message' 2>/dev/null
LOGFILE="${TEST_OUTPUT}/test-plain/current/test.sh_$(date +%Y-%m-%d).log"
grep -q "Plain text message" "$LOGFILE" 2>/dev/null
test_result $? "Plain text format"

# Test 2: Contains timestamp
grep -qE '[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}' "$LOGFILE" 2>/dev/null
test_result $? "Contains ISO timestamp"

# Test 3: Contains log level
grep -q "\[INFO\]" "$LOGFILE" 2>/dev/null
test_result $? "Contains log level"

# Test 4: JSON format
"$LOG_SCRIPT" 'test-json' 'test.sh' 'INFO' 'JSON message' --json 2>/dev/null
JSONFILE="${TEST_OUTPUT}/test-json/current/test.sh_$(date +%Y-%m-%d).log"
grep -q '"message": "JSON message"' "$JSONFILE" 2>/dev/null
test_result $? "JSON format"

# Test 5: JSON has required fields
grep -q '"timestamp"' "$JSONFILE" && \
grep -q '"level"' "$JSONFILE" && \
grep -q '"message"' "$JSONFILE" && \
grep -q '"hostname"' "$JSONFILE" 2>/dev/null
test_result $? "JSON has required fields"

# Test 6: Metadata in JSON
"$LOG_SCRIPT" 'test-metadata' 'test.sh' 'INFO' 'With metadata' --json --metadata key1=value1 --metadata key2=value2 2>/dev/null
METAFILE="${TEST_OUTPUT}/test-metadata/current/test.sh_$(date +%Y-%m-%d).log"
grep -q '"key1": "value1"' "$METAFILE" && grep -q '"key2": "value2"' "$METAFILE" 2>/dev/null
test_result $? "Metadata included in JSON"

# Cleanup
rm -rf "$TEST_OUTPUT"

echo ""
echo "Format Tests: $TESTS_PASSED passed, $TESTS_FAILED failed"
[[ $TESTS_FAILED -eq 0 ]] && exit 0 || exit 1
