#!/bin/bash

# Profile-based setup script
# This script handles loading the appropriate profile configuration

set -euo pipefail

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Available profiles
AVAILABLE_PROFILES=("dev" "personal" "server")

# Function to show usage
show_usage() {
    echo "Usage: $0 [PROFILE]"
    echo ""
    echo "Available profiles:"
    echo "  dev       - Development machine (Xcode, development tools, IDEs)"
    echo "  personal  - Personal machine (entertainment, productivity apps)"
    echo "  server    - Server/headless machine (Docker, server tools, no GUI)"
    echo ""
    echo "If no profile is specified, you'll be prompted to choose one."
    echo ""
    echo "Examples:"
    echo "  $0 dev        # Set up development machine"
    echo "  $0 personal   # Set up personal machine"
    echo "  $0 server     # Set up server machine"
}

# Function to detect current profile
detect_current_profile() {
    local hostname=$(hostname)
    local current_profile=""
    
    # Try to detect from existing configuration
    if [[ -f "$SCRIPT_DIR/.dotfiles.config" ]]; then
        current_profile=$(grep "MACHINE_PROFILE=" "$SCRIPT_DIR/.dotfiles.config" 2>/dev/null | cut -d'=' -f2 | tr -d '"' || echo "")
    fi
    
    # If no profile set, try to guess from hostname
    if [[ -z "$current_profile" ]]; then
        case "$hostname" in
            *dev*|*development*) current_profile="dev" ;;
            *server*|*mini*) current_profile="server" ;;
            *) current_profile="personal" ;;
        esac
    fi
    
    echo "$current_profile"
}

# Function to prompt for profile selection
prompt_for_profile() {
    echo "Please select a profile for this machine:"
    echo ""
    echo "1) dev       - Development machine"
    echo "   • Xcode, development tools, IDEs"
    echo "   • Swift/iOS development focus"
    echo "   • Docker, cloud tools"
    echo ""
    echo "2) personal  - Personal machine"
    echo "   • Productivity and entertainment apps"
    echo "   • Creative tools, games, media"
    echo "   • Lighter development setup"
    echo ""
    echo "3) server    - Server/headless machine"
    echo "   • Docker and container tools"
    echo "   • Server monitoring and management"
    echo "   • No GUI applications"
    echo ""
    read -p "Choose profile (1-3): " choice
    
    case "$choice" in
        1) echo "dev" ;;
        2) echo "personal" ;;
        3) echo "server" ;;
        *) echo "Invalid choice. Defaulting to 'personal'"; echo "personal" ;;
    esac
}

# Function to load profile configuration
load_profile() {
    local profile="$1"
    local base_config="$SCRIPT_DIR/.dotfiles.config"
    local profile_config="$SCRIPT_DIR/.dotfiles.$profile.config"
    
    echo "Loading profile: $profile"
    
    # Check if profile config exists
    if [[ ! -f "$profile_config" ]]; then
        echo "Error: Profile configuration not found: $profile_config"
        exit 1
    fi
    
    # Create a temporary combined config
    local temp_config=$(mktemp)
    
    # Load base config first
    if [[ -f "$base_config" ]]; then
        cat "$base_config" > "$temp_config"
        echo "" >> "$temp_config"
    fi
    
    # Add profile-specific config
    echo "# Profile-specific configuration ($profile)" >> "$temp_config"
    cat "$profile_config" >> "$temp_config"
    
    # Replace the main config with combined config
    mv "$temp_config" "$base_config"
    
    echo "✅ Profile '$profile' loaded successfully"
    echo "Configuration saved to: $base_config"
}

# Function to show current configuration
show_current_config() {
    local profile=$(detect_current_profile)
    echo "Current machine profile: $profile"
    
    if [[ -f "$SCRIPT_DIR/.dotfiles.config" ]]; then
        echo ""
        echo "Key configuration settings:"
        echo "=========================="
        grep -E "^(MACHINE_PROFILE|DEVELOPMENT_TYPE|MINIMAL_PACKAGES|SKIP_.*=false)" "$SCRIPT_DIR/.dotfiles.config" 2>/dev/null || echo "No specific settings found"
        
        echo ""
        echo "Main packages to be installed:"
        echo "============================="
        grep -E "^(HOMEBREW_FORMULAS|HOMEBREW_CASKS|ADDITIONAL_.*)" "$SCRIPT_DIR/.dotfiles.config" 2>/dev/null | head -10 || echo "No packages configured"
    else
        echo "No configuration file found. Run with a profile to create one."
    fi
}

# Main execution
main() {
    local profile=""
    
    # Parse command line arguments
    case "${1:-}" in
        -h|--help)
            show_usage
            exit 0
            ;;
        --current|--status)
            show_current_config
            exit 0
            ;;
        "")
            # No profile specified, prompt user
            profile=$(prompt_for_profile)
            ;;
        *)
            profile="$1"
            ;;
    esac
    
    # Validate profile
    if [[ ! " ${AVAILABLE_PROFILES[@]} " =~ " $profile " ]]; then
        echo "Error: Invalid profile '$profile'"
        echo "Available profiles: ${AVAILABLE_PROFILES[*]}"
        exit 1
    fi
    
    # Load the profile
    load_profile "$profile"
    
    echo ""
    echo "Next steps:"
    echo "==========="
    echo "1. Review the configuration: cat .dotfiles.config"
    echo "2. Run the setup: ./bootstrap.sh"
    echo "3. Or run specific components:"
    echo "   • setup-deps              # Install packages"
    echo "   • setup-symlinks          # Create symlinks"
    echo "   • machine-sync init       # Set up sync"
}

# Run main function with all arguments
main "$@"