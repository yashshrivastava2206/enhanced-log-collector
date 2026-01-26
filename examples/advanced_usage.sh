#!/bin/bash
################################################################################
# Advanced Usage Examples
################################################################################

LOG="/opt/scripts/logCollector.sh"

echo "=== Advanced Usage Examples ==="
echo ""

# Example 1: JSON format with metadata
echo "1. JSON format with custom metadata:"
$LOG 'examples' 'advanced_usage.sh' 'INFO' 'Backup completed' \
    --json \
    --metadata database=production \
    --metadata size=50GB \
    --metadata duration=300s \
    --metadata compression_ratio=0.85

# Example 2: Multiple outputs
echo ""
echo "2. Sending to multiple destinations:"
$LOG 'examples' 'advanced_usage.sh' 'WARNING' 'High memory usage detected' \
    --console \
    --syslog \
    --json

# Example 3: Critical alert with email
echo ""
echo "3. Critical alert (would send email if configured):"
$LOG 'examples' 'advanced_usage.sh' 'CRITICAL' 'Database connection pool exhausted' \
    --email \
    --console \
    --metadata current_connections=100 \
    --metadata max_connections=100

# Example 4: Error with stack trace
echo ""
echo "4. Error with stack trace for debugging:"
$LOG 'examples' 'advanced_usage.sh' 'ERROR' 'Unexpected error in process_data()' \
    --stacktrace \
    --console

# Example 5: Function wrapper
log_wrapper() {
    local level=$1
    local message=$2
    shift 2
    $LOG 'examples' "$(basename $0)" "$level" "$message" --console "$@"
}

echo ""
echo "5. Using a wrapper function:"
log_wrapper 'INFO' 'Starting data processing pipeline'
log_wrapper 'INFO' 'Processing batch 1 of 10'
log_wrapper 'WARNING' 'Slow query detected' --metadata query_time=5.2s
log_wrapper 'INFO' 'Pipeline completed successfully'

echo ""
echo "Check logs at: /var/log/examples/current/advanced_usage.sh_$(date +%Y-%m-%d).log"
