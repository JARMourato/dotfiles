# Configuration Guide

This guide explains how to customize your dotfiles system to install exactly what you want on your Mac.

## Configuration File Overview

Your main configuration lives in `.dotfiles.config` in your dotfiles directory. This file controls:

- Which packages get installed
- What setup steps are skipped
- Environment-specific settings
- Personal vs work configurations

## Creating Your Configuration

### Location and Format

Create your configuration file before running setup:

```bash
# Create the configuration file
touch ~/.dotfiles.config

# Or if you already have dotfiles installed
touch ~/.dotfiles/.dotfiles.config
```

The format is simple shell variables:

```bash
# This is a comment
VARIABLE_NAME="value"
ANOTHER_VARIABLE="multiple values separated by spaces"
```

## Package Configuration

### Core Package Lists

These are the main package categories you can customize:

```bash
# Command-line tools (Homebrew formulas)
HOMEBREW_FORMULAS="git jq curl wget htop tree bat fd ripgrep"

# GUI Applications (Homebrew casks)
HOMEBREW_CASKS="visual-studio-code google-chrome firefox slack"

# Mac App Store applications (format: appid:name)
MAS_APPS="904280696:Things_3 1477385213:Save_to_Pocket"

# QuickLook plugins for file preview
QUICKLOOK_PLUGINS="qlcolorcode qlmarkdown qlstephen"
```

### Package Categories by Use Case

#### Development Tools
```bash
# Essential development
HOMEBREW_FORMULAS="git gh hub jq yq curl wget"

# Text editors and IDEs
HOMEBREW_CASKS="visual-studio-code sublime-text"

# Version control
HOMEBREW_CASKS="sourcetree github-desktop"
```

#### Language-Specific Tools

**Swift/iOS Development:**
```bash
HOMEBREW_FORMULAS="swiftlint swiftformat carthage cocoapods"
HOMEBREW_CASKS="xcode simulator sf-symbols"
```

**Web Development:**
```bash
HOMEBREW_FORMULAS="node yarn typescript"
HOMEBREW_CASKS="chrome firefox firefox-developer-edition"
```

**Python Development:**
```bash
HOMEBREW_FORMULAS="python pyenv pipenv"
HOMEBREW_CASKS="anaconda pycharm"
```

**DevOps/Cloud:**
```bash
HOMEBREW_FORMULAS="docker kubernetes-cli terraform ansible aws-cli"
HOMEBREW_CASKS="docker"
```

#### Productivity Tools
```bash
HOMEBREW_CASKS="notion obsidian alfred rectangle bitwarden"
MAS_APPS="904280696:Things_3 1295203466:Microsoft_Remote_Desktop"
```

#### Media and Creative
```bash
HOMEBREW_CASKS="figma sketch adobe-creative-cloud vlc iina"
```

## Setup Behavior Control

### Skip Major Categories

Skip entire categories if you don't need them:

```bash
# Skip major installation categories
SKIP_XCODE=true           # Skip Xcode command line tools
SKIP_HOMEBREW=false       # Don't skip Homebrew (not recommended)
SKIP_MAS_APPS=true        # Skip Mac App Store applications
SKIP_RUBY_INSTALL=true    # Skip Ruby and gems
SKIP_PYTHON_INSTALL=false # Don't skip Python setup
SKIP_NODE_INSTALL=false   # Don't skip Node.js setup
```

### Setup Modes

Control the overall behavior:

```bash
# Setup mode affects default package selection
SETUP_MODE="personal"     # or "work", "minimal"

# Minimal mode installs only essential tools
MINIMAL_PACKAGES=true

# Auto-detect development environment
AUTO_DETECT_ENV=true

# Create system snapshot before changes
CREATE_SNAPSHOT=true
```

### Package Filtering

Fine-tune what gets installed:

```bash
# Skip specific packages (even if auto-detected)
SKIP_PACKAGES="spotify telegram discord games"

# Additional packages for personal use
PERSONAL_PACKAGES="spotify telegram whatsapp zoom iina"

# Additional packages for work
WORK_PACKAGES="slack teams zoom microsoft-office"
```

## Environment-Specific Configuration

### Work vs Personal

Set up different configurations for work and personal use:

```bash
# Work configuration
SETUP_MODE="work"
SKIP_PACKAGES="spotify telegram discord games entertainment"
WORK_PACKAGES="slack teams zoom microsoft-office"
HOMEBREW_CASKS="1password-cli corporate-vpn"
```

```bash
# Personal configuration
SETUP_MODE="personal"
PERSONAL_PACKAGES="spotify telegram whatsapp discord"
HOMEBREW_CASKS="steam epic-games discord spotify"
```

### Development Environment Types

Configure for your primary development focus:

```bash
# Affects auto-detection and default packages
DEVELOPMENT_TYPE="web"    # or "ios", "python", "devops", "general"
```

**Available development types:**
- `web`: Node.js, TypeScript, web browsers, VS Code
- `ios`: Xcode, SwiftLint, Simulator, iOS tools
- `python`: Python, pyenv, data science tools
- `devops`: Docker, Kubernetes, cloud CLIs
- `general`: Balanced selection of tools

## Security and Encryption

### SSH and Git Configuration

