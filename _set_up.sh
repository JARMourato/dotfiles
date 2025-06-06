#!/bin/bash

set -euo pipefail

################################################################################
### Help Documentation
################################################################################

show_help() {
    cat << 'EOF'
📖 _set_up.sh - Main dotfiles configuration orchestrator

DESCRIPTION:
    Orchestrates the complete dotfiles setup process in the correct order.
    Typically called automatically by bootstrap.sh after repository clone.

USAGE:
    _set_up.sh <encryption_password>
    _set_up.sh --help

ARGUMENTS:
    encryption_password    Password for decrypting sensitive dotfiles

SETUP PROCESS:
    1. Load environment exports and variables
    2. Create symbolic links to dotfiles
    3. Install dependencies (Homebrew, packages, apps)
    4. Reload environment with new tools
    5. Decrypt encrypted sensitive files
    6. Configure system defaults and preferences
    7. Set up terminal appearance and shell
    8. Apply machine-specific settings
    9. Clean up temporary files
    10. Check secrets rotation status
    11. Create system state inventory

REQUIREMENTS:
    • Must be run from within the dotfiles repository
    • Requires valid encryption password
    • Internet connection for package installations

EXAMPLES:
    _set_up.sh "my_encryption_password"

NOTE:
    This script is usually called automatically by bootstrap.sh.
    Manual execution is only needed for re-setup or updates.

EOF
}

################################################################################
### Set up everything in the correct order
################################################################################

# Check for help flag
if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
    show_help
    exit 0
fi

if [ $# -eq 0 ]; then
   echo "Encryption password missing"
   echo "Use --help for usage information"
   exit 1
fi

echo "🔧 Starting dotfiles setup process..."

# Load performance libraries
load_performance_libraries() {
    # Load progress indicators
    if [ -f "Scripts/progress_indicators.sh" ]; then
        source Scripts/progress_indicators.sh
        echo "📊 Loaded progress indicators"
    fi
    
    # Load caching system
    if [ -f "Scripts/caching_system.sh" ]; then
        source Scripts/caching_system.sh
        init_cache
        echo "💾 Initialized caching system"
    fi
    
    # Load progress indicators for better UX
    if [ -f "Scripts/progress_indicators.sh" ]; then
        source Scripts/progress_indicators.sh
        echo "📊 Loaded progress indicators"
    fi
}

# Load performance libraries
load_performance_libraries

# Initialize configuration system
export DOTFILES_DIR="$(pwd)"
if [ -f Scripts/config_parser.sh ]; then
    source Scripts/config_parser.sh
    if [ "${DOTFILES_CONFIG_LOADED:-false}" = false ]; then
        load_dotfiles_config
        export_config_vars
    fi
    echo "📋 Configuration loaded and applied"
else
    echo "⚠️  Configuration parser not found, using defaults"
fi

echo "📝 Loading exports..."
source .exports

echo "🔗 Setting up symlinks..."
if command -v run_with_spinner >/dev/null 2>&1; then
    run_with_spinner "source Scripts/set_up_symlinks.sh" "Setting up symlinks"
else
    source Scripts/set_up_symlinks.sh
fi

echo "📦 Installing dependencies..."
source Scripts/set_up_dependencies.sh

echo "♻️  Reloading exports after dependency installation..."
# Must be run again after installing dependencies to apply changes
source .exports
source .zshrc

echo "🔓 Decrypting files..."
if command -v run_with_spinner >/dev/null 2>&1; then
    run_with_spinner "source Scripts/decrypt_files.sh $1" "Decrypting sensitive files"
else
    source Scripts/decrypt_files.sh $1
fi

echo "⚙️  Configuring user defaults..."
if command -v run_with_spinner >/dev/null 2>&1; then
    run_with_spinner "source Scripts/set_up_user_defaults.sh" "Configuring user defaults"
else
    source Scripts/set_up_user_defaults.sh
fi

echo "🖥️  Setting up terminal..."
if command -v run_with_spinner >/dev/null 2>&1; then
    run_with_spinner "source Terminal/set_up_terminal.sh" "Setting up terminal"
else
    source Terminal/set_up_terminal.sh
fi

echo "🔧 Applying machine-specific settings..."
source Scripts/set_up_machine_specific_settings.sh

echo "🧹 Cleaning up..."
source Scripts/clean_up.sh

echo "🔐 Checking secrets rotation status..."
source Scripts/check_secrets_age.sh || true

echo "📋 Creating system inventory..."
source Scripts/track_system_state.sh --output "$HOME/.dotfiles_inventory.json" || true

echo "✅ Setup completed successfully!"

# Show cache statistics if available
if command -v show_cache_stats >/dev/null 2>&1; then
    echo ""
    show_cache_stats
fi

# Clean up cache if it's getting large
if command -v cleanup_cache >/dev/null 2>&1; then
    echo ""
    cleanup_cache
fi
