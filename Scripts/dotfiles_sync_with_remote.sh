#!/bin/bash

# exit when any command fails
set -e

cd ~/.dotfiles

hub sync

# For now this will suffice
./_set_up.sh