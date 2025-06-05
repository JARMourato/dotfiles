#!/bin/bash

# Quick start mode check
if [ "${1:-}" = "--quick" ] || [ "${1:-}" = "--ultra-quick" ]; then
    echo "🚀 Quick Start Mode Detected"
    exec "$(dirname "$0")/Scripts/quick_start.sh" run
fi

set -euo pipefail

################################################################################
### Error Handling and Utility Functions
################################################################################

# Retry function for network operations
retry_command() {
    local retries=3
    local count=0
    until "$@"; do
        exit_code=$?
        count=$((count + 1))
        if [ $count -lt $retries ]; then
            echo "Command failed. Attempt $count/$retries. Retrying in 5 seconds..."
            sleep 5
        else
            echo "Command failed after $retries attempts."
            return $exit_code
        fi
    done
}

# Verify downloaded script integrity
verify_script_checksum() {
    local script_path="$1"
    local expected_hash="$2"
    local script_name="$3"
    
    if [ -n "$expected_hash" ]; then
        echo "🔍 Verifying $script_name integrity..."
        local actual_hash=$(shasum -a 256 "$script_path" | cut -d' ' -f1)
        if [ "$actual_hash" != "$expected_hash" ]; then
            echo "❌ Error: $script_name checksum mismatch!"
            echo "Expected: $expected_hash"
            echo "Actual:   $actual_hash"
            echo "This may indicate the script has been tampered with."
            exit 1
        fi
        echo "✅ $script_name integrity verified"
    else
        echo "⚠️  No checksum provided for $script_name - proceeding without verification"
    fi
}

# Download and verify script
download_and_verify_script() {
    local url="$1"
    local expected_hash="$2"
    local script_name="$3"
    local temp_file="/tmp/${script_name}_install.sh"
    
    echo "📥 Downloading $script_name..."
    # Use cached download if caching is available
    if command -v download_with_cache >/dev/null 2>&1; then
        local cached_file=$(download_with_cache "$url" "$script_name")
        cp "$cached_file" "$temp_file"
    else
        retry_command curl -fsSL "$url" > "$temp_file"
    fi
    verify_script_checksum "$temp_file" "$expected_hash" "$script_name"
    echo "$temp_file"
}

# Check disk space (require at least 10GB)
check_disk_space() {
    local required_gb=10
    local available=$(df -BG / | awk 'NR==2 {print $4}' | sed 's/G//')
    if [ "$available" -lt "$required_gb" ]; then
        echo "Error: Need at least ${required_gb}GB free space. Have ${available}GB"
        exit 1
    fi
}

# Check internet connectivity
check_internet() {
    if ! ping -c 1 google.com >/dev/null 2>&1; then
        echo "Error: No internet connection detected"
        exit 1
    fi
}

# Cross-platform clipboard function
toClipboard() {
    if command -v pbcopy > /dev/null; then
        pbcopy
    elif command -v xclip > /dev/null; then
        xclip -i -selection c
    else
        echo "No clipboard tool found. Here's what you need to paste into the developer console:"
        cat -
    fi
}

# Load performance libraries if available
load_performance_libraries() {
    local dotfiles_dir="${DOTFILES_DIR:-$HOME/.dotfiles}"
    
    # Load progress indicators
    if [ -f "$dotfiles_dir/Scripts/progress_indicators.sh" ]; then
        source "$dotfiles_dir/Scripts/progress_indicators.sh"
        echo "📊 Loaded progress indicators"
    fi
    
    # Load caching system
    if [ -f "$dotfiles_dir/Scripts/caching_system.sh" ]; then
        source "$dotfiles_dir/Scripts/caching_system.sh"
        init_cache
        echo "💾 Initialized caching system"
    fi
    
    # Load parallel operations
    if [ -f "$dotfiles_dir/Scripts/parallel_operations.sh" ]; then
        source "$dotfiles_dir/Scripts/parallel_operations.sh"
        echo "⚡ Loaded parallel operations"
    fi
}

