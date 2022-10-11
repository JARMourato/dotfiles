#!/bin/bash

################################################################################
### Set up symbolic links
################################################################################

rm -rf $HOME/.aliases
rm -rf $HOME/.exports
rm -rf $HOME/.gemrc
rm -rf $HOME/.paths
rm -rf $HOME/.ruby-version
rm -rf $HOME/.zshrc

# DOTFILES_DIR may have not been initialized yet, if this is the first time setting up .zshrc
source .exports

ln -s $DOTFILES_DIR/.aliases $HOME/.aliases
ln -s $DOTFILES_DIR/.exports $HOME/.exports
ln -s $DOTFILES_DIR/.gemrc $HOME/.gemrc
ln -s $DOTFILES_DIR/.paths $HOME/.paths
ln -s $DOTFILES_DIR/.ruby-version $HOME/.ruby-version
ln -s $DOTFILES_DIR/.zshrc $HOME/.zshrc