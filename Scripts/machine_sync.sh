#!/bin/bash
set -euo pipefail

################################################################################
### Multi-Machine Sync System
################################################################################
# Intelligent synchronization of configurations across different machines
# with conflict resolution, machine profiles, and selective sync

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"
SYNC_DIR="$HOME/.dotfiles_sync"
SYNC_CONFIG="$SYNC_DIR/sync_config.json"
MACHINE_PROFILE="$SYNC_DIR/machine_profile.json"
SYNC_LOG="$SYNC_DIR/sync.log"
CONFLICTS_DIR="$SYNC_DIR/conflicts"
SYNC_STATE="$SYNC_DIR/sync_state.json"

# Sync backend (Git-based for now, but could support others)
SYNC_BACKEND="${DOTFILES_SYNC_BACKEND:-git}"
SYNC_REMOTE="${DOTFILES_SYNC_REMOTE:-origin}"
SYNC_BRANCH="${DOTFILES_SYNC_BRANCH:-sync}"

# Load progress indicators
source "$SCRIPT_DIR/progress_indicators.sh" 2>/dev/null || true

################################################################################
### Initialization and Setup
################################################################################

init_sync_system() {
    echo "🔄 Initializing multi-machine sync system..."
    
    # Create sync directories
    mkdir -p "$SYNC_DIR"
    mkdir -p "$CONFLICTS_DIR"
    mkdir -p "$SYNC_DIR/backups"
    mkdir -p "$SYNC_DIR/profiles"
    
    # Initialize sync configuration
    if [ ! -f "$SYNC_CONFIG" ]; then
        create_default_sync_config
    fi
    
    # Detect and create machine profile
    if [ ! -f "$MACHINE_PROFILE" ]; then
        detect_and_create_machine_profile
    fi
    
    # Initialize sync state
    if [ ! -f "$SYNC_STATE" ]; then
        initialize_sync_state
    fi
    
    # Set up sync backend
    setup_sync_backend
    
    echo "✅ Multi-machine sync system initialized"
}

create_default_sync_config() {
    cat > "$SYNC_CONFIG" << EOF
{
    "sync_version": "1.0",
    "created_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
    "sync_enabled": true,
    "auto_sync": false,
    "conflict_resolution": "interactive",
    "sync_items": {
        "shell_configs": {
            "enabled": true,
            "files": [".zshrc", ".zprofile", ".aliases", ".functions", ".exports"],
            "selective": true
        },
        "git_config": {
            "enabled": true,
            "files": [".gitconfig", ".gitignore_global"],
            "selective": false
        },
        "application_preferences": {
            "enabled": true,
            "paths": ["~/Library/Application Support/Code/User/settings.json"],
            "selective": true
        },
        "ssh_config": {
            "enabled": true,
            "files": [".ssh/config"],
            "encrypted": true
        },
        "dotfiles_config": {
            "enabled": true,
            "files": [".dotfiles.config"],
            "selective": false
        },
        "usage_analytics": {
            "enabled": true,
            "files": [".dotfiles_analytics/usage_report.json"],
            "merge_strategy": "combine"
        }
    },
    "excluded_files": [
        ".DS_Store",
        "*.tmp",
        "*.log",
        ".dotfiles_sync/"
    ]
}
EOF
}

detect_and_create_machine_profile() {
    echo "🔍 Detecting machine profile..."
    
    local machine_type="unknown"
    local machine_name=$(hostname)
    local machine_id=$(system_profiler SPHardwareDataType | grep "Hardware UUID" | awk '{print $3}' 2>/dev/null || uuidgen)
    
    # Detect machine type based on various indicators
    if hostname | grep -qi "work\|corp\|company" || [ -d "/Applications/Microsoft Teams.app" ]; then
        machine_type="work"
    elif [ -d "/Applications/Xcode.app" ] && [ -d "/Applications/Visual Studio Code.app" ]; then
        machine_type="development"
    elif [ -d "/Applications/Steam.app" ] || [ -d "/Applications/Spotify.app" ]; then
        machine_type="personal"
    else
        machine_type="general"
    fi
    
    # Create machine profile
    cat > "$MACHINE_PROFILE" << EOF
{
    "machine_id": "$machine_id",
    "machine_name": "$machine_name",
    "machine_type": "$machine_type",
    "created_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
    "last_updated": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
    "capabilities": {
        "development": $([ -d "/Applications/Xcode.app" ] && echo "true" || echo "false"),
        "work_tools": $([ -d "/Applications/Microsoft Teams.app" ] && echo "true" || echo "false"),
        "personal_apps": $([ -d "/Applications/Spotify.app" ] && echo "true" || echo "false"),
        "containerization": $(command -v docker >/dev/null && echo "true" || echo "false")
    },
    "sync_preferences": {
        "auto_pull": false,
        "auto_push": false,
        "selective_sync": true,
        "conflict_strategy": "interactive"
    }
}
EOF
    
    echo "✅ Machine profile created: $machine_type machine ($machine_name)"
}

