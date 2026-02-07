# Enhanced Log Collector - Changelog

All notable changes to this project will be documented in this file.

Author: Yash Shrivastava  
Copyright: © 2026 Yash Shrivastava  
License: MIT

---

## [3.0.0] - 2026-02-07

### 🎉 Major Release - Complete Rewrite

This is a major release with extensive improvements, new features, and bug fixes based on comprehensive code review.

### ✨ Added

#### Command-Line Interface
- **20+ New Flags:**
  - `-h, --help` - Comprehensive help system
  - `-v, --version` - Version information
  - `-V, --verbose` - Verbose output mode
  - `-q, --quiet` - Quiet mode (suppress output)
  - `-n, --dry-run` - Test mode without making changes
  - `-c, --config FILE` - Custom configuration file
  - `--show-config` - Display current configuration
  - `--validate` - Validate configuration
  - `-u, --user USER` - Set file owner
  - `-g, --group GROUP` - Set file group
  - `-m, --metadata KEY=VALUE` - Add metadata (multiple allowed)
  - `--debug` - Enable debug mode
  - `--no-rotation` - Disable rotation
  - `--no-compression` - Disable compression
  - `-f, --force` - Force operations
  - `--cleanup [TASK]` - Run cleanup
  - `--rotate [TASK]` - Force rotation
  - `--compress [TASK]` - Force compression

#### Core Features
- **Rate Limiting:** Prevent log flooding with configurable limits
  - Actions: drop, sample, or block
  - Configurable window and maximum count
  - Per-task tracking
  
- **Disk Space Management:**
  - Pre-write disk space checks
  - Warning and critical thresholds
  - Emergency cleanup when critical
  - Configurable actions (cleanup, alert, stop)
  
- **Input Validation & Sanitization:**
  - Task name sanitization (prevent path traversal)
  - Message length limits
  - Special character escaping for JSON
  - Configurable max lengths
  
- **File Size Caching:**
  - Reduces filesystem stat() calls
  - Configurable cache timeout
  - Significant performance improvement
  
- **Health Check & Metrics:**
  - Health check file with timestamps
  - Metrics collection (total logs, errors, rotations, compressions)
  - Exportable metrics for monitoring
  
- **Async Compression:**
  - Background compression to avoid blocking
  - Configurable worker count
  - Improved throughput

#### Security Features
- Input sanitization (enabled by default)
- Path traversal prevention
- Configurable file permissions (640 default)
- Configurable directory permissions (750 default)
- User/group ownership control
- Maximum message length enforcement
- Safe metadata handling

#### Usability Features
- **Comprehensive Help System:**
  - Quick help for common usage
  - Full help with all options
  - Examples for every feature
  - Integration guides
  
- **Configuration Management:**
  - Show current config
  - Validate configuration
  - Environment-based config selection
  - Config file auto-detection
  
- **Maintenance Tools:**
  - Force cleanup command
  - Force rotation command
  - Force compression command
  - Dry-run mode for all operations
  
- **Better Error Messages:**
  - Descriptive error messages
  - Colored output (when terminal)
  - Exit codes for automation
  - Verbose and debug modes

#### Developer Features
- Proper exit codes (0-6)
- Lock files for safe rotation
- Race condition prevention
- Better error handling
- Script metadata (version, PID, etc.)
- Logging wrapper examples
- Integration templates

### 🔧 Changed

#### Breaking Changes
- None - v3.0 is fully backward compatible with v2.0

#### Improvements
- **Configuration Loading:**
  - Environment-based config selection (`LOG_COLLECTOR_ENV`)
  - Custom config path support
  - Better error messages
  - Validation on load
  
- **Log Rotation:**
  - File locking to prevent race conditions
  - Improved rotation trigger detection
  - Better archive naming
  - Safer move operations
  
- **Compression:**
  - Async compression option
  - Configurable compression level
  - Background compression queue
  - Non-blocking operations
  
- **Performance:**
  - File size caching
  - Reduced filesystem calls
  - Optimized cleanup scheduling
  - Better memory usage
  
- **Code Quality:**
  - Proper function organization
  - Consistent naming conventions
  - Better comments and documentation
  - Shellcheck compliance
  - Error handling throughout

### 🐛 Fixed

#### Critical Fixes
- **Race Condition in Rotation:** Fixed concurrent rotation attempts using file locks
- **Path Injection Vulnerability:** Added input sanitization for task names
- **Command Injection in Metadata:** Proper escaping of all metadata values
- **Unsafe Email Command:** Properly escaped email content
- **Missing Disk Space Check:** Added pre-write space verification

#### Important Fixes
- **No Configuration Validation:** Added comprehensive validation
- **Inefficient Rotation Check:** Implemented file size caching
- **Synchronous Compression Blocking:** Added async compression option
- **Missing Input Validation:** Validate all user inputs
- **Hardcoded Paths:** Made paths configurable
- **No Rate Limiting:** Implemented rate limiting
- **Unsafe File Permissions:** Made permissions configurable

#### Minor Fixes
- Fixed log level validation
- Improved error messages
- Better cleanup scheduling
- Fixed metadata JSON formatting
- Corrected color codes for terminal output
- Fixed stack trace generation
- Improved syslog integration

