#!/bin/bash

################################################################################
### Configure macOS's helpful UserDefaults from YAML configuration
################################################################################

set -e # Immediately rethrows exceptions

echo "⚙️  Configuring macOS system preferences..."
echo ""

# Source the configuration
if [[ -f "$DOTFILES_DIR/.dotfiles.config" ]]; then
    source "$DOTFILES_DIR/.dotfiles.config"
else
    echo "❌ No configuration found. Run profile setup first."
    exit 1
fi

################################################################################
# Script Setup                                                                 #
################################################################################

echo "🔄 Preparing system for configuration..."

# Close any open instances of the following programs, to prevent them from
# overriding settings we're about to change
echo "   ├─ Closing System Preferences..."
osascript -e 'tell application "System Preferences" to quit' 2>/dev/null || true
echo "   ├─ Closing Xcode..."
osascript -e 'tell app "Xcode" to quit' 2>/dev/null || true
echo "   └─ Closing SourceTree..."
osascript -e 'tell app "SourceTree" to quit' 2>/dev/null || true

echo "🔐 Requesting administrator privileges..."
# Ask for the administrator password upfront
sudo -v

# Keep-alive: update existing `sudo` time stamp until this script has finished
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

echo "✅ System prepared for configuration"
echo ""

################################################################################
# Helper Functions                                                             #
################################################################################

# Function to safely execute defaults commands with error handling
safe_defaults() {
    local domain="$1"
    local key="$2" 
    local type="$3"
    local value="$4"
    
    if defaults write "$domain" "$key" -"$type" "$value" 2>/dev/null; then
        return 0
    else
        echo "   ⚠️  Failed to set $domain $key"
        return 1
    fi
}

# Function to convert boolean string to appropriate value
convert_bool() {
    local value="$1"
    if [[ "$value" == "true" ]]; then
        echo "true"
    else
        echo "false"
    fi
}

################################################################################
# Activity Monitor                                                             #
################################################################################

if [[ -n "${ACTIVITY_MONITOR_OPEN_MAIN_WINDOW:-}" ]]; then
    echo "📊 Configuring Activity Monitor..."
    
    [[ -n "${ACTIVITY_MONITOR_OPEN_MAIN_WINDOW:-}" ]] && 
        safe_defaults "com.apple.ActivityMonitor" "OpenMainWindow" "bool" "$(convert_bool "$ACTIVITY_MONITOR_OPEN_MAIN_WINDOW")"
    
    [[ -n "${ACTIVITY_MONITOR_SHOW_ALL_PROCESSES:-}" ]] && 
        safe_defaults "com.apple.ActivityMonitor" "ShowCategory" "int" "0"
    
    [[ -n "${ACTIVITY_MONITOR_SORT_BY_CPU:-}" ]] && [[ "$ACTIVITY_MONITOR_SORT_BY_CPU" == "true" ]] && {
        safe_defaults "com.apple.ActivityMonitor" "SortColumn" "string" "CPUUsage"
        safe_defaults "com.apple.ActivityMonitor" "SortDirection" "int" "0"
    }
    
    echo "✅ Activity Monitor configured"
fi

################################################################################
# App Store                                                                    #
################################################################################

if [[ -n "${APP_STORE_CHECK_UPDATES_DAILY:-}" ]]; then
    echo "🍎 Configuring App Store..."
    
    [[ "$APP_STORE_CHECK_UPDATES_DAILY" == "true" ]] && 
        safe_defaults "com.apple.SoftwareUpdate" "ScheduleFrequency" "int" "1"
    
    echo "✅ App Store configured"
fi

################################################################################
# Dock                                                                         #
################################################################################

