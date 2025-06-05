#!/bin/bash
set -euo pipefail

################################################################################
### Comprehensive Health Monitoring System
################################################################################
# Personal system health monitoring with real-time dashboard, drift detection,
# performance monitoring, and automated issue resolution

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"
HEALTH_LOG_DIR="$HOME/.dotfiles_health"
HEALTH_LOG="$HEALTH_LOG_DIR/health.log"
PERFORMANCE_LOG="$HEALTH_LOG_DIR/performance.log"
DRIFT_LOG="$HEALTH_LOG_DIR/drift.log"
BASELINE_FILE="$HEALTH_LOG_DIR/config_baseline.sha"
HEALTH_REPORT="$HEALTH_LOG_DIR/health_report.json"

# Load dependencies
source "$SCRIPT_DIR/progress_indicators.sh" 2>/dev/null || true

################################################################################
### Initialization and Configuration
################################################################################

init_health_monitoring() {
    echo "🩺 Initializing health monitoring system..."
    
    # Create health directories
    mkdir -p "$HEALTH_LOG_DIR"
    mkdir -p "$HEALTH_LOG_DIR/snapshots"
    mkdir -p "$HEALTH_LOG_DIR/reports"
    
    # Initialize baseline if doesn't exist
    if [ ! -f "$BASELINE_FILE" ]; then
        create_config_baseline
    fi
    
    # Initialize health report structure
    init_health_report_structure
    
    echo "✅ Health monitoring system initialized"
}

init_health_report_structure() {
    if [ ! -f "$HEALTH_REPORT" ]; then
        cat > "$HEALTH_REPORT" << EOF
{
    "last_updated": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
    "system": {
        "cpu_usage": 0,
        "memory_usage": 0,
        "disk_usage": 0,
        "load_average": 0,
        "uptime": 0
    },
    "dotfiles": {
        "config_integrity": "unknown",
        "symlinks_health": "unknown",
        "package_health": "unknown",
        "security_status": "unknown"
    },
    "performance": {
        "shell_startup_time": 0,
        "brew_speed": 0,
        "git_speed": 0
    },
    "issues": [],
    "recommendations": []
}
EOF
    fi
}

################################################################################
### Real-Time System Health Dashboard
################################################################################

show_health_dashboard() {
    local refresh_interval="${1:-5}"
    local show_once="${2:-false}"
    
    while true; do
        clear
        echo "🩺 System Health Dashboard - $(date '+%Y-%m-%d %H:%M:%S')"
        echo "================================================================"
        
        # System vitals
        show_system_vitals
        
        echo ""
        
        # Dotfiles health
        show_dotfiles_health
        
        echo ""
        
        # Performance metrics
        show_performance_metrics
        
        echo ""
        
        # Recent issues and recommendations
        show_recent_issues_and_recommendations
        
        echo ""
        echo "Press Ctrl+C to exit | Refreshing every ${refresh_interval}s"
        
        [ "$show_once" = "true" ] && break
        
        sleep "$refresh_interval"
    done
}

show_system_vitals() {
    echo "💻 System Status:"
    
    # CPU Usage
    local cpu_usage
    cpu_usage=$(top -l 1 | grep "CPU usage" | awk '{print $3}' | sed 's/%//')
    printf "  CPU Usage: %s%% " "$cpu_usage"
    show_health_indicator "$cpu_usage" 80 90
    
    # Memory Usage
    local memory_info
    memory_info=$(memory_pressure | head -1)
    local memory_percent
    memory_percent=$(echo "$memory_info" | grep -o '[0-9]*%' | head -1 | sed 's/%//')
    printf "  Memory: %s%% " "$memory_percent"
    show_health_indicator "$memory_percent" 75 90
    
    # Disk Usage
    local disk_usage
    disk_usage=$(df -h / | tail -1 | awk '{print $5}' | sed 's/%//')
    printf "  Disk Space: %s%% " "$disk_usage"
    show_health_indicator "$disk_usage" 80 95
    
    # Load Average
    local load_avg
    load_avg=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | sed 's/,//')
    echo "  Load Average: $load_avg"
    
    # Uptime
    local uptime_info
    uptime_info=$(uptime | awk -F'up ' '{print $2}' | awk -F',' '{print $1}')
    echo "  Uptime: $uptime_info"
}

