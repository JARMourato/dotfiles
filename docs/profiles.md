# Machine Profiles Guide

This dotfiles system includes three pre-configured profiles tailored for different machine types and use cases.

## Overview

Instead of manually configuring each machine, you can use one of three profiles:

- **dev** - Development machine with full development tools
- **personal** - Personal machine with productivity and entertainment apps  
- **server** - Headless server machine with container and server tools

Each profile extends a base configuration with profile-specific packages and settings.

## Quick Setup

### Using Profile During Bootstrap

```bash
# Development machine
bash <(curl -Lks https://raw.githubusercontent.com/JARMourato/dotfiles/main/bootstrap.sh) --profile=dev

# Personal machine
bash <(curl -Lks https://raw.githubusercontent.com/JARMourato/dotfiles/main/bootstrap.sh) --profile=personal

# Server machine
bash <(curl -Lks https://raw.githubusercontent.com/JARMourato/dotfiles/main/bootstrap.sh) --profile=server
```

### Setting Profile for Existing Installation

```bash
# Set up profile interactively
./profile-setup.sh

# Set specific profile
./profile-setup.sh dev
./profile-setup.sh personal
./profile-setup.sh server

# Check current profile
./profile-setup.sh --current
```

## Profile Details

### Development Profile (`dev`)

**Target**: Primary development machine for Swift/iOS development

**Key Features**:
- Full Xcode and iOS development tools
- Development IDEs and editors
- Container and cloud tools
- Advanced terminal setup

**Main Packages**:
```bash
# Development tools
swiftlint swiftformat carthage cocoapods fastlane xcbeautify

# IDEs and editors
xcode simulator sf-symbols visual-studio-code sublime-text

# Version control
sourcetree github-desktop

# Design and debugging
figma proxyman charles

# Container and cloud
docker docker-compose kubernetes-cli terraform ansible aws-cli

# Productivity
raycast alfred rectangle cleanmymac postman insomnia
```

**Configuration Highlights**:
- Git editor: VS Code
- Terminal: Powerline with syntax highlighting
- Python 3.11 & 3.12, Node.js LTS
- Xcode templates and tools
- QuickLook plugins for development files

### Personal Profile (`personal`)

**Target**: Personal machine for daily use, entertainment, and light development

**Key Features**:
- Productivity and entertainment apps
- Creative tools and games
- Social and communication apps
- Basic development setup

**Main Packages**:
```bash
# Browsers and communication
google-chrome firefox spotify telegram whatsapp discord zoom

# Productivity
notion obsidian 1password bitwarden dropbox google-drive

# Entertainment and media
iina vlc handbrake steam epic-games-launcher netflix

# Creative tools
adobe-creative-cloud final-cut-pro logic-pro

# Utilities
cleanmymac bartender alfred raycast rectangle
```

**Configuration Highlights**:
- Git editor: nano (simpler)
- Basic terminal setup
- Python 3.11, Node.js LTS
- Mac App Store apps enabled
- Fun commands and aliases

### Server Profile (`server`)

**Target**: Mac Mini or headless server for containers and services

**Key Features**:
- Docker and container orchestration
- Server monitoring and management
- Network tools and utilities
- Minimal GUI (headless operation)

**Main Packages**:
```bash
# Container tools
docker docker-compose docker-buildx kubernetes-cli helm

# Infrastructure and automation
terraform ansible portainer-cli

# Monitoring and system tools
htop iftop nethogs ncdu tmux screen

# Network utilities
rsync scp ssh-copy-id mosh nmap
```

**Configuration Highlights**:
- No GUI applications
- Minimal terminal setup
- Python 3.11 only (for server scripts)
- SSH hardening enabled
- Automated backups and monitoring
- No Xcode or development IDEs

## Base Configuration

All profiles inherit from a base configuration that includes:

### Common Settings
```bash
# Git configuration
GIT_NAME="João Armourato"
GIT_EMAIL="joao.armourato@gmail.com"

# Essential tools (all machines)
git gh jq curl wget tree bat fd ripgrep htop neovim

# Security
SSH_KEY_TYPE="ed25519"
ENCRYPTION_METHOD="age"

# System
AUTO_SETUP_GIT_SSH=true
CREATE_SNAPSHOT=true
DAILY_HEALTH_CHECK=true
```

