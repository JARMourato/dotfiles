#!/bin/bash

# exit when any command fails
set -e

if [ -z "$1" ]
  then
    echo "⛔️ No commit message provided. Usage example: ./git_commit.sh \"my commit message\""
    exit 1
fi

git add .
git commit -m "$1"
git push