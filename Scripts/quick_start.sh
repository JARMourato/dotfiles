#!/bin/bash
set -euo pipefail

################################################################################
### Ultra-Fast Quick Start Mode
################################################################################
# 30-second setup for immediate productivity with essential tools only
# Progressive enhancement available after core setup

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"
QUICK_START_LOG="$HOME/.dotfiles_quick_start.log"

# Load progress indicators
source "$SCRIPT_DIR/progress_indicators.sh" 2>/dev/null || true

################################################################################
### Environment Detection
################################################################################

detect_user_environment() {
    local environments=()
    
    echo "🔍 Detecting your development environment..."
    
    # Project type detection
    if find . -maxdepth 2 -name "Package.swift" -o -name "*.xcodeproj" -o -name "*.xcworkspace" 2>/dev/null | grep -q .; then
        environments+=("swift_developer")
        echo "  📱 Swift/iOS development detected"
    fi
    
    if find . -maxdepth 2 -name "package.json" -o -name "yarn.lock" -o -name "webpack.config.js" 2>/dev/null | grep -q .; then
        environments+=("web_developer")
        echo "  🌐 Web development detected"
    fi
    
    if find . -maxdepth 2 -name "requirements.txt" -o -name "Pipfile" -o -name "*.ipynb" 2>/dev/null | grep -q .; then
        environments+=("python_developer")
        echo "  🐍 Python development detected"
    fi
    
    if find . -maxdepth 2 -name "Dockerfile" -o -name "docker-compose.yml" 2>/dev/null | grep -q .; then
        environments+=("containerization_user")
        echo "  🐳 Docker/containerization detected"
    fi
    
    # Check existing tools
    if [ -d "$HOME/.aws" ] || command -v aws >/dev/null 2>&1; then
        environments+=("cloud_developer")
        echo "  ☁️  Cloud development detected"
    fi
    
    if command -v docker >/dev/null 2>&1; then
        environments+=("containerization_user")
        echo "  🐳 Docker already available"
    fi
    
    # Work environment detection
    if hostname | grep -qi "work\|corp\|company" || [ -d "/Applications/Microsoft Teams.app" ]; then
        environments+=("work_environment")
        echo "  🏢 Work environment detected"
    fi
    
    # Save detected environments
    printf '%s\n' "${environments[@]}" > "$HOME/.dotfiles_detected_env"
    
    echo "✅ Environment detection complete"
    return 0
}

################################################################################
### Phase 1: Critical Core Tools (10 seconds)
################################################################################

install_critical_core() {
    echo "🚀 Phase 1: Installing critical tools (10 seconds)..."
    
    show_progress_bar 1 3 "Installing Homebrew if needed"
    
    # Ensure Homebrew is installed
    if ! command -v brew >/dev/null; then
        echo "📦 Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        eval "$(/opt/homebrew/bin/brew shellenv)"
    else
        echo "✅ Homebrew already installed"
    fi
    
    show_progress_bar 2 3 "Installing essential tools"
    
    # Critical tools only
    local essential_tools=(
        "git"           # Version control
        "curl"          # Downloads
        "wget"          # Alternative downloads
        "jq"            # JSON processing
        "tree"          # Directory visualization
        "mas"           # Mac App Store CLI
    )
    
    for tool in "${essential_tools[@]}"; do
        if ! brew list "$tool" >/dev/null 2>&1; then
            echo "  Installing $tool..."
            brew install "$tool" 2>/dev/null || echo "  ⚠️ Failed to install $tool"
        fi
    done
    
    show_progress_bar 3 3 "Setting up minimal shell config"
    
    # Minimal shell configuration
    setup_minimal_shell_config
    
    echo "✅ Phase 1 complete - Critical tools ready"
}