## Customizing Profiles

### Override Settings

You can override any profile setting by creating a machine-specific config:

```bash
# Create machine-specific overrides
cat > ~/.dotfiles/.dotfiles.$(hostname).config << 'EOF'
# Machine-specific overrides
ADDITIONAL_CASKS="my-special-app"
SKIP_PYTHON_INSTALL=true
EOF
```

### Adding Custom Packages

Add packages to any profile by editing the profile config:

```bash
# Edit development profile
vim ~/.dotfiles/.dotfiles.dev.config

# Add your custom packages
ADDITIONAL_FORMULAS="my-tool another-tool"
ADDITIONAL_CASKS="my-app"
```

### Profile-Specific Aliases

Each profile can have custom aliases:

```bash
# Development aliases (loaded when MACHINE_PROFILE="dev")
alias xcode="open -a Xcode"
alias simulator="open -a Simulator"
alias build="xcodebuild"

# Personal aliases (loaded when MACHINE_PROFILE="personal")
alias music="open -a Spotify"
alias notes="open -a Notion"

# Server aliases (loaded when MACHINE_PROFILE="server")
alias containers="docker ps"
alias logs="docker logs"
alias monitor="htop"
```

## Multi-Machine Sync with Profiles

### Syncing Between Different Profiles

The sync system respects machine profiles:

```bash
# On development machine
machine-sync profile dev
machine-sync push

# On personal machine  
machine-sync profile personal
machine-sync pull  # Gets base config + personal overrides
```

### Profile-Specific Sync

You can sync profile-specific configurations:

```bash
# Sync only development configs
machine-sync push --profile=dev

# Pull personal configs only
machine-sync pull --profile=personal
```

## Switching Profiles

### Changing Machine Profile

To switch an existing machine to a different profile:

```bash
# Switch to development profile
./profile-setup.sh dev

# Re-run setup to apply new configuration
setup-deps
setup-symlinks

# Verify new profile
health-check
```

### Profile Migration

When switching profiles, the system will:

1. Backup current configuration
2. Apply new profile settings
3. Install/remove packages as needed
4. Update symlinks and settings
5. Run health checks

## Troubleshooting Profiles

### Check Current Profile

```bash
# See current profile and configuration
./profile-setup.sh --current

# Check what packages would be installed
setup-deps --dry-run

# Verify profile-specific settings
grep MACHINE_PROFILE ~/.dotfiles/.dotfiles.config
```

### Reset Profile

If profile configuration gets corrupted:

```bash
# Reset to specific profile
./profile-setup.sh dev --force

# Or start fresh
rm ~/.dotfiles/.dotfiles.config
./profile-setup.sh
```

### Profile Conflicts

If you have package conflicts between profiles:

```bash
# Check for conflicts
deps-scan --conflicts

# Resolve by updating profile config
vim ~/.dotfiles/.dotfiles.dev.config

# Re-apply profile
./profile-setup.sh dev
```

## Examples

### Setting Up Development Machine

```bash
# 1. Clone and set up with dev profile
bash <(curl -Lks https://raw.githubusercontent.com/JARMourato/dotfiles/main/bootstrap.sh) --profile=dev

# 2. Verify installation
health-check

# 3. Set up sync for other machines
machine-sync init
machine-sync profile dev
```

### Setting Up Mac Mini Server

```bash
# 1. SSH into Mac Mini
ssh user@mac-mini.local

# 2. Set up with server profile
bash <(curl -Lks https://raw.githubusercontent.com/JARMourato/dotfiles/main/bootstrap.sh) --profile=server

# 3. Verify server tools
docker --version
kubectl version --client
```

### Switching Personal to Development

```bash
# 1. Current machine is personal, switch to dev
./profile-setup.sh dev

# 2. Install additional development packages
setup-deps

# 3. Update terminal and configs
setup-symlinks
setup-terminal

# 4. Verify development tools
which swiftlint
code --version
```

## Next Steps

- **[Getting Started](getting-started.md)** - Basic setup walkthrough
- **[Configuration Guide](configuration.md)** - Detailed customization options
- **[Multi-Machine Sync](sync-guide.md)** - Sync configs across machines
- **[Command Reference](commands.md)** - All available commands