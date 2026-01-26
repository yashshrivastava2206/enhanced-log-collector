#!/bin/bash
################################################################################
# Uninstallation Script for Enhanced Log Collector
################################################################################

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m'

PREFIX="/opt/scripts"
CONFIG_DIR="/etc"
BACKUP_DIR="/opt/backups/logcollector"

echo -e "${YELLOW}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${YELLOW}║     Enhanced Log Collector Uninstallation                  ║${NC}"
echo -e "${YELLOW}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}Error: This script must be run as root${NC}"
   exit 1
fi

# Confirm uninstallation
read -p "Are you sure you want to uninstall? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Uninstallation cancelled${NC}"
    exit 0
fi

# Backup before uninstalling
echo -e "${YELLOW}[1/4] Creating backup...${NC}"
if [[ -f "${PREFIX}/logCollector.sh" ]]; then
    mkdir -p "${BACKUP_DIR}"
    BACKUP_FILE="${BACKUP_DIR}/uninstall-backup-$(date +%Y%m%d-%H%M%S).tar.gz"
    tar -czf "${BACKUP_FILE}" \
        "${PREFIX}/logCollector.sh" \
        "${CONFIG_DIR}/logCollector.conf" 2>/dev/null || true
    echo -e "${GREEN}✓ Backup created: ${BACKUP_FILE}${NC}"
fi

# Remove script
echo -e "${YELLOW}[2/4] Removing script...${NC}"
if [[ -f "${PREFIX}/logCollector.sh" ]]; then
    rm -f "${PREFIX}/logCollector.sh"
    echo -e "${GREEN}✓ Script removed${NC}"
fi

# Remove configuration (with confirmation)
echo -e "${YELLOW}[3/4] Configuration file...${NC}"
read -p "Remove configuration file? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    rm -f "${CONFIG_DIR}/logCollector.conf"
    echo -e "${GREEN}✓ Configuration removed${NC}"
else
    echo -e "${YELLOW}⚠ Configuration file preserved${NC}"
fi

# Log files
echo -e "${YELLOW}[4/4] Log files...${NC}"
read -p "Remove ALL log files in /var/log/*? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${RED}⚠ This will delete all logs created by logCollector!${NC}"
    read -p "Are you ABSOLUTELY sure? (yes/no): " -r
    if [[ $REPLY == "yes" ]]; then
        # Remove only directories with log collector structure
        find /var/log -maxdepth 1 -type d -exec sh -c 'test -d "$1/current" && test -d "$1/archive"' _ {} \; -print | while read dir; do
            rm -rf "$dir"
            echo -e "${GREEN}✓ Removed: $dir${NC}"
        done
    fi
else
    echo -e "${YELLOW}⚠ Log files preserved${NC}"
fi

echo ""
echo -e "${GREEN}Uninstallation complete${NC}"
echo -e "${YELLOW}Backup location: ${BACKUP_DIR}${NC}"
