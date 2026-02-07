# Enhanced Log Collector v3.0 - Complete Guide

**Author:** Yash Shrivastava  
**Copyright:** © 2026 Yash Shrivastava  
**License:** MIT  
**Version:** 3.0.0

---

## 🎯 What's New in v3.0

### Major Improvements from v2.0

✅ **Complete Rewrite with Fixes**
- Fixed all issues identified in code review
- Added comprehensive input validation and sanitization
- Implemented proper error handling with exit codes
- Added file locking for safe rotation
- Fixed race conditions

✅ **Rich Command-Line Interface**
- 20+ new flags and options
- Intuitive flag names (--console, --json, --email, etc.)
- Support for metadata key-value pairs
- Dry-run mode for testing
- Comprehensive help system

✅ **Advanced Features**
- Rate limiting to prevent log flooding
- Disk space management with emergency cleanup
- File size caching for performance
- Async compression option
- Health check and metrics support

✅ **Enhanced Security**
- Input sanitization (prevents injection attacks)
- Path traversal prevention
- Configurable file permissions
- User/group ownership control

✅ **Better Usability**
- Quick help (--help shows full guide)
- Configuration validation (--validate)
- Show current config (--show-config)
- Maintenance commands (--cleanup, --rotate, --compress)
- Verbose and quiet modes

---

## 📦 Installation

### Quick Install

```bash
# 1. Download script
sudo curl -o /opt/scripts/logCollector.sh \
  https://raw.githubusercontent.com/yashshrivastava2206/enhanced-log-collector/main/bin/logCollector.sh

# 2. Make executable
sudo chmod +x /opt/scripts/logCollector.sh

# 3. Create configuration
sudo cp config-production.conf /etc/logCollector.conf

# 4. Test installation
/opt/scripts/logCollector.sh backup test.sh INFO "Installation successful" --console
```

### Detailed Installation

```bash
# Create directories
sudo mkdir -p /opt/scripts
sudo mkdir -p /etc
sudo mkdir -p /var/log

# Copy script
sudo cp logCollector_v3.sh /opt/scripts/logCollector.sh
sudo chmod 755 /opt/scripts/logCollector.sh
sudo chown root:root /opt/scripts/logCollector.sh

# Copy configuration (choose environment)
sudo cp config-production.conf /etc/logCollector.conf
sudo chmod 640 /etc/logCollector.conf
sudo chown root:root /etc/logCollector.conf

# Validate configuration
/opt/scripts/logCollector.sh --validate

# Show configuration
/opt/scripts/logCollector.sh --show-config
```

---

## 🚀 Quick Start

### Basic Usage

```bash
# Simple log message
./logCollector.sh backup backup.sh INFO "Backup started"

# With console output (see colored output in terminal)
./logCollector.sh backup backup.sh INFO "Processing files..." --console

# JSON format
./logCollector.sh api app.py ERROR "Request failed" --json

# Multiple outputs
./logCollector.sh system monitor.sh WARNING "High CPU" --console --syslog --email
```

### Common Use Cases

```bash
# 1. Database backups with metadata
./logCollector.sh backup pg_backup.sh INFO "Backup completed" \
  --console \
  --metadata database=production \
  --metadata size=50GB \
  --metadata duration=300s

# 2. Critical system alerts
./logCollector.sh system health_check.sh FATAL "System crash detected" \
  --email \
  --stacktrace \
  --console

# 3. API logging with JSON
./logCollector.sh api api_server.py ERROR "500 Internal Server Error" \
  --json \
  --metadata endpoint=/api/users \
  --metadata status=500 \
  --metadata method=POST

# 4. Cron job logging
./logCollector.sh maintenance vacuum.sh INFO "Database vacuum started" \
  --syslog \
  --metadata tables=all

# 5. Application debugging
./logCollector.sh app myapp.sh DEBUG "Variable state dump" \
  --console \
  --stacktrace \
  --metadata user_id=12345 \
  --metadata session_id=abc123
```

---

