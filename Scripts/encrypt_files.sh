#!/bin/bash

################################################################################
### Encrypt sensitive dotfiles for secure repository storage
################################################################################

KEY="$1"

if [[ -z $KEY ]]; then
  echo "❌ The encryption key is empty."
  exit 1
fi

SYSTEM_PATH="$HOME"
REPO_PATH="$DOTFILES_DIR"

echo "🔐 Encrypting sensitive files..."
echo ""

# List of files and directories to encrypt, relative to the $HOME directory.
declare -a FILES_TO_ENCRYPT=(
  ".tellus"
  ".secrets"
  ".z"
  ".zsh_history"
)

# Encrypt files or directories
function encrypt() {
  SOURCE=$1
  DESTINATION=$2
  
  if [[ ! -e "$SOURCE" ]]; then
    echo "⚠️  Skipping '$SOURCE' (not found)"
    return 0
  fi
  
  echo "🔒 Encrypting: $(basename "$SOURCE")"
  # Use modern PBKDF2 key derivation to avoid deprecation warnings
  # Suppress tar warning about removing leading '/' - this is expected behavior
  tar --create --file - --gzip -- "$SOURCE" 2>/dev/null | \
    openssl aes-256-cbc -e -out "$DESTINATION" -k "$KEY" -pbkdf2 -iter 100000
  
  if [[ $? -eq 0 ]]; then
    echo "✅ $(basename "$SOURCE") encrypted successfully"
  else
    echo "❌ Failed to encrypt $(basename "$SOURCE")"
    return 1
  fi
}

# Encrypt all the files declared above
for ORIGINAL_FILENAME in "${FILES_TO_ENCRYPT[@]}"; do
  ORIGINAL_PATH="$SYSTEM_PATH/$ORIGINAL_FILENAME"
  DESTINATION_PATH="$REPO_PATH/$ORIGINAL_FILENAME.encrypted"
  encrypt "$ORIGINAL_PATH" "$DESTINATION_PATH"
done

echo ""
echo "========================================"
echo "🎉 Encryption Complete!"
echo "========================================"