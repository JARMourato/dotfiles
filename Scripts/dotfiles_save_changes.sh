#!/bin/bash

# exit when any command fails
set -e

cd ~/.dotfiles

hub sync

Scripts/encrypt_files.sh $1

Scripts/git_commit.sh "Sync dotfiles"