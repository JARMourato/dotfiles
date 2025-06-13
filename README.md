# Bootstrap macOS

A comprehensive dotfiles repository with automated macOS setup scripts, profile-based configuration, and state management.

Before doing anything, make sure you know what you're doing! Settings applied by this repository are very personal and definitely don't suit everyone's needs. I suggest you create your own set of dotfiles based on this repo.

## Features

- 🚀 **One-line installation** with profile support
- 🔐 **Secure keychain integration** for encryption passwords
- 📦 **Declarative package management** with state tracking
- 🎨 **Beautiful terminal setup** with oh-my-zsh, powerline, and custom theme
- ⚙️ **Comprehensive macOS defaults** configuration
- 🤖 **AI tools integration** (Claude, ChatGPT)
- 🔄 **Profile system** for different machine types (dev, personal, server)

## Requirements

- macOS (tested on latest versions)
- Internet connection
- Terminal needs full disk access (System Settings > Privacy & Security > Full Disk Access)
- Make sure the system is updated before proceeding

## Installation

### Quick Start (Development Profile)

```bash
bash <(curl -Lks https://raw.githubusercontent.com/JARMourato/dotfiles/main/bootstrap.sh) --profile=dev
```

### Other Options

```bash
# Install with default profile (personal)
bash <(curl -Lks https://raw.githubusercontent.com/JARMourato/dotfiles/main/bootstrap.sh)

# Set up keychain password for first time
bash <(curl -Lks https://raw.githubusercontent.com/JARMourato/dotfiles/main/bootstrap.sh) --setup-keychain
```

## What Gets Installed

### Development Profile (`--profile=dev`)

#### Command Line Tools
- Core: git, gh (GitHub CLI), curl, wget, jq, tree, bat, fd, ripgrep
- iOS/Swift: swiftlint, swiftformat, carthage, cocoapods, fastlane
- Cloud/DevOps: docker, terraform, ansible, awscli
- Languages: Ruby (via rbenv), Python 3, Node.js

#### Applications
- Development: VS Code, Sublime Text, SourceTree, SF Symbols, Proxyman
- Browsers: Google Chrome
- Communication: Slack, Zoom, WhatsApp, Telegram
- Productivity: Bitwarden, Spotify, Things 3
- AI Tools: Claude, ChatGPT, Claude Code CLI

#### Terminal Environment
- oh-my-zsh with plugins (git, bundler, pyenv, z)
- Powerline shell with custom configuration
- Custom "Highway" terminal theme
- Meslo LG powerline fonts

#### macOS Configuration
- Finder: Show all files, path bar, status bar
- Dock: Auto-hide, magnification, custom size
- Keyboard: Fast key repeat, disable auto-correct
- Screenshots: Save to ~/Pictures/Screenshots
- Hot corners: Desktop, Mission Control, Application Windows
- And many more productivity tweaks...

## Project Structure

```
.
├── bootstrap.sh           # Main entry point
├── _set_up.sh            # Setup orchestrator
├── profile-setup.sh      # Profile parser
├── Scripts/
│   ├── set_up_dependencies.sh      # Package installations
│   ├── set_up_symlinks.sh          # Dotfile symlinks
│   ├── set_up_user_defaults.sh     # macOS preferences
│   ├── sync_state.sh               # State management
│   └── ...
├── Terminal/
│   ├── set_up_terminal.sh          # Terminal setup
│   └── Highway.terminal            # Custom theme
└── .dotfiles.dev.yaml              # Dev profile configuration
```

## Profile System

Profiles are defined in YAML files (e.g., `.dotfiles.dev.yaml`) and control:
- Which packages to install (Homebrew formulas and casks)
- Mac App Store applications
- System preferences and defaults
- Terminal customization options

## State Management

The dotfiles use a declarative approach to package management:
- Tracks what's installed vs. what should be installed
- Can remove packages not in your current profile
- Prevents duplicate installations
- Maintains state between runs

## Customization

1. Fork this repository
2. Edit `.dotfiles.dev.yaml` or create your own profile
3. Modify scripts in `Scripts/` to suit your needs
4. Update `.aliases`, `.exports`, and other dotfiles
5. Commit and push your changes
6. Run the installation with your forked repository URL

## Post-Installation

1. Restart your Mac to ensure all changes take effect
2. Open Terminal to see the new theme and configuration
3. Some applications may require manual sign-in or additional setup

## Updates

To update your dotfiles after making changes:
```bash
cd ~/.dotfiles
git pull
./_set_up.sh
```

## Special Thanks

- Felix Krause's dotfiles - https://github.com/KrauseFx/dotfiles - via [@KrauseFx](https://twitter.com/krausefx)
- Felix's Terminal setup - https://github.com/KrauseFx/what-terminal-is-felix-using - via [@KrauseFx](https://twitter.com/krausefx)
- Change macOS User Preferences via Command Line - https://pawelgrzybek.com/change-macos-user-preferences-via-command-line/ - via [@pawelgrzybek](https://twitter.com/pawelgrzybek)
- Mathias's dotfiles - https://github.com/mathiasbynens/dotfiles - via [@mathias](https://twitter.com/mathias)
- Roger's dotfiles - https://github.com/rogerluan/dotfiles - via [@rogerluan_](https://twitter.com/rogerluan_)
- Moving to zsh - https://scriptingosx.com/2019/06/moving-to-zsh-part-2-configuration-files/ - via [@scriptingosx](https://twitter.com/scriptingosx)

## License

Feel free to use any part of this setup for your own dotfiles!