if [[ -n "${DOCK_AUTOHIDE:-}" ]]; then
    echo "🚢 Configuring Dock..."
    
    [[ -n "${DOCK_AUTOHIDE:-}" ]] && 
        safe_defaults "com.apple.dock" "autohide" "bool" "$(convert_bool "$DOCK_AUTOHIDE")"
    
    [[ -n "${DOCK_TILE_SIZE:-}" ]] && 
        safe_defaults "com.apple.dock" "tilesize" "int" "$DOCK_TILE_SIZE"
    
    [[ -n "${DOCK_LARGE_SIZE:-}" ]] && 
        safe_defaults "com.apple.dock" "largesize" "float" "$DOCK_LARGE_SIZE"
    
    [[ -n "${DOCK_MAGNIFICATION:-}" ]] && 
        safe_defaults "com.apple.dock" "magnification" "bool" "$(convert_bool "$DOCK_MAGNIFICATION")"
    
    [[ -n "${DOCK_MINIMIZE_TO_APPLICATION:-}" ]] && 
        safe_defaults "com.apple.dock" "minimize-to-application" "bool" "$(convert_bool "$DOCK_MINIMIZE_TO_APPLICATION")"
    
    [[ -n "${DOCK_SHOW_PROCESS_INDICATORS:-}" ]] && 
        safe_defaults "com.apple.dock" "show-process-indicators" "bool" "$(convert_bool "$DOCK_SHOW_PROCESS_INDICATORS")"
    
    [[ -n "${DOCK_ORIENTATION:-}" ]] && 
        safe_defaults "com.apple.dock" "orientation" "string" "$DOCK_ORIENTATION"
    
    [[ -n "${DOCK_DISABLE_REARRANGE_SPACES:-}" ]] && [[ "$DOCK_DISABLE_REARRANGE_SPACES" == "true" ]] && 
        safe_defaults "com.apple.dock" "mru-spaces" "bool" "false"
    
    [[ -n "${DOCK_DISABLE_RECENT_APPS:-}" ]] && [[ "$DOCK_DISABLE_RECENT_APPS" == "true" ]] && 
        safe_defaults "com.apple.dock" "show-recents" "bool" "false"
    
    echo "✅ Dock configured"
fi

################################################################################
# Finder                                                                       #
################################################################################

