.PHONY: help install uninstall test clean dev-setup validate package

# Variables
VERSION := $(shell cat VERSION)
PREFIX := /opt/scripts
CONFIG_DIR := /etc
LOG_DIR := /var/log
INSTALL_USER := root
INSTALL_GROUP := root

# Colors
GREEN := \033[0;32m
YELLOW := \033[0;33m
RED := \033[0;31m
NC := \033[0m # No Color

help: ## Show this help message
	@echo "$(GREEN)Enhanced Log Collector v$(VERSION)$(NC)"
	@echo ""
	@echo "Available targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(GREEN)%-15s$(NC) %s\n", $$1, $$2}'

install: validate ## Install the log collector system
	@echo "$(GREEN)Installing Enhanced Log Collector v$(VERSION)...$(NC)"
	@chmod +x scripts/install.sh
	@sudo scripts/install.sh
	@echo "$(GREEN)✓ Installation complete$(NC)"

uninstall: ## Uninstall the log collector system
	@echo "$(YELLOW)Uninstalling Enhanced Log Collector...$(NC)"
	@chmod +x scripts/uninstall.sh
	@sudo scripts/uninstall.sh
	@echo "$(GREEN)✓ Uninstall complete$(NC)"

upgrade: ## Upgrade from previous version
	@echo "$(GREEN)Upgrading Enhanced Log Collector to v$(VERSION)...$(NC)"
	@chmod +x scripts/upgrade.sh
	@sudo scripts/upgrade.sh
	@echo "$(GREEN)✓ Upgrade complete$(NC)"

test: ## Run all tests
	@echo "$(GREEN)Running test suite...$(NC)"
	@chmod +x tests/run_all_tests.sh
	@./tests/run_all_tests.sh
	@echo "$(GREEN)✓ All tests passed$(NC)"

test-basic: ## Run basic functionality tests
	@echo "$(GREEN)Running basic tests...$(NC)"
	@chmod +x tests/test_basic.sh
	@./tests/test_basic.sh

test-rotation: ## Run rotation tests
	@echo "$(GREEN)Running rotation tests...$(NC)"
	@chmod +x tests/test_rotation.sh
	@./tests/test_rotation.sh

test-compression: ## Run compression tests
	@echo "$(GREEN)Running compression tests...$(NC)"
	@chmod +x tests/test_compression.sh
	@./tests/test_compression.sh

validate: ## Validate script syntax and dependencies
	@echo "$(GREEN)Validating installation...$(NC)"
	@chmod +x scripts/validate.sh
	@./scripts/validate.sh
	@echo "$(GREEN)✓ Validation complete$(NC)"

dev-setup: ## Setup development environment
	@echo "$(GREEN)Setting up development environment...$(NC)"
	@chmod +x scripts/setup-env.sh
	@./scripts/setup-env.sh
	@echo "$(GREEN)✓ Development environment ready$(NC)"

clean: ## Clean temporary and generated files
	@echo "$(YELLOW)Cleaning temporary files...$(NC)"
	@rm -rf tests/output/
	@find . -name "*.log" -type f -delete
	@find . -name "*.log.gz" -type f -delete
	@find . -name "*.tmp" -type f -delete
	@find . -name "*~" -type f -delete
	@echo "$(GREEN)✓ Cleanup complete$(NC)"

package: clean ## Create distribution package
	@echo "$(GREEN)Creating distribution package...$(NC)"
	@mkdir -p dist
	@tar -czf dist/enhanced-log-collector-$(VERSION).tar.gz \
		--exclude='.git' \
		--exclude='dist' \
		--exclude='*.log*' \
		--exclude='tests/output' \
		.
	@echo "$(GREEN)✓ Package created: dist/enhanced-log-collector-$(VERSION).tar.gz$(NC)"

health-check: ## Run system health check
	@echo "$(GREEN)Running health check...$(NC)"
	@chmod +x tools/health_check.sh
	@sudo tools/health_check.sh

analyze-logs: ## Analyze logs with built-in analyzer
	@echo "$(GREEN)Analyzing logs...$(NC)"
	@chmod +x tools/log_analyzer.sh
	@./tools/log_analyzer.sh

cleanup-logs: ## Clean old logs according to retention policy
	@echo "$(YELLOW)Cleaning old logs...$(NC)"
	@chmod +x tools/cleanup.sh
	@sudo tools/cleanup.sh
	@echo "$(GREEN)✓ Log cleanup complete$(NC)"

migrate: ## Migrate from v1.0 to v2.0
	@echo "$(GREEN)Migrating from v1.0 to v2.0...$(NC)"
	@chmod +x tools/migrate_v1_to_v2.sh
	@sudo tools/migrate_v1_to_v2.sh
	@echo "$(GREEN)✓ Migration complete$(NC)"

show-config: ## Display current configuration
	@echo "$(GREEN)Current Configuration:$(NC)"
	@if [ -f $(CONFIG_DIR)/logCollector.conf ]; then \
		cat $(CONFIG_DIR)/logCollector.conf; \
	else \
		echo "$(RED)No configuration file found at $(CONFIG_DIR)/logCollector.conf$(NC)"; \
	fi

show-version: ## Display version information
	@echo "Enhanced Log Collector v$(VERSION)"

check-deps: ## Check for required dependencies
	@echo "$(GREEN)Checking dependencies...$(NC)"
	@command -v bash >/dev/null 2>&1 || echo "$(RED)✗ bash not found$(NC)"
	@command -v gzip >/dev/null 2>&1 || echo "$(RED)✗ gzip not found$(NC)"
	@command -v logger >/dev/null 2>&1 || echo "$(YELLOW)⚠ logger not found (syslog will be disabled)$(NC)"
	@command -v mail >/dev/null 2>&1 || echo "$(YELLOW)⚠ mail not found (email alerts will be disabled)$(NC)"
	@echo "$(GREEN)✓ Dependency check complete$(NC)"

.DEFAULT_GOAL := help
