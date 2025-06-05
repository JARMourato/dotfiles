#!/bin/bash

set -euo pipefail

################################################################################
### Automated Maintenance System
################################################################################

# This script provides automated maintenance for the dotfiles system including
# package updates, health monitoring, cleanup, and proactive issue detection

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"
MAINTENANCE_LOG="$HOME/.dotfiles_logs/maintenance.log"
HEALTH_REPORT="$HOME/.dotfiles_logs/health_report.json"

# Load dependencies
source "$SCRIPT_DIR/caching_system.sh" 2>/dev/null || true
source "$SCRIPT_DIR/progress_indicators.sh" 2>/dev/null || true
source "$SCRIPT_DIR/config_parser.sh" 2>/dev/null || true

# Maintenance configuration
MAINTENANCE_CONFIG_FILE="$HOME/.dotfiles_maintenance.config"
AUTO_UPDATE_PACKAGES=true
AUTO_CLEANUP_CACHE=true
AUTO_ROTATE_LOGS=true
AUTO_SNAPSHOT_BEFORE_UPDATES=true
NOTIFICATION_EMAIL=""
SLACK_WEBHOOK=""

################################################################################
### Core Maintenance Functions
################################################################################

# Initialize maintenance system
init_maintenance() {
    echo "🔧 Initializing automated maintenance system..."
    
    # Create log directories
    mkdir -p "$HOME/.dotfiles_logs"
    mkdir -p "$HOME/.dotfiles_maintenance"
    
    # Initialize maintenance config if not exists
    if [ ! -f "$MAINTENANCE_CONFIG_FILE" ]; then
        create_default_maintenance_config
    fi
    
    # Load maintenance configuration
    load_maintenance_config
    
    echo "✅ Maintenance system initialized"
}

# Create default maintenance configuration
create_default_maintenance_config() {
    cat > "$MAINTENANCE_CONFIG_FILE" << 'EOF'
# Automated Maintenance Configuration
# Controls what automatic maintenance tasks are performed

# Package Management
AUTO_UPDATE_PACKAGES=true
AUTO_UPDATE_HOMEBREW=true
AUTO_CLEANUP_BREW_CACHE=true
AUTO_UPDATE_GEMS=false
AUTO_UPDATE_PYTHON_PACKAGES=false

# System Maintenance
AUTO_CLEANUP_CACHE=true
AUTO_ROTATE_LOGS=true
AUTO_CLEANUP_DOWNLOADS=true
AUTO_VALIDATE_SYMLINKS=true

# Safety Features
AUTO_SNAPSHOT_BEFORE_UPDATES=true
AUTO_ROLLBACK_ON_FAILURE=true
MAX_SNAPSHOTS_TO_KEEP=10

# Monitoring
ENABLE_HEALTH_MONITORING=true
ENABLE_PERFORMANCE_MONITORING=true
ENABLE_DISK_MONITORING=true

# Notifications
NOTIFICATION_EMAIL=""
SLACK_WEBHOOK=""
ENABLE_CONSOLE_NOTIFICATIONS=true

# Schedules (in minutes)
DAILY_MAINTENANCE_TIME="02:00"
WEEKLY_MAINTENANCE_DAY="Sunday"
WEEKLY_MAINTENANCE_TIME="03:00"
EOF
}

# Load maintenance configuration
load_maintenance_config() {
    if [ -f "$MAINTENANCE_CONFIG_FILE" ]; then
        source "$MAINTENANCE_CONFIG_FILE"
    fi
}

################################################################################
### Daily Maintenance Routine
################################################################################

