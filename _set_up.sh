#!/bin/bash

################################################################################
### Set up everything in the correct order
################################################################################

source .exports
source Scripts/set_up_symlinks.sh
source Scripts/set_up_dependencies.sh
source .zshrc # Must be run again after installing dependencies to apply changes
source Scripts/set_up_user_defaults.sh
source Terminal/set_up_terminal.sh
source Scripts/set_up_machine_specific_settings.sh
source Scripts/clean_up.sh