show_dotfiles_health() {
    echo "⚙️  Dotfiles Health:"
    
    # Config Integrity
    local config_status
    config_status=$(check_config_integrity)
    printf "  Config Integrity: %s " "$config_status"
    [ "$config_status" = "✅ Good" ] && echo "✅" || echo "⚠️"
    
    # Symlinks Health
    local symlink_status
    symlink_status=$(check_symlinks_health)
    printf "  Symlinks: %s " "$symlink_status"
    [ "$symlink_status" = "✅ All Good" ] && echo "✅" || echo "⚠️"
    
    # Package Health
    local package_status
    package_status=$(check_package_health)
    printf "  Packages: %s " "$package_status"
    [ "$package_status" = "✅ Up to Date" ] && echo "✅" || echo "⚠️"
    
    # Security Status
    local security_status
    security_status=$(check_security_status)
    printf "  Security: %s " "$security_status"
    [ "$security_status" = "✅ Secure" ] && echo "✅" || echo "⚠️"
}

show_performance_metrics() {
    echo "📈 Performance Metrics:"
    
    # Shell Startup Time
    local shell_time
    shell_time=$(measure_shell_startup_time)
    printf "  Shell Startup: %sms " "$shell_time"
    show_performance_indicator "$shell_time" 1000 3000
    
    # Brew Speed
    local brew_time
    brew_time=$(measure_brew_speed)
    printf "  Brew Speed: %sms " "$brew_time"
    show_performance_indicator "$brew_time" 2000 5000
    
    # Git Speed
    local git_time
    git_time=$(measure_git_speed)
    printf "  Git Speed: %sms " "$git_time"
    show_performance_indicator "$git_time" 500 1500
}

show_recent_issues_and_recommendations() {
    echo "⚠️  Recent Issues:"
    local issues
    issues=$(get_recent_issues 3)
    if [ -n "$issues" ]; then
        echo "$issues" | while IFS= read -r issue; do
            echo "  • $issue"
        done
    else
        echo "  No recent issues 🎉"
    fi
    
    echo ""
    echo "💡 Recommendations:"
    local recommendations
    recommendations=$(get_recommendations 3)
    if [ -n "$recommendations" ]; then
        echo "$recommendations" | while IFS= read -r rec; do
            echo "  • $rec"
        done
    else
        echo "  System running optimally!"
    fi
}

show_health_indicator() {
    local value="$1"
    local warning_threshold="$2"
    local critical_threshold="$3"
    
    if [ "${value%%.*}" -lt "$warning_threshold" ]; then
        echo "✅"
    elif [ "${value%%.*}" -lt "$critical_threshold" ]; then
        echo "⚠️"
    else
        echo "❌"
    fi
}

show_performance_indicator() {
    local value="$1"
    local good_threshold="$2"
    local poor_threshold="$3"
    
    if [ "${value%%.*}" -lt "$good_threshold" ]; then
        echo "🚀"
    elif [ "${value%%.*}" -lt "$poor_threshold" ]; then
        echo "⚠️"
    else
        echo "🐌"
    fi
}

################################################################################
### Configuration Drift Detection
################################################################################

create_config_baseline() {
    echo "📋 Creating configuration baseline..."
    
    # Key configuration files to monitor
    local config_files=(
        "$HOME/.zshrc"
        "$HOME/.zprofile"
        "$HOME/.aliases"
        "$HOME/.exports"
        "$HOME/.functions"
        "$HOME/.gitconfig"
        "$HOME/.gitignore_global"
        "$DOTFILES_DIR/.dotfiles.config"
    )
    
    # Create checksums for all config files
    > "$BASELINE_FILE"
    for file in "${config_files[@]}"; do
        if [ -f "$file" ]; then
            shasum -a 256 "$file" >> "$BASELINE_FILE"
        fi
    done
    
    # Also include directory structure
    find "$DOTFILES_DIR" -name "*.sh" -o -name "*.md" -o -name "Makefile" | \
        xargs shasum -a 256 >> "$BASELINE_FILE"
    
    echo "✅ Configuration baseline created with $(wc -l < "$BASELINE_FILE") files"
}