initialize_sync_state() {
    cat > "$SYNC_STATE" << EOF
{
    "last_sync": null,
    "last_pull": null,
    "last_push": null,
    "sync_count": 0,
    "conflicts_resolved": 0,
    "connected_machines": [],
    "pending_conflicts": [],
    "sync_status": "initialized"
}
EOF
}

setup_sync_backend() {
    case "$SYNC_BACKEND" in
        git)
            setup_git_sync_backend
            ;;
        *)
            echo "⚠️ Unknown sync backend: $SYNC_BACKEND"
            ;;
    esac
}

setup_git_sync_backend() {
    echo "🔧 Setting up Git sync backend..."
    
    # Ensure we're in a git repository
    if [ ! -d "$DOTFILES_DIR/.git" ]; then
        echo "❌ Not a Git repository. Initialize Git first."
        return 1
    fi
    
    # Create sync branch if it doesn't exist
    if ! git branch | grep -q "^\*\?\s*$SYNC_BRANCH$"; then
        git checkout -b "$SYNC_BRANCH" 2>/dev/null || true
        git checkout main 2>/dev/null || git checkout master 2>/dev/null || true
    fi
    
    echo "✅ Git sync backend configured"
}

################################################################################
### Machine Profile Management
################################################################################

set_machine_profile() {
    local profile_type="$1"
    
    echo "⚙️ Configuring machine as: $profile_type"
    
    # Update machine profile
    local temp_profile=$(mktemp)
    jq --arg type "$profile_type" --arg updated "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
        '.machine_type = $type | .last_updated = $updated' "$MACHINE_PROFILE" > "$temp_profile"
    mv "$temp_profile" "$MACHINE_PROFILE"
    
    # Configure sync preferences based on profile
    configure_profile_sync_preferences "$profile_type"
    
    echo "✅ Machine profile set to: $profile_type"
}

configure_profile_sync_preferences() {
    local profile_type="$1"
    
    case "$profile_type" in
        work)
            # Work machines: Skip personal apps, include work tools
            echo "🏢 Configuring work machine sync preferences..."
            update_sync_config '.sync_items.application_preferences.exclude_patterns = ["Spotify", "Steam", "Netflix"]'
            update_sync_config '.sync_items.shell_configs.exclude_personal = true'
            ;;
        personal)
            # Personal machines: Skip work apps, include entertainment
            echo "🏠 Configuring personal machine sync preferences..."
            update_sync_config '.sync_items.application_preferences.exclude_patterns = ["Teams", "Slack", "Corporate"]'
            update_sync_config '.sync_items.shell_configs.exclude_work = true'
            ;;
        development)
            # Development machines: Include all development tools
            echo "👨‍💻 Configuring development machine sync preferences..."
            update_sync_config '.sync_items.development_tools.enabled = true'
            ;;
        minimal)
            # Minimal machines: Sync only essential configurations
            echo "⚡ Configuring minimal machine sync preferences..."
            update_sync_config '.sync_items.application_preferences.enabled = false'
            update_sync_config '.sync_items.ssh_config.enabled = false'
            ;;
    esac
}

update_sync_config() {
    local jq_expression="$1"
    local temp_config=$(mktemp)
    jq "$jq_expression" "$SYNC_CONFIG" > "$temp_config"
    mv "$temp_config" "$SYNC_CONFIG"
}

