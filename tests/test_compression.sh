#!/bin/bash
################################################################################
# Compression Tests
################################################################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
TEST_OUTPUT="${SCRIPT_DIR}/output/compression"

mkdir -p "$TEST_OUTPUT"

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

# Test 1: gzip is available
command -v gzip &> /dev/null
test_result $? "gzip command available"

# Test 2: Create and compress a test file
TEST_FILE="${TEST_OUTPUT}/test.log"
for i in {1..1000}; do
    echo "Log entry $i with some text to compress xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx" >> "$TEST_FILE"
done

ORIGINAL_SIZE=$(stat -f%z "$TEST_FILE" 2>/dev/null || stat -c%s "$TEST_FILE" 2>/dev/null)
[[ $ORIGINAL_SIZE -gt 0 ]]
test_result $? "Test file created (${ORIGINAL_SIZE} bytes)"

# Test 3: Compress file
gzip -c "$TEST_FILE" > "${TEST_FILE}.gz"
COMPRESSED_SIZE=$(stat -f%z "${TEST_FILE}.gz" 2>/dev/null || stat -c%s "${TEST_FILE}.gz" 2>/dev/null)
[[ $COMPRESSED_SIZE -gt 0 ]]
test_result $? "File compressed (${COMPRESSED_SIZE} bytes)"

# Test 4: Check compression ratio
RATIO=$((COMPRESSED_SIZE * 100 / ORIGINAL_SIZE))
[[ $RATIO -lt 50 ]]
test_result $? "Compression ratio good (${RATIO}%)"

# Test 5: Decompress and verify
gzip -dc "${TEST_FILE}.gz" > "${TEST_OUTPUT}/test_decompressed.log"
diff -q "$TEST_FILE" "${TEST_OUTPUT}/test_decompressed.log" &>/dev/null
test_result $? "Decompression preserves data"

# Cleanup
rm -rf "$TEST_OUTPUT"

echo ""
echo "Compression Tests: $TESTS_PASSED passed, $TESTS_FAILED failed"
[[ $TESTS_FAILED -eq 0 ]] && exit 0 || exit 1
