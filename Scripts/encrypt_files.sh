#!/bin/bash

set -euo pipefail

# Show help documentation
show_help() {
    cat << 'EOF'
📖 encrypt_files.sh - Encrypt sensitive dotfiles for secure storage

DESCRIPTION:
    Encrypts sensitive dotfiles using age (preferred) or OpenSSL encryption.
    Creates encrypted archives that can be safely stored in version control.

USAGE:
    encrypt_files.sh [--keychain-service <service>] [--password <password>]
    encrypt_files.sh --help

OPTIONS:
    --keychain-service   Keychain service name (default: dotfiles-encryption)
    --password          Specify password directly (not recommended)
    --setup-keychain    Store password in keychain for future use
    --help              Show this help

FILES ENCRYPTED:
    ~/.secrets          API keys, tokens, credentials
    ~/.zsh_history      Shell command history
    ~/.z                Directory jump history
    ~/.tellus           Application-specific secrets

OUTPUT:
    Creates .age.encrypted or .encrypted files in the dotfiles repository

ENCRYPTION METHOD:
    • Prefers age encryption (ChaCha20-Poly1305) if available
    • Falls back to OpenSSL AES-256-CBC for compatibility
    • Files are tar+gzip compressed before encryption

EXAMPLES:
    # First time: store password in keychain
    encrypt_files.sh --setup-keychain
    
    # Subsequent uses: read from keychain automatically
    encrypt_files.sh
    
    # Use custom keychain service
    encrypt_files.sh --keychain-service my-custom-service
    
    # Direct password (not recommended)
    encrypt_files.sh --password "my_secure_password"
    
SECURITY NOTES:
    • Use strong, unique passwords
    • Store encryption password securely
    • Regularly rotate secrets (see rotate_secrets.sh)
    • Never commit unencrypted sensitive files

SEE ALSO:
    decrypt_files.sh - Decrypt encrypted files
    rotate_secrets.sh - Rotate secrets with new keys

EOF
}

# Default values
KEYCHAIN_SERVICE="dotfiles-encryption"
KEYCHAIN_ACCOUNT="$USER"
KEY=""
SETUP_KEYCHAIN=false

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
        --setup-keychain)
            SETUP_KEYCHAIN=true
            shift
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

# Function to store password in keychain
store_in_keychain() {
    local password="$1"
    echo "Storing encryption password in keychain service: $KEYCHAIN_SERVICE"
    
    # Delete existing entry if it exists
    security delete-generic-password -s "$KEYCHAIN_SERVICE" -a "$KEYCHAIN_ACCOUNT" 2>/dev/null || true
    
    # Add new entry
    security add-generic-password -s "$KEYCHAIN_SERVICE" -a "$KEYCHAIN_ACCOUNT" -w "$password"
    echo "✅ Password stored in keychain successfully"
}

# Function to retrieve password from keychain
get_from_keychain() {
    security find-generic-password -s "$KEYCHAIN_SERVICE" -a "$KEYCHAIN_ACCOUNT" -w 2>/dev/null
}

# Function to prompt for password securely
prompt_for_password() {
    echo -n "Enter encryption password: "
    read -s password
    echo
    echo "$password"
}

# Setup keychain if requested
if [[ "$SETUP_KEYCHAIN" == true ]]; then
    password=$(prompt_for_password)
    if [[ -n "$password" ]]; then
        store_in_keychain "$password"
        KEY="$password"
    else
        echo "❌ No password provided"
        exit 1
    fi
fi

# Get password if not provided
if [[ -z "$KEY" ]]; then
    echo "🔑 Attempting to retrieve password from keychain..."
    KEY=$(get_from_keychain)
    
    if [[ -z "$KEY" ]]; then
        echo "❌ No password found in keychain service: $KEYCHAIN_SERVICE"
        echo "💡 Run with --setup-keychain to store password first:"
        echo "   encrypt_files.sh --setup-keychain"
        echo ""
        echo "🔧 Or specify password directly (not recommended):"
        echo "   encrypt_files.sh --password 'your-password'"
        exit 1
    else
        echo "✅ Password retrieved from keychain"
    fi
fi

# Check if age is available
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

SYSTEM_PATH="$HOME"
REPO_PATH="$DOTFILES_DIR"

# List of files and directories to encrypt, relative to the $HOME directory.
declare -a FILES_TO_ENCRYPT=(
  ".tellus"
  ".secrets"
  ".z"
  ".zsh_history"
)

# Encrypt files or directories
function encrypt() {
  local source="$1"
  local destination="$2"
  echo "Encrypting '$source' into '$destination'"
  
  # Use age if available (modern), otherwise fallback to openssl (legacy)
  if command_exists age; then
    echo "Using age encryption for $destination"
    # This function throws a "tar: Removing leading '/' from member names" warning, but it can be safely ignored.
    # See https://unix.stackexchange.com/questions/59243/tar-removing-leading-from-member-names#comment81782_59243 for more info.
    tar --create --file - --gzip -- "$source" | age --encrypt --passphrase-file <(echo "$KEY") > "$destination"
  else
    echo "Using OpenSSL encryption for $destination"
    tar --create --file - --gzip -- "$source" | openssl aes-256-cbc -e -out "$destination" -k "$KEY"
  fi
}

# Encrypt all the files declared above
for ORIGINAL_FILENAME in "${FILES_TO_ENCRYPT[@]}"; do
  ORIGINAL_PATH="$SYSTEM_PATH/$ORIGINAL_FILENAME"
  
  # Use .age.encrypted extension for age, .encrypted for openssl
  if command_exists age; then
    DESTINATION_PATH="$REPO_PATH/$ORIGINAL_FILENAME.age.encrypted"
  else
    DESTINATION_PATH="$REPO_PATH/$ORIGINAL_FILENAME.encrypted"
  fi
  
  encrypt "$ORIGINAL_PATH" "$DESTINATION_PATH"
done