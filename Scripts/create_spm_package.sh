#!/bin/bash

# exit when any command fails
set -e

if [ -z "$1" ]
  then
    echo "⛔️ No package name supplied"
    exit 1
fi

TEMPLATE=~/.dotfiles/Templates/SPMPACKAGE
PACKAGENAME=$1
DESTINATION=~/Workspace/Git/$PACKAGENAME
GITREMOTE=JARMourato/$PACKAGENAME

echo "🚀 Creating new package..."

cp -r $TEMPLATE/. $DESTINATION

#TODO: Implement a more code efficient approach

cd $DESTINATION

# Change file names
mv Sources/PACKAGE.swift Sources/$PACKAGENAME.swift
mv Tests/PACKAGETests.swift Tests/${PACKAGENAME}Tests.swift

# Replace occurences of PACKAGE by actual name
sed -i '' "s/PACKAGE/$PACKAGENAME/g" .github/workflows/CI.yml
sed -i '' "s/PACKAGE/$PACKAGENAME/g" Tests/${PACKAGENAME}Tests.swift
sed -i '' "s/PACKAGE/$PACKAGENAME/g" README.md
sed -i '' "s/PACKAGE/$PACKAGENAME/g" Package.swift

echo "1️⃣ Local files set up"

gh repo create $GITREMOTE --private

echo "2️⃣ Remote git repo set up"

~/.dotfiles/Scripts/git_repo_setup.sh $GITREMOTE

echo "3️⃣ Local git set up"

open .