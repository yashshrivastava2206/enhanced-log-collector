#!/bin/bash
################################################################################
# Installation Script for Enhanced Log Collector
################################################################################

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m'

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
PREFIX="/opt/scripts"
CONFIG_DIR="/etc"
LOG_DIR="/var/log"
BACKUP_DIR="/opt/backups/logcollector"

echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║     Enhanced Log Collector Installation v2.0              ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}Error: This script must be run as root${NC}"
   exit 1
fi

# Check dependencies
echo -e "${YELLOW}[1/6] Checking dependencies...${NC}"
for cmd in bash gzip find stat date; do
    if ! command -v $cmd &> /dev/null; then
        echo -e "${RED}Error: Required command '$cmd' not found${NC}"
        exit 1
    fi
done
echo -e "${GREEN}✓ All required dependencies found${NC}"

# Backup existing installation
if [[ -f "${PREFIX}/logCollector.sh" ]]; then
    echo -e "${YELLOW}[2/6] Backing up existing installation...${NC}"
    mkdir -p "${BACKUP_DIR}"
    BACKUP_FILE="${BACKUP_DIR}/logCollector-$(date +%Y%m%d-%H%M%S).tar.gz"
    tar -czf "${BACKUP_FILE}" \
        "${PREFIX}/logCollector.sh" \
        "${CONFIG_DIR}/logCollector.conf" 2>/dev/null || true
    echo -e "${GREEN}✓ Backup created: ${BACKUP_FILE}${NC}"
else
    echo -e "${YELLOW}[2/6] No existing installation found${NC}"
fi

# Create directories
echo -e "${YELLOW}[3/6] Creating directory structure...${NC}"
mkdir -p "${PREFIX}"
mkdir -p "${LOG_DIR}"
chmod 755 "${PREFIX}"
chmod 755 "${LOG_DIR}"
echo -e "${GREEN}✓ Directories created${NC}"

# Install main script
echo -e "${YELLOW}[4/6] Installing logCollector.sh...${NC}"
cp "${REPO_DIR}/bin/logCollector.sh" "${PREFIX}/logCollector.sh"
chmod 755 "${PREFIX}/logCollector.sh"
chown root:root "${PREFIX}/logCollector.sh"
echo -e "${GREEN}✓ Script installed to ${PREFIX}/logCollector.sh${NC}"

# Install configuration
echo -e "${YELLOW}[5/6] Installing configuration...${NC}"
if [[ ! -f "${CONFIG_DIR}/logCollector.conf" ]]; then
    cp "${REPO_DIR}/config/logCollector.conf.example" "${CONFIG_DIR}/logCollector.conf"
    chmod 644 "${CONFIG_DIR}/logCollector.conf"
    echo -e "${GREEN}✓ Configuration installed to ${CONFIG_DIR}/logCollector.conf${NC}"
else
    echo -e "${YELLOW}⚠ Configuration file already exists, skipping${NC}"
    echo -e "${YELLOW}  New example available at: ${REPO_DIR}/config/logCollector.conf.example${NC}"
fi

# Test installation
echo -e "${YELLOW}[6/6] Testing installation...${NC}"
if "${PREFIX}/logCollector.sh" 'install-test' 'install.sh' 'INFO' 'Installation test' --console > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Installation test successful${NC}"
else
    echo -e "${RED}✗ Installation test failed${NC}"
    exit 1
fi

# Display summary
echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║            Installation Completed Successfully             ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}Installation Details:${NC}"
echo -e "  Script:        ${PREFIX}/logCollector.sh"
echo -e "  Config:        ${CONFIG_DIR}/logCollector.conf"
echo -e "  Log Directory: ${LOG_DIR}"
echo ""
echo -e "${YELLOW}Next Steps:${NC}"
echo -e "  1. Review and customize: ${CONFIG_DIR}/logCollector.conf"
echo -e "  2. Test with: ${PREFIX}/logCollector.sh 'test' 'test.sh' 'INFO' 'Hello World' --console"
echo -e "  3. View logs: ls -la ${LOG_DIR}/test/current/"
echo -e "  4. Read docs: ${REPO_DIR}/docs/README.md"
echo ""
echo -e "${GREEN}Installation complete!${NC}"