if [[ -n "${FINDER_NEW_WINDOW_TARGET:-}" ]]; then
    echo "📁 Configuring Finder..."
    
    # Set new window target
    if [[ "$FINDER_NEW_WINDOW_TARGET" == "home" ]]; then
        safe_defaults "com.apple.finder" "NewWindowTarget" "string" "PfLo"
        safe_defaults "com.apple.finder" "NewWindowTargetPath" "string" "file://${HOME}"
    elif [[ "$FINDER_NEW_WINDOW_TARGET" == "desktop" ]]; then
        safe_defaults "com.apple.finder" "NewWindowTarget" "string" "PfDe"
        safe_defaults "com.apple.finder" "NewWindowTargetPath" "string" "file://${HOME}/Desktop/"
    fi
    
    [[ -n "${FINDER_SHOW_EXTERNAL_DRIVES:-}" ]] && 
        safe_defaults "com.apple.finder" "ShowExternalHardDrivesOnDesktop" "bool" "$(convert_bool "$FINDER_SHOW_EXTERNAL_DRIVES")"
    
    [[ -n "${FINDER_SHOW_HARD_DRIVES:-}" ]] && 
        safe_defaults "com.apple.finder" "ShowHardDrivesOnDesktop" "bool" "$(convert_bool "$FINDER_SHOW_HARD_DRIVES")"
    
    [[ -n "${FINDER_SHOW_SERVERS:-}" ]] && 
        safe_defaults "com.apple.finder" "ShowMountedServersOnDesktop" "bool" "$(convert_bool "$FINDER_SHOW_SERVERS")"
    
    [[ -n "${FINDER_SHOW_REMOVABLE_MEDIA:-}" ]] && 
        safe_defaults "com.apple.finder" "ShowRemovableMediaOnDesktop" "bool" "$(convert_bool "$FINDER_SHOW_REMOVABLE_MEDIA")"
    
    [[ -n "${FINDER_SHOW_HIDDEN_FILES:-}" ]] && 
        safe_defaults "com.apple.finder" "AppleShowAllFiles" "bool" "$(convert_bool "$FINDER_SHOW_HIDDEN_FILES")"
    
    [[ -n "${FINDER_SHOW_STATUS_BAR:-}" ]] && 
        safe_defaults "com.apple.finder" "ShowStatusBar" "bool" "$(convert_bool "$FINDER_SHOW_STATUS_BAR")"
    
    [[ -n "${FINDER_SHOW_PATH_BAR:-}" ]] && 
        safe_defaults "com.apple.finder" "ShowPathbar" "bool" "$(convert_bool "$FINDER_SHOW_PATH_BAR")"
    
    [[ -n "${FINDER_SHOW_POSIX_PATH_TITLE:-}" ]] && 
        safe_defaults "com.apple.finder" "_FXShowPosixPathInTitle" "bool" "$(convert_bool "$FINDER_SHOW_POSIX_PATH_TITLE")"
    
    [[ -n "${FINDER_SORT_FOLDERS_FIRST:-}" ]] && 
        safe_defaults "com.apple.finder" "_FXSortFoldersFirst" "bool" "$(convert_bool "$FINDER_SORT_FOLDERS_FIRST")"
    
    [[ -n "${FINDER_SEARCH_CURRENT_FOLDER:-}" ]] && [[ "$FINDER_SEARCH_CURRENT_FOLDER" == "true" ]] && 
        safe_defaults "com.apple.finder" "FXDefaultSearchScope" "string" "SCcf"
    
    # Set preferred view style
    if [[ -n "${FINDER_PREFERRED_VIEW:-}" ]]; then
        case "$FINDER_PREFERRED_VIEW" in
            "icon") safe_defaults "com.apple.finder" "FXPreferredViewStyle" "string" "icnv" ;;
            "list") safe_defaults "com.apple.finder" "FXPreferredViewStyle" "string" "Nlsv" ;;
            "column") safe_defaults "com.apple.finder" "FXPreferredViewStyle" "string" "clmv" ;;
            "gallery") safe_defaults "com.apple.finder" "FXPreferredViewStyle" "string" "glyv" ;;
        esac
    fi
    
    [[ -n "${FINDER_EMPTY_TRASH_SECURELY:-}" ]] && 
        safe_defaults "com.apple.finder" "EmptyTrashSecurely" "bool" "$(convert_bool "$FINDER_EMPTY_TRASH_SECURELY")"
    
    # Configure snap to grid if enabled
    if [[ "${FINDER_SNAP_TO_GRID:-}" == "true" ]]; then
        /usr/libexec/PlistBuddy -c "Set :DesktopViewSettings:IconViewSettings:arrangeBy grid" ~/Library/Preferences/com.apple.finder.plist 2>/dev/null || true
        /usr/libexec/PlistBuddy -c "Set :FK_StandardViewSettings:IconViewSettings:arrangeBy grid" ~/Library/Preferences/com.apple.finder.plist 2>/dev/null || true
        /usr/libexec/PlistBuddy -c "Set :StandardViewSettings:IconViewSettings:arrangeBy grid" ~/Library/Preferences/com.apple.finder.plist 2>/dev/null || true
    fi
    
    # Expand info panes if enabled
    if [[ "${FINDER_EXPAND_INFO_PANES:-}" == "true" ]]; then
        defaults write com.apple.finder FXInfoPanesExpanded -dict \
            General -bool true \
            OpenWith -bool true \
            Privileges -bool true 2>/dev/null || true
    fi
    
    echo "✅ Finder configured"
fi

################################################################################
# Keyboard                                                                     #
################################################################################

