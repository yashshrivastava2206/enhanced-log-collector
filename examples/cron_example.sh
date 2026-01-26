#!/bin/bash
################################################################################
# Cron Job Example with Logging
################################################################################

# This script demonstrates how to use logCollector in cron jobs

LOG="/opt/scripts/logCollector.sh"
TASK="cron-backup"
SCRIPT=$(basename "$0")

# Wrapper function
log() {
    $LOG "$TASK" "$SCRIPT" "$1" "$2" "${@:3}"
}

# Start
log 'INFO' "=== Cron backup job started ===" --console

# Check prerequisites
log 'DEBUG' "Checking disk space..."
DISK_USAGE=$(df -h /backup | tail -1 | awk '{print $5}' | tr -d '%')

if [ "$DISK_USAGE" -gt 90 ]; then
    log 'CRITICAL' "Disk usage critical: ${DISK_USAGE}%" --email
    exit 1
fi

log 'INFO' "Disk usage OK: ${DISK_USAGE}%"

# Perform backup
log 'INFO' "Starting database dump..."
START=$(date +%s)

if pg_dump mydb > /backup/mydb_$(date +%Y%m%d).sql 2>/tmp/backup.err; then
    END=$(date +%s)
    DURATION=$((END - START))
    SIZE=$(du -h /backup/mydb_$(date +%Y%m%d).sql | cut -f1)
    
    log 'INFO' "Backup completed successfully" \
        --json \
        --metadata duration="${DURATION}s" \
        --metadata size="$SIZE"
else
    ERROR=$(cat /tmp/backup.err)
    log 'ERROR' "Backup failed: $ERROR" --email
    exit 1
fi

# Cleanup old backups
log 'INFO' "Cleaning up old backups..."
find /backup -name "mydb_*.sql" -mtime +7 -delete

log 'INFO' "=== Cron backup job completed ==="
exit 0

# Add to crontab:
# 0 2 * * * /path/to/cron_example.sh >> /var/log/cron-backup.log 2>&1