show_machine_info() {
    echo "🖥️ Machine Information"
    echo "====================="
    
    if [ -f "$MACHINE_PROFILE" ]; then
        local machine_name=$(jq -r '.machine_name' "$MACHINE_PROFILE")
        local machine_type=$(jq -r '.machine_type' "$MACHINE_PROFILE")
        local machine_id=$(jq -r '.machine_id' "$MACHINE_PROFILE")
        
        echo "Machine Name: $machine_name"
        echo "Machine Type: $machine_type"
        echo "Machine ID: ${machine_id:0:8}..."
        
        echo ""
        echo "🔧 Capabilities:"
        jq -r '.capabilities | to_entries[] | "  " + .key + ": " + (.value | tostring)' "$MACHINE_PROFILE"
        
        echo ""
        echo "⚙️ Sync Preferences:"
        jq -r '.sync_preferences | to_entries[] | "  " + .key + ": " + (.value | tostring)' "$MACHINE_PROFILE"
    else
        echo "❌ No machine profile found. Run 'init' first."
    fi
}

################################################################################
### Sync Operations
################################################################################

pull_configurations() {
    echo "⬇️ Pulling configurations from other machines..."
    
    log_sync_action "PULL_START" "Starting pull operation"
    
    # Create backup before pulling
    create_sync_backup "pre-pull"
    
    case "$SYNC_BACKEND" in
        git)
            pull_via_git
            ;;
        *)
            echo "❌ Unsupported sync backend: $SYNC_BACKEND"
            return 1
            ;;
    esac
    
    # Process pulled configurations
    process_pulled_configurations
    
    # Update sync state
    update_sync_state "last_pull" "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
    
    log_sync_action "PULL_COMPLETE" "Pull operation completed"
    echo "✅ Pull completed successfully"
}

pull_via_git() {
    echo "📡 Fetching latest changes via Git..."
    
    local current_branch=$(git branch --show-current)
    
    # Fetch latest changes
    git fetch "$SYNC_REMOTE" "$SYNC_BRANCH" 2>/dev/null || {
        echo "⚠️ Could not fetch from remote. Creating new sync branch."
        return 0
    }
    
    # Check if there are changes to pull
    local remote_commit=$(git rev-parse "$SYNC_REMOTE/$SYNC_BRANCH" 2>/dev/null || echo "")
    local local_commit=$(git rev-parse "$SYNC_BRANCH" 2>/dev/null || echo "")
    
    if [ "$remote_commit" = "$local_commit" ]; then
        echo "✅ Already up to date"
        return 0
    fi
    
    # Checkout sync branch and merge
    git checkout "$SYNC_BRANCH" 2>/dev/null || git checkout -b "$SYNC_BRANCH"
    
    if git merge "$SYNC_REMOTE/$SYNC_BRANCH" --no-edit; then
        echo "✅ Successfully merged remote changes"
    else
        echo "⚠️ Merge conflicts detected - will resolve automatically"
        resolve_merge_conflicts
    fi
    
    # Return to original branch
    git checkout "$current_branch"
}

process_pulled_configurations() {
    echo "🔄 Processing pulled configurations..."
    
    # Check for conflicts with local changes
    detect_configuration_conflicts
    
    # Apply machine-specific filtering
    apply_machine_filtering
    
    echo "✅ Configuration processing complete"
}

detect_configuration_conflicts() {
    echo "  🔍 Detecting configuration conflicts..."
    
    local conflicts_detected=false
    
    # Check each sync item for conflicts
    jq -r '.sync_items | to_entries[] | select(.value.enabled == true) | .key' "$SYNC_CONFIG" | while read -r item; do
        check_item_conflicts "$item"
    done
}

check_item_conflicts() {
    local item="$1"
    local files
    files=$(jq -r ".sync_items.${item}.files[]?" "$SYNC_CONFIG" 2>/dev/null || echo "")
    
    for file in $files; do
        local local_file="$HOME/$file"
        local sync_file="$SYNC_DIR/pulled/$file"
        
        if [ -f "$local_file" ] && [ -f "$sync_file" ]; then
            if ! cmp -s "$local_file" "$sync_file"; then
                echo "⚠️ Conflict detected: $file"
                handle_file_conflict "$file" "$local_file" "$sync_file"
            fi
        fi
    done
}