setup_minimal_shell_config() {
    echo "⚙️ Setting up minimal shell configuration..."
    
    # Create minimal .zshrc if it doesn't exist
    if [ ! -f "$HOME/.zshrc" ]; then
        cat > "$HOME/.zshrc" << 'EOF'
# Minimal dotfiles .zshrc - Quick Start Mode
# Run 'dotfiles-expand' to add more features

# Essential exports
export HOMEBREW_NO_ANALYTICS=1
export EDITOR="code"

# Essential aliases
alias ll='ls -la'
alias la='ls -A'
alias l='ls -CF'
alias ..='cd ..'
alias ...='cd ../..'
alias reload='source ~/.zshrc'

# Git aliases
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git pull'

# Quick dotfiles commands
alias dotfiles-expand='~/dotfiles/Scripts/quick_start.sh --expand'
alias dotfiles-health='~/dotfiles/Scripts/health_monitor.sh check'
alias dotfiles-help='~/dotfiles/Scripts/quick_start.sh --help'

# Add Homebrew to PATH
eval "$(/opt/homebrew/bin/brew shellenv)"

# Basic prompt
autoload -U colors && colors
PS1="%{$fg[green]%}%n@%m%{$reset_color%}:%{$fg[blue]%}%~%{$reset_color%}$ "
EOF
        echo "✅ Created minimal .zshrc"
    else
        echo "✅ .zshrc already exists"
    fi
    
    # Essential functions
    if [ ! -f "$HOME/.functions" ]; then
        cat > "$HOME/.functions" << 'EOF'
# Essential functions for quick start

# Quick directory navigation
cdl() { cd "$1" && ls; }
mkcd() { mkdir -p "$1" && cd "$1"; }

# Quick file operations
extract() {
    if [ -f "$1" ]; then
        case $1 in
            *.tar.bz2)   tar xjf "$1"     ;;
            *.tar.gz)    tar xzf "$1"     ;;
            *.bz2)       bunzip2 "$1"     ;;
            *.rar)       unrar x "$1"     ;;
            *.gz)        gunzip "$1"      ;;
            *.tar)       tar xf "$1"      ;;
            *.tbz2)      tar xjf "$1"     ;;
            *.tgz)       tar xzf "$1"     ;;
            *.zip)       unzip "$1"       ;;
            *.Z)         uncompress "$1"  ;;
            *.7z)        7z x "$1"        ;;
            *)           echo "'$1' cannot be extracted" ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}

# Quick git operations
gacp() {
    git add .
    git commit -m "$1"
    git push
}
EOF
        echo "source ~/.functions" >> "$HOME/.zshrc"
        echo "✅ Created essential functions"
    fi
}

################################################################################
### Phase 2: Basic Development Setup (15 seconds)
################################################################################

install_basic_development() {
    echo "🛠️ Phase 2: Basic development setup (15 seconds)..."
    
    show_progress_bar 1 4 "Installing development applications"
    
    # Essential development applications
    local dev_apps=(
        "visual-studio-code"    # Code editor
        "iterm2"               # Better terminal
    )
    
    for app in "${dev_apps[@]}"; do
        if ! brew list --cask "$app" >/dev/null 2>&1; then
            echo "  Installing $app..."
            brew install --cask "$app" 2>/dev/null || echo "  ⚠️ Failed to install $app"
        fi
    done
    
    show_progress_bar 2 4 "Configuring Git"
    
    # Git configuration
    setup_basic_git_config
    
    show_progress_bar 3 4 "Setting up SSH"
    
    # SSH setup
    setup_basic_ssh
    
    show_progress_bar 4 4 "Installing environment-specific tools"
    
    # Install tools based on detected environment
    install_environment_specific_tools
    
    echo "✅ Phase 2 complete - Development environment ready"
}

setup_basic_git_config() {
    echo "⚙️ Setting up basic Git configuration..."
    
    # Only set if not already configured
    if ! git config user.name >/dev/null 2>&1; then
        echo "📝 Git user configuration needed"
        read -p "Enter your Git username: " git_username
        read -p "Enter your Git email: " git_email
        
        git config --global user.name "$git_username"
        git config --global user.email "$git_email"
        
        # Basic Git settings
        git config --global init.defaultBranch main
        git config --global pull.rebase true
        git config --global core.autocrlf input
        
        echo "✅ Git configured"
    else
        echo "✅ Git already configured"
    fi
}

setup_basic_ssh() {
    echo "🔑 Setting up SSH..."
    
    if [ ! -f "$HOME/.ssh/id_ed25519" ] && [ ! -f "$HOME/.ssh/id_rsa" ]; then
        echo "🔐 Generating SSH key..."
        read -p "Enter your email for SSH key: " ssh_email
        ssh-keygen -t ed25519 -C "$ssh_email" -f "$HOME/.ssh/id_ed25519" -N ""
        
        # Start SSH agent and add key
        eval "$(ssh-agent -s)"
        ssh-add "$HOME/.ssh/id_ed25519"
        
        echo "📋 Your SSH public key (copy this to GitHub/GitLab):"
        cat "$HOME/.ssh/id_ed25519.pub"
        echo ""
        echo "💡 Tip: Run 'pbcopy < ~/.ssh/id_ed25519.pub' to copy to clipboard"
        
        # Fix permissions
        chmod 700 "$HOME/.ssh"
        chmod 600 "$HOME/.ssh/id_ed25519"
        chmod 644 "$HOME/.ssh/id_ed25519.pub"
        
        echo "✅ SSH key generated"
    else
        echo "✅ SSH key already exists"
    fi
}