## 📖 Complete Flag Reference

### General Options

| Flag | Short | Description | Example |
|------|-------|-------------|---------|
| `--help` | `-h` | Show full help | `./logCollector.sh --help` |
| `--version` | `-v` | Show version | `./logCollector.sh --version` |
| `--verbose` | `-V` | Verbose output | `./logCollector.sh -V ...` |
| `--quiet` | `-q` | Suppress output | `./logCollector.sh -q ...` |
| `--dry-run` | `-n` | Show what would happen | `./logCollector.sh -n ...` |

### Configuration Options

| Flag | Short | Description | Example |
|------|-------|-------------|---------|
| `--config FILE` | `-c` | Use config file | `./logCollector.sh -c /etc/custom.conf ...` |
| `--show-config` | | Display current config | `./logCollector.sh --show-config` |
| `--validate` | | Validate configuration | `./logCollector.sh --validate` |

### Output Format Options

| Flag | Description | Example |
|------|-------------|---------|
| `--console` | Show on console with colors | `./logCollector.sh ... --console` |
| `--json` | Output in JSON format | `./logCollector.sh ... --json` |
| `--syslog` | Send to syslog | `./logCollector.sh ... --syslog` |
| `--plain` | Plain text (default) | `./logCollector.sh ... --plain` |

### Alert Options

| Flag | Description | Example |
|------|-------------|---------|
| `--email` | Send email alert | `./logCollector.sh ... CRITICAL ... --email` |
| `--stacktrace` | Include stack trace | `./logCollector.sh ... ERROR ... --stacktrace` |

### Metadata Options

| Flag | Short | Description | Example |
|------|-------|-------------|---------|
| `--metadata K=V` | `-m` | Add metadata field | `./logCollector.sh ... -m env=prod -m user=admin` |

### Permission Options

| Flag | Short | Description | Example |
|------|-------|-------------|---------|
| `--user USER` | `-u` | Set file owner | `./logCollector.sh -u postgres ...` |
| `--group GROUP` | `-g` | Set file group | `./logCollector.sh -g postgres ...` |

### Log Management Options

| Flag | Description | Example |
|------|-------------|---------|
| `--no-rotation` | Disable rotation | `./logCollector.sh ... --no-rotation` |
| `--no-compression` | Disable compression | `./logCollector.sh ... --no-compression` |
| `--force` | Force operation | `./logCollector.sh -f ...` |

### Maintenance Options

| Flag | Description | Example |
|------|-------------|---------|
| `--cleanup [TASK]` | Clean old logs | `./logCollector.sh --cleanup backup` |
| `--rotate [TASK]` | Force rotation | `./logCollector.sh --rotate backup` |
| `--compress [TASK]` | Compress archives | `./logCollector.sh --compress backup` |

---

## 🔧 Integration Examples

### Bash Scripts

```bash
#!/bin/bash
################################################################################
# Example: Backup Script with Enhanced Logging
################################################################################

LOG="/opt/scripts/logCollector.sh"
TASK="backup"
SCRIPT=$(basename "$0")

# Logging wrapper function
log() {
    local level="$1"
    local message="$2"
    shift 2
    $LOG "$TASK" "$SCRIPT" "$level" "$message" --console "$@"
}

# Start backup
log INFO "=== Starting Database Backup ==="

# Check prerequisites
log DEBUG "Checking disk space..."
DISK_USAGE=$(df -h /backup | tail -1 | awk '{print $5}' | tr -d '%')

if [ "$DISK_USAGE" -gt 90 ]; then
    log CRITICAL "Disk usage critical: ${DISK_USAGE}%" --email
    exit 1
fi

log INFO "Disk usage acceptable: ${DISK_USAGE}%"

# Perform backup
log INFO "Starting PostgreSQL dump..."
START_TIME=$(date +%s)

if pg_dump production > /backup/production_$(date +%Y%m%d).sql 2>/tmp/backup.err; then
    END_TIME=$(date +%s)
    DURATION=$((END_TIME - START_TIME))
    SIZE=$(du -h /backup/production_$(date +%Y%m%d).sql | cut -f1)
    
    log INFO "Backup completed successfully" \
        --metadata duration="${DURATION}s" \
        --metadata size="$SIZE" \
        --metadata database="production"
else
    ERROR_MSG=$(cat /tmp/backup.err)
    log ERROR "Backup failed: $ERROR_MSG" --email --stacktrace
    exit 1
fi

# Cleanup old backups
log INFO "Cleaning up backups older than 7 days..."
find /backup -name "*.sql" -mtime +7 -delete

log INFO "=== Backup Completed Successfully ===" \
    --metadata total_time="${DURATION}s"

exit 0
```

