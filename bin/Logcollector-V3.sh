#!/usr/bin/env bash
################################################################################
# Enhanced Log Collector v3.0
# 
# A production-grade logging system with automatic rotation, compression,
# retention policies, and multiple output formats.
#
# Author: Yash Shrivastava
# Copyright: © 2026 Yash Shrivastava
# License: MIT
# Version: 3.0.0
# Repository: https://github.com/yashshrivastava2206/enhanced-log-collector
################################################################################

set -o pipefail

################################################################################
# SCRIPT METADATA
################################################################################
readonly SCRIPT_VERSION="3.0.0"
readonly SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_PID=$$

################################################################################
# EXIT CODES
################################################################################
readonly EXIT_SUCCESS=0
readonly EXIT_INVALID_ARGS=1
readonly EXIT_PERMISSION_DENIED=2
readonly EXIT_DISK_SPACE_ERROR=3
readonly EXIT_CONFIG_ERROR=4
readonly EXIT_EMAIL_ERROR=5
readonly EXIT_RATE_LIMIT=6

################################################################################
# DEFAULT CONFIGURATION
################################################################################
BASE_LOG_DIR="${BASE_LOG_DIR:-/var/log}"
DEFAULT_OWNER="${DEFAULT_OWNER:-postgres:postgres}"
MAX_LOG_SIZE_MB="${MAX_LOG_SIZE_MB:-100}"
LOG_RETENTION_DAYS="${LOG_RETENTION_DAYS:-30}"
ARCHIVE_RETENTION_DAYS="${ARCHIVE_RETENTION_DAYS:-90}"
ENABLE_COMPRESSION="${ENABLE_COMPRESSION:-true}"
COMPRESSION_LEVEL="${COMPRESSION_LEVEL:-6}"
ENABLE_EMAIL_ALERTS="${ENABLE_EMAIL_ALERTS:-false}"
ALERT_EMAIL="${ALERT_EMAIL:-}"
ALERT_LEVELS="${ALERT_LEVELS:-FATAL,CRITICAL}"
EMAIL_SUBJECT_PREFIX="${EMAIL_SUBJECT_PREFIX:-[LOG-ALERT]}"
ENABLE_SYSLOG="${ENABLE_SYSLOG:-false}"
SYSLOG_FACILITY="${SYSLOG_FACILITY:-local0}"
SYSLOG_SERVER="${SYSLOG_SERVER:-}"
ENABLE_JSON_FORMAT="${ENABLE_JSON_FORMAT:-false}"
ENABLE_CONSOLE_OUTPUT="${ENABLE_CONSOLE_OUTPUT:-false}"
ENABLE_RATE_LIMIT="${ENABLE_RATE_LIMIT:-true}"
RATE_LIMIT_MAX="${RATE_LIMIT_MAX:-10000}"
RATE_LIMIT_WINDOW="${RATE_LIMIT_WINDOW:-60}"
RATE_LIMIT_ACTION="${RATE_LIMIT_ACTION:-sample}"
SANITIZE_INPUT="${SANITIZE_INPUT:-true}"
MAX_TASK_NAME_LENGTH="${MAX_TASK_NAME_LENGTH:-100}"
MAX_MESSAGE_LENGTH="${MAX_MESSAGE_LENGTH:-65536}"
MIN_FREE_DISK_MB="${MIN_FREE_DISK_MB:-1024}"
DISK_WARNING_THRESHOLD="${DISK_WARNING_THRESHOLD:-80}"
DISK_CRITICAL_THRESHOLD="${DISK_CRITICAL_THRESHOLD:-90}"
DISK_CRITICAL_ACTION="${DISK_CRITICAL_ACTION:-cleanup}"
ASYNC_COMPRESSION="${ASYNC_COMPRESSION:-true}"
ENABLE_SIZE_CACHE="${ENABLE_SIZE_CACHE:-true}"
SIZE_CACHE_TIMEOUT="${SIZE_CACHE_TIMEOUT:-60}"
CLEANUP_CHECK_PROBABILITY="${CLEANUP_CHECK_PROBABILITY:-1}"
LOG_FILE_PERMISSIONS="${LOG_FILE_PERMISSIONS:-640}"
LOG_DIR_PERMISSIONS="${LOG_DIR_PERMISSIONS:-750}"
ENABLE_HEALTH_CHECK="${ENABLE_HEALTH_CHECK:-false}"
HEALTH_CHECK_FILE="${HEALTH_CHECK_FILE:-/var/run/logCollector.health}"
ENABLE_METRICS="${ENABLE_METRICS:-false}"
METRICS_FILE="${METRICS_FILE:-/var/log/logCollector_metrics.txt}"
DEBUG_MODE="${DEBUG_MODE:-false}"

################################################################################
# LOG LEVELS
################################################################################
declare -A LOG_LEVEL_VALUES=(
    [DEBUG]=0
    [INFO]=1
    [NOTICE]=2
    [WARNING]=3
    [ERROR]=4
    [CRITICAL]=5
    [FATAL]=6
)

declare -A LOG_LEVEL_COLORS=(
    [DEBUG]='\033[0;36m'      # Cyan
    [INFO]='\033[0;32m'       # Green
    [NOTICE]='\033[0;34m'     # Blue
    [WARNING]='\033[0;33m'    # Yellow
    [ERROR]='\033[0;31m'      # Red
    [CRITICAL]='\033[1;31m'   # Bold Red
    [FATAL]='\033[1;35m'      # Bold Magenta
)
readonly COLOR_RESET='\033[0m'

################################################################################
# GLOBAL VARIABLES
################################################################################
declare -A SIZE_CACHE
declare -A RATE_LIMIT_COUNTER
declare -A METRICS=(
    [total_logs]=0
    [errors]=0
    [rotations]=0
    [compressions]=0
)