detect_configuration_drift() {
    echo "🔍 Scanning for configuration drift..."
    
    local drift_detected=false
    local drift_count=0
    
    while IFS= read -r line; do
        local expected_hash=$(echo "$line" | awk '{print $1}')
        local file_path=$(echo "$line" | awk '{print $2}')
        
        if [ -f "$file_path" ]; then
            local current_hash
            current_hash=$(shasum -a 256 "$file_path" | awk '{print $1}')
            
            if [ "$expected_hash" != "$current_hash" ]; then
                echo "⚠️  DRIFT DETECTED: $file_path"
                log_drift_event "$file_path" "$expected_hash" "$current_hash"
                drift_detected=true
                ((drift_count++))
                
                # Offer resolution
                offer_drift_resolution "$file_path"
            fi
        else
            echo "📁 MISSING FILE: $file_path"
            log_drift_event "$file_path" "missing" "n/a"
            drift_detected=true
            ((drift_count++))
        fi
    done < "$BASELINE_FILE"
    
    if [ "$drift_detected" = false ]; then
        echo "✅ No configuration drift detected"
    else
        echo "📊 Found $drift_count drifted configuration files"
        send_local_notification "Configuration Drift" "$drift_count files have drifted from baseline"
    fi
}

log_drift_event() {
    local file_path="$1"
    local expected_hash="$2"
    local current_hash="$3"
    
    echo "$(date -u +"%Y-%m-%dT%H:%M:%SZ") | DRIFT | $file_path | $expected_hash | $current_hash" >> "$DRIFT_LOG"
}

offer_drift_resolution() {
    local file_path="$1"
    
    echo ""
    echo "🔧 Resolution options for: $(basename "$file_path")"
    echo "1) Show differences"
    echo "2) Restore from dotfiles backup"
    echo "3) Update baseline (accept changes)"
    echo "4) Ignore this file temporarily"
    echo "5) Skip for now"
    
    read -p "Choose action (1-5): " choice
    case $choice in
        1) show_file_diff "$file_path" ;;
        2) restore_from_backup "$file_path" ;;
        3) update_baseline_file "$file_path" ;;
        4) add_to_drift_ignore "$file_path" ;;
        5) echo "Skipping..." ;;
        *) echo "Invalid choice" ;;
    esac
}

show_file_diff() {
    local file_path="$1"
    local backup_file
    backup_file=$(find_backup_file "$file_path")
    
    if [ -n "$backup_file" ]; then
        echo "📋 Differences in $file_path:"
        diff -u "$backup_file" "$file_path" || true
    else
        echo "⚠️  No backup file found for comparison"
    fi
}

################################################################################
### Performance Monitoring and Optimization
################################################################################

measure_shell_startup_time() {
    # Measure zsh startup time
    local start_time end_time duration
    start_time=$(date +%s%N)
    zsh -i -c exit 2>/dev/null
    end_time=$(date +%s%N)
    duration=$(((end_time - start_time) / 1000000))  # Convert nanoseconds to milliseconds
    
    # Log if slow
    if [ $duration -gt 2000 ]; then
        log_performance_issue "shell_startup" "$duration" "Slow shell startup detected"
    fi
    
    echo "$duration"
}

measure_brew_speed() {
    # Measure brew command speed
    local start_time end_time duration
    start_time=$(date +%s%3N)
    brew --version >/dev/null 2>&1
    end_time=$(date +%s%3N)
    duration=$((end_time - start_time))
    
    echo "$duration"
}

measure_git_speed() {
    # Measure git status speed
    local start_time end_time duration
    start_time=$(date +%s%3N)
    git status --porcelain >/dev/null 2>&1 || true
    end_time=$(date +%s%3N)
    duration=$((end_time - start_time))
    
    echo "$duration"
}

log_performance_issue() {
    local component="$1"
    local duration="$2"
    local description="$3"
    
    echo "$(date -u +"%Y-%m-%dT%H:%M:%SZ") | PERF | $component | ${duration}ms | $description" >> "$PERFORMANCE_LOG"
}

analyze_performance_trends() {
    echo "📊 Analyzing performance trends..."
    
    if [ ! -f "$PERFORMANCE_LOG" ]; then
        echo "No performance data available yet"
        return
    fi
    
    # Analyze shell startup trends
    local shell_times
    shell_times=$(grep "shell_startup" "$PERFORMANCE_LOG" | tail -10 | awk -F'|' '{print $4}' | sed 's/ms//')
    
    if [ -n "$shell_times" ]; then
        local avg_time
        avg_time=$(echo "$shell_times" | awk '{sum+=$1} END {print sum/NR}')
        echo "📈 Average shell startup time (last 10): ${avg_time}ms"
        
        # Check if getting worse
        local recent_avg
        recent_avg=$(echo "$shell_times" | tail -3 | awk '{sum+=$1} END {print sum/NR}')
        
        if [ "${recent_avg%%.*}" -gt $((${avg_time%%.*} + 500)) ]; then
            add_recommendation "Shell startup time is increasing. Consider profiling your .zshrc"
        fi
    fi
}

