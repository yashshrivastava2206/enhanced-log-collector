#!/usr/bin/env bash
################################################################################
# Enhanced Log Collector v2.0
# Author: Yash Shrivastava
# Copyright: © 2026 Yash Shrivastava
# Description: Enterprise-grade logging system with rotation, compression,
#              retention policies, and multiple output formats
################################################################################

################################################################################
# CONFIGURATION SECTION
################################################################################
SCRIPT_VERSION="2.0"
CONFIG_FILE="/etc/logCollector.conf"
BASE_LOG_DIR="/var/log"
DEFAULT_OWNER="postgres:postgres"
MAX_LOG_SIZE_MB=100
LOG_RETENTION_DAYS=30
ARCHIVE_RETENTION_DAYS=90
ENABLE_COMPRESSION=true
ENABLE_JSON_FORMAT=false
ENABLE_CONSOLE_OUTPUT=false
ENABLE_SYSLOG=false
ENABLE_EMAIL_ALERTS=false
ALERT_EMAIL=""
ALERT_LEVELS="FATAL,CRITICAL"

# Log level definitions with numeric values for comparison
declare -A LOG_LEVELS=(
    ["DEBUG"]=0
    ["INFO"]=1
    ["NOTICE"]=2
    ["WARNING"]=3
    ["ERROR"]=4
    ["CRITICAL"]=5
    ["FATAL"]=6
)

# ANSI color codes for console output
declare -A LOG_COLORS=(
    ["DEBUG"]="\033[0;36m"      # Cyan
    ["INFO"]="\033[0;32m"       # Green
    ["NOTICE"]="\033[0;34m"     # Blue
    ["WARNING"]="\033[0;33m"    # Yellow
    ["ERROR"]="\033[0;31m"      # Red
    ["CRITICAL"]="\033[1;31m"   # Bold Red
    ["FATAL"]="\033[1;35m"      # Bold Magenta
    ["RESET"]="\033[0m"         # Reset
)

################################################################################
# LOAD CONFIGURATION FILE
################################################################################
load_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        source "$CONFIG_FILE"
    fi
}

################################################################################
# UTILITY FUNCTIONS
################################################################################

# Print usage information
print_usage() {
    cat << EOF
╔════════════════════════════════════════════════════════════════════════════╗
║                    Enhanced Log Collector v${SCRIPT_VERSION}               ║
╚════════════════════════════════════════════════════════════════════════════╝

USAGE:
    $0 [TaskName] [ScriptFileName] [LogLevel] [Message] [Options]

REQUIRED ARGUMENTS:
    TaskName        : Task name or log directory identifier
    ScriptFileName  : Name of the calling script (use \$0)
    LogLevel        : Log severity level
    Message         : Log message content

SUPPORTED LOG LEVELS (in order of severity):
    DEBUG           : Detailed debugging information
    INFO            : General informational messages
    NOTICE          : Normal but significant events
    WARNING         : Warning messages
    ERROR           : Error messages
    CRITICAL        : Critical conditions
    FATAL           : Fatal errors causing termination

OPTIONAL FLAGS:
    --json          : Output in JSON format
    --console       : Display on console with colors
    --syslog        : Send to syslog
    --email         : Send email alert (for CRITICAL/FATAL)
    --stacktrace    : Include stack trace (for errors)
    --metadata KEY=VALUE : Add custom metadata

EXAMPLES:
    # Basic usage
    $0 'backup' 'backup.sh' 'INFO' 'Backup started'
    
    # With console output
    $0 'backup' 'backup.sh' 'ERROR' 'Backup failed' --console
    
    # With JSON format and metadata
    $0 'backup' 'backup.sh' 'INFO' 'Backup completed' --json --metadata size=10GB
    
    # With email alert for critical error
    $0 'backup' 'backup.sh' 'FATAL' 'System crash' --email --stacktrace

CONFIGURATION FILE: ${CONFIG_FILE}

LOG DIRECTORY STRUCTURE:
    ${BASE_LOG_DIR}/[TaskName]/
    ├── current/                 # Active log files
    ├── archive/                 # Compressed archives
    └── metadata.json            # Log metadata

For more information, see: /opt/scripts/README.md

EOF
}

# Validate log level
validate_log_level() {
    local level=$1
    if [[ ! -v LOG_LEVELS[$level] ]]; then
        echo "ERROR: Invalid log level '$level'" >&2
        echo "Valid levels: ${!LOG_LEVELS[@]}" >&2
        return 1
    fi
    return 0
}

# Get current timestamp in ISO 8601 format
get_timestamp() {
    date '+%Y-%m-%dT%H:%M:%S%z'
}

# Get hostname
get_hostname() {
    hostname -f 2>/dev/null || hostname
}

