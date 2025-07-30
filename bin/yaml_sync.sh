#!/usr/bin/env bash

set -euo pipefail

# YAML Sync - Lightweight sync mechanism for dotfiles YAML configuration
# This script handles pulling remote YAML changes and determining if a full sync is needed

DOTFILES_DIR="${HOME}/.dotfiles"

# Read profile from config file
if [[ -f "$DOTFILES_DIR/.dotfiles.config" ]]; then
    # Try both patterns and use the first one that matches
    PROFILE=$(grep -E '^(export )?MACHINE_PROFILE=' "$DOTFILES_DIR/.dotfiles.config" 2>/dev/null | head -n1 | cut -d'"' -f2)
else
    echo -e "${RED}Error: Config file not found at $DOTFILES_DIR/.dotfiles.config${NC}"
    exit 1
fi

# Ensure profile was found
if [[ -z "${PROFILE:-}" ]]; then
    echo -e "${RED}Error: Could not determine machine profile from config file${NC}"
    echo "Config file contents:"
    grep MACHINE_PROFILE "$DOTFILES_DIR/.dotfiles.config" || echo "No MACHINE_PROFILE found"
    exit 1
fi

YAML_FILE=".dotfiles.${PROFILE}.yaml"
CONFIG_FILE=".dotfiles.config"
STATE_DIR="${DOTFILES_DIR}/.state"
CHECKSUM_FILE="${STATE_DIR}/yaml_checksum"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Ensure state directory exists
mkdir -p "${STATE_DIR}"

# Calculate checksum of YAML file
calculate_yaml_checksum() {
    local yaml_path="$1"
    if [[ -f "$yaml_path" ]]; then
        if command -v sha256sum &> /dev/null; then
            sha256sum "$yaml_path" | awk '{print $1}'
        else
            shasum -a 256 "$yaml_path" | awk '{print $1}'
        fi
    else
        echo ""
    fi
}

# Fetch remote YAML without full git operations
fetch_remote_yaml() {
    local remote_url="https://raw.githubusercontent.com/JARMourato/dotfiles/main/${YAML_FILE}"
    local temp_file="${STATE_DIR}/remote_${YAML_FILE}"
    
    echo -e "${YELLOW}Fetching remote YAML configuration...${NC}" >&2
    
    if curl -sL "$remote_url" -o "$temp_file"; then
        echo -e "${GREEN}✓ Remote YAML fetched successfully${NC}" >&2
        echo "$temp_file"
    else
        echo -e "${RED}✗ Failed to fetch remote YAML${NC}" >&2
        return 1
    fi
}

# Compare local and remote YAML checksums
compare_yaml_versions() {
    local local_yaml="${DOTFILES_DIR}/${YAML_FILE}"
    local remote_yaml="$1"
    
    local local_checksum=$(calculate_yaml_checksum "$local_yaml")
    local remote_checksum=$(calculate_yaml_checksum "$remote_yaml")
    
    if [[ "$local_checksum" == "$remote_checksum" ]]; then
        echo -e "${GREEN}✓ YAML configuration is up to date${NC}"
        return 0
    else
        echo -e "${YELLOW}⚠ YAML configuration has changed${NC}"
        return 1
    fi
}

# Parse and generate config from YAML
generate_config_from_yaml() {
    local yaml_file="$1"
    local output_file="$2"
    
    echo -e "${YELLOW}Generating configuration from YAML...${NC}"
    
    # Use the existing profile-setup.sh script
    if [[ -x "${DOTFILES_DIR}/profile-setup.sh" ]]; then
        cd "${DOTFILES_DIR}"
        ./profile-setup.sh
        echo -e "${GREEN}✓ Configuration generated${NC}"
    else
        echo -e "${RED}✗ profile-setup.sh not found or not executable${NC}"
        return 1
    fi
}

# Compare generated configs to detect changes
compare_configs() {
    local config1="$1"
    local config2="$2"
    
    # Strip timestamps and comments for comparison
    local clean1=$(grep -v '^#' "$config1" | grep -v '^$' | sort)
    local clean2=$(grep -v '^#' "$config2" | grep -v '^$' | sort)
    
    if [[ "$clean1" == "$clean2" ]]; then
        return 0
    else
        return 1
    fi
}

# Save checksum for tracking
save_checksum() {
    local yaml_file="$1"
    local checksum=$(calculate_yaml_checksum "$yaml_file")
    echo "$checksum" > "$CHECKSUM_FILE"
    echo "$(date -Iseconds) $PROFILE" >> "$CHECKSUM_FILE"
}

