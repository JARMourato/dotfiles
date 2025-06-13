#!/bin/bash

################################################################################
### Configure machine-specific settings (git config and hostname)
################################################################################

echo "🔧 Configuring machine-specific settings..."
echo ""

# Source the configuration
if [[ -f "$DOTFILES_DIR/.dotfiles.config" ]]; then
    source "$DOTFILES_DIR/.dotfiles.config"
else
    echo "❌ No configuration found. Run profile setup first."
    exit 1
fi

# Ask for the administrator password upfront
echo "🔐 Requesting administrator privileges for hostname changes..."
sudo -v

# Keep-alive: update existing `sudo` time stamp until script has finished
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

################################################################################
### Configure git 
################################################################################

echo "👤 Configuring git user information..."
if [[ -n "${GIT_USER_NAME:-}" ]] && [[ -n "${GIT_USER_EMAIL:-}" ]]; then
    git config --global user.name "$GIT_USER_NAME"
    git config --global user.email "$GIT_USER_EMAIL"
    echo "✅ Git configured: $GIT_USER_NAME <$GIT_USER_EMAIL>"
else
    echo "⚠️  Git user info not found in configuration, skipping..."
fi

################################################################################
### Configure computer name
################################################################################

echo "🖥️  Configuring computer hostname..."

# Function to validate machine name (alphanumeric only)
validate_machine_name() {
    local name="$1"
    if [[ "$name" =~ ^[a-zA-Z0-9]+$ ]]; then
        return 0
    else
        return 1
    fi
}

# Get machine name with validation
while true; do
    echo -n "   └─ Please enter the machine name (alphanumeric only): "
    read name
    
    if [[ -z "$name" ]]; then
        echo "   ❌ Machine name cannot be empty. Please try again."
        continue
    fi
    
    if validate_machine_name "$name"; then
        echo "   ✅ Valid machine name: $name"
        break
    else
        echo "   ❌ Invalid machine name. Only alphanumeric characters allowed. Please try again."
    fi
done

echo "   ├─ Setting ComputerName..."
sudo scutil --set ComputerName "$name"

echo "   ├─ Setting HostName..."
sudo scutil --set HostName "$name"

echo "   ├─ Setting LocalHostName..."
sudo scutil --set LocalHostName "$name"

echo "   └─ Setting NetBIOSName..."
sudo defaults write /Library/Preferences/SystemConfiguration/com.apple.smb.server NetBIOSName -string "$name"

echo "✅ Hostname configured: $name"

echo ""
echo "========================================"
echo "🎉 Machine Configuration Complete!"
echo "========================================"
echo ""
echo "💡 Some hostname changes may require a restart to take full effect"