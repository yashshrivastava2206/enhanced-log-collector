
# Migration Guide

Guide for migrating from v1.0 to v2.0 of Enhanced Log Collector.

## Overview

Version 2.0 introduces significant improvements but requires migration of existing installations.

### What's Changed

| Aspect | v1.0 | v2.0 |
|--------|------|------|
| **Log Levels** | 3 (ERROR, INFO, WARNING) | 7 (DEBUG to FATAL) |
| **Formats** | Plain text only | 4 formats (Plain, JSON, Console, Syslog) |
| **Rotation** | Manual | Automatic (size and date-based) |
| **Compression** | None | Automatic gzip |
| **Retention** | Manual | Policy-based automatic cleanup |
| **Structure** | Flat directory | current/ and archive/ subdirectories |
| **Metadata** | Basic timestamp | Rich metadata with custom fields |
| **Alerts** | None | Email alerts for critical events |
| **Configuration** | Hardcoded | External file (/etc/logCollector.conf) |

### Compatibility

✅ **Backward Compatible**: v2.0 accepts all v1.0 syntax  
✅ **Gradual Migration**: Can run v1.0 and v2.0 side-by-side  
✅ **Data Preserved**: All existing logs are migrated safely  

## Pre-Migration Checklist

Before starting migration:

- [ ] **Backup current installation**
  ```bash
  sudo tar -czf /backup/logcollector-v1-$(date +%Y%m%d).tar.gz \
      /opt/scripts/logCollector.sh \
      /var/log/*
  ```

- [ ] **Document current usage**
  ```bash
  # Find all scripts using logCollector
  grep -r "logCollector.sh" /opt/scripts/
  grep -r "logCollector.sh" /home/*/
  ```

- [ ] **Check disk space**
  ```bash
  df -h /var/log
  # Ensure at least 20% free for migration
  ```

- [ ] **Review retention needs**
  ```bash
  # How long do you need to keep logs?
  # This affects LOG_RETENTION_DAYS and ARCHIVE_RETENTION_DAYS
  ```

- [ ] **Test in non-production first**

## Migration Methods

### Method 1: Automated Migration (Recommended)

Use the provided migration tool:

```bash
# 1. Download v2.0
git clone https://github.com/your-org/enhanced-log-collector.git
cd enhanced-log-collector

# 2. Run migration tool
sudo make migrate
# or
sudo ./tools/migrate_v1_to_v2.sh
```

This automatically:
- Backs up v1.0 installation
- Installs v2.0 script
- Creates configuration file
- Migrates directory structure
- Preserves all existing logs

### Method 2: Manual Migration

For more control:

#### Step 1: Backup

```bash
sudo mkdir -p /opt/backups/logcollector
sudo tar -czf /opt/backups/logcollector/pre-migration-$(date +%Y%m%d).tar.gz \
    /opt/scripts/logCollector.sh \
    /var/log/*
```

#### Step 2: Install v2.0

```bash
cd enhanced-log-collector
sudo make install
```

#### Step 3: Migrate Directory Structure

```bash
# For each log directory
for dir in /var/log/*/; do
    if [[ -d "$dir" ]]; then
        # Create new structure
        sudo mkdir -p "${dir}current" "${dir}archive"
        
        # Move .log files to current/
        sudo mv "${dir}"*.log "${dir}current/" 2>/dev/null || true
        
        # Move .log.gz files to archive/ (if any)
        sudo mv "${dir}"*.log.gz "${dir}archive/" 2>/dev/null || true
    fi
done
```

#### Step 4: Update Scripts

Update your scripts to use new features (optional):

```bash
# Old v1.0 syntax (still works in v2.0)
bash /opt/scripts/logCollector.sh "backup" "$0" "INFO" "Backup started"

# New v2.0 syntax with features
bash /opt/scripts/logCollector.sh "backup" "$0" "INFO" "Backup started" \
    --console \
    --json \
    --metadata size=50GB
```

### Method 3: Side-by-Side Installation

Run both versions during transition:

```bash
# Install v2.0 with different name
sudo cp bin/logCollector.sh /opt/scripts/logCollector-v2.sh

# Update select scripts to use v2
LOG_V2="/opt/scripts/logCollector-v2.sh"
$LOG_V2 'myapp' "$0" 'INFO' 'Using v2.0'

# Old scripts continue using v1
LOG_
