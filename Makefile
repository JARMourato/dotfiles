# Makefile for macOS dotfiles development

.PHONY: lint test format install-deps setup-dev ci test-macos help plugins maintenance wizard health quick-start dependencies analytics sync

# Default target
help:
	@echo "🍎 macOS Dotfiles Development Commands"
	@echo "======================================"
	@echo "make install-deps  - Install development dependencies"
	@echo "make lint         - Run shellcheck on all scripts"
	@echo "make test         - Run unit tests"
	@echo "make test-macos   - Run macOS-specific tests"
	@echo "make format       - Format shell scripts"
	@echo "make ci           - Run all CI checks locally"
	@echo "make setup-dev    - Set up development environment"
	@echo ""
	@echo "🔧 System Management Commands"
	@echo "=============================="
	@echo "make quick-start  - Ultra-fast 30-second setup"
	@echo "make plugins      - Manage plugin system"
	@echo "make maintenance  - Run system maintenance"
	@echo "make wizard       - Launch setup wizard"
	@echo "make health       - Show system health dashboard"
	@echo "make dependencies - Smart dependency resolution"
	@echo "make analytics    - Usage analytics and optimization"
	@echo "make sync         - Multi-machine synchronization"

install-deps:
	@echo "📦 Installing macOS development dependencies..."
	@command -v brew >/dev/null 2>&1 || /bin/bash -c "$$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
	brew install shellcheck shfmt bats-core
	@echo "✅ Dependencies installed"

lint:
	@echo "🔍 Running shellcheck on all scripts..."
	@find . -name "*.sh" -not -path "./.git/*" | while read -r script; do \
		echo "Checking: $$script"; \
		shellcheck -s bash "$$script"; \
	done
	@echo "✅ Linting completed"

