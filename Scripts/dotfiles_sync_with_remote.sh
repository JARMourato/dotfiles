#!/bin/zsh

cd ~/.dotfiles

# Check if we only need a light YAML sync
if [[ "$1" != "--force" ]]; then
    echo "Checking for YAML configuration changes..."
    if ~/dotfiles/bin/yaml_sync.sh check; then
        echo "Configuration is up to date. Use --force for full sync."
        exit 0
    else
        echo "YAML configuration has changed. Proceeding with full sync..."
        # First pull the YAML changes
        ~/dotfiles/bin/yaml_sync.sh pull
    fi
fi

# Full sync process
hub sync

# For now this will suffice

source .exports
source Scripts/set_up_symlinks.sh
source Scripts/set_up_dependencies.sh
source .zshrc # Must be run again after installing dependencies to apply changes
source Scripts/decrypt_files.sh $1
source Scripts/set_up_user_defaults.sh