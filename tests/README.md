# Enhanced Log Collector — Manual Test Cases

**Script Under Test:** `bin/logCollector.sh`  
**Version:** 2.0  
**Author:** Yash Shrivastava  
**Test Document Purpose:** Step-by-step manual test cases with exact commands to run, expected output, and what to verify.

---

## How to Use This Document

Each test case follows this structure:

| Field | Meaning |
|---|---|
| **TC-ID** | Unique test case identifier |
| **Category** | Feature area being tested |
| **Objective** | What this test proves |
| **Pre-condition** | What must be true before running |
| **Command** | Exact command to paste into your terminal |
| **Expected Result** | What should happen (file created, output shown, etc.) |
| **How to Verify** | Exact command to confirm the result |
| **Pass Criteria** | What a PASS looks like |

---

## Setup Before Running Tests

Run these once before starting any test cases:

```bash
# 1. Make script executable
chmod +x /opt/scripts/logCollector.sh

# Or if running from repo directory:
chmod +x bin/logCollector.sh

# 2. Create a test alias to save typing (optional)
alias lc="bin/logCollector.sh"

# 3. Set base log dir for testing (avoids touching /var/log)
export TEST_LOG_DIR="/tmp/lc_test"
mkdir -p $TEST_LOG_DIR

# Add to /etc/logCollector.conf or create a test config:
echo 'BASE_LOG_DIR="/tmp/lc_test"' | sudo tee /etc/logCollector.conf
```

---

## TC-01 — Missing Arguments (No Arguments)

**Category:** Input Validation  
**Objective:** Verify the script prints usage help when called with no arguments and exits with code 1.

**Pre-condition:** Script is executable.

**Command:**
```bash
bin/logCollector.sh
```

**Expected Result:**
```
╔════════════════════════════════════════════════════════════════════════════╗
║ Enhanced Log Collector v2.0                                               ║
╚════════════════════════════════════════════════════════════════════════════╝

USAGE:
  bin/logCollector.sh [TaskName] [ScriptFileName] [LogLevel] [Message] [Options]
  ...
```
Script exits with code `1`.

**How to Verify:**
```bash
bin/logCollector.sh
echo "Exit code: $?"
```

**Pass Criteria:**
- Usage block is printed to terminal
- `echo "Exit code: $?"` outputs `Exit code: 1`

---

## TC-02 — Missing Arguments (Only 3 of 4 Required)

**Category:** Input Validation  
**Objective:** Verify the script rejects calls that are missing the Message argument.

**Pre-condition:** Script is executable.

**Command:**
```bash
bin/logCollector.sh 'backup' 'backup.sh' 'INFO'
```

**Expected Result:**
- Usage/help block is printed
- Script exits with code `1` (not `0`)

**How to Verify:**
```bash
bin/logCollector.sh 'backup' 'backup.sh' 'INFO'
echo "Exit code: $?"
```

**Pass Criteria:**
- Usage is printed
- Exit code is `1`

---

## TC-03 — Invalid Log Level

**Category:** Input Validation  
**Objective:** Verify the script rejects unrecognized log level names and reports them clearly.

**Pre-condition:** Script is executable.

**Command:**
```bash
bin/logCollector.sh 'backup' 'backup.sh' 'WARN' 'Test message'
```

**Expected Result:**
```
ERROR: Invalid log level 'WARN'
Valid levels: DEBUG INFO NOTICE WARNING ERROR CRITICAL FATAL
```
Exit code is `1`.

**How to Verify:**
```bash
bin/logCollector.sh 'backup' 'backup.sh' 'WARN' 'Test message'
echo "Exit code: $?"
```

**Pass Criteria:**
- Error message names the invalid level (`WARN`)
- Valid levels are listed
- Exit code is `1`

**Common Mistakes to Check:**
Try these — all should fail with the same error:
```bash
bin/logCollector.sh 'test' 'test.sh' 'CRIT'    'msg'   # Should fail — use CRITICAL
bin/logCollector.sh 'test' 'test.sh' 'warn'    'msg'   # Should fail — lowercase
bin/logCollector.sh 'test' 'test.sh' 'VERBOSE' 'msg'   # Should fail — not a valid level
```

---

## TC-04 — Basic INFO Log (Plain Text)

**Category:** Core Logging  
**Objective:** Verify a basic INFO log entry is written to the correct file in plain text format.

**Pre-condition:** `BASE_LOG_DIR` is set (e.g. `/tmp/lc_test`).

**Command:**
```bash
bin/logCollector.sh 'backup' 'backup.sh' 'INFO' 'Backup started successfully'
```

