# Troubleshooting Guide

Solutions to common problems and issues.

## Quick Diagnosis

### Run Health Check

```bash
sudo make health-check
# or
sudo ./tools/health_check.sh
```

This automatically checks:
- Script installation
- Configuration
- Permissions
- Dependencies
- Disk space
- Log structure

## Common Issues

### 1. Permission Denied Errors

#### Symptom
```
ERROR: Failed to create directory: /var/log/myapp
Permission denied
```

#### Diagnosis
```bash
# Check directory permissions
ls -ld /var/log
ls -ld /var/log/myapp 2>/dev/null

# Check script permissions
ls -l /opt/scripts/logCollector.sh

# Check current user
whoami
```

#### Solutions

**Solution A**: Run with proper permissions
```bash
# Use sudo for system directories
sudo /opt/scripts/logCollector.sh 'myapp' 'test.sh' 'INFO' 'Test'
```

**Solution B**: Change directory ownership
```bash
# Make directory writable by your user
sudo chown -R $USER:$USER /var/log/myapp

# Or change default owner in config
sudo vi /etc/logCollector.conf
# Set: DEFAULT_OWNER="your-user:your-group"
```

**Solution C**: Use alternative log directory
```bash
# Create user-writable location
mkdir -p ~/logs
export BASE_LOG_DIR=~/logs
/opt/scripts/logCollector.sh 'myapp' 'test.sh' 'INFO' 'Test'
```

### 2. Logs Not Rotating

#### Symptom
```bash
# Log file is huge
ls -lh /var/log/myapp/current/app.sh_2026-01-24.log
-rw-r--r-- 1 postgres postgres 500M Jan 24 10:30 app.sh_2026-01-24.log
```

#### Diagnosis
```bash
# Check rotation setting
grep MAX_LOG_SIZE_MB /etc/logCollector.conf

# Check if rotation check is working
/opt/scripts/logCollector.sh 'myapp' 'test.sh' 'DEBUG' 'Test rotation'

# Check for rotation errors
journalctl | grep logCollector
```

#### Solutions

**Solution A**: Adjust rotation threshold
```bash
sudo vi /etc/logCollector.conf
# Lower the threshold
MAX_LOG_SIZE_MB=100
```

**Solution B**: Manual rotation
```bash
# Manually rotate large file
cd /var/log/myapp/current
sudo mv app.sh_2026-01-24.log ../archive/app.sh_20260124_103000.log
sudo gzip ../archive/app.sh_20260124_103000.log
```

**Solution C**: Force rotation with new log
```bash
# This will trigger rotation check
/opt/scripts/logCollector.sh 'myapp' 'app.sh' 'INFO' 'Force rotation check'
```

### 3. Email Alerts Not Working

#### Symptom
```bash
# No emails received for CRITICAL/FATAL logs
/opt/scripts/logCollector.sh 'test' 'test.sh' 'CRITICAL' 'Test alert' --email
# No email arrives
```

#### Diagnosis
```bash
# Check mail command
which mail
mail --version

# Test mail manually
echo "Test" | mail -s "Test Subject" your@email.com

# Check configuration
grep ALERT /etc/logCollector.conf
```

#### Solutions

**Solution A**: Install mail utility
```bash
# RHEL/CentOS
sudo yum install mailx

# Debian/Ubuntu
sudo apt-get install mailutils

# Verify installation
which mail
```

**Solution B**: Configure sendmail/postfix
```bash
# Check mail service
systemctl status postfix
# or
systemctl status sendmail

# Start if stopped
sudo systemctl start postfix
sudo systemctl enable postfix
```

**Solution C**: Check configuration
```bash
sudo vi /etc/logCollector.conf

# Ensure these are set
ENABLE_EMAIL_ALERTS=true
ALERT_EMAIL="your@email.com"
ALERT_LEVELS="FATAL,CRITICAL"
```

**Solution D**: Check spam folder
- Email may be filtered as spam
- Add sender to whitelist
- Check email server logs