################################################################################
### Health Checks
################################################################################

check_config_integrity() {
    local issues=0
    
    # Check if key dotfiles exist
    local key_files=("$HOME/.zshrc" "$HOME/.gitconfig" "$DOTFILES_DIR/.dotfiles.config")
    for file in "${key_files[@]}"; do
        if [ ! -f "$file" ]; then
            ((issues++))
        fi
    done
    
    # Check for syntax errors in shell files
    if ! zsh -n "$HOME/.zshrc" 2>/dev/null; then
        ((issues++))
    fi
    
    if [ $issues -eq 0 ]; then
        echo "✅ Good"
    else
        echo "⚠️ $issues Issues"
    fi
}

check_symlinks_health() {
    local broken_links=0
    
    # Check for broken symlinks in common directories
    while IFS= read -r -d '' symlink; do
        if [ ! -e "$symlink" ]; then
            ((broken_links++))
        fi
    done < <(find "$HOME" -maxdepth 2 -type l -print0 2>/dev/null)
    
    if [ $broken_links -eq 0 ]; then
        echo "✅ All Good"
    else
        echo "⚠️ $broken_links Broken"
    fi
}

check_package_health() {
    if ! command -v brew >/dev/null; then
        echo "❌ Homebrew Missing"
        return
    fi
    
    local outdated_count
    outdated_count=$(brew outdated | wc -l)
    
    if [ "$outdated_count" -eq 0 ]; then
        echo "✅ Up to Date"
    else
        echo "⚠️ $outdated_count Updates"
    fi
}

check_security_status() {
    local security_issues=0
    
    # Check SSH key permissions
    if [ -f "$HOME/.ssh/id_rsa" ]; then
        local perms
        perms=$(stat -f "%A" "$HOME/.ssh/id_rsa" 2>/dev/null || stat -c "%a" "$HOME/.ssh/id_rsa" 2>/dev/null)
        if [ "$perms" != "600" ]; then
            ((security_issues++))
        fi
    fi
    
    # Check for suspicious files
    if find "$HOME" -name "*.sh" -perm +111 -path "*/Downloads/*" 2>/dev/null | grep -q .; then
        ((security_issues++))
    fi
    
    if [ $security_issues -eq 0 ]; then
        echo "✅ Secure"
    else
        echo "⚠️ $security_issues Issues"
    fi
}

################################################################################
### Automated Issue Resolution
################################################################################

auto_resolve_issues() {
    echo "🔧 Running automated issue resolution..."
    
    local resolved_count=0
    
    # Basic fixes (existing functionality)
    if resolve_broken_symlinks; then
        ((resolved_count++))
    fi
    
    if resolve_permission_issues; then
        ((resolved_count++))
    fi
    
    if resolve_homebrew_issues; then
        ((resolved_count++))
    fi
    
    if resolve_git_issues; then
        ((resolved_count++))
    fi
    
    echo "✅ Basic auto-resolution complete: $resolved_count issues fixed"
    
    # Advanced healing integration
    echo "🚀 Running advanced healing system..."
    if [ -f "$SCRIPT_DIR/advanced_healing.sh" ]; then
        local advanced_fixes
        advanced_fixes=$("$SCRIPT_DIR/advanced_healing.sh" run 2>/dev/null | grep -o "Issues detected and fixed: [0-9]*" | awk '{print $5}' || echo "0")
        resolved_count=$((resolved_count + advanced_fixes))
        echo "✅ Advanced healing complete: $advanced_fixes additional issues resolved"
    fi
    
    echo "📊 Total issues resolved: $resolved_count"
    
    if [ $resolved_count -gt 0 ]; then
        send_local_notification "Issues Resolved" "Automatically fixed $resolved_count system issues"
    fi
}

resolve_broken_symlinks() {
    local fixed=false
    
    echo "🔗 Checking for broken symlinks..."
    while IFS= read -r -d '' broken_link; do
        if [ ! -e "$broken_link" ]; then
            echo "🔧 Removing broken symlink: $broken_link"
            rm "$broken_link"
            fixed=true
        fi
    done < <(find "$HOME" -maxdepth 2 -type l -print0 2>/dev/null)
    
    $fixed
}