### Python Integration

```python
#!/usr/bin/env python3
"""
Example: Python Application with Enhanced Logging
"""

import subprocess
import sys
import json
from datetime import datetime

class LogCollector:
    def __init__(self, task="python_app", script=__file__):
        self.log_cmd = "/opt/scripts/logCollector.sh"
        self.task = task
        self.script = script
    
    def log(self, level, message, **metadata):
        """Send log to logCollector.sh"""
        cmd = [
            self.log_cmd,
            self.task,
            self.script,
            level,
            message
        ]
        
        # Add flags
        if metadata.get('console'):
            cmd.append('--console')
        if metadata.get('json'):
            cmd.append('--json')
        if metadata.get('email'):
            cmd.append('--email')
        
        # Add metadata fields
        for key, value in metadata.items():
            if key not in ['console', 'json', 'email']:
                cmd.extend(['--metadata', f'{key}={value}'])
        
        try:
            subprocess.run(cmd, check=True)
        except subprocess.CalledProcessError as e:
            print(f"Logging failed: {e}", file=sys.stderr)
    
    def debug(self, message, **metadata):
        self.log('DEBUG', message, **metadata)
    
    def info(self, message, **metadata):
        self.log('INFO', message, **metadata)
    
    def warning(self, message, **metadata):
        self.log('WARNING', message, **metadata)
    
    def error(self, message, **metadata):
        self.log('ERROR', message, **metadata)
    
    def critical(self, message, **metadata):
        self.log('CRITICAL', message, console=True, email=True, **metadata)
    
    def fatal(self, message, **metadata):
        self.log('FATAL', message, console=True, email=True, **metadata)

# Usage example
if __name__ == "__main__":
    logger = LogCollector(task="myapp")
    
    logger.info("Application started", console=True, version="1.0")
    
    try:
        # Simulate processing
        logger.debug("Processing user request", user_id=12345)
        
        # Simulate error
        raise ValueError("Database connection failed")
        
    except Exception as e:
        logger.error(
            f"Error: {str(e)}",
            console=True,
            error_type=type(e).__name__,
            timestamp=datetime.now().isoformat()
        )
        sys.exit(1)
    
    logger.info("Application completed", console=True)
```

### Cron Job Integration

```bash
# /etc/cron.d/backup-jobs

# Daily backup at 2 AM with logging
0 2 * * * postgres /opt/scripts/backup.sh 2>&1 | \
  while read line; do \
    /opt/scripts/logCollector.sh backup-cron backup.sh INFO "$line" --syslog; \
  done

# Hourly health check with alert
0 * * * * root /opt/scripts/health_check.sh || \
  /opt/scripts/logCollector.sh health health_check.sh CRITICAL "Health check failed" --email --console
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
WorkingDirectory=/opt/myapp
ExecStartPre=/opt/scripts/logCollector.sh myapp service.sh INFO "Service starting" --syslog
ExecStart=/opt/myapp/start.sh
ExecStopPost=/opt/scripts/logCollector.sh myapp service.sh INFO "Service stopped" --syslog
Restart=on-failure
RestartSec=10

# Log stdout/stderr through logCollector
StandardOutput=pipe
StandardError=pipe

[Install]
WantedBy=multi-user.target
```

### Docker Container

