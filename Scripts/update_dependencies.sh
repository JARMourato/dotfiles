#!/usr/bin/env bash

# Exit on error
set -e

# Get the directory where the script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_ROOT="$(dirname "$SCRIPT_DIR")"

# Source the configuration
if [ -f "$DOTFILES_ROOT/.dotfiles.config" ]; then
    source "$DOTFILES_ROOT/.dotfiles.config"
else
    echo "❌ .dotfiles.config not found. Please run profile-setup.sh first."
    exit 1
fi

# Check if profile is set
if [ -z "$DOTFILES_PROFILE" ]; then
    echo "❌ No profile set in .dotfiles.config"
    exit 1
fi

PROFILE_FILE="$DOTFILES_ROOT/.dotfiles.$DOTFILES_PROFILE.yaml"

if [ ! -f "$PROFILE_FILE" ]; then
    echo "❌ Profile file not found: $PROFILE_FILE"
    exit 1
fi

echo "🔄 Updating dependencies for profile: $DOTFILES_PROFILE"
echo ""

# Function to update Homebrew formulas
update_brew_formulas() {
    echo "📦 Updating Homebrew formulas..."
    
    # First update Homebrew itself
    brew update
    
    # Get formulas from config
    if [ -n "$DOTFILES_BREW_FORMULAS" ]; then
        # Convert comma-separated list to array
        IFS=',' read -ra formulas <<< "$DOTFILES_BREW_FORMULAS"
        
        for formula in "${formulas[@]}"; do
            formula=$(echo "$formula" | xargs) # Trim whitespace
            if brew list --formula | grep -q "^${formula}$"; then
                echo "  ↻ Updating $formula..."
                brew upgrade "$formula" 2>/dev/null || echo "  ✓ $formula is already up-to-date"
            fi
        done
    fi
    echo ""
}

# Function to update Homebrew casks
update_brew_casks() {
    echo "🖥️  Updating Homebrew casks..."
    
    if [ -n "$DOTFILES_BREW_CASKS" ]; then
        # Convert comma-separated list to array
        IFS=',' read -ra casks <<< "$DOTFILES_BREW_CASKS"
        
        for cask in "${casks[@]}"; do
            cask=$(echo "$cask" | xargs) # Trim whitespace
            if brew list --cask | grep -q "^${cask}$"; then
                echo "  ↻ Updating $cask..."
                brew upgrade --cask "$cask" 2>/dev/null || echo "  ✓ $cask is already up-to-date"
            fi
        done
    fi
    echo ""
}

# Function to update Mac App Store apps
update_mas_apps() {
    echo "🛍️  Updating Mac App Store apps..."
    
    if command -v mas &> /dev/null && [ -n "$DOTFILES_MAS_APPS" ]; then
        echo "  ↻ Checking for updates..."
        mas upgrade
    else
        echo "  ⚠️  mas not installed or no apps configured"
    fi
    echo ""
}

# Function to update Ruby gems
update_gems() {
    echo "💎 Updating Ruby gems..."
    
    if [ -n "$DOTFILES_GEMS" ]; then
        # Convert comma-separated list to array
        IFS=',' read -ra gems <<< "$DOTFILES_GEMS"
        
        for gem in "${gems[@]}"; do
            gem=$(echo "$gem" | xargs) # Trim whitespace
            if gem list | grep -q "^${gem} "; then
                echo "  ↻ Updating $gem..."
                gem update "$gem" 2>/dev/null || echo "  ✓ $gem update failed or already up-to-date"
            fi
        done
    fi
    echo ""
}

# Function to update Python packages
update_python_packages() {
    echo "🐍 Updating Python packages..."
    
    if [ -n "$DOTFILES_PYTHON_PACKAGES" ]; then
        # Convert comma-separated list to array
        IFS=',' read -ra packages <<< "$DOTFILES_PYTHON_PACKAGES"
        
        for package in "${packages[@]}"; do
            package=$(echo "$package" | xargs) # Trim whitespace
            if pip list 2>/dev/null | grep -qi "^${package} "; then
                echo "  ↻ Updating $package..."
                pip install --upgrade "$package" 2>/dev/null || echo "  ✓ $package update failed or already up-to-date"
            fi
        done
    fi
    echo ""
}

# Main execution
echo "🚀 Starting dependency updates..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Update each category
update_brew_formulas
update_brew_casks
update_mas_apps
update_gems
update_python_packages

# Clean up outdated versions
echo "🧹 Cleaning up outdated versions..."
brew cleanup
echo ""

echo "✅ Dependency update complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"