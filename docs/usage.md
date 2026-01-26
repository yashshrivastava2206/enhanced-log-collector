# Usage Guide

Complete guide to using Enhanced Log Collector in your applications.

## Table of Contents
1. [Basic Usage](#basic-usage)
2. [Log Levels](#log-levels)
3. [Output Formats](#output-formats)
4. [Metadata](#metadata)
5. [Common Patterns](#common-patterns)
6. [Integration](#integration)

## Basic Usage

### Command Syntax

```bash
/opt/scripts/logCollector.sh <TaskName> <ScriptName> <LogLevel> <Message> [Options]
```

**Parameters**:
- `TaskName`: Logical grouping (creates /var/log/TaskName/)
- `ScriptName`: Name of your script (use `$0`)
- `LogLevel`: DEBUG|INFO|NOTICE|WARNING|ERROR|CRITICAL|FATAL
- `Message`: Your log message
- `Options`: Optional flags (--console, --json, etc.)

### Simple Example

```bash
/opt/scripts/logCollector.sh 'myapp' 'myapp.sh' 'INFO' 'Application started'
```

This creates:
```
/var/log/myapp/current/myapp.sh_2026-01-24.log
```

## Log Levels

### Level Hierarchy

From least to most severe:

```
DEBUG (0)     → Detailed debugging
INFO (1)      → General information
NOTICE (2)    → Significant events
WARNING (3)   → Warning messages
ERROR (4)     → Error conditions
CRITICAL (5)  → Critical problems
FATAL (6)     → Fatal failures
```

### When to Use Each Level

#### DEBUG
Detailed information for diagnosing problems.

```bash
log 'DEBUG' "Processing record $i of $total"
log 'DEBUG' "Variable state: user=$USER, path=$PWD"
log 'DEBUG' "SQL query: SELECT * FROM users WHERE id=$id"
```

**Use when**: Development, troubleshooting, detailed tracing

#### INFO
General informational messages about normal operations.

```bash
log 'INFO' "Application started successfully"
log 'INFO' "Connected to database: production"
log 'INFO' "Processed 1000 records in 5.2 seconds"
```

**Use when**: Tracking normal flow, milestones, confirmations

#### NOTICE
Significant but normal events that deserve attention.

```bash
log 'NOTICE' "Configuration file reloaded"
log 'NOTICE' "Switched to standby database"
log 'NOTICE' "Cache cleared, rebuilding index"
```

**Use when**: Important state changes, configuration updates

#### WARNING
Potentially harmful situations that don't prevent operation.

```bash
log 'WARNING' "Disk usage at 85%"
log 'WARNING' "Query took 5.2s (threshold: 1s)"
log 'WARNING' "Deprecated API call detected"
```

**Use when**: Resource limits approaching, performance issues, deprecations

#### ERROR
Error conditions that don't stop the application.

```bash
log 'ERROR' "Failed to send email notification"
log 'ERROR' "Unable to connect to backup server"
log 'ERROR' "Invalid data format in input file"
```

**Use when**: Recoverable errors, retry attempts, validation failures

#### CRITICAL
Critical conditions requiring immediate attention.

```bash
log 'CRITICAL' "Primary database unreachable"
log 'CRITICAL' "All connection pool slots exhausted"
log 'CRITICAL' "Security breach detected"
```

**Use when**: Service degradation, security issues, resource exhaustion

#### FATAL
Fatal errors that force termination.

```bash
log 'FATAL' "Required configuration file missing"
log 'FATAL' "Cannot bind to port 5432"
log 'FATAL' "Unrecoverable database corruption"
exit 1
```

**Use when**: Application cannot continue, initialization failures

## Output Formats

### Plain Text (Default)

```bash
/opt/scripts/logCollector.sh 'myapp' 'test.sh' 'INFO' 'Test message'
```

**Output**:
```
2026-01-24T10:30:15+0530 [server01.example.com] [test.sh] [PID:12345] [postgres] [INFO] Test message
```

**Best for**: Traditional log files, grep operations, human reading

### JSON Format

```bash
/opt/scripts/logCollector.sh 'myapp' 'test.sh' 'INFO' 'Test message' --json
```

**Output**:
```json
{
  "timestamp": "2026-01-24T10:30:15+0530",
  "hostname": "server01.example.com",
  "script": "test.sh",
  "level": "INFO",
  "message": "Test message",
  "pid": 12345,
  "user": "postgres",
  "version": "2.0"
}
```

**Best for**: Log aggregation tools, APIs, machine parsing

### Console Output (Colored)

```bash
/opt/scripts/logCollector.sh 'myapp' 'test.sh' 'INFO' 'Test message' --console
```

**Output** (with colors):
```
[INFO] 2026-01-24T10:30:15+0530 [test.sh] Test message
```

**Best for**: Real-time monitoring, development, debugging

### Syslog Integration

```bash
/opt/scripts/logCollector.sh 'myapp' 'test.sh' 'INFO' 'Test message' --syslog
```

**Best for**: Centralized logging, compliance, system-wide collection

### Multiple Outputs

Combine formats:

```bash
/opt/scripts/logCollector.sh 'myapp' 'test.sh' 'ERROR' 'Database error' \
    --console \
    --json \
    --syslog \
    --email
```

## Metadata

Add structured data to logs:

### Basic Metadata

```bash
/opt/scripts/logCollector.sh 'backup' 'backup.sh' 'INFO' 'Backup completed' \
    --json \
    --metadata size=50GB \
    --metadata duration=300s
```

**Output**:
```json
{
  "timestamp": "2026-01-24T10:30:15+0530",
  "message": "Backup completed",
  "metadata": {
    "size": "50GB",
    "duration": "300s"
  }
}
```

### Multiple Metadata Fields

```bash
/opt/scripts/logCollector.sh 'api' 'api.sh' 'INFO' 'Request processed' \
    --json \
    --metadata endpoint=/api/users \
    --metadata method=GET \
    --metadata status=200 \
    --metadata duration_ms=45 \
    --metadata user_id=12345
```

## Common Patterns

### Pattern 1: Function Wrapper

Create a reusable logging function:

```bash
#!/bin/bash

LOG_SCRIPT="/opt/scripts/logCollector.sh"
TASK_NAME="myapp"

log() {
    local level=$1
    local message=$2
    shift 2
    $LOG_SCRIPT "$TASK_NAME" "$(basename $0)" "$level" "$message" "$@"
}

# Usage
log 'INFO' "Application started" --console
log 'ERROR' "Connection failed" --email
```

### Pattern 2: Error Handling

```bash
#!/bin/bash

log() {
    /opt/scripts/logCollector.sh 'myapp' "$0" "$1" "$2" --console
}

# With error handling
if ! connect_database; then
    log 'ERROR' "Database connection failed"
    log 'INFO' "Attempting reconnection..."
    
    if ! retry_connect; then
        log 'FATAL' "All connection attempts exhausted"
        exit 1
    fi
    
    log 'INFO' "Reconnection successful"
fi
```

### Pattern 3: Performance Tracking

```bash
#!/bin/bash

log() {
    /opt/scripts/logCollector.sh 'performance' "$0" "$@"
}

# Track execution time
START=$(date +%s)
process_data
END=$(date +%s)
DURATION=$((END - START))

log 'INFO' "Processing completed" \
    --json \
    --metadata duration="${DURATION}s" \
    --metadata records_processed=1000
```

### Pattern 4: Conditional Logging

```bash
#!/bin/bash

LOG_LEVEL=${LOG_LEVEL:-INFO}  # Default to INFO

log() {
    local level=$1
    local message=$2
    
    # Only log if level is high enough
    case "$level" in
        DEBUG) [[ "$LOG_LEVEL" == "DEBUG" ]] || return ;;
        INFO) [[ "$LOG_LEVEL" =~ ^(DEBUG|INFO)$ ]] || return ;;
    esac
    
    /opt/scripts/logCollector.sh 'myapp' "$0" "$level" "$message" --console
}

log 'DEBUG' "This only shows if LOG_LEVEL=DEBUG"
log 'INFO' "This shows for DEBUG or INFO"
```

### Pattern 5: Transaction Logging

```bash
#!/bin/bash

log() {
    /opt/scripts/logCollector.sh 'transactions' "$0" "$@"
}

TRANSACTION_ID=$(uuidgen)

log 'INFO' "Transaction started" \
    --json \
    --metadata transaction_id=$TRANSACTION_ID \
    --metadata user_id=$USER_ID

# ... perform operations ...

log 'INFO' "Transaction completed" \
    --json \
    --metadata transaction_id=$TRANSACTION_ID \
    --metadata status=success \
    --metadata duration=5.2s
```

## Integration

### Bash Scripts

```bash
#!/bin/bash
source /opt/scripts/log_wrapper.sh  # If you create one

log 'INFO' "Script started"

for file in *.dat; do
    log 'DEBUG' "Processing file: $file"
    process_file "$file"
done

log 'INFO' "Script completed"
```

### Python Integration

```python
from log_collector import LogCollector

logger = LogCollector('myapp')
logger.info("Application started")
logger.error("Error occurred", metadata={'error_code': 500})
```

See [examples/python_integration.py](../examples/python_integration.py)

### Cron Jobs

```bash
# In crontab
0 2 * * * /path/to/backup.sh 2>&1 | while read line; do \
    /opt/scripts/logCollector.sh 'backup-cron' 'backup.sh' 'INFO' "$line"; \
done
```

See [examples/cron_example.sh](../examples/cron_example.sh)

## Best Practices

### DO
✅ Use appropriate log levels  
✅ Include context in messages  
✅ Add metadata for structured data  
✅ Use task names consistently  
✅ Log errors with enough detail  

### DON'T
❌ Log sensitive data (passwords, keys)  
❌ Over-use high severity levels  
❌ Create extremely long messages  
❌ Log in tight loops without throttling  
❌ Mix different task names randomly  

## Examples Summary

| Example | Location | Description |
|---------|----------|-------------|
| Basic | [examples/basic_usage.sh](../examples/basic_usage.sh) | Simple logging patterns |
| Advanced | [examples/advanced_usage.sh](../examples/advanced_usage.sh) | JSON, metadata, alerts |
| Python | [examples/python_integration.py](../examples/python_integration.py) | Python wrapper class |
| Cron | [examples/cron_example.sh](../examples/cron_example.sh) | Cron job integration |
| Systemd | [examples/systemd_example.service](../examples/systemd_example.service) | Service integration |

---

**Previous**: [Installation Guide](installation.md) | **Next**: [Configuration Guide](configuration.md) →