### 4. Logs Not Compressing

#### Symptom
```bash
# Archive directory has uncompressed files
ls -lh /var/log/myapp/archive/
-rw-r--r-- 1 postgres postgres 100M Jan 23 02:00 app.sh_20260123_020000.log
```

#### Diagnosis
```bash
# Check gzip availability
which gzip
gzip --version

# Check configuration
grep ENABLE_COMPRESSION /etc/logCollector.conf

# Check for gzip errors
ls -la /var/log/myapp/archive/
```

#### Solutions

**Solution A**: Install gzip
```bash
# RHEL/CentOS
sudo yum install gzip

# Debian/Ubuntu
sudo apt-get install gzip
```

**Solution B**: Enable compression
```bash
sudo vi /etc/logCollector.conf
# Set:
ENABLE_COMPRESSION=true
```

**Solution C**: Manual compression
```bash
# Compress existing archives
cd /var/log/myapp/archive
sudo gzip *.log
```

**Solution D**: Check background process
```bash
# Compression runs in background
# Check system load
top
ps aux | grep gzip

# May need to wait for completion
```

### 5. Invalid Log Level Errors

#### Symptom
```
ERROR: Invalid log level 'WARN'
Valid levels: DEBUG INFO NOTICE WARNING ERROR CRITICAL FATAL
```

#### Solution
Use correct level names:
```bash
# Wrong
/opt/scripts/logCollector.sh 'test' 'test.sh' 'WARN' 'Message'

# Correct
/opt/scripts/logCollector.sh 'test' 'test.sh' 'WARNING' 'Message'
```

Valid levels (case-sensitive):
- DEBUG
- INFO
- NOTICE
- WARNING (not WARN)
- ERROR
- CRITICAL (not CRIT)
- FATAL

### 6. JSON Format Issues

#### Symptom
```bash
# JSON appears malformed
cat /var/log/myapp/current/app.sh_2026-01-24.log
{
  "timestamp": "2026-01-24T10:30:15+0530",
  "message": "Test"
  "metadata": {
```

#### Diagnosis
```bash
# Validate JSON
cat /var/log/myapp/current/app.sh_2026-01-24.log | jq .

# Check for proper flag usage
grep -- --json /path/to/your/script.sh
```

#### Solutions

**Solution A**: Ensure --json flag is used
```bash
# Wrong - no flag
/opt/scripts/logCollector.sh 'test' 'test.sh' 'INFO' 'Message'

# Correct
/opt/scripts/logCollector.sh 'test' 'test.sh' 'INFO' 'Message' --json
```

**Solution B**: Validate with jq
```bash
# Install jq for validation
sudo yum install jq  # RHEL/CentOS
sudo apt-get install jq  # Debian/Ubuntu

# Validate each line
cat logfile.log | while read line; do echo "$line" | jq .; done
```

### 7. Disk Space Issues

#### Symptom
```
ERROR: No space left on device
```

#### Diagnosis
```bash
# Check disk usage
df -h /var/log

# Check log directory sizes
du -sh /var/log/*/ | sort -hr

# Check for large files
find /var/log -type f -size +100M -exec ls -lh {} \;
```

#### Solutions

**Solution A**: Clean old logs
```bash
# Run cleanup tool
sudo ./tools/cleanup.sh

# Or manually
sudo find /var/log -name "*.log.gz" -mtime +90 -delete
```

**Solution B**: Reduce retention
```bash
sudo vi /etc/logCollector.conf
# Reduce retention periods
LOG_RETENTION_DAYS=7
ARCHIVE_RETENTION_DAYS=30
```

**Solution C**: Increase rotation frequency
```bash
sudo vi /etc/logCollector.conf
# Smaller file size before rotation
MAX_LOG_SIZE_MB=50
```

