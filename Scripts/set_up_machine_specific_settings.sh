#!/bin/bash

# Ask for the administrator password upfront
sudo -v

# Keep-alive: update existing `sudo` time stamp until `.macos` has finished
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

################################################################################
### Configure git 
################################################################################

git config --global user.name "JARMourato"
git config --global user.email "joao.armourato@gmail.com"

################################################################################
### Configure computer name
################################################################################

echo -n "Please enter the wanted machine name: "
read name

# Set computer name (as done via System Preferences → Sharing)
sudo scutil --set ComputerName $name
sudo scutil --set HostName $name
sudo scutil --set LocalHostName $name
sudo defaults write /Library/Preferences/SystemConfiguration/com.apple.smb.server NetBIOSName -string $name