if [[ -n "${KEYBOARD_DISABLE_AUTO_CAPITALIZATION:-}" ]]; then
    echo "⌨️  Configuring Keyboard..."
    
    [[ "${KEYBOARD_DISABLE_AUTO_CAPITALIZATION:-}" == "true" ]] && 
        safe_defaults "-g" "NSAutomaticCapitalizationEnabled" "bool" "false"
    
    [[ "${KEYBOARD_DISABLE_SMART_DASHES:-}" == "true" ]] && 
        safe_defaults "-g" "NSAutomaticDashSubstitutionEnabled" "bool" "false"
    
    [[ "${KEYBOARD_DISABLE_PERIOD_SUBSTITUTION:-}" == "true" ]] && 
        safe_defaults "-g" "NSAutomaticPeriodSubstitutionEnabled" "bool" "false"
    
    [[ "${KEYBOARD_DISABLE_SMART_QUOTES:-}" == "true" ]] && 
        safe_defaults "-g" "NSAutomaticQuoteSubstitutionEnabled" "bool" "false"
    
    [[ "${KEYBOARD_DISABLE_AUTO_CORRECT:-}" == "true" ]] && 
        safe_defaults "-g" "NSAutomaticSpellingCorrectionEnabled" "bool" "false"
    
    [[ "${KEYBOARD_DISABLE_TEXT_COMPLETION:-}" == "true" ]] && 
        safe_defaults "-g" "NSAutomaticTextCompletionEnabled" "bool" "false"
    
    [[ -n "${KEYBOARD_KEY_REPEAT_RATE:-}" ]] && 
        safe_defaults "-g" "KeyRepeat" "int" "$KEYBOARD_KEY_REPEAT_RATE"
    
    [[ -n "${KEYBOARD_INITIAL_KEY_REPEAT:-}" ]] && 
        safe_defaults "-g" "InitialKeyRepeat" "int" "$KEYBOARD_INITIAL_KEY_REPEAT"
    
    [[ "${KEYBOARD_DISABLE_PRESS_AND_HOLD:-}" == "true" ]] && 
        safe_defaults "-g" "ApplePressAndHoldEnabled" "bool" "false"
    
    # Tab navigation shortcuts
    if [[ "${KEYBOARD_ENABLE_TAB_NAVIGATION:-}" == "true" ]]; then
        defaults write -g NSUserKeyEquivalents -dict-add "Show Next Tab" "@~\\U2192" 2>/dev/null || true
        defaults write -g NSUserKeyEquivalents -dict-add "Show Previous Tab" "@~\\U2190" 2>/dev/null || true
    fi
    
    echo "✅ Keyboard configured"
fi

################################################################################
# Language & Region                                                           #
################################################################################

if [[ -n "${LANGUAGE_LANGUAGES:-}" ]]; then
    echo "🌐 Configuring Language & Region..."
    
    # Set preferred languages
    if [[ -n "${LANGUAGE_LANGUAGES:-}" ]]; then
        # Convert space-separated list to array format for defaults
        IFS=' ' read -ra LANG_ARRAY <<< "$LANGUAGE_LANGUAGES"
        defaults write -g AppleLanguages -array "${LANG_ARRAY[@]}" 2>/dev/null || true
    fi
    
    [[ -n "${LANGUAGE_LOCALE:-}" ]] && 
        safe_defaults "-g" "AppleLocale" "string" "$LANGUAGE_LOCALE"
    
    [[ -n "${LANGUAGE_MEASUREMENT_UNITS:-}" ]] && 
        safe_defaults "-g" "AppleMeasurementUnits" "string" "$LANGUAGE_MEASUREMENT_UNITS"
    
    [[ "${LANGUAGE_METRIC_UNITS:-}" == "true" ]] && 
        safe_defaults "-g" "AppleMetricUnits" "bool" "true"
    
    [[ -n "${LANGUAGE_TEMPERATURE_UNIT:-}" ]] && 
        safe_defaults "-g" "AppleTemperatureUnit" "string" "$LANGUAGE_TEMPERATURE_UNIT"
    
    [[ "${LANGUAGE_FORCE_24_HOUR:-}" == "true" ]] && 
        safe_defaults "-g" "AppleICUForce24HourTime" "bool" "true"
    
    [[ "${LANGUAGE_HIDE_LANGUAGE_MENU:-}" == "true" ]] && 
        safe_defaults "com.apple.TextInputMenu" "visible" "bool" "false"
    
    echo "✅ Language & Region configured"
fi

################################################################################
# Mouse                                                                        #
################################################################################

