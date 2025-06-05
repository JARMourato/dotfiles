#!/bin/bash

################################################################################
### Preemptively check for encryption password
################################################################################

if [ $# -eq 0 ]; then
   echo "Encryption password missing"
   exit 1
fi

################################################################################
### Configure SSH key
################################################################################

count=`ls -1 ~/.ssh/*.pub 2>/dev/null | wc -l`
if [ $count != 0 ]; then
   echo "Assuming Github SSH has been setup previously!"
else 
   echo "No ssh key has been found! Setting up new Github SSH key."
   
   function toClipboard {
      if command -v pbcopy > /dev/null; then
         pbcopy
      elif command -v xclip > /dev/null; then
         xclip -i -selection c
      else
         echo "No clipboard tool found. Here's what you need to paste into the developer console:"
         cat -
      fi
   }
   
   # Generate new SSH key
   echo -n "Please enter the email you'd like to register with your GitHub SSH key: "
   read email
   echo "Next, press enter. Then create a memorable passphrase"
   ssh-keygen -t rsa -b 4096 -C $email
   
   # Add your SSH key to the ssh-agent
   # Start the ssh-agent in the background
   eval "$(ssh-agent -s)"
   # Automatically load keys into the ssh-agent and store passphrases in the keychain
   # Host *
   #   AddKeysToAgent yes
   #   UseKeychain yes
   #   IdentityFile ~/.ssh/id_rsa
   printf "Host *\n  AddKeysToAgent yes\n  UseKeychain yes\n  IdentityFile ~/.ssh/id_rsa\n" >> ~/.ssh/config
   
   # Add your SSH private key to the ssh-agent and store your passphrase in the keychain
   ssh-add -K ~/.ssh/id_rsa
   
   # Copy the contents of the id_rsa.pub file to clipboard
   cat ~/.ssh/id_rsa.pub | toClipboard
   echo "Copied SSH key to clipboard!"
   echo "Opening Safari, create a descriptive title to describe this computer and paste the key there"
   open -a safari https://github.com/settings/ssh/new
   
   read -p "Press enter to continue after completing ssh setup in github..."
fi 

##################################################################################
##### Command line developer tools
##################################################################################

if type xcode-select >&- && xpath=$( xcode-select --print-path ) && test -d "${xpath}" && test -x "${xpath}" ; then
   echo "Xcode Command Line Tools already installed"
else
   echo "Need to install xcode tools"
   xcode-select --install
   echo "Requested install"
   read -p "Press enter to continue after completing the installation..."
fi


#################################################################################
#### Configure Directories
#################################################################################

rm -rf ~/Workspace
mkdir ~/Workspace
mkdir ~/Workspace/Git

#################################################################################
#### Start Configuration Process
#################################################################################

set -e # Immediately rethrows exceptions

rm -rf ~/.dotfiles
git clone git@github.com:jarmourato/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./_set_up.sh $1
echo "Done"
