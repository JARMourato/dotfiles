#!/bin/bash

# Simple profile-based setup script
# This script converts YAML configuration to shell variables

set -e

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
    echo "Examples:"
    echo "  $0 dev        # Set up development machine"
    echo "  $0 personal   # Set up personal machine"
    echo "  $0 server     # Set up server machine"
}

# Function to parse YAML and create shell config
parse_yaml_to_config() {
    local profile="$1"
    local yaml_file="$SCRIPT_DIR/.dotfiles.$profile.yaml"
    local output_file="$SCRIPT_DIR/.dotfiles.config"
    
    if [[ ! -f "$yaml_file" ]]; then
        echo "Error: Profile configuration not found: $yaml_file"
        exit 1
    fi
    
    echo "# Generated configuration for profile: $profile" > "$output_file"
    echo "# Generated at: $(date)" >> "$output_file"
    echo "" >> "$output_file"
    
    # Extract basic config
    echo "MACHINE_PROFILE=\"$profile\"" >> "$output_file"
    
    # Parse homebrew formulas (precise parsing to avoid conflicts)
    local formulas=$(awk '/^  formulas:/{flag=1; next} /^  [a-z]/{flag=0} flag && /^    - /{gsub(/^    - /, ""); print}' "$yaml_file" | tr '\n' ' ' | sed 's/ $//')
    if [[ -n "$formulas" ]]; then
        echo "HOMEBREW_FORMULAS=\"$formulas\"" >> "$output_file"
    fi
    
    # Parse homebrew casks (more precise parsing to avoid conflicts)
    local casks=$(awk '/^  casks:/{flag=1; next} /^  [a-z]/{flag=0} flag && /^    - /{gsub(/^    - /, ""); print}' "$yaml_file" | tr '\n' ' ' | sed 's/ $//')
    if [[ -n "$casks" ]]; then
        echo "HOMEBREW_CASKS=\"$casks\"" >> "$output_file"
    fi
    
    # Parse MAS apps
    local mas_ids=$(grep -A 20 "mas_apps:" "$yaml_file" | grep "  - id:" | sed 's/  - id: //' | tr '\n' ' ' | sed 's/ $//')
    if [[ -n "$mas_ids" ]]; then
        echo "MAS_APPS=\"$mas_ids\"" >> "$output_file"
    fi
    
    # Parse configuration flags
    
    local enable_powerline=$(grep "enable_powerline:" "$yaml_file" | sed 's/.*enable_powerline: //')
    [[ -n "$enable_powerline" ]] && echo "ENABLE_POWERLINE=\"$enable_powerline\"" >> "$output_file"
    
    local theme=$(grep "theme:" "$yaml_file" | sed 's/.*theme: "//' | sed 's/"//')
    [[ -n "$theme" ]] && echo "THEME=\"$theme\"" >> "$output_file"
    
    # Parse git configuration
    local git_user_name=$(grep "user_name:" "$yaml_file" | sed 's/.*user_name: "//' | sed 's/"//')
    [[ -n "$git_user_name" ]] && echo "GIT_USER_NAME=\"$git_user_name\"" >> "$output_file"
    
    local git_user_email=$(grep "user_email:" "$yaml_file" | sed 's/.*user_email: "//' | sed 's/"//')
    [[ -n "$git_user_email" ]] && echo "GIT_USER_EMAIL=\"$git_user_email\"" >> "$output_file"
    
    # Parse cleanup apps configuration (nested under config)
    local cleanup_apps=$(awk '/^  cleanup_apps:/{flag=1; next} /^  [a-z]/{flag=0} flag && /^    - /{gsub(/^    - "?/, ""); gsub(/"$/, ""); print}' "$yaml_file" | tr '\n' ' ' | sed 's/ $//')
    if [[ -n "$cleanup_apps" ]]; then
        echo "CLEANUP_APPS=\"$cleanup_apps\"" >> "$output_file"
    fi
    
    # Parse user defaults configuration
    local parser_script="$SCRIPT_DIR/Scripts/parse_user_defaults.sh"
    if [[ -f "$parser_script" ]]; then
        source "$parser_script"
        parse_user_defaults "$yaml_file" "$output_file"
    else
        echo "# User defaults parser not found: $parser_script" >> "$output_file"
    fi
    
    echo "" >> "$output_file"
    echo "# Profile setup completed" >> "$output_file"
    
    echo "✅ Profile '$profile' configuration generated: $output_file"
}

# Main execution
main() {
    local profile="${1:-}"
    
    # Parse command line arguments
    case "$profile" in
        -h|--help)
            show_usage
            exit 0
            ;;
        "")
            echo "Error: Profile argument required"
            show_usage
            exit 1
            ;;
        *)
            if [[ ! " ${AVAILABLE_PROFILES[@]} " =~ " $profile " ]]; then
                echo "Error: Invalid profile '$profile'"
                echo "Available profiles: ${AVAILABLE_PROFILES[*]}"
                exit 1
            fi
            ;;
    esac
    
    # Generate configuration
    parse_yaml_to_config "$profile"
    
    echo ""
    echo "Next steps:"
    echo "==========="
    echo "Profile configuration has been generated."
    echo "The main setup script will now use these settings."
}

# Run main function with all arguments
main "$@"