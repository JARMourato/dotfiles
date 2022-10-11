#!/bin/bash

# exit when any command fails
set -e

cd ~/.dotfiles

hub sync

Scripts/git_commit.sh "Sync dotfiles"