```dockerfile
FROM ubuntu:22.04

# Install logCollector
COPY logCollector_v3.sh /usr/local/bin/logCollector.sh
COPY config-docker.conf /etc/logCollector.conf
RUN chmod +x /usr/local/bin/logCollector.sh

# Application
COPY myapp.sh /app/myapp.sh
RUN chmod +x /app/myapp.sh

# Environment
ENV LOG_COLLECTOR_ENV=production

# Health check using logCollector
HEALTHCHECK --interval=30s --timeout=3s \
  CMD /usr/local/bin/logCollector.sh health healthcheck INFO "Health check" || exit 1

CMD ["/app/myapp.sh"]
```

---

## 🛠️ Maintenance Commands

### Cleanup Operations

```bash
# Clean all tasks
./logCollector.sh --cleanup

# Clean specific task
./logCollector.sh --cleanup backup

# Dry run to see what would be deleted
./logCollector.sh --dry-run --cleanup backup
```

### Force Rotation

```bash
# Rotate all log files
./logCollector.sh --rotate

# Rotate specific task
./logCollector.sh --rotate backup

# Rotate with dry run
./logCollector.sh --dry-run --rotate backup
```

### Compress Archives

```bash
# Compress all uncompressed archives
./logCollector.sh --compress

# Compress specific task
./logCollector.sh --compress backup
```

### Configuration Management

```bash
# Validate configuration
./logCollector.sh --validate

# Show current configuration
./logCollector.sh --show-config

# Test with custom config
./logCollector.sh -c /etc/logCollector.dev.conf backup test.sh INFO "Test"

# Use environment-specific config
LOG_COLLECTOR_ENV=staging ./logCollector.sh backup test.sh INFO "Test"
```

---

## 📊 Monitoring & Health

### Health Check

```bash
# Enable in configuration
ENABLE_HEALTH_CHECK=true
HEALTH_CHECK_FILE="/var/run/logCollector.health"

# Check health file age
age=$(($(date +%s) - $(stat -c %Y /var/run/logCollector.health)))
if [ $age -gt 300 ]; then
    echo "Health check stale: ${age}s old"
fi
```

### Metrics Collection

```bash
# Enable in configuration
ENABLE_METRICS=true
METRICS_FILE="/var/log/logCollector_metrics.txt"

# View metrics
cat /var/log/logCollector_metrics.txt

# Example output:
# timestamp 1707303600
# total_logs 15234
# errors 23
# rotations 5
# compressions 5
```

### Disk Space Monitoring

```bash
# Set thresholds in config
MIN_FREE_DISK_MB=1024
DISK_WARNING_THRESHOLD=80
DISK_CRITICAL_THRESHOLD=90
DISK_CRITICAL_ACTION=cleanup

# Manual disk check
df -h /var/log

# Check specific task
du -sh /var/log/backup
```

---

## 🔒 Security Best Practices

### 1. File Permissions

```bash
# Configuration file
sudo chmod 640 /etc/logCollector.conf
sudo chown root:postgres /etc/logCollector.conf

# Script
sudo chmod 755 /opt/scripts/logCollector.sh
sudo chown root:root /opt/scripts/logCollector.sh

# Log directory
sudo chmod 750 /var/log/backup
sudo chown postgres:postgres /var/log/backup
```

### 2. Input Sanitization

```bash
# Enable in config (default: true)
SANITIZE_INPUT=true
MAX_TASK_NAME_LENGTH=100
MAX_MESSAGE_LENGTH=65536
```

### 3. Secure Email Alerts

```bash
# Use authenticated SMTP
SMTP_SERVER="smtp.company.com"
SMTP_PORT=587

# Limit alert recipients
ALERT_EMAIL="security-team@company.com"
ALERT_LEVELS="FATAL,CRITICAL"
```

### 4. Audit Logging

```bash
# Monitor config changes
sudo auditctl -w /etc/logCollector.conf -p wa -k logcollector_config

# Review changes
sudo ausearch -k logcollector_config
```

---