# Run daily maintenance tasks
run_daily_maintenance() {
    local start_time=$(date +%s)
    local maintenance_id="daily_$(date +%Y%m%d_%H%M%S)"
    
    log_maintenance "🌅 Starting daily maintenance: $maintenance_id"
    
    # Initialize systems
    init_cache 2>/dev/null || true
    
    # Create maintenance snapshot if enabled
    if [ "$AUTO_SNAPSHOT_BEFORE_UPDATES" = "true" ]; then
        create_maintenance_snapshot "$maintenance_id"
    fi
    
    # Run daily tasks
    local tasks=(
        "check_system_health"
        "update_package_lists"
        "validate_symlinks" 
        "cleanup_cache_if_needed"
        "rotate_logs_if_needed"
        "check_disk_space"
        "monitor_security_updates"
        "validate_configurations"
    )
    
    local failed_tasks=()
    
    for task in "${tasks[@]}"; do
        log_maintenance "📋 Running task: $task"
        
        if run_with_error_handling "$task"; then
            log_maintenance "✅ Task completed: $task"
        else
            log_maintenance "❌ Task failed: $task"
            failed_tasks+=("$task")
        fi
    done
    
    # Generate health report
    generate_health_report "$maintenance_id" "${failed_tasks[@]}"
    
    # Send notifications if configured
    send_maintenance_notification "$maintenance_id" "${failed_tasks[@]}"
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    log_maintenance "✅ Daily maintenance completed in ${duration}s"
    
    # Return success if no critical failures
    [ ${#failed_tasks[@]} -eq 0 ]
}

# Run weekly maintenance tasks
run_weekly_maintenance() {
    local start_time=$(date +%s)
    local maintenance_id="weekly_$(date +%Y%m%d_%H%M%S)"
    
    log_maintenance "📅 Starting weekly maintenance: $maintenance_id"
    
    # Create maintenance snapshot
    if [ "$AUTO_SNAPSHOT_BEFORE_UPDATES" = "true" ]; then
        create_maintenance_snapshot "$maintenance_id"
    fi
    
    # Run weekly tasks
    local tasks=(
        "run_daily_maintenance"
        "deep_system_cleanup"
        "update_packages_safely"
        "optimize_homebrew_cache"
        "cleanup_old_snapshots"
        "run_comprehensive_health_check"
        "analyze_performance_metrics"
        "backup_configurations"
    )
    
    local failed_tasks=()
    
    for task in "${tasks[@]}"; do
        log_maintenance "📋 Running weekly task: $task"
        
        if run_with_error_handling "$task"; then
            log_maintenance "✅ Weekly task completed: $task"
        else
            log_maintenance "❌ Weekly task failed: $task"
            failed_tasks+=("$task")
        fi
    done
    
    # Generate comprehensive weekly report
    generate_weekly_report "$maintenance_id" "${failed_tasks[@]}"
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    log_maintenance "✅ Weekly maintenance completed in ${duration}s"
    
    [ ${#failed_tasks[@]} -eq 0 ]
}

################################################################################
### Health Monitoring Functions
################################################################################

# Check overall system health
check_system_health() {
    local health_issues=()
    
    # Check critical dependencies
    if ! command -v brew >/dev/null 2>&1; then
        health_issues+=("Homebrew not available")
    fi
    
    if ! command -v git >/dev/null 2>&1; then
        health_issues+=("Git not available")
    fi
    
    # Check dotfiles repository status
    if [ -d "$DOTFILES_DIR/.git" ]; then
        cd "$DOTFILES_DIR"
        if ! git status >/dev/null 2>&1; then
            health_issues+=("Dotfiles repository corrupted")
        fi
    else
        health_issues+=("Dotfiles repository not found")
    fi
    
    # Check available disk space
    local available_space=$(df / | awk 'NR==2 {print $4}')
    if [ "$available_space" -lt 1048576 ]; then  # Less than 1GB
        health_issues+=("Low disk space: $(df -h / | awk 'NR==2 {print $4}') available")
    fi
    
    # Check for broken symlinks
    local broken_symlinks=$(find "$HOME" -maxdepth 3 -type l ! -exec test -e {} \; -print 2>/dev/null | wc -l)
    if [ "$broken_symlinks" -gt 0 ]; then
        health_issues+=("$broken_symlinks broken symlinks detected")
    fi
    
    # Report health status
    if [ ${#health_issues[@]} -eq 0 ]; then
        log_maintenance "✅ System health check passed"
        return 0
    else
        log_maintenance "⚠️  System health issues detected:"
        for issue in "${health_issues[@]}"; do
            log_maintenance "  - $issue"
        done
        return 1
    fi
}

# Update package lists without installing
update_package_lists() {
    if [ "$AUTO_UPDATE_HOMEBREW" = "true" ]; then
        log_maintenance "📦 Updating Homebrew package lists..."
        if brew update >/dev/null 2>&1; then
            log_maintenance "✅ Homebrew package lists updated"
        else
            log_maintenance "❌ Failed to update Homebrew package lists"
            return 1
        fi
    fi
    
    # Check for available updates
    local outdated_packages=$(brew outdated | wc -l)
    if [ "$outdated_packages" -gt 0 ]; then
        log_maintenance "📊 $outdated_packages packages have updates available"
        brew outdated | while read -r package; do
            log_maintenance "  - $package"
        done
    fi
}

# Validate symlinks are correct
validate_symlinks() {
    log_maintenance "🔗 Validating symlinks..."
    
    local broken_count=0
    local fixed_count=0
    
    # Check for broken symlinks in common dotfile locations
    for location in "$HOME" "$HOME/.config" "$HOME/bin"; do
        if [ -d "$location" ]; then
            while IFS= read -r -d '' symlink; do
                if [ ! -e "$symlink" ]; then
                    log_maintenance "❌ Broken symlink: $symlink"
                    broken_count=$((broken_count + 1))
                    
                    # Try to fix if we can determine the source
                    if attempt_symlink_repair "$symlink"; then
                        fixed_count=$((fixed_count + 1))
                    fi
                fi
            done < <(find "$location" -maxdepth 2 -type l -print0 2>/dev/null)
        fi
    done
    
    if [ $broken_count -eq 0 ]; then
        log_maintenance "✅ All symlinks are valid"
    else
        log_maintenance "⚠️  Found $broken_count broken symlinks, fixed $fixed_count"
    fi
    
    return 0
}

# Attempt to repair a broken symlink
attempt_symlink_repair() {
    local broken_symlink="$1"
    local link_target=$(readlink "$broken_symlink")
    
    # If target looks like a dotfiles path, try to recreate
    if [[ "$link_target" == *".dotfiles"* ]]; then
        local potential_source="$DOTFILES_DIR/$(basename "$broken_symlink")"
        if [ -f "$potential_source" ]; then
            rm "$broken_symlink"
            ln -sf "$potential_source" "$broken_symlink"
            log_maintenance "🔧 Repaired symlink: $broken_symlink -> $potential_source"
            return 0
        fi
    fi
    
    return 1
}

################################################################################
### Smart Update System
################################################################################

# Safely update packages with rollback capability
update_packages_safely() {
    if [ "$AUTO_UPDATE_PACKAGES" != "true" ]; then
        log_maintenance "⏭️  Package updates disabled in configuration"
        return 0
    fi
    
    log_maintenance "📦 Starting safe package updates..."
    
    # Create pre-update snapshot
    local snapshot_name="pre-update-$(date +%Y%m%d_%H%M%S)"
    if ! create_maintenance_snapshot "$snapshot_name"; then
        log_maintenance "❌ Failed to create pre-update snapshot, aborting updates"
        return 1
    fi
    
    # Check what packages will be updated
    local packages_to_update=($(brew outdated --quiet))
    if [ ${#packages_to_update[@]} -eq 0 ]; then
        log_maintenance "✅ All packages are up to date"
        return 0
    fi
    
    log_maintenance "📊 Updating ${#packages_to_update[@]} packages..."
    
    # Update packages with progress if available
    if command -v install_packages_with_progress >/dev/null 2>&1; then
        install_packages_with_progress "upgrade" "${packages_to_update[@]}"
    else
        brew upgrade "${packages_to_update[@]}"
    fi
    
    # Validate system health after updates
    if check_system_health && validate_critical_applications; then
        log_maintenance "✅ Package updates completed successfully"
        
        # Clean up old packages
        brew cleanup >/dev/null 2>&1 || true
        
        return 0
    else
        log_maintenance "❌ System validation failed after updates, rolling back..."
        
        # Rollback to pre-update snapshot
        if rollback_to_snapshot "$snapshot_name"; then
            log_maintenance "✅ Rollback completed successfully"
        else
            log_maintenance "❌ Rollback failed - manual intervention required"
        fi
        
        return 1
    fi
}

# Validate critical applications still work after updates
validate_critical_applications() {
    local critical_apps=("git" "brew" "curl" "ssh")
    
    for app in "${critical_apps[@]}"; do
        if ! command -v "$app" >/dev/null 2>&1; then
            log_maintenance "❌ Critical application not working: $app"
            return 1
        fi
    done
    
    # Test git functionality
    if ! git --version >/dev/null 2>&1; then
        log_maintenance "❌ Git not functioning properly"
        return 1
    fi
    
    # Test brew functionality
    if ! brew --version >/dev/null 2>&1; then
        log_maintenance "❌ Homebrew not functioning properly"
        return 1
    fi
    
    log_maintenance "✅ Critical applications validated"
    return 0
}

################################################################################
### Cleanup and Optimization
################################################################################

# Clean up cache if needed
cleanup_cache_if_needed() {
    if [ "$AUTO_CLEANUP_CACHE" != "true" ]; then
        return 0
    fi
    
    # Check cache size
    local cache_size_mb=$(get_cache_size_mb 2>/dev/null || echo "0")
    local cache_max_mb=${CACHE_MAX_SIZE_MB:-2000}
    
    if [ "$cache_size_mb" -gt "$cache_max_mb" ]; then
        log_maintenance "🧹 Cache size ($cache_size_mb MB) exceeds limit ($cache_max_mb MB), cleaning..."
        cleanup_cache >/dev/null 2>&1 || true
    fi
    
    # Clean old downloads
    if [ "$AUTO_CLEANUP_DOWNLOADS" = "true" ]; then
        find "$HOME/Downloads" -type f -mtime +7 -name "*.dmg" -delete 2>/dev/null || true
        find "$HOME/Downloads" -type f -mtime +30 -delete 2>/dev/null || true
    fi
}

# Rotate logs if needed
rotate_logs_if_needed() {
    if [ "$AUTO_ROTATE_LOGS" != "true" ]; then
        return 0
    fi
    
    local log_dir="$HOME/.dotfiles_logs"
    
    # Rotate maintenance log if it's too large
    if [ -f "$MAINTENANCE_LOG" ] && [ $(stat -f%z "$MAINTENANCE_LOG" 2>/dev/null || echo 0) -gt 10485760 ]; then
        mv "$MAINTENANCE_LOG" "${MAINTENANCE_LOG}.$(date +%Y%m%d)"
        gzip "${MAINTENANCE_LOG}.$(date +%Y%m%d)" 2>/dev/null || true
        touch "$MAINTENANCE_LOG"
        log_maintenance "📋 Rotated maintenance log"
    fi
    
    # Clean old log files
    find "$log_dir" -name "*.log.*" -mtime +30 -delete 2>/dev/null || true
    find "$log_dir" -name "*.gz" -mtime +90 -delete 2>/dev/null || true
}

# Check disk space and warn if low
check_disk_space() {
    local available_gb=$(df / | awk 'NR==2 {printf "%.1f", $4/1024/1024}')
    local used_percent=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')
    
    if [ "$used_percent" -gt 90 ]; then
        log_maintenance "⚠️  Disk space critical: ${used_percent}% used, ${available_gb}GB available"
        
        # Suggest cleanup actions
        suggest_disk_cleanup
        
        return 1
    elif [ "$used_percent" -gt 80 ]; then
        log_maintenance "⚠️  Disk space warning: ${used_percent}% used, ${available_gb}GB available"
    else
        log_maintenance "✅ Disk space healthy: ${used_percent}% used, ${available_gb}GB available"
    fi
    
    return 0
}

# Suggest disk cleanup actions
suggest_disk_cleanup() {
    log_maintenance "💡 Disk cleanup suggestions:"
    
    # Large files in Downloads
    local large_downloads=$(find "$HOME/Downloads" -type f -size +100M | wc -l)
    if [ "$large_downloads" -gt 0 ]; then
        log_maintenance "  - $large_downloads large files in Downloads folder"
    fi
    
    # Homebrew cache
    local brew_cache_size=$(brew --cache | xargs du -sh 2>/dev/null | cut -f1 || echo "0B")
    log_maintenance "  - Homebrew cache: $brew_cache_size (run 'brew cleanup --prune=all')"
    
    # Docker if installed
    if command -v docker >/dev/null 2>&1; then
        log_maintenance "  - Docker images and containers (run 'docker system prune -a')"
    fi
    
    # Xcode if installed
    if [ -d "/Applications/Xcode.app" ]; then
        log_maintenance "  - Xcode derived data and archives"
    fi
}

################################################################################
### Security Monitoring
################################################################################

# Monitor for security updates
monitor_security_updates() {
    log_maintenance "🔒 Checking for security updates..."
    
    # Check for macOS security updates
    local software_updates=$(softwareupdate --list 2>/dev/null | grep -c "recommended" || echo "0")
    if [ "$software_updates" -gt 0 ]; then
        log_maintenance "⚠️  $software_updates macOS security updates available"
        log_maintenance "   Run 'sudo softwareupdate --install --all' to apply"
    fi
    
    # Check for Homebrew security updates
    if command -v brew >/dev/null 2>&1; then
        local outdated_count=$(brew outdated | wc -l)
        if [ "$outdated_count" -gt 0 ]; then
            log_maintenance "📦 $outdated_count package updates available (may include security fixes)"
        fi
    fi
    
    # Check age of encrypted files
    if [ -f "$DOTFILES_DIR/Scripts/check_secrets_age.sh" ]; then
        if ! "$DOTFILES_DIR/Scripts/check_secrets_age.sh" --quiet; then
            log_maintenance "⚠️  Some encrypted secrets may need rotation"
        fi
    fi
}

################################################################################
### Snapshot Management
################################################################################

# Create maintenance snapshot
create_maintenance_snapshot() {
    local snapshot_name="$1"
    
    if [ -f "$DOTFILES_DIR/Scripts/create_snapshot.sh" ]; then
        log_maintenance "📸 Creating maintenance snapshot: $snapshot_name"
        
        if "$DOTFILES_DIR/Scripts/create_snapshot.sh" "$snapshot_name" --description "Automated maintenance snapshot" --quick >/dev/null 2>&1; then
            log_maintenance "✅ Snapshot created: $snapshot_name"
            return 0
        else
            log_maintenance "❌ Failed to create snapshot: $snapshot_name"
            return 1
        fi
    else
        log_maintenance "⚠️  Snapshot script not found, skipping snapshot creation"
        return 1
    fi
}

# Rollback to snapshot
rollback_to_snapshot() {
    local snapshot_name="$1"
    
    if [ -f "$DOTFILES_DIR/Scripts/rollback.sh" ]; then
        log_maintenance "🔄 Rolling back to snapshot: $snapshot_name"
        
        if "$DOTFILES_DIR/Scripts/rollback.sh" "$snapshot_name" --auto-confirm >/dev/null 2>&1; then
            log_maintenance "✅ Rollback completed: $snapshot_name"
            return 0
        else
            log_maintenance "❌ Rollback failed: $snapshot_name"
            return 1
        fi
    else
        log_maintenance "❌ Rollback script not found"
        return 1
    fi
}

# Cleanup old snapshots
cleanup_old_snapshots() {
    local max_snapshots=${MAX_SNAPSHOTS_TO_KEEP:-10}
    
    if [ -d "$HOME/.dotfiles_snapshots" ]; then
        local snapshot_count=$(ls -1 "$HOME/.dotfiles_snapshots" | wc -l)
        
        if [ "$snapshot_count" -gt "$max_snapshots" ]; then
            log_maintenance "🗑️  Cleaning up old snapshots (keeping $max_snapshots most recent)"
            
            # Remove oldest snapshots
            ls -1t "$HOME/.dotfiles_snapshots" | tail -n +$((max_snapshots + 1)) | while read -r old_snapshot; do
                rm -rf "$HOME/.dotfiles_snapshots/$old_snapshot"
                log_maintenance "  - Removed old snapshot: $old_snapshot"
            done
        fi
    fi
}

################################################################################
### Reporting and Notifications
################################################################################

# Generate health report
generate_health_report() {
    local maintenance_id="$1"
    shift
    local failed_tasks=("$@")
    
    local report_data=$(cat << EOF
{
    "maintenance_id": "$maintenance_id",
    "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
    "system_info": {
        "macos_version": "$(sw_vers -productVersion)",
        "architecture": "$(uname -m)",
        "uptime": "$(uptime | awk '{print $3,$4}' | sed 's/,//')"
    },
    "health_status": {
        "overall": "$([ ${#failed_tasks[@]} -eq 0 ] && echo "healthy" || echo "issues_detected")",
        "failed_tasks": [$(printf '"%s",' "${failed_tasks[@]}" | sed 's/,$//')],
        "disk_usage": "$(df / | awk 'NR==2 {print $5}')",
        "available_space": "$(df -h / | awk 'NR==2 {print $4}')"
    },
    "package_status": {
        "outdated_packages": $(brew outdated | wc -l),
        "homebrew_health": "$(brew doctor >/dev/null 2>&1 && echo "healthy" || echo "issues")"
    },
    "cache_status": {
        "cache_size": "$(get_cache_size 2>/dev/null || echo "unknown")",
        "cache_health": "$(check_cache_health >/dev/null 2>&1 && echo "healthy" || echo "issues")"
    }
}
EOF
    )
    
    echo "$report_data" > "$HEALTH_REPORT"
    log_maintenance "📊 Health report generated: $HEALTH_REPORT"
}

# Send maintenance notifications
send_maintenance_notification() {
    local maintenance_id="$1"
    shift
    local failed_tasks=("$@")
    
    if [ "$ENABLE_CONSOLE_NOTIFICATIONS" = "true" ]; then
        if [ ${#failed_tasks[@]} -eq 0 ]; then
            osascript -e 'display notification "Daily maintenance completed successfully" with title "Dotfiles Maintenance"' 2>/dev/null || true
        else
            osascript -e "display notification \"${#failed_tasks[@]} tasks failed during maintenance\" with title \"Dotfiles Maintenance\"" 2>/dev/null || true
        fi
    fi
    
    # Email notification (if configured)
    if [ -n "$NOTIFICATION_EMAIL" ]; then
        send_email_notification "$maintenance_id" "${failed_tasks[@]}"
    fi
    
    # Slack notification (if configured)
    if [ -n "$SLACK_WEBHOOK" ]; then
        send_slack_notification "$maintenance_id" "${failed_tasks[@]}"
    fi
}

################################################################################
### Utility Functions
################################################################################

# Log maintenance activities
log_maintenance() {
    local message="$1"
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    
    # Ensure log directory exists
    mkdir -p "$(dirname "$MAINTENANCE_LOG")"
    
    echo "[$timestamp] $message" | tee -a "$MAINTENANCE_LOG"
}

# Run function with error handling
run_with_error_handling() {
    local function_name="$1"
    
    if "$function_name" 2>&1; then
        return 0
    else
        local exit_code=$?
        log_maintenance "❌ Function failed with exit code $exit_code: $function_name"
        return $exit_code
    fi
}

################################################################################
### Installation and Setup
################################################################################

# Install automated maintenance as launchd daemon
install_maintenance_daemon() {
    local plist_file="$HOME/Library/LaunchAgents/com.dotfiles.maintenance.plist"
    
    echo "⚙️  Installing automated maintenance daemon..."
    
    # Create launchd plist
    cat > "$plist_file" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.dotfiles.maintenance</string>
    <key>ProgramArguments</key>
    <array>
        <string>$SCRIPT_DIR/automated_maintenance.sh</string>
        <string>--daily</string>
    </array>
    <key>StartCalendarInterval</key>
    <dict>
        <key>Hour</key>
        <integer>2</integer>
        <key>Minute</key>
        <integer>0</integer>
    </dict>
    <key>StandardErrorPath</key>
    <string>$HOME/.dotfiles_logs/maintenance_error.log</string>
    <key>StandardOutPath</key>
    <string>$HOME/.dotfiles_logs/maintenance_output.log</string>
</dict>
</plist>
EOF
    
    # Load the daemon
    launchctl load "$plist_file"
    
    echo "✅ Maintenance daemon installed and loaded"
    echo "📅 Daily maintenance will run at 2:00 AM"
}

# Uninstall maintenance daemon
uninstall_maintenance_daemon() {
    local plist_file="$HOME/Library/LaunchAgents/com.dotfiles.maintenance.plist"
    
    if [ -f "$plist_file" ]; then
        launchctl unload "$plist_file"
        rm "$plist_file"
        echo "✅ Maintenance daemon uninstalled"
    else
        echo "❌ Maintenance daemon not found"
    fi
}

################################################################################
### Command Line Interface
################################################################################

show_maintenance_help() {
    cat << 'EOF'
📖 automated_maintenance.sh - Automated maintenance system for dotfiles

DESCRIPTION:
    Provides automated maintenance including package updates, health monitoring,
    cleanup, and proactive issue detection with rollback capabilities.

USAGE:
    automated_maintenance.sh [COMMAND] [OPTIONS]

COMMANDS:
    --daily                 Run daily maintenance routine
    --weekly                Run weekly maintenance routine
    --install-daemon        Install as launchd daemon (runs daily at 2 AM)
    --uninstall-daemon      Uninstall launchd daemon
    --health-check          Run health check only
    --update-packages       Safely update packages with rollback
    --cleanup               Run cleanup tasks only
    --generate-report       Generate health report
    --config               Show/edit maintenance configuration

OPTIONS:
    --dry-run              Show what would be done without executing
    --verbose              Show detailed output
    --help                 Show this help message

EXAMPLES:
    # Run daily maintenance manually
    automated_maintenance.sh --daily
    
    # Install automatic daily maintenance
    automated_maintenance.sh --install-daemon
    
    # Just check health without maintenance
    automated_maintenance.sh --health-check
    
    # Safe package updates only
    automated_maintenance.sh --update-packages

CONFIGURATION:
    Edit ~/.dotfiles_maintenance.config to control:
    - Which tasks run automatically
    - Notification settings
    - Safety and rollback behavior
    - Cleanup schedules and limits

LOGS:
    Maintenance logs: ~/.dotfiles_logs/maintenance.log
    Health reports: ~/.dotfiles_logs/health_report.json

EOF
}

# Main command processor
main() {
    case "${1:-}" in
        --daily)
            init_maintenance
            run_daily_maintenance
            ;;
        --weekly)
            init_maintenance
            run_weekly_maintenance
            ;;
        --install-daemon)
            init_maintenance
            install_maintenance_daemon
            ;;
        --uninstall-daemon)
            uninstall_maintenance_daemon
            ;;
        --health-check)
            init_maintenance
            check_system_health
            ;;
        --update-packages)
            init_maintenance
            update_packages_safely
            ;;
        --cleanup)
            init_maintenance
            cleanup_cache_if_needed
            rotate_logs_if_needed
            cleanup_old_snapshots
            ;;
        --generate-report)
            init_maintenance
            generate_health_report "manual_$(date +%Y%m%d_%H%M%S)"
            ;;
        --config)
            "${EDITOR:-nano}" "$MAINTENANCE_CONFIG_FILE"
            ;;
        --help|-h)
            show_maintenance_help
            ;;
        "")
            echo "Automated maintenance system for dotfiles"
            echo "Use --help for usage information or --install-daemon to set up automatic maintenance"
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
}

# Run main function if script is executed directly
if [ "${BASH_SOURCE[0]:-}" = "${0:-}" ]; then
    main "$@"
fi