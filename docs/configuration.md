**Previous**: [Documentation Index](README.md) | **Next**: [Configuration Guide](configuration.md) →


#### `docs/configuration.md`
```markdown
# Configuration Guide

Complete guide to configuring Enhanced Log Collector.

## Configuration File

Location: `/etc/logCollector.conf`

This file controls global behavior. All settings can be overridden per-call with command-line flags.

## Basic Configuration

### Minimal Configuration

```bash
BASE_LOG_DIR="/var/log"
DEFAULT_OWNER="postgres:postgres"
MAX_LOG_SIZE_MB=100
ENABLE_COMPRESSION=true
```

### Full Configuration Template

```bash
#!/bin/bash
# Enhanced Log Collector Configuration

# Directory Settings
BASE_LOG_DIR="/var/log"              # Root directory for all logs
DEFAULT_OWNER="postgres:postgres"     # Default file ownership

# Rotation Settings
MAX_LOG_SIZE_MB=100                   # Rotate when file reaches this size
LOG_RETENTION_DAYS=30                 # Keep uncompressed logs this long
ARCHIVE_RETENTION_DAYS=90             # Keep compressed archives this long

# Compression
ENABLE_COMPRESSION=true               # Auto-compress rotated logs

# Default Output Formats
ENABLE_JSON_FORMAT=false              # Default to plain text
ENABLE_CONSOLE_OUTPUT=false           # Don't show on console by default
ENABLE_SYSLOG=false                   # Don't send to syslog by default

# Email Alerts
ENABLE_EMAIL_ALERTS=true              # Enable email notifications
ALERT_EMAIL="dba-team@example.com"    # Alert recipient
ALERT_LEVELS="FATAL,CRITICAL"         # Levels that trigger emails

# System
SCRIPT_VERSION="2.0"                  # Version identifier
```

## Configuration Options

### Directory Settings

#### BASE_LOG_DIR
**Default**: `/var/log`  
**Description**: Root directory where all log subdirectories are created

```bash
BASE_LOG_DIR="/var/log"
# Creates: /var/log/taskname/current/ and /var/log/taskname/archive/
```

**Custom locations**:
```bash
# Application-specific
BASE_LOG_DIR="/opt/myapp/logs"

# Network storage
BASE_LOG_DIR="/mnt/nfs/logs"

# Fast SSD for high-volume logging
BASE_LOG_DIR="/ssd/logs"
```

#### DEFAULT_OWNER
**Default**: `postgres:postgres`  
**Description**: Default user:group ownership for created directories and files

```bash
DEFAULT_OWNER="app-user:app-group"
```

### Log Rotation

#### MAX_LOG_SIZE_MB
**Default**: `100`  
**Description**: Rotate log file when it reaches this size in megabytes

```bash
# High-volume applications
MAX_LOG_SIZE_MB=500

# Low-volume applications
MAX_LOG_SIZE_MB=10

# Disable size-based rotation
MAX_LOG_SIZE_MB=999999
```

**Note**: Logs also rotate daily regardless of size.

### Retention Policies

#### LOG_RETENTION_DAYS
**Default**: `30`  
**Description**: Delete uncompressed logs older than this many days

```bash
# Development (short retention)
LOG_RETENTION_DAYS=7

# Production (standard)
LOG_RETENTION_DAYS=30

# Compliance (extended)
LOG_RETENTION_DAYS=365
```

#### ARCHIVE_RETENTION_DAYS
**Default**: `90`  
**Description**: Delete compressed archives older than this many days

```bash
# Standard retention
ARCHIVE_RETENTION_DAYS=90

# Long-term archival
ARCHIVE_RETENTION_DAYS=730  # 2 years

# Compliance requirements
ARCHIVE_RETENTION_DAYS=2555  # 7 years
```

### Compression

#### ENABLE_COMPRESSION
**Default**: `true`  
**Description**: Automatically compress rotated log files

```bash
# Enable compression (recommended)
ENABLE_COMPRESSION=true

