#!/bin/bash
################################################################################
# Health Check Tool
################################################################################

LOG_DIR="/var/log"
CONFIG_FILE="/etc/logCollector.conf"
SCRIPT_FILE="/opt/scripts/logCollector.sh"

GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m'

ISSUES=0

echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║              Health Check                                  ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check 1: Script exists
echo -e "${YELLOW}[1/8] Checking script installation...${NC}"
if [[ -f "$SCRIPT_FILE" ]] && [[ -x "$SCRIPT_FILE" ]]; then
    VERSION=$(grep 'SCRIPT_VERSION=' "$SCRIPT_FILE" | head -1 | cut -d'"' -f2)
    echo -e "${GREEN}✓ Script installed (v${VERSION})${NC}"
else
    echo -e "${RED}✗ Script not found or not executable${NC}"
    ISSUES=$((ISSUES + 1))
fi

# Check 2: Configuration
echo -e "${YELLOW}[2/8] Checking configuration...${NC}"
if [[ -f "$CONFIG_FILE" ]]; then
    echo -e "${GREEN}✓ Configuration file exists${NC}"
else
    echo -e "${RED}✗ Configuration file missing${NC}"
    ISSUES=$((ISSUES + 1))
fi

# Check 3: Log directory
echo -e "${YELLOW}[3/8] Checking log directory...${NC}"
if [[ -d "$LOG_DIR" ]] && [[ -w "$LOG_DIR" ]]; then
    echo -e "${GREEN}✓ Log directory accessible${NC}"
else
    echo -e "${RED}✗ Log directory not writable${NC}"
    ISSUES=$((ISSUES + 1))
fi

# Check 4: Disk space
echo -e "${YELLOW}[4/8] Checking disk space...${NC}"
DISK_USAGE=$(df "$LOG_DIR" | tail -1 | awk '{print $5}' | tr -d '%')
if [[ $DISK_USAGE -lt 90 ]]; then
    echo -e "${GREEN}✓ Disk usage OK (${DISK_USAGE}%)${NC}"
elif [[ $DISK_USAGE -lt 95 ]]; then
    echo -e "${YELLOW}⚠ Disk usage high (${DISK_USAGE}%)${NC}"
    ISSUES=$((ISSUES + 1))
else
    echo -e "${RED}✗ Disk usage critical (${DISK_USAGE}%)${NC}"
    ISSUES=$((ISSUES + 1))
fi

# Check 5: Dependencies
echo -e "${YELLOW}[5/8] Checking dependencies...${NC}"
for cmd in bash gzip find stat date; do
    if command -v $cmd &> /dev/null; then
        echo -e "${GREEN}✓ ${cmd}${NC}"
    else
        echo -e "${RED}✗ ${cmd} not found${NC}"
        ISSUES=$((ISSUES + 1))
    fi
done

# Check 6: Optional dependencies
echo -e "${YELLOW}[6/8] Checking optional dependencies...${NC}"
command -v logger &> /dev/null && echo -e "${GREEN}✓ logger (syslog)${NC}" || echo -e "${YELLOW}⚠ logger not found (syslog disabled)${NC}"
command -v mail &> /dev/null && echo -e "${GREEN}✓ mail (email alerts)${NC}" || echo -e "${YELLOW}⚠ mail not found (email alerts disabled)${NC}"

# Check 7: Test log write
echo -e "${YELLOW}[7/8] Testing log write...${NC}"
if "$SCRIPT_FILE" 'health-check' 'health_check.sh' 'INFO' 'Health check test' 2>/dev/null; then
    echo -e "${GREEN}✓ Log write successful${NC}"
    rm -rf "${LOG_DIR}/health-check" 2>/dev/null
else
    echo -e "${RED}✗ Log write failed${NC}"
    ISSUES=$((ISSUES + 1))
fi

# Check 8: Log structure
echo -e "${YELLOW}[8/8] Checking log structure...${NC}"
VALID_TASKS=0
INVALID_TASKS=0

for task_dir in "${LOG_DIR}"/*; do
    if [[ -d "$task_dir" ]]; then
        if [[ -d "${task_dir}/current" ]] && [[ -d "${task_dir}/archive" ]]; then
            VALID_TASKS=$((VALID_TASKS + 1))
        else
            INVALID_TASKS=$((INVALID_TASKS + 1))
            echo -e "${YELLOW}⚠ Invalid structure: $(basename "$task_dir")${NC}"
        fi
    fi
done

echo "  Valid task directories: ${VALID_TASKS}"
if [[ $INVALID_TASKS -gt 0 ]]; then
    echo -e "  ${YELLOW}Invalid task directories: ${INVALID_TASKS}${NC}"
    ISSUES=$((ISSUES + 1))
fi

# Summary
echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║              Health Check Summary                          ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

if [[ $ISSUES -eq 0 ]]; then
    echo -e "${GREEN}✓ All checks passed${NC}"
    echo -e "${GREEN}System is healthy${NC}"
    exit 0
else
    echo -e "${YELLOW}⚠ Found ${ISSUES} issue(s)${NC}"
    echo -e "${YELLOW}Review the output above for details${NC}"
    exit 1
fi