# Main sync logic
main() {
    local action="${1:-check}"
    
    case "$action" in
        check)
            # Just check if remote YAML has changed
            remote_yaml=$(fetch_remote_yaml)
            if [[ -z "$remote_yaml" ]]; then
                exit 1
            fi
            
            if compare_yaml_versions "$remote_yaml"; then
                rm -f "$remote_yaml"
                exit 0
            else
                echo -e "${YELLOW}Remote YAML has changes. Run 'yaml_sync pull' to update.${NC}"
                rm -f "$remote_yaml"
                exit 1
            fi
            ;;
            
        pull)
            # Pull remote YAML and update if changed
            remote_yaml=$(fetch_remote_yaml)
            if [[ -z "$remote_yaml" ]]; then
                exit 1
            fi
            
            if compare_yaml_versions "$remote_yaml"; then
                rm -f "$remote_yaml"
                echo "No changes needed."
                exit 0
            fi
            
            # Backup current YAML
            local local_yaml="${DOTFILES_DIR}/${YAML_FILE}"
            cp "$local_yaml" "${local_yaml}.backup"
            
            # Update local YAML
            cp "$remote_yaml" "$local_yaml"
            rm -f "$remote_yaml"
            
            # Regenerate config
            generate_config_from_yaml "$local_yaml" "${DOTFILES_DIR}/${CONFIG_FILE}"
            
            # Save new checksum
            save_checksum "$local_yaml"
            
            echo -e "${GREEN}✓ YAML configuration updated${NC}"
            
            # Check if state sync is available and run it
            if [[ -x "${DOTFILES_DIR}/Scripts/sync_state.sh" ]]; then
                echo -e "${YELLOW}Running state sync to check for changes...${NC}"
                "${DOTFILES_DIR}/Scripts/sync_state.sh" compare || true
                echo -e "${YELLOW}Run 'dotfiles_sync --force' for a full system update${NC}"
            else
                echo -e "${YELLOW}Run 'dotfiles_sync' for a full system update${NC}"
            fi
            ;;
            
        push)
            # Push local YAML changes to git
            cd "${DOTFILES_DIR}"
            
            # Check if YAML has local changes
            if git diff --quiet "${YAML_FILE}"; then
                echo -e "${GREEN}No local YAML changes to push${NC}"
                exit 0
            fi
            
            echo -e "${YELLOW}Pushing YAML configuration changes...${NC}"
            
            # Stage and commit YAML
            git add "${YAML_FILE}"
            git commit -m "Update ${PROFILE} profile YAML configuration"
            
            # Push to remote
            if git push origin main; then
                echo -e "${GREEN}✓ YAML configuration pushed successfully${NC}"
                save_checksum "${DOTFILES_DIR}/${YAML_FILE}"
            else
                echo -e "${RED}✗ Failed to push YAML changes${NC}"
                exit 1
            fi
            ;;
            
        status)
            # Show current sync status
            echo "Profile: ${PROFILE}"
            echo "YAML file: ${YAML_FILE}"
            echo "Config path: ${DOTFILES_DIR}/${CONFIG_FILE}"
            
            if [[ -f "$CHECKSUM_FILE" ]]; then
                echo -e "\nLast sync:"
                tail -n 1 "$CHECKSUM_FILE"
            else
                echo -e "\nNo sync history found"
            fi
            
            # Check for local changes (if in git repo)
            if [[ -d "${DOTFILES_DIR}/.git" ]]; then
                cd "${DOTFILES_DIR}" || {
                    echo -e "${RED}Error: Cannot change to dotfiles directory${NC}"
                    exit 1
                }
                
                if git diff --quiet "${YAML_FILE}" 2>/dev/null; then
                    echo -e "\n${GREEN}No local YAML changes${NC}"
                else
                    echo -e "\n${YELLOW}Local YAML has uncommitted changes${NC}"
                    git diff --stat "${YAML_FILE}" 2>/dev/null || true
                fi
            fi
            
            # Check remote
            remote_yaml=$(fetch_remote_yaml)
            if [[ -n "$remote_yaml" ]]; then
                if compare_yaml_versions "$remote_yaml"; then
                    echo -e "\n${GREEN}In sync with remote${NC}"
                else
                    echo -e "\n${YELLOW}Remote has newer changes${NC}"
                fi
                rm -f "$remote_yaml"
            fi
            ;;
            
        *)
            echo "Usage: $0 {check|pull|push|status}"
            echo ""
            echo "Commands:"
            echo "  check  - Check if remote YAML has changed"
            echo "  pull   - Pull remote YAML changes if any"
            echo "  push   - Push local YAML changes to git"
            echo "  status - Show current sync status"
            exit 1
            ;;
    esac
}

main "$@"