**Previous**: [Configuration Guide](configuration.md) | **Next**: [API Reference](api.md) →
```

#### `docs/api.md`
```markdown
# API Reference

Complete reference for Enhanced Log Collector functions and parameters.

## Command Line Interface

### Synopsis

```bash
logCollector.sh <TaskName> <ScriptName> <LogLevel> <Message> [Options]
```

### Required Parameters

#### TaskName
- **Type**: String
- **Description**: Logical grouping for logs
- **Creates**: `/var/log/<TaskName>/` directory
- **Examples**: `'backup'`, `'monitoring'`, `'api-server'`
- **Constraints**: 
  - No spaces
  - Alphanumeric, dashes, underscores allowed
  - Case-sensitive

```bash
# Valid
logCollector.sh 'backup' ...
logCollector.sh 'api-server' ...
logCollector.sh 'db_maintenance' ...

# Invalid
logCollector.sh 'my backup' ...  # Spaces not allowed
```

#### ScriptName
- **Type**: String
- **Description**: Name of the calling script
- **Recommendation**: Use `$0` or `$(basename $0)`
- **Creates**: Log file named `<ScriptName>_YYYY-MM-DD.log`
- **Examples**: `'backup.sh'`, `'monitor.py'`, `'app.js'`

```bash
# In your script
logCollector.sh 'myapp' "$0" 'INFO' 'Message'
logCollector.sh 'myapp' "$(basename $0)" 'INFO' 'Message'
```

#### LogLevel
- **Type**: Enum
- **Values**: `DEBUG` | `INFO` | `NOTICE` | `WARNING` | `ERROR` | `CRITICAL` | `FATAL`
- **Case**: Sensitive (must be uppercase)
- **Description**: Severity level of the log message

| Level | Value | Description |
|-------|-------|-------------|
| DEBUG | 0 | Detailed debugging information |
| INFO | 1 | General informational messages |
| NOTICE | 2 | Normal but significant events |
| WARNING | 3 | Warning messages |
| ERROR | 4 | Error conditions |
| CRITICAL | 5 | Critical conditions |
| FATAL | 6 | Fatal errors causing termination |

#### Message
- **Type**: String
- **Description**: The log message content
- **Constraints**: 
  - Enclose in quotes if contains spaces
  - Newlines supported
  - Maximum practical length: ~10,000 characters

```bash
# Simple
logCollector.sh 'myapp' 'app.sh' 'INFO' 'Application started'

# With variables
logCollector.sh 'myapp' 'app.sh' 'INFO' "Processed $count records"

# Multiline
logCollector.sh 'myapp' 'app.sh' 'ERROR' "Error occurred:
  Reason: Connection timeout
  Host: db.example.com"
```

### Optional Flags

#### --json
- **Description**: Output in JSON format
- **Default**: Plain text (unless configured otherwise)
- **Output**: Structured JSON with all fields

```bash
logCollector.sh 'myapp' 'app.sh' 'INFO' 'Message' --json
```

**Output**:
```json
{
  "timestamp": "2026-01-24T10:30:15+0530",
  "hostname": "server01.example.com",
  "script": "app.sh",
  "level": "INFO",
  "message": "Message",
  "pid": 12345,
  "user": "postgres",
  "version": "2.0"
}
```

#### --console
- **Description**: Display log on console with colors
- **Default**: No console output (unless configured otherwise)
- **Colors**: ANSI color codes based on log level

```bash
logCollector.sh 'myapp' 'app.sh' 'INFO' 'Message' --console
```

#### --syslog
- **Description**: Send log to system logger
- **Default**: No syslog (unless configured otherwise)
- **Requires**: `logger` command

```bash
logCollector.sh 'myapp' 'app.sh' 'INFO' 'Message' --syslog
```

#### --email
- **Description**: Send email alert (if level matches ALERT_LEVELS)
- **Default**: No email (unless configured otherwise)
- **Requires**: 
  - `mail` command
  - ENABLE_EMAIL_ALERTS=true
  - ALERT_EMAIL configured
  - Log level in ALERT_LEVELS

```bash
logCollector.sh 'myapp' 'app.sh' 'CRITICAL' 'Database down' --email
```

#### --stacktrace
- **Description**: Include shell stack trace in message
- **Use**: Debugging errors
- **Output**: Appends stack trace to message

```bash
logCollector.sh 'myapp' 'app.sh' 'ERROR' 'Unexpected error' --stacktrace
```

**Output**:
```
Unexpected error
Stack Trace:
3 log backup.sh 42
2 main backup.sh 100
1 source backup.sh 1
```

#### --metadata KEY=VALUE
- **Description**: Add custom metadata field
- **Format**: `key=value` pairs
- **Multiple**: Can specify multiple times
- **Requires**: `--json` flag for output
- **Constraints**: 
  - No spaces in key
  - Value can contain spaces if quoted

```bash
logCollector.sh 'myapp' 'app.sh' 'INFO' 'Backup done' \
    --json \
    --metadata size=50GB \
    --metadata duration=300s \
    --metadata status=success
```

**Output**:
```json
{
  "timestamp": "2026-01-24T10:30:15+0530",
  "message": "Backup done",
  "metadata": {
    "size": "50GB",
    "duration": "300s",
    "status": "success"
  }
}
```

### Flag Combinations

