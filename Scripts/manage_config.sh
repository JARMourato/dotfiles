#!/bin/bash

set -euo pipefail

################################################################################
### Configuration Management Tool
################################################################################

# Show help documentation
show_help() {
    cat << 'EOF'
📖 manage_config.sh - Manage dotfiles configuration settings

DESCRIPTION:
    Provides easy management of .dotfiles.config settings including validation,
    mode switching, and configuration templates for different use cases.

USAGE:
    manage_config.sh <command> [options]
    manage_config.sh --help

COMMANDS:
    show                    Display current configuration
    validate                Check configuration for errors
    set <key> <value>       Set a configuration value
    get <key>               Get a configuration value
    create-template <type>  Create configuration template
    switch-mode <mode>      Preview configuration for setup mode
    backup                  Backup current configuration
    restore <backup>        Restore from backup

TEMPLATE TYPES:
    minimal                 Minimal installation template
    developer               Full development environment
    work                    Corporate/work-friendly setup
    server                  Headless server setup

SETUP MODES:
    minimal                 Only essential command-line tools
    dev-only                Development tools, no entertainment apps
    work                    Corporate setup, skip personal apps
    quick                   Fast setup, skip time-consuming parts

EXAMPLES:
    # Show current config
    manage_config.sh show
    
    # Create minimal template
    manage_config.sh create-template minimal
    
    # Set configuration value
    manage_config.sh set SKIP_XCODE true
    
    # Preview work mode configuration
    manage_config.sh switch-mode work
    
    # Backup current config
    manage_config.sh backup

SEE ALSO:
    bootstrap.sh - Use configuration during setup
    config_parser.sh - Configuration parsing library

EOF
}

# Configuration management functions
DOTFILES_DIR="${DOTFILES_DIR:-$(pwd)}"
CONFIG_FILE="${DOTFILES_DIR}/.dotfiles.config"
BACKUP_DIR="${DOTFILES_DIR}/.config_backups"

# Source configuration parser
if [ -f "${DOTFILES_DIR}/Scripts/config_parser.sh" ]; then
    source "${DOTFILES_DIR}/Scripts/config_parser.sh"
fi

# Show current configuration
show_current_config() {
    echo "📋 Current Dotfiles Configuration"
    echo "=================================="
    echo ""
    
    if [ ! -f "$CONFIG_FILE" ]; then
        echo "❌ Configuration file not found: $CONFIG_FILE"
        echo "Use 'create-template' command to create one"
        return 1
    fi
    
    echo "📁 Config file: $CONFIG_FILE"
    echo "📅 Last modified: $(stat -f %Sm "$CONFIG_FILE" 2>/dev/null || date)"
    echo ""
    
    # Load and show config using parser
    if command -v show_config >/dev/null 2>&1; then
        load_dotfiles_config "$CONFIG_FILE"
        show_config
    else
        echo "Configuration contents:"
        echo "======================"
        grep -E '^[A-Z_]+=' "$CONFIG_FILE" | head -20
        echo ""
        local total_settings=$(grep -c '^[A-Z_]+=' "$CONFIG_FILE")
        echo "Total settings: $total_settings"
    fi
}

