#!/bin/bash

################################################################################
### Set up everything in the correct order
################################################################################

source .exports
source set_up_symlinks.sh
source set_up_dependencies.sh
source .zshrc # Must be run again after installing dependencies to apply changes
source set_up_user_defaults.sh
source Terminal/set_up_terminal.sh
source set_up_machine_specific_settings.sh
source clean_up.sh