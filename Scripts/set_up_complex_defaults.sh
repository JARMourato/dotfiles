#!/bin/bash

################################################################################
### 🔧 Configure Complex macOS Settings
### Settings that don't fit the simple YAML model
################################################################################

echo "========================================"
echo "🔧 Configuring Complex System Settings..."
echo "========================================"
echo ""

# Ask for the administrator password upfront
echo "🔐 Some settings require administrator privileges..."
sudo -v

# Keep-alive: update existing `sudo` time stamp until script has finished
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

################################################################################
# Dock - Add Applications Folder
################################################################################

echo "🚢 Adding Applications folder to Dock..."
defaults write com.apple.dock persistent-others -array-add "<dict>
    <key>tile-data</key>
    <dict>
        <key>arrangement</key>
        <integer>1</integer>
        <key>displayas</key>
        <integer>0</integer>
        <key>file-data</key>
        <dict>
            <key>_CFURLString</key>
            <string>file:///Applications/</string>
            <key>_CFURLStringType</key>
            <integer>15</integer>
        </dict>
        <key>preferreditemsize</key>
        <string>-1</string>
        <key>showas</key>
        <integer>0</integer>
    </dict>
    <key>tile-type</key>
    <string>directory-tile</string>
</dict>"
echo "   └─ ✅ Applications folder added to Dock"

################################################################################
# Photos
################################################################################

echo "📸 Configuring Photos app..."
# Prevent Photos from opening automatically when devices are plugged in
defaults -currentHost write com.apple.ImageCapture disableHotPlug -bool true
echo "   └─ ✅ Disabled auto-open when devices connect"

################################################################################
# Spotlight
################################################################################

echo "🔍 Configuring Spotlight..."
# Skip showing the "learn more" tutorial
defaults write com.apple.Spotlight showedLearnMore -bool true
# Remove menu bar icon
defaults -currentHost write com.apple.Spotlight MenuItemHidden -int 1
echo "   └─ ✅ Hidden menu bar icon and skipped tutorial"

################################################################################
# System UI
################################################################################

echo "🎛️  Configuring System UI..."
# Hide battery icon in menu bar
defaults write $HOME/Library/Preferences/com.apple.controlcenter.plist "NSStatusItem Visible Battery" -bool false
echo "   └─ ✅ Hidden battery icon from menu bar"

################################################################################
# Audio & Bluetooth
################################################################################

echo "🎧 Configuring Audio & Bluetooth..."
# Increase sound quality for Bluetooth headphones/headsets
defaults write com.apple.BluetoothAudioAgent "Apple Bitpool Min (editable)" -int 40
echo "   └─ ✅ Improved Bluetooth audio quality"

################################################################################
# Printing
################################################################################

echo "🖨️  Configuring Printing..."
# Automatically quit printer app once the print jobs complete
defaults write com.apple.print.PrintingPrefs "Quit When Finished" -bool true
echo "   └─ ✅ Auto-quit printer app after jobs complete"

################################################################################
# Advanced Keyboard Shortcuts
################################################################################

echo "⌨️  Adding Advanced Keyboard Shortcuts..."
# Add keyboard shortcut `⌘ + shift + x` to strikethrough text globally
defaults write -g NSUserKeyEquivalents -dict-add "Strikethrough" "@\$x"
echo "   └─ ✅ Added ⌘+Shift+X for strikethrough"

# Add keyboard shortcut for Xcode Sort Selected Lines (requires SortingMatters app)
defaults write com.apple.dt.Xcode NSUserKeyEquivalents -dict-add "Sort Selected Lines" "^\$i"
echo "   └─ ✅ Added Ctrl+Shift+I for Sort Selected Lines in Xcode"

################################################################################
# Miscellaneous UI
################################################################################

echo "🖱️  Configuring Miscellaneous UI..."
# When clicking scroll indicator, navigate to the spot that's clicked
defaults write -g AppleScrollerPagingBehavior -bool true
echo "   └─ ✅ Click scroll bar to jump to location"

# Maximizes the application upon double clicking its navigation bar
defaults write -g AppleActionOnDoubleClick -string "Maximize"
echo "   └─ ✅ Double-click title bar to maximize"

# Plays sound feedback when volume is changed
defaults write -g com.apple.sound.beep.feedback -int 1
echo "   └─ ✅ Volume change sound feedback enabled"

################################################################################
# Login Window
################################################################################

