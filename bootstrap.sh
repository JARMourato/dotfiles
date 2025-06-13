#!/bin/bash

################################################################################
### Parse command line arguments and manage keychain password
################################################################################

PROFILE=""
SETUP_KEYCHAIN=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --profile=*)
            PROFILE="${1#*=}"
            shift
            ;;
        --profile)
            PROFILE="$2"
            shift 2
            ;;
        --setup-keychain)
            SETUP_KEYCHAIN=true
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [--profile=PROFILE] [--setup-keychain]"
            echo ""
            echo "Available profiles: dev, personal, server"
            echo "If no profile specified, default configuration will be used"
            echo ""
            echo "Options:"
            echo "  --profile=PROFILE     Use specific machine profile"
            echo "  --setup-keychain      Set up encryption password in keychain"
            echo ""
            echo "Examples:"
            echo "  $0 --profile=personal"
            echo "  $0 --profile=dev --setup-keychain"
            echo "  $0 --setup-keychain  # Set up keychain first time"
            exit 0
            ;;
        *)
            echo "Unknown argument: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

################################################################################
### Keychain functions
################################################################################

KEYCHAIN_SERVICE="dotfiles-encryption"
KEYCHAIN_ACCOUNT="default"

# Function to retrieve password from keychain
get_keychain_password() {
    security find-generic-password -s "$KEYCHAIN_SERVICE" -a "$KEYCHAIN_ACCOUNT" -w 2>/dev/null
}

# Function to setup keychain password
setup_keychain_password() {
    echo "🔑 Setting up encryption password in keychain..."
    echo ""
    echo "This password will be used to encrypt/decrypt sensitive files in your dotfiles."
    echo "It will be securely stored in your macOS keychain for future use."
    echo "Choose a strong password you'll remember (you'll only need to enter it once per device)."
    echo ""
    echo -n "Enter encryption password: "
    read -s password
    echo
    
    if [[ -n "$password" ]]; then
        # Delete existing entry if it exists
        security delete-generic-password -s "$KEYCHAIN_SERVICE" -a "$KEYCHAIN_ACCOUNT" 2>/dev/null || true
        
        # Add new entry
        security add-generic-password -s "$KEYCHAIN_SERVICE" -a "$KEYCHAIN_ACCOUNT" -w "$password"
        echo "✅ Password stored in keychain successfully"
        echo "$password"
    else
        echo "❌ No password provided"
        exit 1
    fi
}

################################################################################
### Get or setup encryption password
################################################################################

ENCRYPTION_PASSWORD=""

if [[ "$SETUP_KEYCHAIN" == true ]]; then
    ENCRYPTION_PASSWORD=$(setup_keychain_password)
else
    echo "🔑 Retrieving encryption password from keychain..."
    ENCRYPTION_PASSWORD=$(get_keychain_password)
    
    if [[ -z "$ENCRYPTION_PASSWORD" ]]; then
        echo "❌ No encryption password found in keychain"
        echo ""
        echo "🔐 First-time setup: You need to set an encryption password"
        echo "   This password will encrypt sensitive files and be stored securely in keychain."
        echo ""
        ENCRYPTION_PASSWORD=$(setup_keychain_password)
    else
        echo "✅ Encryption password retrieved from keychain"
    fi
fi

################################################################################
### Configure SSH key
################################################################################

echo "🔍 Checking SSH key setup..."
count=`ls -1 ~/.ssh/*.pub 2>/dev/null | wc -l`
if [ $count != 0 ]; then
   echo "✅ SSH key found - GitHub SSH setup detected"
else 
   echo "🔧 No SSH key found - setting up new GitHub SSH key"
   
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

echo "🔍 Checking Xcode Command Line Tools..."

# Check if xcode-select exists and has a valid path
if command -v xcode-select >/dev/null 2>&1; then
    xpath=$(xcode-select --print-path 2>/dev/null)
    if [ -n "$xpath" ] && [ -d "$xpath" ] && [ -x "$xpath/usr/bin/git" ]; then
        echo "✅ Xcode Command Line Tools already installed and functional"
    else
        # Tools exist but may not be properly set up
        echo "⚠️  Xcode Command Line Tools detected but not properly configured"
        echo "🔧 Attempting to install/update Xcode Command Line Tools..."
        xcode-select --install 2>/dev/null || echo "⚠️  Installation may already be in progress or tools are current"
        echo "📋 If a dialog appeared, please complete the installation"
        read -p "Press enter to continue..."
    fi
else
    echo "🔧 Installing Xcode Command Line Tools..."
    xcode-select --install
    echo "📋 Installation requested - please complete in the dialog"
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

# Ensure we're in a safe directory before removing ~/.dotfiles
cd "$HOME"

rm -rf ~/.dotfiles
git clone git@github.com:jarmourato/dotfiles.git ~/.dotfiles
cd ~/.dotfiles

# Set up profile if specified
if [ -n "$PROFILE" ]; then
    echo "🎯 Setting up profile: $PROFILE"
    
    if [ -f "./profile-setup.sh" ]; then
        ./profile-setup.sh "$PROFILE" || echo "⚠️  Profile setup failed, continuing with defaults..."
    else
        echo "⚠️  Profile setup script not found, continuing with defaults..."
    fi
fi

./_set_up.sh "$ENCRYPTION_PASSWORD"
echo "Done"
