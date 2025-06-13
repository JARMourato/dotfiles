#!/bin/bash

################################################################################
### 🔄 State tracking and synchronization for dotfiles
### Implements declarative package management - removes items not in YAML
################################################################################

echo "========================================"
echo "🔄 Syncing System State..."
echo "========================================"
echo ""

set -e

# Get the directory of the dotfiles
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STATE_DIR="$DOTFILES_DIR/.state"
CURRENT_STATE_FILE="$STATE_DIR/current.json"
PREVIOUS_STATE_FILE="$STATE_DIR/previous.json"

# Ensure state directory exists
mkdir -p "$STATE_DIR"

# Source the current configuration
if [[ -f "$DOTFILES_DIR/.dotfiles.config" ]]; then
    source "$DOTFILES_DIR/.dotfiles.config"
else
    echo "❌ No configuration found. Run profile setup first."
    exit 1
fi

################################################################################
### Functions to get current system state
################################################################################

get_installed_formulas() {
    if command -v brew >/dev/null 2>&1; then
        brew list --formula | jq -R -s 'split("\n") | map(select(length > 0))'
    else
        echo "[]"
    fi
}

get_installed_casks() {
    if command -v brew >/dev/null 2>&1; then
        brew list --cask | jq -R -s 'split("\n") | map(select(length > 0))'
    else
        echo "[]"
    fi
}

get_installed_mas_apps() {
    if command -v mas >/dev/null 2>&1; then
        # Get MAS apps in format: {"id": "app_name"}
        mas list | awk '{print "\"" $1 "\": \"" substr($0, index($0, $2)) "\""}' | \
        sed 's/^/{/' | sed 's/$/}/' | jq -s 'add // {}'
    else
        echo "{}"
    fi
}

get_installed_gems() {
    if command -v gem >/dev/null 2>&1; then
        gem list --local --no-versions | jq -R -s 'split("\n") | map(select(length > 0))'
    else
        echo "[]"
    fi
}

get_installed_python_packages() {
    if command -v pip3 >/dev/null 2>&1; then
        pip3 list --format=freeze | cut -d'=' -f1 | jq -R -s 'split("\n") | map(select(length > 0))'
    else
        echo "[]"
    fi
}

################################################################################
### Functions to parse desired state from configuration
################################################################################

get_desired_formulas() {
    if [[ -n "${HOMEBREW_FORMULAS:-}" ]]; then
        echo "$HOMEBREW_FORMULAS" | tr ' ' '\n' | jq -R -s 'split("\n") | map(select(length > 0))'
    else
        echo "[]"
    fi
}

get_desired_casks() {
    if [[ -n "${HOMEBREW_CASKS:-}" ]]; then
        echo "$HOMEBREW_CASKS" | tr ' ' '\n' | jq -R -s 'split("\n") | map(select(length > 0))'
    else
        echo "[]"
    fi
}

get_desired_mas_apps() {
    if [[ -n "${MAS_APPS:-}" ]]; then
        # Convert space-separated IDs to JSON object with empty names (will be filled by mas list)
        local result="{"
        local first=true
        for app_id in $MAS_APPS; do
            if [[ "$first" == "true" ]]; then
                first=false
            else
                result+=", "
            fi
            result+="\"$app_id\": \"\""
        done
        result+="}"
        echo "$result"
    else
        echo "{}"
    fi
}

################################################################################
### Core state functions
################################################################################

generate_current_state() {
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    cat > "$CURRENT_STATE_FILE" << EOF
{
  "last_updated": "$timestamp",
  "profile": "${MACHINE_PROFILE:-unknown}",
  "desired": {
    "homebrew": {
      "formulas": $(get_desired_formulas),
      "casks": $(get_desired_casks)
    },
    "mas_apps": $(get_desired_mas_apps),
    "gems": ["bundler"],
    "python_packages": ["pyusb"]
  },
  "installed": {
    "homebrew": {
      "formulas": $(get_installed_formulas),
      "casks": $(get_installed_casks)
    },
    "mas_apps": $(get_installed_mas_apps),
    "gems": $(get_installed_gems),
    "python_packages": $(get_installed_python_packages)
  }
}
EOF
}

