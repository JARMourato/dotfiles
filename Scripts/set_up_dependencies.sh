#!/bin/bash

################################################################################
### Install Dependencies
################################################################################

echo "🚀 Starting setup"
echo "========================================"

# Load configuration if available
if [ -f ".dotfiles.config" ]; then
    echo
echo "📋 Loading profile configuration..."
    source .dotfiles.config
    echo "✅ Configuration loaded for profile: ${MACHINE_PROFILE:-default}"
echo
else
    echo "⚠️  No profile configuration found, using defaults"
fi

# Install Homebrew if not already installed
if command -v brew >/dev/null 2>&1; then
    echo "✅ Homebrew already installed"
elif [ -f "/opt/homebrew/bin/brew" ]; then
    echo "✅ Homebrew found at /opt/homebrew/bin/brew (adding to PATH)"
    eval "$(/opt/homebrew/bin/brew shellenv)"
else
    echo "🍺 Installing homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    # Add to PATH for this session
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

echo "🍺 Updating homebrew..."
brew update

# Check Xcode (both standard and versioned installations)
if [ -d "/Applications/Xcode.app" ] || ls /Applications/Xcode*.app 1> /dev/null 2>&1; then
    echo "✅ Xcode is already installed 🎉"
else
    # Install Xcode 
    brew install aria2
    brew install robotsandpencils/made/xcodes
    xcodes install --latest --experimental-unxip
fi

# Install utilities and apps
if [ -n "${HOMEBREW_FORMULAS:-}" ]; then
    # Convert space-separated string to array
    IFS=' ' read -ra PACKAGES <<< "$HOMEBREW_FORMULAS"
    echo "📦 Installing Homebrew Packages"
echo "   ├─ ${#PACKAGES[@]} packages configured"
echo "   └─ Packages: $(echo $HOMEBREW_FORMULAS | tr ' ' ',' | sed 's/,/, /g')"
echo
    
    # Skip already installed packages
    for package in "${PACKAGES[@]}"; do
        if ! brew list "$package" >/dev/null 2>&1; then
            echo "🍺 Installing $package..."
            brew install "$package"
        else
            echo "✅ $package already installed"
        fi
    done
else
    # Default packages for backward compatibility
    PACKAGES=(
        aria2
        gh
        jq
        mas
        pyenv
        python
        rbenv
        ruby
        ruby-build
        swiftformat
        swiftlint
    )
    echo "📦 Installing Default Homebrew Packages"
echo "   └─ ${#PACKAGES[@]} packages"
echo
    
    # Skip already installed packages
    for package in "${PACKAGES[@]}"; do
        if ! brew list "$package" >/dev/null 2>&1; then
            echo "🍺 Installing $package..."
            brew install "$package"
        else
            echo "✅ $package already installed"
        fi
    done
fi

if [ -n "${HOMEBREW_CASKS:-}" ]; then
    # Convert space-separated string to array
    IFS=' ' read -ra CASKS <<< "$HOMEBREW_CASKS"
    echo "🖥️  Installing macOS Applications"
    echo "   ├─ ${#CASKS[@]} applications configured"
    echo "   └─ Apps: $(echo $HOMEBREW_CASKS | tr ' ' ',' | sed 's/,/, /g')"
    echo
    
    # Skip already installed casks
    for cask in "${CASKS[@]}"; do
        if ! brew list --cask "$cask" >/dev/null 2>&1; then
            echo "🍺 Installing $cask..."
            brew install --cask "$cask"
        else
            echo "✅ $cask already installed"
        fi
    done
else
    # Default casks for backward compatibility
    CASKS=(
        betterzip
        bitwarden
        google-chrome
        iina
        notion
        raycast
        setapp
        slack
        sourcetree
        spotify
        sublime-text
        telegram
        visual-studio-code
        whatsapp
        zoom
    )
    echo "🖥️  Installing Default macOS Applications"
    echo "   └─ ${#CASKS[@]} applications"
    echo
    
    # Skip already installed casks
    for cask in "${CASKS[@]}"; do
        if ! brew list --cask "$cask" >/dev/null 2>&1; then
            echo "🍺 Installing $cask..."
            brew install --cask "$cask"
        else
            echo "✅ $cask already installed"
        fi
    done
