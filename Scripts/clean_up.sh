#!/bin/bash

################################################################################
### Clean up default macOS applications and finalize setup
################################################################################

echo "🧹 Cleaning up default macOS applications..."
echo ""

# Source the configuration
if [[ -f "$DOTFILES_DIR/.dotfiles.config" ]]; then
    source "$DOTFILES_DIR/.dotfiles.config"
else
    echo "❌ No configuration found. Run profile setup first."
    exit 1
fi

# Check if cleanup apps are configured
if [[ -z "${CLEANUP_APPS:-}" ]]; then
    echo "ℹ️  No cleanup apps configured for this profile"
    echo ""
    echo "========================================"
    echo "🎉 Setup Complete!"
    echo "========================================"
    echo ""
    echo "💡 You can add cleanup_apps to your YAML profile if desired"
    exit 0
fi

# Ask for the administrator password upfront
echo "🔐 Requesting administrator privileges for app removal..."
sudo -v

# Keep-alive: update existing `sudo` time stamp until this script has finished
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

# Convert space-separated string to array
declare -a APPS_TO_REMOVE
IFS=' ' read -ra APPS_TO_REMOVE <<< "$CLEANUP_APPS"

echo "🗑️  The following default applications will be removed:"
for app in "${APPS_TO_REMOVE[@]}"; do
    if [[ -d "/Applications/$app" ]]; then
        echo "   ├─ $app (found)"
    else
        echo "   ├─ $app (not found - will skip)"
    fi
done
echo ""

# Confirmation prompt
echo "⚠️  This action is irreversible. These apps can be reinstalled from the App Store if needed."
read -p "   └─ Continue with app removal? (y/N): " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ App removal cancelled by user"
    echo ""
    echo "========================================"
    echo "🎉 Setup Complete!"
    echo "========================================"
    echo ""
    echo "💡 You can run this cleanup script later if desired"
    exit 0
fi

echo ""
echo "🗑️  Removing applications..."

# Remove each app with verification
removed_count=0
for app in "${APPS_TO_REMOVE[@]}"; do
    app_path="/Applications/$app"
    if [[ -d "$app_path" ]]; then
        echo "   ├─ Removing $app..."
        if sudo rm -rf "$app_path"; then
            echo "   ✅ $app removed successfully"
            ((removed_count++))
        else
            echo "   ❌ Failed to remove $app"
        fi
    else
        echo "   ⏭️  $app not found - skipping"
    fi
done

echo ""
if [[ $removed_count -gt 0 ]]; then
    echo "✅ Removed $removed_count application(s) successfully"
else
    echo "ℹ️  No applications were removed"
fi

echo ""
echo "========================================"
echo "🎉 Cleanup Complete!"
echo "========================================"
echo ""
echo "🔄 Some system changes require a restart to take full effect."
read -p "   └─ Restart now? (y/N): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    echo "🔄 Restarting system in 3 seconds..."
    sleep 1
    echo "   3..."
    sleep 1
    echo "   2..."
    sleep 1
    echo "   1..."
    sudo shutdown -r now
else
    echo ""
    echo "💡 Please restart your system manually when convenient to complete the setup"
fi