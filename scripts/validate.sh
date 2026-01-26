#!/bin/bash
################################################################################
# Validation Script for Enhanced Log Collector
################################################################################

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
ERRORS=0

echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║     Enhanced Log Collector Validation                      ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check script syntax
echo -e "${YELLOW}[1/6] Checking shell script syntax...${NC}"
while IFS= read -r -d '' script; do
    if bash -n "$script" 2>/dev/null; then
        echo -e "${GREEN}✓ $(basename "$script")${NC}"
    else
        echo -e "${RED}✗ $(basename "$script") - Syntax error${NC}"
        ERRORS=$((ERRORS + 1))
    fi
done < <(find "$REPO_DIR" -name "*.sh" -type f -print0)

# Check ShellCheck if available
echo -e "${YELLOW}[2/6] Running ShellCheck (if available)...${NC}"
if command -v shellcheck &> /dev/null; then
    while IFS= read -r -d '' script; do
        if shellcheck -e SC2181,SC2155 "$script" 2>/dev/null; then
            echo -e "${GREEN}✓ $(basename "$script")${NC}"
        else
            echo -e "${YELLOW}⚠ $(basename "$script") - Has warnings${NC}"
        fi
    done < <(find "$REPO_DIR/bin" "$REPO_DIR/scripts" -name "*.sh" -type f -print0 2>/dev/null)
else
    echo -e "${YELLOW}⚠ ShellCheck not installed (optional)${NC}"
fi

# Check required files exist
echo -e "${YELLOW}[3/6] Checking required files...${NC}"
REQUIRED_FILES=(
    "bin/logCollector.sh"
    "config/logCollector.conf.example"
    "Makefile"
    "README.md"
    "VERSION"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [[ -f "${REPO_DIR}/${file}" ]]; then
        echo -e "${GREEN}✓ ${file}${NC}"
    else
        echo -e "${RED}✗ ${file} - Missing${NC}"
        ERRORS=$((ERRORS + 1))
    fi
done

# Check directory structure
echo -e "${YELLOW}[4/6] Checking directory structure...${NC}"
REQUIRED_DIRS=(
    "bin"
    "config"
    "docs"
    "examples"
    "scripts"
    "tests"
    "tools"
)

for dir in "${REQUIRED_DIRS[@]}"; do
    if [[ -d "${REPO_DIR}/${dir}" ]]; then
        echo -e "${GREEN}✓ ${dir}/${NC}"
    else
        echo -e "${RED}✗ ${dir}/ - Missing${NC}"
        ERRORS=$((ERRORS + 1))
    fi
done

# Check dependencies
echo -e "${YELLOW}[5/6] Checking system dependencies...${NC}"
REQUIRED_CMDS=(bash gzip find stat date)
for cmd in "${REQUIRED_CMDS[@]}"; do
    if command -v $cmd &> /dev/null; then
        echo -e "${GREEN}✓ ${cmd}${NC}"
    else
        echo -e "${RED}✗ ${cmd} - Not found${NC}"
        ERRORS=$((ERRORS + 1))
    fi
done

# Check permissions
echo -e "${YELLOW}[6/6] Checking script permissions...${NC}"
if [[ -x "${REPO_DIR}/bin/logCollector.sh" ]]; then
    echo -e "${GREEN}✓ logCollector.sh is executable${NC}"
else
    echo -e "${RED}✗ logCollector.sh is not executable${NC}"
    ERRORS=$((ERRORS + 1))
fi

# Summary
echo ""
if [[ $ERRORS -eq 0 ]]; then
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║           Validation Passed - No Errors Found              ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
    exit 0
else
    echo -e "${RED}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║           Validation Failed - ${ERRORS} Error(s) Found             ║${NC}"
    echo -e "${RED}╚════════════════════════════════════════════════════════════╝${NC}"
    exit 1
fi
