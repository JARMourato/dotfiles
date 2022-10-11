#!/bin/zsh

cd ~/.dotfiles

hub sync

# For now this will suffice

source .exports
source Scripts/set_up_symlinks.sh
source Scripts/set_up_dependencies.sh
source .zshrc # Must be run again after installing dependencies to apply changes
source Scripts/decrypt_files.sh $1
source Scripts/set_up_user_defaults.sh