#!/bin/bash

set -euo pipefail

################################################################################
### Progress Indicators Library
################################################################################

# This library provides various progress indicators for long-running operations
# including progress bars, spinners, and real-time status dashboards

# Global variables for progress tracking
# Using associative arrays with bash 4+ compatibility check
if [[ "${BASH_VERSION:-3}" =~ ^[0-9]+\.[0-9]+ ]] && [[ ${BASH_VERSION%%.*} -ge 4 ]]; then
    declare -A PROGRESS_STATE=()
    declare -A PROGRESS_TOTAL=()
    declare -A PROGRESS_CURRENT=()
    declare -A PROGRESS_MESSAGE=()
    PROGRESS_ASSOCIATIVE_AVAILABLE=true
else
    # Fallback for older bash versions
    PROGRESS_ASSOCIATIVE_AVAILABLE=false
fi
PROGRESS_OPERATIONS=()

################################################################################
### Progress Bar Functions
################################################################################

# Show a progress bar with percentage
show_progress_bar() {
    local current=$1
    local total=$2
    local message="${3:-Processing}"
    local width=50
    
    # Calculate percentage and filled portion
    local percentage=$((current * 100 / total))
    local filled=$((current * width / total))
    local empty=$((width - filled))
    
    # Create progress bar
    printf "\r🔄 %s [" "$message"
    printf "%*s" $filled | tr ' ' '█'
    printf "%*s" $empty | tr ' ' '░'
    printf "] %d%% (%d/%d)" $percentage $current $total
    
    # Add newline if complete
    if [ $current -eq $total ]; then
        printf "\n"
    fi
}

