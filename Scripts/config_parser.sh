#!/bin/bash

################################################################################
### Dotfiles Configuration Parser Library
################################################################################

# This file provides functions to parse and apply .dotfiles.config settings
# Source this file to use the configuration functions

# Only set strict mode if running directly, not when sourced
if [ "${BASH_SOURCE[0]:-}" = "${0:-}" ]; then
    set -euo pipefail
fi

# Global configuration variables - bash 3.2 compatible
declare -a DOTFILES_CONFIG_KEYS=()
declare -a DOTFILES_CONFIG_VALUES=()
DOTFILES_CONFIG_LOADED=false
DOTFILES_SETUP_MODE=""

# Default configuration file path
DOTFILES_CONFIG_FILE="${DOTFILES_DIR:-$(pwd)}/.dotfiles.config"

################################################################################
### Helper Functions for bash 3.2 Compatibility
################################################################################

# Set configuration value
set_config() {
    local key="$1"
    local value="$2"
    local i
    
    # Check if key already exists
    for ((i=0; i<${#DOTFILES_CONFIG_KEYS[@]}; i++)); do
        if [ "${DOTFILES_CONFIG_KEYS[i]}" = "$key" ]; then
            DOTFILES_CONFIG_VALUES[i]="$value"
            return 0
        fi
    done
    
    # Add new key-value pair
    DOTFILES_CONFIG_KEYS+=("$key")
    DOTFILES_CONFIG_VALUES+=("$value")
}

# Get configuration value with default fallback
get_config() {
    local key="$1"
    local default_value="${2:-}"
    local i
    
    if [ "$DOTFILES_CONFIG_LOADED" = false ]; then
        load_dotfiles_config
    fi
    
    for ((i=0; i<${#DOTFILES_CONFIG_KEYS[@]}; i++)); do
        if [ "${DOTFILES_CONFIG_KEYS[i]}" = "$key" ]; then
            local value="${DOTFILES_CONFIG_VALUES[i]}"
            # Expand variables in the value
            value=$(expand_config_variables "$value")
            echo "$value"
            return 0
        fi
    done
    
    echo "$default_value"  # Return default if not found
}

# Expand variables in configuration values
expand_config_variables() {
    local value="$1"
    local expanded_value="$value"
    
    # Handle $BASE_HOMEBREW_FORMULAS expansion
    if [[ "$expanded_value" == *'$BASE_HOMEBREW_FORMULAS'* ]]; then
        local base_formulas=$(get_config_raw "BASE_HOMEBREW_FORMULAS")
        expanded_value="${expanded_value//\$BASE_HOMEBREW_FORMULAS/$base_formulas}"
    fi
    
    echo "$expanded_value"
}

# Get config value without expansion (to avoid infinite recursion)
get_config_raw() {
    local key="$1"
    local i
    
    for ((i=0; i<${#DOTFILES_CONFIG_KEYS[@]}; i++)); do
        if [ "${DOTFILES_CONFIG_KEYS[i]}" = "$key" ]; then
            echo "${DOTFILES_CONFIG_VALUES[i]}"
            return 0
        fi
    done
}

################################################################################
### Configuration Loading Functions
################################################################################

# Load configuration from file
load_dotfiles_config() {
    local config_file="${1:-$DOTFILES_CONFIG_FILE}"
    
    if [ ! -f "$config_file" ]; then
        echo "⚠️  Configuration file not found: $config_file"
        echo "Using default settings..."
        return 0
    fi
    
    echo "📋 Loading configuration from: $config_file"
    
    # Parse configuration file (skip comments and empty lines)
    while IFS='=' read -r key value; do
        # Skip comments and empty lines
        [[ $key =~ ^[[:space:]]*# ]] && continue
        [[ -z $key ]] && continue
        
        # Remove leading/trailing whitespace
        key=$(echo "$key" | xargs)
        value=$(echo "$value" | xargs)
        
        # Remove quotes from value if present
        value="${value%\"}"
        value="${value#\"}"
        
        # Store in configuration arrays
        set_config "$key" "$value"
    done < <(grep -E '^[^#]*=' "$config_file" || true)
    
    DOTFILES_CONFIG_LOADED=true
    echo "✅ Configuration loaded successfully"
}


# Check if configuration value is true
config_is_true() {
    local key="$1"
    local value=$(get_config "$key" "false")
    [[ "$value" =~ ^(true|True|TRUE|yes|Yes|YES|1)$ ]]
}

# Check if configuration value is false
config_is_false() {
    local key="$1"
    local value=$(get_config "$key" "true")
    [[ "$value" =~ ^(false|False|FALSE|no|No|NO|0)$ ]]
}

################################################################################
### Setup Mode Functions
################################################################################

# Set setup mode and apply mode-specific overrides
set_setup_mode() {
    local mode="$1"
    DOTFILES_SETUP_MODE="$mode"
    
    echo "🎯 Setting up in $mode mode..."
    
    case "$mode" in
        minimal)
            apply_minimal_mode_config
            ;;
        dev-only)
            apply_dev_mode_config
            ;;
        work)
            apply_work_mode_config
            ;;
        quick)
            apply_quick_mode_config
            ;;
        *)
            echo "⚠️  Unknown setup mode: $mode"
            ;;
    esac
}

# Apply minimal mode configuration
apply_minimal_mode_config() {
    echo "🔧 Applying minimal mode overrides..."
    
    # Override package lists
    set_config "HOMEBREW_FORMULAS" "$(get_config "MINIMAL_MODE_PACKAGES" "age git jq")"
    set_config "HOMEBREW_CASKS" ""
    set_config "QUICKLOOK_PLUGINS" ""
    set_config "SKIP_MAS_APPS" "true"
    set_config "SKIP_RUBY_INSTALL" "true"
    set_config "SKIP_PYTHON_INSTALL" "true"
    set_config "SETUP_POWERLINE" "false"
}

# Apply development mode configuration
apply_dev_mode_config() {
    echo "🔧 Applying dev-only mode overrides..."
    
    local skip_packages=$(get_config "DEV_MODE_SKIP_PACKAGES")
    local extra_packages=$(get_config "DEV_MODE_EXTRA_PACKAGES")
    
    # Add to skip list
    if [ -n "$skip_packages" ]; then
        local current_skip=$(get_config "SKIP_PACKAGES")
        set_config "SKIP_PACKAGES" "$current_skip $skip_packages"
    fi
    
    # Add extra dev packages
    if [ -n "$extra_packages" ]; then
        local current_formulas=$(get_config "HOMEBREW_FORMULAS")
        set_config "HOMEBREW_FORMULAS" "$current_formulas $extra_packages"
    fi
}

# Apply work mode configuration
apply_work_mode_config() {
    echo "🔧 Applying work mode overrides..."
    
    local skip_packages=$(get_config "WORK_MODE_SKIP_PACKAGES")
    local extra_packages=$(get_config "WORK_MODE_EXTRA_PACKAGES")
    
    # Skip personal packages
    if config_is_true "WORK_MODE_SKIP_PERSONAL"; then
        local personal_packages=$(get_config "PERSONAL_PACKAGES")
        local current_skip=$(get_config "SKIP_PACKAGES")
        set_config "SKIP_PACKAGES" "$current_skip $personal_packages"
    fi
    
    # Add work-specific skip packages
    if [ -n "$skip_packages" ]; then
        local current_skip=$(get_config "SKIP_PACKAGES")
        set_config "SKIP_PACKAGES" "$current_skip $skip_packages"
    fi
    
    # Add work-specific packages
    if [ -n "$extra_packages" ]; then
        local current_formulas=$(get_config "HOMEBREW_FORMULAS")
        set_config "HOMEBREW_FORMULAS" "$current_formulas $extra_packages"
    fi
}

# Apply quick mode configuration
apply_quick_mode_config() {
    echo "🔧 Applying quick mode overrides..."
    
    # Skip time-consuming installations
    set_config "SKIP_XCODE" "true"
    set_config "SKIP_MAS_APPS" "true"
    set_config "SKIP_RUBY_INSTALL" "true"
    set_config "SKIP_PYTHON_INSTALL" "true"
    
    # Reduce package list to essentials
    set_config "HOMEBREW_CASKS" "google-chrome visual-studio-code"
    set_config "QUICKLOOK_PLUGINS" ""
}

################################################################################
### Package Filtering Functions
################################################################################

# Filter package list based on configuration
filter_packages() {
    local package_list="$1"
    local skip_packages=$(get_config "SKIP_PACKAGES")
    
    if [ -z "$skip_packages" ]; then
        echo "$package_list"
        return
    fi
    
    # Convert to arrays for processing
    local -a packages=($package_list)
    local -a skip_array=($skip_packages)
    local -a filtered=()
    
    # Filter out packages in skip list
    for package in "${packages[@]}"; do
        local should_skip=false
        for skip_package in "${skip_array[@]}"; do
            if [ "$package" = "$skip_package" ]; then
                should_skip=true
                break
            fi
        done
        
        if [ "$should_skip" = false ]; then
            filtered+=("$package")
        fi
    done
    
    # Return filtered list
    echo "${filtered[*]}"
}

# Get filtered homebrew formulas
get_homebrew_formulas() {
    local core_packages=$(get_config "CORE_PACKAGES")
    local formulas=$(get_config "HOMEBREW_FORMULAS")
    local all_packages="$core_packages $formulas"
    
    filter_packages "$all_packages"
}

# Get filtered homebrew casks
get_homebrew_casks() {
    local casks=$(get_config "HOMEBREW_CASKS")
    filter_packages "$casks"
}

# Get filtered QuickLook plugins
get_quicklook_plugins() {
    local plugins=$(get_config "QUICKLOOK_PLUGINS")
    filter_packages "$plugins"
}

# Get filtered MAS apps
get_mas_apps() {
    if config_is_true "SKIP_MAS_APPS"; then
        echo ""
        return
    fi
    
    local mas_apps=$(get_config "MAS_APPS")
    echo "$mas_apps"
}

################################################################################
### Utility Functions
################################################################################

# Show current configuration
show_config() {
    echo "📋 Current Dotfiles Configuration"
    echo "================================="
    echo ""
    
    if [ "$DOTFILES_CONFIG_LOADED" = false ]; then
        echo "⚠️  Configuration not loaded"
        return
    fi
    
    echo "Setup Mode: ${DOTFILES_SETUP_MODE:-default}"
    echo "Config File: $DOTFILES_CONFIG_FILE"
    echo ""
    
    echo "🎛️  Setup Options:"
    echo "Skip Xcode: $(get_config "SKIP_XCODE")"
    echo "Skip Homebrew: $(get_config "SKIP_HOMEBREW")"
    echo "Skip MAS Apps: $(get_config "SKIP_MAS_APPS")"
    echo "Skip Ruby: $(get_config "SKIP_RUBY_INSTALL")"
    echo "Skip Python: $(get_config "SKIP_PYTHON_INSTALL")"
    echo ""
    
    echo "📦 Package Counts:"
    echo "Homebrew Formulas: $(get_homebrew_formulas | wc -w | tr -d ' ')"
    echo "Homebrew Casks: $(get_homebrew_casks | wc -w | tr -d ' ')"
    echo "QuickLook Plugins: $(get_quicklook_plugins | wc -w | tr -d ' ')"
    echo "MAS Apps: $(get_mas_apps | wc -w | tr -d ' ')"
    echo ""
    
    local skip_packages=$(get_config "SKIP_PACKAGES")
    if [ -n "$skip_packages" ]; then
        echo "🚫 Skipped Packages: $skip_packages"
        echo ""
    fi
}

# Validate configuration
validate_config() {
    echo "🔍 Validating configuration..."
    
    local errors=0
    
    # Check encryption method
    local encryption_method=$(get_config "ENCRYPTION_METHOD" "age")
    if [[ ! "$encryption_method" =~ ^(age|openssl)$ ]]; then
        echo "❌ Invalid encryption method: $encryption_method"
        errors=$((errors + 1))
    fi
    
    # Check shell
    local shell=$(get_config "DEFAULT_SHELL" "zsh")
    if [[ ! "$shell" =~ ^(zsh|bash)$ ]]; then
        echo "❌ Invalid shell: $shell"
        errors=$((errors + 1))
    fi
    
    # Check rotation days
    local warning_days=$(get_config "ROTATION_WARNING_DAYS" "90")
    local urgent_days=$(get_config "ROTATION_URGENT_DAYS" "180")
    
    if ! [[ "$warning_days" =~ ^[0-9]+$ ]] || ! [[ "$urgent_days" =~ ^[0-9]+$ ]]; then
        echo "❌ Rotation days must be numbers"
        errors=$((errors + 1))
    elif [ "$warning_days" -ge "$urgent_days" ]; then
        echo "❌ Warning days must be less than urgent days"
        errors=$((errors + 1))
    fi
    
    if [ $errors -eq 0 ]; then
        echo "✅ Configuration is valid"
        return 0
    else
        echo "❌ Found $errors configuration errors"
        return 1
    fi
}

################################################################################
### Export Functions for Scripts
################################################################################

# Export configuration as environment variables for compatibility
export_config_vars() {
    if [ "$DOTFILES_CONFIG_LOADED" = false ]; then
        load_dotfiles_config
    fi
    
    # Export commonly used variables
    export SKIP_XCODE=$(get_config "SKIP_XCODE" "false")
    export SKIP_HOMEBREW=$(get_config "SKIP_HOMEBREW" "false")
    export SKIP_MAS_APPS=$(get_config "SKIP_MAS_APPS" "false")
    export SKIP_RUBY_INSTALL=$(get_config "SKIP_RUBY_INSTALL" "false")
    export SKIP_PYTHON_INSTALL=$(get_config "SKIP_PYTHON_INSTALL" "false")
    export ENCRYPTION_METHOD=$(get_config "ENCRYPTION_METHOD" "age")
    export AUTO_SNAPSHOT=$(get_config "AUTO_SNAPSHOT" "true")
}

# Initialize configuration system
init_config() {
    local mode="${1:-}"
    
    # Load base configuration
    load_dotfiles_config
    
    # Apply mode if specified
    if [ -n "$mode" ]; then
        set_setup_mode "$mode"
    fi
    
    # Validate configuration
    validate_config
    
    # Export variables
    export_config_vars
}

# Show help for configuration system
show_config_help() {
    cat << 'EOF'
📖 Configuration System Help

CONFIGURATION FILE: .dotfiles.config
    Controls what gets installed and how setup behaves
    Edit this file to customize your dotfiles setup

SETUP MODES:
    --minimal     Only essential tools, no GUI apps
    --dev-only    Development tools only
    --work        Corporate-friendly setup
    --quick       Fast setup, skip time-consuming parts

FUNCTIONS:
    load_dotfiles_config    Load configuration from file
    get_config KEY          Get configuration value
    config_is_true KEY      Check if setting is enabled
    set_setup_mode MODE     Apply mode-specific settings
    show_config             Display current configuration
    validate_config         Check configuration for errors

EXAMPLES:
    source Scripts/config_parser.sh
    init_config "minimal"
    show_config

EOF
}

# If script is run directly, show help
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
        show_config_help
    else
        echo "This is a library file. Source it to use configuration functions."
        echo "Use --help for more information."
    fi
fi