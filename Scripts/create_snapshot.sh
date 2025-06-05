#!/bin/bash

set -euo pipefail

################################################################################
### System Snapshot Creation Tool
################################################################################

# Show help documentation
show_help() {
    cat << 'EOF'
📖 create_snapshot.sh - Create system state snapshots for rollback capability

DESCRIPTION:
    Creates comprehensive snapshots of system state including package lists,
    configurations, and dotfiles status for easy rollback if changes go wrong.

USAGE:
    create_snapshot.sh [SNAPSHOT_NAME] [OPTIONS]
    create_snapshot.sh --help

ARGUMENTS:
    SNAPSHOT_NAME         Optional name for the snapshot (default: auto-generated)

OPTIONS:
    --description TEXT    Description of the snapshot
    --include-files       Include backup of important config files
    --quick              Quick snapshot (packages only, no file backups)
    --help, -h           Show this help message

SNAPSHOT INCLUDES:
    • Homebrew package lists (formulas and casks)
    • Mac App Store applications
    • Ruby gems and Python packages
    • System information and versions
    • Dotfiles repository status
    • Symlink states
    • Configuration files (if --include-files)

STORAGE:
    Snapshots are stored in ~/.dotfiles_snapshots/
    Each snapshot gets a timestamped directory

EXAMPLES:
    create_snapshot.sh
    create_snapshot.sh "before_major_update"
    create_snapshot.sh "work_setup" --description "Corporate laptop setup"
    create_snapshot.sh --quick --description "Quick backup before test"

USE CASES:
    • Before major system updates
    • Prior to testing new configurations
    • Creating restore points for rollback
    • Documenting known-good system states

SEE ALSO:
    rollback.sh - Restore from snapshot
    list_snapshots.sh - View available snapshots

EOF
}

# Default configuration
SNAPSHOT_DIR="$HOME/.dotfiles_snapshots"
INCLUDE_FILES=false
QUICK_MODE=false
SNAPSHOT_NAME=""
DESCRIPTION=""

# Get timestamp for snapshot
get_timestamp() {
    date +%Y%m%d_%H%M%S
}

# Create snapshot directory structure
create_snapshot_dir() {
    local name="$1"
    local timestamp=$(get_timestamp)
    local snapshot_path="$SNAPSHOT_DIR/${name}_${timestamp}"
    
    mkdir -p "$snapshot_path"
    echo "$snapshot_path"
}

# Backup Homebrew state
backup_homebrew() {
    local snapshot_path="$1"
    
    echo "📦 Backing up Homebrew packages..."
    
    if command -v brew >/dev/null 2>&1; then
        brew list --formula > "$snapshot_path/homebrew_formulas.txt" 2>/dev/null || true
        brew list --cask > "$snapshot_path/homebrew_casks.txt" 2>/dev/null || true
        brew --version > "$snapshot_path/homebrew_version.txt" 2>/dev/null || true
        
        # Export detailed package info
        brew list --formula --json > "$snapshot_path/homebrew_formulas.json" 2>/dev/null || echo "[]" > "$snapshot_path/homebrew_formulas.json"
        brew list --cask --json > "$snapshot_path/homebrew_casks.json" 2>/dev/null || echo "[]" > "$snapshot_path/homebrew_casks.json"
        
        echo "✅ Homebrew packages backed up"
    else
        echo "⚠️  Homebrew not found, skipping package backup"
        touch "$snapshot_path/homebrew_not_installed.txt"
    fi
}

# Backup MAS applications
backup_mas_apps() {
    local snapshot_path="$1"
    
    echo "📱 Backing up Mac App Store applications..."
    
    if command -v mas >/dev/null 2>&1; then
        mas list > "$snapshot_path/mas_apps.txt" 2>/dev/null || true
        echo "✅ MAS apps backed up"
    else
        echo "⚠️  MAS not found, skipping App Store backup"
        touch "$snapshot_path/mas_not_installed.txt"
    fi
}

# Backup Ruby gems
backup_ruby_gems() {
    local snapshot_path="$1"
    
    echo "💎 Backing up Ruby gems..."
    
    if command -v gem >/dev/null 2>&1; then
        gem list > "$snapshot_path/ruby_gems.txt" 2>/dev/null || true
        gem list --json > "$snapshot_path/ruby_gems.json" 2>/dev/null || echo "[]" > "$snapshot_path/ruby_gems.json"
        ruby --version > "$snapshot_path/ruby_version.txt" 2>/dev/null || true
        
        if command -v rbenv >/dev/null 2>&1; then
            rbenv version > "$snapshot_path/rbenv_version.txt" 2>/dev/null || true
            rbenv versions > "$snapshot_path/rbenv_versions.txt" 2>/dev/null || true
        fi
        
        echo "✅ Ruby gems backed up"
    else
        echo "⚠️  Ruby not found, skipping gems backup"
        touch "$snapshot_path/ruby_not_installed.txt"
    fi
}

