#!/bin/bash

set -euo pipefail

# Add debug trap to see where script exits
trap 'echo "❌ Script exited at line $LINENO with exit code $?" >&2' ERR
trap 'echo "🔍 DEBUG: Executing line $LINENO: $BASH_COMMAND" >&2' DEBUG

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
EOF
}

################################################################################
### Argument Processing
################################################################################

ENCRYPTION_PASSWORD="$1"

if [ "$ENCRYPTION_PASSWORD" = "--help" ] || [ -z "$ENCRYPTION_PASSWORD" ]; then
    show_help
    exit 0
fi

################################################################################
### Performance Libraries
################################################################################

# Load performance libraries for better UX
load_performance_libraries() {
    DOTFILES_DIR="${DOTFILES_DIR:-$(pwd)}"
    DOTFILES_CONFIG_FILE="${DOTFILES_DIR}/.dotfiles.config"
    
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

################################################################################
### Main Setup Process
################################################################################

echo "🔧 Starting dotfiles setup process..."

echo "📋 Loading configuration from: $DOTFILES_CONFIG_FILE"
if [ -f Scripts/config_parser.sh ]; then
    source Scripts/config_parser.sh
    load_dotfiles_config
    echo "✅ Configuration loaded successfully"
else
    echo "⚠️  Configuration parser not found, using defaults"
fi
echo "📋 Configuration loaded and applied"

echo "📝 Loading exports..."
source .exports

echo "🔗 Setting up symlinks..."
if command -v run_with_spinner >/dev/null 2>&1; then
    run_with_spinner "source Scripts/set_up_symlinks.sh" "Setting up symlinks"
    echo "✅ Setting up symlinks completed"
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
    run_with_spinner "source Scripts/decrypt_files.sh '$ENCRYPTION_PASSWORD'" "Decrypting sensitive files"
    echo "✅ File decryption completed"
else
    source Scripts/decrypt_files.sh "$ENCRYPTION_PASSWORD"
fi

echo "⚙️  Configuring system defaults..."
if command -v run_with_spinner >/dev/null 2>&1; then
    run_with_spinner "source Scripts/set_up_user_defaults.sh" "Configuring system defaults"
    echo "✅ System defaults configured"
else
    source Scripts/set_up_user_defaults.sh
fi

echo "🖥️  Setting up terminal..."
if command -v run_with_spinner >/dev/null 2>&1; then
    run_with_spinner "source Terminal/set_up_terminal.sh" "Configuring terminal"
    echo "✅ Terminal setup completed"
else
    source Terminal/set_up_terminal.sh
fi

echo "🔧 Configuring machine-specific settings..."
if command -v run_with_spinner >/dev/null 2>&1; then
    run_with_spinner "source Scripts/set_up_machine_specific_settings.sh" "Configuring machine settings"
    echo "✅ Machine-specific settings configured"
else
    source Scripts/set_up_machine_specific_settings.sh
fi

echo "🧹 Running cleanup..."
if command -v run_with_spinner >/dev/null 2>&1; then
    run_with_spinner "source Scripts/clean_up.sh" "Running cleanup"
    echo "✅ Cleanup completed"
else
    source Scripts/clean_up.sh
fi

echo "🎉 Dotfiles setup completed successfully!"