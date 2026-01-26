#!/bin/bash
################################################################################
# Upgrade Script for Enhanced Log Collector
################################################################################

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
PREFIX="/opt/scripts"
CONFIG_DIR="/etc"
BACKUP_DIR="/opt/backups/logcollector"

echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║     Enhanced Log Collector Upgrade                         ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}Error: This script must be run as root${NC}"
   exit 1
fi

# Detect current version
CURRENT_VERSION="unknown"
if [[ -f "${PREFIX}/logCollector.sh" ]]; then
    CURRENT_VERSION=$(grep 'SCRIPT_VERSION=' "${PREFIX}/logCollector.sh" | head -1 | cut -d'"' -f2)
fi

NEW_VERSION=$(cat "${REPO_DIR}/VERSION")

echo -e "${YELLOW}Current Version: ${CURRENT_VERSION}${NC}"
echo -e "${YELLOW}New Version:     ${NEW_VERSION}${NC}"
echo ""

# Backup current installation
echo -e "${YELLOW}[1/5] Creating backup...${NC}"
mkdir -p "${BACKUP_DIR}"
BACKUP_FILE="${BACKUP_DIR}/upgrade-from-${CURRENT_VERSION}-$(date +%Y%m%d-%H%M%S).tar.gz"

if [[ -f "${PREFIX}/logCollector.sh" ]]; then
    tar -czf "${BACKUP_FILE}" \
        "${PREFIX}/logCollector.sh" \
        "${CONFIG_DIR}/logCollector.conf" \
        /var/log/*/current/*.log 2>/dev/null || true
    echo -e "${GREEN}✓ Backup created: ${BACKUP_FILE}${NC}"
else
    echo -e "${YELLOW}⚠ No existing installation found, performing fresh install${NC}"
fi

# Upgrade script
echo -e "${YELLOW}[2/5] Upgrading script...${NC}"
cp "${REPO_DIR}/bin/logCollector.sh" "${PREFIX}/logCollector.sh"
chmod 755 "${PREFIX}/logCollector.sh"
chown root:root "${PREFIX}/logCollector.sh"
echo -e "${GREEN}✓ Script upgraded${NC}"

# Merge configuration
echo -e "${YELLOW}[3/5] Checking configuration...${NC}"
if [[ -f "${CONFIG_DIR}/logCollector.conf" ]]; then
    echo -e "${YELLOW}⚠ Existing configuration found${NC}"
    echo -e "${YELLOW}  Comparing with new defaults...${NC}"
    
    # Check for new config options
    NEW_OPTIONS=$(comm -13 \
        <(grep '^[A-Z_]*=' "${CONFIG_DIR}/logCollector.conf" | cut -d'=' -f1 | sort) \
        <(grep '^[A-Z_]*=' "${REPO_DIR}/config/logCollector.conf.example" | cut -d'=' -f1 | sort))
    
    if [[ -n "$NEW_OPTIONS" ]]; then
        echo -e "${YELLOW}  New configuration options available:${NC}"
        echo "$NEW_OPTIONS" | while read opt; do
            echo -e "    - $opt"
        done
        echo -e "${YELLOW}  Review: ${REPO_DIR}/config/logCollector.conf.example${NC}"
    else
        echo -e "${GREEN}✓ Configuration is up to date${NC}"
    fi
else
    cp "${REPO_DIR}/config/logCollector.conf.example" "${CONFIG_DIR}/logCollector.conf"
    echo -e "${GREEN}✓ Configuration installed${NC}"
fi

# Migrate log structure if needed
echo -e "${YELLOW}[4/5] Checking log structure...${NC}"
MIGRATED=0
for task_dir in /var/log/*/; do
    if [[ -d "$task_dir" ]]; then
        # Check if already migrated (has current/ and archive/ subdirs)
        if [[ ! -d "${task_dir}current" ]] && [[ ! -d "${task_dir}archive" ]]; then
            # Old structure detected, migrate
            echo -e "${YELLOW}  Migrating: ${task_dir}${NC}"
            mkdir -p "${task_dir}current" "${task_dir}archive"
            
            # Move .log files to current/
            find "$task_dir" -maxdepth 1 -name "*.log" -type f -exec mv {} "${task_dir}current/" \; 2>/dev/null || true
            
            # Move .log.gz files to archive/
            find "$task_dir" -maxdepth 1 -name "*.log.gz" -type f -exec mv {} "${task_dir}archive/" \; 2>/dev/null || true
            
            MIGRATED=$((MIGRATED + 1))
        fi
    fi
done

if [[ $MIGRATED -gt 0 ]]; then
    echo -e "${GREEN}✓ Migrated ${MIGRATED} log directories${NC}"
else
    echo -e "${GREEN}✓ Log structure already up to date${NC}"
fi

# Test upgraded installation
echo -e "${YELLOW}[5/5] Testing upgrade...${NC}"
if "${PREFIX}/logCollector.sh" 'upgrade-test' 'upgrade.sh' 'INFO' "Upgraded to v${NEW_VERSION}" --console > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Upgrade test successful${NC}"
else
    echo -e "${RED}✗ Upgrade test failed${NC}"
    echo -e "${YELLOW}  You can restore from: ${BACKUP_FILE}${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║            Upgrade Completed Successfully                  ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}Upgrade Summary:${NC}"
echo -e "  Previous Version: ${CURRENT_VERSION}"
echo -e "  Current Version:  ${NEW_VERSION}"
echo -e "  Backup Location:  ${BACKUP_FILE}"
echo ""
echo -e "${YELLOW}Post-Upgrade Steps:${NC}"
echo -e "  1. Review configuration changes in ${CONFIG_DIR}/logCollector.conf"
echo -e "  2. Check changelog: ${REPO_DIR}/CHANGELOG.md"
echo -e "  3. Test with: ${PREFIX}/logCollector.sh 'test' 'test.sh' 'INFO' 'Test' --console"
echo ""