# Backup Python packages
backup_python_packages() {
    local snapshot_path="$1"
    
    echo "🐍 Backing up Python packages..."
    
    if command -v pip3 >/dev/null 2>&1; then
        pip3 list > "$snapshot_path/python_packages.txt" 2>/dev/null || true
        pip3 list --format=json > "$snapshot_path/python_packages.json" 2>/dev/null || echo "[]" > "$snapshot_path/python_packages.json"
        python3 --version > "$snapshot_path/python_version.txt" 2>/dev/null || true
        
        if command -v pyenv >/dev/null 2>&1; then
            pyenv version > "$snapshot_path/pyenv_version.txt" 2>/dev/null || true
            pyenv versions > "$snapshot_path/pyenv_versions.txt" 2>/dev/null || true
        fi
        
        echo "✅ Python packages backed up"
    else
        echo "⚠️  Python3 not found, skipping packages backup"
        touch "$snapshot_path/python_not_installed.txt"
    fi
}

# Backup system information
backup_system_info() {
    local snapshot_path="$1"
    
    echo "🖥️  Backing up system information..."
    
    # System info
    uname -a > "$snapshot_path/system_info.txt"
    hostname > "$snapshot_path/hostname.txt"
    
    # macOS specific info
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sw_vers > "$snapshot_path/macos_version.txt" 2>/dev/null || true
        system_profiler SPSoftwareDataType > "$snapshot_path/system_profile.txt" 2>/dev/null || true
    fi
    
    # Development tools
    {
        echo "=== Development Tools ==="
        for tool in git node npm yarn; do
            if command -v "$tool" >/dev/null 2>&1; then
                echo "$tool: $($tool --version 2>/dev/null | head -n1)"
            else
                echo "$tool: not installed"
            fi
        done
    } > "$snapshot_path/dev_tools.txt"
    
    echo "✅ System information backed up"
}

# Backup dotfiles state
backup_dotfiles_state() {
    local snapshot_path="$1"
    
    echo "📁 Backing up dotfiles state..."
    
    # Repository information
    local dotfiles_dir="${DOTFILES_DIR:-$HOME/.dotfiles}"
    if [ -d "$dotfiles_dir" ]; then
        {
            echo "Repository path: $dotfiles_dir"
            echo "Git branch: $(git -C "$dotfiles_dir" branch --show-current 2>/dev/null || echo 'unknown')"
            echo "Git commit: $(git -C "$dotfiles_dir" rev-parse HEAD 2>/dev/null || echo 'unknown')"
            echo "Git status:"
            git -C "$dotfiles_dir" status --porcelain 2>/dev/null || echo "Could not get git status"
        } > "$snapshot_path/dotfiles_repo.txt"
        
        # Last few commits
        git -C "$dotfiles_dir" log --oneline -10 > "$snapshot_path/dotfiles_commits.txt" 2>/dev/null || true
    else
        echo "Dotfiles directory not found: $dotfiles_dir" > "$snapshot_path/dotfiles_repo.txt"
    fi
    
    # Symlink status
    {
        echo "=== Dotfiles Symlinks ==="
        for file in .zshrc .aliases .exports .paths .gemrc .ruby-version; do
            if [ -L "$HOME/$file" ]; then
                echo "$file -> $(readlink "$HOME/$file")"
            elif [ -f "$HOME/$file" ]; then
                echo "$file (regular file, not symlinked)"
            else
                echo "$file (not found)"
            fi
        done
    } > "$snapshot_path/symlinks.txt"
    
    echo "✅ Dotfiles state backed up"
}

# Backup configuration files
backup_config_files() {
    local snapshot_path="$1"
    
    if [ "$INCLUDE_FILES" = false ]; then
        return
    fi
    
    echo "📄 Backing up configuration files..."
    
    local configs_dir="$snapshot_path/config_files"
    mkdir -p "$configs_dir"
    
    # List of important config files to backup
    local config_files=(
        ".zshrc"
        ".aliases" 
        ".exports"
        ".paths"
        ".gitconfig"
        ".ssh/config"
        ".dotfiles.config"
    )
    
    for config_file in "${config_files[@]}"; do
        local source_path="$HOME/$config_file"
        if [ -f "$source_path" ] || [ -L "$source_path" ]; then
            local dest_dir="$configs_dir/$(dirname "$config_file")"
            mkdir -p "$dest_dir"
            cp -L "$source_path" "$configs_dir/$config_file" 2>/dev/null || true
            echo "Backed up: $config_file"
        fi
    done
    
    echo "✅ Configuration files backed up"
}