# Command-line options
OPT_CONFIG_FILE=""
OPT_USER=""
OPT_GROUP=""
OPT_CONSOLE=false
OPT_JSON=false
OPT_SYSLOG=false
OPT_EMAIL=false
OPT_STACKTRACE=false
OPT_NO_ROTATION=false
OPT_NO_COMPRESSION=false
OPT_QUIET=false
OPT_VERBOSE=false
OPT_DRY_RUN=false
OPT_FORCE=false
OPT_SHOW_CONFIG=false
OPT_VALIDATE=false
OPT_CLEANUP=false
declare -A OPT_METADATA

################################################################################
# UTILITY FUNCTIONS
################################################################################

print_color() {
    local color="$1"
    local message="$2"
    if [[ -t 1 ]]; then
        echo -e "${color}${message}${COLOR_RESET}"
    else
        echo "$message"
    fi
}

log_internal() {
    local level="$1"
    local message="$2"
    
    [[ "$OPT_QUIET" == "true" ]] && return 0
    
    case "$level" in
        ERROR|CRITICAL|FATAL)
            print_color "${LOG_LEVEL_COLORS[ERROR]}" "[$level] $message" >&2
            ;;
        *)
            [[ "$OPT_VERBOSE" == "true" ]] && print_color "${LOG_LEVEL_COLORS[INFO]}" "[DEBUG] $message"
            ;;
    esac
}

die() {
    local message="$1"
    local exit_code="${2:-$EXIT_INVALID_ARGS}"
    print_color "${LOG_LEVEL_COLORS[FATAL]}" "FATAL: $message" >&2
    exit "$exit_code"
}

warn() {
    print_color "${LOG_LEVEL_COLORS[WARNING]}" "WARNING: $1" >&2
}

################################################################################
# HELP AND USAGE
################################################################################

show_version() {
    cat << EOF
Enhanced Log Collector v${SCRIPT_VERSION}
Author: Yash Shrivastava
Copyright: © 2026 Yash Shrivastava
License: MIT
EOF
}

show_help() {
    cat << 'EOF'
╔══════════════════════════════════════════════════════════════════════════╗
║              Enhanced Log Collector v3.0 - User Guide                   ║
║              Author: Yash Shrivastava                                    ║
╚══════════════════════════════════════════════════════════════════════════╝

SYNOPSIS
    logCollector.sh [OPTIONS] <task> <script> <level> <message>

DESCRIPTION
    A production-grade logging system with automatic rotation, compression,
    retention policies, and multiple output formats.

REQUIRED ARGUMENTS
    <task>          Task name or category (e.g., 'backup', 'maintenance')
    <script>        Script name or source identifier (e.g., 'backup.sh')
    <level>         Log level (see LOG LEVELS below)
    <message>       Log message text

LOG LEVELS (severity order: low → high)
    DEBUG           Detailed debugging information
    INFO            General informational messages
    NOTICE          Normal but significant events
    WARNING         Warning messages
    ERROR           Error conditions
    CRITICAL        Critical conditions requiring attention
    FATAL           Fatal errors causing termination

GENERAL OPTIONS
    -h, --help              Show this help message
    -v, --version           Show version information
    -V, --verbose           Enable verbose output
    -q, --quiet             Suppress all output except errors
    -n, --dry-run           Show what would be done without doing it

CONFIGURATION OPTIONS
    -c, --config FILE       Use specified configuration file
                            Default: /etc/logCollector.conf
    --show-config           Display current configuration and exit
    --validate              Validate configuration and exit

OUTPUT FORMAT OPTIONS
    --console               Display output on console with colors
    --json                  Format output as JSON
    --syslog                Send to syslog
    --plain                 Use plain text format (default)

OUTPUT DESTINATION OPTIONS
    --email                 Send email alert for this message
    --no-file               Don't write to file (console/syslog only)

LOG MANAGEMENT OPTIONS
    --no-rotation           Disable log rotation for this write
    --no-compression        Disable compression for rotated logs
    -f, --force             Force operation even if checks fail

METADATA OPTIONS
    -m, --metadata KEY=VALUE    Add custom metadata field
                                Can be used multiple times
                                Example: -m env=prod -m user=admin

PERMISSION OPTIONS
    -u, --user USER         Set file owner user
    -g, --group GROUP       Set file owner group
    --permissions MODE      Set file permissions (octal)

DEBUGGING OPTIONS
    --stacktrace            Include stack trace in log
    --debug                 Enable debug mode

MAINTENANCE OPTIONS
    --cleanup [TASK]        Run cleanup for task (or all if not specified)
    --rotate [TASK]         Force rotation for task
    --compress [TASK]       Force compression of archives

EXAMPLES
    Basic logging:
        logCollector.sh backup backup.sh INFO "Backup started"

    With console output:
        logCollector.sh backup backup.sh INFO "Processing..." --console

    JSON format with metadata:
        logCollector.sh api api.py ERROR "Request failed" \\
            --json --metadata status=500 --metadata endpoint=/api/users

    Critical alert with email:
        logCollector.sh system monitor.sh FATAL "Disk full" \\
            --email --stacktrace --console

    Custom config file:
        logCollector.sh -c /etc/logCollector.prod.conf \\
            backup backup.sh INFO "Started"

    Multiple outputs:
        logCollector.sh backup backup.sh WARNING "Low disk space" \\
            --console --syslog --email

    With custom ownership:
        logCollector.sh -u postgres -g postgres \\
            database pg_backup.sh INFO "Backup complete"

    Dry run:
        logCollector.sh --dry-run backup backup.sh INFO "Test message"

MAINTENANCE EXAMPLES
    Cleanup old logs:
        logCollector.sh --cleanup backup

    Force log rotation:
        logCollector.sh --rotate backup

    Compress all archives:
        logCollector.sh --compress backup

    Validate configuration:
        logCollector.sh --validate

    Show current config:
        logCollector.sh --show-config

INTEGRATION EXAMPLES
    In bash scripts:
        #!/bin/bash
        LOG="./logCollector.sh"
        
        log() {
            $LOG "myapp" "$0" "$1" "$2" --console "${@:3}"
        }
        
        log INFO "Application started"
        log ERROR "Connection failed" --metadata retry=3

    In cron jobs:
        0 2 * * * /opt/scripts/logCollector.sh \\
            backup cron INFO "Daily backup started" --syslog

    With systemd:
        ExecStart=/usr/bin/logCollector.sh \\
            myservice service.sh INFO "Service started" --console

ENVIRONMENT VARIABLES
    LOG_COLLECTOR_ENV       Environment name (production, staging, dev)
                           Loads /etc/logCollector.<env>.conf
    
    LOG_COLLECTOR_CONFIG    Override config file path
    
    BASE_LOG_DIR           Override base log directory

DIRECTORY STRUCTURE
    /var/log/<task>/
    ├── current/           Active log files
    │   └── <script>_YYYY-MM-DD.log
    ├── archive/           Rotated & compressed logs
    │   └── <script>_YYYYMMDD_HHMMSS.log.gz
    └── metadata.json      Optional metadata

CONFIGURATION FILES
    /etc/logCollector.conf              Default configuration
    /etc/logCollector.production.conf   Production environment
    /etc/logCollector.development.conf  Development environment
    /etc/logCollector.staging.conf      Staging environment

LOG ROTATION
    - Automatic rotation when file reaches MAX_LOG_SIZE_MB (default: 100MB)
    - Daily rotation (new file per day)
    - Compressed archives (gzip)
    - Configurable retention policies

RETENTION POLICIES
    - Uncompressed logs: LOG_RETENTION_DAYS (default: 30)
    - Compressed archives: ARCHIVE_RETENTION_DAYS (default: 90)
    - Automatic cleanup of expired logs

RATE LIMITING
    - Prevents log flooding
    - Configurable limits: RATE_LIMIT_MAX per RATE_LIMIT_WINDOW
    - Actions: drop, sample, or block

SECURITY FEATURES
    - Input sanitization (prevent injection attacks)
    - Configurable file permissions
    - Ownership management
    - Path traversal prevention

HEALTH & MONITORING
    - Health check file updates
    - Metrics collection
    - Disk space monitoring
    - Performance tracking

FILES
    /etc/logCollector.conf          Configuration file
    /var/log/<task>/               Log directory structure
    /var/run/logCollector.health    Health check file
    /var/log/logCollector_metrics.txt    Metrics file

EXIT CODES
    0    Success
    1    Invalid arguments
    2    Permission denied
    3    Disk space error
    4    Configuration error
    5    Email error
    6    Rate limit exceeded

AUTHOR
    Written by Yash Shrivastava

COPYRIGHT
    Copyright © 2026 Yash Shrivastava
    License: MIT

REPORTING BUGS
    Report bugs to: https://github.com/yashshrivastava2206/enhanced-log-collector/issues

SEE ALSO
    logger(1), syslog(3), logrotate(8)

EOF
}