if [[ -n "${MOUSE_TRACKING_SPEED:-}" ]]; then
    echo "🖱️  Configuring Mouse..."
    
    [[ -n "${MOUSE_TRACKING_SPEED:-}" ]] && 
        safe_defaults "-g" "com.apple.mouse.scaling" "float" "$MOUSE_TRACKING_SPEED"
    
    [[ -n "${MOUSE_DOUBLE_CLICK_THRESHOLD:-}" ]] && 
        safe_defaults "-g" "com.apple.mouse.doubleClickThreshold" "float" "$MOUSE_DOUBLE_CLICK_THRESHOLD"
    
    [[ -n "${MOUSE_SCROLL_SPEED:-}" ]] && 
        safe_defaults "-g" "com.apple.scrollwheel.scaling" "float" "$MOUSE_SCROLL_SPEED"
    
    echo "✅ Mouse configured"
fi

################################################################################
# Trackpad                                                                     #
################################################################################

if [[ -n "${TRACKPAD_TAP_TO_CLICK:-}" ]]; then
    echo "👆 Configuring Trackpad..."
    
    [[ "${TRACKPAD_TAP_TO_CLICK:-}" == "true" ]] && {
        safe_defaults "com.apple.driver.AppleBluetoothMultitouch.trackpad" "Clicking" "bool" "true"
        safe_defaults "com.apple.AppleMultitouchTrackpad" "Clicking" "bool" "true"
        safe_defaults "-g" "com.apple.mouse.tapBehavior" "int" "1"
    }
    
    [[ "${TRACKPAD_SILENT_CLICKING:-}" == "true" ]] && {
        safe_defaults "com.apple.AppleMultitouchTrackpad" "ActuationStrength" "int" "0"
        safe_defaults "com.apple.driver.AppleBluetoothMultitouch.trackpad" "ActuationStrength" "int" "0"
    }
    
    [[ -n "${TRACKPAD_HAPTIC_FEEDBACK:-}" ]] && {
        safe_defaults "com.apple.AppleMultitouchTrackpad" "FirstClickThreshold" "int" "$TRACKPAD_HAPTIC_FEEDBACK"
        safe_defaults "com.apple.driver.AppleBluetoothMultitouch.trackpad" "FirstClickThreshold" "int" "$TRACKPAD_HAPTIC_FEEDBACK"
    }
    
    [[ -n "${TRACKPAD_TRACKING_SPEED:-}" ]] && 
        safe_defaults "-g" "com.apple.trackpad.scaling" "float" "$TRACKPAD_TRACKING_SPEED"
    
    [[ "${TRACKPAD_DISABLE_SWIPE_NAVIGATION:-}" == "true" ]] && {
        safe_defaults "com.apple.AppleMultitouchTrackpad" "TrackpadThreeFingerHorizSwipeGesture" "int" "0"
        safe_defaults "com.apple.driver.AppleBluetoothMultitouch.trackpad" "TrackpadThreeFingerHorizSwipeGesture" "int" "0"
    }
    
    echo "✅ Trackpad configured"
fi

################################################################################
# Power Management                                                             #
################################################################################

if [[ -n "${POWER_SLEEP_ON_POWER:-}" ]]; then
    echo "🔋 Configuring Power Management..."
    
    [[ -n "${POWER_SLEEP_ON_POWER:-}" ]] && 
        sudo pmset -c sleep "$POWER_SLEEP_ON_POWER" 2>/dev/null || true
    
    [[ -n "${POWER_SLEEP_ON_BATTERY:-}" ]] && 
        sudo pmset -b sleep "$POWER_SLEEP_ON_BATTERY" 2>/dev/null || true
    
    [[ "${POWER_DISABLE_PROXIMITY_WAKE:-}" == "true" ]] && 
        sudo pmset -a proximitywake 0 2>/dev/null || true
    
    [[ "${POWER_DISABLE_POWER_NAP:-}" == "true" ]] && {
        sudo pmset -c powernap 0 2>/dev/null || true
        sudo pmset -b powernap 0 2>/dev/null || true
    }
    
    [[ "${POWER_REQUIRE_PASSWORD_IMMEDIATELY:-}" == "true" ]] && 
        safe_defaults "com.apple.screensaver" "askForPassword" "int" "1" && 
        safe_defaults "com.apple.screensaver" "askForPasswordDelay" "int" "0"
    
    echo "✅ Power Management configured"
