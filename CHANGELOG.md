# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.0] - 2026-01-04

### Added
- Automatic log rotation (size and date-based)
- Gzip compression for archived logs
- Configurable retention policies
- JSON output format
- Colored console output with ANSI codes
- Syslog integration
- Email alerts for critical events
- Rich metadata support
- Stack trace capability
- External configuration file support
- Expanded to 7 log levels (DEBUG, INFO, NOTICE, WARNING, ERROR, CRITICAL, FATAL)
- Background cleanup operations
- Complete test suite
- Installation and deployment scripts
- Migration tools from v1.0

### Changed
- Restructured log directory layout (current/archive separation)
- Improved error handling and validation
- Performance optimizations for concurrent writes

### Fixed
- Concurrent write race conditions
- Permission handling issues
- Date-based log file naming

## [1.0.0] - 2025-01-01

### Added
- Initial release
- Basic text logging
- 3 log levels (INFO, WARNING, ERROR)
- Simple directory structure