```bash
# Git configuration
GIT_NAME="Your Name"
GIT_EMAIL="your.email@example.com"

# SSH key settings
SSH_KEY_TYPE="ed25519"    # or "rsa"
SSH_KEY_BITS="4096"       # for RSA keys

# Auto-configure Git with SSH
AUTO_SETUP_GIT_SSH=true
```

### File Encryption Settings

```bash
# Encryption method for sensitive files
ENCRYPTION_METHOD="age"   # or "openssl"

# Secrets rotation warnings
SECRETS_WARNING_DAYS=90   # Warn when secrets are 90 days old
SECRETS_CRITICAL_DAYS=180 # Critical warning at 180 days
```

## Complete Configuration Examples

### Example 1: Web Developer (Personal Machine)

```bash
# ~/.dotfiles.config
SETUP_MODE="personal"
DEVELOPMENT_TYPE="web"

# Core development tools
HOMEBREW_FORMULAS="git gh node yarn typescript eslint prettier"
HOMEBREW_CASKS="visual-studio-code chrome firefox figma"

# Personal apps
PERSONAL_PACKAGES="spotify discord telegram"

# Skip what I don't need
SKIP_XCODE=true
SKIP_RUBY_INSTALL=true
MAS_APPS=""

# Git setup
GIT_NAME="John Doe"
GIT_EMAIL="john@example.com"
AUTO_SETUP_GIT_SSH=true
```

### Example 2: iOS Developer (Work Machine)

```bash
# ~/.dotfiles.config
SETUP_MODE="work"
DEVELOPMENT_TYPE="ios"

# iOS development tools
HOMEBREW_FORMULAS="git gh swiftlint swiftformat carthage cocoapods"
HOMEBREW_CASKS="xcode simulator sf-symbols proxyman"

# Work applications
WORK_PACKAGES="slack teams zoom"

# Skip personal stuff
SKIP_PACKAGES="spotify discord telegram games"

# Need Xcode for iOS development
SKIP_XCODE=false

# Company Git config
GIT_NAME="John Doe"
GIT_EMAIL="john.doe@company.com"
```

### Example 3: Data Scientist

```bash
# ~/.dotfiles.config
SETUP_MODE="personal"
DEVELOPMENT_TYPE="python"

# Data science tools
HOMEBREW_FORMULAS="python pyenv jupyter pandas numpy scipy matplotlib"
HOMEBREW_CASKS="anaconda rstudio tableau-public"

# Research tools
ADDITIONAL_CASKS="papers mendeley zotero"

# Skip unneeded development tools
SKIP_XCODE=true
SKIP_NODE_INSTALL=true
```

### Example 4: Minimal Setup

```bash
# ~/.dotfiles.config
SETUP_MODE="minimal"
MINIMAL_PACKAGES=true

# Only essential tools
HOMEBREW_FORMULAS="git jq curl wget"
HOMEBREW_CASKS=""

# Skip everything optional
SKIP_XCODE=true
SKIP_MAS_APPS=true
SKIP_RUBY_INSTALL=true
SKIP_PYTHON_INSTALL=true
SKIP_NODE_INSTALL=true
```

## Advanced Configuration

### Custom Package Sources

Add custom Homebrew taps:

```bash
# Additional Homebrew taps
CUSTOM_TAPS="homebrew/cask-fonts homebrew/cask-drivers"

# Packages from custom taps
CUSTOM_FORMULAS="font-fira-code font-source-code-pro"
```

### Environment Variables

Set environment variables that persist:

```bash
# Custom environment variables
CUSTOM_ENV_VARS="EDITOR=code BROWSER=chrome LANG=en_US.UTF-8"
```

### Shell Configuration

Customize shell behavior:

```bash
# Shell selection
SHELL_TYPE="zsh"          # or "bash"

# Shell theme/prompt
SHELL_THEME="powerline"   # or "minimal", "custom"

# Enable shell features
ENABLE_AUTOSUGGESTIONS=true
ENABLE_SYNTAX_HIGHLIGHTING=true
```

## Applying Configuration Changes

### For New Setups

Just create your `.dotfiles.config` file before running bootstrap:

```bash
# Create your config
vim ~/.dotfiles.config

# Run setup
bash <(curl -Lks https://raw.githubusercontent.com/JARMourato/dotfiles/main/bootstrap.sh)
```

### For Existing Installations

Update your configuration and re-run setup:

```bash
# Edit your configuration
cd ~/.dotfiles
vim .dotfiles.config

# Apply changes
./Scripts/setup_wizard.sh --reconfigure

# Or re-run specific parts
setup-deps              # Re-install dependencies
setup-symlinks          # Re-create symlinks
```

### Validating Configuration

Check your configuration before applying:

```bash
# Preview what would be installed
./Scripts/setup_wizard.sh --dry-run

# Validate configuration syntax
./Scripts/manage_config.sh validate
```

## Next Steps

- **[Getting Started](getting-started.md)** - Basic setup walkthrough
- **[Multi-Machine Sync](sync-guide.md)** - Sync configs across machines
- **[Health Monitoring](health-monitoring.md)** - Keep your system healthy
- **[Advanced Usage](advanced-usage.md)** - Custom plugins and scripts