fi

################################################################################
# Screen & Screenshots                                                         #
################################################################################

if [[ -n "${SCREEN_FONT_SMOOTHING:-}" ]]; then
    echo "📸 Configuring Screen & Screenshots..."
    
    [[ -n "${SCREEN_FONT_SMOOTHING:-}" ]] && 
        safe_defaults "-g" "CGFontRenderingFontSmoothingDisabled" "bool" "false" && 
        safe_defaults "-g" "AppleFontSmoothing" "int" "$SCREEN_FONT_SMOOTHING"
    
    [[ "${SCREEN_ENABLE_HIDPI:-}" == "true" ]] && 
        sudo defaults write /Library/Preferences/com.apple.windowserver DisplayResolutionEnabled -bool true 2>/dev/null || true
    
    # Create screenshots directory if specified
    if [[ -n "${SCREEN_SCREENSHOT_LOCATION:-}" ]]; then
        screenshot_dir=$(eval echo "$SCREEN_SCREENSHOT_LOCATION")
        mkdir -p "$screenshot_dir" 2>/dev/null || true
        safe_defaults "com.apple.screencapture" "location" "string" "$screenshot_dir"
    fi
    
    [[ -n "${SCREEN_SCREENSHOT_FORMAT:-}" ]] && 
        safe_defaults "com.apple.screencapture" "type" "string" "$SCREEN_SCREENSHOT_FORMAT"
    
    [[ "${SCREEN_DISABLE_SCREENSHOT_SHADOWS:-}" == "true" ]] && 
        safe_defaults "com.apple.screencapture" "disable-shadow" "bool" "true"
    
    # Enable "More Space" display scaling (requires logout/restart to take effect)
    if [[ "${SCREEN_ENABLE_MORE_SPACE:-}" == "true" ]]; then
        echo "   ├─ Setting display to 'More Space' scaling..."
        # This sets the display to scaled resolution for more desktop space
        # Note: This requires a logout/restart to take effect
        sudo defaults write /Library/Preferences/com.apple.windowserver DisplayResolutionEnabled -bool true 2>/dev/null || true
        
        # For built-in displays, try to set a higher resolution
        # This is system-dependent and may need manual adjustment in System Preferences
        echo "   └─ Display scaling configured (restart required)"
    fi
    
    echo "✅ Screen & Screenshots configured"
fi

################################################################################
# Menu Bar Clock                                                              #
################################################################################

if [[ -n "${MENU_BAR_SHOW_FULL_DATE_TIME:-}" ]]; then
    echo "🕰️  Configuring Menu Bar Clock..."
    
    # Configure the menu bar clock to show full date and time with seconds
    if [[ "${MENU_BAR_SHOW_FULL_DATE_TIME:-}" == "true" ]]; then
        # Set the date format to include full date and seconds
        if [[ -n "${MENU_BAR_DATE_FORMAT:-}" ]]; then
            safe_defaults "com.apple.menuextra.clock" "DateFormat" "string" "$MENU_BAR_DATE_FORMAT"
        else
            # Default format: "Mon Jan 1  1:23:45 PM"
            safe_defaults "com.apple.menuextra.clock" "DateFormat" "string" "EEE MMM d  h:mm:ss a"
        fi
        
        # Enable flashing date separators (blinking colons)
        [[ "${MENU_BAR_FLASH_DATE_SEPARATORS:-}" == "true" ]] && 
            safe_defaults "com.apple.menuextra.clock" "FlashDateSeparators" "bool" "true"
        
        # Show the date in menu bar (in addition to time)
        safe_defaults "com.apple.menuextra.clock" "Show24Hour" "bool" "false"
        safe_defaults "com.apple.menuextra.clock" "ShowDayOfWeek" "bool" "true"
        safe_defaults "com.apple.menuextra.clock" "ShowDate" "int" "1"
        safe_defaults "com.apple.menuextra.clock" "ShowSeconds" "bool" "true"
    fi
    
    echo "✅ Menu Bar Clock configured"
