#!/bin/bash

################################################################################
### Set up everything in the correct order
################################################################################

source .exports
source Scripts/set_up_symlinks.sh
source Scripts/set_up_dependencies.sh
 # Must be run again after installing dependencies to apply changes
source .exports
source .zshrc
source Scripts/decrypt_files.sh $1
source Scripts/set_up_user_defaults.sh
source Terminal/set_up_terminal.sh
source Scripts/set_up_machine_specific_settings.sh
source Scripts/clean_up.sh