show_quick_help() {
    cat << EOF
Usage: $SCRIPT_NAME [OPTIONS] <task> <script> <level> <message>

Quick Examples:
  $SCRIPT_NAME backup backup.sh INFO "Backup started"
  $SCRIPT_NAME api app.py ERROR "Failed" --console --json
  $SCRIPT_NAME system monitor FATAL "Critical" --email --stacktrace

Options:
  -h, --help              Show full help
  -v, --version           Show version
  -c, --config FILE       Config file
  --console               Console output
  --json                  JSON format
  --email                 Send email alert
  -m, --metadata K=V      Add metadata

For full documentation: $SCRIPT_NAME --help
EOF
}

################################################################################
# CONFIGURATION MANAGEMENT
################################################################################

load_configuration() {
    local config_file="${OPT_CONFIG_FILE}"
    
    # Auto-detect config file
    if [[ -z "$config_file" ]]; then
        local env="${LOG_COLLECTOR_ENV:-production}"
        
        if [[ -f "/etc/logCollector.${env}.conf" ]]; then
            config_file="/etc/logCollector.${env}.conf"
        elif [[ -f "/etc/logCollector.conf" ]]; then
            config_file="/etc/logCollector.conf"
        fi
    fi
    
    if [[ -n "$config_file" ]]; then
        if [[ ! -f "$config_file" ]]; then
            die "Configuration file not found: $config_file" $EXIT_CONFIG_ERROR
        fi
        
        if [[ ! -r "$config_file" ]]; then
            die "Cannot read configuration file: $config_file" $EXIT_PERMISSION_DENIED
        fi
        
        log_internal "INFO" "Loading configuration from: $config_file"
        
        # shellcheck source=/dev/null
        source "$config_file" || die "Failed to load configuration: $config_file" $EXIT_CONFIG_ERROR
    fi
}

