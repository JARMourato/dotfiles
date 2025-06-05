#!/bin/bash

set -euo pipefail

################################################################################
### System Rollback Tool
################################################################################

# Show help documentation
show_help() {
    cat << 'EOF'
📖 rollback.sh - Restore system state from snapshots

DESCRIPTION:
    Rolls back system state to a previous snapshot, undoing package installations,
    configuration changes, and restoring previous system state.

USAGE:
    rollback.sh <snapshot_name> [OPTIONS]
    rollback.sh --list
    rollback.sh --help

ARGUMENTS:
    snapshot_name         Name or path of snapshot to restore from

OPTIONS:
    --packages-only       Only rollback package installations
    --configs-only        Only rollback configuration files  
    --dotfiles-only       Only rollback dotfiles repository state
    --dry-run             Show what would be rolled back without doing it
    --force               Skip confirmation prompts
    --list                List available snapshots
    --help, -h            Show this help message

ROLLBACK INCLUDES:
    • Uninstall packages not in snapshot
    • Install packages that were in snapshot
    • Restore configuration files (if available)
    • Reset dotfiles repository state
    • Restore symlinks

SAFETY FEATURES:
    • Confirmation prompts before destructive operations
    • Dry-run mode to preview changes
    • Selective rollback options
    • Creates pre-rollback snapshot automatically

EXAMPLES:
    # List available snapshots
    rollback.sh --list
    
    # Full rollback with confirmation
    rollback.sh "before_major_update_20241206_143022"
    
    # Rollback packages only
    rollback.sh "work_setup_20241205_091500" --packages-only
    
    # Preview what would be rolled back
    rollback.sh "auto_snapshot_20241204_160000" --dry-run
    
    # Force rollback without prompts
    rollback.sh "known_good_state" --force

WARNINGS:
    • Rollback operations can remove packages and configurations
    • Always create a snapshot before rollback for safety
    • Test rollbacks in non-production environments first
    • Some system changes cannot be automatically rolled back

SEE ALSO:
    create_snapshot.sh - Create snapshots for rollback
    list_snapshots.sh - View available snapshots

EOF
}

# Default configuration
SNAPSHOT_DIR="$HOME/.dotfiles_snapshots"
PACKAGES_ONLY=false
CONFIGS_ONLY=false
DOTFILES_ONLY=false
DRY_RUN=false
FORCE=false
LIST_SNAPSHOTS=false

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Find snapshot directory
find_snapshot() {
    local name="$1"
    
    # If it's already a full path, use it
    if [ -d "$name" ]; then
        echo "$name"
        return 0
    fi
    
    # Look for exact match
    if [ -d "$SNAPSHOT_DIR/$name" ]; then
        echo "$SNAPSHOT_DIR/$name"
        return 0
    fi
    
    # Look for partial match (most recent if multiple)
    local matches=$(find "$SNAPSHOT_DIR" -type d -name "*${name}*" 2>/dev/null | sort | tail -1)
    if [ -n "$matches" ]; then
        echo "$matches"
        return 0
    fi
    
    return 1
}

# List available snapshots
list_snapshots() {
    echo "📋 Available Snapshots"
    echo "======================"
    echo ""
    
    if [ ! -d "$SNAPSHOT_DIR" ]; then
        echo "No snapshots directory found: $SNAPSHOT_DIR"
        return 0
    fi
    
    local snapshots=$(find "$SNAPSHOT_DIR" -maxdepth 1 -type d -name "*_*" | sort -r)
    
    if [ -z "$snapshots" ]; then
        echo "No snapshots found in $SNAPSHOT_DIR"
        return 0
    fi
    
    printf "%-40s %-20s %s\n" "Snapshot Name" "Created" "Description"
    printf "%-40s %-20s %s\n" "-------------" "-------" "-----------"
    
    while IFS= read -r snapshot_path; do
        local snapshot_name=$(basename "$snapshot_path")
        local created="unknown"
        local description="none"
        
        # Try to read metadata
        if [ -f "$snapshot_path/metadata.json" ]; then
            created=$(jq -r '.created // "unknown"' "$snapshot_path/metadata.json" 2>/dev/null | cut -d'T' -f1)
            description=$(jq -r '.description // "none"' "$snapshot_path/metadata.json" 2>/dev/null)
        elif [ -f "$snapshot_path/snapshot_metadata.txt" ]; then
            created=$(grep "^Created:" "$snapshot_path/snapshot_metadata.txt" 2>/dev/null | cut -d' ' -f2 || echo "unknown")
            description=$(grep "^Description:" "$snapshot_path/snapshot_metadata.txt" 2>/dev/null | cut -d' ' -f2- || echo "none")
        fi
        
        printf "%-40s %-20s %s\n" "$snapshot_name" "$created" "$description"
    done <<< "$snapshots"
    
    echo ""
    echo "💡 Use: rollback.sh <snapshot_name> to restore"
}