# Create full system inventory
create_system_inventory() {
    local snapshot_path="$1"
    
    echo "📋 Creating system inventory..."
    
    # Use existing inventory tool if available
    local dotfiles_dir="${DOTFILES_DIR:-$HOME/.dotfiles}"
    if [ -f "$dotfiles_dir/Scripts/track_system_state.sh" ]; then
        "$dotfiles_dir/Scripts/track_system_state.sh" --output "$snapshot_path/system_inventory.json" 2>/dev/null || true
    fi
    
    echo "✅ System inventory created"
}

# Create snapshot metadata
create_metadata() {
    local snapshot_path="$1"
    local name="$2"
    
    cat > "$snapshot_path/snapshot_metadata.txt" << EOF
Snapshot Name: $name
Created: $(date -u +"%Y-%m-%d %H:%M:%S UTC")
Hostname: $(hostname)
User: $(whoami)
Description: $DESCRIPTION
Quick Mode: $QUICK_MODE
Include Files: $INCLUDE_FILES
Snapshot Path: $snapshot_path
EOF
    
    # Create JSON metadata for programmatic use
    cat > "$snapshot_path/metadata.json" << EOF
{
  "name": "$name",
  "created": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "hostname": "$(hostname)",
  "user": "$(whoami)",
  "description": "$DESCRIPTION",
  "quick_mode": $QUICK_MODE,
  "include_files": $INCLUDE_FILES,
  "snapshot_path": "$snapshot_path"
}
EOF
}

# Main snapshot creation function
create_snapshot() {
    local name="$1"
    
    echo "📸 Creating system snapshot: $name"
    echo "================================="
    echo ""
    
    # Create snapshot directory
    local snapshot_path=$(create_snapshot_dir "$name")
    echo "📁 Snapshot location: $snapshot_path"
    echo ""
    
    # Create metadata
    create_metadata "$snapshot_path" "$name"
    
    # Backup system state
    backup_system_info "$snapshot_path"
    backup_dotfiles_state "$snapshot_path"
    backup_homebrew "$snapshot_path"
    backup_mas_apps "$snapshot_path"
    
    if [ "$QUICK_MODE" = false ]; then
        backup_ruby_gems "$snapshot_path"
        backup_python_packages "$snapshot_path"
        create_system_inventory "$snapshot_path"
    fi
    
    backup_config_files "$snapshot_path"
    
    echo ""
    echo "✅ Snapshot created successfully!"
    echo "📁 Location: $snapshot_path"
    echo "📊 Use 'rollback.sh $(basename "$snapshot_path")' to restore"
    echo ""
    
    # Clean up old snapshots if needed
    cleanup_old_snapshots
    
    return 0
}

# Clean up old snapshots
cleanup_old_snapshots() {
    local retention_days=30
    
    # Load retention from config if available
    if [ -f "${DOTFILES_DIR:-$(pwd)}/.dotfiles.config" ]; then
        local config_retention=$(grep "^SNAPSHOT_RETENTION_DAYS=" "${DOTFILES_DIR:-$(pwd)}/.dotfiles.config" 2>/dev/null | cut -d'=' -f2 | tr -d '"' || true)
        if [ -n "$config_retention" ] && [ "$config_retention" -gt 0 ]; then
            retention_days="$config_retention"
        fi
    fi
    
    echo "🧹 Cleaning up snapshots older than $retention_days days..."
    
    if [ -d "$SNAPSHOT_DIR" ]; then
        find "$SNAPSHOT_DIR" -type d -name "*_*" -mtime +$retention_days -exec rm -rf {} + 2>/dev/null || true
    fi
}

# Parse command line arguments
main() {
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --help|-h)
                show_help
                exit 0
                ;;
            --description)
                DESCRIPTION="$2"
                shift 2
                ;;
            --include-files)
                INCLUDE_FILES=true
                shift
                ;;
            --quick)
                QUICK_MODE=true
                shift
                ;;
            -*)
                echo "Unknown option: $1"
                echo "Use --help for usage information"
                exit 1
                ;;
            *)
                if [ -z "$SNAPSHOT_NAME" ]; then
                    SNAPSHOT_NAME="$1"
                else
                    echo "Unexpected argument: $1"
                    echo "Use --help for usage information"
                    exit 1
                fi
                shift
                ;;
        esac
    done
    
    # Generate snapshot name if not provided
    if [ -z "$SNAPSHOT_NAME" ]; then
        SNAPSHOT_NAME="auto_snapshot"
    fi
    
    # Create the snapshot
    create_snapshot "$SNAPSHOT_NAME"
}

# Execute main function with all arguments
main "$@"