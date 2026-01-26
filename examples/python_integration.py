#!/usr/bin/env python3
"""
Python Integration Example for Enhanced Log Collector
"""

import subprocess
import sys
import json
from datetime import datetime

class LogCollector:
    """Wrapper class for logCollector.sh"""
    
    def __init__(self, task_name, script_name="/opt/scripts/logCollector.sh"):
        self.task_name = task_name
        self.script_name = script_name
        self.log_script = script_name
    
    def log(self, level, message, **kwargs):
        """
        Log a message
        
        Args:
            level: Log level (DEBUG, INFO, NOTICE, WARNING, ERROR, CRITICAL, FATAL)
            message: Log message
            **kwargs: Additional options (console=True, json=True, email=True, metadata={})
        """
        cmd = [
            self.log_script,
            self.task_name,
            sys.argv[0],
            level,
            message
        ]
        
        # Add optional flags
        if kwargs.get('console'):
            cmd.append('--console')
        if kwargs.get('json'):
            cmd.append('--json')
        if kwargs.get('syslog'):
            cmd.append('--syslog')
        if kwargs.get('email'):
            cmd.append('--email')
        if kwargs.get('stacktrace'):
            cmd.append('--stacktrace')
        
        # Add metadata
        metadata = kwargs.get('metadata', {})
        for key, value in metadata.items():
            cmd.extend(['--metadata', f'{key}={value}'])
        
        try:
            result = subprocess.run(cmd, capture_output=True, text=True, check=True)
            return True
        except subprocess.CalledProcessError as e:
            print(f"Logging failed: {e}", file=sys.stderr)
            return False
    
    def debug(self, message, **kwargs):
        return self.log('DEBUG', message, **kwargs)
    
    def info(self, message, **kwargs):
        return self.log('INFO', message, **kwargs)
    
    def notice(self, message, **kwargs):
        return self.log('NOTICE', message, **kwargs)
    
    def warning(self, message, **kwargs):
        return self.log('WARNING', message, **kwargs)
    
    def error(self, message, **kwargs):
        return self.log('ERROR', message, **kwargs)
    
    def critical(self, message, **kwargs):
        return self.log('CRITICAL', message, **kwargs)
    
    def fatal(self, message, **kwargs):
        return self.log('FATAL', message, **kwargs)


# Example usage
if __name__ == '__main__':
    # Initialize logger
    logger = LogCollector('python-examples')
    
    print("=== Python Integration Examples ===\n")
    
    # Example 1: Basic logging
    print("1. Basic logging:")
    logger.info("Python application started")
    logger.debug("Debug information", console=True)
    
    # Example 2: With metadata
    print("\n2. Logging with metadata:")
    logger.info(
        "Data processing completed",
        json=True,
        metadata={
            'records_processed': 1000,
            'duration_seconds': 5.2,
            'success_rate': 0.98
        }
    )
    
    # Example 3: Error logging
    print("\n3. Error logging:")
    try:
        # Simulate an error
        result = 10 / 0
    except Exception as e:
        logger.error(
            f"Error in calculation: {str(e)}",
            console=True,
            metadata={'error_type': type(e).__name__}
        )
    
    # Example 4: Different log levels
    print("\n4. Different log levels:")
    logger.info("Starting database backup")
    logger.warning("Disk usage at 85%")
    logger.error("Connection timeout", console=True)
    
    # Example 5: Context manager (optional enhancement)
    class LogContext:
        def __init__(self, logger, operation):
            self.logger = logger
            self.operation = operation
            self.start_time = None
        
        def __enter__(self):
            self.start_time = datetime.now()
            self.logger.info(f"Starting: {self.operation}")
            return self
        
        def __exit__(self, exc_type, exc_val, exc_tb):
            duration = (datetime.now() - self.start_time).total_seconds()
            if exc_type:
                self.logger.error(
                    f"Failed: {self.operation}",
                    metadata={'duration': duration, 'error': str(exc_val)}
                )
            else:
                self.logger.info(
                    f"Completed: {self.operation}",
                    metadata={'duration': duration}
                )
    
    print("\n5. Using context manager:")
    with LogContext(logger, "data_export"):
        # Simulate some work
        import time
        time.sleep(0.1)
        print("   Processing...")
    
    print("\nCheck logs at: /var/log/python-examples/current/")
