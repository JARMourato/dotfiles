#!/bin/bash

# Ask for the administrator password upfront
sudo -v

# Keep-alive: update existing `sudo` time stamp until this script has finished
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

# Remove default apps
echo "Removing default apps. 🚧"

sudo rm -rf /Applications/GarageBand.app
sudo rm -rf /Applications/iMovie.app
sudo rm -rf /Applications/Keynote.app
sudo rm -rf /Applications/Numbers.app
sudo rm -rf /Applications/Pages.app

echo "All done here! 🎉"
read -p "The system needs to be rebooted to complete the configuration. Press enter to reboot..."
sudo shutdown -r now