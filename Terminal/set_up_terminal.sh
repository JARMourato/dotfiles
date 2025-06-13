#!/bin/bash

################################################################################
### Set up terminal environment with oh-my-zsh, powerline, and custom theme
################################################################################

echo "========================================"
echo "🖥️  Setting up terminal environment..."
echo "========================================"
echo ""

# Shamelessly copied from https://stackoverflow.com/a/246128/4075379
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# Prerequisite:
# - git
# - git SSH
# - pyenv installed & running (`which python3` must point to pyenv shims)

echo "🐚 Installing oh-my-zsh..."
# Check if oh-my-zsh is already installed
if [[ -d "$HOME/.oh-my-zsh" ]]; then
    echo "✅ oh-my-zsh already installed"
else
    # Install oh-my-zsh
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    echo "✅ oh-my-zsh installed"
fi

echo "🔤 Installing powerline fonts..."
# Check if Meslo LG fonts are already installed
if ls ~/Library/Fonts/Meslo* >/dev/null 2>&1; then
    echo "✅ Powerline fonts already installed"
else
    # Install powerline-shell font "Meslo Slashed"
    git clone https://github.com/powerline/fonts.git --depth=1
    cd fonts
    # This script uses a string argument to look for font with prefixes with the given string
    ./install.sh "Meslo LG"
    cd ..
    rm -rf fonts
    echo "✅ Powerline fonts installed"
fi

echo "⚡ Installing powerline-shell..."
# Check if powerline-shell is already installed
if command -v powerline-shell >/dev/null 2>&1; then
    echo "✅ powerline-shell already installed"
else
    # Install powerline-shell
    git clone https://github.com/b-ryan/powerline-shell.git --depth=1
    cd powerline-shell
    python3 setup.py install # Note that this must be run only after pyenv has already been installed and is
    cd ..
    rm -rf powerline-shell
    echo "✅ Powerline-shell installed"
fi

echo "🎨 Configuring custom terminal theme..."
# Open my custom Solarized Dark theme to apply it on Terminal
open $DIR/Highway.terminal

# Make this theme the default one
defaults write com.apple.Terminal "Default Window Settings" -string "Highway"
defaults write com.apple.Terminal "Startup Window Settings" -string "Highway"

# Apply the theme to all open terminal windows using AppleScript
osascript <<EOF
tell application "Terminal"
    set default settings to settings set "Highway"
    repeat with w in windows
        repeat with t in tabs of w
            set current settings of t to settings set "Highway"
        end repeat
    end repeat
end tell
EOF

# Ensure font is properly set (fallback to Menlo if Meslo not available)
osascript <<EOF
tell application "Terminal"
    set fontName to "MesloLGS-Regular"
    set fontSize to 11
    
    -- Check if Meslo font exists, otherwise use Menlo
    try
        set font name of default settings to fontName
    on error
        set font name of default settings to "Menlo-Regular"
    end try
    
    set font size of default settings to fontSize
    
    -- Apply to all open windows
    repeat with w in windows
        repeat with t in tabs of w
            try
                set font name of current settings of t to fontName
            on error
                set font name of current settings of t to "Menlo-Regular"
            end try
            set font size of current settings of t to fontSize
        end repeat
    end repeat
end tell
EOF

echo "✅ Highway theme set as default and applied to current windows"

echo "⚙️  Configuring powerline-shell..."
echo "   └─ Copying powerline configuration..."
mkdir -p $HOME/.config/powerline-shell/
cp $DOTFILES_DIR/Terminal/powerline-shell-config.json $HOME/.config/powerline-shell/config.json
echo "✅ Powerline-shell configured"

echo ""
echo "========================================"
echo "🎉 Terminal Setup Complete!"
echo "========================================"
echo ""
echo "💡 Restart Terminal to see the new theme and powerline prompt"
