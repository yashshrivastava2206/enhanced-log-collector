#!/bin/bash
################################################################################
# Migration Tool - v1.0 to v2.0
################################################################################

LOG_DIR="/var/log"
BACKUP_DIR="/opt/backups/logcollector/migration"

GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║        Migration Tool: v1.0 → v2.0                         ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}Error: This script must be run as root${NC}"
   exit 1
fi

# Create backup
echo -e "${YELLOW}[1/4] Creating backup...${NC}"
mkdir -p "$BACKUP_DIR"
BACKUP_FILE="${BACKUP_DIR}/pre-migration-$(date +%Y%m%d-%H%M%S).tar.gz"
tar -czf "$BACKUP_FILE" "$LOG_DIR" 2>/dev/null
echo -e "${GREEN}✓ Backup created: ${BACKUP_FILE}${NC}"

# Detect v1.0 structure
echo -e "${YELLOW}[2/4] Detecting v1.0 log directories...${NC}"
MIGRATED=0
SKIPPED=0

for task_dir in "${LOG_DIR}"/*; do
    if [[ -d "$task_dir" ]]; then
        task_name=$(basename "$task_dir")
        
        # Check if already migrated
        if [[ -d "${task_dir}/current" ]] && [[ -d "${task_dir}/archive" ]]; then
            echo -e "${YELLOW}  Skipping ${task_name} (already migrated)${NC}"
            SKIPPED=$((SKIPPED + 1))
            continue
        fi
        
        # Check if it has log files
        if ls "${task_dir}"/*.log &>/dev/null || ls "${task_dir}"/*.log.gz &>/dev/null; then
            echo -e "${GREEN}  Found ${task_name}${NC}"
            
            # Migrate structure
            echo -e "${YELLOW}[3/4] Migrating ${task_name}...${NC}"
            
            mkdir -p "${task_dir}/current"
            mkdir -p "${task_dir}/archive"
            
            # Move .log files to current/
            if ls "${task_dir}"/*.log &>/dev/null; then
                mv "${task_dir}"/*.log "${task_dir}/current/" 2>/dev/null
                echo "    Moved .log files to current/"
            fi
            
            # Move .log.gz files to archive/
            if ls "${task_dir}"/*.log.gz &>/dev/null; then
                mv "${task_dir}"/*.log.gz "${task_dir}/archive/" 2>/dev/null
                echo "    Moved .log.gz files to archive/"
            fi
            
            MIGRATED=$((MIGRATED + 1))
        fi
    fi
done

echo ""
echo -e "${YELLOW}[4/4] Updating log file naming convention...${NC}"

# Rename old format logs to new format if needed
for task_dir in "${LOG_DIR}"/*/current; do
    if [[ -d "$task_dir" ]]; then
        for logfile in "${task_dir}"/*.log; do
            if [[ -f "$logfile" ]]; then
                # Check if already in new format (contains date)
                if [[ ! "$logfile" =~ _[0-9]{4}-[0-9]{2}-[0-9]{2}\.log$ ]]; then
                    # Add today's date
                    new_name="${logfile%.log}_$(date +%Y-%m-%d).log"
                    mv "$logfile" "$new_name" 2>/dev/null
                    echo "  Renamed: $(basename "$logfile") → $(basename "$new_name")"
                fi
            fi
        done
    fi
done

# Summary
echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║              Migration Complete                            ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo "Migration Summary:"
echo "  Directories migrated: ${MIGRATED}"
echo "  Directories skipped:  ${SKIPPED}"
echo "  Backup location:      ${BACKUP_FILE}"
echo ""
echo -e "${YELLOW}Next Steps:${NC}"
echo "  1. Verify migrated logs in ${LOG_DIR}"
echo "  2. Test with: /opt/scripts/logCollector.sh 'test' 'test.sh' 'INFO' 'Migration test' --console"
echo "  3. Remove backup after verification: rm ${BACKUP_FILE}"
echo ""
