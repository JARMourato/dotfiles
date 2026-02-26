#!/bin/bash
# @jarmourato/macsetup — one-liner bootstrap
# Usage: bash <(curl -Lks https://raw.githubusercontent.com/JARMourato/dotfiles/main/bootstrap.sh)
#
# This shim ensures Homebrew + Node exist, then hands off to the interactive CLI.

set -e

echo "🚀 @jarmourato/macsetup"
echo ""

# 1. Xcode Command Line Tools
if ! xcode-select -p &>/dev/null; then
  echo "⚙️  Installing Xcode Command Line Tools..."
  xcode-select --install
  echo "   Please complete the installation dialog, then press Enter to continue."
  read -r
fi

# 2. Homebrew
if ! command -v brew &>/dev/null; then
  echo "🍺 Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  # Add to PATH for this session (Apple Silicon vs Intel)
  if [ -f "/opt/homebrew/bin/brew" ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [ -f "/usr/local/bin/brew" ]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
else
  echo "✅ Homebrew found"
fi

# 3. Node.js
if ! command -v node &>/dev/null; then
  echo "📦 Installing Node.js..."
  brew install node
else
  echo "✅ Node.js found ($(node -v))"
fi

# 4. Clone and run
REPO_URL="https://github.com/JARMourato/dotfiles.git"
INSTALL_DIR="$HOME/.macsetup"

if [ -d "$INSTALL_DIR" ]; then
  echo "🔄 Updating macsetup..."
  cd "$INSTALL_DIR"
  git pull --ff-only
else
  echo "📥 Cloning macsetup..."
  git clone "$REPO_URL" "$INSTALL_DIR"
  cd "$INSTALL_DIR"
fi

# 5. Install deps & build
echo "🔨 Building..."
npm install --no-fund --no-audit --silent 2>&1 | tail -1
npm run build --silent 2>&1 | tail -1

# 6. Run interactive CLI (pass through any args)
echo ""
node dist/index.js "$@"