compare_states() {
    if [[ ! -f "$PREVIOUS_STATE_FILE" ]]; then
        echo "📝 No previous state found - this is the first run"
        return 0
    fi
    
    if [[ ! -f "$CURRENT_STATE_FILE" ]]; then
        echo "❌ Current state file not found"
        return 1
    fi
    
    echo "🔍 Comparing current desired state with previous installation..."
    
    # Check if jq is available
    if ! command -v jq >/dev/null 2>&1; then
        echo "❌ jq is required for state comparison but not found"
        return 1
    fi
    
    # Compare and show differences
    local has_changes=false
    
    # Compare formulas
    local prev_formulas=$(jq -r '.desired.homebrew.formulas[]?' "$PREVIOUS_STATE_FILE" 2>/dev/null | sort)
    local curr_formulas=$(jq -r '.desired.homebrew.formulas[]?' "$CURRENT_STATE_FILE" 2>/dev/null | sort)
    
    if [[ "$prev_formulas" != "$curr_formulas" ]]; then
        echo "📦 Homebrew formulas changed:"
        comm -23 <(echo "$prev_formulas") <(echo "$curr_formulas") | while read formula; do
            [[ -n "$formula" ]] && echo "  ➖ $formula (will be removed)"
        done
        comm -13 <(echo "$prev_formulas") <(echo "$curr_formulas") | while read formula; do
            [[ -n "$formula" ]] && echo "  ➕ $formula (will be added)"
        done
        has_changes=true
    fi
    
    # Compare casks
    local prev_casks=$(jq -r '.desired.homebrew.casks[]?' "$PREVIOUS_STATE_FILE" 2>/dev/null | sort)
    local curr_casks=$(jq -r '.desired.homebrew.casks[]?' "$CURRENT_STATE_FILE" 2>/dev/null | sort)
    
    if [[ "$prev_casks" != "$curr_casks" ]]; then
        echo "🖥️  Homebrew casks changed:"
        comm -23 <(echo "$prev_casks") <(echo "$curr_casks") | while read cask; do
            [[ -n "$cask" ]] && echo "  ➖ $cask (will be removed)"
        done
        comm -13 <(echo "$prev_casks") <(echo "$curr_casks") | while read cask; do
            [[ -n "$cask" ]] && echo "  ➕ $cask (will be added)"
        done
        has_changes=true
    fi
    
    # Compare MAS apps
    local prev_mas=$(jq -r '.desired.mas_apps | keys[]?' "$PREVIOUS_STATE_FILE" 2>/dev/null | sort)
    local curr_mas=$(jq -r '.desired.mas_apps | keys[]?' "$CURRENT_STATE_FILE" 2>/dev/null | sort)
    
    if [[ "$prev_mas" != "$curr_mas" ]]; then
        echo "🍏 Mac App Store apps changed:"
        comm -23 <(echo "$prev_mas") <(echo "$curr_mas") | while read app_id; do
            [[ -n "$app_id" ]] && echo "  ➖ App ID $app_id (will be removed)"
        done
        comm -13 <(echo "$prev_mas") <(echo "$curr_mas") | while read app_id; do
            [[ -n "$app_id" ]] && echo "  ➕ App ID $app_id (will be added)"
        done
        has_changes=true
    fi
    
    if [[ "$has_changes" == "false" ]]; then
        echo "✅ No changes detected in desired state"
    fi
}

save_state() {
    if [[ -f "$CURRENT_STATE_FILE" ]]; then
        cp "$CURRENT_STATE_FILE" "$PREVIOUS_STATE_FILE"
        echo "💾 State saved for next comparison"
    fi
}

################################################################################
### Removal functions
################################################################################