################################################################################
### Pre-flight Checks
################################################################################

echo "🔍 Running pre-flight checks..."
check_disk_space
check_internet
echo "✅ Pre-flight checks passed"

################################################################################
### Help Documentation
################################################################################

show_help() {
    cat << 'EOF'
📖 bootstrap.sh - Complete macOS dotfiles setup from scratch

DESCRIPTION:
    Sets up a new macOS machine with dotfiles, applications, and configurations.
    Handles SSH key generation, Xcode tools, Homebrew, and complete system setup.
    Supports multiple setup modes and configuration customization.

USAGE:
    bootstrap.sh <encryption_password> [OPTIONS]
    bootstrap.sh --help

ARGUMENTS:
    encryption_password    Password for decrypting sensitive dotfiles

OPTIONS:
    --minimal             Minimal setup - only essential tools, no GUI apps
    --dev-only            Development tools only, skip entertainment apps
    --work                Corporate-friendly setup, skip personal apps
    --quick               Fast setup, skip time-consuming installations
    --config FILE         Use custom configuration file
    --snapshot NAME       Create snapshot before setup (for rollback)
    --update-only         Update existing installation only
    --dry-run             Show what would be installed without doing it
    --help, -h            Show this help message

SETUP MODES:
    default               Full installation with all packages and apps
    --minimal             Core tools only (git, age, jq), no GUI applications
    --dev-only            Development tools, skip entertainment/personal apps
    --work                Work setup, skip personal apps, add corporate tools
    --quick               Fast setup, skip Xcode, MAS apps, Ruby/Python

CONFIGURATION:
    Setup behavior is controlled by .dotfiles.config file
    Edit this file to customize packages, skip installations, etc.
    Use --config to specify alternate configuration file.

REQUIREMENTS:
    • macOS system
    • Internet connection
    • At least 10GB free disk space (less for minimal mode)
    • Terminal with full disk access permissions

WHAT IT DOES:
    1. Checks system requirements (disk space, internet)
    2. Loads configuration and applies setup mode
    3. Creates snapshot (if requested)
    4. Sets up SSH keys for GitHub (if needed)
    5. Installs Xcode Command Line Tools (unless skipped)
    6. Creates workspace directories
    7. Clones dotfiles repository
    8. Runs configured system setup

EXAMPLES:
    # Full setup
    bash bootstrap.sh "my_secure_password"
    
    # Minimal setup for CI/build machines
    bash bootstrap.sh "password" --minimal
    
    # Work laptop setup
    bash bootstrap.sh "password" --work --snapshot "before_work_setup"
    
    # Quick setup with custom config
    bash bootstrap.sh "password" --quick --config /path/to/custom.config
    
    # Test what would be installed
    bash bootstrap.sh "password" --dev-only --dry-run

TROUBLESHOOTING:
    • If setup fails, check TROUBLESHOOTING.md in the dotfiles repo
    • Use --dry-run to preview changes before applying
    • Create snapshots before major changes for easy rollback
    • Ensure Terminal has full disk access in System Preferences

EOF
}

################################################################################
### Parse Command Line Arguments
################################################################################

# Initialize variables
ENCRYPTION_PASSWORD=""
SETUP_MODE=""
CONFIG_FILE=""
SNAPSHOT_NAME=""
UPDATE_ONLY=false
DRY_RUN=false

# Parse arguments
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --help|-h)
                show_help
                exit 0
                ;;
            --minimal)
                SETUP_MODE="minimal"
                shift
                ;;
            --dev-only)
                SETUP_MODE="dev-only"
                shift
                ;;
            --work)
                SETUP_MODE="work"
                shift
                ;;
            --quick)
                SETUP_MODE="quick"
                shift
                ;;
            --config)
                CONFIG_FILE="$2"
                shift 2
                ;;
            --snapshot)
                SNAPSHOT_NAME="$2"
                shift 2
                ;;
            --update-only)
                UPDATE_ONLY=true
                shift
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            -*)
                echo "Unknown option: $1"
                echo "Use --help for usage information"
                exit 1
                ;;
            *)
                if [ -z "$ENCRYPTION_PASSWORD" ]; then
                    ENCRYPTION_PASSWORD="$1"
                else
                    echo "Unexpected argument: $1"
                    echo "Use --help for usage information"
                    exit 1
                fi
                shift
                ;;
        esac
    done
}

