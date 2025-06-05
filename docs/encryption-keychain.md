# Keychain-Enabled Encryption Guide

This guide covers the keychain-enabled encryption system that eliminates the need to type passwords every time you encrypt or decrypt sensitive dotfiles.

## Overview

The dotfiles system can securely store your encryption password in macOS Keychain, allowing automatic encryption and decryption without manual password entry. This provides both convenience and security by leveraging macOS's built-in credential management.

## Quick Start

### First Time Setup

1. **Store your encryption password in Keychain**:
   ```bash
   setup-encryption
   ```
   
   This will:
   - Prompt for your encryption password (input is hidden)
   - Store it securely in macOS Keychain
   - Encrypt your sensitive files using that password

2. **Verify the setup worked**:
   ```bash
   encrypt
   ```
   
   You should see: `✅ Password retrieved from keychain`

### Daily Usage

Once set up, encryption and decryption are seamless:

```bash
# Encrypt sensitive files (no password prompt)
encrypt

# Decrypt files (no password prompt)
decrypt
```

## Detailed Setup

### Initial Password Setup

When you run `setup-encryption` for the first time:

```bash
$ setup-encryption
Enter encryption password: [hidden input]
Storing encryption password in keychain service: dotfiles-encryption
✅ Password stored in keychain successfully
🔑 Encrypting files...
Encrypting '/Users/you/.tellus' into '/Users/you/.dotfiles/.tellus.age.encrypted'
Using age encryption for .tellus.age.encrypted
...
✅ All files encrypted successfully
```

### What Gets Stored

The system stores your password in macOS Keychain with these details:
- **Service**: `dotfiles-encryption` (customizable)
- **Account**: Your username
- **Password**: Your encryption passphrase
- **Access**: Only your user account can access it

### Verifying Keychain Storage

You can verify the password is stored correctly:

```bash
# View in Keychain Access app
open "/Applications/Utilities/Keychain Access.app"
# Search for "dotfiles-encryption"

# Or check via command line
security find-generic-password -s "dotfiles-encryption" -a "$USER" -w
```

## Usage Examples

### Basic Operations

```bash
# First time: set up keychain
setup-encryption

# Encrypt files (reads password from keychain)
encrypt

# Decrypt files (reads password from keychain)
decrypt

# Check what files would be encrypted
encrypt --help
```

### Advanced Options

#### Custom Keychain Service

Use different keychain services for different projects:

```bash
# Set up company-specific encryption
encrypt --setup-keychain --keychain-service company-secrets

# Use company keychain for encryption
encrypt --keychain-service company-secrets
decrypt --keychain-service company-secrets
```

#### Custom Output Directory

```bash
# Decrypt to specific directory
decrypt --output ~/temp

# Decrypt company files to project directory
decrypt --keychain-service company-secrets --output ~/Workspace/Git/Company
```

#### Fallback to Manual Password

```bash
# If keychain is unavailable, use direct password
encrypt --password "your-secure-password"
decrypt --password "your-secure-password"
```

## What Gets Encrypted

The system encrypts these sensitive files from your home directory:

| File | Description |
|------|-------------|
| `~/.tellus` | Tellus application secrets |
| `~/.secrets` | API keys, tokens, credentials |
| `~/.zsh_history` | Shell command history |
| `~/.z` | Directory jump history |

Encrypted files are stored in your dotfiles repository as:
- `.tellus.age.encrypted` (if using age encryption)
- `.tellus.encrypted` (if using OpenSSL encryption)

## Security Considerations

### Keychain Security

✅ **Secure**:
- Passwords stored in encrypted macOS Keychain
- Only your user account can access the password
- Keychain protected by your login password/Touch ID
- No passwords stored in plain text files

✅ **Access Control**:
- Each user has their own keychain entry
- Cannot access other users' encryption passwords
- Keychain entry tied to your user account

### Best Practices

1. **Use strong passwords**: Choose a strong, unique encryption password
2. **Regular rotation**: Rotate encryption passwords periodically
3. **Multiple services**: Use different keychain services for different projects
4. **Backup**: Ensure your keychain is backed up (part of Time Machine)

### Team Environments

For teams, each person should use their own encryption password:

```bash
# Each team member sets up their own keychain
setup-encryption
# Each person enters their own unique password
```

The encrypted files can be shared in the repository, but each person uses their own decryption password.

## Troubleshooting

