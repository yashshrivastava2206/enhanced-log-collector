# Enhanced Log Collector Documentation

Welcome to the Enhanced Log Collector documentation. This system provides enterprise-grade logging for your applications and scripts.

## 📚 Documentation Index

### Getting Started
- [Installation Guide](installation.md) - How to install and set up the system
- [Quick Start](../README.md#quick-start) - Get running in 5 minutes

### Using the System
- [Usage Guide](usage.md) - Complete usage examples and patterns
- [Configuration Guide](configuration.md) - How to configure for your environment
- [API Reference](api.md) - Complete function and parameter reference

### Maintenance & Support
- [Troubleshooting](troubleshooting.md) - Common issues and solutions
- [Migration Guide](migration.md) - Upgrading from v1.0 to v2.0

## 🎯 Quick Links

### Common Tasks
- **Basic Logging**: See [Usage Guide - Basic Examples](usage.md#basic-examples)
- **JSON Output**: See [Usage Guide - Output Formats](usage.md#output-formats)
- **Email Alerts**: See [Configuration Guide - Alerts](configuration.md#email-alerts)
- **Log Rotation**: See [Configuration Guide - Rotation](configuration.md#log-rotation)

### Integration Examples
- **Bash Scripts**: [examples/basic_usage.sh](../examples/basic_usage.sh)
- **Python**: [examples/python_integration.py](../examples/python_integration.py)
- **Cron Jobs**: [examples/cron_example.sh](../examples/cron_example.sh)
- **Systemd**: [examples/systemd_example.service](../examples/systemd_example.service)

## 🔧 Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    Your Application                         │
│                  (Bash, Python, etc.)                       │
└────────────────────┬────────────────────────────────────────┘
                     │
                     │ Calls logCollector.sh
                     ▼
┌─────────────────────────────────────────────────────────────┐
│              Enhanced Log Collector                         │
│  ┌──────────┬──────────┬──────────┬──────────┐             │
│  │ Validate │  Format  │ Rotate   │  Output  │             │
│  │  Input   │   Log    │  Check   │  Write   │             │
│  └──────────┴──────────┴──────────┴──────────┘             │
└────┬────────┬────────┬────────┬────────┬────────┬──────────┘
     │        │        │        │        │        │
     ▼        ▼        ▼        ▼        ▼        ▼
  ┌────┐  ┌────┐  ┌────┐  ┌────┐  ┌────┐  ┌────┐
  │File│  │JSON│  │Cons│  │Sysl│  │Mail│  │Arch│
  │ Log│  │ Log│  │ole │  │og  │  │    │  │ive │
  └────┘  └────┘  └────┘  └────┘  └────┘  └────┘
```

## 📋 Features at a Glance

| Feature | Description | Docs |
|---------|-------------|------|
| **7 Log Levels** | DEBUG, INFO, NOTICE, WARNING, ERROR, CRITICAL, FATAL | [API](api.md#log-levels) |
| **Multiple Formats** | Plain text, JSON, Console, Syslog | [Usage](usage.md#output-formats) |
| **Auto Rotation** | Size and date-based rotation | [Config](configuration.md#rotation) |
| **Compression** | Automatic gzip compression | [Config](configuration.md#compression) |
| **Retention** | Configurable cleanup policies | [Config](configuration.md#retention) |
| **Email Alerts** | Notifications for critical events | [Config](configuration.md#email-alerts) |
| **Metadata** | Rich structured logging | [Usage](usage.md#metadata) |
| **Stack Traces** | Debug support | [Usage](usage.md#debugging) |

## 🚀 Version Information

**Current Version**: 2.0.0  
**Release Date**: January 4, 2026  
**License**: MIT  

## 💬 Support

- **Issues**: Contact DB Team at dba-team@example.com
- **Documentation**: This directory
- **Examples**: [../examples/](../examples/)

## 📝 Contributing

See [CONTRIBUTING.md](../CONTRIBUTING.md) for guidelines.

**Next**: [Installation Guide](installation.md) →




