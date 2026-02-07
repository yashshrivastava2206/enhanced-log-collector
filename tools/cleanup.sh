#!/bin/bash
################################################################################
# Cleanup Tool - Remove old logs based on retention policy
################################################################################

LOG_DIR="/var/log"
CONFIG_FILE="/etc/logCollector.conf"
DRY_RUN=false

# Colors
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m'

# Load config
if [[ -f "$CONFIG_FILE" ]]; then
    source "$CONFIG_FILE"
fi

# Defaults
LOG_RETENTION_DAYS=${LOG_RETENTION_DAYS:-30}
ARCHIVE_RETENTION_DAYS=${ARCHIVE_RETENTION_DAYS:-90}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --log-retention)
            LOG_RETENTION_DAYS=$2
            shift 2
            ;;
        --archive-retention)
            ARCHIVE_RETENTION_DAYS=$2
            shift 2
            ;;
        *)
            echo "Usage: $0 [--dry-run] [--log-retention DAYS] [--archive-retention DAYS]"
            exit 1
            ;;
    esac
done

echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║              Log Cleanup Tool                              ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

[[ "$DRY_RUN" == "true" ]] && echo -e "${YELLOW}DRY RUN MODE - No files will be deleted${NC}" && echo ""

echo "Retention Policy:"
echo "  Uncompressed logs: ${LOG_RETENTION_DAYS} days"
echo "  Compressed archives: ${ARCHIVE_RETENTION_DAYS} days"
echo ""

DELETED_COUNT=0
FREED_SPACE=0

# Cleanup function
cleanup_directory() {
    local dir=$1
    local pattern=$2
    local days=$3
    local label=$4
    
    echo -e "${YELLOW}Cleaning ${label}...${NC}"
    
    while IFS= read -r -d '' file; do
        local size=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null)
        FREED_SPACE=$((FREED_SPACE + size))
        DELETED_COUNT=$((DELETED_COUNT + 1))
        
        if [[ "$DRY_RUN" == "true" ]]; then
            echo "  [DRY RUN] Would delete: $file ($(numfmt --to=iec-i --suffix=B $size 2>/dev/null || echo "${size} bytes"))"
        else
            echo "  Deleting: $file ($(numfmt --to=iec-i --suffix=B $size 2>/dev/null || echo "${size} bytes"))"
            rm -f "$file"
        fi
    done < <(find "$dir" -name "$pattern" -type f -mtime +${days} -print0 2>/dev/null)
}

# Process each task
for task_dir in "${LOG_DIR}"/*; do
    if [[ -d "$task_dir" ]]; then
        task_name=$(basename "$task_dir")
        echo -e "${GREEN}Task: ${task_name}${NC}"
        
        # Cleanup uncompressed logs in archive
        if [[ -d "${task_dir}/archive" ]]; then
            cleanup_directory "${task_dir}/archive" "*.log" "$LOG_RETENTION_DAYS" "uncompressed archives"
        fi
        
        # Cleanup compressed archives
        if [[ -d "${task_dir}/archive" ]]; then
            cleanup_directory "${task_dir}/archive" "*.log.gz" "$ARCHIVE_RETENTION_DAYS" "compressed archives"
        fi
        
        echo ""
    fi
done

# Summary
echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║              Cleanup Summary                               ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo "Files processed: ${DELETED_COUNT}"
echo "Space freed: $(numfmt --to=iec-i --suffix=B $FREED_SPACE 2>/dev/null || echo "${FREED_SPACE} bytes")"
echo ""

[[ "$DRY_RUN" == "true" ]] && echo -e "${YELLOW}Run without --dry-run to actually delete files${NC}"