### 📝 Documentation

- **README_v3.md:** Complete user guide with examples
- **QUICK_REFERENCE.md:** Quick reference card
- **CONFIGURATION_GUIDE.md:** Detailed configuration documentation
- **ANALYSIS_AND_FIXES.md:** Complete code review and fixes
- Inline code comments throughout
- Integration examples (Bash, Python, Cron, Systemd, Docker)
- Troubleshooting guide
- Migration guide from v2.0

### 🔒 Security

- Input sanitization enabled by default
- Path traversal prevention
- Command injection prevention
- Configurable file permissions
- Ownership validation
- Safe metadata handling
- Email content escaping
- Maximum length enforcement

### ⚡ Performance

- File size caching (60s default)
- Async compression option
- Reduced filesystem calls
- Optimized cleanup scheduling
- Better memory usage
- Non-blocking operations
- Configurable performance settings

---

## [2.0.0] - 2026-01-04

### Added
- Automatic log rotation (size and date-based)
- Gzip compression for archives
- Configurable retention policies
- JSON output format
- Colored console output
- Syslog integration
- Email alerts
- Rich metadata support
- Stack trace capability
- External configuration file
- Seven log levels (DEBUG to FATAL)
- Background cleanup operations

### Changed
- Expanded from 3 to 7 log levels
- Improved directory structure (current/archive)
- Better error handling

### Fixed
- Concurrent write issues
- Permission handling
- Various bug fixes

---

## [1.0.0] - 2025-01-01

### Added
- Initial release
- Basic text logging
- 3 log levels (INFO, WARNING, ERROR)
- Simple file output
- Manual log management

---

## Upgrade Guide

### From v2.0 to v3.0

v3.0 is **fully backward compatible**. Your existing scripts will work without changes.

**Optional Upgrades:**

```bash
# 1. Update script
sudo cp logCollector_v3.sh /opt/scripts/logCollector.sh

# 2. Update configuration (optional)
sudo cp config-production.conf /etc/logCollector.conf

# 3. Validate new config
/opt/scripts/logCollector.sh --validate

# 4. Test with dry-run
/opt/scripts/logCollector.sh --dry-run backup test.sh INFO "Test" --console
```

**New Features to Adopt:**

```bash
# Use new flags
./logCollector.sh -c /etc/custom.conf backup backup.sh INFO "Message"

# Add metadata
./logCollector.sh backup backup.sh INFO "Complete" -m size=10GB

# Use maintenance commands
./logCollector.sh --cleanup backup
./logCollector.sh --validate

# Enable new features in config
ENABLE_RATE_LIMIT=true
ENABLE_HEALTH_CHECK=true
ENABLE_METRICS=true
```

### From v1.0 to v3.0

v3.0 includes all v2.0 features plus v3.0 enhancements.

**Major Changes:**
- 3 → 7 log levels
- Manual → Automatic rotation
- No compression → Automatic compression
- Hardcoded → Configurable settings

**Migration Steps:**

```bash
# 1. Review new log levels
DEBUG, INFO, NOTICE, WARNING, ERROR, CRITICAL, FATAL

# 2. Update scripts to use new levels
# Old: ERROR, INFO, WARNING
# New: Map to appropriate new levels

# 3. Configure retention policies
LOG_RETENTION_DAYS=30
ARCHIVE_RETENTION_DAYS=90

# 4. Enable compression
ENABLE_COMPRESSION=true

# 5. Set up configuration file
sudo cp config-production.conf /etc/logCollector.conf
```

---

## Version Numbering

This project uses [Semantic Versioning](https://semver.org/):

- **MAJOR** version for incompatible API changes
- **MINOR** version for new functionality (backward compatible)
- **PATCH** version for backward compatible bug fixes

---

## Future Roadmap

### v3.1 (Planned)
- [ ] Web dashboard for log viewing
- [ ] REST API endpoint
- [ ] Elasticsearch direct integration
- [ ] Grafana/Prometheus metrics export
- [ ] Log search functionality
- [ ] Log replay feature
- [ ] Multi-destination routing

### v3.2 (Planned)
- [ ] Cloud storage backends (S3, GCS, Azure Blob)
- [ ] Log streaming protocol support
- [ ] Enhanced filtering capabilities
- [ ] Performance profiling mode
- [ ] Auto-tuning based on load
- [ ] Machine learning anomaly detection

### v4.0 (Future)
- [ ] Distributed logging support
- [ ] Cluster coordination
- [ ] Load balancing
- [ ] High availability mode
- [ ] Real-time log tailing API
- [ ] Advanced query language

---

## Contributing

We welcome contributions! See CONTRIBUTING.md for details.

Types of contributions:
- Bug reports
- Feature requests
- Code contributions
- Documentation improvements
- Performance optimizations
- Security enhancements

---

## Support

- **Issues:** https://github.com/yashshrivastava2206/enhanced-log-collector/issues
- **Discussions:** https://github.com/yashshrivastava2206/enhanced-log-collector/discussions
- **Documentation:** README_v3.md, CONFIGURATION_GUIDE.md
- **Author:** Yash Shrivastava

---

**Changelog Last Updated:** 2026-02-07  
**Current Version:** 3.0.0  
**License:** MIT