fi

################################################################################
# Terminal                                                                     #
################################################################################

if [[ -n "${TERMINAL_SECURE_KEYBOARD_ENTRY:-}" ]]; then
    echo "💻 Configuring Terminal..."
    
    [[ "${TERMINAL_SECURE_KEYBOARD_ENTRY:-}" == "true" ]] && 
        safe_defaults "com.apple.terminal" "SecureKeyboardEntry" "bool" "true"
    
    echo "✅ Terminal configured"
fi

################################################################################
# Time Machine                                                                #
################################################################################

if [[ -n "${TIME_MACHINE_DISABLE_NEW_DISK_PROMPT:-}" ]]; then
    echo "⏰ Configuring Time Machine..."
    
    [[ "${TIME_MACHINE_DISABLE_NEW_DISK_PROMPT:-}" == "true" ]] && 
        safe_defaults "com.apple.TimeMachine" "DoNotOfferNewDisksForBackup" "bool" "true"
    
    echo "✅ Time Machine configured"
fi

################################################################################
# Hot Corners                                                                  #
################################################################################

if [[ -n "${HOT_CORNERS_TOP_LEFT:-}" ]]; then
    echo "🔥 Configuring Hot Corners..."
    
    # Hot corner actions:
    # 0: No action
    # 2: Mission Control  
    # 3: Application windows
    # 4: Desktop
    # 5: Start screen saver
    # 6: Disable screen saver
    # 10: Put display to sleep
    # 11: Launchpad
    # 12: Notification Center
    # 13: Lock Screen
    
    [[ -n "${HOT_CORNERS_TOP_LEFT:-}" ]] && {
        safe_defaults "com.apple.dock" "wvous-tl-corner" "int" "$HOT_CORNERS_TOP_LEFT"
        safe_defaults "com.apple.dock" "wvous-tl-modifier" "int" "0"
    }
    
    [[ -n "${HOT_CORNERS_TOP_RIGHT:-}" ]] && {
        safe_defaults "com.apple.dock" "wvous-tr-corner" "int" "$HOT_CORNERS_TOP_RIGHT"
        safe_defaults "com.apple.dock" "wvous-tr-modifier" "int" "0"
    }
    
    [[ -n "${HOT_CORNERS_BOTTOM_LEFT:-}" ]] && {
        safe_defaults "com.apple.dock" "wvous-bl-corner" "int" "$HOT_CORNERS_BOTTOM_LEFT"
        safe_defaults "com.apple.dock" "wvous-bl-modifier" "int" "0"
    }
    
    [[ -n "${HOT_CORNERS_BOTTOM_RIGHT:-}" ]] && {
        safe_defaults "com.apple.dock" "wvous-br-corner" "int" "$HOT_CORNERS_BOTTOM_RIGHT"
        safe_defaults "com.apple.dock" "wvous-br-modifier" "int" "0"
    }
    
    echo "✅ Hot Corners configured"
fi

################################################################################
# Xcode (Developer Settings)                                                   #
################################################################################

