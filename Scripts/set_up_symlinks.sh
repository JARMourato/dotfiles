#!/bin/bash

################################################################################
### 🔗 Set up symbolic links
################################################################################

echo "========================================"
echo "🔗 Setting up symbolic links..."
echo "========================================"
echo ""

echo "🗑️  Removing existing dotfiles..."
rm -rf $HOME/.aliases
rm -rf $HOME/.exports
rm -rf $HOME/.gemrc
rm -rf $HOME/.paths
rm -rf $HOME/.ruby-version
rm -rf $HOME/.zshrc

# DOTFILES_DIR may have not been initialized yet, if this is the first time setting up .zshrc
source .exports

echo "🔗 Creating symlinks..."
ln -s $DOTFILES_DIR/.aliases $HOME/.aliases
echo "   └─ ✅ .aliases"
ln -s $DOTFILES_DIR/.exports $HOME/.exports
echo "   └─ ✅ .exports"
ln -s $DOTFILES_DIR/.gemrc $HOME/.gemrc
echo "   └─ ✅ .gemrc"
ln -s $DOTFILES_DIR/.paths $HOME/.paths
echo "   └─ ✅ .paths"
ln -s $DOTFILES_DIR/.ruby-version $HOME/.ruby-version
echo "   └─ ✅ .ruby-version"
ln -s $DOTFILES_DIR/.zshrc $HOME/.zshrc
echo "   └─ ✅ .zshrc"

echo ""
echo "========================================"
echo "🎉 Symbolic Links Setup Complete!"
echo "========================================"