# Disable compression (development)
ENABLE_COMPRESSION=false
```

**Compression savings**: Typically 85-90% size reduction

### Output Formats

These set defaults but can be overridden per-call:

#### ENABLE_JSON_FORMAT
**Default**: `false`  
**Description**: Output in JSON format by default

```bash
# For log aggregation systems
ENABLE_JSON_FORMAT=true
```

Override per-call:
```bash
# Force plain text even if JSON is default
/opt/scripts/logCollector.sh 'task' 'script.sh' 'INFO' 'Message'  # Uses config default

# Force JSON regardless of default
/opt/scripts/logCollector.sh 'task' 'script.sh' 'INFO' 'Message' --json
```

#### ENABLE_CONSOLE_OUTPUT
**Default**: `false`  
**Description**: Display logs on console by default

```bash
# Development environments
ENABLE_CONSOLE_OUTPUT=true

# Production (quiet)
ENABLE_CONSOLE_OUTPUT=false
```

#### ENABLE_SYSLOG
**Default**: `false`  
**Description**: Send logs to syslog by default

```bash
# Enable for centralized logging
ENABLE_SYSLOG=true
```

### Email Alerts

#### ENABLE_EMAIL_ALERTS
**Default**: `false`  
**Description**: Enable email notification system

```bash
ENABLE_EMAIL_ALERTS=true
```

**Requires**: `mail` or `sendmail` command available

#### ALERT_EMAIL
**Default**: `""`  
**Description**: Email address for alerts

```bash
# Single recipient
ALERT_EMAIL="dba-team@example.com"

# Multiple recipients (comma-separated)
ALERT_EMAIL="oncall@example.com,manager@example.com"
```

#### ALERT_LEVELS
**Default**: `"FATAL,CRITICAL"`  
**Description**: Comma-separated list of log levels that trigger emails

```bash
# Only most severe
ALERT_LEVELS="FATAL"

# Critical and above
ALERT_LEVELS="FATAL,CRITICAL"

# Include errors
ALERT_LEVELS="FATAL,CRITICAL,ERROR"
```

## Environment-Specific Configurations

### Development Environment

**File**: `config/logCollector.conf.dev`

```bash
BASE_LOG_DIR="/var/log"
DEFAULT_OWNER="developer:developer"
MAX_LOG_SIZE_MB=50
LOG_RETENTION_DAYS=7
ARCHIVE_RETENTION_DAYS=14
ENABLE_COMPRESSION=false              # Easier to view uncompressed
ENABLE_CONSOLE_OUTPUT=true            # Show all output
ENABLE_JSON_FORMAT=false
ENABLE_SYSLOG=false
ENABLE_EMAIL_ALERTS=false             # No alerts in dev
```

### Testing Environment

**File**: `config/logCollector.conf.test`

```bash
BASE_LOG_DIR="/var/log"
DEFAULT_OWNER="postgres:postgres"
MAX_LOG_SIZE_MB=75
LOG_RETENTION_DAYS=14
ARCHIVE_RETENTION_DAYS=30
ENABLE_COMPRESSION=true
ENABLE_JSON_FORMAT=true               # Test JSON parsing
ENABLE_SYSLOG=false
ENABLE_EMAIL_ALERTS=true
ALERT_EMAIL="qa-team@example.com"
ALERT_LEVELS="FATAL,CRITICAL,ERROR"   # More aggressive in testing
```

### Production Environment

**File**: `config/logCollector.conf.prod`

```bash
BASE_LOG_DIR="/var/log"
DEFAULT_OWNER="postgres:postgres"
MAX_LOG_SIZE_MB=100
LOG_RETENTION_DAYS=30
ARCHIVE_RETENTION_DAYS=90
ENABLE_COMPRESSION=true
ENABLE_JSON_FORMAT=false              # Plain text for grep
ENABLE_CONSOLE_OUTPUT=false           # Quiet in production
ENABLE_SYSLOG=true                    # Send to central syslog
ENABLE_EMAIL_ALERTS=true
ALERT_EMAIL="oncall@example.com"
ALERT_LEVELS="FATAL,CRITICAL"         # Only critical alerts
```

## Advanced Configuration

### Multiple Configurations

You can maintain multiple config files and switch between them:

```bash
# Development
sudo cp /path/to/repo/config/logCollector.conf.dev /etc/logCollector.conf

# Production
sudo cp /path/to/repo/config/logCollector.conf.prod /etc/logCollector.conf
```
