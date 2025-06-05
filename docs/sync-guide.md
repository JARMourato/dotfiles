# Multi-Machine Sync Guide

Keep your development environment synchronized across multiple machines with intelligent conflict resolution.

## Overview

The sync system allows you to:

- Share configurations between work and personal machines
- Keep different machine profiles (work/personal/development)
- Automatically resolve conflicts when configurations differ
- Encrypt sensitive files during sync
- Maintain separate package lists for different machine types

## Quick Start

### Set Up Sync on Your First Machine

```bash
# Initialize sync system
machine-sync init

# Set machine profile
machine-sync profile work    # or 'personal', 'development'

# Push your configuration to sync storage
machine-sync push
```

### Set Up Additional Machines

```bash
# Do basic dotfiles setup first
bash <(curl -Lks https://raw.githubusercontent.com/JARMourato/dotfiles/main/bootstrap.sh) --quick

# Initialize sync and pull configuration
cd ~/.dotfiles
machine-sync init
machine-sync pull
```

## Machine Profiles

Profiles allow different configurations for different types of machines:

### Available Profiles

- **work**: Corporate-friendly, excludes personal apps
- **personal**: Full configuration including entertainment
- **development**: Development-focused, minimal GUI apps
- **minimal**: Essential tools only

### Setting Your Profile

```bash
# Set profile for current machine
machine-sync profile work

# See current profile
machine-sync status

# List available profiles
machine-sync profile --list
```

### Profile-Specific Packages

Configure different packages for each profile in `.dotfiles.config`:

```bash
# Base packages (installed on all profiles)
HOMEBREW_FORMULAS="git jq curl wget"

# Work-specific packages
WORK_PACKAGES="slack teams zoom microsoft-office"

# Personal-specific packages  
PERSONAL_PACKAGES="spotify telegram discord games"

# Development-specific packages
DEV_PACKAGES="docker kubernetes-cli terraform"
```

## Sync Operations

### Basic Sync Commands

```bash
# Check sync status
machine-sync status

# Pull latest configuration from other machines
machine-sync pull

# Push your local changes to sync storage
machine-sync push

# See what changes would be synced
machine-sync diff
```

### Automatic Sync

Enable automatic synchronization:

```bash
# Set up automatic sync (runs every hour)
machine-sync auto --enable

# Disable automatic sync
machine-sync auto --disable

# Check auto-sync status
machine-sync auto --status
```

## Conflict Resolution

When configurations differ between machines, the sync system provides multiple resolution strategies:

### Automatic Resolution

Most conflicts are resolved automatically:

- **Package additions**: Merged from all machines
- **New files**: Added to all machines
- **Compatible changes**: Automatically merged

### Manual Resolution

For conflicts that need your input:

```bash
# Check for conflicts
machine-sync status

# Resolve conflicts interactively
machine-sync resolve

# Use specific resolution strategy
machine-sync resolve --strategy=mine     # Keep local version
machine-sync resolve --strategy=theirs   # Use remote version
machine-sync resolve --strategy=merge    # Interactive merge
```

### Conflict Types and Solutions

#### Package Conflicts
When different machines have different package lists:

```bash
# View package differences
machine-sync diff --packages

# Merge packages from all machines
machine-sync resolve --merge-packages

# Keep only local packages
machine-sync resolve --packages=local
```

#### Configuration File Conflicts
When dotfiles differ between machines:

```bash
# View configuration differences
machine-sync diff --configs

# Launch merge tool (VS Code, vim, etc.)
machine-sync resolve --interactive

# Use file from specific machine
machine-sync resolve --use-from=work-macbook
```

## Encryption and Security

### Sensitive Files

Some files are automatically encrypted during sync:

- SSH keys and certificates
- API tokens and passwords
- Personal configuration files

### Managing Encrypted Files

```bash
# List encrypted files
machine-sync encrypt --list

# Encrypt a specific file
machine-sync encrypt ~/.dotfiles/sensitive.conf

# Decrypt files on new machine
machine-sync decrypt --all

# Rotate encryption keys
rotate-secrets
```

### Setting Up Encryption

```bash
# Initialize encryption with your GPG key
machine-sync encrypt --init --gpg-key=your@email.com

# Or use a shared password
machine-sync encrypt --init --password
```

## Sync Storage Options

### GitHub (Default)

Uses a private GitHub repository for sync storage:

```bash
# Set up GitHub sync (done automatically)
machine-sync init --storage=github

# Configure custom repository
machine-sync init --repo=username/dotfiles-sync
```

### Cloud Storage

Use cloud storage services:

```bash
# iCloud Drive
machine-sync init --storage=icloud

# Dropbox
machine-sync init --storage=dropbox

# Google Drive
machine-sync init --storage=gdrive
```