test:
	@echo "🧪 Running unit tests..."
	@if [ -d tests ]; then \
		bats tests/*.bats; \
	else \
		echo "No tests directory found"; \
	fi
	@echo "✅ Tests completed"

test-macos:
	@echo "🍎 Running macOS-specific tests..."
	@echo "macOS version: $$(sw_vers -productVersion)"
	@echo "Architecture: $$(uname -m)"
	@./bootstrap.sh "test_password" --minimal --dry-run
	@./Scripts/create_snapshot.sh "makefile_test" --quick
	@./Scripts/rollback.sh --list
	@echo "✅ macOS tests completed"

format:
	@echo "✨ Formatting shell scripts..."
	shfmt -w -i 4 Scripts/*.sh bootstrap.sh _set_up.sh
	@echo "✅ Formatting completed"

ci: lint test format
	@echo "🚀 Running all CI checks locally..."
	@./Scripts/manage_config.sh validate
	@echo "✅ All CI checks passed"

setup-dev:
	@echo "🛠️  Setting up macOS development environment..."
	@if [ ! -f .git/hooks/pre-commit ]; then \
		echo "Installing pre-commit hooks..."; \
		echo "#!/bin/bash" > .git/hooks/pre-commit; \
		echo "make lint" >> .git/hooks/pre-commit; \
		chmod +x .git/hooks/pre-commit; \
	fi
	@make install-deps
	@echo "✅ Development environment ready"

# Quick test for different setup modes
test-modes:
	@echo "🎯 Testing all setup modes..."
	@for mode in minimal dev-only work quick; do \
		echo "Testing $$mode mode..."; \
		./bootstrap.sh "test_password" --$$mode --dry-run; \
	done
	@echo "✅ All modes tested"

# Check macOS compatibility
check-macos:
	@echo "🍎 Checking macOS compatibility..."
	@echo "macOS version: $$(sw_vers -productVersion)"
	@echo "Architecture: $$(uname -m)"
	@if [ "$$(uname -m)" = "arm64" ]; then \
		echo "Apple Silicon detected"; \
		ls -la /opt/homebrew 2>/dev/null || echo "Homebrew not found at /opt/homebrew"; \
	else \
		echo "Intel Mac detected"; \
		ls -la /usr/local/Homebrew 2>/dev/null || echo "Homebrew not found at /usr/local"; \
	fi

# Update dependencies manually
update-deps:
	@echo "🔄 Checking for dependency updates..."
	@source Scripts/config_parser.sh && \
	load_dotfiles_config && \
	echo "Configured formulas: $$(get_homebrew_formulas)" && \
	echo "Configured casks: $$(get_homebrew_casks)"
	@brew update
	@brew outdated
	@echo "Run 'brew upgrade' to update packages"

# Clean up test artifacts
clean:
	@echo "🧹 Cleaning up test artifacts..."
	@rm -rf tests/test_config_* 2>/dev/null || true
	@rm -rf /tmp/test_snapshots_* 2>/dev/null || true
	@find ~/.dotfiles_snapshots -name "*makefile_test*" -type d -exec rm -rf {} + 2>/dev/null || true
	@echo "✅ Cleanup completed"

# Create a release snapshot
release-snapshot:
	@echo "📸 Creating release snapshot..."
	@./Scripts/create_snapshot.sh "release_$$(date +%Y%m%d)" --description "Release snapshot before changes"
	@echo "✅ Release snapshot created"

# Validate all configurations
validate-configs:
	@echo "🔍 Validating all configuration templates..."
	@for template in minimal developer work server; do \
		echo "Validating $$template template..."; \
		./Scripts/manage_config.sh create-template $$template; \
		./Scripts/manage_config.sh validate; \
		rm -f $$template.config; \
	done
	@echo "✅ All configurations validated"

# New system management commands
plugins:
	@echo "🔌 Plugin System Management"
	@echo "=========================="
	@./Scripts/plugin_manager.sh list
	@echo ""
	@echo "Available commands:"
	@echo "  make plugins-enable PLUGIN=name  - Enable a plugin"
	@echo "  make plugins-list                - List all plugins"
	@echo "  ./Scripts/plugin_manager.sh      - Full plugin manager"

plugins-list:
	@./Scripts/plugin_manager.sh list

plugins-enable:
	@./Scripts/plugin_manager.sh enable $(PLUGIN)

maintenance:
	@echo "🔧 Running system maintenance..."
	@./Scripts/automated_maintenance.sh --daily

wizard:
	@echo "🎯 Launching setup wizard..."
	@./Scripts/setup_wizard.sh --interactive

health:
	@echo "🩺 System Health Dashboard"
	@echo "========================="
	@./Scripts/health_monitor.sh check
	@echo ""
	@echo "Available commands:"
	@echo "  make health-dashboard   - Live dashboard"
	@echo "  make health-check       - One-time health check"
	@echo "  make health-fix         - Auto-fix issues"
	@echo "  ./Scripts/health_monitor.sh - Full health monitor"

health-dashboard:
	@./Scripts/health_monitor.sh dashboard

health-check:
	@./Scripts/health_monitor.sh report

health-fix:
	@./Scripts/health_monitor.sh auto-fix

quick-start:
	@echo "🚀 Ultra-Fast Quick Start Mode"
	@echo "=============================="
	@./Scripts/quick_start.sh run
	@echo ""
	@echo "Available commands:"
	@echo "  make quick-expand   - Add more tools after quick start"
	@echo "  ./Scripts/quick_start.sh - Full quick start manager"

quick-expand:
	@./Scripts/quick_start.sh --expand

dependencies:
	@echo "🔧 Smart Dependency Resolution"
	@echo "============================="
	@./Scripts/dependency_resolver.sh scan
	@echo ""
	@echo "Available commands:"
	@echo "  make deps-analyze    - Analyze missing dependencies"
	@echo "  make deps-resolve    - Install missing dependencies"
	@echo "  ./Scripts/dependency_resolver.sh - Full dependency manager"

deps-analyze:
	@./Scripts/dependency_resolver.sh analyze

deps-resolve:
	@./Scripts/dependency_resolver.sh resolve

analytics:
	@echo "📊 Usage Analytics and Optimization"
	@echo "==================================="
	@./Scripts/usage_analyzer.sh dashboard
	@echo ""
	@echo "Available commands:"
	@echo "  make analytics-init    - Initialize usage tracking"
	@echo "  make analytics-report  - Generate usage report"
	@echo "  ./Scripts/usage_analyzer.sh - Full analytics manager"

analytics-init:
	@./Scripts/usage_analyzer.sh init

analytics-report:
	@./Scripts/usage_analyzer.sh report

sync:
	@echo "🔄 Multi-Machine Synchronization"
	@echo "==============================="
	@./Scripts/machine_sync.sh status
	@echo ""
	@echo "Available commands:"
	@echo "  make sync-init     - Initialize sync system"
	@echo "  make sync-pull     - Pull configurations from other machines"
	@echo "  make sync-push     - Push configurations to other machines"
	@echo "  ./Scripts/machine_sync.sh - Full sync manager"

sync-init:
	@./Scripts/machine_sync.sh init

sync-pull:
	@./Scripts/machine_sync.sh pull

sync-push:
	@./Scripts/machine_sync.sh push

sync-profile:
	@./Scripts/machine_sync.sh profile $(filter-out $@,$(MAKECMDGOALS))