#!/bin/bash

################################################################################
### Set up everything in the correct order
################################################################################

source .exports
source Scripts/set_up_symlinks.sh

# Sync state (compare with previous run and optionally remove orphaned packages)
Scripts/sync_state.sh sync

source Scripts/set_up_dependencies.sh
# Must be run again after installing dependencies to apply changes
source .exports
source .zshrc
source Scripts/decrypt_files.sh $1

echo ""
source Scripts/set_up_user_defaults.sh

echo ""
source Scripts/set_up_complex_defaults.sh

echo ""
source Terminal/set_up_terminal.sh

echo ""
source Scripts/set_up_machine_specific_settings.sh

echo ""
source Scripts/clean_up.sh
