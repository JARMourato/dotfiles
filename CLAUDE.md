# CLAUDE.md - Dotfiles Development Context

## Project Overview
This repository contains a comprehensive macOS dotfiles setup system that can be deployed via a single command:
```bash
bash <(curl -Lks https://raw.githubusercontent.com/JARMourato/dotfiles/main/bootstrap.sh) --profile=dev
```

## Current Development Focus
- **Objective**: Improve the dev profile setup for fresh macOS installations
- **Testing**: Secondary machine for testing (not this machine)
- **Current Phase**: Preventing profile-setup.sh execution during development

## Architecture

### Core Files
- `bootstrap.sh` - Main entry point with keychain password management
- `profile-setup.sh` - YAML-based profile configuration parser
- `_set_up.sh` - Main setup orchestrator (called by bootstrap)

### Key Features Already Implemented
1. **Keychain Password Management**:
   - Service: `dotfiles-encryption`
   - Account: `default`
   - Automatic retrieval/setup via macOS keychain
   - Fallback to interactive setup if not found

2. **Profile System**:
   - Available profiles: dev, personal, server
   - YAML-based configuration (`.dotfiles.{profile}.yaml`)
   - Generates shell config (`.dotfiles.config`)

3. **SSH Setup**:
   - Automatic GitHub SSH key generation and setup
   - Clipboard integration for key sharing

## Development Tasks

### Phase 1: Development Mode Preparation
- [ ] Prevent profile-setup.sh execution during development
- [ ] Document keychain password setup process
- [ ] Ensure clean bootstrap.sh execution flow

### Phase 2: Keychain Integration
- [ ] Test keychain password retrieval
- [ ] Verify encryption/decryption workflow
- [ ] Handle edge cases (missing passwords, etc.)

## Keychain Password Setup

The bootstrap.sh script includes comprehensive keychain password management:

### Usage Options:
1. **First-time setup**: `--setup-keychain` flag
2. **Automatic retrieval**: Script attempts to get password from keychain
3. **Fallback**: Interactive password setup if not found

### Storage Details:
- **Service**: `dotfiles-encryption`
- **Account**: `default`
- **Access**: Via macOS Security framework commands

### Commands:
```bash
# Set up keychain password
./bootstrap.sh --setup-keychain

# Use existing keychain password
./bootstrap.sh --profile=dev

# Manual keychain operations
security add-generic-password -s "dotfiles-encryption" -a "default" -w "your-password"
security find-generic-password -s "dotfiles-encryption" -a "default" -w
```

## Notes
- The encryption password is used for sensitive file encryption/decryption
- Password is stored securely in macOS keychain
- Script handles both interactive setup and automated retrieval