#!/bin/bash

set -euo pipefail

# Show help documentation
show_help() {
    cat << 'EOF'
📖 decrypt_files.sh - Decrypt encrypted dotfiles to home directory

DESCRIPTION:
    Decrypts encrypted dotfiles and extracts them to their original locations.
    Supports both age and OpenSSL encrypted files for backward compatibility.

USAGE:
    decrypt_files.sh [--keychain-service <service>] [--password <password>] [--output <dir>]
    decrypt_files.sh --help

OPTIONS:
    --keychain-service   Keychain service name (default: dotfiles-encryption)
    --password          Specify password directly (not recommended)
    --output            Output directory (default: /)
    --help              Show this help

FILES DECRYPTED:
    Searches for *.encrypted and *.age.encrypted files in the current directory
    and decrypts them to their original locations in the home directory.

DECRYPTION METHOD:
    • Auto-detects age vs OpenSSL encrypted files
    • Prefers age decryption for .age.encrypted files
    • Falls back to OpenSSL for .encrypted files
    • Extracts tar+gzip archives to original paths

EXAMPLES:
    # Use password from keychain (recommended)
    decrypt_files.sh
    
    # Decrypt to specific directory
    decrypt_files.sh --output ~/temp
    
    # Use custom keychain service
    decrypt_files.sh --keychain-service my-custom-service
    
    # Direct password (not recommended)
    decrypt_files.sh --password "my_secure_password"
    
SECURITY NOTES:
    • Files are extracted with original permissions
    • Failed decryption may indicate wrong password or corrupted files
    • Check file integrity after decryption

SEE ALSO:
    encrypt_files.sh - Encrypt sensitive files
    check_secrets_age.sh - Check rotation status

EOF
}

# Default values
KEYCHAIN_SERVICE="dotfiles-encryption"
KEYCHAIN_ACCOUNT="$USER"
KEY=""
OUTPUT_DIR="/"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --help|-h)
            show_help
            exit 0
            ;;
        --keychain-service)
            KEYCHAIN_SERVICE="$2"
            shift 2
            ;;
        --password)
            KEY="$2"
            shift 2
            ;;
        --output)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        *)
            # Legacy support: if it's a single argument without flags, treat as password
            if [[ -z "$KEY" && $# -eq 1 ]]; then
                KEY="$1"
                shift
            else
                echo "Unknown option: $1"
                echo "Use --help for usage information"
                exit 1
            fi
            ;;
    esac
done

# Function to retrieve password from keychain
get_from_keychain() {
    security find-generic-password -s "$KEYCHAIN_SERVICE" -a "$KEYCHAIN_ACCOUNT" -w 2>/dev/null
}

# Get password if not provided
if [[ -z "$KEY" ]]; then
    echo "🔑 Attempting to retrieve password from keychain..."
    KEY=$(get_from_keychain)
    
    if [[ -z "$KEY" ]]; then
        echo "❌ No password found in keychain service: $KEYCHAIN_SERVICE"
        echo "💡 Run encrypt_files.sh --setup-keychain to store password first"
        echo ""
        echo "🔧 Or specify password directly (not recommended):"
        echo "   decrypt_files.sh --password 'your-password'"
        exit 1
    else
        echo "✅ Password retrieved from keychain"
    fi
fi

# Check if age is available, fallback to openssl for backward compatibility
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

function decrypt() {
  local source="$1"
  echo "Decrypting from '$source'"
  
  # Try age first (modern encryption), fallback to openssl (legacy)
  if command_exists age && [[ "$source" == *.age.encrypted ]]; then
    echo "Using age decryption for $source"
    if ! age --decrypt --passphrase-file <(echo "$KEY") "$source" | tar -v --extract --gzip --file - -C "$OUTPUT_DIR"; then
      echo "Error: Failed to decrypt $source with age"
      return 1
    fi
  else
    echo "Using OpenSSL decryption for $source"
    # Extract to the same folder where it was encrypted from
    if ! openssl aes-256-cbc -d -in "$source" -k "$KEY" | tar -v --extract --gzip --file - -C "$OUTPUT_DIR"; then
      echo "Error: Failed to decrypt $source with OpenSSL"
      return 1
    fi
  fi
}

SYSTEM_PATH="$HOME"
REPO_PATH="${DOTFILES_DIR:-$(pwd)}"

# Decrypt all files with .encrypted extension in this folder.
echo "Looking for encrypted files to decrypt..."
encrypted_files=$(find . -name '*.encrypted' 2>/dev/null || true)
if [ -z "$encrypted_files" ]; then
  echo "No encrypted files found"
else
  for ENCRYPTED_FILE in $encrypted_files; do
    decrypt "$REPO_PATH/$ENCRYPTED_FILE"
  done
  echo "Decryption complete"
fi