# Validate snapshot
validate_snapshot() {
    local snapshot_path="$1"
    
    if [ ! -d "$snapshot_path" ]; then
        echo "❌ Snapshot directory not found: $snapshot_path"
        return 1
    fi
    
    # Check for required files
    local required_files=("snapshot_metadata.txt")
    for file in "${required_files[@]}"; do
        if [ ! -f "$snapshot_path/$file" ]; then
            echo "⚠️  Warning: Missing snapshot file: $file"
        fi
    done
    
    return 0
}

# Show rollback preview
show_rollback_preview() {
    local snapshot_path="$1"
    
    echo "🔍 Rollback Preview"
    echo "==================="
    echo ""
    
    echo "📁 Snapshot: $(basename "$snapshot_path")"
    if [ -f "$snapshot_path/metadata.json" ]; then
        local created=$(jq -r '.created' "$snapshot_path/metadata.json" 2>/dev/null)
        local description=$(jq -r '.description' "$snapshot_path/metadata.json" 2>/dev/null)
        echo "📅 Created: $created"
        echo "📝 Description: $description"
    fi
    echo ""
    
    # Show package differences
    if [ -f "$snapshot_path/homebrew_formulas.txt" ] && command_exists brew; then
        echo "📦 HOMEBREW FORMULAS:"
        local current_formulas=$(brew list --formula 2>/dev/null | sort)
        local snapshot_formulas=$(cat "$snapshot_path/homebrew_formulas.txt" | sort)
        
        local to_install=$(comm -23 <(echo "$snapshot_formulas") <(echo "$current_formulas") || true)
        local to_remove=$(comm -13 <(echo "$snapshot_formulas") <(echo "$current_formulas") || true)
        
        if [ -n "$to_install" ]; then
            echo "➕ To install:"
            echo "$to_install" | head -10
            local install_count=$(echo "$to_install" | wc -l | tr -d ' ')
            if [ "$install_count" -gt 10 ]; then
                echo "... and $(($install_count - 10)) more"
            fi
        fi
        
        if [ -n "$to_remove" ]; then
            echo "❌ To remove:"
            echo "$to_remove" | head -10
            local remove_count=$(echo "$to_remove" | wc -l | tr -d ' ')
            if [ "$remove_count" -gt 10 ]; then
                echo "... and $(($remove_count - 10)) more"
            fi
        fi
        
        if [ -z "$to_install" ] && [ -z "$to_remove" ]; then
            echo "✅ No changes needed"
        fi
    fi
    
    echo ""
    
    # Show cask differences
    if [ -f "$snapshot_path/homebrew_casks.txt" ] && command_exists brew; then
        echo "📱 HOMEBREW CASKS:"
        local current_casks=$(brew list --cask 2>/dev/null | sort)
        local snapshot_casks=$(cat "$snapshot_path/homebrew_casks.txt" | sort)
        
        local casks_to_install=$(comm -23 <(echo "$snapshot_casks") <(echo "$current_casks") || true)
        local casks_to_remove=$(comm -13 <(echo "$snapshot_casks") <(echo "$current_casks") || true)
        
        if [ -n "$casks_to_install" ]; then
            echo "➕ To install: $(echo "$casks_to_install" | wc -l | tr -d ' ') casks"
        fi
        
        if [ -n "$casks_to_remove" ]; then
            echo "❌ To remove: $(echo "$casks_to_remove" | wc -l | tr -d ' ') casks"
        fi
        
        if [ -z "$casks_to_install" ] && [ -z "$casks_to_remove" ]; then
            echo "✅ No changes needed"
        fi
    fi
    
    echo ""
}

