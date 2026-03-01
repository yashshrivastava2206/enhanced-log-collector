# Enhanced Log Collector - Configuration Guide

**Author:** Yash Shrivastava  
**Copyright:** © 2026 Yash Shrivastava  
**License:** MIT  
**Version:** 2.0.0  
**Last Updated:** February 7, 2026

---

## Table of Contents

1. [Overview](#overview)
2. [Configuration Files](#configuration-files)
3. [Configuration Reference](#configuration-reference)
4. [Environment Selection](#environment-selection)
5. [Custom Configuration](#custom-configuration)
6. [Best Practices](#best-practices)
7. [Troubleshooting](#troubleshooting)

---

## Overview

The Enhanced Log Collector supports flexible configuration through external configuration files. This allows you to customize behavior for different environments without modifying the core script.

### Configuration File Location

**Default:** `/etc/logCollector.conf`

**Environment-Specific:**
- Production: `/etc/logCollector.production.conf`
- Development: `/etc/logCollector.development.conf`
- Staging: `/etc/logCollector.staging.conf`
- Docker: `/etc/logCollector.docker.conf`
- Minimal: `/etc/logCollector.minimal.conf`
- High-Performance: `/etc/logCollector.high-performance.conf`

---

## Configuration Files

### 1. Production Configuration (`config-production.conf`)

**Use Case:** Production environments with balanced performance and durability

**Key Features:**
- Moderate log rotation (100MB files)
- 30-day retention for active logs, 90-day for archives
- Email alerts for FATAL and CRITICAL events
- Syslog integration enabled
- Compression enabled (level 6)
- Rate limiting enabled

**Installation:**
```bash
sudo cp config-production.conf /etc/logCollector.conf
sudo chmod 640 /etc/logCollector.conf
sudo chown root:postgres /etc/logCollector.conf
```

**When to Use:**
- Production database servers
- Production application servers
- Any mission-critical environment
- Systems requiring audit compliance

---

### 2. Development Configuration (`config-development.conf`)

**Use Case:** Development and local testing environments

**Key Features:**
- Small log files (10MB) for easier viewing
- Short retention (3 days)
- No compression (easier to read)
- Console output enabled
- Email alerts disabled
- All debugging features enabled
- JSON format enabled for testing

**Installation:**
```bash
sudo cp config-development.conf /etc/logCollector.conf
# Or use with environment variable
export LOG_COLLECTOR_CONFIG=/path/to/config-development.conf
```

**When to Use:**
- Developer workstations
- Local testing
- Debug troubleshooting
- Feature development

---

### 3. Staging/Testing Configuration (`config-staging.conf`)

**Use Case:** Pre-production testing and QA environments

**Key Features:**
- Medium-sized files (50MB)
- Moderate retention (14/30 days)
- Email alerts to QA team
- Compression enabled
- Rate limiting enabled
- Load testing mode available
- Production-like security settings

**Installation:**
```bash
sudo cp config-staging.conf /etc/logCollector.conf
```

**When to Use:**
- Staging environments
- QA testing
- Integration testing
- Performance testing
- Pre-production validation

---

### 4. High-Performance Configuration (`config-high-performance.conf`)

**Use Case:** Large-scale, high-volume production environments

**Key Features:**
- Large files (500MB) to reduce rotation overhead
- Aggressive sampling (10% of INFO/DEBUG)
- Maximum compression (level 9)
- Async operations maximized
- High rate limits (50,000/minute)
- Fast rotation and cleanup
- Minimal metadata
- Direct Elasticsearch integration

**Installation:**
```bash
sudo cp config-high-performance.conf /etc/logCollector.conf
```

**When to Use:**
- High-traffic production systems
- Big data environments
- Systems generating >100GB logs/day
- Performance-critical applications
- When disk I/O is a bottleneck

**Performance Tuning:**
```bash
# Additional OS-level tuning recommended:
echo "vm.dirty_ratio = 40" >> /etc/sysctl.conf
echo "vm.dirty_background_ratio = 10" >> /etc/sysctl.conf
sysctl -p

# Increase file descriptor limits
echo "* soft nofile 65535" >> /etc/security/limits.conf
echo "* hard nofile 65535" >> /etc/security/limits.conf
```

---

### 5. Docker/Container Configuration (`config-docker.conf`)

**Use Case:** Containerized applications (Docker, Kubernetes, etc.)

**Key Features:**
- Small files (25MB) suitable for containers
- Very short retention (logs shipped externally)
- JSON format by default
- Console output enabled (for `docker logs`)
- Kubernetes metadata included
- Environment variable driven
- Cloud provider integrations
- Health check endpoints

**Installation:**
```dockerfile
# In Dockerfile
COPY config-docker.conf /etc/logCollector.conf
```

**Kubernetes ConfigMap:**
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: logcollector-config
data:
  logCollector.conf: |
    # Include contents of config-docker.conf
```

**When to Use:**
- Docker containers
- Kubernetes pods
- Cloud-native applications
- Microservices
- Serverless containers

**Environment Variables:**
```bash
# Override settings via environment
ENABLE_ELASTICSEARCH=true
ELASTICSEARCH_HOST=elasticsearch.default.svc.cluster.local
ALERT_EMAIL=alerts@company.com
ENABLE_SAMPLING=true
SAMPLE_RATE=50
```

---

### 6. Minimal/Embedded Configuration (`config-minimal.conf`)

**Use Case:** Resource-constrained environments (IoT, Edge, Raspberry Pi)

**Key Features:**
- Tiny files (5MB max)
- Extremely short retention (hours to days)
- Maximum compression
- Aggressive sampling (1% of non-critical)
- No background processes
- No optional features
- Emergency cleanup enabled
- Memory limit: 1MB

**Installation:**
```bash
sudo cp config-minimal.conf /etc/logCollector.conf
```

**When to Use:**
- IoT devices
- Edge computing
- Raspberry Pi
- Embedded systems
- Systems with <1GB RAM
- Systems with <100MB free disk
- Battery-powered devices

**Resource Requirements:**
- Minimum RAM: 256MB
- Minimum Disk: 100MB
- CPU: Any (throttled to lowest priority)

---

## Configuration Reference

### Core Settings

| Setting | Type | Default | Description |
|---------|------|---------|-------------|
| `BASE_LOG_DIR` | Path | `/var/log` | Root directory for all logs |
| `DEFAULT_OWNER` | String | `postgres:postgres` | Default file ownership |
| `SCRIPT_VERSION` | String | `2.0.0` | Script version identifier |

### Rotation Settings

| Setting | Type | Default | Description |
|---------|------|---------|-------------|
| `MAX_LOG_SIZE_MB` | Integer | `100` | Max file size before rotation (MB) |
| `LOG_RETENTION_DAYS` | Integer | `30` | Days to keep uncompressed logs |
| `ARCHIVE_RETENTION_DAYS` | Integer | `90` | Days to keep compressed archives |
| `ENABLE_COMPRESSION` | Boolean | `true` | Enable automatic compression |
| `COMPRESSION_LEVEL` | Integer (1-9) | `6` | Compression level (1=fast, 9=best) |

### Output Settings

| Setting | Type | Default | Description |
|---------|------|---------|-------------|
| `DEFAULT_OUTPUT_FORMAT` | String | `plain` | Default format (plain, json, syslog) |
| `ENABLE_JSON_FORMAT` | Boolean | `false` | Enable JSON by default |
| `ENABLE_CONSOLE_OUTPUT` | Boolean | `false` | Show on console by default |
| `ENABLE_SYSLOG` | Boolean | `true` | Send to syslog by default |
| `SYSLOG_FACILITY` | String | `local0` | Syslog facility |
| `SYSLOG_SERVER` | String | `` | Remote syslog server (host:port) |

### Email Settings

| Setting | Type | Default | Description |
|---------|------|---------|-------------|
| `ENABLE_EMAIL_ALERTS` | Boolean | `true` | Enable email notifications |
| `ALERT_EMAIL` | String | `` | Email address(es) for alerts |
| `ALERT_LEVELS` | String | `FATAL,CRITICAL` | Levels that trigger emails |
| `EMAIL_SUBJECT_PREFIX` | String | `[LOG-ALERT]` | Subject line prefix |
| `EMAIL_FROM` | String | `` | From address |
| `SMTP_SERVER` | String | `` | SMTP server (optional) |
| `SMTP_PORT` | Integer | `25` | SMTP port |

### Performance Settings

| Setting | Type | Default | Description |
|---------|------|---------|-------------|
| `ASYNC_COMPRESSION` | Boolean | `true` | Compress in background |
| `ENABLE_SIZE_CACHE` | Boolean | `true` | Cache file sizes |
| `SIZE_CACHE_TIMEOUT` | Integer | `60` | Cache timeout (seconds) |
| `MAX_COMPRESSION_JOBS` | Integer | `4` | Concurrent compression workers |

### Rate Limiting

| Setting | Type | Default | Description |
|---------|------|---------|-------------|
| `ENABLE_RATE_LIMIT` | Boolean | `true` | Enable rate limiting |
| `RATE_LIMIT_MAX` | Integer | `10000` | Max logs per window |
| `RATE_LIMIT_WINDOW` | Integer | `60` | Window size (seconds) |
| `RATE_LIMIT_ACTION` | String | `sample` | Action (drop, sample, block) |

### Sampling

| Setting | Type | Default | Description |
|---------|------|---------|-------------|
| `ENABLE_SAMPLING` | Boolean | `false` | Enable log sampling |
| `SAMPLE_RATE` | Integer (0-100) | `100` | Percentage to log |
| `SAMPLE_EXEMPT_LEVELS` | String | `ERROR,CRITICAL,FATAL` | Never sample these |

### Security

| Setting | Type | Default | Description |
|---------|------|---------|-------------|
| `LOG_FILE_PERMISSIONS` | Octal | `640` | File permissions |
| `LOG_DIR_PERMISSIONS` | Octal | `750` | Directory permissions |
| `SANITIZE_INPUT` | Boolean | `true` | Sanitize all inputs |
| `MAX_TASK_NAME_LENGTH` | Integer | `100` | Max task name length |
| `MAX_MESSAGE_LENGTH` | Integer | `65536` | Max message length |

### Storage

| Setting | Type | Default | Description |
|---------|------|---------|-------------|
| `MIN_FREE_DISK_MB` | Integer | `1024` | Minimum free disk (MB) |
| `DISK_WARNING_THRESHOLD` | Integer (%) | `80` | Warning threshold |
| `DISK_CRITICAL_THRESHOLD` | Integer (%) | `90` | Critical threshold |
| `DISK_CRITICAL_ACTION` | String | `cleanup` | Action when critical |

---

## Environment Selection

### Method 1: Environment Variable

```bash
# Set environment before running
export LOG_COLLECTOR_ENV=staging
./logCollector.sh ...

# Or inline
LOG_COLLECTOR_ENV=development ./logCollector.sh ...
```

The script will look for `/etc/logCollector.staging.conf` or `/etc/logCollector.development.conf`.

### Method 2: Config File Path

```bash
# Specify exact config file
export LOG_COLLECTOR_CONFIG=/path/to/custom.conf
./logCollector.sh ...
```

### Method 3: Symlink

```bash
# Create symlink to desired config
sudo ln -sf /etc/logCollector.production.conf /etc/logCollector.conf
```

### Method 4: Config Inheritance

Create a base config and environment-specific overrides:

```bash
# /etc/logCollector.conf (base)
BASE_LOG_DIR="/var/log"
DEFAULT_OWNER="postgres:postgres"

# /etc/logCollector.production.conf (overrides)
source /etc/logCollector.conf
MAX_LOG_SIZE_MB=100
ENABLE_EMAIL_ALERTS=true

# /etc/logCollector.development.conf (overrides)
source /etc/logCollector.conf
MAX_LOG_SIZE_MB=10
ENABLE_EMAIL_ALERTS=false
```

---

## Custom Configuration

### Creating a Custom Config

1. **Start with a template:**
```bash
cp config-production.conf /etc/logCollector.custom.conf
```

2. **Edit settings:**
```bash
sudo vi /etc/logCollector.custom.conf
```

3. **Validate config:**
```bash
# Source the config to check for syntax errors
bash -n /etc/logCollector.custom.conf
```

4. **Test with your script:**
```bash
LOG_COLLECTOR_CONFIG=/etc/logCollector.custom.conf \
  ./logCollector.sh 'test' 'test.sh' 'INFO' 'Test message' --console
```

### Use Case-Specific Configs

#### Audit Logging
```bash
# config-audit.conf
LOG_RETENTION_DAYS=365
ARCHIVE_RETENTION_DAYS=2555  # 7 years
ENABLE_COMPRESSION=true
COMPRESSION_LEVEL=9
SANITIZE_INPUT=true
LOG_FILE_PERMISSIONS=400  # Read-only
INCLUDE_STACK_TRACES=true
```

#### Debug Logging
```bash
# config-debug.conf
MAX_LOG_SIZE_MB=5
LOG_RETENTION_DAYS=1
ENABLE_COMPRESSION=false
ENABLE_CONSOLE_OUTPUT=true
DEBUG_MODE=true
INCLUDE_STACK_TRACES=true
ALLOWED_LOG_LEVELS="DEBUG,INFO,NOTICE,WARNING,ERROR,CRITICAL,FATAL"
```

#### High-Security
```bash
# config-security.conf
LOG_FILE_PERMISSIONS=400
LOG_DIR_PERMISSIONS=700
VALIDATE_CONFIG_PERMISSIONS=true
SANITIZE_INPUT=true
ENABLE_ENCRYPTION=true  # If implemented
ENABLE_SIGNED_LOGS=true  # If implemented
```

---

## Best Practices

### 1. Use Environment-Specific Configs

```bash
# Production
/etc/logCollector.production.conf

# Staging
/etc/logCollector.staging.conf

# Development
/etc/logCollector.development.conf
```

### 2. Version Control Your Configs

```bash
# Store configs in git
/path/to/repo/configs/
├── production.conf
├── staging.conf
└── development.conf

# Deploy via automation
ansible-playbook deploy-logcollector-config.yml
```

### 3. Validate Before Deploying

```bash
#!/bin/bash
# validate-config.sh

CONFIG_FILE="$1"

# Check syntax
bash -n "$CONFIG_FILE" || exit 1

# Check required variables
required_vars=(
    "BASE_LOG_DIR"
    "MAX_LOG_SIZE_MB"
    "LOG_RETENTION_DAYS"
)

source "$CONFIG_FILE"

for var in "${required_vars[@]}"; do
    if [ -z "${!var}" ]; then
        echo "ERROR: $var not set in $CONFIG_FILE"
        exit 1
    fi
done

echo "Config validation passed: $CONFIG_FILE"
```

### 4. Document Custom Settings

```bash
# Add comments to your custom config
# Custom configuration for XYZ application
# Author: Yash Shrivastava
# Date: 2026-02-07
# Purpose: High-volume transaction logging

MAX_LOG_SIZE_MB=500  # Large files due to high volume
SAMPLE_RATE=10       # Sample 10% to manage disk space
```

### 5. Test Thoroughly

```bash
# Test script with new config
./tests/test-config.sh /etc/logCollector.custom.conf

# Load test
./tests/load-test.sh --config=/etc/logCollector.custom.conf --duration=300
```

### 6. Monitor Config Changes

```bash
# Use auditd to track config changes
auditctl -w /etc/logCollector.conf -p wa -k logcollector_config

# Review changes
ausearch -k logcollector_config
```

### 7. Backup Configs

```bash
# Backup before changes
sudo cp /etc/logCollector.conf /etc/logCollector.conf.backup.$(date +%Y%m%d)

# Automated backup
0 0 * * * cp /etc/logCollector.conf /backup/logCollector.conf.$(date +\%Y\%m\%d)
```

---

## Troubleshooting

### Config Not Loading

**Problem:** Settings not taking effect

**Solution:**
```bash
# Verify config file exists
ls -l /etc/logCollector.conf

# Check for syntax errors
bash -n /etc/logCollector.conf

# Verify script is sourcing the config
grep "source.*logCollector.conf" /opt/scripts/logCollector.sh

# Test with explicit config path
LOG_COLLECTOR_CONFIG=/etc/logCollector.conf \
  ./logCollector.sh 'test' 'test.sh' 'INFO' 'Test' --console
```

### Permission Denied

**Problem:** Cannot read config file

**Solution:**
```bash
# Fix permissions
sudo chmod 640 /etc/logCollector.conf
sudo chown root:postgres /etc/logCollector.conf

# Verify
namei -l /etc/logCollector.conf
```

### Invalid Values

**Problem:** Script fails with invalid config values

**Solution:**
```bash
# Add validation to your config
if ! [[ "$MAX_LOG_SIZE_MB" =~ ^[0-9]+$ ]]; then
    echo "ERROR: MAX_LOG_SIZE_MB must be numeric"
    exit 1
fi

# Use defaults for missing values
MAX_LOG_SIZE_MB="${MAX_LOG_SIZE_MB:-100}"
```

### Environment Variables Not Working

**Problem:** Environment-based config selection fails

**Solution:**
```bash
# Verify environment variable is set
echo $LOG_COLLECTOR_ENV

# Export if using in scripts
export LOG_COLLECTOR_ENV=production

# Use absolute path if relative doesn't work
export LOG_COLLECTOR_CONFIG=/etc/logCollector.production.conf
```

---

## Quick Reference

### Config Selection Priority

1. `LOG_COLLECTOR_CONFIG` environment variable (highest priority)
2. `/etc/logCollector.${LOG_COLLECTOR_ENV}.conf`
3. `/etc/logCollector.conf` (default)

### Common Config Patterns

#### Development: Fast iteration
```bash
MAX_LOG_SIZE_MB=10
ENABLE_COMPRESSION=false
ENABLE_CONSOLE_OUTPUT=true
```

#### Production: Balanced
```bash
MAX_LOG_SIZE_MB=100
ENABLE_COMPRESSION=true
LOG_RETENTION_DAYS=30
```

#### High-Volume: Performance
```bash
MAX_LOG_SIZE_MB=500
ENABLE_SAMPLING=true
SAMPLE_RATE=10
ASYNC_COMPRESSION=true
```

#### Compliance: Audit
```bash
LOG_RETENTION_DAYS=365
ARCHIVE_RETENTION_DAYS=2555
LOG_FILE_PERMISSIONS=400
SANITIZE_INPUT=true
```

---

## Additional Resources

- Main README: `/docs/README.md`
- API Documentation: `/docs/API.md`
- Troubleshooting Guide: `/docs/TROUBLESHOOTING.md`
- Migration Guide: `/docs/MIGRATION.md`

---

**Configuration Guide - End of Document**

**Author:** Yash Shrivastava  
**Copyright:** © 2026 Yash Shrivastava  
**License:** MIT