fi


echo
echo "🔄 Upgrading outdated Homebrew packages..."
brew upgrade
echo
echo "🧼 Cleaning up Homebrew cache..."
brew cleanup -s

# Verify rbenv is working before installing Ruby
if ! command -v rbenv >/dev/null 2>&1; then
    echo "❌ rbenv not found, skipping Ruby installation"
else
    echo
echo "💎 Installing Ruby Environment"
echo "   └─ Using rbenv for Ruby version management"
    # Will pick up version from ~/.ruby-version
    RUBY_VERSION="$(cat ~/.ruby-version)"
    
    # Check if Ruby version is already installed
    if rbenv versions | grep -q "$RUBY_VERSION"; then
        echo "✅ Ruby $RUBY_VERSION already installed"
    else
        echo "🍺 Installing Ruby $RUBY_VERSION..."
        rbenv install
    fi
    
    rbenv global $RUBY_VERSION
    echo "💎 Ruby $RUBY_VERSION set as global version!"
    
    # Reload rbenv to ensure the correct Ruby is used
    eval "$(rbenv init -)"
    
    # Check if bundler is already installed
    if gem list bundler | grep -q "bundler"; then
        echo "✅ bundler already installed"
    else
        echo "   ├─ Installing bundler gem..."
        gem install bundler
    fi
fi

echo
echo "🐍 Installing Python Packages"

# Ensure pip and setuptools are up to date
echo "   ├─ Upgrading pip and setuptools..."
pip3 install --upgrade --break-system-packages pip setuptools wheel

# Check if pyusb is already installed
if pip3 show pyusb >/dev/null 2>&1; then
    echo "✅ pyusb already installed"
else
    echo "   └─ Installing pyusb..."
    # Use --break-system-packages flag to bypass externally-managed-environment restriction
    pip3 install --break-system-packages pyusb
fi

echo
echo "🍏 Installing Mac App Store Apps"
if [ -n "${MAS_APPS:-}" ]; then
    echo "   ├─ Installing configured MAS apps"
echo "   └─ App IDs: $MAS_APPS"
echo
    for app_id in $MAS_APPS; do
        if mas list | grep -q "^$app_id"; then
            echo "✅ MAS app $app_id already installed"
        else
            echo "🍺 Installing MAS app $app_id..."
            mas install "$app_id"
        fi
    done
else
    # Default MAS apps for backward compatibility
    echo "   └─ Installing default MAS apps"
echo
    
    if mas list | grep -q "^904280696"; then
        echo "✅ Things 3 already installed"
    else
        echo "🍺 Installing Things 3..."
        mas install 904280696
    fi
    
    if mas list | grep -q "^1477385213"; then
        echo "✅ Save to Pocket already installed"
    else
        echo "🍺 Installing Save to Pocket..."
        mas install 1477385213
    fi
    
    if mas list | grep -q "^472226235"; then
        echo "✅ LanScan already installed"
    else
        echo "🍺 Installing LanScan..."
        mas install 472226235
    fi
    
    if mas list | grep -q "^441258766"; then
        echo "✅ Magnet already installed"
    else
        echo "🍺 Installing Magnet..."
        mas install 441258766
    fi
fi

echo
echo "========================================"
echo "🤖 Installing AI Assistant Tools..."
echo "========================================"
echo

# Install Claude Code CLI (requires Node.js)
if command -v node >/dev/null 2>&1 && command -v npm >/dev/null 2>&1; then
    if npm list -g @anthropic-ai/claude-code >/dev/null 2>&1; then
        echo "✅ Claude Code CLI already installed"
    else
        echo "🤖 Installing Claude Code CLI..."
        npm install -g @anthropic-ai/claude-code
    fi
else
    echo "⚠️  Node.js not installed, skipping Claude Code CLI installation"
fi




echo
echo "========================================"
echo "🎉 Dependencies Setup Complete!"
echo "========================================"