# Progress bar for array operations
progress_array() {
    local array_name=$1
    local operation_function=$2
    local message_prefix="${3:-Processing}"
    
    # Get array contents using eval for compatibility
    local array_contents
    eval "array_contents=(\"\${${array_name}[@]}\")"
    local total=${#array_contents[@]}
    
    echo "📊 $message_prefix ($total items)"
    
    for i in "${!array_contents[@]}"; do
        local item="${array_contents[i]}"
        show_progress_bar $((i+1)) $total "$message_prefix $item"
        
        # Execute the operation
        $operation_function "$item"
    done
    
    echo "✅ $message_prefix completed"
}

# Estimated time remaining calculator
calculate_eta() {
    local start_time=$1
    local current=$2
    local total=$3
    
    if [ $current -eq 0 ]; then
        echo "calculating..."
        return
    fi
    
    local elapsed=$(($(date +%s) - start_time))
    local rate=$((current * 1000 / elapsed))  # items per second * 1000
    local remaining=$((total - current))
    local eta_seconds=$((remaining * 1000 / rate))
    
    if [ $eta_seconds -lt 60 ]; then
        echo "${eta_seconds}s"
    elif [ $eta_seconds -lt 3600 ]; then
        echo "$((eta_seconds / 60))m $((eta_seconds % 60))s"
    else
        local hours=$((eta_seconds / 3600))
        local minutes=$(((eta_seconds % 3600) / 60))
        echo "${hours}h ${minutes}m"
    fi
}

# Enhanced progress bar with ETA
show_progress_bar_with_eta() {
    local current=$1
    local total=$2
    local message="$3"
    local start_time=$4
    local width=40
    
    # Calculate percentage and filled portion
    local percentage=$((current * 100 / total))
    local filled=$((current * width / total))
    local empty=$((width - filled))
    
    # Calculate ETA
    local eta=$(calculate_eta "$start_time" "$current" "$total")
    
    # Create progress bar with ETA
    printf "\r🔄 %s [" "$message"
    printf "%*s" $filled | tr ' ' '█'
    printf "%*s" $empty | tr ' ' '░'
    printf "] %d%% (%d/%d) ETA: %s" $percentage $current $total "$eta"
    
    # Add newline if complete
    if [ $current -eq $total ]; then
        printf "\n"
    fi
}

################################################################################
### Spinner Functions
################################################################################

# Simple spinner for indeterminate operations
show_spinner() {
    local pid=$1
    local message="${2:-Working}"
    local spin='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    local i=0
    
    while kill -0 $pid 2>/dev/null; do
        local char="${spin:$((i%10)):1}"
        printf "\r%s %s" "$char" "$message"
        sleep 0.1
        i=$((i+1))
    done
    
    printf "\r✅ %s completed\n" "$message"
}

# Bouncing dots spinner
show_dots_spinner() {
    local pid=$1
    local message="${2:-Working}"
    local dots=("⠋" "⠙" "⠚" "⠞" "⠖" "⠦" "⠴" "⠲" "⠳" "⠓")
    local i=0
    
    while kill -0 $pid 2>/dev/null; do
        printf "\r%s %s" "${dots[$((i%10))]}" "$message"
        sleep 0.1
        i=$((i+1))
    done
    
    printf "\r✅ %s completed\n" "$message"
}

# Clock spinner
show_clock_spinner() {
    local pid=$1
    local message="${2:-Working}"
    local clock=("🕐" "🕑" "🕒" "🕓" "🕔" "🕕" "🕖" "🕗" "🕘" "🕙" "🕚" "🕛")
    local i=0
    
    while kill -0 $pid 2>/dev/null; do
        printf "\r%s %s" "${clock[$((i%12))]}" "$message"
        sleep 0.25
        i=$((i+1))
    done
    
    printf "\r✅ %s completed\n" "$message"
}

################################################################################
### Multi-Operation Dashboard
################################################################################

# Initialize progress dashboard
init_progress_dashboard() {
    # Clear screen and hide cursor
    clear
    tput civis
    
    echo "🚀 Dotfiles Setup Progress Dashboard"
    echo "====================================="
    echo ""
}

# Update dashboard with current status
update_progress_dashboard() {
    local operations=("$@")
    
    # Move cursor to dashboard area (line 4)
    tput cup 3 0
    
    echo "📊 Operation Status:"
    echo "-------------------"
    
    for operation in "${operations[@]}"; do
        local status="pending"
        local current="0"
        local total="1"
        local message="$operation"
        
        if [ "$PROGRESS_ASSOCIATIVE_AVAILABLE" = true ]; then
            status="${PROGRESS_STATE[$operation]:-pending}"
            current="${PROGRESS_CURRENT[$operation]:-0}"
            total="${PROGRESS_TOTAL[$operation]:-1}"
            message="${PROGRESS_MESSAGE[$operation]:-$operation}"
        fi
        
        local icon="⏳"
        local progress_info=""
        
        case "$status" in
            "pending")
                icon="⏳"
                progress_info="Waiting to start"
                ;;
            "running")
                icon="🔄"
                if [ "$total" -gt 1 ]; then
                    local percentage=$((current * 100 / total))
                    progress_info="$percentage% ($current/$total)"
                else
                    progress_info="In progress..."
                fi
                ;;
            "completed")
                icon="✅"
                progress_info="Completed"
                ;;
            "failed")
                icon="❌"
                progress_info="Failed"
                ;;
        esac
        
        printf "  %s %-25s %s\n" "$icon" "$message" "$progress_info"
    done
    
    echo ""
    echo "🕐 Started: $(date '+%H:%M:%S')"
    
    # Calculate overall progress
    local total_ops=${#operations[@]}
    local completed_ops=0
    
    for operation in "${operations[@]}"; do
        local op_status="pending"
        if [ "$PROGRESS_ASSOCIATIVE_AVAILABLE" = true ]; then
            op_status="${PROGRESS_STATE[$operation]:-pending}"
        fi
        
        if [ "$op_status" = "completed" ]; then
            completed_ops=$((completed_ops + 1))
        fi
    done
    
    local overall_percentage=$((completed_ops * 100 / total_ops))
    echo "📈 Overall Progress: $overall_percentage% ($completed_ops/$total_ops operations)"
    
    # Estimate remaining time
    if [ $completed_ops -gt 0 ] && [ $completed_ops -lt $total_ops ]; then
        echo "⏱️  Estimated time remaining: calculating..."
    fi
}

# Set operation status
set_operation_status() {
    local operation="$1"
    local status="$2"
    local current="${3:-0}"
    local total="${4:-1}"
    local message="${5:-$operation}"
    
    if [ "$PROGRESS_ASSOCIATIVE_AVAILABLE" = true ]; then
        PROGRESS_STATE["$operation"]="$status"
        PROGRESS_CURRENT["$operation"]="$current"
        PROGRESS_TOTAL["$operation"]="$total"
        PROGRESS_MESSAGE["$operation"]="$message"
    fi
}

# Cleanup dashboard
cleanup_progress_dashboard() {
    # Show cursor
    tput cnorm
    echo ""
    echo "🎉 Setup completed!"
}

################################################################################
### Real-Time Progress Monitoring
################################################################################

