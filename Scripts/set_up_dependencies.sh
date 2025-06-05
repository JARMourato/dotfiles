#!/bin/bash

set -euo pipefail

################################################################################
### Error Handling and Utility Functions
################################################################################

# Retry function for network operations
retry_command() {
    local retries=3
    local count=0
    until "$@"; do
        exit_code=$?
        count=$((count + 1))
        if [ $count -lt $retries ]; then
            echo "Command failed. Attempt $count/$retries. Retrying in 5 seconds..."
            sleep 5
        else
            echo "Command failed after $retries attempts."
            return $exit_code
        fi
    done
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Validate brew installation
validate_brew() {
    if ! command_exists brew; then
        echo "Error: Homebrew installation failed"
        exit 1
    fi
}

################################################################################
### Install Dependencies
################################################################################

echo "🚀 Starting dependencies setup"

# Load performance libraries if available
load_performance_libraries() {
    # Load progress indicators
    if [ -f "Scripts/progress_indicators.sh" ]; then
        source Scripts/progress_indicators.sh
    fi
    
    # Load caching system
    if [ -f "Scripts/caching_system.sh" ]; then
        source Scripts/caching_system.sh
        init_cache
    fi
}

# Initialize performance libraries if we're in the dotfiles directory
if [ -f "Scripts/progress_indicators.sh" ]; then
    load_performance_libraries
fi

# Load configuration if not already loaded
if [ "${DOTFILES_CONFIG_LOADED:-false}" = false ]; then
    if [ -f "${DOTFILES_DIR:-$(pwd)}/Scripts/config_parser.sh" ]; then
        source "${DOTFILES_DIR:-$(pwd)}/Scripts/config_parser.sh"
        load_dotfiles_config
        export_config_vars
    fi
fi

# Check if Homebrew installation should be skipped
if [ "${SKIP_HOMEBREW:-false}" = "true" ]; then
    echo "⏭️  Skipping Homebrew installation (configured)"
    exit 0
fi

# Install Homebrew if not already installed
if ! command_exists brew; then
	echo "🍺 Installing homebrew..."
	# Note: Homebrew doesn't publish checksums for their install script
	# Consider pinning to a specific commit hash for better security
	local homebrew_url="https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"
	local temp_script="/tmp/homebrew_install.sh"
	
	echo "📥 Downloading Homebrew install script..."
	retry_command curl -fsSL "$homebrew_url" > "$temp_script"
	echo "⚠️  Note: Homebrew install script integrity cannot be verified (no published checksums)"
	echo "🔧 Executing Homebrew installation..."
	retry_command bash "$temp_script"
	rm -f "$temp_script"
	validate_brew
fi

# In case paths have not been set up yet
if [ -f ~/.zshrc ]; then
    source ~/.zshrc
fi

echo "🍺 Updating homebrew..."
if command -v run_with_spinner >/dev/null 2>&1; then
    run_with_spinner "retry_command brew update" "Updating Homebrew"
else
    retry_command brew update
fi

# Check if Xcode installation should be skipped
if [ "${SKIP_XCODE:-false}" = "true" ]; then
    echo "⏭️  Skipping Xcode installation (configured)"
else
    # Check Xcode
    xcode=`ls /Applications | grep 'Xcode-'`

    if [[ ! -z "$xcode" ]]; then
        echo "Xcode is already installed 🎉"
    else
        # Install Xcode 
        brew install aria2
        brew install robotsandpencils/made/xcodes
        xcodes install --latest --experimental-unxip
    fi
fi

# Get package lists from configuration
if command -v get_homebrew_formulas >/dev/null 2>&1; then
    PACKAGES=($(get_homebrew_formulas))
else
    # Fallback to default packages if configuration not available
    PACKAGES=(age aria2 detekt gh hub jq ktlint libusb make mas pyenv python python-tk rbenv ruby ruby-build swiftformat swiftlint robotsandpencils/made/xcodes)
fi

if [ ${#PACKAGES[@]} -gt 0 ]; then
    echo "🍺 Installing utility packages (${#PACKAGES[@]} packages)..."
    echo "Packages: ${PACKAGES[*]}"
    
    # Use caching and progress if available
    if command -v install_packages_with_progress >/dev/null 2>&1; then
        install_packages_with_progress "formula" "${PACKAGES[@]}"
    else
        retry_command brew install ${PACKAGES[@]}
    fi
else
    echo "⏭️  No utility packages to install (configuration)"
fi

# Get cask lists from configuration
if command -v get_homebrew_casks >/dev/null 2>&1; then
    CASKS=($(get_homebrew_casks))
else
    # Fallback to default casks if configuration not available
    CASKS=(android-studio betterzip bitwarden calibre google-chrome iina logi-options-plus notion raycast setapp sf-symbols slack sourcetree spotify sublime-text telegram visual-studio-code xcodes whatsapp zoom)
fi

if [ ${#CASKS[@]} -gt 0 ]; then
    echo "🍺 Installing apps (${#CASKS[@]} casks)..."
    echo "Apps: ${CASKS[*]}"
    
    # Use caching and progress if available
    if command -v install_packages_with_progress >/dev/null 2>&1; then
        install_packages_with_progress "cask" "${CASKS[@]}"
    else
        retry_command brew install --cask ${CASKS[@]}
    fi
else
    echo "⏭️  No apps to install (configuration)"
fi

# Get QuickLook plugins from configuration
if command -v get_quicklook_plugins >/dev/null 2>&1; then
    QUICKLOOKPLUGINS=($(get_quicklook_plugins))
else
    # Fallback to default plugins if configuration not available
    QUICKLOOKPLUGINS=(apparency qlcolorcode qlimagesize qlmarkdown qlprettypatch qlstephen quicklook-csv quicklook-json suspicious-package webpquicklook)
fi

if [ ${#QUICKLOOKPLUGINS[@]} -gt 0 ]; then
    echo "🍺 Installing quicklook plugins (${#QUICKLOOKPLUGINS[@]} plugins)..."
    echo "Plugins: ${QUICKLOOKPLUGINS[*]}"
    
    # Use caching and progress if available
    if command -v install_packages_with_progress >/dev/null 2>&1; then
        install_packages_with_progress "cask" "${QUICKLOOKPLUGINS[@]}"
    else
        retry_command brew install --cask ${QUICKLOOKPLUGINS[@]}
    fi
else
    echo "⏭️  No QuickLook plugins to install (configuration)"
fi

echo "📦 Installing bundler..."
if command -v run_with_spinner >/dev/null 2>&1; then
    run_with_spinner "retry_command gem install bundler" "Installing bundler"
else
    retry_command gem install bundler
fi

echo "🧼 Cleaning up..."
if command -v run_with_spinner >/dev/null 2>&1; then
    run_with_spinner "brew cleanup -s" "Cleaning up Homebrew cache"
else
    brew cleanup -s
fi

# Ruby installation
if [ "${SKIP_RUBY_INSTALL:-false}" = "true" ]; then
    echo "⏭️  Skipping Ruby installation (configured)"
else
    echo "💎 Installing Ruby"
    # Will pick up version from ~/.ruby-version
    if [ -f ~/.ruby-version ]; then
        RUBY_VERSION="$(cat ~/.ruby-version)"
        retry_command rbenv install
        rbenv global $RUBY_VERSION
        echo "💎 Ruby $RUBY_VERSION installed successfully!"
    else
        echo "⚠️  No .ruby-version file found, skipping Ruby installation"
    fi
fi

# Python packages installation
if [ "${SKIP_PYTHON_INSTALL:-false}" = "true" ]; then
    echo "⏭️  Skipping Python packages installation (configured)"
else
    echo "🐍 Installing python usb..."
    retry_command pip3 install pyusb
fi

# Mac App Store applications
if [ "${SKIP_MAS_APPS:-false}" = "true" ]; then
    echo "⏭️  Skipping Mac App Store apps installation (configured)"
else
    echo "🍏 Installing Mac App Store Apps"
    
    # Get MAS apps from configuration
    if command -v get_mas_apps >/dev/null 2>&1; then
        local mas_apps=$(get_mas_apps)
        if [ -n "$mas_apps" ]; then
            echo "Installing configured MAS apps..."
            for app_entry in $mas_apps; do
                local app_id="${app_entry%:*}"
                local app_name="${app_entry#*:}"
                echo "Installing: $app_name ($app_id)"
                retry_command mas install "$app_id"
            done
        else
            echo "⏭️  No MAS apps configured to install"
        fi
    else
        # Fallback to default MAS apps
        echo "Installing default MAS apps..."
        retry_command mas install 904280696 # Things 3
        retry_command mas install 1477385213 # Save to Pocket
        retry_command mas install 472226235 # LanScan
        retry_command mas install 441258766 # Magnet
    fi
fi

echo "🎉 Dependencies Setup complete!"
