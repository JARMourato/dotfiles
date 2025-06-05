#!/bin/bash

set -euo pipefail

################################################################################
### Secrets Rotation Management
################################################################################

# Check if age is available
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Get current timestamp for archiving
get_timestamp() {
    date +%Y%m%d_%H%M%S
}

# Archive old encrypted file
archive_old_secret() {
    local secret_file="$1"
    local timestamp="$2"
    
    if [ -f "$secret_file" ]; then
        local archive_name="${secret_file%.encrypted}.${timestamp}.old"
        echo "📦 Archiving old version: $archive_name"
        mv "$secret_file" "$archive_name"
    fi
}

# Rotate a single secret file
rotate_secret() {
    local secret_name="$1"
    local source_path="$2"
    local new_key="$3"
    local timestamp="$4"
    
    echo "🔄 Rotating secret: $secret_name"
    
    if [ ! -f "$source_path" ]; then
        echo "⚠️  Source file $source_path not found, skipping..."
        return 0
    fi
    
    local repo_path="${DOTFILES_DIR:-$(pwd)}"
    
    # Determine file extension based on available tools
    if command_exists age; then
        local encrypted_file="$repo_path/$secret_name.age.encrypted"
        echo "📝 Using age encryption for $secret_name"
    else
        local encrypted_file="$repo_path/$secret_name.encrypted" 
        echo "📝 Using OpenSSL encryption for $secret_name"
    fi
    
    # Archive existing encrypted file
    archive_old_secret "$encrypted_file" "$timestamp"
    
    # Create new encrypted file
    echo "🔐 Creating new encrypted file: $encrypted_file"
    if command_exists age; then
        tar --create --file - --gzip -- "$source_path" | age --encrypt --passphrase-file <(echo "$new_key") > "$encrypted_file"
    else
        tar --create --file - --gzip -- "$source_path" | openssl aes-256-cbc -e -out "$encrypted_file" -k "$new_key"
    fi
    
    echo "✅ Successfully rotated $secret_name"
}

# Show help documentation
show_help() {
    cat << 'EOF'
📖 rotate_secrets.sh - Rotate encrypted secrets with new encryption keys

DESCRIPTION:
    Rotates all encrypted dotfiles secrets with a new encryption key.
    Archives old encrypted files with timestamps for rollback capability.

USAGE:
    rotate_secrets.sh <new_encryption_key> [--force]
    rotate_secrets.sh --help

ARGUMENTS:
    new_encryption_key    New passphrase/key for encrypting secrets

OPTIONS:
    --force              Skip confirmation prompts (useful for automation)
    --help, -h           Show this help message

FILES ROTATED:
    ~/.secrets           API keys, tokens, credentials
    ~/.zsh_history       Shell command history
    ~/.z                 Directory jump history
    ~/.tellus            Application-specific secrets

PROCESS:
    1. Archives existing encrypted files with timestamp
    2. Re-encrypts source files with new key
    3. Uses age encryption if available, falls back to OpenSSL
    4. Provides rotation summary and recommendations

EXAMPLES:
    rotate_secrets.sh "my_new_secure_password_2024"
    rotate_secrets.sh "new_key" --force
    
SECURITY NOTES:
    • Use strong, unique passwords for encryption
    • Store new password securely before rotation
    • Test decryption before deleting old archives
    • Update any automation using these secrets

EOF
}

# Main rotation function
main() {
    # Check for help flag first
    if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
        show_help
        exit 0
    fi
    
    echo "🔐 Starting secrets rotation process..."
    
    if [ $# -lt 1 ]; then
        echo "❌ Error: Missing required encryption key argument"
        echo ""
        echo "Usage: $0 <new_encryption_key> [--force]"
        echo "Use --help for detailed documentation"
        exit 1
    fi
    
    local new_key="$1"
    local force_mode=false
    
    if [ "${2:-}" = "--force" ]; then
        force_mode=true
    fi
    
    if [ -z "$new_key" ]; then
        echo "Error: Encryption key cannot be empty"
        exit 1
    fi
    
    local timestamp=$(get_timestamp)
    echo "📅 Rotation timestamp: $timestamp"
    
    # Confirm rotation unless in force mode
    if [ "$force_mode" = false ]; then
        echo ""
        echo "⚠️  This will rotate all encrypted secrets with a new encryption key."
        echo "   Old encrypted files will be archived with timestamp: $timestamp"
        echo ""
        read -p "Do you want to continue? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "❌ Rotation cancelled"
            exit 0
        fi
    fi
    
    echo ""
    echo "🚀 Starting rotation process..."
    
    # Define secrets to rotate (same as encrypt_files.sh)
    declare -a SECRETS_TO_ROTATE=(
        ".tellus"
        ".secrets" 
        ".z"
        ".zsh_history"
    )
    
    local success_count=0
    local total_count=${#SECRETS_TO_ROTATE[@]}
    
    # Rotate each secret
    for secret_name in "${SECRETS_TO_ROTATE[@]}"; do
        local source_path="$HOME/$secret_name"
        if rotate_secret "$secret_name" "$source_path" "$new_key" "$timestamp"; then
            ((success_count++))
        fi
        echo ""
    done
    
    echo "📊 Rotation Summary:"
    echo "   Total secrets: $total_count"
    echo "   Successfully rotated: $success_count"
    echo "   Timestamp: $timestamp"
    
    if [ $success_count -eq $total_count ]; then
        echo "✅ All secrets rotated successfully!"
    else
        echo "⚠️  Some secrets failed to rotate. Check the output above."
        exit 1
    fi
    
    echo ""
    echo "🔔 Important reminders:"
    echo "   1. Update your decryption processes to use the new key"
    echo "   2. Test decryption with the new key before deleting archives"
    echo "   3. Securely store/backup the new encryption key"
    echo "   4. Consider updating any automation that uses these secrets"
}

# Execute main function with all arguments
main "$@"