#!/bin/bash

# exit when any command fails
set -e

if [ -z "$1" ]
  then
    echo "⛔️ No remote provided. Usage example: ./git_repo_setup.sh JARMourato/Repository"
    exit 1
fi

git init
git add .
git commit -m "first commit"
git branch -M main
git remote add origin git@github.com:"$1".git
git push -u origin main