# Parse command line arguments
parse_arguments "$@"

# Check for required encryption password
if [ -z "$ENCRYPTION_PASSWORD" ]; then
   echo "❌ Error: Encryption password missing"
   echo "Use --help for usage information"
   exit 1
fi

# Show setup summary
echo "🚀 Bootstrap Setup Summary"
echo "=========================="
echo "Mode: ${SETUP_MODE:-default}"
echo "Config: ${CONFIG_FILE:-default (.dotfiles.config)}"
echo "Snapshot: ${SNAPSHOT_NAME:-none}"
echo "Update only: $UPDATE_ONLY"
echo "Dry run: $DRY_RUN"
echo ""

# Initialize performance systems early if in dotfiles directory
if [ -d "$HOME/.dotfiles/Scripts" ]; then
    load_performance_libraries
fi

if [ "$DRY_RUN" = true ]; then
    echo "🔍 DRY RUN MODE - No actual changes will be made"
    echo ""
fi

################################################################################
### Configure SSH key
################################################################################

count=`ls -1 ~/.ssh/*.pub 2>/dev/null | wc -l`
if [ $count != 0 ]; then
   echo "Assuming Github SSH has been setup previously!"
else 
   echo "No ssh key has been found! Setting up new Github SSH key."
   
   
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


rm -rf ~/.dotfiles
echo "📥 Cloning dotfiles repository..."
if command -v run_with_spinner >/dev/null 2>&1; then
    run_with_spinner "retry_command git clone git@github.com:jarmourato/dotfiles.git ~/.dotfiles" "Cloning dotfiles repository"
else
    retry_command git clone git@github.com:jarmourato/dotfiles.git ~/.dotfiles
fi
cd ~/.dotfiles

# Load performance libraries now that we're in the dotfiles directory
load_performance_libraries

# Set up configuration system
export DOTFILES_DIR="$HOME/.dotfiles"
if [ -n "$CONFIG_FILE" ]; then
    export DOTFILES_CONFIG_FILE="$CONFIG_FILE"
fi

# Load configuration and apply setup mode
source Scripts/config_parser.sh
init_config "$SETUP_MODE"

# Create snapshot if requested
if [ -n "$SNAPSHOT_NAME" ]; then
    if [ "$DRY_RUN" = false ]; then
        echo "📸 Creating snapshot: $SNAPSHOT_NAME"
        Scripts/create_snapshot.sh "$SNAPSHOT_NAME" --description "Snapshot before bootstrap setup" || true
    else
        echo "🔍 DRY RUN: Would create snapshot: $SNAPSHOT_NAME"
    fi
fi

# Show configuration summary
if [ "$DRY_RUN" = true ] || [ -n "$SETUP_MODE" ]; then
    show_config
fi

echo "🚀 Starting setup process..."

# Pass all configuration to setup script
if [ "$DRY_RUN" = true ]; then
    echo "🔍 DRY RUN MODE - Setup process would run with configuration:"
    show_config
    echo ""
    echo "✅ Bootstrap dry run completed"
    echo "Run without --dry-run to apply changes"
else
    # Run setup with performance monitoring if available
    if command -v run_with_progress >/dev/null 2>&1; then
        run_with_progress "dotfiles_setup" "./_set_up.sh '$ENCRYPTION_PASSWORD'" 5
    else
        ./_set_up.sh "$ENCRYPTION_PASSWORD"
    fi
    echo "✅ Bootstrap completed successfully!"
    
    # Show cache statistics if available
    if command -v show_cache_stats >/dev/null 2>&1; then
        echo ""
        show_cache_stats
    fi
fi