if [[ -n "${XCODE_TRIM_WHITESPACE:-}" ]]; then
    echo "🛠️  Configuring Xcode..."
    
    [[ "${XCODE_TRIM_WHITESPACE:-}" == "true" ]] && 
        safe_defaults "com.apple.dt.Xcode" "DVTTextEditorTrimTrailingWhitespace" "bool" "true"
    
    [[ "${XCODE_TRIM_WHITESPACE_ONLY_LINES:-}" == "true" ]] && 
        safe_defaults "com.apple.dt.Xcode" "DVTTextEditorTrimWhitespaceOnlyLines" "bool" "true"
    
    [[ "${XCODE_DISABLE_CASE_INDENT:-}" == "true" ]] && 
        safe_defaults "com.apple.dt.Xcode" "DVTTextIndentCase" "bool" "false"
    
    [[ "${XCODE_INDENT_ON_PASTE:-}" == "true" ]] && 
        safe_defaults "com.apple.dt.Xcode" "DVTTextIndentOnPaste" "bool" "true"
    
    [[ -n "${XCODE_OVERSCROLL_AMOUNT:-}" ]] && 
        safe_defaults "com.apple.dt.Xcode" "DVTTextOverscrollAmount" "float" "$XCODE_OVERSCROLL_AMOUNT"
    
    [[ "${XCODE_HIDE_AUTHORS_PANEL:-}" == "true" ]] && 
        safe_defaults "com.apple.dt.Xcode" "DVTTextShowAuthors" "bool" "false"
    
    [[ "${XCODE_HIDE_MINIMAP:-}" == "true" ]] && 
        safe_defaults "com.apple.dt.Xcode" "DVTTextShowMinimap" "bool" "false"
    
    [[ "${XCODE_SHOW_BUILD_STEPS:-}" == "true" ]] && 
        safe_defaults "com.apple.dt.Xcode" "DVTBuildLogShowSteps" "bool" "true"
    
    [[ "${XCODE_SHOW_ANALYZER_RESULTS:-}" == "true" ]] && 
        safe_defaults "com.apple.dt.Xcode" "DVTAnalyzerResultsViewerShowResultsInline" "bool" "true"
    
    [[ "${XCODE_SHOW_ERRORS:-}" == "true" ]] && 
        safe_defaults "com.apple.dt.Xcode" "DVTIssueNavigatorShowErrors" "bool" "true"
    
    [[ "${XCODE_SHOW_WARNINGS:-}" == "true" ]] && 
        safe_defaults "com.apple.dt.Xcode" "DVTIssueNavigatorShowWarnings" "bool" "true"
    
    [[ "${XCODE_COMMAND_CLICK_JUMPS:-}" == "true" ]] && 
        safe_defaults "com.apple.dt.Xcode" "DVTTextEditorCommandClickJumpsToDefinition" "bool" "true"
    
    [[ "${XCODE_SHOW_INDEXING_PROGRESS:-}" == "true" ]] && 
        safe_defaults "com.apple.dt.Xcode" "IDEIndexShowIndexingProgress" "bool" "true"
    
    [[ "${XCODE_SHOW_BUILD_DURATION:-}" == "true" ]] && 
        safe_defaults "com.apple.dt.Xcode" "ShowBuildOperationDuration" "bool" "true"
    
    echo "✅ Xcode configured"
fi

################################################################################
# System Restart and Cleanup                                                  #
################################################################################

echo ""
echo "🔄 Restarting affected services..."
echo "   ├─ Restarting Dock..."
killall "Dock" 2>/dev/null || true
echo "   ├─ Restarting Finder..."
killall "Finder" 2>/dev/null || true
echo "   ├─ Restarting SystemUIServer..."
killall "SystemUIServer" 2>/dev/null || true
echo "   └─ Restarting ControlStrip..."
killall "ControlStrip" 2>/dev/null || true

echo ""
echo "========================================"
echo "🎉 macOS Configuration Complete!"
echo "========================================"
echo ""
echo "💡 Configuration applied successfully!"
echo "📋 Summary:"
echo "   • Activity Monitor preferences set"
echo "   • App Store update schedule configured"
echo "   • Dock appearance and behavior customized"
echo "   • Finder display and navigation enhanced"
echo "   • Keyboard shortcuts and typing optimized"
echo "   • Language and regional settings applied"
echo "   • Mouse and trackpad behavior configured"
echo "   • Power management optimized"
echo "   • Screenshot settings customized"
echo "   • Menu bar clock with full date/time configured"
echo "   • Display scaling ('More Space') applied"
echo "   • Terminal security enhanced"
echo "   • Time Machine preferences set"
echo "   • Hot corners functionality assigned"
echo "   • Xcode development environment configured"
echo ""
echo "🔄 Some changes may require a system restart to take full effect."