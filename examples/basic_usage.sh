#!/bin/bash
################################################################################
# Basic Usage Examples
################################################################################

LOG="/opt/scripts/logCollector.sh"

echo "=== Basic Usage Examples ==="
echo ""

# Example 1: Simple log message
echo "1. Simple INFO message:"
$LOG 'examples' 'basic_usage.sh' 'INFO' 'Application started successfully'

# Example 2: Different log levels
echo ""
echo "2. Different log levels:"
$LOG 'examples' 'basic_usage.sh' 'DEBUG' 'Debug information for troubleshooting'
$LOG 'examples' 'basic_usage.sh' 'INFO' 'General information message'
$LOG 'examples' 'basic_usage.sh' 'WARNING' 'Warning: disk usage at 85%'
$LOG 'examples' 'basic_usage.sh' 'ERROR' 'Error connecting to database'

# Example 3: With console output
echo ""
echo "3. With console output (colored):"
$LOG 'examples' 'basic_usage.sh' 'INFO' 'This appears in both file and console' --console

# Example 4: Variable in message
echo ""
echo "4. Using variables in messages:"
DATABASE="production"
RECORDS=1000
$LOG 'examples' 'basic_usage.sh' 'INFO' "Processed ${RECORDS} records from ${DATABASE} database"

# Example 5: Multiline message
echo ""
echo "5. Multiline message:"
ERROR_MSG="Failed to connect to database
Reason: Connection timeout
Host: db.example.com
Port: 5432"
$LOG 'examples' 'basic_usage.sh' 'ERROR' "$ERROR_MSG"

echo ""
echo "Check logs at: /var/log/examples/current/basic_usage.sh_$(date +%Y-%m-%d).log"