# Rollback Homebrew packages
rollback_homebrew() {
    local snapshot_path="$1"
    
    if [ "$CONFIGS_ONLY" = true ] || [ "$DOTFILES_ONLY" = true ]; then
        return 0
    fi
    
    echo "🍺 Rolling back Homebrew packages..."
    
    if ! command_exists brew; then
        echo "⚠️  Homebrew not installed, skipping package rollback"
        return 0
    fi
    
    # Rollback formulas
    if [ -f "$snapshot_path/homebrew_formulas.txt" ]; then
        local current_formulas=$(brew list --formula 2>/dev/null | sort)
        local snapshot_formulas=$(cat "$snapshot_path/homebrew_formulas.txt" | sort)
        
        # Remove packages not in snapshot
        local to_remove=$(comm -13 <(echo "$snapshot_formulas") <(echo "$current_formulas") || true)
        if [ -n "$to_remove" ]; then
            echo "❌ Removing formulas not in snapshot..."
            if [ "$DRY_RUN" = true ]; then
                echo "DRY RUN: Would remove: $to_remove"
            else
                echo "$to_remove" | xargs brew uninstall --ignore-dependencies 2>/dev/null || true
            fi
        fi
        
        # Install packages from snapshot
        local to_install=$(comm -23 <(echo "$snapshot_formulas") <(echo "$current_formulas") || true)
        if [ -n "$to_install" ]; then
            echo "➕ Installing formulas from snapshot..."
            if [ "$DRY_RUN" = true ]; then
                echo "DRY RUN: Would install: $to_install"
            else
                echo "$to_install" | xargs brew install 2>/dev/null || true
            fi
        fi
    fi
    
    # Rollback casks
    if [ -f "$snapshot_path/homebrew_casks.txt" ]; then
        local current_casks=$(brew list --cask 2>/dev/null | sort)
        local snapshot_casks=$(cat "$snapshot_path/homebrew_casks.txt" | sort)
        
        # Remove casks not in snapshot
        local casks_to_remove=$(comm -13 <(echo "$snapshot_casks") <(echo "$current_casks") || true)
        if [ -n "$casks_to_remove" ]; then
            echo "❌ Removing casks not in snapshot..."
            if [ "$DRY_RUN" = true ]; then
                echo "DRY RUN: Would remove casks: $casks_to_remove"
            else
                echo "$casks_to_remove" | xargs brew uninstall --cask 2>/dev/null || true
            fi
        fi
        
        # Install casks from snapshot
        local casks_to_install=$(comm -23 <(echo "$snapshot_casks") <(echo "$current_casks") || true)
        if [ -n "$casks_to_install" ]; then
            echo "➕ Installing casks from snapshot..."
            if [ "$DRY_RUN" = true ]; then
                echo "DRY RUN: Would install casks: $casks_to_install"
            else
                echo "$casks_to_install" | xargs brew install --cask 2>/dev/null || true
            fi
        fi
    fi
    
    echo "✅ Homebrew rollback completed"
}

# Rollback configuration files
rollback_configs() {
    local snapshot_path="$1"
    
    if [ "$PACKAGES_ONLY" = true ] || [ "$DOTFILES_ONLY" = true ]; then
        return 0
    fi
    
    local configs_dir="$snapshot_path/config_files"
    if [ ! -d "$configs_dir" ]; then
        echo "⚠️  No configuration files in snapshot, skipping config rollback"
        return 0
    fi
    
    echo "📄 Rolling back configuration files..."
    
    # Restore backed up config files
    find "$configs_dir" -type f | while read -r config_file; do
        local relative_path="${config_file#$configs_dir/}"
        local target_path="$HOME/$relative_path"
        
        if [ "$DRY_RUN" = true ]; then
            echo "DRY RUN: Would restore: $relative_path"
        else
            local target_dir=$(dirname "$target_path")
            mkdir -p "$target_dir"
            cp "$config_file" "$target_path"
            echo "Restored: $relative_path"
        fi
    done
    
    echo "✅ Configuration files rollback completed"
}

# Rollback dotfiles repository
rollback_dotfiles() {
    local snapshot_path="$1"
    
    if [ "$PACKAGES_ONLY" = true ] || [ "$CONFIGS_ONLY" = true ]; then
        return 0
    fi
    
    echo "📁 Rolling back dotfiles repository..."
    
    local dotfiles_dir="${DOTFILES_DIR:-$HOME/.dotfiles}"
    if [ ! -d "$dotfiles_dir/.git" ]; then
        echo "⚠️  Dotfiles repository not found, skipping dotfiles rollback"
        return 0
    fi
    
    if [ -f "$snapshot_path/dotfiles_repo.txt" ]; then
        local snapshot_commit=$(grep "^Git commit:" "$snapshot_path/dotfiles_repo.txt" | cut -d' ' -f3)
        
        if [ -n "$snapshot_commit" ] && [ "$snapshot_commit" != "unknown" ]; then
            echo "🔄 Resetting to commit: $snapshot_commit"
            if [ "$DRY_RUN" = true ]; then
                echo "DRY RUN: Would reset to commit $snapshot_commit"
            else
                git -C "$dotfiles_dir" reset --hard "$snapshot_commit" 2>/dev/null || true
            fi
        fi
    fi
    
    echo "✅ Dotfiles repository rollback completed"
}