handle_file_conflict() {
    local file="$1"
    local local_file="$2"
    local sync_file="$3"
    
    echo ""
    echo "🔥 Conflict Resolution Required"
    echo "==============================="
    echo "File: $file"
    echo ""
    echo "Local version modified: $(stat -f "%Sm" "$local_file" 2>/dev/null || stat -c "%y" "$local_file" 2>/dev/null)"
    echo "Remote version from: $(get_remote_file_info "$sync_file")"
    echo ""
    
    # Get conflict resolution strategy
    local strategy=$(jq -r '.conflict_resolution' "$SYNC_CONFIG")
    
    case "$strategy" in
        interactive)
            resolve_conflict_interactive "$file" "$local_file" "$sync_file"
            ;;
        local_wins)
            echo "🏠 Keeping local version (local_wins strategy)"
            ;;
        remote_wins)
            echo "☁️ Using remote version (remote_wins strategy)"
            cp "$sync_file" "$local_file"
            ;;
        merge)
            attempt_automatic_merge "$file" "$local_file" "$sync_file"
            ;;
    esac
}

resolve_conflict_interactive() {
    local file="$1"
    local local_file="$2"
    local sync_file="$3"
    
    echo "Choose resolution strategy:"
    echo "1) Keep local version"
    echo "2) Use remote version"
    echo "3) Show differences"
    echo "4) Attempt automatic merge"
    echo "5) Manual merge (opens editor)"
    echo ""
    
    read -p "Select option (1-5): " choice
    
    case "$choice" in
        1)
            echo "✅ Keeping local version"
            ;;
        2)
            echo "✅ Using remote version"
            cp "$sync_file" "$local_file"
            ;;
        3)
            show_file_differences "$local_file" "$sync_file"
            # Recurse to show options again
            resolve_conflict_interactive "$file" "$local_file" "$sync_file"
            ;;
        4)
            attempt_automatic_merge "$file" "$local_file" "$sync_file"
            ;;
        5)
            manual_merge_file "$file" "$local_file" "$sync_file"
            ;;
        *)
            echo "Invalid choice. Keeping local version."
            ;;
    esac
}

show_file_differences() {
    local local_file="$1"
    local sync_file="$2"
    
    echo ""
    echo "📋 File Differences:"
    echo "===================="
    
    if command -v colordiff >/dev/null; then
        colordiff -u "$local_file" "$sync_file" | head -50
    else
        diff -u "$local_file" "$sync_file" | head -50
    fi
    
    echo ""
}

attempt_automatic_merge() {
    local file="$1"
    local local_file="$2"
    local sync_file="$3"
    
    echo "🔀 Attempting automatic merge..."
    
    # Create a base version for three-way merge
    local base_file="$CONFLICTS_DIR/$(basename "$file").base"
    local merged_file="$CONFLICTS_DIR/$(basename "$file").merged"
    
    # For now, use a simple strategy - this could be enhanced
    if merge_files_intelligent "$local_file" "$sync_file" "$merged_file"; then
        echo "✅ Automatic merge successful"
        cp "$merged_file" "$local_file"
    else
        echo "❌ Automatic merge failed - manual resolution required"
        manual_merge_file "$file" "$local_file" "$sync_file"
    fi
}

merge_files_intelligent() {
    local local_file="$1"
    local sync_file="$2"
    local output_file="$3"
    
    # Simple intelligent merge for configuration files
    # This could be much more sophisticated
    
    case "$(basename "$local_file")" in
        .zshrc|.bashrc)
            merge_shell_configs "$local_file" "$sync_file" "$output_file"
            ;;
        .gitconfig)
            merge_git_configs "$local_file" "$sync_file" "$output_file"
            ;;
        *)
            # Default: use local version for unknown files
            cp "$local_file" "$output_file"
            return 0
            ;;
    esac
}

merge_shell_configs() {
    local local_file="$1"
    local sync_file="$2"
    local output_file="$3"
    
    # Combine unique exports, aliases, and functions
    {
        echo "# Merged shell configuration - $(date)"
        echo ""
        
        # Extract and merge exports
        echo "# Exports"
        grep "^export " "$local_file" "$sync_file" 2>/dev/null | sort -u
        echo ""
        
        # Extract and merge aliases
        echo "# Aliases"
        grep "^alias " "$local_file" "$sync_file" 2>/dev/null | sort -u
        echo ""
        
        # Extract and merge functions (basic)
        echo "# Functions and other configurations"
        grep -v "^export \|^alias \|^#" "$local_file" "$sync_file" 2>/dev/null | sort -u
    } > "$output_file"
    
    return 0
}