remove_orphaned_packages() {
    if [[ ! -f "$PREVIOUS_STATE_FILE" ]]; then
        echo "📝 No previous state - skipping removal check"
        return 0
    fi
    
    echo "🧹 Checking for packages to remove..."
    
    # Remove orphaned formulas
    local prev_formulas=$(jq -r '.desired.homebrew.formulas[]?' "$PREVIOUS_STATE_FILE" 2>/dev/null)
    local curr_formulas=$(jq -r '.desired.homebrew.formulas[]?' "$CURRENT_STATE_FILE" 2>/dev/null)
    
    comm -23 <(echo "$prev_formulas" | sort) <(echo "$curr_formulas" | sort) | while read formula; do
        if [[ -n "$formula" ]] && brew list --formula | grep -q "^${formula}$"; then
            echo "🗑️  Removing formula: $formula"
            brew uninstall "$formula" || echo "⚠️  Failed to remove $formula"
        fi
    done
    
    # Remove orphaned casks
    local prev_casks=$(jq -r '.desired.homebrew.casks[]?' "$PREVIOUS_STATE_FILE" 2>/dev/null)
    local curr_casks=$(jq -r '.desired.homebrew.casks[]?' "$CURRENT_STATE_FILE" 2>/dev/null)
    
    comm -23 <(echo "$prev_casks" | sort) <(echo "$curr_casks" | sort) | while read cask; do
        if [[ -n "$cask" ]] && brew list --cask | grep -q "^${cask}$"; then
            echo "🗑️  Removing cask: $cask"
            brew uninstall --cask "$cask" || echo "⚠️  Failed to remove $cask"
        fi
    done
    
    # Remove orphaned MAS apps
    local prev_mas=$(jq -r '.desired.mas_apps | keys[]?' "$PREVIOUS_STATE_FILE" 2>/dev/null)
    local curr_mas=$(jq -r '.desired.mas_apps | keys[]?' "$CURRENT_STATE_FILE" 2>/dev/null)
    
    comm -23 <(echo "$prev_mas" | sort) <(echo "$curr_mas" | sort) | while read app_id; do
        if [[ -n "$app_id" ]]; then
            # Get app name from mas list
            local app_name=$(mas list | grep "^$app_id" | cut -d' ' -f2- | sed 's/^[[:space:]]*//')
            local app_path="/Applications/${app_name}.app"
            
            if [[ -d "$app_path" ]]; then
                echo "🗑️  Removing MAS app: $app_name"
                sudo rm -rf "$app_path" || echo "⚠️  Failed to remove $app_name"
            fi
        fi
    done
    
    # Remove orphaned gems
    local prev_gems=$(jq -r '.desired.gems[]?' "$PREVIOUS_STATE_FILE" 2>/dev/null)
    local curr_gems=$(jq -r '.desired.gems[]?' "$CURRENT_STATE_FILE" 2>/dev/null)
    
    comm -23 <(echo "$prev_gems" | sort) <(echo "$curr_gems" | sort) | while read gem_name; do
        if [[ -n "$gem_name" ]] && gem list --local | grep -q "^${gem_name}"; then
            echo "🗑️  Removing gem: $gem_name"
            gem uninstall "$gem_name" --force || echo "⚠️  Failed to remove $gem_name"
        fi
    done
    
    # Remove orphaned Python packages
    local prev_python=$(jq -r '.desired.python_packages[]?' "$PREVIOUS_STATE_FILE" 2>/dev/null)
    local curr_python=$(jq -r '.desired.python_packages[]?' "$CURRENT_STATE_FILE" 2>/dev/null)
    
    comm -23 <(echo "$prev_python" | sort) <(echo "$curr_python" | sort) | while read package; do
        if [[ -n "$package" ]] && pip3 list | grep -q "^${package}"; then
            echo "🗑️  Removing Python package: $package"
            pip3 uninstall "$package" --yes || echo "⚠️  Failed to remove $package"
        fi
    done
}

################################################################################
### Main execution
################################################################################

main() {
    local command="${1:-sync}"
    
    case "$command" in
        "generate")
            echo "📊 Generating current state..."
            generate_current_state
            echo "✅ Current state generated: $CURRENT_STATE_FILE"
            ;;
        "compare")
            generate_current_state
            compare_states
            ;;
        "sync")
            echo "🔄 Synchronizing state..."
            generate_current_state
            compare_states
            
            # Ask for confirmation before removing packages
            if [[ -f "$PREVIOUS_STATE_FILE" ]]; then
                read -p "Remove orphaned packages? (y/N): " -n 1 -r
                echo
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    remove_orphaned_packages
                else
                    echo "⏭️  Skipping package removal"
                fi
            fi
            
            save_state
            ;;
        "reset")
            echo "🗑️  Removing state files..."
            rm -f "$CURRENT_STATE_FILE" "$PREVIOUS_STATE_FILE"
            echo "✅ State reset"
            ;;
        *)
            echo "Usage: $0 [generate|compare|sync|reset]"
            echo "  generate - Generate current state file"
            echo "  compare  - Compare current vs previous state"
            echo "  sync     - Full sync with optional removal"
            echo "  reset    - Remove all state files"
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"