## 🐛 Troubleshooting

### Common Issues

#### Issue: Permission Denied

```bash
# Problem
ERROR: Failed to create directory: /var/log/backup

# Solution
sudo mkdir -p /var/log/backup
sudo chown postgres:postgres /var/log/backup
sudo chmod 750 /var/log/backup
```

#### Issue: Config Not Loading

```bash
# Check config file exists
ls -l /etc/logCollector.conf

# Validate syntax
bash -n /etc/logCollector.conf

# Test explicit config
./logCollector.sh -c /etc/logCollector.conf --validate
```

#### Issue: Email Not Sending

```bash
# Test mail command
echo "Test" | mail -s "Test" your@email.com

# Check configuration
./logCollector.sh --show-config | grep -i email

# Test with explicit flag
./logCollector.sh backup test.sh FATAL "Test alert" --email --console
```

#### Issue: Logs Not Rotating

```bash
# Check file size
ls -lh /var/log/backup/current/*.log

# Force rotation
./logCollector.sh --rotate backup

# Check configuration
./logCollector.sh --show-config | grep -i rotation
```

### Debug Mode

```bash
# Enable debug mode
./logCollector.sh --debug backup test.sh INFO "Test message" --console

# Verbose output
./logCollector.sh --verbose backup test.sh INFO "Test message"

# Dry run to see what would happen
./logCollector.sh --dry-run backup test.sh INFO "Test message" --console
```

---

## 📈 Performance Tuning

### For High-Volume Logging

```bash
# Use high-performance config
cp config-high-performance.conf /etc/logCollector.conf

# Key settings:
MAX_LOG_SIZE_MB=500              # Larger files
ENABLE_COMPRESSION=true          # Save space
COMPRESSION_LEVEL=9              # Maximum compression
ASYNC_COMPRESSION=true           # Background compression
ENABLE_SIZE_CACHE=true           # Cache file sizes
RATE_LIMIT_MAX=50000             # Higher limit
ENABLE_SAMPLING=true             # Sample low-priority logs
SAMPLE_RATE=10                   # Log 10% of INFO/DEBUG
```

### For Low-Resource Systems

```bash
# Use minimal config
cp config-minimal.conf /etc/logCollector.conf

# Key settings:
MAX_LOG_SIZE_MB=5                # Small files
LOG_RETENTION_DAYS=1             # Short retention
ENABLE_COMPRESSION=true          # Save space
COMPRESSION_LEVEL=9              # Max compression
ASYNC_COMPRESSION=false          # Sync (less memory)
ENABLE_SIZE_CACHE=false          # No caching
ENABLE_SAMPLING=true             # Aggressive sampling
SAMPLE_RATE=1                    # Log 1% only
```

---

## 📝 Migration from v2.0

### Backward Compatibility

v3.0 is **fully backward compatible** with v2.0 syntax:

```bash
# Old v2.0 syntax still works
./logCollector.sh backup backup.sh INFO "Message"
./logCollector.sh backup backup.sh ERROR "Error" --console --json
```

### New Features to Adopt

```bash
# 1. Use new flags
./logCollector.sh -c /etc/custom.conf backup backup.sh INFO "Message"

# 2. Add metadata
./logCollector.sh backup backup.sh INFO "Complete" -m size=10GB -m time=60s

# 3. Use maintenance commands
./logCollector.sh --cleanup backup
./logCollector.sh --validate

# 4. Enable health checks
ENABLE_HEALTH_CHECK=true

# 5. Use dry-run for testing
./logCollector.sh --dry-run backup backup.sh INFO "Test"
```

---

## 📄 License

MIT License

Copyright © 2026 Yash Shrivastava

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

---

## 🤝 Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

---

## 📞 Support

- **Issues:** https://github.com/yashshrivastava2206/enhanced-log-collector/issues
- **Author:** Yash Shrivastava
- **Email:** [Contact via GitHub]

---

**Enhanced Log Collector v3.0**  
*Enterprise-grade logging made simple*
