# Dotfiles Setup Troubleshooting Guide

This guide helps you resolve common issues during dotfiles setup and maintenance.

## Quick Diagnostics

### Check System Status
```bash
# Run quick system checks
./Scripts/check_secrets_age.sh
brew doctor
git status
```

### Get Help
```bash
# All scripts have built-in help
./bootstrap.sh --help
./Scripts/rotate_secrets.sh --help
./Scripts/encrypt_files.sh --help
```

## Common Setup Issues

### 1. Bootstrap Script Failures

#### Network/Connection Issues
**Error**: `curl: (7) Failed to connect to raw.githubusercontent.com`
**Symptoms**: Cannot download Homebrew installer or clone repository
**Causes**: 
- No internet connection
- Corporate firewall blocking GitHub
- DNS resolution issues

**Solutions**:
```bash
# Test connectivity
ping google.com
ping github.com
nslookup raw.githubusercontent.com

# Try different network
# Use mobile hotspot or different WiFi
# Configure corporate proxy if needed

# Manual workaround
curl -I https://github.com  # Should return HTTP 200
```

#### SSH Key Issues
**Error**: `Permission denied (publickey)`
**Symptoms**: Cannot clone repository, SSH auth fails
**Causes**: SSH key not configured or not added to GitHub

**Solutions**:
```bash
# Test SSH connection
ssh -T git@github.com

# If fails, check SSH key exists
ls -la ~/.ssh/

# Regenerate SSH key if needed
ssh-keygen -t rsa -b 4096 -C "your_email@example.com"
cat ~/.ssh/id_rsa.pub | pbcopy  # Copy to clipboard
# Add to https://github.com/settings/ssh/new
```

#### Disk Space Issues
**Error**: `Error: Need at least 10GB free space`
**Symptoms**: Bootstrap fails pre-flight checks
**Solutions**:
```bash
# Check disk usage
df -h
du -sh ~/Downloads ~/Desktop  # Clean large folders
brew cleanup --prune=all      # If brew already installed
```

### 2. Homebrew Installation Problems

#### Xcode Command Line Tools Missing
**Error**: `xcode-select: command line tools not installed`
**Solutions**:
```bash
# Install manually
xcode-select --install
# Wait for installation to complete, then retry
```

#### Permission Issues
**Error**: `Permission denied` during Homebrew installation
**Solutions**:
```bash
# Check ownership of /usr/local (Intel) or /opt/homebrew (Apple Silicon)
ls -la /usr/local/
sudo chown -R $(whoami) /usr/local/*

# For Apple Silicon Macs
sudo chown -R $(whoami) /opt/homebrew/*
```

#### Architecture Mismatch
**Error**: Packages failing on Apple Silicon Macs
**Solutions**:
```bash
# Check architecture
uname -m  # Should show arm64 on Apple Silicon

# Ensure using correct Homebrew
which brew
# Should be /opt/homebrew/bin/brew on Apple Silicon
```

### 3. Encryption/Decryption Issues

#### Wrong Password
**Error**: `bad decrypt` or `wrong password`
**Symptoms**: Cannot decrypt encrypted files
**Solutions**:
```bash
# Verify password manually
openssl aes-256-cbc -d -in .secrets.encrypted -k "your_password" | head
age --decrypt --passphrase-file <(echo "your_password") .secrets.age.encrypted | head

# Check which encryption method was used
ls -la *.encrypted *.age.encrypted

# Try password variations (case sensitivity, special characters)
```

#### Corrupted Encrypted Files
**Error**: `tar: Unrecognized archive format`
**Symptoms**: Decryption succeeds but tar extraction fails
**Solutions**:
```bash
# Check file integrity
file .secrets.encrypted
hexdump -C .secrets.encrypted | head

# Try backup/archived versions
ls -la *.old *.encrypted.*

# Re-encrypt from source if available
./Scripts/encrypt_files.sh "password"
```

#### Missing Age Tool
**Error**: `age: command not found`
**Solutions**:
```bash
# Install age via Homebrew
brew install age

# Or fallback to OpenSSL (automatic in scripts)
# Scripts will auto-detect and use available tools
```

### 4. Application Installation Failures