validate_configuration() {
    local errors=0
    
    # Check required variables
    if [[ -z "$BASE_LOG_DIR" ]]; then
        warn "BASE_LOG_DIR not set"
        ((errors++))
    fi
    
    # Validate numeric values
    if ! [[ "$MAX_LOG_SIZE_MB" =~ ^[0-9]+$ ]]; then
        warn "MAX_LOG_SIZE_MB must be numeric: $MAX_LOG_SIZE_MB"
        ((errors++))
    fi
    
    if ! [[ "$LOG_RETENTION_DAYS" =~ ^[0-9]+$ ]]; then
        warn "LOG_RETENTION_DAYS must be numeric: $LOG_RETENTION_DAYS"
        ((errors++))
    fi
    
    if ! [[ "$ARCHIVE_RETENTION_DAYS" =~ ^[0-9]+$ ]]; then
        warn "ARCHIVE_RETENTION_DAYS must be numeric: $ARCHIVE_RETENTION_DAYS"
        ((errors++))
    fi
    
    # Validate email settings
    if [[ "$ENABLE_EMAIL_ALERTS" == "true" ]] && [[ -z "$ALERT_EMAIL" ]]; then
        warn "Email alerts enabled but ALERT_EMAIL not set"
    fi
    
    if [[ "$OPT_VALIDATE" == "true" ]]; then
        if [[ $errors -eq 0 ]]; then
            echo "✓ Configuration is valid"
            exit 0
        else
            die "Configuration has $errors error(s)" $EXIT_CONFIG_ERROR
        fi
    fi
    
    return $errors
}

show_configuration() {
    cat << EOF
════════════════════════════════════════════════════════════════
 Current Configuration
════════════════════════════════════════════════════════════════
Version:                 $SCRIPT_VERSION
Base Log Directory:      $BASE_LOG_DIR
Default Owner:           $DEFAULT_OWNER
Max Log Size:            ${MAX_LOG_SIZE_MB}MB
Log Retention:           ${LOG_RETENTION_DAYS} days
Archive Retention:       ${ARCHIVE_RETENTION_DAYS} days
Compression Enabled:     $ENABLE_COMPRESSION
Compression Level:       $COMPRESSION_LEVEL
Email Alerts:            $ENABLE_EMAIL_ALERTS
Alert Email:             ${ALERT_EMAIL:-not set}
Alert Levels:            $ALERT_LEVELS
Syslog Enabled:          $ENABLE_SYSLOG
Syslog Facility:         $SYSLOG_FACILITY
JSON Format:             $ENABLE_JSON_FORMAT
Console Output:          $ENABLE_CONSOLE_OUTPUT
Rate Limiting:           $ENABLE_RATE_LIMIT
Rate Limit Max:          $RATE_LIMIT_MAX
Rate Limit Window:       ${RATE_LIMIT_WINDOW}s
Sanitize Input:          $SANITIZE_INPUT
Min Free Disk:           ${MIN_FREE_DISK_MB}MB
Async Compression:       $ASYNC_COMPRESSION
File Permissions:        $LOG_FILE_PERMISSIONS
Directory Permissions:   $LOG_DIR_PERMISSIONS
Health Check:            $ENABLE_HEALTH_CHECK
Metrics:                 $ENABLE_METRICS
Debug Mode:              $DEBUG_MODE
════════════════════════════════════════════════════════════════
EOF
}

################################################################################
# INPUT VALIDATION & SANITIZATION
################################################################################

validate_log_level() {
    local level="$1"
    
    if [[ ! -v LOG_LEVEL_VALUES[$level] ]]; then
        die "Invalid log level: '$level'\nValid levels: ${!LOG_LEVEL_VALUES[*]}" $EXIT_INVALID_ARGS
    fi
}

sanitize_task_name() {
    local task="$1"
    
    if [[ "$SANITIZE_INPUT" != "true" ]]; then
        echo "$task"
        return 0
    fi
    
    # Remove dangerous characters
    task="${task//[^a-zA-Z0-9_-]/}"
    
    # Limit length
    task="${task:0:$MAX_TASK_NAME_LENGTH}"
    
    if [[ -z "$task" ]]; then
        die "Invalid task name after sanitization" $EXIT_INVALID_ARGS
    fi
    
    echo "$task"
}

sanitize_message() {
    local message="$1"
    
    if [[ "$SANITIZE_INPUT" != "true" ]]; then
        echo "$message"
        return 0
    fi
    
    # Limit length
    message="${message:0:$MAX_MESSAGE_LENGTH}"
    
    echo "$message"
}

sanitize_metadata_value() {
    local value="$1"
    
    # Escape special characters for JSON
    value="${value//\\/\\\\}"
    value="${value//\"/\\\"}"
    value="${value//$'\n'/\\n}"
    value="${value//$'\r'/\\r}"
    value="${value//$'\t'/\\t}"
    
    echo "$value"
}

################################################################################
# DISK SPACE MANAGEMENT
################################################################################

check_disk_space() {
    local log_dir="$1"
    local required_mb="${2:-$MIN_FREE_DISK_MB}"
    
    # Get available space
    local available_mb=$(df -BM "$log_dir" 2>/dev/null | tail -1 | awk '{print $4}' | tr -d 'M')
    
    if [[ -z "$available_mb" ]]; then
        warn "Could not determine disk space for $log_dir"
        return 0
    fi
    
    if [[ $available_mb -lt $required_mb ]]; then
        local usage=$(df -h "$log_dir" | tail -1 | awk '{print $5}')
        
        if [[ "$DISK_CRITICAL_ACTION" == "cleanup" ]]; then
            warn "Low disk space ($usage), running emergency cleanup..."
            emergency_cleanup "$log_dir"
        else
            die "Insufficient disk space: ${available_mb}MB available, ${required_mb}MB required" $EXIT_DISK_SPACE_ERROR
        fi
    fi
    
    # Check usage percentage
    local usage_pct=$(df "$log_dir" 2>/dev/null | tail -1 | awk '{print $5}' | tr -d '%')
    
    if [[ $usage_pct -ge $DISK_CRITICAL_THRESHOLD ]]; then
        warn "Disk usage critical: ${usage_pct}%"
    elif [[ $usage_pct -ge $DISK_WARNING_THRESHOLD ]]; then
        log_internal "WARNING" "Disk usage high: ${usage_pct}%"
    fi
}