### Network Storage

Use network storage for team environments:

```bash
# Network share
machine-sync init --storage=smb://server/share

# SSH/SCP
machine-sync init --storage=ssh://user@server/path
```

## Advanced Sync Features

### Selective Sync

Only sync specific parts of your configuration:

```bash
# Sync only packages
machine-sync push --packages-only

# Sync only dotfiles
machine-sync push --configs-only

# Exclude specific files
machine-sync push --exclude="*.log,*.tmp"
```

### Machine-Specific Overrides

Keep some settings local to each machine:

Create `.dotfiles.local` for machine-specific configuration:

```bash
# ~/.dotfiles/.dotfiles.local (not synced)
LOCAL_PACKAGES="machine-specific-tool"
LOCAL_CONFIG="DISPLAY_RESOLUTION=4k"

# This file is ignored by sync
```

### Sync Hooks

Run custom scripts during sync operations:

```bash
# ~/.dotfiles/hooks/pre-sync.sh
#!/bin/bash
echo "Preparing for sync..."
# Custom preparation logic

# ~/.dotfiles/hooks/post-sync.sh  
#!/bin/bash
echo "Sync completed, running post-sync tasks..."
# Custom cleanup or setup logic
```

## Troubleshooting Sync Issues

### Common Problems

#### Sync Fails to Connect
```bash
# Check network connectivity
machine-sync diagnose --network

# Verify credentials
machine-sync diagnose --auth

# Reset sync configuration
machine-sync reset --keep-local
```

#### Files Not Syncing
```bash
# Check what's being ignored
machine-sync status --verbose

# Force sync specific file
machine-sync push --force file.conf

# Check file permissions
machine-sync diagnose --permissions
```

#### Merge Conflicts
```bash
# See detailed conflict information
machine-sync status --conflicts

# Reset to last known good state
machine-sync reset --to-last-sync

# Manual conflict resolution
machine-sync resolve --manual
```

### Sync Logs

Check sync logs for detailed information:

```bash
# View recent sync activity
machine-sync logs

# View specific operation
machine-sync logs --operation=pull

# Enable verbose logging
machine-sync config set verbose=true
```

## Multi-User Environments

### Team Configuration Sharing

Share base configurations across a team:

```bash
# Set up team base configuration
machine-sync team --init --base-repo=company/team-dotfiles

# Apply team base + personal overrides
machine-sync team --apply --personal-overrides
```

### Organization Policies

Enforce organization-wide settings:

```bash
# Apply organization policies
machine-sync policy --apply --org=company

# Check policy compliance
machine-sync policy --check

# Override specific policies (if allowed)
machine-sync policy --override security.ssh_timeout
```

## Best Practices

### Sync Strategy

1. **Start with one machine**: Set up your primary machine completely
2. **Test sync early**: Set up sync and test with a secondary machine
3. **Use profiles**: Configure appropriate profiles for different machine types
4. **Regular syncing**: Enable auto-sync or sync manually at least daily
5. **Conflict preparation**: Understand how to resolve conflicts before they happen

### Security

1. **Encrypt sensitive data**: Always encrypt files containing secrets
2. **Regular key rotation**: Rotate encryption keys periodically
3. **Verify sync storage**: Ensure your sync storage is secure and private
4. **Audit sync logs**: Regularly check what's being synced

### Organization

1. **Document machine purposes**: Keep track of what each machine is used for
2. **Profile consistency**: Use the same profile type for similar machines
3. **Local overrides**: Use `.dotfiles.local` for machine-specific needs
4. **Backup strategy**: Ensure sync storage itself is backed up

## Example Workflows

### Setting Up a New Work Machine

```bash
# 1. Basic setup
bash <(curl -Lks https://raw.githubusercontent.com/JARMourato/dotfiles/main/bootstrap.sh) --quick

# 2. Initialize sync and set profile
cd ~/.dotfiles
machine-sync init
machine-sync profile work

# 3. Pull work configuration
machine-sync pull

# 4. Apply configuration
setup-deps
setup-symlinks

# 5. Verify setup
health-check
```

### Updating Configuration Across All Machines

```bash
# 1. Make changes on primary machine
vim ~/.dotfiles/.dotfiles.config

# 2. Test changes locally
setup-deps --dry-run

# 3. Push to sync
machine-sync push

# 4. On other machines, pull and apply
machine-sync pull
setup-deps
```

## Next Steps

- **[Configuration Guide](configuration.md)** - Customize what gets installed
- **[Health Monitoring](health-monitoring.md)** - Keep systems healthy across machines
- **[Advanced Usage](advanced-usage.md)** - Custom sync scripts and automation