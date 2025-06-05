#!/bin/bash

set -euo pipefail

################################################################################
### System State and Inventory Tracking
################################################################################

# Show help documentation
show_help() {
    cat << 'EOF'
📖 track_system_state.sh - Track machine configuration and installed software

DESCRIPTION:
    Creates comprehensive inventory of system state including installed packages,
    versions, configurations, and dotfiles status for debugging and compliance.

USAGE:
    track_system_state.sh [--output FILE] [--format FORMAT]
    track_system_state.sh --help

OPTIONS:
    --output FILE        Save inventory to specific file (default: ~/.dotfiles_inventory.json)
    --format FORMAT      Output format: json, yaml, or text (default: json)
    --help, -h           Show this help message

INVENTORY INCLUDES:
    • System information (OS, hostname, hardware)
    • Dotfiles repository status and version
    • Homebrew packages and casks
    • Mac App Store applications
    • Ruby gems and Python packages
    • Development tool versions
    • Setup completion timestamps

OUTPUT FORMATS:
    json    Machine-readable JSON (default)
    yaml    Human-readable YAML
    text    Plain text summary

EXAMPLES:
    track_system_state.sh
    track_system_state.sh --output ~/Desktop/inventory.json
    track_system_state.sh --format yaml --output system.yaml
    track_system_state.sh --format text | less

USE CASES:
    • Debug setup differences between machines
    • Audit installed software for compliance
    • Track changes over time
    • Backup system configuration state
    • Generate reports for team synchronization

SEE ALSO:
    compare_inventories.sh - Compare inventories between machines

EOF
}