emergency_cleanup() {
    local log_dir="$1"
    
    log_internal "WARNING" "Running emergency cleanup on $log_dir"
    
    # Delete DEBUG and INFO level logs first
    find "$log_dir" -type f -name "*DEBUG*.log" -delete 2>/dev/null || true
    find "$log_dir" -type f -name "*INFO*.log" -mtime +1 -delete 2>/dev/null || true
    
    # Compress old uncompressed logs
    find "$log_dir" -type f -name "*.log" -mtime +7 -exec gzip {} \; 2>/dev/null || true
    
    # Delete old archives
    find "$log_dir" -type f -name "*.log.gz" -mtime +30 -delete 2>/dev/null || true
}

################################################################################
# RATE LIMITING
################################################################################

check_rate_limit() {
    local key="${1:-global}"
    local now=$(date +%s)
    local window_start=$((now - RATE_LIMIT_WINDOW))
    
    if [[ "$ENABLE_RATE_LIMIT" != "true" ]]; then
        return 0
    fi
    
    # Clean old entries
    for time_key in "${!RATE_LIMIT_COUNTER[@]}"; do
        if [[ "$time_key" =~ ^${key}_ ]]; then
            local timestamp="${time_key#${key}_}"
            if [[ $timestamp -lt $window_start ]]; then
                unset RATE_LIMIT_COUNTER[$time_key]
            fi
        fi
    done
    
    # Count messages in current window
    local count=0
    for time_key in "${!RATE_LIMIT_COUNTER[@]}"; do
        if [[ "$time_key" =~ ^${key}_ ]]; then
            ((count++))
        fi
    done
    
    if [[ $count -ge $RATE_LIMIT_MAX ]]; then
        case "$RATE_LIMIT_ACTION" in
            drop)
                log_internal "WARNING" "Rate limit exceeded, dropping message"
                return 1
                ;;
            sample)
                # Log every 100th message when rate limited
                if (( count % 100 == 0 )); then
                    log_internal "WARNING" "Rate limiting active (${count} messages)"
                    return 0
                fi
                return 1
                ;;
            block)
                warn "Rate limit exceeded, waiting..."
                sleep 1
                return 0
                ;;
        esac
    fi
    
    RATE_LIMIT_COUNTER["${key}_${now}"]=$now
    return 0
}

################################################################################
# DIRECTORY MANAGEMENT
################################################################################

create_log_structure() {
    local task_name="$1"
    local log_base="${BASE_LOG_DIR}/${task_name}"
    
    local dirs=("${log_base}" "${log_base}/current" "${log_base}/archive")
    
    for dir in "${dirs[@]}"; do
        if [[ ! -d "$dir" ]]; then
            if [[ "$OPT_DRY_RUN" == "true" ]]; then
                echo "[DRY-RUN] Would create directory: $dir"
                continue
            fi
            
            mkdir -p "$dir" || die "Failed to create directory: $dir" $EXIT_PERMISSION_DENIED
            chmod "$LOG_DIR_PERMISSIONS" "$dir" 2>/dev/null || true
            
            # Set ownership
            local owner="${OPT_USER:-$(echo "$DEFAULT_OWNER" | cut -d: -f1)}"
            local group="${OPT_GROUP:-$(echo "$DEFAULT_OWNER" | cut -d: -f2)}"
            
            if [[ -n "$owner" ]] && [[ "$owner" != "$USER" ]]; then
                chown "${owner}:${group}" "$dir" 2>/dev/null || true
            fi
            
            log_internal "INFO" "Created directory: $dir"
        fi
    done
}

################################################################################
# LOG ROTATION
################################################################################

get_file_size_cached() {
    local file="$1"
    local now=$(date +%s)
    local cache_key="${file}_size"
    local cache_time_key="${file}_time"
    
    if [[ "$ENABLE_SIZE_CACHE" != "true" ]]; then
        stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null || echo 0
        return
    fi
    
    if [[ -n "${SIZE_CACHE[$cache_time_key]}" ]]; then
        local age=$((now - SIZE_CACHE[$cache_time_key]))
        if [[ $age -lt $SIZE_CACHE_TIMEOUT ]]; then
            echo "${SIZE_CACHE[$cache_key]}"
            return
        fi
    fi
    
    local size=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null || echo 0)
    SIZE_CACHE[$cache_key]=$size
    SIZE_CACHE[$cache_time_key]=$now
    echo "$size"
}

check_rotation_needed() {
    local logfile="$1"
    
    [[ ! -f "$logfile" ]] && return 1
    [[ "$OPT_NO_ROTATION" == "true" ]] && return 1
    
    local size_bytes=$(get_file_size_cached "$logfile")
    local size_mb=$((size_bytes / 1024 / 1024))
    
    [[ $size_mb -ge $MAX_LOG_SIZE_MB ]] && return 0
    return 1
}