install_environment_specific_tools() {
    if [ ! -f "$HOME/.dotfiles_detected_env" ]; then
        return
    fi
    
    echo "🎯 Installing environment-specific tools..."
    
    while IFS= read -r environment; do
        case "$environment" in
            swift_developer)
                echo "  📱 Installing Swift development basics..."
                brew install swiftlint swiftformat 2>/dev/null || true
                ;;
            web_developer)
                echo "  🌐 Installing web development basics..."
                brew install node 2>/dev/null || true
                ;;
            python_developer)
                echo "  🐍 Installing Python development basics..."
                brew install python pyenv 2>/dev/null || true
                ;;
            containerization_user)
                echo "  🐳 Installing Docker..."
                brew install --cask docker 2>/dev/null || true
                ;;
            cloud_developer)
                echo "  ☁️ Installing cloud tools..."
                brew install awscli 2>/dev/null || true
                ;;
        esac
    done < "$HOME/.dotfiles_detected_env"
}

################################################################################
### Phase 3: Smart Suggestions (5 seconds)
################################################################################

provide_smart_suggestions() {
    echo "💡 Phase 3: Smart suggestions and next steps (5 seconds)..."
    
    show_progress_bar 1 2 "Analyzing your setup"
    
    # Generate personalized recommendations
    local suggestions=()
    
    if [ -f "$HOME/.dotfiles_detected_env" ]; then
        while IFS= read -r environment; do
            case "$environment" in
                swift_developer)
                    suggestions+=("🍎 Enable Swift plugin: dotfiles-plugin-enable swift-dev")
                    suggestions+=("📱 Install Xcode from App Store: mas install 497799835")
                    ;;
                web_developer)
                    suggestions+=("🌐 Install web development tools: brew install yarn typescript")
                    suggestions+=("⚡ Setup React/Vue environment with recommended extensions")
                    ;;
                python_developer)
                    suggestions+=("🐍 Setup Python environment: pyenv install 3.11.0 && pyenv global 3.11.0")
                    suggestions+=("📊 Install data science tools: pip install pandas numpy matplotlib")
                    ;;
                work_environment)
                    suggestions+=("🏢 Setup work profile: dotfiles-setup --work-mode")
                    suggestions+=("📞 Install Teams/Slack for communication")
                    ;;
            esac
        done < "$HOME/.dotfiles_detected_env"
    fi
    
    # Universal suggestions
    suggestions+=("🔧 Run full setup: ~/dotfiles/bootstrap.sh")
    suggestions+=("🩺 Check system health: dotfiles-health")
    suggestions+=("📦 Explore plugins: ~/dotfiles/Scripts/plugin_manager.sh list")
    
    show_progress_bar 2 2 "Preparing recommendations"
    
    echo ""
    echo "🎉 Quick Start Complete! (Setup time: ~30 seconds)"
    echo "=================================================="
    echo ""
    echo "✅ You now have:"
    echo "  • Essential development tools (git, curl, jq, etc.)"
    echo "  • Code editor (VS Code) and better terminal (iTerm2)"
    echo "  • Basic Git and SSH configuration"
    echo "  • Environment-specific tools for your projects"
    echo ""
    echo "💡 Recommended next steps:"
    
    local count=1
    for suggestion in "${suggestions[@]}"; do
        echo "  $count. $suggestion"
        ((count++))
        [ $count -gt 8 ] && break  # Limit to 8 suggestions
    done
    
    echo ""
    echo "🚀 Quick commands:"
    echo "  dotfiles-expand     - Install additional tools"
    echo "  dotfiles-health     - Check system health"
    echo "  dotfiles-help       - Show help and options"
    echo ""
    echo "📚 Full documentation: ~/dotfiles/README.md"
}

################################################################################
### Expansion Mode
################################################################################

expand_installation() {
    echo "🔧 Expanding installation with additional tools..."
    
    echo ""
    echo "Choose expansion option:"
    echo "1) Full dotfiles setup (all features)"
    echo "2) Development-focused setup"
    echo "3) Productivity tools"
    echo "4) Security and privacy tools"
    echo "5) Custom selection"
    echo ""
    
    read -p "Enter choice (1-5): " choice
    
    case $choice in
        1)
            echo "🚀 Running full bootstrap setup..."
            "$DOTFILES_DIR/bootstrap.sh"
            ;;
        2)
            echo "👨‍💻 Installing development tools..."
            install_development_expansion
            ;;
        3)
            echo "📈 Installing productivity tools..."
            install_productivity_expansion
            ;;
        4)
            echo "🔒 Installing security tools..."
            install_security_expansion
            ;;
        5)
            echo "🎯 Custom tool selection..."
            custom_tool_selection
            ;;
        *)
            echo "Invalid choice. Use dotfiles-expand to try again."
            ;;
    esac
}

