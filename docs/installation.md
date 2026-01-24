# Installation Guide

Complete guide to installing Enhanced Log Collector on your system.

## Prerequisites

### Required Software
- **Bash**: Version 4.0 or higher
- **GNU Coreutils**: date, stat, find, grep
- **gzip**: For log compression

### Optional Software
- **logger**: For syslog integration (usually pre-installed)
- **mail/sendmail**: For email alerts
- **ShellCheck**: For development (optional)

### System Requirements
- **Disk Space**: 50MB for installation, additional space for logs
- **Permissions**: Root or sudo access for system-wide installation
- **OS**: Linux (tested on RHEL, CentOS, Ubuntu, Debian)

## Installation Methods

### Method 1: Using Make (Recommended)

```bash
# 1. Clone or download the repository
git clone https://github.com/your-org/enhanced-log-collector.git
cd enhanced-log-collector

# 2. Validate prerequisites
make validate

# 3. Install
sudo make install

# 4. Verify installation
make test
```

### Method 2: Manual Installation

```bash
# 1. Download the repository
wget https://github.com/your-org/enhanced-log-collector/archive/v2.0.0.tar.gz
tar -xzf v2.0.0.tar.gz
cd enhanced-log-collector-2.0.0

# 2. Make scripts executable
chmod +x bin/logCollector.sh
chmod +x scripts/*.sh

# 3. Run installation script
sudo ./scripts/install.sh

# 4. Test installation
./bin/logCollector.sh 'test' 'test.sh' 'INFO' 'Installation test' --console
```

### Method 3: Docker (Coming Soon)

```bash
# Pull image
docker pull your-org/enhanced-log-collector:2.0.0

# Run container with volume mount
docker run -v /var/log:/var/log enhanced-log-collector:2.0.0
```

## Post-Installation Setup

### 1. Configure the System

Edit the configuration file:

```bash
sudo vi /etc/logCollector.conf
```

**Minimum Configuration**:
```bash
BASE_LOG_DIR="/var/log"
DEFAULT_OWNER="your-user:your-group"
MAX_LOG_SIZE_MB=100
ENABLE_COMPRESSION=true
```

### 2. Set Up Email Alerts (Optional)

```bash
# Install mail if not present
sudo yum install mailx  # RHEL/CentOS
# or
sudo apt-get install mailutils  # Debian/Ubuntu

# Configure in /etc/logCollector.conf
ENABLE_EMAIL_ALERTS=true
ALERT_EMAIL="your-team@example.com"
ALERT_LEVELS="FATAL,CRITICAL"
```

### 3. Test Email Alerts

```bash
/opt/scripts/logCollector.sh 'test' 'test.sh' 'CRITICAL' 'Test alert' --email
```

### 4. Create Your First Log

```bash
/opt/scripts/logCollector.sh 'myapp' 'myapp.sh' 'INFO' 'Application started' --console
```

View the log:
```bash
cat /var/log/myapp/current/myapp.sh_$(date +%Y-%m-%d).log
```

## Environment-Specific Installation

### Development Environment

```bash
# Use development config
sudo cp config/logCollector.conf.dev /etc/logCollector.conf

# Enable console output by default
sudo sed -i 's/ENABLE_CONSOLE_OUTPUT=false/ENABLE_CONSOLE_OUTPUT=true/' /etc/logCollector.conf

# Reduce retention for faster testing
sudo sed -i 's/LOG_RETENTION_DAYS=30/LOG_RETENTION_DAYS=1/' /etc/logCollector.conf
```

### Production Environment

```bash
# Use production config
sudo cp config/logCollector.conf.prod /etc/logCollector.conf

# Enable syslog forwarding
sudo sed -i 's/ENABLE_SYSLOG=false/ENABLE_SYSLOG=true/' /etc/logCollector.conf

# Configure email alerts
sudo sed -i 's/ALERT_EMAIL=""/ALERT_EMAIL="oncall@example.com"/' /etc/logCollector.conf
```

## Verification

### Run Health Check

```bash
sudo make health-check
# or
sudo ./tools/health_check.sh
```

Expected output:
```
╔════════════════════════════════════════════════════════════╗
║              Health Check                                  ║
╚════════════════════════════════════════════════════════════╝

[1/8] Checking script installation...
✓ Script installed (v2.0)
[2/8] Checking configuration...
✓ Configuration file exists
...
✓ All checks passed
System is healthy
```

### Run Test Suite

```bash
make test
```

## Troubleshooting Installation

### Permission Denied

**Problem**: `Permission denied` errors during installation

**Solution**:
```bash
# Ensure you're running with sudo
sudo make install

# Or manually fix permissions
sudo chown -R root:root /opt/scripts/logCollector.sh
sudo chmod 755 /opt/scripts/logCollector.sh
```

### Missing Dependencies

**Problem**: `command not found` errors

**Solution**:
```bash
# RHEL/CentOS
sudo yum install bash gzip findutils coreutils

# Debian/Ubuntu
sudo apt-get install bash gzip findutils coreutils
```

### Configuration Not Loading

**Problem**: Settings in `/etc/logCollector.conf` not applied

**Solution**:
```bash
# Check file permissions
ls -la /etc/logCollector.conf

# Should be readable
sudo chmod 644 /etc/logCollector.conf

# Verify syntax
bash -n /etc/logCollector.conf
```

## Uninstallation

To remove Enhanced Log Collector:

```bash
# Using Make
sudo make uninstall

# Or manually
sudo ./scripts/uninstall.sh
```

**Warning**: This will prompt before removing logs and configuration.

## Next Steps

- [Configuration Guide](configuration.md) - Configure for your needs
- [Usage Guide](usage.md) - Learn how to use the system
- [Examples](../examples/) - See integration examples
