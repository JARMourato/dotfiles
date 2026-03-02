#!/bin/bash

# Restore script for homeserver configuration
if [ $# -eq 0 ]; then
    echo "Usage: ./restore.sh <backup-file.tar.gz.enc>"
    exit 1
fi

BACKUP_FILE="$1"

if [ ! -f "$BACKUP_FILE" ]; then
    echo "❌ Backup file not found: $BACKUP_FILE"
    exit 1
fi

echo "Restoring from encrypted backup: $BACKUP_FILE"

# Try to get password from keychain
PASSWORD=$(security find-generic-password -w -s "dotfiles-encryption" -a "$USER" 2>/dev/null)

if [ -z "$PASSWORD" ]; then
    echo "⚠️  No password found in keychain"
    echo "Enter the encryption password manually:"
    # Decrypt and extract with manual password
    openssl enc -aes-256-cbc -d -pbkdf2 -in "$BACKUP_FILE" | tar -xzf -
else
    echo "Using password from keychain..."
    # Decrypt and extract with keychain password
    openssl enc -aes-256-cbc -d -pbkdf2 -pass "pass:$PASSWORD" -in "$BACKUP_FILE" | tar -xzf -
fi

if [ $? -eq 0 ]; then
    echo "✅ Restore completed successfully!"
    echo ""
    echo "Next steps:"
    echo "1. Install Docker"
    echo "2. Run: docker compose up -d"
    echo "3. All your services will start with preserved data"
else
    echo "❌ Restore failed!"
    echo ""
    echo "If using keychain, ensure password is set:"
    echo "security add-generic-password -s 'dotfiles-encryption' -a '$USER' -w 'your-password'"
    exit 1
fi