# Enhanced Log Collector v3.0 - Quick Reference Card

**Author:** Yash Shrivastava | **Version:** 3.0.0

---

## ⚡ Basic Syntax

```bash
logCollector.sh [OPTIONS] <task> <script> <level> <message>
```

---

## 📊 Log Levels (Low → High Severity)

| Level | Use For | Example |
|-------|---------|---------|
| **DEBUG** | Debugging info | Variable values, loop iterations |
| **INFO** | Normal operations | "Backup started", "Process complete" |
| **NOTICE** | Significant events | "Config loaded", "Service ready" |
| **WARNING** | Potential issues | "Disk at 85%", "Slow query" |
| **ERROR** | Error conditions | "Connection failed", "File not found" |
| **CRITICAL** | Critical problems | "Database down", "Disk full" |
| **FATAL** | Fatal errors | "System crash", "Corruption detected" |

---

## 🚀 Common Commands

```bash
# Basic logging
./logCollector.sh backup backup.sh INFO "Backup started"

# With console output
./logCollector.sh backup backup.sh ERROR "Failed" --console

# JSON format
./logCollector.sh api app.py INFO "Request" --json

# With metadata
./logCollector.sh api app.py ERROR "Error" -m code=500 -m user=admin

# Email alert
./logCollector.sh system monitor FATAL "Crash" --email --stacktrace

# Multiple outputs
./logCollector.sh app app.sh WARNING "Warning" --console --syslog --json
```

---

## 🎛️ Essential Flags

### Output Format
| Flag | Description |
|------|-------------|
| `--console` | Show on console with colors |
| `--json` | Output as JSON |
| `--syslog` | Send to syslog |

### Alerts & Debugging
| Flag | Description |
|------|-------------|
| `--email` | Send email alert |
| `--stacktrace` | Include stack trace |
| `--debug` | Enable debug mode |

### Metadata
| Flag | Description | Example |
|------|-------------|---------|
| `-m KEY=VALUE` | Add metadata | `-m env=prod -m user=john` |

### Configuration
| Flag | Description |
|------|-------------|
| `-c FILE` | Use config file |
| `--show-config` | Display config |
| `--validate` | Validate config |

### Maintenance
| Flag | Description |
|------|-------------|
| `--cleanup [TASK]` | Clean old logs |
| `--rotate [TASK]` | Force rotation |
| `--compress [TASK]` | Compress archives |

### Testing
| Flag | Description |
|------|-------------|
| `-n, --dry-run` | Test without doing |
| `-V, --verbose` | Verbose output |
| `-q, --quiet` | Suppress output |

---

## 📁 Directory Structure

```
/var/log/<task>/
├── current/              # Active logs
│   └── script_YYYY-MM-DD.log
└── archive/              # Rotated logs
    └── script_YYYYMMDD_HHMMSS.log.gz
```

---

## 🔧 Configuration Files

```bash
/etc/logCollector.conf                  # Default
/etc/logCollector.production.conf       # Production
/etc/logCollector.development.conf      # Development
/etc/logCollector.staging.conf          # Staging
```

---

## 🔄 Quick Integration

### Bash
```bash
LOG="/opt/scripts/logCollector.sh"
log() { $LOG myapp "$0" "$1" "$2" --console "${@:3}"; }
log INFO "App started"
```

### Python
```python
import subprocess
def log(level, msg):
    subprocess.run(['./logCollector.sh', 'app', 'app.py', level, msg, '--console'])
```

### Cron
```bash
0 2 * * * /path/to/script.sh 2>&1 | \
  xargs -I {} ./logCollector.sh cron script.sh INFO "{}"
```

---

## 🛠️ Maintenance

```bash
# Validate config
./logCollector.sh --validate

# Show config
./logCollector.sh --show-config

# Clean logs
./logCollector.sh --cleanup backup

# Rotate logs
./logCollector.sh --rotate backup

# Test command
./logCollector.sh --dry-run backup test.sh INFO "Test" --console
```

---

## 🐛 Quick Troubleshooting

| Problem | Solution |
|---------|----------|
| Permission denied | `sudo chown -R user:group /var/log/task` |
| Config not loading | `./logCollector.sh -c /path/to/config --validate` |
| Logs not rotating | `./logCollector.sh --rotate task` |
| Email not sending | Check `ALERT_EMAIL` in config, test with `--email` flag |
| Disk full | `./logCollector.sh --cleanup` or increase `MIN_FREE_DISK_MB` |

---

## 🔒 Security Checklist

- [ ] Set config permissions: `chmod 640 /etc/logCollector.conf`
- [ ] Enable input sanitization: `SANITIZE_INPUT=true`
- [ ] Set file permissions: `LOG_FILE_PERMISSIONS=640`
- [ ] Limit message length: `MAX_MESSAGE_LENGTH=65536`
- [ ] Enable rate limiting: `ENABLE_RATE_LIMIT=true`

---

## 📊 Performance Tips

### High Volume
```bash
MAX_LOG_SIZE_MB=500
ASYNC_COMPRESSION=true
ENABLE_SIZE_CACHE=true
RATE_LIMIT_MAX=50000
ENABLE_SAMPLING=true
```

### Low Resources
```bash
MAX_LOG_SIZE_MB=5
LOG_RETENTION_DAYS=1
COMPRESSION_LEVEL=9
ENABLE_SAMPLING=true
SAMPLE_RATE=1
```

---

## 🚨 Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | Invalid arguments |
| 2 | Permission denied |
| 3 | Disk space error |
| 4 | Configuration error |
| 5 | Email error |
| 6 | Rate limit exceeded |

---

## 📞 Help

```bash
# Quick help
./logCollector.sh

# Full help
./logCollector.sh --help

# Version
./logCollector.sh --version
```

---

## 🔗 Resources

- **GitHub:** https://github.com/yashshrivastava2206/enhanced-log-collector
- **Full Documentation:** README_v3.md
- **Config Guide:** CONFIGURATION_GUIDE.md

---

**Quick Reference v3.0** | © 2026 Yash Shrivastava | MIT License
