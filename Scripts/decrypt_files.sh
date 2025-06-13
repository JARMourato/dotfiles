#!/bin/bash

################################################################################
### Decrypt sensitive dotfiles from encrypted repository storage
################################################################################

KEY="$1"

if [[ -z $KEY ]]; then
  echo "❌ The decryption key is empty."
  exit 1
fi

function decrypt() {
  SOURCE=$1
  local filename=$(basename "$SOURCE" .encrypted)
  
  if [[ ! -f "$SOURCE" ]]; then
    echo "⚠️  Encrypted file not found: $SOURCE"
    return 1
  fi
  
  echo "🔓 Decrypting: $filename"
  # Try modern PBKDF2 first, fallback to legacy method for backward compatibility
  # Extract to the same folder where it was encrypted from
  if openssl aes-256-cbc -d -in "$SOURCE" -k "$KEY" -pbkdf2 -iter 100000 2>/dev/null | tar --extract --gzip --file - -C / 2>/dev/null; then
    echo "✅ $filename decrypted successfully (PBKDF2)"
  elif openssl aes-256-cbc -d -in "$SOURCE" -k "$KEY" 2>/dev/null | tar --extract --gzip --file - -C / 2>/dev/null; then
    echo "✅ $filename decrypted successfully (legacy)"
  else
    echo "❌ Failed to decrypt $filename"
    return 1
  fi
}

SYSTEM_PATH="$HOME"
REPO_PATH="$DOTFILES_DIR"

# Check if any encrypted files exist
ENCRYPTED_FILES=($(find . -name '*.encrypted' 2>/dev/null))

if [[ ${#ENCRYPTED_FILES[@]} -eq 0 ]]; then
  echo "📝 No encrypted files found - skipping decryption"
  exit 0
fi

echo "🔐 Decrypting sensitive files..."
echo ""

# Decrypt all files with .encrypted extension in this folder.
for ENCRYPTED_FILE in "${ENCRYPTED_FILES[@]}"; do
  decrypt "$REPO_PATH/$ENCRYPTED_FILE"
done

echo ""
echo "========================================"
echo "🎉 Decryption Complete!"
echo "========================================"