echo "🔐 Configuring Login Window..."
# Hide language menu in the top right corner of the boot screen
sudo defaults write /Library/Preferences/com.apple.loginwindow showInputMenu -bool false
echo "   └─ ✅ Hidden language menu at login"

################################################################################
# Advanced Xcode Settings
################################################################################

if [[ -d "/Applications/Xcode.app" ]] || ls /Applications/Xcode*.app 1> /dev/null 2>&1; then
    echo "🛠️  Configuring Advanced Xcode Settings..."
    
    # Show all build steps on activity log
    defaults write com.apple.dt.Xcode IDEActivityLogShowsAllBuildSteps -bool YES
    
    # Analyzer results on activity log
    defaults write com.apple.dt.Xcode IDEActivityLogShowsAnalyzerResults -bool YES
    
    # Show errors on activity log
    defaults write com.apple.dt.Xcode IDEActivityLogShowsErrors -bool YES
    
    # Show warnings on activity log
    defaults write com.apple.dt.Xcode IDEActivityLogShowsWarnings -bool YES
    
    # Command-click jumps to definition
    defaults write com.apple.dt.Xcode IDECommandClickOnCodeAction -int 1
    
    # Show Indexing numeric progress
    defaults write com.apple.dt.Xcode IDEIndexerActivityShowNumericProgress -bool YES
    
    # Editor navigation settings
    defaults write com.apple.dt.Xcode IDEEditorCoordinatorTarget_DoubleClick -string "SameAsClick"
    defaults write com.apple.dt.Xcode IDEEditorNavigationStyle_DefaultsKey -string "IDEEditorNavigationStyle_OpenInPlace"
    defaults write com.apple.dt.Xcode IDEIssueNavigatorDetailLevel -int 4
    defaults write com.apple.dt.Xcode IDESearchNavigatorDetailLevel -int 4
    
    echo "   └─ ✅ Advanced Xcode settings configured"
fi

################################################################################
# SourceTree (if installed)
################################################################################

if [[ -d "/Applications/SourceTree.app" ]]; then
    echo "🌳 Configuring SourceTree..."
    
    # Preferred dimensions
    defaults write com.torusknot.SourceTreeNotMAS SidebarWidth_ -int 140
    defaults write com.torusknot.SourceTreeNotMAS commitPaneHeight -int 242
    
    # Also show diff for *.lock files
    defaults write com.torusknot.SourceTreeNotMAS diffSkipFilePatterns -string "*.pbxuser, *.xcuserstate, Cartfile.resolved"
    
    # Sets the GPG binary location
    defaults write com.torusknot.SourceTreeNotMAS gpgProgram -string "/usr/local/MacGPG2/bin"
    
    defaults write com.torusknot.SourceTreeNotMAS fileStatusStagingViewMode -int 1
    defaults write com.torusknot.SourceTreeNotMAS fileStatusViewMode2 -int 0
    
    # Skip tutorials
    defaults write com.torusknot.SourceTreeNotMAS showStagingTip -bool false
    defaults write com.torusknot.SourceTreeNotMAS DidShowGettingStarted -bool true
    
    # Don't restore windows on startup
    defaults write com.torusknot.SourceTreeNotMAS windowRestorationMethod -int 1
    
    # Use fixed-width font for commit messages
    defaults write com.torusknot.SourceTreeNotMAS useFixedWithCommitFont -bool true
    
    # Display column guide in commit message at character: 50
    defaults write com.torusknot.SourceTreeNotMAS commitColumnGuideWidth -int 50
    
    # Keep bookmarks closed on startup
    defaults write com.torusknot.SourceTreeNotMAS bookmarksClosedOnStartup -bool true
    
    # Ask to bookmark upon opening new repo
    defaults write com.torusknot.SourceTreeNotMAS bookmarksWindowOpen -bool false
    
    echo "   └─ ✅ SourceTree configured"
fi

################################################################################
# Advanced Trackpad Settings
################################################################################

echo "👆 Configuring Advanced Trackpad Settings..."
# Set second click threshold for haptic feedback
defaults write com.apple.AppleMultitouchTrackpad SecondClickThreshold -int 0
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad SecondClickThreshold -int 0
echo "   └─ ✅ Advanced trackpad settings configured"

echo ""
echo "========================================"
echo "🎉 Complex Settings Configuration Complete!"
echo "========================================"
echo ""
echo "💡 Some changes may require a logout or restart to take effect"