# Get caller information
get_caller_info() {
    local caller_line="${BASH_LINENO[2]}"
    local caller_func="${FUNCNAME[3]}"
    echo "${caller_func}:${caller_line}"
}

################################################################################
# DIRECTORY MANAGEMENT
################################################################################

# Create log directory structure
create_log_structure() {
    local task_name=$1
    local log_base="${BASE_LOG_DIR}/${task_name}"
    
    # Create directories
    local dirs=("${log_base}" "${log_base}/current" "${log_base}/archive")
    
    for dir in "${dirs[@]}"; do
        if [[ ! -d "$dir" ]]; then
            mkdir -p "$dir" || {
                echo "ERROR: Failed to create directory: $dir" >&2
                return 1
            }
            
            # Set ownership
            if [[ -n "$DEFAULT_OWNER" ]]; then
                chown -R "$DEFAULT_OWNER" "$dir" 2>/dev/null || true
            fi
            
            # Set permissions
            chmod 755 "$dir"
        fi
    done
    
    return 0
}

################################################################################
# LOG ROTATION AND COMPRESSION
################################################################################

# Check if log rotation is needed (size-based)
check_rotation_needed() {
    local logfile=$1
    
    if [[ ! -f "$logfile" ]]; then
        return 1
    fi
    
    local size_bytes=$(stat -f%z "$logfile" 2>/dev/null || stat -c%s "$logfile" 2>/dev/null)
    local size_mb=$((size_bytes / 1024 / 1024))
    
    if [[ $size_mb -ge $MAX_LOG_SIZE_MB ]]; then
        return 0
    fi
    
    return 1
}

# Rotate log file
rotate_log() {
    local logfile=$1
    local task_name=$2
    local log_base="${BASE_LOG_DIR}/${task_name}"
    local archive_dir="${log_base}/archive"
    
    if [[ ! -f "$logfile" ]]; then
        return 0
    fi
    
    # Generate archive filename
    local timestamp=$(date '+%Y%m%d_%H%M%S')
    local base_name=$(basename "$logfile" .log)
    local archive_name="${base_name}_${timestamp}.log"
    
    # Move to archive directory
    mv "$logfile" "${archive_dir}/${archive_name}"
    
    # Compress if enabled
    if [[ "$ENABLE_COMPRESSION" == "true" ]]; then
        gzip "${archive_dir}/${archive_name}" &
    fi
    
    return 0
}

# Clean old archives based on retention policy
cleanup_old_archives() {
    local task_name=$1
    local archive_dir="${BASE_LOG_DIR}/${task_name}/archive"
    
    if [[ ! -d "$archive_dir" ]]; then
        return 0
    fi
    
    # Delete archives older than retention period
    find "$archive_dir" -type f -name "*.log.gz" -mtime +${ARCHIVE_RETENTION_DAYS} -delete 2>/dev/null || true
    find "$archive_dir" -type f -name "*.log" -mtime +${LOG_RETENTION_DAYS} -delete 2>/dev/null || true
}

################################################################################
# LOG FORMATTING
################################################################################

# Format log message as plain text
format_plain_log() {
    local timestamp=$1
    local hostname=$2
    local script=$3
    local level=$4
    local message=$5
    local pid=$6
    local user=$7
    
    echo "${timestamp} [${hostname}] [${script}] [PID:${pid}] [${user}] [${level}] ${message}"
}

# Format log message as JSON
format_json_log() {
    local timestamp=$1
    local hostname=$2
    local script=$3
    local level=$4
    local message=$5
    local pid=$6
    local user=$7
    shift 7
    local metadata="$@"
    
    cat << EOF
{
  "timestamp": "${timestamp}",
  "hostname": "${hostname}",
  "script": "${script}",
  "level": "${level}",
  "message": "${message}",
  "pid": ${pid},
  "user": "${user}",
  "version": "${SCRIPT_VERSION}"$([ -n "$metadata" ] && echo ",
  \"metadata\": {${metadata}}")
}
EOF
}

# Format log message for console with colors
format_console_log() {
    local timestamp=$1
    local level=$2
    local message=$3
    local script=$4
    
    local color="${LOG_COLORS[$level]}"
    local reset="${LOG_COLORS[RESET]}"
    
    echo -e "${color}[${level}]${reset} ${timestamp} [${script}] ${message}"
}

################################################################################
# LOG OUTPUT FUNCTIONS
################################################################################

# Write to log file
write_to_file() {
    local logfile=$1
    local content=$2
    
    echo "$content" >> "$logfile"
}

# Send to syslog
send_to_syslog() {
    local level=$1
    local message=$2
    local script=$3
    
    # Map custom levels to syslog priorities
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
    
    logger -t "$script" -p "user.${syslog_priority}" "$message"
}

