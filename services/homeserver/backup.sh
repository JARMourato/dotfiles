#!/bin/bash

# Backup script for homeserver configuration
echo "Creating encrypted backup of homeserver configuration..."

# Get password from keychain (same as dotfiles)
PASSWORD=$(security find-generic-password -w -s "dotfiles-encryption" -a "$USER" 2>/dev/null)

if [ -z "$PASSWORD" ]; then
    echo "❌ Could not retrieve password from keychain"
    echo "Please set it with: security add-generic-password -s 'dotfiles-encryption' -a '$USER' -w 'your-password'"
    exit 1
fi

# Create backup filename with timestamp
BACKUP_FILE="homeserver-backup-$(date +%Y%m%d-%H%M%S).tar.gz.enc"

# Create encrypted backup using password from keychain
tar -czf - config/ .env docker-compose.yml | openssl enc -aes-256-cbc -salt -pbkdf2 -pass "pass:$PASSWORD" -out "$BACKUP_FILE"

if [ $? -eq 0 ]; then
    echo "✅ Backup created successfully: $BACKUP_FILE"
    echo "📏 Size: $(du -h "$BACKUP_FILE" | cut -f1)"
    
    # Git operations
    echo ""
    echo "📤 Uploading to GitHub..."
    
    # Add the encrypted backup
    git add "$BACKUP_FILE"
    
    # Commit with timestamp
    git commit -m "Backup: $(date +%Y-%m-%d' '%H:%M:%S)"
    
    # Push to GitHub
    git push
    
    if [ $? -eq 0 ]; then
        echo "✅ Backup uploaded to GitHub successfully!"
    else
        echo "⚠️  Backup created but failed to push to GitHub"
        echo "Run 'git push' manually when connection is available"
    fi
    
    echo ""
    echo "To restore on another machine:"
    echo "1. Set keychain password: security add-generic-password -s 'dotfiles-encryption' -a '\$USER' -w 'password'"
    echo "2. Run: ./restore.sh $BACKUP_FILE"
else
    echo "❌ Backup failed!"
    exit 1
fi