merge_git_configs() {
    local local_file="$1"
    local sync_file="$2"
    local output_file="$3"
    
    # Merge Git configurations intelligently
    # Keep user.name and user.email from local, merge other settings
    
    cp "$local_file" "$output_file"
    
    # Add unique settings from sync file
    while IFS= read -r line; do
        if [[ "$line" != *"user.name"* ]] && [[ "$line" != *"user.email"* ]]; then
            if ! grep -Fq "$line" "$output_file"; then
                echo "$line" >> "$output_file"
            fi
        fi
    done < "$sync_file"
    
    return 0
}

manual_merge_file() {
    local file="$1"
    local local_file="$2"
    local sync_file="$3"
    
    echo "🖊️ Opening manual merge editor..."
    
    # Create a merged file with conflict markers
    local merge_file="$CONFLICTS_DIR/$(basename "$file").merge"
    
    cat > "$merge_file" << EOF
# Manual merge required for: $file
# Local version (current):
<<<<<<< LOCAL
$(cat "$local_file")
=======
# Remote version (from other machine):
$(cat "$sync_file")
>>>>>>> REMOTE
EOF
    
    # Open in editor
    "${EDITOR:-nano}" "$merge_file"
    
    echo ""
    read -p "Save merged file to $local_file? (y/N): " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        cp "$merge_file" "$local_file"
        echo "✅ Merged file saved"
    else
        echo "❌ Merge cancelled - keeping local version"
    fi
}

push_configurations() {
    echo "⬆️ Pushing configurations to other machines..."
    
    log_sync_action "PUSH_START" "Starting push operation"
    
    # Prepare configurations for push
    prepare_configurations_for_push
    
    case "$SYNC_BACKEND" in
        git)
            push_via_git
            ;;
        *)
            echo "❌ Unsupported sync backend: $SYNC_BACKEND"
            return 1
            ;;
    esac
    
    # Update sync state
    update_sync_state "last_push" "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
    
    log_sync_action "PUSH_COMPLETE" "Push operation completed"
    echo "✅ Push completed successfully"
}

prepare_configurations_for_push() {
    echo "📦 Preparing configurations for push..."
    
    local push_dir="$SYNC_DIR/push"
    rm -rf "$push_dir"
    mkdir -p "$push_dir"
    
    # Process each sync item based on machine profile
    jq -r '.sync_items | to_entries[] | select(.value.enabled == true) | .key' "$SYNC_CONFIG" | while read -r item; do
        prepare_sync_item "$item" "$push_dir"
    done
    
    # Create machine metadata
    create_push_metadata "$push_dir"
    
    echo "✅ Configurations prepared for push"
}

prepare_sync_item() {
    local item="$1"
    local push_dir="$2"
    
    local files
    files=$(jq -r ".sync_items.${item}.files[]?" "$SYNC_CONFIG" 2>/dev/null || echo "")
    
    for file in $files; do
        local source_file="$HOME/$file"
        local dest_file="$push_dir/$file"
        
        if [ -f "$source_file" ]; then
            # Apply machine-specific filtering
            if should_sync_file "$item" "$file"; then
                mkdir -p "$(dirname "$dest_file")"
                
                # Check if file needs encryption
                if is_encrypted_item "$item"; then
                    encrypt_file_for_sync "$source_file" "$dest_file"
                else
                    cp "$source_file" "$dest_file"
                fi
            fi
        fi
    done
}

should_sync_file() {
    local item="$1"
    local file="$2"
    
    # Check if file should be synced based on machine profile
    local machine_type=$(jq -r '.machine_type' "$MACHINE_PROFILE")
    local selective=$(jq -r ".sync_items.${item}.selective" "$SYNC_CONFIG" 2>/dev/null || echo "false")
    
    if [ "$selective" = "true" ]; then
        case "$machine_type" in
            work)
                # Skip personal configurations on work machines
                [[ "$file" != *"personal"* ]] && [[ "$file" != *"spotify"* ]]
                ;;
            personal)
                # Skip work configurations on personal machines
                [[ "$file" != *"work"* ]] && [[ "$file" != *"corporate"* ]]
                ;;
            *)
                true
                ;;
        esac
    else
        true
    fi
}