# Send email alert
send_email_alert() {
    local level=$1
    local message=$2
    local script=$3
    local hostname=$4
    local logfile=$5
    
    if [[ -z "$ALERT_EMAIL" ]]; then
        return 0
    fi
    
    # Check if this level requires alerting
    if [[ ! "$ALERT_LEVELS" =~ $level ]]; then
        return 0
    fi
    
    local subject="[${level}] Alert from ${hostname}: ${script}"
    local body="Alert Details:
    
Level: ${level}
Script: ${script}
Hostname: ${hostname}
Time: $(date)
Message: ${message}

Recent log entries:
$(tail -20 "$logfile" 2>/dev/null || echo "No log file available")
"
    
    echo "$body" | mail -s "$subject" "$ALERT_EMAIL" 2>/dev/null || true
}

################################################################################
# STACK TRACE FUNCTION
################################################################################

get_stack_trace() {
    local frame=0
    echo "Stack Trace:"
    while caller $frame; do
        ((frame++))
    done
}

################################################################################
# MAIN LOGGING FUNCTION
################################################################################

collect_log() {
    local task_name=$1
    local script=$2
    local level=$3
    local message=$4
    shift 4
    
    # Validate log level
    validate_log_level "$level" || return 1
    
    # Create log directory structure
    create_log_structure "$task_name" || return 1
    
    # Gather metadata
    local timestamp=$(get_timestamp)
    local hostname=$(get_hostname)
    local pid=$$
    local user=${USER:-$(whoami)}
    local log_base="${BASE_LOG_DIR}/${task_name}"
    local logfile="${log_base}/current/${script}_$(date '+%Y-%m-%d').log"
    
    # Parse optional flags
    local use_json=$ENABLE_JSON_FORMAT
    local use_console=$ENABLE_CONSOLE_OUTPUT
    local use_syslog=$ENABLE_SYSLOG
    local use_email=$ENABLE_EMAIL_ALERTS
    local include_stacktrace=false
    local custom_metadata=""
    
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --json)
                use_json=true
                shift
                ;;
            --console)
                use_console=true
                shift
                ;;
            --syslog)
                use_syslog=true
                shift
                ;;
            --email)
                use_email=true
                shift
                ;;
            --stacktrace)
                include_stacktrace=true
                shift
                ;;
            --metadata)
                if [[ -n "$2" && "$2" != --* ]]; then
                    custom_metadata="${custom_metadata}\"${2%%=*}\": \"${2#*=}\", "
                    shift 2
                else
                    shift
                fi
                ;;
            *)
                shift
                ;;
        esac
    done
    
    # Remove trailing comma from metadata
    custom_metadata="${custom_metadata%, }"
    
    # Add stack trace to message if requested
    if [[ "$include_stacktrace" == "true" ]]; then
        message="${message}\n$(get_stack_trace)"
    fi
    
    # Check if rotation is needed
    if check_rotation_needed "$logfile"; then
        rotate_log "$logfile" "$task_name"
    fi
    
    # Format and write log
    if [[ "$use_json" == "true" ]]; then
        local log_entry=$(format_json_log "$timestamp" "$hostname" "$script" "$level" "$message" "$pid" "$user" "$custom_metadata")
    else
        local log_entry=$(format_plain_log "$timestamp" "$hostname" "$script" "$level" "$message" "$pid" "$user")
    fi
    
    write_to_file "$logfile" "$log_entry"
    
    # Console output
    if [[ "$use_console" == "true" ]]; then
        format_console_log "$timestamp" "$level" "$message" "$script"
    fi
    
    # Syslog output
    if [[ "$use_syslog" == "true" ]]; then
        send_to_syslog "$level" "$message" "$script"
    fi
    
    # Email alerts
    if [[ "$use_email" == "true" ]]; then
        send_email_alert "$level" "$message" "$script" "$hostname" "$logfile"
    fi
    
    # Cleanup old archives (run occasionally)
    if (( RANDOM % 100 == 0 )); then
        cleanup_old_archives "$task_name" &
    fi
    
    return 0
}

################################################################################
# COMMAND LINE INTERFACE
################################################################################

main() {
    # Load configuration
    load_config
    
    # Check minimum arguments
    if [[ $# -lt 4 ]]; then
        print_usage
        exit 1
    fi
    
    # Parse required arguments
    local task_name=$1
    local script=$2
    local level=$3
    local message=$4
    shift 4
    
    # Call logging function with remaining arguments
    collect_log "$task_name" "$script" "$level" "$message" "$@"
    
    exit $?
}

################################################################################
# SCRIPT EXECUTION
################################################################################

# Only run main if script is executed directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