### Common Issues

#### "No password found in keychain"

```bash
❌ No password found in keychain service: dotfiles-encryption
💡 Run encrypt_files.sh --setup-keychain to store password first
```

**Solution**: Run the setup command to store your password:
```bash
setup-encryption
```

#### "Failed to decrypt" errors

**Possible causes**:
- Wrong password stored in keychain
- Corrupted encrypted files
- Different encryption method used

**Solutions**:
```bash
# Update keychain with correct password
setup-encryption

# Try manual password to test
decrypt --password "known-good-password"

# Check which encryption method was used
ls -la *.encrypted *.age.encrypted
```

#### Keychain Access Denied

**Solution**: Check Keychain Access permissions:
1. Open Keychain Access app
2. Find "dotfiles-encryption" entry
3. Double-click and check "Access Control" tab
4. Ensure Terminal/your shell has access

### Manual Keychain Management

#### Update Password

```bash
# Remove old password
security delete-generic-password -s "dotfiles-encryption" -a "$USER"

# Add new password
setup-encryption
```

#### Multiple Services

```bash
# List all dotfiles encryption services
security dump-keychain | grep "dotfiles-"

# Remove specific service
security delete-generic-password -s "company-secrets" -a "$USER"
```

#### Backup Keychain Entry

```bash
# Export keychain item (will prompt for password)
security export -k ~/Library/Keychains/login.keychain-db -o ~/Desktop/dotfiles-keychain.p12 -P "export-password"
```

## Migration Guide

### From Manual Passwords

If you've been using manual passwords:

```bash
# Set up keychain with your existing password
setup-encryption
# Enter the same password you've been using manually

# Verify it works
encrypt
decrypt
```

### From Different Encryption Tools

If you have files encrypted with different tools:

```bash
# Decrypt with old method first
decrypt --password "old-password"

# Set up new keychain-based encryption
setup-encryption
# Enter new password

# Re-encrypt with new password
encrypt
```

### Team Migration

For teams migrating to keychain:

1. **Coordinate**: Decide if everyone uses the same password or individual passwords
2. **Individual setup**: Each person runs `setup-encryption`
3. **Test**: Verify everyone can encrypt/decrypt successfully
4. **Document**: Share the new workflow with the team

## Command Reference

### Encryption Commands

```bash
# Setup and management
setup-encryption                              # Store password in keychain
encrypt                                       # Encrypt files using keychain
decrypt                                       # Decrypt files using keychain

# Advanced options
encrypt --keychain-service <name>             # Use custom keychain service
decrypt --keychain-service <name>             # Use custom keychain service
decrypt --output <directory>                  # Decrypt to specific directory

# Fallback options
encrypt --password <password>                 # Direct password (not recommended)
decrypt --password <password>                 # Direct password (not recommended)

# Legacy compatibility
encrypt-files <password>                      # Old manual method still works
decrypt-files <password>                      # Old manual method still works
```

### Keychain Management

```bash
# View stored password (will prompt for keychain access)
security find-generic-password -s "dotfiles-encryption" -a "$USER" -w

# Delete stored password
security delete-generic-password -s "dotfiles-encryption" -a "$USER"

# List all keychain items (filter for dotfiles)
security dump-keychain | grep "dotfiles"
```

## Integration with Other Features

### Multi-Machine Sync

When syncing dotfiles across machines:

```bash
# On first machine: encrypt and sync
encrypt
machine-sync push

# On second machine: sync and decrypt  
machine-sync pull
setup-encryption  # Set up keychain on new machine
decrypt           # Decrypt synced files
```

### Automated Workflows

Include in automated scripts:

```bash
#!/bin/bash
# Backup script

# Encrypt sensitive files
if encrypt; then
    echo "✅ Files encrypted successfully"
    
    # Sync to backup location
    machine-sync push
else
    echo "❌ Encryption failed"
    exit 1
fi
```

### Health Monitoring

The health monitoring system can check encryption status:

```bash
# Check if keychain is set up
health-check encryption

# Check if files are properly encrypted
health-check --component=security
```

## Next Steps

- **[Getting Started](getting-started.md)** - Basic dotfiles setup
- **[Configuration Guide](configuration.md)** - Customize your environment  
- **[Multi-Machine Sync](sync-guide.md)** - Sync across machines
- **[Security Best Practices](security.md)** - Advanced security configuration