# Create pre-rollback snapshot
create_pre_rollback_snapshot() {
    local snapshot_name="$1"
    
    echo "📸 Creating pre-rollback snapshot for safety..."
    
    local dotfiles_dir="${DOTFILES_DIR:-$HOME/.dotfiles}"
    if [ -f "$dotfiles_dir/Scripts/create_snapshot.sh" ]; then
        if [ "$DRY_RUN" = true ]; then
            echo "DRY RUN: Would create snapshot 'before_rollback_to_$snapshot_name'"
        else
            "$dotfiles_dir/Scripts/create_snapshot.sh" "before_rollback_to_$snapshot_name" --quick --description "Auto-created before rollback to $snapshot_name" >/dev/null 2>&1 || true
        fi
    fi
}

# Main rollback function
perform_rollback() {
    local snapshot_name="$1"
    
    echo "🔄 Starting rollback to: $snapshot_name"
    echo "======================================="
    echo ""
    
    # Find snapshot
    local snapshot_path
    if ! snapshot_path=$(find_snapshot "$snapshot_name"); then
        echo "❌ Snapshot not found: $snapshot_name"
        echo "Use --list to see available snapshots"
        exit 1
    fi
    
    # Validate snapshot
    if ! validate_snapshot "$snapshot_path"; then
        echo "❌ Invalid snapshot: $snapshot_path"
        exit 1
    fi
    
    # Show preview
    show_rollback_preview "$snapshot_path"
    
    # Confirmation
    if [ "$FORCE" = false ] && [ "$DRY_RUN" = false ]; then
        echo ""
        echo "⚠️  This will modify your system to match the snapshot state."
        echo "   Packages may be installed or removed."
        echo "   Configuration files may be overwritten."
        echo ""
        read -p "Do you want to continue? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "❌ Rollback cancelled"
            exit 0
        fi
    fi
    
    # Create safety snapshot
    create_pre_rollback_snapshot "$(basename "$snapshot_path")"
    
    # Perform rollback
    rollback_homebrew "$snapshot_path"
    rollback_configs "$snapshot_path"
    rollback_dotfiles "$snapshot_path"
    
    echo ""
    if [ "$DRY_RUN" = true ]; then
        echo "🔍 DRY RUN COMPLETED - No actual changes were made"
    else
        echo "✅ Rollback completed successfully!"
        echo "📁 Restored from: $snapshot_path"
        echo "🔄 System state has been rolled back"
    fi
    echo ""
}

# Parse command line arguments
main() {
    local snapshot_name=""
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --help|-h)
                show_help
                exit 0
                ;;
            --list)
                LIST_SNAPSHOTS=true
                shift
                ;;
            --packages-only)
                PACKAGES_ONLY=true
                shift
                ;;
            --configs-only)
                CONFIGS_ONLY=true
                shift
                ;;
            --dotfiles-only)
                DOTFILES_ONLY=true
                shift
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --force)
                FORCE=true
                shift
                ;;
            -*)
                echo "Unknown option: $1"
                echo "Use --help for usage information"
                exit 1
                ;;
            *)
                if [ -z "$snapshot_name" ]; then
                    snapshot_name="$1"
                else
                    echo "Unexpected argument: $1"
                    echo "Use --help for usage information"
                    exit 1
                fi
                shift
                ;;
        esac
    done
    
    # Handle list option
    if [ "$LIST_SNAPSHOTS" = true ]; then
        list_snapshots
        exit 0
    fi
    
    # Check for required snapshot name
    if [ -z "$snapshot_name" ]; then
        echo "❌ Error: Snapshot name required"
        echo "Use --list to see available snapshots"
        echo "Use --help for usage information"
        exit 1
    fi
    
    # Perform rollback
    perform_rollback "$snapshot_name"
}

# Execute main function with all arguments
main "$@"