#### Mac App Store Authentication
**Error**: `mas` commands fail with authentication errors
**Solutions**:
```bash
# Sign in to Mac App Store manually
open /System/Applications/App\ Store.app
# Sign in with Apple ID, then retry

# Check mas authentication
mas account
```

#### Cask Installation Issues
**Error**: Applications fail to install via `brew install --cask`
**Solutions**:
```bash
# Update Homebrew and casks
brew update
brew upgrade --cask

# Check specific cask
brew info --cask <app-name>

# Install manually if needed
brew install --cask <app-name> --force
```

#### Ruby/Python Version Issues
**Error**: `rbenv` or `pyenv` version conflicts
**Solutions**:
```bash
# Check current versions
rbenv version
python3 --version

# Reset to system defaults
rbenv global system
# Then re-run setup

# Check .ruby-version file exists
cat ~/.ruby-version
```

### 5. Symlink Creation Problems

#### File Already Exists
**Error**: `ln: File exists`
**Symptoms**: Cannot create symbolic links
**Solutions**:
```bash
# Check existing files
ls -la ~/.zshrc ~/.aliases ~/.exports

# Remove existing files (backup first!)
cp ~/.zshrc ~/.zshrc.backup
rm ~/.zshrc ~/.aliases ~/.exports

# Re-run symlink setup
./Scripts/set_up_symlinks.sh
```

#### Permission Denied
**Error**: `ln: Permission denied`
**Solutions**:
```bash
# Check home directory permissions
ls -la ~/
# Should be owned by your user

# Fix permissions if needed
sudo chown -R $(whoami) ~/
```

## Environment-Specific Issues

### Corporate Networks
```bash
# Configure proxy if needed
export http_proxy=http://proxy.company.com:8080
export https_proxy=http://proxy.company.com:8080

# Configure git proxy
git config --global http.proxy http://proxy.company.com:8080
```

### Apple Silicon Macs
```bash
# Ensure using ARM64 Homebrew
arch -arm64 brew install <package>

# Check Rosetta 2 if needed for Intel apps
/usr/sbin/softwareupdate --install-rosetta
```

### Multiple Users
```bash
# Each user needs separate setup
sudo su - other_user
# Run bootstrap as that user
```

## Recovery Procedures

### Complete Reset
```bash
# Nuclear option - start fresh
rm -rf ~/.dotfiles
rm ~/.zshrc ~/.aliases ~/.exports ~/.paths ~/.gemrc ~/.ruby-version
# Re-run bootstrap.sh
```

### Restore from Backup
```bash
# If you have Time Machine or manual backups
cp ~/Desktop/backup/.zshrc ~/
# Restore other files as needed
```

### Rollback Secrets
```bash
# Find archived secrets
ls -la *.old *.*encrypted

# Restore specific archived version
cp .secrets.20241206_143022.old .secrets.encrypted
./Scripts/decrypt_files.sh "old_password"
```

## Getting Help

### Log Collection
```bash
# Collect system information for support
system_profiler SPSoftwareDataType > ~/Desktop/system_info.txt
brew config > ~/Desktop/brew_config.txt
ls -la ~/.dotfiles/ > ~/Desktop/dotfiles_status.txt
```

### Debug Mode
```bash
# Run scripts with debug output
bash -x ./bootstrap.sh "password"
set -x  # Enable debug mode in current shell
```

### Contact Information
- Create issue: [GitHub Issues](https://github.com/jarmourato/dotfiles/issues)
- Include: error messages, system info, steps to reproduce
- Attach: relevant log files (sanitized of sensitive data)

## Prevention

### Regular Maintenance
```bash
# Weekly checks
./Scripts/check_secrets_age.sh
brew doctor
git status

# Monthly updates
brew update && brew upgrade
mas upgrade
gem update
```

### Backup Strategy
```bash
# Before major changes
cp -r ~/.dotfiles ~/Desktop/dotfiles_backup_$(date +%Y%m%d)
./Scripts/encrypt_files.sh "current_password"
git add . && git commit -m "Backup before changes"
```

### Testing New Changes
```bash
# Test in VM or separate user account first
sudo dscl . -create /Users/testuser
# Test setup as testuser before applying to main account
```