# Get current timestamp in ISO format
get_timestamp() {
    date -u +"%Y-%m-%dT%H:%M:%SZ"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Get system information
get_system_info() {
    local hostname=$(hostname)
    local os_version=""
    local hardware_info=""
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        os_version=$(sw_vers -productVersion)
        hardware_info=$(system_profiler SPHardwareDataType | grep "Model Name\|Chip\|Memory" | head -3)
    else
        os_version=$(uname -r)
        hardware_info=$(uname -m)
    fi
    
    cat << EOF
{
  "hostname": "$hostname",
  "os_type": "$OSTYPE",
  "os_version": "$os_version",
  "hardware_info": "$hardware_info"
}
EOF
}

# Get dotfiles repository information
get_dotfiles_info() {
    local repo_path="${DOTFILES_DIR:-$HOME/.dotfiles}"
    local git_hash="unknown"
    local git_branch="unknown"
    local last_update="unknown"
    
    if [ -d "$repo_path/.git" ]; then
        git_hash=$(git -C "$repo_path" rev-parse HEAD 2>/dev/null || echo "unknown")
        git_branch=$(git -C "$repo_path" branch --show-current 2>/dev/null || echo "unknown")
        last_update=$(git -C "$repo_path" log -1 --format="%ai" 2>/dev/null || echo "unknown")
    fi
    
    cat << EOF
{
  "repository_path": "$repo_path",
  "git_hash": "$git_hash",
  "git_branch": "$git_branch",
  "last_update": "$last_update"
}
EOF
}

# Get Homebrew packages
get_homebrew_packages() {
    if command_exists brew; then
        local formulas=$(brew list --formula --json 2>/dev/null || echo "[]")
        local casks=$(brew list --cask --json 2>/dev/null || echo "[]")
        
        cat << EOF
{
  "formulas": $formulas,
  "casks": $casks
}
EOF
    else
        echo '{"formulas": [], "casks": []}'
    fi
}

# Get Mac App Store applications
get_mas_apps() {
    if command_exists mas; then
        local apps=$(mas list 2>/dev/null | while read line; do
            local id=$(echo "$line" | cut -d' ' -f1)
            local name=$(echo "$line" | cut -d' ' -f2-)
            echo "{\"id\": \"$id\", \"name\": \"$name\"}"
        done | jq -s 2>/dev/null || echo "[]")
        
        echo "$apps"
    else
        echo "[]"
    fi
}

# Get Ruby gems
get_ruby_gems() {
    if command_exists gem; then
        gem list --json 2>/dev/null || echo "[]"
    else
        echo "[]"
    fi
}

# Get Python packages
get_python_packages() {
    if command_exists pip3; then
        pip3 list --format=json 2>/dev/null || echo "[]"
    else
        echo "[]"
    fi
}

# Get development tool versions
get_tool_versions() {
    local versions=()
    
    # Check common development tools
    for tool in brew git ruby python3 node npm yarn rbenv pyenv; do
        if command_exists "$tool"; then
            local version=$($tool --version 2>/dev/null | head -n1 || echo "unknown")
            versions+=("\"$tool\": \"$version\"")
        fi
    done
    
    # Special cases
    if command_exists xcode-select; then
        local xcode_version=$(xcode-select --version 2>/dev/null || echo "unknown")
        versions+=("\"xcode-select\": \"$xcode_version\"")
    fi
    
    if command_exists age; then
        local age_version=$(age --version 2>/dev/null | head -n1 || echo "unknown")
        versions+=("\"age\": \"$age_version\"")
    fi
    
    echo "{$(IFS=','; echo "${versions[*]}")}"
}

# Get setup completion status
get_setup_status() {
    local repo_path="${DOTFILES_DIR:-$HOME/.dotfiles}"
    local setup_completed=false
    local last_setup="unknown"
    
    # Check if key symlinks exist (indicates completed setup)
    if [ -L ~/.zshrc ] && [ -L ~/.aliases ] && [ -L ~/.exports ]; then
        setup_completed=true
        
        # Get timestamp of most recent symlink
        if [[ "$OSTYPE" == "darwin"* ]]; then
            last_setup=$(stat -f %Sm -t %Y-%m-%dT%H:%M:%SZ ~/.zshrc 2>/dev/null || echo "unknown")
        else
            last_setup=$(stat -c %y ~/.zshrc 2>/dev/null | cut -d' ' -f1,2 || echo "unknown")
        fi
    fi
    
    cat << EOF
{
  "setup_completed": $setup_completed,
  "last_setup": "$last_setup"
}
EOF
}

# Create complete inventory in JSON format
create_json_inventory() {
    local timestamp=$(get_timestamp)
    
    cat << EOF
{
  "inventory_timestamp": "$timestamp",
  "system_info": $(get_system_info),
  "dotfiles": $(get_dotfiles_info),
  "homebrew": $(get_homebrew_packages),
  "mas_apps": $(get_mas_apps),
  "ruby_gems": $(get_ruby_gems),
  "python_packages": $(get_python_packages),
  "tool_versions": $(get_tool_versions),
  "setup_status": $(get_setup_status)
}
EOF
}

# Convert JSON to YAML format
json_to_yaml() {
    if command_exists yq; then
        yq eval -P
    elif command_exists python3; then
        python3 -c "import sys, json, yaml; yaml.dump(json.load(sys.stdin), sys.stdout, default_flow_style=False)"
    else
        echo "Error: YAML output requires yq or python3 with PyYAML"
        return 1
    fi
}

# Convert JSON to human-readable text
json_to_text() {
    local json_data="$1"
    
    echo "🖥️  SYSTEM INVENTORY REPORT"
    echo "=============================="
    echo ""
    
    echo "📅 Generated: $(echo "$json_data" | jq -r '.inventory_timestamp')"
    echo "🏷️  Hostname: $(echo "$json_data" | jq -r '.system_info.hostname')"
    echo "💻 OS: $(echo "$json_data" | jq -r '.system_info.os_version')"
    echo ""
    
    echo "📁 DOTFILES STATUS"
    echo "Repository: $(echo "$json_data" | jq -r '.dotfiles.repository_path')"
    echo "Branch: $(echo "$json_data" | jq -r '.dotfiles.git_branch')"
    echo "Commit: $(echo "$json_data" | jq -r '.dotfiles.git_hash' | cut -c1-8)"
    echo "Setup completed: $(echo "$json_data" | jq -r '.setup_status.setup_completed')"
    echo ""
    
    echo "🍺 HOMEBREW PACKAGES ($(echo "$json_data" | jq '.homebrew.formulas | length'))"
    echo "$json_data" | jq -r '.homebrew.formulas[].name' | sort | head -10
    if [ $(echo "$json_data" | jq '.homebrew.formulas | length') -gt 10 ]; then
        echo "... and $(( $(echo "$json_data" | jq '.homebrew.formulas | length') - 10 )) more"
    fi
    echo ""
    
    echo "📱 INSTALLED APPS ($(echo "$json_data" | jq '.homebrew.casks | length') casks + $(echo "$json_data" | jq '.mas_apps | length') MAS)"
    echo "$json_data" | jq -r '.homebrew.casks[].name' | sort | head -5
    echo "$json_data" | jq -r '.mas_apps[].name' | head -5
    echo ""
    
    echo "🔧 DEVELOPMENT TOOLS"
    echo "$json_data" | jq -r '.tool_versions | to_entries[] | "\(.key): \(.value)"' | head -8
    echo ""
}

# Main function
main() {
    local output_file="$HOME/.dotfiles_inventory.json"
    local format="json"
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --help|-h)
                show_help
                exit 0
                ;;
            --output)
                output_file="$2"
                shift 2
                ;;
            --format)
                format="$2"
                shift 2
                ;;
            *)
                echo "Unknown option: $1"
                echo "Use --help for usage information"
                exit 1
                ;;
        esac
    done
    
    # Validate format
    if [[ ! "$format" =~ ^(json|yaml|text)$ ]]; then
        echo "Error: Invalid format '$format'. Must be json, yaml, or text"
        exit 1
    fi
    
    echo "📋 Creating system inventory..."
    
    # Create JSON inventory
    local json_inventory=$(create_json_inventory)
    
    # Output in requested format
    case "$format" in
        json)
            if [ "$output_file" = "-" ]; then
                echo "$json_inventory" | jq .
            else
                echo "$json_inventory" | jq . > "$output_file"
                echo "✅ JSON inventory saved to: $output_file"
            fi
            ;;
        yaml)
            if [ "$output_file" = "-" ]; then
                echo "$json_inventory" | json_to_yaml
            else
                echo "$json_inventory" | json_to_yaml > "$output_file"
                echo "✅ YAML inventory saved to: $output_file"
            fi
            ;;
        text)
            if [ "$output_file" = "-" ]; then
                json_to_text "$json_inventory"
            else
                json_to_text "$json_inventory" > "$output_file"
                echo "✅ Text inventory saved to: $output_file"
            fi
            ;;
    esac
    
    echo ""
    echo "💡 Usage tips:"
    echo "   • Compare with: diff old_inventory.json new_inventory.json"
    echo "   • View packages: cat $output_file | jq '.homebrew.formulas[].name'"
    echo "   • Check versions: cat $output_file | jq '.tool_versions'"
}

# Execute main function with all arguments
main "$@"