# Validate configuration
validate_current_config() {
    echo "🔍 Validating Configuration"
    echo "==========================="
    echo ""
    
    if [ ! -f "$CONFIG_FILE" ]; then
        echo "❌ Configuration file not found: $CONFIG_FILE"
        return 1
    fi
    
    if command -v validate_config >/dev/null 2>&1; then
        load_dotfiles_config "$CONFIG_FILE"
        validate_config
    else
        echo "⚠️  Configuration parser not available"
        echo "Basic syntax check:"
        
        # Basic syntax validation
        local errors=0
        while IFS= read -r line; do
            if [[ $line =~ ^[A-Z_]+= ]] && [[ ! $line =~ ^[A-Z_]+=\".*\"$ ]] && [[ ! $line =~ ^[A-Z_]+=[a-zA-Z0-9_\ ]*$ ]]; then
                echo "❌ Syntax error: $line"
                errors=$((errors + 1))
            fi
        done < "$CONFIG_FILE"
        
        if [ $errors -eq 0 ]; then
            echo "✅ Basic syntax validation passed"
        else
            echo "❌ Found $errors syntax errors"
            return 1
        fi
    fi
}

# Set configuration value
set_config_value() {
    local key="$1"
    local value="$2"
    
    if [ ! -f "$CONFIG_FILE" ]; then
        echo "❌ Configuration file not found: $CONFIG_FILE"
        return 1
    fi
    
    echo "🔧 Setting configuration: $key=$value"
    
    # Backup current config
    cp "$CONFIG_FILE" "${CONFIG_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
    
    # Update or add the setting
    if grep -q "^${key}=" "$CONFIG_FILE"; then
        # Update existing setting
        if [[ "$OSTYPE" == "darwin"* ]]; then
            sed -i '' "s/^${key}=.*/${key}=\"${value}\"/" "$CONFIG_FILE"
        else
            sed -i "s/^${key}=.*/${key}=\"${value}\"/" "$CONFIG_FILE"
        fi
        echo "✅ Updated: $key=$value"
    else
        # Add new setting
        echo "${key}=\"${value}\"" >> "$CONFIG_FILE"
        echo "✅ Added: $key=$value"
    fi
}

# Get configuration value
get_config_value() {
    local key="$1"
    
    if [ ! -f "$CONFIG_FILE" ]; then
        echo "❌ Configuration file not found: $CONFIG_FILE"
        return 1
    fi
    
    local value=$(grep "^${key}=" "$CONFIG_FILE" | cut -d'=' -f2- | tr -d '"')
    if [ -n "$value" ]; then
        echo "$key=$value"
    else
        echo "❌ Setting not found: $key"
        return 1
    fi
}

# Create configuration template
create_config_template() {
    local template_type="$1"
    local output_file="${2:-$CONFIG_FILE}"
    
    echo "📝 Creating $template_type configuration template"
    
    # Backup existing config if it exists
    if [ -f "$output_file" ]; then
        local backup_file="${output_file}.backup.$(date +%Y%m%d_%H%M%S)"
        cp "$output_file" "$backup_file"
        echo "📦 Backed up existing config to: $backup_file"
    fi
    
    case "$template_type" in
        minimal)
            create_minimal_template "$output_file"
            ;;
        developer)
            create_developer_template "$output_file"
            ;;
        work)
            create_work_template "$output_file"
            ;;
        server)
            create_server_template "$output_file"
            ;;
        *)
            echo "❌ Unknown template type: $template_type"
            echo "Available types: minimal, developer, work, server"
            return 1
            ;;
    esac
    
    echo "✅ Template created: $output_file"
    echo "💡 Edit the file to customize your setup"
}

# Create minimal template
create_minimal_template() {
    local output_file="$1"
    
    cat > "$output_file" << 'EOF'
# Minimal Dotfiles Configuration
# Only essential command-line tools, no GUI applications

# Skip major installation categories
SKIP_XCODE=true
SKIP_MAS_APPS=true
SKIP_RUBY_INSTALL=true
SKIP_PYTHON_INSTALL=true

# Minimal package set
CORE_PACKAGES="git age jq"
HOMEBREW_FORMULAS=""
HOMEBREW_CASKS=""
QUICKLOOK_PLUGINS=""
MAS_APPS=""

# Security settings
ENCRYPTION_METHOD="age"
ROTATION_WARNING_DAYS=90
ROTATION_URGENT_DAYS=180

# Disable powerline for faster setup
SETUP_POWERLINE=false

# Quick mode settings
MINIMAL_PACKAGES=true
EOF
}

# Create developer template
create_developer_template() {
    local output_file="$1"
    
    # Copy the default configuration and modify for developer use
    cp "${DOTFILES_DIR}/.dotfiles.config" "$output_file" 2>/dev/null || cat > "$output_file" << 'EOF'
# Developer Dotfiles Configuration
# Full development environment with all tools

# Enable all installations
SKIP_XCODE=false
SKIP_HOMEBREW=false
SKIP_MAS_APPS=false
SKIP_RUBY_INSTALL=false
SKIP_PYTHON_INSTALL=false

# Full development package set
CORE_PACKAGES="age git jq"
HOMEBREW_FORMULAS="aria2 gh hub ktlint make mas pyenv python rbenv ruby swiftformat swiftlint docker node npm yarn"
HOMEBREW_CASKS="visual-studio-code android-studio sourcetree docker sublime-text"
QUICKLOOK_PLUGINS="qlcolorcode qlmarkdown qlstephen quicklook-json"
MAS_APPS="904280696:Things_3"

# Developer-specific settings
DEV_TOOLS_ONLY=true
SETUP_POWERLINE=true
ENCRYPTION_METHOD="age"
EOF
}

# Create work template
create_work_template() {
    local output_file="$1"
    
    cat > "$output_file" << 'EOF'
# Work/Corporate Dotfiles Configuration
# Corporate-friendly setup, no personal apps

# Standard installations
SKIP_XCODE=false
SKIP_MAS_APPS=true
SKIP_RUBY_INSTALL=false
SKIP_PYTHON_INSTALL=false

# Work-appropriate packages
CORE_PACKAGES="age git jq"
HOMEBREW_FORMULAS="gh hub mas docker node"
HOMEBREW_CASKS="google-chrome visual-studio-code microsoft-teams slack zoom"
QUICKLOOK_PLUGINS="qlmarkdown quicklook-json"
MAS_APPS=""

# Skip personal apps
SKIP_PACKAGES="spotify telegram whatsapp iina"
WORK_MODE=true

# Security settings
ENCRYPTION_METHOD="age"
ROTATION_WARNING_DAYS=60
ROTATION_URGENT_DAYS=120
EOF
}

