# Getting Started with Dotfiles

This guide walks you through setting up your Mac development environment from scratch using this dotfiles system.

## What This Will Do

This system will transform your Mac into a fully configured development environment by:

- Installing essential development tools (Git, Homebrew, terminal utilities)
- Setting up your preferred programming languages and frameworks
- Configuring your terminal with a modern shell and prompt
- Installing GUI applications you choose
- Setting up SSH keys for GitHub
- Configuring macOS system preferences
- Creating a synchronized environment that works across multiple machines

## Before You Start

### Prerequisites

- **macOS 10.15+** (Catalina or newer)
- **Admin access** on your Mac
- **Internet connection** for downloading tools
- **Apple ID** (if you want Mac App Store apps)

### What You'll Need to Decide

1. **Setup Mode**: How comprehensive do you want the setup?
2. **Development Focus**: What type of development do you do?
3. **Applications**: Which GUI apps do you want installed?
4. **Personal vs Work**: Are you setting up a work or personal machine?

## Step 1: Choose Your Setup Mode

### Quick Start (30 seconds)
Perfect for trying out the system or when you're in a hurry:

```bash
bash <(curl -Lks https://raw.githubusercontent.com/JARMourato/dotfiles/main/bootstrap.sh) --quick
```

**What gets installed:**
- Essential CLI tools: git, jq, curl, wget
- Basic security tools
- Terminal configuration

### Full Setup (5-10 minutes)
Complete development environment setup:

```bash
bash <(curl -Lks https://raw.githubusercontent.com/JARMourato/dotfiles/main/bootstrap.sh)
```

**What gets installed:**
- Everything from Quick Start
- Development tools for detected languages
- GUI applications
- System configuration
- Optional: Mac App Store apps

### Interactive Setup (Recommended for first-time users)
Guided setup with explanations and choices:

```bash
# First, do the quick start to get basic tools
bash <(curl -Lks https://raw.githubusercontent.com/JARMourato/dotfiles/main/bootstrap.sh) --quick

# Then run the interactive wizard
cd ~/.dotfiles
./Scripts/setup_wizard.sh --interactive
```

## Step 2: What Happens During Setup

