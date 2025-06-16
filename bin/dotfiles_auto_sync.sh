#!/usr/bin/env bash

set -euo pipefail

# Auto-sync script for dotfiles
# This can be run via cron or launchd to keep dotfiles in sync automatically

DOTFILES_DIR="${HOME}/dotfiles"
LOG_FILE="${DOTFILES_DIR}/.state/auto_sync.log"
LOCK_FILE="${DOTFILES_DIR}/.state/auto_sync.lock"

# Ensure state directory exists
mkdir -p "${DOTFILES_DIR}/.state"

# Function to log messages
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$LOG_FILE"
}

# Function to clean up lock file
cleanup() {
    rm -f "$LOCK_FILE"
}

# Set up trap to clean up on exit
trap cleanup EXIT

# Check if another instance is running
if [[ -f "$LOCK_FILE" ]]; then
    log "Another sync is already running. Exiting."
    exit 0
fi

# Create lock file
echo $$ > "$LOCK_FILE"

log "Starting auto-sync check..."

# Check for YAML changes
if "${DOTFILES_DIR}/bin/yaml_sync.sh" check > /dev/null 2>&1; then
    log "No changes detected."
else
    log "Changes detected. Running light sync..."
    
    # Pull YAML changes
    if "${DOTFILES_DIR}/bin/yaml_sync.sh" pull >> "$LOG_FILE" 2>&1; then
        log "YAML sync completed successfully."
        
        # Check if we need to run full sync based on state changes
        if "${DOTFILES_DIR}/Scripts/sync_state.sh" compare > /dev/null 2>&1; then
            log "No package changes needed."
        else
            log "Package changes detected. Manual intervention may be required."
            # Could send notification here if desired
        fi
    else
        log "ERROR: YAML sync failed."
    fi
fi

# Rotate log if it gets too large (keep last 1000 lines)
if [[ -f "$LOG_FILE" ]] && [[ $(wc -l < "$LOG_FILE") -gt 1000 ]]; then
    tail -n 1000 "$LOG_FILE" > "$LOG_FILE.tmp"
    mv "$LOG_FILE.tmp" "$LOG_FILE"
fi

log "Auto-sync check completed."