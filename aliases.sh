#!/bin/bash

# Dotfiles System Aliases
# Source this file to get convenient aliases for common Scripts/ commands

# Get the directory of this script
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# System Setup
alias setup-wizard="$DOTFILES_DIR/Scripts/setup_wizard.sh"
alias quick-start="$DOTFILES_DIR/Scripts/quick_start.sh"
alias setup-deps="$DOTFILES_DIR/Scripts/set_up_dependencies.sh"
alias setup-symlinks="$DOTFILES_DIR/Scripts/set_up_symlinks.sh"
alias setup-user-defaults="$DOTFILES_DIR/Scripts/set_up_user_defaults.sh"
alias setup-terminal="$DOTFILES_DIR/Terminal/set_up_terminal.sh"
alias setup-xcode="$DOTFILES_DIR/Xcode/set_up_xcode.sh"
alias setup-machine-settings="$DOTFILES_DIR/Scripts/set_up_machine_specific_settings.sh"

# Health Monitoring
alias health-monitor="$DOTFILES_DIR/Scripts/health_monitor.sh"
alias health-dashboard="$DOTFILES_DIR/Scripts/health_monitor.sh dashboard"
alias health-check="$DOTFILES_DIR/Scripts/health_monitor.sh check"
alias health-drift="$DOTFILES_DIR/Scripts/health_monitor.sh drift"
alias health-autofix="$DOTFILES_DIR/Scripts/health_monitor.sh auto-fix"
alias advanced-healing="$DOTFILES_DIR/Scripts/advanced_healing.sh"

# Multi-Machine Sync
alias machine-sync="$DOTFILES_DIR/Scripts/machine_sync.sh"
alias dotfiles-sync="$DOTFILES_DIR/Scripts/dotfiles_sync_with_remote.sh"
alias dotfiles-save="$DOTFILES_DIR/Scripts/dotfiles_save_changes.sh"

# Dependency Management
alias deps-resolve="$DOTFILES_DIR/Scripts/dependency_resolver.sh"
alias deps-scan="$DOTFILES_DIR/Scripts/dependency_resolver.sh scan"
alias deps-graph="$DOTFILES_DIR/Scripts/dependency_resolver.sh graph"

# Plugin Management
alias plugin-manager="$DOTFILES_DIR/Scripts/plugin_manager.sh"
alias plugin-init="$DOTFILES_DIR/Scripts/plugin_manager.sh init"
alias plugin-list="$DOTFILES_DIR/Scripts/plugin_manager.sh list"
alias plugin-enable="$DOTFILES_DIR/Scripts/plugin_manager.sh enable"
alias plugin-create="$DOTFILES_DIR/Scripts/plugin_manager.sh create"

# Usage Analytics
alias usage-analyzer="$DOTFILES_DIR/Scripts/usage_analyzer.sh"
alias usage-init="$DOTFILES_DIR/Scripts/usage_analyzer.sh init"
alias usage-dashboard="$DOTFILES_DIR/Scripts/usage_analyzer.sh dashboard"
alias usage-recommendations="$DOTFILES_DIR/Scripts/usage_analyzer.sh recommendations"

# Maintenance
alias auto-maintenance="$DOTFILES_DIR/Scripts/automated_maintenance.sh"
alias cleanup="$DOTFILES_DIR/Scripts/clean_up.sh"
alias track-system="$DOTFILES_DIR/Scripts/track_system_state.sh"

# Security Operations
alias encrypt-files="$DOTFILES_DIR/Scripts/encrypt_files.sh"
alias decrypt-files="$DOTFILES_DIR/Scripts/decrypt_files.sh"
alias rotate-secrets="$DOTFILES_DIR/Scripts/rotate_secrets.sh"
alias check-secrets-age="$DOTFILES_DIR/Scripts/check_secrets_age.sh"

# Keychain-enabled encryption shortcuts
alias setup-encryption="$DOTFILES_DIR/Scripts/encrypt_files.sh --setup-keychain"
alias encrypt="$DOTFILES_DIR/Scripts/encrypt_files.sh"
alias decrypt="$DOTFILES_DIR/Scripts/decrypt_files.sh"

# Development Tools
alias create-snapshot="$DOTFILES_DIR/Scripts/create_snapshot.sh"
alias create-spm-package="$DOTFILES_DIR/Scripts/create_spm_package.sh"
alias git-commit="$DOTFILES_DIR/Scripts/git_commit.sh"
alias backup-github="$DOTFILES_DIR/Scripts/backup-github.sh"
alias git-repo-setup="$DOTFILES_DIR/Scripts/git_repo_setup.sh"

# Configuration Management
alias manage-config="$DOTFILES_DIR/Scripts/manage_config.sh"
alias config-parser="$DOTFILES_DIR/Scripts/config_parser.sh"
alias compare-inventories="$DOTFILES_DIR/Scripts/compare_inventories.sh"

# System Utilities
alias parallel-ops="$DOTFILES_DIR/Scripts/parallel_operations.sh"
alias cache-utils="$DOTFILES_DIR/Scripts/cache_utils.sh"
alias caching-system="$DOTFILES_DIR/Scripts/caching_system.sh"
alias progress-indicators="$DOTFILES_DIR/Scripts/progress_indicators.sh"
alias rollback="$DOTFILES_DIR/Scripts/rollback.sh"

# Project bootstrapping
alias bootstrap-project="$DOTFILES_DIR/Scripts/bootstrap_project.sh"
alias bootstrap="bootstrap-project"  # Short alias for convenience
alias create-private-bootstrap="$DOTFILES_DIR/Scripts/create_private_bootstrap.sh"

# Add these aliases to your shell configuration
echo "Dotfiles aliases loaded. Available commands:"
echo "  Setup: setup-wizard, quick-start, setup-deps, setup-symlinks"
echo "  Health: health-dashboard, health-check, advanced-healing"
echo "  Sync: machine-sync, dotfiles-sync"
echo "  Dependencies: deps-scan, deps-resolve, deps-graph"
echo "  Plugins: plugin-init, plugin-list, plugin-enable, plugin-create"
echo "  Analytics: usage-dashboard, usage-recommendations"
echo "  Security: encrypt-files, decrypt-files, rotate-secrets"
echo "  Development: create-snapshot, git-commit, backup-github"
echo ""
echo "To permanently enable these aliases, add this to your ~/.zshrc or ~/.bashrc:"
echo "  source $DOTFILES_DIR/aliases.sh"