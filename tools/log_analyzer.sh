#!/bin/bash
################################################################################
# Log Analyzer Tool
################################################################################

LOG_DIR="/var/log"
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║              Log Analyzer                                  ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Function to analyze a log directory
analyze_task() {
    local task_dir=$1
    local task_name=$(basename "$task_dir")
    
    echo -e "${YELLOW}Task: ${task_name}${NC}"
    
    # Count current logs
    local current_count=$(find "${task_dir}/current" -name "*.log" 2>/dev/null | wc -l)
    local current_size=$(du -sh "${task_dir}/current" 2>/dev/null | cut -f1)
    
    # Count archives
    local archive_count=$(find "${task_dir}/archive" -name "*.log*" 2>/dev/null | wc -l)
    local archive_size=$(du -sh "${task_dir}/archive" 2>/dev/null | cut -f1)
    
    echo "  Current Logs:  ${current_count} files (${current_size})"
    echo "  Archived Logs: ${archive_count} files (${archive_size})"
    
    # Get latest log file
    local latest_log=$(find "${task_dir}/current" -name "*.log" -type f 2>/dev/null | sort | tail -1)
    
    if [[ -f "$latest_log" ]]; then
        echo "  Latest Log: $(basename "$latest_log")"
        
        # Count log levels
        echo "  Log Level Distribution:"
        for level in DEBUG INFO NOTICE WARNING ERROR CRITICAL FATAL; do
            local count=$(grep -c "\[$level\]" "$latest_log" 2>/dev/null || echo 0)
            if [[ $count -gt 0 ]]; then
                echo "    $level: $count"
            fi
        done
        
        # Last 3 entries
        echo "  Last 3 Entries:"
        tail -3 "$latest_log" 2>/dev/null | while read line; do
            echo "    ${line:0:100}..."
        done
    fi
    
    echo ""
}

# Analyze all tasks
echo -e "${YELLOW}Analyzing all log tasks...${NC}"
echo ""

for task_dir in "${LOG_DIR}"/*; do
    if [[ -d "$task_dir/current" ]] && [[ -d "$task_dir/archive" ]]; then
        analyze_task "$task_dir"
    fi
done

# Summary
echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║              Summary                                       ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo "Total Tasks: $(find "$LOG_DIR" -maxdepth 1 -type d -exec sh -c 'test -d "$1/current"' _ {} \; -print | wc -l)"
echo "Total Disk Usage: $(du -sh "$LOG_DIR" 2>/dev/null | cut -f1)"
echo ""