rotate_log_file() {
    local logfile="$1"
    local task_name="$2"
    local log_base="${BASE_LOG_DIR}/${task_name}"
    local archive_dir="${log_base}/archive"
    local lock_file="${logfile}.lock"
    
    [[ ! -f "$logfile" ]] && return 0
    
    if [[ "$OPT_DRY_RUN" == "true" ]]; then
        echo "[DRY-RUN] Would rotate: $logfile"
        return 0
    fi
    
    # Acquire lock
    exec 200>"$lock_file"
    flock -x 200 || {
        warn "Failed to acquire lock for rotation"
        return 1
    }
    
    local timestamp=$(date '+%Y%m%d_%H%M%S')
    local base_name=$(basename "$logfile" .log)
    local archive_name="${base_name}_${timestamp}.log"
    
    log_internal "INFO" "Rotating log: $logfile"
    
    # Move to archive
    mv "$logfile" "${archive_dir}/${archive_name}"
    
    # Compress
    if [[ "$ENABLE_COMPRESSION" == "true" ]] && [[ "$OPT_NO_COMPRESSION" != "true" ]]; then
        if [[ "$ASYNC_COMPRESSION" == "true" ]]; then
            (gzip "${archive_dir}/${archive_name}" 2>/dev/null && \
             log_internal "INFO" "Compressed: ${archive_name}.gz") &
        else
            gzip "${archive_dir}/${archive_name}"
            log_internal "INFO" "Compressed: ${archive_name}.gz"
        fi
        ((METRICS[compressions]++))
    fi
    
    # Release lock
    flock -u 200
    rm -f "$lock_file"
    
    ((METRICS[rotations]++))
    return 0
}

################################################################################
# LOG CLEANUP
################################################################################

cleanup_old_archives() {
    local task_name="$1"
    local archive_dir="${BASE_LOG_DIR}/${task_name}/archive"
    
    [[ ! -d "$archive_dir" ]] && return 0
    
    if [[ "$OPT_DRY_RUN" == "true" ]]; then
        echo "[DRY-RUN] Would cleanup archives in: $archive_dir"
        local old_gz=$(find "$archive_dir" -type f -name "*.log.gz" -mtime +${ARCHIVE_RETENTION_DAYS} 2>/dev/null | wc -l)
        local old_log=$(find "$archive_dir" -type f -name "*.log" -mtime +${LOG_RETENTION_DAYS} 2>/dev/null | wc -l)
        echo "[DRY-RUN] Would delete: ${old_gz} compressed, ${old_log} uncompressed"
        return 0
    fi
    
    log_internal "INFO" "Cleaning up old archives for: $task_name"
    
    # Delete old compressed archives
    find "$archive_dir" -type f -name "*.log.gz" -mtime +${ARCHIVE_RETENTION_DAYS} -delete 2>/dev/null || true
    
    # Delete old uncompressed logs
    find "$archive_dir" -type f -name "*.log" -mtime +${LOG_RETENTION_DAYS} -delete 2>/dev/null || true
    
    # Clean up empty directories
    find "$archive_dir" -type d -empty -delete 2>/dev/null || true
}

force_cleanup() {
    local task_pattern="${1:-*}"
    
    echo "Running cleanup for: $task_pattern"
    
    for task_dir in ${BASE_LOG_DIR}/${task_pattern}; do
        if [[ -d "$task_dir" ]]; then
            local task_name=$(basename "$task_dir")
            echo "  Cleaning: $task_name"
            cleanup_old_archives "$task_name"
        fi
    done
    
    echo "Cleanup complete"
}