### Phase 1: System Preparation
1. **System Check**: Verifies you have enough disk space and internet
2. **SSH Keys**: Creates GitHub SSH keys if needed (you'll be guided through GitHub setup)
3. **Xcode Tools**: Installs Apple's command line developer tools
4. **Repository**: Downloads the dotfiles to `~/.dotfiles`

### Phase 2: Core Installation
1. **Homebrew**: Installs the macOS package manager
2. **Essential Tools**: Installs git, curl, and other basic utilities
3. **Shell Setup**: Configures zsh with modern features

### Phase 3: Development Environment
1. **Language Detection**: Scans your directories for projects
2. **Tool Installation**: Installs relevant development tools
3. **Configuration**: Sets up editors, linters, and formatters

### Phase 4: Applications & System
1. **GUI Apps**: Installs applications via Homebrew Cask
2. **Mac App Store**: Optionally installs paid apps you own
3. **System Preferences**: Configures macOS settings
4. **Dotfiles**: Creates symlinks for configuration files

## Step 3: Customize What Gets Installed

### Before Running Setup
Create a customization file to control what gets installed:

```bash
# Create your customization (optional)
cat > ~/.dotfiles.config << 'EOF'
# Development focus (affects auto-detection)
DEVELOPMENT_TYPE="web"  # or "ios", "python", "general"

# Setup mode
SETUP_MODE="personal"   # or "work", "minimal"

# Skip certain categories
SKIP_XCODE=false
SKIP_HOMEBREW=false
SKIP_MAS_APPS=true      # Skip Mac App Store apps

# Additional packages to install
ADDITIONAL_FORMULAS="docker kubernetes-cli terraform"
ADDITIONAL_CASKS="visual-studio-code figma notion"

# Packages to skip (even if auto-detected)
SKIP_PACKAGES="spotify telegram"
EOF
```

### Common Configuration Examples

#### For iOS/Swift Development:
```bash
DEVELOPMENT_TYPE="ios"
ADDITIONAL_FORMULAS="swiftlint swiftformat carthage"
ADDITIONAL_CASKS="xcode simulator sf-symbols"
```

#### For Web Development:
```bash
DEVELOPMENT_TYPE="web"
ADDITIONAL_FORMULAS="node yarn typescript"
ADDITIONAL_CASKS="visual-studio-code chrome firefox"
```

#### For Data Science:
```bash
DEVELOPMENT_TYPE="python"
ADDITIONAL_FORMULAS="python jupyter pandas numpy"
ADDITIONAL_CASKS="anaconda r rstudio"
```

#### For Work/Corporate Environment:
```bash
SETUP_MODE="work"
SKIP_PACKAGES="spotify telegram discord games"
ADDITIONAL_CASKS="slack zoom teams microsoft-office"
```

## Step 4: Run the Setup

### If You Created a Config File:
```bash
bash <(curl -Lks https://raw.githubusercontent.com/JARMourato/dotfiles/main/bootstrap.sh)
```

### If You Want Interactive Choices:
```bash
bash <(curl -Lks https://raw.githubusercontent.com/JARMourato/dotfiles/main/bootstrap.sh) --interactive
```

## Step 5: What to Expect

### During Setup:
- **Progress indicators** show what's happening
- **Prompts** ask for your input when needed (passwords, confirmations)
- **Logs** are saved for troubleshooting
- **Snapshots** are created so you can rollback if needed

### You'll Be Asked About:
1. **GitHub SSH Setup**: Opening GitHub to add your SSH key
2. **Xcode Installation**: Confirming the large download
3. **Admin Password**: For system modifications
4. **Mac App Store**: Signing in if you want paid apps

### Time Estimates:
- **Quick Start**: 30 seconds
- **Minimal Setup**: 2-3 minutes
- **Full Setup**: 5-10 minutes
- **With Xcode**: 15-30 minutes (large download)

## Step 6: After Setup Completes

### Immediate Next Steps:
1. **Restart Terminal** or run `source ~/.zshrc`
2. **Test Your Setup**: Try `git status`, `brew --version`
3. **Check Applications**: Look in `/Applications` for new apps

### Using Your New Environment:
```bash
# Use convenient aliases
health-check          # Check system health
machine-sync status   # Check sync status
setup-wizard --help   # See available options

# Set up secure encryption (recommended)
setup-encryption      # Store encryption password in keychain

# Access commonly used commands
code .               # Open VS Code (if installed)
sourcetree          # Open Sourcetree (if installed)
```

### Customizing Further:
- **Edit dotfiles**: Modify files in `~/.dotfiles`
- **Add packages**: Edit `.dotfiles.config` and re-run setup
- **Sync to other machines**: Use `machine-sync` commands

## What If Something Goes Wrong?

### Common Issues:

#### "Command not found" after setup:
```bash
# Restart your terminal or reload shell
exec zsh
# Or manually source the configuration
source ~/.zshrc
```

#### Setup gets stuck or fails:
```bash
# Check the logs
tail -f ~/.dotfiles/logs/setup.log

# Try again with verbose output
bootstrap.sh --verbose

# Or use the troubleshooting guide
open ~/.dotfiles/TROUBLESHOOTING.md
```

#### Want to start over:
```bash
# Remove and start fresh
rm -rf ~/.dotfiles
# Then run bootstrap again
```

### Getting Help:
- **Troubleshooting Guide**: `~/.dotfiles/TROUBLESHOOTING.md`
- **Check Health**: Run `health-check` for diagnostics
- **GitHub Issues**: Report problems on the repository

## Multi-Machine Setup

Once you have one machine configured, you can sync to other machines:

```bash
# On your new machine, first do basic setup
bash <(curl -Lks https://raw.githubusercontent.com/JARMourato/dotfiles/main/bootstrap.sh) --quick

# Then sync your configuration
cd ~/.dotfiles
machine-sync init
machine-sync pull    # Get configuration from your other machines
```

## Next Steps

After your basic setup is complete:

1. **[Set Up Encryption](encryption-keychain.md)** - Secure your sensitive files with keychain integration
2. **[Customize Your Configuration](configuration.md)** - Learn how to modify what gets installed
3. **[Multi-Machine Sync](sync-guide.md)** - Keep configurations in sync across devices
4. **[Health Monitoring](health-monitoring.md)** - Set up automated maintenance
5. **[Advanced Usage](advanced-usage.md)** - Plugin development and customization