# Create server template
create_server_template() {
    local output_file="$1"
    
    cat > "$output_file" << 'EOF'
# Server/Headless Dotfiles Configuration
# Command-line only, no GUI applications

# Skip all GUI installations
SKIP_XCODE=true
SKIP_MAS_APPS=true
SKIP_TERMINAL_SETUP=true

# Server-appropriate packages only
CORE_PACKAGES="age git jq"
HOMEBREW_FORMULAS="gh hub make python node"
HOMEBREW_CASKS=""
QUICKLOOK_PLUGINS=""
MAS_APPS=""

# Server settings
MINIMAL_PACKAGES=true
SETUP_POWERLINE=false
DEFAULT_SHELL="bash"

# Security settings
ENCRYPTION_METHOD="age"
AUTO_SNAPSHOT=true
EOF
}

# Preview mode configuration
preview_mode_config() {
    local mode="$1"
    
    echo "🎯 Preview: $mode Mode Configuration"
    echo "====================================="
    echo ""
    
    if [ ! -f "$CONFIG_FILE" ]; then
        echo "❌ Configuration file not found: $CONFIG_FILE"
        return 1
    fi
    
    # Load config and apply mode
    if command -v init_config >/dev/null 2>&1; then
        echo "Loading base configuration..."
        load_dotfiles_config "$CONFIG_FILE"
        
        echo "Applying $mode mode overrides..."
        set_setup_mode "$mode"
        
        echo ""
        show_config
    else
        echo "⚠️  Configuration parser not available"
        echo "Cannot preview mode-specific settings"
    fi
}

# Backup configuration
backup_config() {
    if [ ! -f "$CONFIG_FILE" ]; then
        echo "❌ Configuration file not found: $CONFIG_FILE"
        return 1
    fi
    
    mkdir -p "$BACKUP_DIR"
    local backup_file="$BACKUP_DIR/config_backup_$(date +%Y%m%d_%H%M%S).config"
    
    cp "$CONFIG_FILE" "$backup_file"
    echo "📦 Configuration backed up to: $backup_file"
    
    # List recent backups
    echo ""
    echo "Recent backups:"
    ls -la "$BACKUP_DIR" | tail -5
}

# Restore configuration
restore_config() {
    local backup_file="$1"
    
    if [ ! -f "$backup_file" ]; then
        echo "❌ Backup file not found: $backup_file"
        echo ""
        echo "Available backups:"
        if [ -d "$BACKUP_DIR" ]; then
            ls -la "$BACKUP_DIR"
        else
            echo "No backups found"
        fi
        return 1
    fi
    
    # Backup current config before restore
    if [ -f "$CONFIG_FILE" ]; then
        cp "$CONFIG_FILE" "${CONFIG_FILE}.before_restore.$(date +%Y%m%d_%H%M%S)"
    fi
    
    cp "$backup_file" "$CONFIG_FILE"
    echo "✅ Configuration restored from: $backup_file"
}

# Main function
main() {
    local command="${1:-}"
    
    case "$command" in
        show)
            show_current_config
            ;;
        validate)
            validate_current_config
            ;;
        set)
            if [ $# -lt 3 ]; then
                echo "❌ Usage: manage_config.sh set <key> <value>"
                exit 1
            fi
            set_config_value "$2" "$3"
            ;;
        get)
            if [ $# -lt 2 ]; then
                echo "❌ Usage: manage_config.sh get <key>"
                exit 1
            fi
            get_config_value "$2"
            ;;
        create-template)
            if [ $# -lt 2 ]; then
                echo "❌ Usage: manage_config.sh create-template <type>"
                echo "Types: minimal, developer, work, server"
                exit 1
            fi
            create_config_template "$2"
            ;;
        switch-mode)
            if [ $# -lt 2 ]; then
                echo "❌ Usage: manage_config.sh switch-mode <mode>"
                echo "Modes: minimal, dev-only, work, quick"
                exit 1
            fi
            preview_mode_config "$2"
            ;;
        backup)
            backup_config
            ;;
        restore)
            if [ $# -lt 2 ]; then
                echo "❌ Usage: manage_config.sh restore <backup_file>"
                exit 1
            fi
            restore_config "$2"
            ;;
        --help|-h)
            show_help
            ;;
        "")
            echo "❌ Command required"
            echo "Use --help for usage information"
            exit 1
            ;;
        *)
            echo "❌ Unknown command: $command"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
}

# Execute main function with all arguments
main "$@"