install_development_expansion() {
    local dev_tools=(
        "docker"
        "kubectl"
        "terraform"
        "ansible"
        "postman"
        "github-desktop"
        "sourcetree"
    )
    
    echo "Installing development tools..."
    for tool in "${dev_tools[@]}"; do
        echo "  Installing $tool..."
        brew install --cask "$tool" 2>/dev/null || brew install "$tool" 2>/dev/null || echo "    ⚠️ Failed to install $tool"
    done
}

install_productivity_expansion() {
    local productivity_tools=(
        "alfred"
        "raycast"
        "notion"
        "obsidian"
        "rectangle"
        "cleanmymac"
    )
    
    echo "Installing productivity tools..."
    for tool in "${productivity_tools[@]}"; do
        echo "  Installing $tool..."
        brew install --cask "$tool" 2>/dev/null || echo "    ⚠️ Failed to install $tool"
    done
}

install_security_expansion() {
    local security_tools=(
        "1password"
        "little-snitch"
        "micro-snitch"
        "gpg-suite"
        "keybase"
    )
    
    echo "Installing security tools..."
    for tool in "${security_tools[@]}"; do
        echo "  Installing $tool..."
        brew install --cask "$tool" 2>/dev/null || echo "    ⚠️ Failed to install $tool"
    done
}

custom_tool_selection() {
    echo "🎯 Custom tool selection coming soon..."
    echo "For now, use: brew search <tool-name> to find and install specific tools"
}

################################################################################
### Main Functions
################################################################################

run_quick_start() {
    echo "🚀 Ultra-Fast Quick Start Mode"
    echo "============================="
    echo "Setting up essential tools in ~30 seconds..."
    echo ""
    
    # Log start time
    echo "$(date): Quick start initiated" > "$QUICK_START_LOG"
    
    # Phase 1: Critical tools (10 seconds)
    detect_user_environment
    install_critical_core
    
    # Phase 2: Development setup (15 seconds)  
    install_basic_development
    
    # Phase 3: Suggestions (5 seconds)
    provide_smart_suggestions
    
    # Log completion
    echo "$(date): Quick start completed" >> "$QUICK_START_LOG"
    
    echo "✨ Quick start complete! Your development environment is ready."
}

show_help() {
    cat << 'EOF'
🚀 Ultra-Fast Quick Start Mode

DESCRIPTION:
    Get productive in 30 seconds with essential tools only.
    Progressive enhancement available after core setup.

USAGE:
    ./quick_start.sh [command]

COMMANDS:
    run                 Run quick start setup (default)
    --expand           Expand installation with additional tools
    --status           Show quick start status
    --help             Show this help

FEATURES:
    • 30-second setup with essential tools only
    • Environment detection (Swift, Web, Python, etc.)
    • Smart recommendations based on your projects
    • Progressive enhancement - add tools as needed
    • No bloat - only install what you'll actually use

QUICK COMMANDS (after setup):
    dotfiles-expand     - Add more tools
    dotfiles-health     - Check system health  
    dotfiles-help       - Show this help

EXAMPLES:
    ./quick_start.sh                    # Run quick setup
    ./quick_start.sh --expand           # Add more tools
    ./quick_start.sh --status           # Check status

EOF
}

show_status() {
    echo "📊 Quick Start Status"
    echo "===================="
    
    if [ -f "$QUICK_START_LOG" ]; then
        echo "✅ Quick start has been run"
        echo "Last run: $(tail -1 "$QUICK_START_LOG")"
    else
        echo "❌ Quick start not yet run"
        echo "Run: ./quick_start.sh"
        return
    fi
    
    echo ""
    echo "🔍 Detected environment:"
    if [ -f "$HOME/.dotfiles_detected_env" ]; then
        while IFS= read -r env; do
            echo "  • $env"
        done < "$HOME/.dotfiles_detected_env"
    else
        echo "  No environment detected yet"
    fi
    
    echo ""
    echo "🛠️ Essential tools status:"
    local tools=("git" "curl" "jq" "brew" "code")
    for tool in "${tools[@]}"; do
        if command -v "$tool" >/dev/null 2>&1; then
            echo "  ✅ $tool"
        else
            echo "  ❌ $tool (missing)"
        fi
    done
}

main() {
    case "${1:-run}" in
        run)
            run_quick_start
            ;;
        --expand)
            expand_installation
            ;;
        --status)
            show_status
            ;;
        --help|-h)
            show_help
            ;;
        *)
            echo "❌ Unknown command: $1"
            echo "💡 Use '$0 --help' for usage information"
            exit 1
            ;;
    esac
}

# Run main function if script is executed directly
if [ "${BASH_SOURCE[0]:-}" = "${0:-}" ]; then
    main "$@"
fi