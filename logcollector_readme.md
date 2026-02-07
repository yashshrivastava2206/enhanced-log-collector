# Enhanced Log Collector System

**Version:** 2.0  
**Location:** `/opt/scripts/logCollector.sh`  
**Owner:** DB Team  
**License:** Internal Use

---

## 📋 Table of Contents

1. [Overview](#overview)
2. [Features](#features)
3. [Installation](#installation)
4. [Quick Start](#quick-start)
5. [Usage Examples](#usage-examples)
6. [Configuration](#configuration)
7. [Log Levels](#log-levels)
8. [Output Formats](#output-formats)
9. [Log Rotation & Compression](#log-rotation--compression)
10. [Directory Structure](#directory-structure)
11. [Integration Guide](#integration-guide)
12. [Troubleshooting](#troubleshooting)
13. [Migration from v1.0](#migration-from-v10)
14. [Best Practices](#best-practices)
15. [FAQ](#faq)

---

## 🎯 Overview

The Enhanced Log Collector is an enterprise-grade logging system designed for production database and application environments. It transforms simple logging into a comprehensive observability solution with automatic rotation, compression, retention policies, and multiple output formats.

### What's New in v2.0

- ✅ **Automatic log rotation** (size and date-based)
- ✅ **Compression** with gzip (50-90% space savings)
- ✅ **Configurable retention policies** (30/90 days default)
- ✅ **Multiple output formats** (plain text, JSON, syslog, console)
- ✅ **Email alerts** for critical events
- ✅ **Rich metadata** (hostname, PID, user, timestamps)
- ✅ **Stack trace support** for debugging
- ✅ **External configuration file**
- ✅ **Seven log levels** (DEBUG to FATAL)
- ✅ **Colored console output** with ANSI codes
- ✅ **Background cleanup** operations

---

## 🚀 Features

### Core Capabilities

| Feature | Description |
|---------|-------------|
| **Multi-Level Logging** | 7 severity levels from DEBUG to FATAL |
| **Format Flexibility** | Plain text, JSON, syslog, colored console |
| **Auto Rotation** | Size-based (100MB default) and date-based rotation |
| **Compression** | Automatic gzip compression of archived logs |
| **Retention Management** | Configurable retention with automatic cleanup |
| **Email Alerts** | Notifications for CRITICAL and FATAL events |
| **Rich Metadata** | Hostname, PID, user, timestamp, custom fields |
| **Stack Traces** | Optional stack trace inclusion for errors |
| **Syslog Integration** | Send logs to system logger |
| **Background Processing** | Non-blocking compression and cleanup |

### Advanced Features

- **Configuration File Support:** `/etc/logCollector.conf`
- **Per-Task Directories:** Organized log structure by task name
- **Concurrent Safe:** Handles multiple simultaneous log writes
- **Error Handling:** Graceful failure with fallback mechanisms
- **Performance Optimized:** Minimal overhead, async operations
- **Production Ready:** Battle-tested in enterprise environments

---

## 📦 Installation

### Prerequisites

- Bash 4.0 or higher
- GNU coreutils (date, stat, find)
- gzip (for compression)
- mail/sendmail (for email alerts, optional)
- logger (for syslog, optional)

### Installation Steps

```bash
# 1. Download the script
sudo curl -o /opt/scripts/logCollector.sh https://your-repo/logCollector.sh

# 2. Make it executable
sudo chmod +x /opt/scripts/logCollector.sh

# 3. Create configuration file
sudo cat > /etc/logCollector.conf << 'EOF'
BASE_LOG_DIR="/var/log"
DEFAULT_OWNER="postgres:postgres"
MAX_LOG_SIZE_MB=100
LOG_RETENTION_DAYS=30
ARCHIVE_RETENTION_DAYS=90
ENABLE_COMPRESSION=true
ENABLE_EMAIL_ALERTS=true
ALERT_EMAIL="dba-team@example.com"
ALERT_LEVELS="FATAL,CRITICAL"
EOF

# 4. Set permissions
sudo chown root:root /opt/scripts/logCollector.sh
sudo chmod 755 /opt/scripts/logCollector.sh

# 5. Create base log directory
sudo mkdir -p /var/log
sudo chmod 755 /var/log

# 6. Test installation
/opt/scripts/logCollector.sh 'test' 'test.sh' 'INFO' 'Installation successful' --console
```

---

## ⚡ Quick Start

### Basic Usage

```bash
# Simple info message
./logCollector.sh 'backup' 'backup.sh' 'INFO' 'Backup started'

# Error message with console output
./logCollector.sh 'backup' 'backup.sh' 'ERROR' 'Backup failed' --console

# Critical alert with email
./logCollector.sh 'backup' 'backup.sh' 'FATAL' 'System crash' --email
```

### Integration in Your Scripts

```bash
#!/bin/bash
# your-script.sh

LOG="/opt/scripts/logCollector.sh"
TASK="myapp"
SCRIPT="$0"

# Create log wrapper function
log() {
    $LOG "$TASK" "$SCRIPT" "$1" "$2" --console
}

# Use throughout your script
log "INFO" "Application starting..."

if ! connect_database; then
    log "ERROR" "Database connection failed"
    exit 1
fi

log "INFO" "Application completed successfully"
```

---

## 📖 Usage Examples

### 1. Basic Logging

```bash
# Information message
./logCollector.sh 'backup' 'backup.sh' 'INFO' 'Daily backup initiated'

# Warning message
./logCollector.sh 'backup' 'backup.sh' 'WARNING' 'Disk usage at 85%'

# Error message
./logCollector.sh 'backup' 'backup.sh' 'ERROR' 'Connection timeout to database'

# Critical failure
./logCollector.sh 'backup' 'backup.sh' 'FATAL' 'Unrecoverable database corruption'
```

### 2. With Output Options

```bash
# Display on console with colors
./logCollector.sh 'backup' 'backup.sh' 'INFO' 'Backup started' --console

# Send to syslog
./logCollector.sh 'backup' 'backup.sh' 'ERROR' 'Backup failed' --syslog

# Output in JSON format
./logCollector.sh 'backup' 'backup.sh' 'INFO' 'Backup completed' --json

# Multiple outputs
./logCollector.sh 'backup' 'backup.sh' 'WARNING' 'Low disk space' \
  --console --syslog --json
```

### 3. With Metadata

```bash
# Add custom metadata fields
./logCollector.sh 'backup' 'backup.sh' 'INFO' 'Backup completed' \
  --json \
  --metadata database=production \
  --metadata size=50GB \
  --metadata duration=300s \
  --metadata status=success
```

### 4. Error Debugging

```bash
# Include stack trace for debugging
./logCollector.sh 'backup' 'backup.sh' 'ERROR' 'Unexpected failure' \
  --stacktrace \
  --console
```

### 5. Critical Alerts

```bash
# Send email alert for critical event
./logCollector.sh 'backup' 'backup.sh' 'CRITICAL' 'Database unreachable' \
  --email \
  --metadata uptime=0 \
  --metadata last_success="2 hours ago"
```

### 6. Complete Example Script

```bash
#!/bin/bash
################################################################################
# Backup Script with Enhanced Logging
################################################################################

LOG="/opt/scripts/logCollector.sh"
TASK="backup"
SCRIPT=$(basename "$0")

log() {
    $LOG "$TASK" "$SCRIPT" "$1" "$2" --console "$@"
}

# Start
log "INFO" "=== Database Backup Started ==="

# Check prerequisites
log "DEBUG" "Checking disk space..."
DISK_USAGE=$(df -h /backup | tail -1 | awk '{print $5}' | tr -d '%')

if [ "$DISK_USAGE" -gt 90 ]; then
    log "CRITICAL" "Disk usage critical: ${DISK_USAGE}%" --email
    exit 1
fi

log "INFO" "Disk usage acceptable: ${DISK_USAGE}%"

# Perform backup
log "INFO" "Starting database dump..."
START_TIME=$(date +%s)

if pg_dump production > /backup/production.sql 2>/tmp/backup.err; then
    END_TIME=$(date +%s)
    DURATION=$((END_TIME - START_TIME))
    SIZE=$(du -h /backup/production.sql | cut -f1)
    
    log "INFO" "Backup completed successfully" \
        --metadata duration="${DURATION}s" \
        --metadata size="$SIZE"
else
    ERROR_MSG=$(cat /tmp/backup.err)
    log "ERROR" "Backup failed: $ERROR_MSG" --email --stacktrace
    exit 1
fi

# Cleanup
log "INFO" "Cleaning up old backups..."
find /backup -name "*.sql" -mtime +7 -delete
log "INFO" "=== Backup Completed Successfully ==="

exit 0
```

---

## ⚙️ Configuration

### Configuration File: `/etc/logCollector.conf`

```bash
#!/bin/bash
# Log Collector Configuration File

# Base Configuration
BASE_LOG_DIR="/var/log"              # Root directory for all logs
DEFAULT_OWNER="postgres:postgres"     # Default ownership for log files

# Rotation Settings
MAX_LOG_SIZE_MB=100                   # Rotate logs when they reach this size
LOG_RETENTION_DAYS=30                 # Keep uncompressed logs for this period
ARCHIVE_RETENTION_DAYS=90             # Keep compressed archives for this period

# Compression
ENABLE_COMPRESSION=true               # Automatically compress rotated logs

# Output Formats (default behavior, can be overridden per call)
ENABLE_JSON_FORMAT=false              # Default to plain text format
ENABLE_CONSOLE_OUTPUT=false           # Don't display on console by default
ENABLE_SYSLOG=false                   # Don't send to syslog by default

# Email Alerts
ENABLE_EMAIL_ALERTS=true              # Enable email notifications
ALERT_EMAIL="dba-team@example.com"    # Email address for alerts
ALERT_LEVELS="FATAL,CRITICAL"         # Comma-separated list of levels to alert

# Custom Settings
SCRIPT_VERSION="2.0"
```

### Environment-Specific Configurations

#### Development Environment

```bash
# /etc/logCollector.conf.dev
BASE_LOG_DIR="/var/log"
DEFAULT_OWNER="developer:developer"
MAX_LOG_SIZE_MB=50
LOG_RETENTION_DAYS=7
ARCHIVE_RETENTION_DAYS=14
ENABLE_COMPRESSION=false              # Keep uncompressed for easy viewing
ENABLE_CONSOLE_OUTPUT=true            # Show all logs on console
ENABLE_EMAIL_ALERTS=false             # No email in development
```

#### Testing Environment

```bash
# /etc/logCollector.conf.test
BASE_LOG_DIR="/var/log"
DEFAULT_OWNER="postgres:postgres"
MAX_LOG_SIZE_MB=75
LOG_RETENTION_DAYS=14
ARCHIVE_RETENTION_DAYS=30
ENABLE_COMPRESSION=true
ENABLE_JSON_FORMAT=true               # JSON for log aggregation testing
ENABLE_EMAIL_ALERTS=true
ALERT_EMAIL="qa-team@example.com"
ALERT_LEVELS="FATAL,CRITICAL,ERROR"   # More aggressive alerting
```

#### Production Environment

```bash
# /etc/logCollector.conf.prod
BASE_LOG_DIR="/var/log"
DEFAULT_OWNER="postgres:postgres"
MAX_LOG_SIZE_MB=100
LOG_RETENTION_DAYS=30
ARCHIVE_RETENTION_DAYS=90
ENABLE_COMPRESSION=true
ENABLE_SYSLOG=true                    # Send to centralized syslog
ENABLE_EMAIL_ALERTS=true
ALERT_EMAIL="dba-oncall@example.com"
ALERT_LEVELS="FATAL,CRITICAL"         # Only critical alerts
```

---

## 📊 Log Levels

The system supports seven severity levels, ordered from lowest to highest:

| Level | Value | Color | Use Case | Example |
|-------|-------|-------|----------|---------|
| **DEBUG** | 0 | Cyan | Detailed debugging information | Variable values, loop iterations |
| **INFO** | 1 | Green | General informational messages | Process started, operation completed |
| **NOTICE** | 2 | Blue | Normal but significant events | Configuration loaded, service ready |
| **WARNING** | 3 | Yellow | Warning messages | High disk usage, deprecated API |
| **ERROR** | 4 | Red | Error conditions | Connection failed, file not found |
| **CRITICAL** | 5 | Bold Red | Critical conditions | Database unavailable, disk full |
| **FATAL** | 6 | Bold Magenta | Fatal errors causing termination | System crash, unrecoverable error |

### When to Use Each Level

```bash
# DEBUG - Development and troubleshooting
log "DEBUG" "Processing record 1523 of 10000"
log "DEBUG" "Variable state: user=$USER, path=$PATH"

# INFO - Normal operations
log "INFO" "Backup process started"
log "INFO" "Successfully connected to database"
log "INFO" "Processed 10,000 records in 5 minutes"

# NOTICE - Significant but normal events
log "NOTICE" "Configuration file reloaded"
log "NOTICE" "Switched to standby database"
log "NOTICE" "Service entering maintenance mode"

# WARNING - Potential issues
log "WARNING" "Disk usage at 85%"
log "WARNING" "Query took longer than expected (15s)"
log "WARNING" "Connection pool near capacity"

# ERROR - Failures that don't stop the application
log "ERROR" "Failed to send notification email"
log "ERROR" "Unable to connect to backup server"
log "ERROR" "Invalid data format in input file"

# CRITICAL - Serious problems requiring immediate attention
log "CRITICAL" "Primary database unreachable"
log "CRITICAL" "Disk usage exceeded 95%"
log "CRITICAL" "Security breach detected"

# FATAL - Application cannot continue
log "FATAL" "Configuration file missing"
log "FATAL" "Required service not responding"
log "FATAL" "Database corruption detected"
```

---

## 📝 Output Formats

### 1. Plain Text Format (Default)

```
2026-01-04T10:30:15+0530 [pgserver01.example.com] [backup.sh] [PID:12345] [postgres] [INFO] Database backup started
```

**Components:**
- ISO 8601 timestamp with timezone
- Fully qualified hostname
- Script name
- Process ID
- Username
- Log level
- Message

**Best for:** Traditional log files, grep operations, human readability

### 2. JSON Format (`--json`)

```json
{
  "timestamp": "2026-01-04T10:30:15+0530",
  "hostname": "pgserver01.example.com",
  "script": "backup.sh",
  "level": "INFO",
  "message": "Database backup completed",
  "pid": 12345,
  "user": "postgres",
  "version": "2.0",
  "metadata": {
    "database": "production",
    "size": "50GB",
    "duration": "300s"
  }
}
```

**Best for:**  
- Log aggregation tools (Elasticsearch, Splunk, Datadog)
- Automated parsing and analysis
- Machine learning on log data
- API integration

### 3. Colored Console Output (`--console`)

```bash
[INFO] 2026-01-04T10:30:15+0530 [backup.sh] Database backup started
[WARNING] 2026-01-04T10:35:22+0530 [backup.sh] Disk usage at 85%
[ERROR] 2026-01-04T10:40:18+0530 [backup.sh] Connection timeout
```

**Color Scheme:**
- DEBUG: Cyan
- INFO: Green  
- NOTICE: Blue
- WARNING: Yellow
- ERROR: Red
- CRITICAL: Bold Red
- FATAL: Bold Magenta

**Best for:** Real-time monitoring, terminal output, development

### 4. Syslog Format (`--syslog`)

Integrates with system logger using appropriate priority mapping:

```
Jan 04 10:30:15 pgserver01 backup.sh[12345]: Database backup started
Jan 04 10:35:22 pgserver01 backup.sh[12345]: Disk usage at 85%
```

**Priority Mapping:**
- DEBUG → debug
- INFO → info
- NOTICE → notice
- WARNING → warning
- ERROR → err
- CRITICAL → crit
- FATAL → alert

**Best for:** Centralized logging, system-wide log collection, compliance

---

## 🔄 Log Rotation & Compression

### Rotation Triggers

1. **Size-Based:** Log reaches MAX_LOG_SIZE_MB (default: 100MB)
2. **Date-Based:** New log file created daily

### Rotation Process

```
1. Check if current log >= MAX_LOG_SIZE_MB
   ↓
2. If yes, move to archive/ with timestamp
   ↓
3. Create new empty log file
   ↓
4. Compress archived log (if enabled)
   ↓
5. Delete old archives beyond retention period
```

### Example Timeline

```
Day 1:  backup.sh_2026-01-01.log (50 MB) → Active
Day 2:  backup.sh_2026-01-02.log (95 MB) → Active
Day 3:  backup.sh_2026-01-03.log (110 MB) → Rotated!
        → Moved to archive/backup.sh_20260103_143022.log
        → Compressed to backup.sh_20260103_143022.log.gz (12 MB)
        → New backup.sh_2026-01-03.log created
```

### Compression Savings

| Original Size | Compressed Size | Savings |
|--------------|-----------------|---------|
| 100 MB | 10-15 MB | 85-90% |
| 500 MB | 50-75 MB | 85-90% |
| 1 GB | 100-150 MB | 85-90% |

### Cleanup Schedule

- **Uncompressed logs:** Deleted after LOG_RETENTION_DAYS (30 days default)
- **Compressed archives:** Deleted after ARCHIVE_RETENTION_DAYS (90 days default)
- **Cleanup frequency:** Automatically triggered (1% probability per log call)

---

## 📁 Directory Structure

### Standard Layout

```
/var/log/
├── backup/                          # Task-specific directory
│   ├── current/                     # Active log files
│   │   ├── backup.sh_2026-01-04.log
│   │   └── restore.sh_2026-01-04.log
│   ├── archive/                     # Rotated & compressed logs
│   │   ├── backup.sh_20260103_143022.log.gz
│   │   ├── backup.sh_20260102_151533.log.gz
│   │   └── restore.sh_20260101_120015.log.gz
│   └── metadata.json                # Optional metadata file
│
├── maintenance/
│   ├── current/
│   │   ├── vacuum.sh_2026-01-04.log
│   │   └── reindex.sh_2026-01-04.log
│   └── archive/
│       └── vacuum.sh_20260103_090000.log.gz
│
└── monitoring/
    ├── current/
    │   └── health_check.sh_2026-01-04.log
    └── archive/
        └── health_check.sh_20260103_000000.log.gz
```

### Permissions

```bash
# Directory permissions
drwxr-xr-x (755) postgres:postgres /var/log/backup/
drwxr-xr-x (755) postgres:postgres /var/log/backup/current/
drwxr-xr-x (755) postgres:postgres /var/log/backup/archive/

# File permissions
-rw-r--r-- (644) postgres:postgres backup.sh_2026-01-04.log
-rw-r--r-- (644) postgres:postgres backup.sh_20260103_143022.log.gz
```

---

## 🔗 Integration Guide

### Bash Scripts

```bash
#!/bin/bash
LOG="/opt/scripts/logCollector.sh"

# Method 1: Direct calls
/opt/scripts/logCollector.sh 'myapp' "$0" 'INFO' 'Process started'

# Method 2: Function wrapper
log() {
    local level=$1
    local message=$2
    shift 2
    $LOG 'myapp' "$(basename $0)" "$level" "$message" "$@"
}

log 'INFO' 'Application started' --console
log 'ERROR' 'Database connection failed' --email
```

### Python Integration

```python
#!/usr/bin/env python3
import subprocess
import sys

def log(task, script, level, message, *args):
    """Send log to logCollector.sh"""
    cmd = [
        '/opt/scripts/logCollector.sh',
        task,
        script,
        level,
        message
    ] + list(args)
    
    try:
        subprocess.run(cmd, check=True)
    except subprocess.CalledProcessError as e:
        print(f"Logging failed: {e}", file=sys.stderr)

# Usage
log('myapp', 'app.py', 'INFO', 'Application started', '--console')
log('myapp', 'app.py', 'ERROR', 'Database error', '--email')
```

### Cron Jobs

```bash
# /etc/cron.d/backup

# Backup job with logging
0 2 * * * postgres /opt/scripts/backup.sh 2>&1 | \
  while read line; do \
    /opt/scripts/logCollector.sh 'backup-cron' 'backup.sh' 'INFO' "$line"; \
  done
```

### Systemd Service

```ini
# /etc/systemd/system/myapp.service

[Unit]
Description=My Application
After=network.target

[Service]
Type=simple
User=postgres
ExecStart=/opt/myapp/start.sh
ExecStartPre=/opt/scripts/logCollector.sh 'myapp' 'start.sh' 'INFO' 'Service starting'
ExecStopPost=/opt/scripts/logCollector.sh 'myapp' 'start.sh' 'INFO' 'Service stopped'

[Install]
WantedBy=multi-user.target
```

---

## 🔧 Troubleshooting

### Common Issues

#### 1. Permission Denied

**Symptom:**
```
ERROR: Failed to create directory: /var/log/backup
```

**Solution:**
```bash
# Ensure base directory exists and has correct permissions
sudo mkdir -p /var/log
sudo chmod 755 /var/log

# Or run script with sudo if necessary
sudo ./logCollector.sh 'backup' 'backup.sh' 'INFO' 'Test message'
```

#### 2. Email Alerts Not Working

**Symptom:**
```
# No emails received for CRITICAL/FATAL events
```

**Solution:**
```bash
# 1. Check mail command is available
which mail || sudo yum install mailx

# 2. Test mail manually
echo "Test" | mail -s "Test Subject" your@email.com

# 3. Check configuration
grep ALERT_EMAIL /etc/logCollector.conf
grep ENABLE_EMAIL_ALERTS /etc/logCollector.conf

# 4. Test with explicit email flag
./logCollector.sh 'test' 'test.sh' 'FATAL' 'Test alert' --email
```

#### 3. Logs Not Rotating

**Symptom:**
```
# Log file grows beyond expected size
-rw-r--r-- 1 postgres postgres 250M backup.sh_2026-01-04.log
```

**Solution:**
```bash
# 1. Check configuration
grep MAX_LOG_SIZE_MB /etc/logCollector.conf

# 2. Verify rotation check is working
./logCollector.sh 'backup' 'backup.sh' 'DEBUG' 'Test rotation'

# 3. Manual rotation if needed
cd /var/log/backup/current
timestamp=$(date +%Y%m%d_%H%M%S)
mv backup.sh_2026-01-04.log ../archive/backup.sh_${timestamp}.log
gzip ../archive/backup.sh_${timestamp}.log
```

#### 4. Compression Not Working

**Symptom:**
```
# Archive files are not compressed
-rw-r--r-- 1 postgres postgres 100M backup.sh_20260103_143022.log
```

**Solution:**
```bash
# 1. Check if gzip is installed
which gzip || sudo yum install gzip

# 2. Check configuration
grep ENABLE_COMPRESSION /etc/logCollector.conf

# 3. Manual compression
cd /var/log/backup/archive
gzip backup.sh_20260103_143022.log
```

#### 5. Invalid Log Level

**Symptom:**
```
ERROR: Invalid log level 'WARN'
Valid levels: DEBUG INFO NOTICE WARNING ERROR CRITICAL FATAL
```

**Solution:**
```bash
# Use correct level name (WARNING, not WARN)
./logCollector.sh 'backup' 'backup.sh' 'WARNING' 'Test message'
```

### Debug Mode

Enable detailed debugging:

```bash
# Add to beginning of script
set -x

# Or run with bash -x
bash -x /opt/scripts/logCollector.sh 'test' 'test.sh' 'DEBUG' 'Test'

# Check what files are being created
ls -laht /var/log/test/

# Check permissions
namei -l /var/log/test/current/test.sh_2026-01-04.log
```

---

## 🔄 Migration from v1.0

### Comparison

| Feature | v1.0 | v2.0 |
|---------|------|------|
| Log Levels | 3 (ERROR, INFO, WARNING) | 7 (DEBUG to FATAL) |
| Output Formats | Plain text only | 4 formats |
| Rotation | Manual | Automatic |
| Compression | None | Automatic |
| Retention | Manual cleanup | Policy-based |
| Metadata | Minimal | Rich |
| Email Alerts | None | Built-in |
| Configuration | Hardcoded | External file |

### Migration Steps

#### Step 1: Backup Current Setup

```bash
# Backup existing logs
tar -czf /backup/logs-v1-$(date +%Y%m%d).tar.gz /var/log/*

# Backup existing scripts
cp /opt/scripts/logCollector.sh /opt/scripts/logCollector.sh.v1.backup
```

#### Step 2: Install v2.0

```bash
# Deploy new version
sudo cp logCollector-v2.sh /opt/scripts/logCollector.sh.new
sudo chmod +x /opt/scripts/logCollector.sh.new

# Create configuration
sudo cp logCollector.conf /etc/logCollector.conf
sudo chmod 644 /etc/logCollector.conf
```

#### Step 3: Test in Parallel

```bash
# Test new version
/opt/scripts/logCollector.sh.new 'test' 'test.sh' 'INFO' 'Test v2.0' --console

# Compare outputs
cat /var/log/test/current/test.sh_*.log
```

#### Step 4: Update Scripts Gradually

```bash
# Update one script at a time
# Old syntax (v1.0):
bash /opt/scripts/logCollector.sh "backup" "$0" "INFO" "Backup started"

# New syntax (v2.0) - backwards compatible:
bash /opt/scripts/logCollector.sh "backup" "$0" "INFO" "Backup started"

# New syntax with features:
bash /opt/scripts/logCollector.sh "backup" "$0" "INFO" "Backup started" --console --json
```

#### Step 5: Reorganize Log Structure

```bash
# v1.0 structure:
/var/log/
└── backup/
    └── backup.sh_2026-01-04.log

# v2.0 structure:
/var/log/
└── backup/
    ├── current/
    │   └── backup.sh_2026-01-04.log
    └── archive/
        └── backup.sh_20260103_143022.log.gz

# Migration script
for task in /var/log/*; do
    if [ -d "$task" ]; then
        mkdir -p "$task/current" "$task/archive"
        mv "$task"/*.log "$task/current/" 2>/dev/null || true
    fi
done
```

#### Step 6: Enable Advanced Features

```bash
# Edit /etc/logCollector.conf
ENABLE_COMPRESSION=true
ENABLE_EMAIL_ALERTS=true
ALERT_EMAIL="your-team@example.com"
```

#### Step 7: Complete Migration

```bash
# Replace old version
sudo mv /opt/scripts/logCollector.sh.new /opt/scripts/logCollector.sh

# Verify all scripts using new version
grep -r "logCollector.sh" /opt/scripts/
```

---

## ✅ Best Practices

### 1. Choose Appropriate Log Levels

```bash
# ✅ Good
log 'INFO' 'Backup started'
log 'WARNING' 'Disk usage at 85%'
log 'ERROR' 'Connection failed, retrying...'
log 'CRITICAL' 'All database connections exhausted'

# ❌ Bad
log 'ERROR' 'Backup started'                    # Wrong level
log 'INFO' 'DATABASE IS DOWN'                    # Should be CRITICAL
log 'FATAL' 'Minor connection hiccup'            # Over-dramatic
```

### 2. Add Meaningful Context

```bash
# ✅ Good
log 'ERROR' 'Failed to connect to database prod-01 on port 5432 after 3 attempts'
log 'INFO' 'Backup completed: 50GB in 300 seconds (166MB/s)'

# ❌ Bad
log 'ERROR' 'Failed'                             # Too vague
log 'INFO' 'Done'                                # No context
```

### 3. Use Metadata for Structured Data

```bash
# ✅ Good
log 'INFO' 'Backup completed' \
    --json \
    --metadata database=production \
    --metadata size=50GB \
    --metadata duration=300s \
    --metadata compression_ratio=0.85

# ❌ Bad
log 'INFO' 'Backup completed. Database: production, Size: 50GB, Duration: 300s'
```

### 4. Standardize Task Names

```bash
# ✅ Good
log 'backup' 'daily_backup.sh' 'INFO' 'Started'
log 'backup' 'weekly_backup.sh' 'INFO' 'Started'
log 'backup' 'restore.sh' 'INFO' 'Started'

# ❌ Bad
log 'daily-backup' 'daily_backup.sh' 'INFO' 'Started'
log 'Backup' 'weekly_backup.sh' 'INFO' 'Started'
log 'RESTORE_TASK' 'restore.sh' 'INFO' 'Started'
```

### 5. Use Console Output During Development

```bash
# Development
log 'DEBUG' 'Variable x = 123' --console

# Production (no console clutter)
log 'INFO' 'Process completed'
```

### 6. Email Only Critical Events

```bash
# ✅ Good
log 'CRITICAL' 'Database unreachable' --email
log 'FATAL' 'Unrecoverable error' --email

# ❌ Bad
log 'INFO' 'Backup started' --email              # Too noisy
log 'WARNING' 'Disk at 75%' --email              # Not critical enough
```

### 7. Clean Log Messages

```bash
# ✅ Good
log 'INFO' 'Processed 10000 records in 5 minutes'

# ❌ Bad
log 'INFO' '
====================================
PROCESSED 10000 RECORDS IN 5 MINUTES!!!
===================================='
```

### 8. Handle Errors Gracefully

```bash
#!/bin/bash
LOG="/opt/scripts/logCollector.sh"

log() {
    $LOG 'myapp' "$0" "$1" "$2" "${@:3}" 2>/dev/null || {
        echo "[$1] $2" >&2  # Fallback to stderr
    }
}
```

### 9. Test Email Alerts

```bash
# Before production deployment
./logCollector.sh 'test' 'test.sh' 'CRITICAL' 'Test alert' --email

# Verify email received
# Check spam folder
# Verify email address in config
```

### 10. Monitor Disk Usage

```bash
# Set up monitoring for log directories
du -sh /var/log/*/

# Alert if approaching capacity
USAGE=$(df /var/log | tail -1 | awk '{print $5}' | tr -d '%')
if [ $USAGE -gt 80 ]; then
    log 'monitoring' 'disk_check.sh' 'WARNING' "Log partition at ${USAGE}%"
fi
```

---

## ❓ FAQ

### Q: Can I use this with non-Bash scripts?

**A:** Yes! Call it from any language that can execute shell commands:

```python
# Python
import subprocess
subprocess.run(['/opt/scripts/logCollector.sh', 'myapp', 'app.py', 'INFO', 'Message'])
```

```perl
# Perl
system('/opt/scripts/logCollector.sh', 'myapp', 'app.pl', 'INFO', 'Message');
```

### Q: What happens if the log directory is full?

**A:** The script will fail to write. Implement monitoring:

```bash
# Pre-check before logging
FREE_GB=$(df /var/log | tail -1 | awk '{print $4}')
if [ $FREE_GB -lt 1000000 ]; then  # Less than 1GB
    log 'system' 'disk_check.sh' 'CRITICAL' 'Log disk almost full' --email
fi
```

### Q: Can I customize the log format?

**A:** Yes, modify the `format_plain_log()` function in the script:

```bash
format_plain_log() {
    local timestamp=$1
    local level=$4
    local message=$5
    
    # Custom format
    echo "[$level] $timestamp - $message"
}
```

### Q: How do I search compressed logs?

**A:** Use `zgrep` and `zcat`:

```bash
# Search in compressed files
zgrep "ERROR" /var/log/backup/archive/*.log.gz

# View compressed log
zcat /var/log/backup/archive/backup.sh_20260103_143022.log.gz | less

# Search across all logs (compressed and uncompressed)
find /var/log/backup -name "*.log*" -exec zgrep -H "ERROR" {} \;
```

### Q: Can I change retention policies per task?

**A:** Currently global, but you can create task-specific cleanup scripts:

```bash
#!/bin/bash
# cleanup_backup_logs.sh - Custom retention for backup task

# Keep only 7 days for backup logs
find /var/log/backup/archive -name "*.log.gz" -mtime +7 -delete
```

### Q: How do I integrate with log aggregation tools?

**A:** Use JSON format and configure file shipper:

```bash
# Filebeat configuration (filebeat.yml)
filebeat.inputs:
- type: log
  enabled: true
  paths:
    - /var/log/*/current/*.log
  json.keys_under_root: true
  json.add_error_key: true
```

### Q: What's the performance impact?

**A:** Minimal. Async operations prevent blocking:

```bash
# Benchmark
time for i in {1..1000}; do
    ./logCollector.sh 'test' 'test.sh' 'INFO' "Message $i" > /dev/null
done

# Typical: 0.5-1 seconds for 1000 logs
```

### Q: Can I disable rotation temporarily?

**A:** Yes, set large size in config:

```bash
# /etc/logCollector.conf
MAX_LOG_SIZE_MB=999999  # Effectively disables size-based rotation
```

### Q: How do I log multiline messages?

**A:** Escape newlines or use proper quoting:

```bash
# Method 1: Escape newlines
log 'myapp' 'test.sh' 'ERROR' "Line 1
Line 2
Line 3"

# Method 2: Explicit escaping
log 'myapp' 'test.sh' 'ERROR' "Line 1\nLine 2\nLine 3"

# Method 3: Read from variable
ERROR_MSG=$(cat <<EOF
Error occurred:
  - Condition 1
  - Condition 2
EOF
)
log 'myapp' 'test.sh' 'ERROR' "$ERROR_MSG"
```

### Q: Can I log from remote servers?

**A:** Yes, via SSH:

```bash
# Log from remote server
ssh user@remote-server "/opt/scripts/logCollector.sh 'remote-task' 'script.sh' 'INFO' 'Message'"

# Or use syslog forwarding
# Configure rsyslog on remote server to forward to central server
```

---

## 📞 Support

### Getting Help

1. **Check this README:** Most answers are documented here
2. **Review presentation:** `/opt/scripts/presentation.html`
3. **Contact DB Team:** dba-team@example.com
4. **Check logs:** Review logCollector's own output for errors

### Reporting Issues

When reporting issues, include:

1. Script version: `grep SCRIPT_VERSION /opt/scripts/logCollector.sh`
2. Configuration: `cat /etc/logCollector.conf`
3. Command used: Exact command that failed
4. Error message: Complete error output
5. Environment: OS version, Bash version, available disk space

### Contributing

To suggest improvements:

1. Test your changes thoroughly
2. Update this README
3. Submit to DB Team for review
4. Include use cases and examples

---

## 📜 License

Internal use only. Copyright © 2026 DB Team. All rights reserved.

---

## 🗓️ Changelog

### Version 2.0 (2026-01-04)
- ✨ Added automatic log rotation (size and date-based)
- ✨ Added gzip compression for archives
- ✨ Added configurable retention policies
- ✨ Added JSON output format
- ✨ Added colored console output
- ✨ Added syslog integration
- ✨ Added email alerts
- ✨ Added rich metadata support
- ✨ Added stack trace capability
- ✨ Added external configuration file
- ✨ Expanded to 7 log levels
- ✨ Added background cleanup operations
- 🐛 Fixed concurrent write issues
- 🐛 Fixed permission handling
- ⚡ Performance optimizations
- 📝 Comprehensive documentation

### Version 1.0 (2025-01-01)
- Initial release
- Basic text logging
- 3 log levels (INFO, WARNING, ERROR)
- Manual log management

---

**Last Updated:** 2026-01-04  
**Maintained By:** DB Team  
**Version:** 2.0