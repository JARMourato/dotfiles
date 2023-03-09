#!/bin/bash

################################################################################
### Install Dependencies
################################################################################

echo "🚀 Starting setup"

# Install Homebrew if not already installed
if test ! $(which brew); then
	echo "🍺 Installing homebrew..."
	/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# In case paths have not been set up yet
source ~/.zshrc

echo "🍺 Updating homebrew..."
brew update

# Check Xcode
xcode=`ls /Applications | grep 'Xcode-'`

if [[ ! -z "$xcode" ]]; then
	echo "Xcode is already installed 🎉"
else
	# Install Xcode 
	brew install aria2
	brew install robotsandpencils/made/xcodes
	xcodes install --latest --experimental-unxip
fi

# Install utilities and apps
PACKAGES=(
	aria2
	detekt
	gh
	hub
	ktlint
	make
	mas
	pyenv
	python
	rbenv
	ruby
	ruby-build
	swiftformat
	swiftlint
	robotsandpencils/made/xcodes
)
echo "🍺 Installing utility packages..."
brew install ${PACKAGES[@]}

CASKS=(
	android-studio
	betterzip
	bitwarden
	google-chrome
	iina
	notion
	raycast
	setapp
	sf-symbols
	slack
	sourcetree
	spotify
	sublime-text
	telegram
	visual-studio-code
	xcodes
	whatsapp
	zoom
)
echo "🍺 Installing apps..."
brew install --cask ${CASKS[@]}

QUICKLOOKPLUGINS=(
	apparency
	qlcolorcode
	qlimagesize
	qlmarkdown
	qlprettypatch
    qlstephen
    quicklook-csv
    quicklook-json
    suspicious-package
    webpquicklook
)
echo "🍺 Installing quicklook plugins..."
brew install --cask ${QUICKLOOKPLUGINS[@]}

echo "📦 Installing bundler..."
gem install bundler

echo "🧼 Cleaning up..."
brew cleanup -s

echo "💎 Installing Ruby"
# Will pick up version from ~/.ruby-version
RUBY_VERSION="$(cat ~/.ruby-version)"
rbenv install
rbenv global $RUBY_VERSION
echo "💎 Ruby $RUBY_VERSION installed successfully!"

echo "🍏 Installing Appstore Apps"
mas install 904280696 # Things 3
mas install 1477385213 # Save to Pocket

echo "🎉 Dependencies Setup complete!"