**Expected Result:**
- No error output on terminal
- Directory `/tmp/lc_test/backup/current/` is created
- A file named `backup.sh_YYYY-MM-DD.log` (today's date) appears in that directory
- The file contains a line like:
  ```
  2026-03-04T14:22:01+0530 [your-hostname] [backup.sh] [PID:XXXXX] [your-user] [INFO] Backup started successfully
  ```

**How to Verify:**
```bash
# Check directory was created
ls /tmp/lc_test/backup/current/

# Read the log file (replace date)
cat /tmp/lc_test/backup/current/backup.sh_$(date +%Y-%m-%d).log
```

**Pass Criteria:**
- File exists with today's date in the name
- Log line contains: correct timestamp format, hostname, `[backup.sh]`, `[INFO]`, and the message
- Exit code is `0`

---

## TC-05 — All 7 Log Levels Written to File

**Category:** Core Logging  
**Objective:** Verify all 7 log levels (DEBUG, INFO, NOTICE, WARNING, ERROR, CRITICAL, FATAL) are accepted and written correctly.

**Pre-condition:** `BASE_LOG_DIR` set.

**Commands (run all 7):**
```bash
bin/logCollector.sh 'leveltest' 'test.sh' 'DEBUG'    'Debug message'
bin/logCollector.sh 'leveltest' 'test.sh' 'INFO'     'Info message'
bin/logCollector.sh 'leveltest' 'test.sh' 'NOTICE'   'Notice message'
bin/logCollector.sh 'leveltest' 'test.sh' 'WARNING'  'Warning message'
bin/logCollector.sh 'leveltest' 'test.sh' 'ERROR'    'Error message'
bin/logCollector.sh 'leveltest' 'test.sh' 'CRITICAL' 'Critical message'
bin/logCollector.sh 'leveltest' 'test.sh' 'FATAL'    'Fatal message'
```

**How to Verify:**
```bash
cat /tmp/lc_test/leveltest/current/test.sh_$(date +%Y-%m-%d).log
```

**Expected Output (7 lines, one per level):**
```
2026-03-04T...[DEBUG]    Debug message
2026-03-04T...[INFO]     Info message
2026-03-04T...[NOTICE]   Notice message
2026-03-04T...[WARNING]  Warning message
2026-03-04T...[ERROR]    Error message
2026-03-04T...[CRITICAL] Critical message
2026-03-04T...[FATAL]    Fatal message
```

**Pass Criteria:**
- File contains exactly 7 lines
- Each line contains the correct `[LEVEL]` tag
- No errors during execution
- All 7 exit codes are `0`

---

## TC-06 — Console Output (`--console`)

**Category:** Output Format  
**Objective:** Verify that `--console` flag prints a color-coded line to the terminal AND still writes to the log file.

**Pre-condition:** Run in a terminal that supports ANSI colors.

**Commands:**
```bash
bin/logCollector.sh 'consoletest' 'test.sh' 'INFO'     'Info line'    --console
bin/logCollector.sh 'consoletest' 'test.sh' 'WARNING'  'Warning line' --console
bin/logCollector.sh 'consoletest' 'test.sh' 'ERROR'    'Error line'   --console
bin/logCollector.sh 'consoletest' 'test.sh' 'CRITICAL' 'Critical line' --console
bin/logCollector.sh 'consoletest' 'test.sh' 'FATAL'    'Fatal line'   --console
```

**Expected Terminal Output (each command):**
You should see colored output like:
```
[INFO]     2026-03-04T... [test.sh] Info line          ← Green
[WARNING]  2026-03-04T... [test.sh] Warning line       ← Yellow
[ERROR]    2026-03-04T... [test.sh] Error line         ← Red
[CRITICAL] 2026-03-04T... [test.sh] Critical line      ← Bold Red
[FATAL]    2026-03-04T... [test.sh] Fatal line         ← Bold Magenta
```

**How to Verify:**
```bash
# Confirm log file was ALSO written (not just console)
cat /tmp/lc_test/consoletest/current/test.sh_$(date +%Y-%m-%d).log
```

**Pass Criteria:**
- Colored output visible on terminal for each level
- Each level shows a different color
- Log file ALSO contains all 5 entries (dual output confirmed)

---

## TC-07 — JSON Format (`--json`)

**Category:** Output Format  
**Objective:** Verify that `--json` writes a valid JSON object to the log file.

**Pre-condition:** `BASE_LOG_DIR` set.

**Command:**
```bash
bin/logCollector.sh 'jsontest' 'myscript.sh' 'INFO' 'Backup completed' --json
```

**How to Verify:**
```bash
cat /tmp/lc_test/jsontest/current/myscript.sh_$(date +%Y-%m-%d).log
```

**Expected Output:**
```json
{
  "timestamp": "2026-03-04T14:30:00+0530",
  "hostname": "your-hostname",
  "script": "myscript.sh",
  "level": "INFO",
  "message": "Backup completed",
  "pid": 12345,
  "user": "youruser",
  "version": "2.0"
}
```

**Pass Criteria:**
- Output is valid JSON (can be parsed by `python3 -m json.tool`)
- All fields present: `timestamp`, `hostname`, `script`, `level`, `message`, `pid`, `user`, `version`
- `level` is `"INFO"`, `message` is `"Backup completed"`

**Bonus Verify (parse the JSON):**
```bash
cat /tmp/lc_test/jsontest/current/myscript.sh_$(date +%Y-%m-%d).log | python3 -m json.tool
```
Should print the JSON without errors.

---

## TC-08 — JSON with Custom Metadata (`--json --metadata`)

**Category:** Output Format + Metadata  
**Objective:** Verify that `--metadata KEY=VALUE` pairs appear inside the `metadata` block of the JSON output.

**Command:**
```bash
bin/logCollector.sh 'jsonmeta' 'backup.sh' 'INFO' 'Backup done' \
  --json \
  --metadata database=production \
  --metadata size=50GB \
  --metadata duration=300s
```

**How to Verify:**
```bash
cat /tmp/lc_test/jsonmeta/current/backup.sh_$(date +%Y-%m-%d).log
```

**Expected Output:**
```json
{
  "timestamp": "...",
  "hostname": "...",
  "script": "backup.sh",
  "level": "INFO",
  "message": "Backup done",
  "pid": ...,
  "user": "...",
  "version": "2.0",
  "metadata": {
    "database": "production",
    "size": "50GB",
    "duration": "300s"
  }
}
```

**Pass Criteria:**
- `metadata` block exists in the JSON
- Contains all 3 key-value pairs: `database`, `size`, `duration`
- JSON is still valid (parse with `python3 -m json.tool`)

---

## TC-09 — Syslog Integration (`--syslog`)

**Category:** Output Format  
**Objective:** Verify that `--syslog` forwards the log entry to the system logger.

**Pre-condition:** `logger` command is available (`which logger`).

**Command:**
```bash
bin/logCollector.sh 'syslogtest' 'test.sh' 'ERROR' 'Syslog test entry' --syslog
```

**How to Verify:**
```bash
# On RHEL/CentOS:
sudo grep "Syslog test entry" /var/log/messages

# On Ubuntu/Debian:
sudo grep "Syslog test entry" /var/log/syslog

# Universal:
sudo journalctl -t test.sh --since "1 minute ago"
```

**Expected Output:**
A syslog entry like:
```
Mar 04 14:30:00 hostname test.sh[12345]: Syslog test entry
```

**Pass Criteria:**
- Entry appears in syslog within a few seconds
- The script name (`test.sh`) appears as the syslog tag
- Message text matches exactly

---

## TC-10 — Stack Trace (`--stacktrace`)

**Category:** Debugging  
**Objective:** Verify that `--stacktrace` appends Bash call stack information to the log entry.

**Command:**
```bash
bin/logCollector.sh 'tracetest' 'test.sh' 'ERROR' 'Something failed' --stacktrace --console
```

**How to Verify:**
```bash
cat /tmp/lc_test/tracetest/current/test.sh_$(date +%Y-%m-%d).log
```

**Expected Output:**
The log entry message should contain something like:
```
... [ERROR] Something failed
Stack Trace:
main 20 test.sh
...
```

**Pass Criteria:**
- Log entry contains the original message (`Something failed`)
- Stack trace information is appended (lines showing function name, line number, file)
- No crash or error during execution

---

## TC-11 — Log Directory Auto-Creation

**Category:** Directory Management  
**Objective:** Verify the script automatically creates the 3-level directory structure (`task/`, `task/current/`, `task/archive/`) on first use.

**Pre-condition:** The task name `autodir` does NOT already exist under `BASE_LOG_DIR`.

**Setup:**
```bash
# Ensure the task directory does not exist
rm -rf /tmp/lc_test/autodir
```

**Command:**
```bash
bin/logCollector.sh 'autodir' 'test.sh' 'INFO' 'Testing dir creation'
```

**How to Verify:**
```bash
ls -la /tmp/lc_test/autodir/
ls -la /tmp/lc_test/autodir/current/
ls -la /tmp/lc_test/autodir/archive/
```

**Expected Output:**
```
/tmp/lc_test/autodir/
├── current/
│   └── test.sh_YYYY-MM-DD.log
└── archive/   (empty, but exists)
```

**Pass Criteria:**
- `autodir/` directory created
- `autodir/current/` directory created
- `autodir/archive/` directory created
- Log file exists inside `current/`

---

## TC-12 — Multiple Scripts, Same Task (Separate Log Files)

**Category:** Directory Management  
**Objective:** Verify that different scripts logging to the same task create separate log files per script name.

**Commands:**
```bash
bin/logCollector.sh 'multiscript' 'backup.sh'  'INFO' 'Backup started'
bin/logCollector.sh 'multiscript' 'restore.sh' 'INFO' 'Restore started'
bin/logCollector.sh 'multiscript' 'vacuum.sh'  'INFO' 'Vacuum started'
```

**How to Verify:**
```bash
ls /tmp/lc_test/multiscript/current/
```

**Expected Output:**
```
backup.sh_2026-03-04.log
restore.sh_2026-03-04.log
vacuum.sh_2026-03-04.log
```

**Pass Criteria:**
- 3 separate log files exist under the same `multiscript/current/` directory
- Each file contains only the entries from its respective script

---

## TC-13 — Multiple Tasks (Separate Directories)

**Category:** Directory Management  
**Objective:** Verify that different task names create separate top-level directories.

**Commands:**
```bash
bin/logCollector.sh 'backup'      'backup.sh'  'INFO' 'Task A'
bin/logCollector.sh 'maintenance' 'vacuum.sh'  'INFO' 'Task B'
bin/logCollector.sh 'monitoring'  'health.sh'  'INFO' 'Task C'
```

**How to Verify:**
```bash
ls /tmp/lc_test/
```

**Expected Output:**
```
backup/
maintenance/
monitoring/
```

**Pass Criteria:**
- 3 separate task directories exist
- Each has its own `current/` and `archive/` subdirectories

---

## TC-14 — Log File Name Uses Today's Date

**Category:** File Naming  
**Objective:** Verify log files are named `[scriptname]_YYYY-MM-DD.log` using the current date.

**Command:**
```bash
TODAY=$(date +%Y-%m-%d)
bin/logCollector.sh 'datetest' 'myscript.sh' 'INFO' 'Date naming test'
```

**How to Verify:**
```bash
ls /tmp/lc_test/datetest/current/
```

**Expected Output:**
```
myscript.sh_2026-03-04.log    ← today's date
```

**Pass Criteria:**
- File name matches the pattern `myscript.sh_YYYY-MM-DD.log`
- The date in the file name equals today (`date +%Y-%m-%d`)

---

## TC-15 — Timestamp Format is ISO 8601

**Category:** Log Format  
**Objective:** Verify the timestamp in each log entry follows ISO 8601 format with timezone offset.

**Command:**
```bash
bin/logCollector.sh 'tstest' 'test.sh' 'INFO' 'Timestamp format check'
cat /tmp/lc_test/tstest/current/test.sh_$(date +%Y-%m-%d).log
```

**Expected Timestamp Format:**
```
2026-03-04T14:22:01+0530
```
Pattern: `YYYY-MM-DDTHH:MM:SS+HHMM` or `YYYY-MM-DDTHH:MM:SS-HHMM`

**Pass Criteria:**
- Timestamp starts the log line
- Format matches `YYYY-MM-DDTHH:MM:SS[+-]HHMM`
- Time is close to the current system time

---

## TC-16 — PID is Captured in Log Entry

**Category:** Log Format  
**Objective:** Verify each log entry contains the process ID (`[PID:XXXXX]`).

**Command:**
```bash
bin/logCollector.sh 'pidtest' 'test.sh' 'INFO' 'PID capture test'
cat /tmp/lc_test/pidtest/current/test.sh_$(date +%Y-%m-%d).log
```

**Expected Log Line:**
```
2026-03-04T14:22:01+0530 [hostname] [test.sh] [PID:12345] [user] [INFO] PID capture test
```

**Pass Criteria:**
- `[PID:NNNNN]` is present in the log line
- The PID value is a positive integer

---

## TC-17 — Hostname is Captured in Log Entry

**Category:** Log Format  
**Objective:** Verify each log entry contains the server hostname.

**Command:**
```bash
EXPECTED_HOST=$(hostname -f 2>/dev/null || hostname)
bin/logCollector.sh 'hosttest' 'test.sh' 'INFO' 'Hostname capture test'
grep "$EXPECTED_HOST" /tmp/lc_test/hosttest/current/test.sh_$(date +%Y-%m-%d).log
```

**Pass Criteria:**
- `grep` finds the hostname in the log entry
- Hostname matches the output of `hostname -f` (or `hostname` as fallback)

---

## TC-18 — Username is Captured in Log Entry

**Category:** Log Format  
**Objective:** Verify each log entry contains the current username.

**Command:**
```bash
EXPECTED_USER=$USER
bin/logCollector.sh 'usertest' 'test.sh' 'INFO' 'User capture test'
cat /tmp/lc_test/usertest/current/test.sh_$(date +%Y-%m-%d).log
```

**Expected Log Line Contains:**
```
[your-username]
```

**Pass Criteria:**
- `[$USER]` appears in the log line
- Username matches the current shell user

---

## TC-19 — Script Can Be Sourced (Not Just Executed)

**Category:** Sourceable Design  
**Objective:** Verify `collect_log` function is available when the script is sourced, and that the script does NOT auto-execute `main`.

**Command:**
```bash
source bin/logCollector.sh
collect_log 'sourcetest' 'test.sh' 'INFO' 'Called after sourcing'
```

**How to Verify:**
```bash
cat /tmp/lc_test/sourcetest/current/test.sh_$(date +%Y-%m-%d).log
```

**Pass Criteria:**
- `source` completes without error
- `collect_log` function is callable directly
- Log entry appears in the file
- Sourcing does NOT trigger the usage/help message (i.e., `main` is NOT called on source)

---

## TC-20 — Log Rotation: File Moves to Archive on Size Threshold

**Category:** Log Rotation  
**Objective:** Verify that when a log file reaches `MAX_LOG_SIZE_MB`, it is rotated to the `archive/` directory.

**Pre-condition:** Set `MAX_LOG_SIZE_MB=1` in `/etc/logCollector.conf` for this test (so we don't need to write 100 MB of data).

**Setup:**
```bash
# Temporarily lower the size threshold to 1 MB
echo 'BASE_LOG_DIR="/tmp/lc_test"
MAX_LOG_SIZE_MB=1' | sudo tee /etc/logCollector.conf

# Create a fake 2 MB log file to trigger rotation
mkdir -p /tmp/lc_test/rottest/current
dd if=/dev/zero bs=1M count=2 | tr '\0' 'X' > /tmp/lc_test/rottest/current/rot.sh_$(date +%Y-%m-%d).log
ls -lh /tmp/lc_test/rottest/current/
```

**Command:**
```bash
bin/logCollector.sh 'rottest' 'rot.sh' 'INFO' 'This should trigger rotation'
```

**How to Verify:**
```bash
# Old file should now be in archive/
ls -lh /tmp/lc_test/rottest/archive/

# New (small) log file should be in current/
ls -lh /tmp/lc_test/rottest/current/
```

**Pass Criteria:**
- Archive directory contains a file named `rot.sh_YYYYMMDD_HHMMSS.log` (or `.log.gz` if compressed)
- Current directory contains a new, small `rot.sh_YYYY-MM-DD.log` file
- The new log file contains the "This should trigger rotation" entry

**Teardown:**
```bash
# Restore config
echo 'BASE_LOG_DIR="/tmp/lc_test"
MAX_LOG_SIZE_MB=100' | sudo tee /etc/logCollector.conf
```

---

## TC-21 — Log Rotation: Archive File Has Timestamp in Name

**Category:** Log Rotation  
**Objective:** Verify that rotated files are named with a timestamp suffix (`scriptname_YYYYMMDD_HHMMSS.log`).

**Pre-condition:** TC-20 has been run (archive file already exists).

**How to Verify:**
```bash
ls /tmp/lc_test/rottest/archive/
```

**Expected Output:**
```
rot.sh_20260304_142201.log        (uncompressed)
— or —
rot.sh_20260304_142201.log.gz     (if ENABLE_COMPRESSION=true)
```

**Pass Criteria:**
- Archive filename matches pattern `[scriptname]_YYYYMMDD_HHMMSS.log` or `.log.gz`

---

## TC-22 — Compression: Rotated Log is Gzip-Compressed

**Category:** Compression  
**Objective:** Verify that when `ENABLE_COMPRESSION=true`, rotated archive files are compressed with gzip.

**Pre-condition:** `ENABLE_COMPRESSION=true` in config. TC-20 rotation was triggered.

**How to Verify:**
```bash
# Check for .gz files
ls /tmp/lc_test/rottest/archive/*.gz

# Confirm the file is a valid gzip archive
file /tmp/lc_test/rottest/archive/*.gz

# Confirm it can be read
zcat /tmp/lc_test/rottest/archive/*.gz | head -5
```

**Pass Criteria:**
- File ends with `.gz`
- `file` command reports `gzip compressed data`
- `zcat` outputs the original log content without errors

---

## TC-23 — Compression Disabled: Archive is Uncompressed

**Category:** Compression  
**Objective:** Verify that when `ENABLE_COMPRESSION=false`, rotated files remain as plain `.log` files.

**Pre-condition:** Set `ENABLE_COMPRESSION=false` in config.

**Setup:**
```bash
echo 'BASE_LOG_DIR="/tmp/lc_test"
MAX_LOG_SIZE_MB=1
ENABLE_COMPRESSION=false' | sudo tee /etc/logCollector.conf

mkdir -p /tmp/lc_test/nocomp/current
dd if=/dev/zero bs=1M count=2 | tr '\0' 'X' > /tmp/lc_test/nocomp/current/nc.sh_$(date +%Y-%m-%d).log
```

**Command:**
```bash
bin/logCollector.sh 'nocomp' 'nc.sh' 'INFO' 'No compression test'
sleep 2   # allow background compression to run (if any)
```

**How to Verify:**
```bash
ls /tmp/lc_test/nocomp/archive/
```

**Pass Criteria:**
- Archive file exists with `.log` extension (NOT `.log.gz`)
- No `.gz` file present

**Teardown:**
```bash
echo 'BASE_LOG_DIR="/tmp/lc_test"
MAX_LOG_SIZE_MB=100
ENABLE_COMPRESSION=true' | sudo tee /etc/logCollector.conf
```

---

## TC-24 — Multiple Flags Combined

**Category:** Multiple Features  
**Objective:** Verify that `--json`, `--console`, and `--syslog` can all be used together in one call.

**Command:**
```bash
bin/logCollector.sh 'multiflags' 'test.sh' 'WARNING' 'Multi-flag test' \
  --json \
  --console \
  --syslog
```

**How to Verify:**
```bash
# 1. Check log file contains JSON
cat /tmp/lc_test/multiflags/current/test.sh_$(date +%Y-%m-%d).log | python3 -m json.tool

# 2. Console output should have appeared when command ran (check terminal)

# 3. Check syslog
sudo journalctl -t test.sh --since "1 minute ago" | grep "Multi-flag test"
```

**Pass Criteria:**
- Log file contains valid JSON
- Console output appeared in terminal with color
- Syslog entry exists
- Exit code is `0`

---

## TC-25 — Email Alert — CRITICAL Level

**Category:** Email Alerts  
**Objective:** Verify that `--email` flag sends an email when used with a CRITICAL event.

**Pre-condition:**  
- `mail` or `mailx` is installed
- `ALERT_EMAIL` is set to a valid address in `/etc/logCollector.conf`
- You have access to that inbox

**Setup:**
```bash
echo 'BASE_LOG_DIR="/tmp/lc_test"
ENABLE_EMAIL_ALERTS=true
ALERT_EMAIL="your-actual-email@example.com"
ALERT_LEVELS="FATAL,CRITICAL"' | sudo tee /etc/logCollector.conf
```

**Command:**
```bash
bin/logCollector.sh 'emailtest' 'test.sh' 'CRITICAL' 'Database is unreachable' --email
```

**Expected Email:**
- Subject: `[CRITICAL] Alert from [hostname]: test.sh`
- Body contains: level, script, hostname, timestamp, message, and recent log entries

**Pass Criteria:**
- Email arrives at `ALERT_EMAIL` inbox within a few minutes
- Subject line contains `[CRITICAL]`
- Body contains `Database is unreachable`

---

## TC-26 — Email Alert — INFO Level (Should NOT Send Email)

**Category:** Email Alerts  
**Objective:** Verify that `--email` does NOT send an email for levels not in `ALERT_LEVELS`.

**Pre-condition:** `ALERT_LEVELS="FATAL,CRITICAL"` in config (default).

**Command:**
```bash
bin/logCollector.sh 'noemail' 'test.sh' 'INFO' 'Just an info message' --email
```

**Pass Criteria:**
- No email is sent for `INFO` level
- Command exits with code `0`
- Log entry IS still written to file

**How to Verify:**
```bash
# Confirm log was written
cat /tmp/lc_test/noemail/current/test.sh_$(date +%Y-%m-%d).log

# No email should arrive in inbox — wait 2 minutes and confirm
```

---

## TC-27 — Configuration File Override

**Category:** Configuration  
**Objective:** Verify that settings in `/etc/logCollector.conf` override the script's built-in defaults.

**Setup:**
```bash
echo 'BASE_LOG_DIR="/tmp/lc_custom"
MAX_LOG_SIZE_MB=50
ENABLE_CONSOLE_OUTPUT=true' | sudo tee /etc/logCollector.conf

mkdir -p /tmp/lc_custom
```

**Command:**
```bash
bin/logCollector.sh 'configtest' 'test.sh' 'INFO' 'Config override test'
```

**How to Verify:**
```bash
# Logs should go to /tmp/lc_custom, not /tmp/lc_test or /var/log
ls /tmp/lc_custom/configtest/current/

# Console output should appear (ENABLE_CONSOLE_OUTPUT=true)
# — confirm it printed to terminal when you ran the command
```

**Pass Criteria:**
- Log file appears under `/tmp/lc_custom/` (not the default `/var/log/`)
- Console output appeared without using `--console` flag (set in config)

**Teardown:**
```bash
echo 'BASE_LOG_DIR="/tmp/lc_test"' | sudo tee /etc/logCollector.conf
```

---

## TC-28 — Default JSON from Config (`ENABLE_JSON_FORMAT=true`)

**Category:** Configuration  
**Objective:** Verify that when `ENABLE_JSON_FORMAT=true` is set in config, ALL log entries are written in JSON format by default (without needing `--json` flag).

**Setup:**
```bash
echo 'BASE_LOG_DIR="/tmp/lc_test"
ENABLE_JSON_FORMAT=true' | sudo tee /etc/logCollector.conf
```

**Command:**
```bash
bin/logCollector.sh 'defaultjson' 'test.sh' 'INFO' 'Should be JSON by default'
```

**How to Verify:**
```bash
cat /tmp/lc_test/defaultjson/current/test.sh_$(date +%Y-%m-%d).log | python3 -m json.tool
```

**Pass Criteria:**
- Output is valid JSON without using `--json` flag
- JSON contains all standard fields

**Teardown:**
```bash
echo 'BASE_LOG_DIR="/tmp/lc_test"
ENABLE_JSON_FORMAT=false' | sudo tee /etc/logCollector.conf
```

---

## TC-29 — Special Characters in Message

**Category:** Edge Cases  
**Objective:** Verify that messages containing special characters (spaces, quotes, slashes, brackets) are handled correctly.

**Commands:**
```bash
# Message with spaces (already standard)
bin/logCollector.sh 'special' 'test.sh' 'INFO' 'Message with spaces here'

# Message with single quotes
bin/logCollector.sh 'special' 'test.sh' 'WARNING' "Server 'prod-db-01' is slow"

# Message with brackets
bin/logCollector.sh 'special' 'test.sh' 'ERROR' 'Failed at [step 3] of backup'

# Message with slashes
bin/logCollector.sh 'special' 'test.sh' 'INFO' 'Path /var/log/backup/ created'
```

**How to Verify:**
```bash
cat /tmp/lc_test/special/current/test.sh_$(date +%Y-%m-%d).log
```

**Pass Criteria:**
- All 4 log entries appear in file
- Each message is preserved exactly as written (special chars not mangled)
- No script crash or error

---

## TC-30 — Long Message

**Category:** Edge Cases  
**Objective:** Verify that a very long message (500+ characters) is handled without truncation or crash.

**Command:**
```bash
LONG_MSG="This is a very long log message that goes on and on. $(python3 -c "print('A'*400)")"
bin/logCollector.sh 'longmsg' 'test.sh' 'INFO' "$LONG_MSG"
```

**How to Verify:**
```bash
cat /tmp/lc_test/longmsg/current/test.sh_$(date +%Y-%m-%d).log | wc -c
# Should show a large character count
```

**Pass Criteria:**
- Script does not crash
- Log entry is written
- Message is not truncated (full 400+ 'A' characters present)

---

## TC-31 — Rapid Successive Writes (Concurrent Safety)

**Category:** Concurrency  
**Objective:** Verify that multiple rapid writes to the same log file do not cause corruption or missing entries.

**Command:**
```bash
for i in $(seq 1 50); do
  bin/logCollector.sh 'conctest' 'test.sh' 'INFO' "Rapid write number $i" &
done
wait
```

**How to Verify:**
```bash
wc -l /tmp/lc_test/conctest/current/test.sh_$(date +%Y-%m-%d).log
grep -c "Rapid write number" /tmp/lc_test/conctest/current/test.sh_$(date +%Y-%m-%d).log
```

**Pass Criteria:**
- File contains close to 50 entries (some lines may interleave but should all be present)
- No lines are half-written or corrupted
- `grep -c` returns a number near 50

---

## TC-32 — Exit Code 0 on Successful Log

**Category:** Exit Codes  
**Objective:** Verify script exits with code `0` on a successful log write.

**Command:**
```bash
bin/logCollector.sh 'exitcode' 'test.sh' 'INFO' 'Exit code test'
echo "Exit code: $?"
```

**Expected Output:**
```
Exit code: 0
```

**Pass Criteria:**
- Exit code is exactly `0`

---

## TC-33 — Version is Recorded in JSON Output

**Category:** Log Format  
**Objective:** Verify the `version` field in JSON output matches the script version (`2.0`).

**Command:**
```bash
bin/logCollector.sh 'versiontest' 'test.sh' 'INFO' 'Version check' --json
cat /tmp/lc_test/versiontest/current/test.sh_$(date +%Y-%m-%d).log
```

**Pass Criteria:**
- JSON contains `"version": "2.0"`

---

## TC-34 — No Config File (Uses Defaults)

**Category:** Configuration  
**Objective:** Verify script works correctly when `/etc/logCollector.conf` does not exist, using built-in defaults.

**Setup:**
```bash
sudo mv /etc/logCollector.conf /etc/logCollector.conf.bak 2>/dev/null || true
```

**Command:**
```bash
bin/logCollector.sh 'noconfig' 'test.sh' 'INFO' 'Running without config file'
```

**How to Verify:**
```bash
# With no config, BASE_LOG_DIR defaults to /var/log
ls /var/log/noconfig/current/
```

**Pass Criteria:**
- Script does not crash
- Log entry is written to `/var/log/noconfig/current/` (default `BASE_LOG_DIR`)
- Exit code is `0`

**Teardown:**
```bash
sudo mv /etc/logCollector.conf.bak /etc/logCollector.conf 2>/dev/null || true
```

---

## Test Execution Summary Tracker

Use this table to track your results:

| TC-ID | Test Name | Result | Notes |
|---|---|---|---|
| TC-01 | No arguments | PASS / FAIL | |
| TC-02 | Missing 4th argument | PASS / FAIL | |
| TC-03 | Invalid log level | PASS / FAIL | |
| TC-04 | Basic INFO log | PASS / FAIL | |
| TC-05 | All 7 log levels | PASS / FAIL | |
| TC-06 | Console output | PASS / FAIL | |
| TC-07 | JSON format | PASS / FAIL | |
| TC-08 | JSON with metadata | PASS / FAIL | |
| TC-09 | Syslog integration | PASS / FAIL | |
| TC-10 | Stack trace | PASS / FAIL | |
| TC-11 | Directory auto-creation | PASS / FAIL | |
| TC-12 | Multiple scripts, same task | PASS / FAIL | |
| TC-13 | Multiple tasks | PASS / FAIL | |
| TC-14 | Log file date naming | PASS / FAIL | |
| TC-15 | ISO 8601 timestamp | PASS / FAIL | |
| TC-16 | PID in log entry | PASS / FAIL | |
| TC-17 | Hostname in log entry | PASS / FAIL | |
| TC-18 | Username in log entry | PASS / FAIL | |
| TC-19 | Script can be sourced | PASS / FAIL | |
| TC-20 | Log rotation trigger | PASS / FAIL | |
| TC-21 | Archive file timestamp name | PASS / FAIL | |
| TC-22 | Compression enabled | PASS / FAIL | |
| TC-23 | Compression disabled | PASS / FAIL | |
| TC-24 | Multiple flags combined | PASS / FAIL | |
| TC-25 | Email — CRITICAL | PASS / FAIL | |
| TC-26 | Email — INFO (no send) | PASS / FAIL | |
| TC-27 | Config file override | PASS / FAIL | |
| TC-28 | Default JSON from config | PASS / FAIL | |
| TC-29 | Special characters | PASS / FAIL | |
| TC-30 | Long message | PASS / FAIL | |
| TC-31 | Rapid concurrent writes | PASS / FAIL | |
| TC-32 | Exit code 0 on success | PASS / FAIL | |
| TC-33 | Version in JSON | PASS / FAIL | |
| TC-34 | No config file (defaults) | PASS / FAIL | |

---

**Total Test Cases:** 34  
**Last Updated:** 2026-03-04  
**Script Version Tested:** 2.0