**Solution D**: Move logs to larger partition
```bash
# Stop logging temporarily
# Create new location
sudo mkdir -p /mnt/large-disk/logs

# Move existing logs
sudo mv /var/log/* /mnt/large-disk/logs/

# Update configuration
sudo vi /etc/logCollector.conf
BASE_LOG_DIR="/mnt/large-disk/logs"
```

### 8. Metadata Not Appearing

#### Symptom
```bash
# Metadata not in output
/opt/scripts/logCollector.sh 'test' 'test.sh' 'INFO' 'Test' \
    --json --metadata key=value

# Output missing metadata
```

#### Solution
Ensure proper syntax:
```bash
# Wrong - missing --json
/opt/scripts/logCollector.sh 'test' 'test.sh' 'INFO' 'Test' --metadata key=value

# Correct
/opt/scripts/logCollector.sh 'test' 'test.sh' 'INFO' 'Test' \
    --json \
    --metadata key=value

# Multiple metadata
/opt/scripts/logCollector.sh 'test' 'test.sh' 'INFO' 'Test' \
    --json \
    --metadata key1=value1 \
    --metadata key2=value2
```

### 9. Syslog Not Receiving Logs

#### Symptom
```bash
# Logs not appearing in syslog
journalctl | grep myapp
# No results
```

#### Diagnosis
```bash
# Check logger command
which logger

# Test logger manually
logger -t test "Test message"
journalctl -t test

# Check configuration
grep ENABLE_SYSLOG /etc/logCollector.conf
```

#### Solutions

**Solution A**: Install logger
```bash
# Usually part of util-linux package
sudo yum install util-linux  # RHEL/CentOS
sudo apt-get install bsdutils  # Debian/Ubuntu
```

**Solution B**: Enable syslog
```bash
sudo vi /etc/logCollector.conf
ENABLE_SYSLOG=true

# Or use flag
/opt/scripts/logCollector.sh 'test' 'test.sh' 'INFO' 'Test' --syslog
```

**Solution C**: Check rsyslog service
```bash
# Check if running
systemctl status rsyslog

# Start if needed
sudo systemctl start rsyslog
sudo systemctl enable rsyslog
```

### 10. Script Not Found

#### Symptom
```
bash: /opt/scripts/logCollector.sh: No such file or directory
```

#### Solution
```bash
# Check if installed
ls -l /opt/scripts/logCollector.sh

# If not, install
cd /path/to/repo
sudo make install

# Or specify full path to script
/path/to/repo/bin/logCollector.sh 'test' 'test.sh' 'INFO' 'Test'
```

## Debugging Tools

### Enable Debug Mode

```bash
# Run script with bash debugging
bash -x /opt/scripts/logCollector.sh 'test' 'test.sh' 'DEBUG' 'Test message'
```

### Check Log Output

```bash
# View latest logs
tail -f /var/log/myapp/current/app.sh_$(date +%Y-%m-%d).log

# Search for errors
grep ERROR /var/log/myapp/current/*.log

# Check compressed archives
zgrep ERROR /var/log/myapp/archive/*.log.gz
```

### Analyze with Log Analyzer

```bash
# Run built-in analyzer
sudo ./tools/log_analyzer.sh
```

### Validate Script

```bash
# Check syntax
bash -n /opt/scripts/logCollector.sh

# Run validation
make validate
```

## Getting Help

If you're still stuck:

1. **Run health check**:
   ```bash
   sudo make health-check
   ```

2. **Check documentation**:
   - [Installation Guide](installation.md)
   - [Usage Guide](usage.md)
   - [Configuration Guide](configuration.md)

3. **Collect diagnostic info**:
   ```bash
   # Script version
   grep SCRIPT_VERSION /opt/scripts/logCollector.sh
   
   # Configuration
   cat /etc/logCollector.conf
   
   # Recent logs
   tail -50 /var/log/myapp/current/*.log
   
   # System info
   uname -a
   df -h
   ```

4. **Contact support**:
   - Email: dba-team@example.com
   - Include diagnostic information above


---

**Previous**: [Configuration Guide](configuration.md) | **Next**: [API Reference](api.md) →