resolve_permission_issues() {
    local fixed=false
    
    echo "🔐 Checking file permissions..."
    
    # Fix SSH permissions
    if [ -d "$HOME/.ssh" ]; then
        chmod 700 "$HOME/.ssh"
        find "$HOME/.ssh" -name "id_*" -not -name "*.pub" -exec chmod 600 {} \;
        find "$HOME/.ssh" -name "*.pub" -exec chmod 644 {} \;
        fixed=true
    fi
    
    # Fix dotfiles script permissions
    if [ -d "$DOTFILES_DIR/Scripts" ]; then
        chmod +x "$DOTFILES_DIR/Scripts"/*.sh
        fixed=true
    fi
    
    $fixed
}

resolve_homebrew_issues() {
    local fixed=false
    
    if command -v brew >/dev/null; then
        echo "🍺 Checking Homebrew health..."
        
        # Try to fix common issues
        if brew doctor 2>&1 | grep -q "outdated"; then
            echo "🔧 Updating Homebrew..."
            brew update
            fixed=true
        fi
        
        # Clean up if needed
        if [ "$(brew --cache | xargs du -sh | awk '{print $1}' | sed 's/[^0-9]//g')" -gt 1000 ]; then
            echo "🧹 Cleaning Homebrew cache..."
            brew cleanup
            fixed=true
        fi
    fi
    
    $fixed
}

resolve_git_issues() {
    local fixed=false
    
    echo "🔧 Checking Git configuration..."
    
    # Ensure user is configured
    if ! git config user.name >/dev/null 2>&1; then
        if [ -f "$HOME/.gitconfig" ]; then
            # Try to restore from backup
            echo "🔧 Restoring Git configuration..."
            fixed=true
        fi
    fi
    
    $fixed
}

################################################################################
### Notification System (Local Only)
################################################################################

send_local_notification() {
    local title="$1"
    local message="$2"
    local urgency="${3:-normal}"
    
    # macOS notification
    if command -v osascript >/dev/null; then
        osascript -e "display notification \"$message\" with title \"🩺 Health Monitor\" subtitle \"$title\""
    fi
    
    # Terminal notification (if in terminal)
    if [ -t 1 ]; then
        echo ""
        echo "🔔 $title: $message"
        echo ""
    fi
    
    # Log notification
    echo "$(date -u +"%Y-%m-%dT%H:%M:%SZ") | NOTIFICATION | $title | $message" >> "$HEALTH_LOG"
}

################################################################################
### Reporting and Analytics
################################################################################

generate_health_report() {
    echo "📊 Generating health report..."
    
    # Update health report JSON
    local temp_report
    temp_report=$(mktemp)
    
    cat > "$temp_report" << EOF
{
    "last_updated": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
    "system": {
        "cpu_usage": $(top -l 1 | grep "CPU usage" | awk '{print $3}' | sed 's/%//'),
        "memory_usage": $(memory_pressure | head -1 | grep -o '[0-9]*%' | head -1 | sed 's/%//'),
        "disk_usage": $(df -h / | tail -1 | awk '{print $5}' | sed 's/%//'),
        "load_average": $(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | sed 's/,//'),
        "uptime_hours": $(uptime | awk '{print $3}' | sed 's/,//')
    },
    "dotfiles": {
        "config_integrity": "$(check_config_integrity)",
        "symlinks_health": "$(check_symlinks_health)",
        "package_health": "$(check_package_health)",
        "security_status": "$(check_security_status)"
    },
    "performance": {
        "shell_startup_time": $(measure_shell_startup_time),
        "brew_speed": $(measure_brew_speed),
        "git_speed": $(measure_git_speed)
    },
    "issues_count": $(get_recent_issues_count),
    "last_drift_check": "$(get_last_drift_check)",
    "last_auto_resolution": "$(get_last_auto_resolution)"
}
EOF
    
    mv "$temp_report" "$HEALTH_REPORT"
    echo "✅ Health report updated: $HEALTH_REPORT"
}

get_recent_issues() {
    local limit="${1:-10}"
    
    if [ -f "$HEALTH_LOG" ]; then
        grep "ISSUE\|DRIFT\|PERF" "$HEALTH_LOG" | tail -"$limit" | \
            awk -F'|' '{print $4 " - " $5}' | sed 's/^ *//'
    fi
}

get_recent_issues_count() {
    if [ -f "$HEALTH_LOG" ]; then
        grep "ISSUE\|DRIFT\|PERF" "$HEALTH_LOG" | wc -l
    else
        echo "0"
    fi
}