# Monitor parallel operations with real-time updates
monitor_parallel_operations() {
    local operations=("$@")
    local start_time=$(date +%s)
    
    init_progress_dashboard
    
    # Initialize all operations as pending
    for operation in "${operations[@]}"; do
        set_operation_status "$operation" "pending" 0 1 "$operation"
    done
    
    # Monitor loop
    while true; do
        local all_complete=true
        
        # Update status for each operation
        for operation in "${operations[@]}"; do
            # Check if operation is complete (this would be provided by parallel system)
            if command -v "check_${operation}_status" >/dev/null 2>&1; then
                local status_info=$("check_${operation}_status")
                # Parse status_info and update accordingly
                set_operation_status "$operation" "running" 0 1 "$operation"
            fi
            
            # Check if any operation is still running
            local op_status="pending"
            if [ "$PROGRESS_ASSOCIATIVE_AVAILABLE" = true ]; then
                op_status="${PROGRESS_STATE[$operation]:-pending}"
            fi
            
            if [ "$op_status" != "completed" ] && [ "$op_status" != "failed" ]; then
                all_complete=false
            fi
        done
        
        # Update dashboard
        update_progress_dashboard "${operations[@]}"
        
        # Check if all operations are complete
        if [ "$all_complete" = true ]; then
            break
        fi
        
        sleep 2
    done
    
    cleanup_progress_dashboard
}

################################################################################
### Package Installation Progress
################################################################################

# Progress-aware package installer
install_packages_with_progress() {
    local package_type="$1"
    shift
    local packages=("$@")
    local total=${#packages[@]}
    local start_time=$(date +%s)
    
    echo "📦 Installing $total $package_type packages..."
    
    for i in "${!packages[@]}"; do
        local package="${packages[i]}"
        local current=$((i + 1))
        
        show_progress_bar_with_eta "$current" "$total" "Installing $package" "$start_time"
        
        case "$package_type" in
            "formula")
                brew install "$package" >/dev/null 2>&1
                ;;
            "cask")
                brew install --cask "$package" >/dev/null 2>&1
                ;;
            "mas")
                mas install "$package" >/dev/null 2>&1
                ;;
        esac
    done
    
    echo "✅ All $package_type packages installed successfully"
}

# Download with progress
download_with_progress() {
    local url="$1"
    local output_file="$2"
    local description="${3:-Downloading}"
    
    echo "📥 $description..."
    
    # Use curl with progress bar
    curl -L --progress-bar "$url" -o "$output_file"
    
    echo "✅ Download completed: $output_file"
}

################################################################################
### Integration Functions
################################################################################

# Wrapper for long-running commands with spinner
run_with_spinner() {
    local command="$1"
    local message="${2:-Running command}"
    
    # Run command in background
    $command >/dev/null 2>&1 &
    local pid=$!
    
    # Show spinner while command runs
    show_spinner "$pid" "$message"
    
    # Wait for command and get exit status
    wait "$pid"
    return $?
}

# Wrapper for operations with progress tracking
run_with_progress() {
    local operation_name="$1"
    local operation_function="$2"
    local total_steps="${3:-1}"
    
    echo "🚀 Starting: $operation_name"
    set_operation_status "$operation_name" "running" 0 "$total_steps" "$operation_name"
    
    if $operation_function; then
        set_operation_status "$operation_name" "completed" "$total_steps" "$total_steps" "$operation_name"
        echo "✅ Completed: $operation_name"
        return 0
    else
        set_operation_status "$operation_name" "failed" 0 "$total_steps" "$operation_name"
        echo "❌ Failed: $operation_name"
        return 1
    fi
}

################################################################################
### Help Documentation
################################################################################

show_progress_help() {
    cat << 'EOF'
📖 progress_indicators.sh - Progress indication and monitoring library

DESCRIPTION:
    Provides comprehensive progress indicators for long-running dotfiles
    setup operations including progress bars, spinners, and dashboards.

PROGRESS BARS:
    show_progress_bar              Simple progress bar
    show_progress_bar_with_eta     Progress bar with time estimation
    progress_array                 Progress bar for array operations

SPINNERS:
    show_spinner                   Basic spinner animation
    show_dots_spinner             Dots animation
    show_clock_spinner            Clock animation

DASHBOARD:
    init_progress_dashboard        Initialize real-time dashboard
    update_progress_dashboard      Update dashboard status
    monitor_parallel_operations    Monitor multiple operations

UTILITIES:
    install_packages_with_progress Package installation with progress
    download_with_progress         File download with progress
    run_with_spinner              Wrap commands with spinner
    run_with_progress             Wrap operations with tracking

EXAMPLES:
    # Progress bar
    for i in {1..10}; do
        show_progress_bar $i 10 "Processing items"
        sleep 1
    done
    
    # Spinner for background task
    long_running_command &
    show_spinner $! "Working on something"
    
    # Package installation
    packages=(git age jq)
    install_packages_with_progress "formula" "${packages[@]}"

EOF
}

# Show help if script is run directly
if [ "${BASH_SOURCE[0]:-}" = "${0:-}" ]; then
    if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
        show_progress_help
    else
        echo "This is a library file. Source it to use progress functions."
        echo "Use --help for more information."
    fi
fi