force_rotation() {
    local task_pattern="${1:-*}"
    
    echo "Forcing rotation for: $task_pattern"
    
    for task_dir in ${BASE_LOG_DIR}/${task_pattern}; do
        if [[ -d "$task_dir/current" ]]; then
            local task_name=$(basename "$task_dir")
            echo "  Rotating: $task_name"
            
            for logfile in "$task_dir/current"/*.log; do
                [[ -f "$logfile" ]] && rotate_log_file "$logfile" "$task_name"
            done
        fi
    done
    
    echo "Rotation complete"
}

force_compression() {
    local task_pattern="${1:-*}"
    
    echo "Forcing compression for: $task_pattern"
    
    for task_dir in ${BASE_LOG_DIR}/${task_pattern}/archive; do
        if [[ -d "$task_dir" ]]; then
            echo "  Compressing: $task_dir"
            find "$task_dir" -type f -name "*.log" ! -name "*.gz" -exec gzip {} \; 2>/dev/null || true
        fi
    done
    
    echo "Compression complete"
}

################################################################################
# LOG FORMATTING
################################################################################

format_plain_log() {
    local timestamp="$1"
    local hostname="$2"
    local script="$3"
    local level="$4"
    local message="$5"
    local pid="$6"
    local user="$7"
    
    echo "${timestamp} [${hostname}] [${script}] [PID:${pid}] [${user}] [${level}] ${message}"
}

format_json_log() {
    local timestamp="$1"
    local hostname="$2"
    local script="$3"
    local level="$4"
    local message="$5"
    local pid="$6"
    local user="$7"
    shift 7
    
    # Escape message for JSON
    message=$(sanitize_metadata_value "$message")
    
    local json="{\"timestamp\":\"${timestamp}\""
    json+=",\"hostname\":\"${hostname}\""
    json+=",\"script\":\"${script}\""
    json+=",\"level\":\"${level}\""
    json+=",\"message\":\"${message}\""
    json+=",\"pid\":${pid}"
    json+=",\"user\":\"${user}\""
    json+=",\"version\":\"${SCRIPT_VERSION}\""
    
    # Add metadata
    if [[ ${#OPT_METADATA[@]} -gt 0 ]]; then
        json+=",\"metadata\":{"
        local first=true
        for key in "${!OPT_METADATA[@]}"; do
            [[ "$first" != "true" ]] && json+=","
            local value=$(sanitize_metadata_value "${OPT_METADATA[$key]}")
            json+="\"${key}\":\"${value}\""
            first=false
        done
        json+="}"
    fi
    
    json+="}"
    echo "$json"
}

format_console_log() {
    local timestamp="$1"
    local level="$2"
    local message="$3"
    local script="$4"
    
    local color="${LOG_LEVEL_COLORS[$level]}"
    echo -e "${color}[${level}]${COLOR_RESET} ${timestamp} [${script}] ${message}"
}

################################################################################
# OUTPUT FUNCTIONS
################################################################################

write_to_file() {
    local logfile="$1"
    local content="$2"
    
    if [[ "$OPT_DRY_RUN" == "true" ]]; then
        echo "[DRY-RUN] Would write to: $logfile"
        echo "[DRY-RUN] Content: $content"
        return 0
    fi
    
    echo "$content" >> "$logfile" || {
        warn "Failed to write to log file: $logfile"
        return 1
    }
    
    # Set permissions
    chmod "$LOG_FILE_PERMISSIONS" "$logfile" 2>/dev/null || true
    
    ((METRICS[total_logs]++))
}

send_to_syslog() {
    local level="$1"
    local message="$2"
    local script="$3"
    
    [[ "$ENABLE_SYSLOG" != "true" ]] && [[ "$OPT_SYSLOG" != "true" ]] && return 0
    
    local syslog_priority
    case "$level" in
        DEBUG)    syslog_priority="debug" ;;
        INFO)     syslog_priority="info" ;;
        NOTICE)   syslog_priority="notice" ;;
        WARNING)  syslog_priority="warning" ;;
        ERROR)    syslog_priority="err" ;;
        CRITICAL) syslog_priority="crit" ;;
        FATAL)    syslog_priority="alert" ;;
        *)        syslog_priority="info" ;;
    esac
    
    if [[ "$OPT_DRY_RUN" == "true" ]]; then
        echo "[DRY-RUN] Would send to syslog: priority=${syslog_priority}, tag=${script}"
        return 0
    fi
    
    if [[ -n "$SYSLOG_SERVER" ]]; then
        logger -t "$script" -p "${SYSLOG_FACILITY}.${syslog_priority}" -n "$SYSLOG_SERVER" "$message" 2>/dev/null || true
    else
        logger -t "$script" -p "${SYSLOG_FACILITY}.${syslog_priority}" "$message" 2>/dev/null || true
    fi
}

send_email_alert() {
    local level="$1"
    local message="$2"
    local script="$3"
    local hostname="$4"
    local logfile="$5"
    
    [[ "$ENABLE_EMAIL_ALERTS" != "true" ]] && [[ "$OPT_EMAIL" != "true" ]] && return 0
    [[ -z "$ALERT_EMAIL" ]] && return 0
    
    # Check if level requires alerting
    [[ ! "$ALERT_LEVELS" =~ $level ]] && [[ "$OPT_EMAIL" != "true" ]] && return 0
    
    local subject="${EMAIL_SUBJECT_PREFIX} [${level}] ${hostname}: ${script}"
    local body="Alert Details:

Level:     ${level}
Script:    ${script}
Hostname:  ${hostname}
Time:      $(date)
Message:   ${message}

Recent log entries:
$(tail -20 "$logfile" 2>/dev/null || echo "No log file available")

--
Enhanced Log Collector v${SCRIPT_VERSION}
"
    
    if [[ "$OPT_DRY_RUN" == "true" ]]; then
        echo "[DRY-RUN] Would send email to: $ALERT_EMAIL"
        echo "[DRY-RUN] Subject: $subject"
        return 0
    fi
    
    echo "$body" | mail -s "$subject" "$ALERT_EMAIL" 2>/dev/null || {
        warn "Failed to send email alert"
        return 1
    }
    
    log_internal "INFO" "Email alert sent to: $ALERT_EMAIL"
}

################################################################################
# STACK TRACE
################################################################################

get_stack_trace() {
    local frame=0
    local output="Stack Trace:\n"
    
    while caller $frame 2>/dev/null; do
        ((frame++))
    done | while read line func file; do
        output+="  at ${func} (${file}:${line})\n"
    done
    
    echo -e "$output"
}

################################################################################
# HEALTH CHECK & METRICS
################################################################################

update_health_check() {
    [[ "$ENABLE_HEALTH_CHECK" != "true" ]] && return 0
    
    local health_dir=$(dirname "$HEALTH_CHECK_FILE")
    [[ ! -d "$health_dir" ]] && mkdir -p "$health_dir" 2>/dev/null
    
    date +%s > "$HEALTH_CHECK_FILE" 2>/dev/null || true
}

update_metrics() {
    [[ "$ENABLE_METRICS" != "true" ]] && return 0
    
    local metrics_dir=$(dirname "$METRICS_FILE")
    [[ ! -d "$metrics_dir" ]] && mkdir -p "$metrics_dir" 2>/dev/null
    
    {
        echo "# Log Collector Metrics"
        echo "timestamp $(date +%s)"
        echo "total_logs ${METRICS[total_logs]}"
        echo "errors ${METRICS[errors]}"
        echo "rotations ${METRICS[rotations]}"
        echo "compressions ${METRICS[compressions]}"
    } > "$METRICS_FILE" 2>/dev/null || true
}

################################################################################
# MAIN LOGGING FUNCTION
################################################################################

collect_log() {
    local task_name="$1"
    local script="$2"
    local level="$3"
    local message="$4"
    
    # Validate and sanitize
    validate_log_level "$level"
    task_name=$(sanitize_task_name "$task_name")
    message=$(sanitize_message "$message")
    
    # Check rate limit
    check_rate_limit "$task_name" || return $EXIT_RATE_LIMIT
    
    # Create directory structure
    create_log_structure "$task_name"
    
    # Check disk space
    check_disk_space "${BASE_LOG_DIR}/${task_name}"
    
    # Gather metadata
    local timestamp=$(date '+%Y-%m-%dT%H:%M:%S%z')
    local hostname=$(hostname -f 2>/dev/null || hostname)
    local pid=$$
    local user=${USER:-$(whoami)}
    local log_base="${BASE_LOG_DIR}/${task_name}"
    local logfile="${log_base}/current/${script}_$(date '+%Y-%m-%d').log"
    
    # Add stack trace if requested
    if [[ "$OPT_STACKTRACE" == "true" ]]; then
        message="${message}\n$(get_stack_trace)"
    fi
    
    # Check rotation
    if check_rotation_needed "$logfile"; then
        rotate_log_file "$logfile" "$task_name"
    fi
    
    # Format log entry
    local log_entry
    if [[ "$OPT_JSON" == "true" ]] || [[ "$ENABLE_JSON_FORMAT" == "true" ]]; then
        log_entry=$(format_json_log "$timestamp" "$hostname" "$script" "$level" "$message" "$pid" "$user")
    else
        log_entry=$(format_plain_log "$timestamp" "$hostname" "$script" "$level" "$message" "$pid" "$user")
    fi
    
    # Write to file
    write_to_file "$logfile" "$log_entry"
    
    # Console output
    if [[ "$OPT_CONSOLE" == "true" ]] || [[ "$ENABLE_CONSOLE_OUTPUT" == "true" ]]; then
        format_console_log "$timestamp" "$level" "$message" "$script"
    fi
    
    # Syslog
    if [[ "$OPT_SYSLOG" == "true" ]] || [[ "$ENABLE_SYSLOG" == "true" ]]; then
        send_to_syslog "$level" "$message" "$script"
    fi
    
    # Email
    if [[ "$OPT_EMAIL" == "true" ]] || [[ "$ENABLE_EMAIL_ALERTS" == "true" ]]; then
        send_email_alert "$level" "$message" "$script" "$hostname" "$logfile"
    fi
    
    # Periodic cleanup
    if (( RANDOM % (100 / CLEANUP_CHECK_PROBABILITY) == 0 )); then
        cleanup_old_archives "$task_name" &
    fi
    
    # Update health and metrics
    update_health_check
    update_metrics
    
    return 0
}

################################################################################
# COMMAND LINE PARSING
################################################################################

parse_arguments() {
    local positional_args=()
    
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                show_help
                exit 0
                ;;
            -v|--version)
                show_version
                exit 0
                ;;
            -V|--verbose)
                OPT_VERBOSE=true
                shift
                ;;
            -q|--quiet)
                OPT_QUIET=true
                shift
                ;;
            -n|--dry-run)
                OPT_DRY_RUN=true
                shift
                ;;
            -c|--config)
                OPT_CONFIG_FILE="$2"
                shift 2
                ;;
            --show-config)
                OPT_SHOW_CONFIG=true
                shift
                ;;
            --validate)
                OPT_VALIDATE=true
                shift
                ;;
            --console)
                OPT_CONSOLE=true
                shift
                ;;
            --json)
                OPT_JSON=true
                shift
                ;;
            --syslog)
                OPT_SYSLOG=true
                shift
                ;;
            --email)
                OPT_EMAIL=true
                shift
                ;;
            --stacktrace)
                OPT_STACKTRACE=true
                shift
                ;;
            --no-rotation)
                OPT_NO_ROTATION=true
                shift
                ;;
            --no-compression)
                OPT_NO_COMPRESSION=true
                shift
                ;;
            -f|--force)
                OPT_FORCE=true
                shift
                ;;
            -u|--user)
                OPT_USER="$2"
                shift 2
                ;;
            -g|--group)
                OPT_GROUP="$2"
                shift 2
                ;;
            -m|--metadata)
                if [[ "$2" =~ ^([^=]+)=(.+)$ ]]; then
                    OPT_METADATA["${BASH_REMATCH[1]}"]="${BASH_REMATCH[2]}"
                fi
                shift 2
                ;;
            --debug)
                DEBUG_MODE=true
                OPT_VERBOSE=true
                shift
                ;;
            --cleanup)
                OPT_CLEANUP=true
                positional_args+=("${2:-}")
                shift
                [[ -n "${2:-}" ]] && shift
                ;;
            --rotate)
                force_rotation "${2:-*}"
                exit 0
                ;;
            --compress)
                force_compression "${2:-*}"
                exit 0
                ;;
            -*)
                warn "Unknown option: $1"
                shift
                ;;
            *)
                positional_args+=("$1")
                shift
                ;;
        esac
    done
    
    # Return positional arguments
    set -- "${positional_args[@]}"
    echo "$@"
}

################################################################################
# MAIN FUNCTION
################################################################################

main() {
    # Parse command line
    local args=$(parse_arguments "$@")
    eval set -- "$args"
    
    # Load configuration
    load_configuration
    
    # Show config if requested
    if [[ "$OPT_SHOW_CONFIG" == "true" ]]; then
        show_configuration
        exit 0
    fi
    
    # Validate configuration
    validate_configuration
    
    # Handle maintenance operations
    if [[ "$OPT_CLEANUP" == "true" ]]; then
        force_cleanup "${1:-*}"
        exit 0
    fi
    
    # Check for required arguments
    if [[ $# -lt 4 ]]; then
        show_quick_help
        exit $EXIT_INVALID_ARGS
    fi
    
    # Extract arguments
    local task_name="$1"
    local script="$2"
    local level="$3"
    local message="$4"
    
    # Perform logging
    collect_log "$task_name" "$script" "$level" "$message"
    exit $?
}

################################################################################
# SCRIPT EXECUTION
################################################################################

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