Flags can be combined:

```bash
# Write to file + console + syslog
logCollector.sh 'myapp' 'app.sh' 'INFO' 'Message' \
    --console \
    --syslog

# JSON format + metadata + email
logCollector.sh 'myapp' 'app.sh' 'CRITICAL' 'Error' \
    --json \
    --email \
    --metadata error_code=500

# All outputs
logCollector.sh 'myapp' 'app.sh' 'ERROR' 'Problem' \
    --console \
    --json \
    --syslog \
    --email \
    --stacktrace \
    --metadata severity=high
```

## Configuration File API

### File Location
`/etc/logCollector.conf`

### Format
Bash variable assignments

### Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| BASE_LOG_DIR | String | `/var/log` | Root log directory |
| DEFAULT_OWNER | String | `postgres:postgres` | File ownership |
| MAX_LOG_SIZE_MB | Integer | `100` | Rotation size threshold |
| LOG_RETENTION_DAYS | Integer | `30` | Uncompressed log retention |
| ARCHIVE_RETENTION_DAYS | Integer | `90` | Compressed archive retention |
| ENABLE_COMPRESSION | Boolean | `true` | Auto-compress rotated logs |
| ENABLE_JSON_FORMAT | Boolean | `false` | Default to JSON output |
| ENABLE_CONSOLE_OUTPUT | Boolean | `false` | Default console output |
| ENABLE_SYSLOG | Boolean | `false` | Default syslog output |
| ENABLE_EMAIL_ALERTS | Boolean | `false` | Enable email alerts |
| ALERT_EMAIL | String | `""` | Alert recipient email |
| ALERT_LEVELS | String | `"FATAL,CRITICAL"` | Levels that trigger email |

### Example Configuration

```bash
#!/bin/bash
# Production Configuration

BASE_LOG_DIR="/var/log"
DEFAULT_OWNER="postgres:postgres"
MAX_LOG_SIZE_MB=100
LOG_RETENTION_DAYS=30
ARCHIVE_RETENTION_DAYS=90
ENABLE_COMPRESSION=true
ENABLE_JSON_FORMAT=false
ENABLE_CONSOLE_OUTPUT=false
ENABLE_SYSLOG=true
ENABLE_EMAIL_ALERTS=true
ALERT_EMAIL="oncall@example.com"
ALERT_LEVELS="FATAL,CRITICAL"
SCRIPT_VERSION="2.0"
```

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | Invalid arguments or log level |
| 1 | Permission denied |
| 1 | Directory creation failed |

## Output Formats

### Plain Text Format

**Structure**:
```
<timestamp> [<hostname>] [<script>] [PID:<pid>] [<user>] [<level>] <message>
```

**Example**:
```
2026-01-24T10:30:15+0530 [server01.example.com] [backup.sh] [PID:12345] [postgres] [INFO] Backup started
```

**Fields**:
- `timestamp`: ISO 8601 with timezone
- `hostname`: Fully qualified domain name
- `script`: Script name
- `pid`: Process ID
- `user`: Username
- `level`: Log level
- `message`: Log message

### JSON Format

**Structure**:
```json
{
  "timestamp": "string (ISO 8601)",
  "hostname": "string",
  "script": "string",
  "level": "string",
  "message": "string",
  "pid": number,
  "user": "string",
  "version": "string",
  "metadata": {
    "key": "value"
  }
}
```

**Example**:
```json
{
  "timestamp": "2026-01-24T10:30:15+0530",
  "hostname": "server01.example.com",
  "script": "backup.sh",
  "level": "INFO",
  "message": "Backup started",
  "pid": 12345,
  "user": "postgres",
  "version": "2.0",
  "metadata": {
    "database": "production",
    "size": "50GB"
  }
}
```

## Directory Structure

### Created Structure

```
/var/log/<TaskName>/
├── current/
│   └── <ScriptName>_YYYY-MM-DD.log
└── archive/
    ├── <ScriptName>_YYYYMMDD_HHMMSS.log.gz
    └── <ScriptName>_YYYYMMDD_HHMMSS.log.gz
```

### Permissions

- Directories: `755` (drwxr-xr-x)
- Log files: `644` (-rw-r--r--)
- Owner: As specified in DEFAULT_OWNER or script execution user

## Internal Functions (For Development)

### validate_log_level(level)
Validates that the provided log level is valid.

**Returns**: 0 if valid, 1 if invalid

### get_timestamp()
Returns current timestamp in ISO 8601 format with timezone.

**Returns**: String (e.g., "2026-01-24T10:30:15+0530")

### create_log_structure(task_name)
Creates the directory structure for a task.

**Parameters**:
- task_name: Name of the task

**Returns**: 0 on success, 1 on failure

### check_rotation_needed(logfile)
Checks if a log file needs rotation based on size.

**Parameters**:
- logfile: Path to log file

**Returns**: 0 if rotation needed, 1 if not

### rotate_log(logfile, task_name)
Rotates a log file to the archive directory.

**Parameters**:
- logfile: Path to log file
- task_name: Name of the task

**Returns**: 0 on success

## Version History

| Version | Release Date | Changes |
|---------|--------------|---------|
| 2.0.0 | 2026-01-04 | Complete rewrite with rotation, compression, multiple formats |
| 1.0.0 | 2025-01-01 | Initial release |