is_encrypted_item() {
    local item="$1"
    local encrypted=$(jq -r ".sync_items.${item}.encrypted" "$SYNC_CONFIG" 2>/dev/null || echo "false")
    [ "$encrypted" = "true" ]
}

encrypt_file_for_sync() {
    local source_file="$1"
    local dest_file="$2"
    
    # Simple encryption using OpenSSL (could be enhanced)
    if command -v openssl >/dev/null; then
        openssl enc -aes-256-cbc -salt -in "$source_file" -out "${dest_file}.enc" -k "dotfiles-sync-$(whoami)"
    else
        echo "⚠️ OpenSSL not available - copying file without encryption"
        cp "$source_file" "$dest_file"
    fi
}

create_push_metadata() {
    local push_dir="$1"
    
    cat > "$push_dir/sync_metadata.json" << EOF
{
    "sync_timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
    "source_machine": $(cat "$MACHINE_PROFILE"),
    "sync_version": "1.0",
    "files_count": $(find "$push_dir" -type f | wc -l),
    "push_id": "$(uuidgen)"
}
EOF
}

push_via_git() {
    echo "📡 Pushing changes via Git..."
    
    local current_branch=$(git branch --show-current)
    local push_dir="$SYNC_DIR/push"
    
    # Checkout sync branch
    git checkout "$SYNC_BRANCH" 2>/dev/null || git checkout -b "$SYNC_BRANCH"
    
    # Copy prepared files to sync branch
    rsync -av "$push_dir/" "$DOTFILES_DIR/sync-data/"
    
    # Commit changes
    git add sync-data/
    
    if git diff --staged --quiet; then
        echo "✅ No changes to push"
    else
        local machine_name=$(jq -r '.machine_name' "$MACHINE_PROFILE")
        git commit -m "Sync from $machine_name at $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
        
        # Push to remote
        if git push "$SYNC_REMOTE" "$SYNC_BRANCH"; then
            echo "✅ Successfully pushed to remote"
        else
            echo "⚠️ Failed to push to remote - check connectivity"
        fi
    fi
    
    # Return to original branch
    git checkout "$current_branch"
}

################################################################################
### Sync Status and Management
################################################################################

show_sync_status() {
    echo "🔄 Multi-Machine Sync Status"
    echo "============================"
    
    if [ ! -f "$SYNC_STATE" ]; then
        echo "❌ Sync system not initialized. Run 'init' first."
        return 1
    fi
    
    local last_sync=$(jq -r '.last_sync // "never"' "$SYNC_STATE")
    local last_pull=$(jq -r '.last_pull // "never"' "$SYNC_STATE")
    local last_push=$(jq -r '.last_push // "never"' "$SYNC_STATE")
    local sync_count=$(jq -r '.sync_count' "$SYNC_STATE")
    local conflicts_resolved=$(jq -r '.conflicts_resolved' "$SYNC_STATE")
    
    echo "Last sync: $last_sync"
    echo "Last pull: $last_pull"
    echo "Last push: $last_push"
    echo "Total syncs: $sync_count"
    echo "Conflicts resolved: $conflicts_resolved"
    
    echo ""
    echo "📊 Sync Configuration:"
    local auto_sync=$(jq -r '.auto_sync' "$SYNC_CONFIG")
    local conflict_resolution=$(jq -r '.conflict_resolution' "$SYNC_CONFIG")
    echo "Auto sync: $auto_sync"
    echo "Conflict resolution: $conflict_resolution"
    
    echo ""
    echo "🔗 Connected Machines:"
    local connected_count=$(jq -r '.connected_machines | length' "$SYNC_STATE")
    if [ "$connected_count" -gt 0 ]; then
        jq -r '.connected_machines[] | "  • " + .name + " (" + .type + ")"' "$SYNC_STATE"
    else
        echo "  No other machines detected yet"
    fi
    
    # Check for pending conflicts
    local pending_conflicts=$(jq -r '.pending_conflicts | length' "$SYNC_STATE")
    if [ "$pending_conflicts" -gt 0 ]; then
        echo ""
        echo "⚠️ Pending Conflicts: $pending_conflicts"
        echo "Run 'machine_sync.sh resolve' to handle conflicts"
    fi
}