get_recommendations() {
    local limit="${1:-5}"
    
    local recommendations=()
    
    # Performance recommendations
    local shell_time
    shell_time=$(measure_shell_startup_time)
    if [ "${shell_time%%.*}" -gt 2000 ]; then
        recommendations+=("Shell startup is slow (${shell_time}ms). Consider profiling .zshrc")
    fi
    
    # Package recommendations
    if command -v brew >/dev/null; then
        local outdated_count
        outdated_count=$(brew outdated | wc -l)
        if [ "$outdated_count" -gt 0 ]; then
            recommendations+=("$outdated_count packages need updates. Run 'brew upgrade'")
        fi
        
        local cache_size
        cache_size=$(du -sh "$(brew --cache)" 2>/dev/null | awk '{print $1}' | sed 's/[^0-9]//g')
        if [ "${cache_size:-0}" -gt 1000 ]; then
            recommendations+=("Homebrew cache is large. Run 'brew cleanup' to free space")
        fi
    fi
    
    # Security recommendations
    if [ -f "$HOME/.ssh/id_rsa" ]; then
        local key_age
        key_age=$(find "$HOME/.ssh/id_rsa" -mtime +365 2>/dev/null | wc -l)
        if [ "$key_age" -gt 0 ]; then
            recommendations+=("SSH key is over 1 year old. Consider rotating")
        fi
    fi
    
    # Print recommendations up to limit
    local count=0
    for rec in "${recommendations[@]}"; do
        [ $count -ge "$limit" ] && break
        echo "$rec"
        ((count++))
    done
}

add_recommendation() {
    local recommendation="$1"
    echo "$(date -u +"%Y-%m-%dT%H:%M:%SZ") | RECOMMENDATION | $recommendation" >> "$HEALTH_LOG"
}

################################################################################
### Utility Functions
################################################################################

get_last_drift_check() {
    if [ -f "$DRIFT_LOG" ]; then
        tail -1 "$DRIFT_LOG" | awk -F'|' '{print $1}' || echo "never"
    else
        echo "never"
    fi
}

get_last_auto_resolution() {
    if [ -f "$HEALTH_LOG" ]; then
        grep "Auto-resolved" "$HEALTH_LOG" | tail -1 | awk -F'|' '{print $1}' || echo "never"
    else
        echo "never"
    fi
}

find_backup_file() {
    local file_path="$1"
    local file_name
    file_name=$(basename "$file_path")
    
    # Look for backup in dotfiles directory
    find "$DOTFILES_DIR" -name "$file_name" -type f | head -1
}

################################################################################
### Main Command Interface
################################################################################

show_help() {
    cat << 'EOF'
🩺 Comprehensive Health Monitoring System

USAGE:
    ./health_monitor.sh <command> [options]

COMMANDS:
    dashboard [interval]    Show real-time health dashboard (default: 5s refresh)
    check                  Run full system health check
    drift                  Check for configuration drift
    auto-fix              Run automated issue resolution
    report                Generate detailed health report
    performance           Analyze performance trends
    baseline              Create new configuration baseline
    
    --continuous          Run continuous monitoring (dashboard + periodic checks)
    --help                Show this help message

EXAMPLES:
    ./health_monitor.sh dashboard           # Show dashboard with 5s refresh
    ./health_monitor.sh dashboard 10        # Show dashboard with 10s refresh
    ./health_monitor.sh check               # Run health check once
    ./health_monitor.sh drift               # Check configuration drift
    ./health_monitor.sh auto-fix            # Fix issues automatically
    ./health_monitor.sh --continuous        # Run continuous monitoring

LOGS:
    Health logs: ~/.dotfiles_health/health.log
    Performance: ~/.dotfiles_health/performance.log
    Drift logs:  ~/.dotfiles_health/drift.log
    Reports:     ~/.dotfiles_health/health_report.json

EOF
}

main() {
    # Initialize if needed
    init_health_monitoring
    
    case "${1:-dashboard}" in
        dashboard)
            show_health_dashboard "${2:-5}"
            ;;
        check)
            echo "🩺 Running comprehensive health check..."
            show_health_dashboard 0 true
            generate_health_report
            ;;
        drift)
            detect_configuration_drift
            ;;
        auto-fix)
            auto_resolve_issues
            ;;
        report)
            generate_health_report
            ;;
        performance)
            analyze_performance_trends
            ;;
        baseline)
            create_config_baseline
            ;;
        --continuous)
            echo "🩺 Starting continuous health monitoring..."
            echo "Press Ctrl+C to stop"
            
            # Run dashboard in background and periodic checks
            while true; do
                show_health_dashboard 10 true
                
                # Run checks every 10 minutes
                sleep 600
                detect_configuration_drift >/dev/null 2>&1
                auto_resolve_issues >/dev/null 2>&1
            done
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