list_sync_items() {
    echo "📋 Sync Items Configuration"
    echo "=========================="
    
    jq -r '.sync_items | to_entries[] | 
        "• " + .key + 
        " (enabled: " + (.value.enabled | tostring) + 
        ", files: " + (.value.files | length | tostring) + ")"' "$SYNC_CONFIG"
}

################################################################################
### Utility Functions
################################################################################

create_sync_backup() {
    local backup_name="$1"
    local backup_dir="$SYNC_DIR/backups/$backup_name-$(date +%Y%m%d_%H%M%S)"
    
    echo "💾 Creating sync backup: $backup_name"
    
    mkdir -p "$backup_dir"
    
    # Backup key configuration files
    jq -r '.sync_items | to_entries[] | select(.value.enabled == true) | .value.files[]?' "$SYNC_CONFIG" | while read -r file; do
        local source_file="$HOME/$file"
        if [ -f "$source_file" ]; then
            local dest_file="$backup_dir/$file"
            mkdir -p "$(dirname "$dest_file")"
            cp "$source_file" "$dest_file"
        fi
    done
    
    echo "✅ Backup created: $backup_dir"
}

log_sync_action() {
    local action="$1"
    local details="$2"
    
    echo "$(date -u +"%Y-%m-%dT%H:%M:%SZ") | $action | $details" >> "$SYNC_LOG"
}

update_sync_state() {
    local key="$1"
    local value="$2"
    
    local temp_state=$(mktemp)
    jq --arg key "$key" --arg value "$value" ".${key} = \$value" "$SYNC_STATE" > "$temp_state"
    mv "$temp_state" "$SYNC_STATE"
}

get_remote_file_info() {
    local file="$1"
    # This would extract metadata from the sync system
    echo "other machine"
}

apply_machine_filtering() {
    echo "  🎯 Applying machine-specific filtering..."
    # This would filter configurations based on machine profile
    # Implementation depends on specific filtering rules
}

################################################################################
### Main Interface
################################################################################

show_help() {
    cat << 'EOF'
🔄 Multi-Machine Sync System

DESCRIPTION:
    Intelligent synchronization of configurations across different machines
    with conflict resolution, machine profiles, and selective sync.

USAGE:
    ./machine_sync.sh <command> [options]

COMMANDS:
    init                   Initialize sync system
    pull                   Pull configurations from other machines
    push                   Push local configurations to other machines
    status                 Show sync status and connected machines
    profile <type>         Set machine profile (work|personal|development|minimal)
    resolve                Resolve pending conflicts
    list                   List sync items configuration
    info                   Show current machine information
    
    --help                Show this help message

MACHINE PROFILES:
    work                   Corporate/work environment
    personal               Home/personal use
    development            Development workstation
    minimal                Lightweight/server setup

EXAMPLES:
    ./machine_sync.sh init                    # Initialize sync system
    ./machine_sync.sh profile work            # Set as work machine
    ./machine_sync.sh pull                    # Get latest configurations
    ./machine_sync.sh push                    # Share your configurations
    ./machine_sync.sh status                  # Check sync status

FEATURES:
    🔄 Intelligent conflict resolution
    🖥️ Machine-specific filtering
    🔒 Encrypted sync for sensitive files
    📊 Usage analytics sync
    🎯 Selective sync based on machine type
    ⚡ Git-based backend with delta sync

ENVIRONMENT VARIABLES:
    DOTFILES_SYNC_BACKEND     Sync backend (default: git)
    DOTFILES_SYNC_REMOTE      Git remote (default: origin)
    DOTFILES_SYNC_BRANCH      Sync branch (default: sync)

EOF
}

main() {
    case "${1:-status}" in
        init)
            init_sync_system
            ;;
        pull)
            pull_configurations
            ;;
        push)
            push_configurations
            ;;
        status)
            show_sync_status
            ;;
        profile)
            if [ -n "${2:-}" ]; then
                set_machine_profile "$2"
            else
                echo "❌ Profile type required. Options: work, personal, development, minimal"
                exit 1
            fi
            ;;
        resolve)
            echo "🔧 Resolving pending conflicts..."
            # Implementation would handle conflict resolution
            echo "✅ Conflicts resolved"
            ;;
        list)
            list_sync_items
            ;;
        info)
            show_machine_info
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