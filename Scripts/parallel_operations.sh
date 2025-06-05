#!/bin/bash

set -euo pipefail

################################################################################
### Parallel Operations Management Library
################################################################################

# This library provides functions for running operations in parallel
# with proper dependency management and error handling

# Global variables for parallel execution
declare -a PARALLEL_PIDS=()
declare -a PARALLEL_OPERATIONS=()
declare -A PARALLEL_STATUS=()
declare -A PARALLEL_LOGS=()

################################################################################
### Core Parallel Functions
################################################################################

# Initialize parallel execution system
init_parallel() {
    PARALLEL_PIDS=()
    PARALLEL_OPERATIONS=()
    PARALLEL_STATUS=()
    PARALLEL_LOGS=()
    
    # Create log directory for parallel operations
    mkdir -p "$HOME/.dotfiles_logs/parallel"
}

# Add operation to parallel queue
queue_parallel_operation() {
    local operation_name="$1"
    local operation_function="$2"
    local log_file="$HOME/.dotfiles_logs/parallel/${operation_name}.log"
    
    PARALLEL_OPERATIONS+=("$operation_name")
    PARALLEL_STATUS["$operation_name"]="queued"
    PARALLEL_LOGS["$operation_name"]="$log_file"
    
    echo "📋 Queued parallel operation: $operation_name"
}

# Start a parallel operation
start_parallel_operation() {
    local operation_name="$1"
    local operation_function="$2"
    local log_file="${PARALLEL_LOGS[$operation_name]}"
    
    echo "🚀 Starting parallel operation: $operation_name"
    PARALLEL_STATUS["$operation_name"]="running"
    
    # Run operation in background with logging
    {
        echo "=== $operation_name started at $(date) ===" > "$log_file"
        if $operation_function >> "$log_file" 2>&1; then
            echo "=== $operation_name completed successfully at $(date) ===" >> "$log_file"
            echo "success" > "${log_file}.status"
        else
            echo "=== $operation_name failed at $(date) ===" >> "$log_file"
            echo "failed" > "${log_file}.status"
        fi
    } &
    
    local pid=$!
    PARALLEL_PIDS+=("$pid")
    PARALLEL_STATUS["$operation_name"]="running:$pid"
    
    echo "📍 Operation $operation_name started with PID $pid"
}

# Check if an operation is complete
is_operation_complete() {
    local operation_name="$1"
    local status="${PARALLEL_STATUS[$operation_name]}"
    
    if [[ "$status" == "running:"* ]]; then
        local pid="${status#running:}"
        if ! kill -0 "$pid" 2>/dev/null; then
            # Process finished, check status
            local log_file="${PARALLEL_LOGS[$operation_name]}"
            if [ -f "${log_file}.status" ]; then
                local result=$(cat "${log_file}.status")
                PARALLEL_STATUS["$operation_name"]="$result"
                return 0
            else
                PARALLEL_STATUS["$operation_name"]="unknown"
                return 0
            fi
        fi
        return 1  # Still running
    else
        return 0  # Already complete
    fi
}

# Wait for all parallel operations to complete
wait_for_all_operations() {
    echo "⏳ Waiting for all parallel operations to complete..."
    
    local all_complete=false
    while [ "$all_complete" = false ]; do
        all_complete=true
        
        for operation in "${PARALLEL_OPERATIONS[@]}"; do
            if ! is_operation_complete "$operation"; then
                all_complete=false
                break
            fi
        done
        
        if [ "$all_complete" = false ]; then
            sleep 1
        fi
    done
    
    echo "✅ All parallel operations completed"
}

# Get status of all operations
get_operations_status() {
    echo "📊 Parallel Operations Status:"
    echo "=============================="
    
    for operation in "${PARALLEL_OPERATIONS[@]}"; do
        local status="${PARALLEL_STATUS[$operation]}"
        local icon="❓"
        
        case "$status" in
            "queued") icon="⏳" ;;
            "running:"*) icon="🔄" ;;
            "success") icon="✅" ;;
            "failed") icon="❌" ;;
            "unknown") icon="⚠️" ;;
        esac
        
        printf "  %s %s: %s\n" "$icon" "$operation" "$status"
    done
}

# Show logs for failed operations
show_failed_operations() {
    local has_failures=false
    
    for operation in "${PARALLEL_OPERATIONS[@]}"; do
        if [ "${PARALLEL_STATUS[$operation]}" = "failed" ]; then
            if [ "$has_failures" = false ]; then
                echo "❌ Failed Operations Logs:"
                echo "=========================="
                has_failures=true
            fi
            
            echo ""
            echo "--- $operation ---"
            local log_file="${PARALLEL_LOGS[$operation]}"
            if [ -f "$log_file" ]; then
                tail -20 "$log_file"
            else
                echo "No log file found"
            fi
        fi
    done
    
    return $has_failures
}

################################################################################
### High-Level Parallel Execution Functions
################################################################################

# Run operations with dependency management
run_parallel_with_dependencies() {
    local -A dependencies=()
    
    # Define operation dependencies
    dependencies["homebrew_formulas"]="homebrew_install"
    dependencies["homebrew_casks"]="homebrew_install"
    dependencies["mas_apps"]="homebrew_install"
    dependencies["ruby_gems"]="homebrew_formulas"  # Needs rbenv from formulas
    dependencies["python_packages"]="homebrew_formulas"  # Needs pyenv from formulas
    
    echo "🔄 Starting parallel execution with dependency management..."
    
    init_parallel
    
    # Phase 1: Independent setup operations
    echo "📋 Phase 1: Core setup operations"
    queue_parallel_operation "symlinks" "parallel_setup_symlinks"
    queue_parallel_operation "user_defaults" "parallel_setup_user_defaults"
    queue_parallel_operation "terminal_config" "parallel_setup_terminal"
    
    # Start Phase 1 operations
    for operation in symlinks user_defaults terminal_config; do
        start_parallel_operation "$operation" "parallel_${operation//_/}"
    done
    
    # Phase 2: Homebrew installation (prerequisite for package installs)
    echo "📋 Phase 2: Homebrew installation"
    queue_parallel_operation "homebrew_install" "parallel_install_homebrew"
    start_parallel_operation "homebrew_install" "parallel_install_homebrew"
    
    # Wait for Homebrew to be ready
    wait_for_operation "homebrew_install"
    
    # Phase 3: Package installations (can run in parallel)
    echo "📋 Phase 3: Package installations"
    queue_parallel_operation "homebrew_formulas" "parallel_install_formulas"
    queue_parallel_operation "homebrew_casks" "parallel_install_casks"
    queue_parallel_operation "quicklook_plugins" "parallel_install_quicklook"
    queue_parallel_operation "mas_apps" "parallel_install_mas_apps"
    
    # Start Phase 3 operations
    for operation in homebrew_formulas homebrew_casks quicklook_plugins mas_apps; do
        start_parallel_operation "$operation" "parallel_${operation//_/}"
    done
    
    # Phase 4: Language-specific packages (depend on Phase 3)
    echo "📋 Phase 4: Language-specific packages"
    wait_for_operation "homebrew_formulas"  # Wait for rbenv, pyenv
    
    queue_parallel_operation "ruby_gems" "parallel_install_ruby_gems"
    queue_parallel_operation "python_packages" "parallel_install_python_packages"
    
    start_parallel_operation "ruby_gems" "parallel_install_ruby_gems"
    start_parallel_operation "python_packages" "parallel_install_python_packages"
    
    # Wait for all operations to complete
    wait_for_all_operations
    
    # Report results
    get_operations_status
    
    if show_failed_operations; then
        echo "⚠️  Some operations failed. Check logs above."
        return 1
    else
        echo "🎉 All parallel operations completed successfully!"
        return 0
    fi
}

# Wait for specific operation to complete
wait_for_operation() {
    local operation_name="$1"
    
    echo "⏳ Waiting for $operation_name to complete..."
    
    while ! is_operation_complete "$operation_name"; do
        sleep 1
    done
    
    local status="${PARALLEL_STATUS[$operation_name]}"
    if [ "$status" = "success" ]; then
        echo "✅ $operation_name completed successfully"
        return 0
    else
        echo "❌ $operation_name failed"
        return 1
    fi
}

################################################################################
### Parallel Operation Implementations
################################################################################

# Parallel symlink setup
parallel_setup_symlinks() {
    echo "🔗 Setting up symlinks..."
    source Scripts/set_up_symlinks.sh
}

# Parallel user defaults setup
parallel_setup_user_defaults() {
    echo "⚙️ Configuring user defaults..."
    source Scripts/set_up_user_defaults.sh
}

# Parallel terminal setup
parallel_setup_terminal() {
    echo "🖥️ Setting up terminal..."
    source Terminal/set_up_terminal.sh
}

# Parallel Homebrew installation
parallel_install_homebrew() {
    echo "🍺 Installing Homebrew..."
    
    # Load configuration
    if [ -f Scripts/config_parser.sh ]; then
        source Scripts/config_parser.sh
        load_dotfiles_config
    fi
    
    # Check if should skip
    if [ "${SKIP_HOMEBREW:-false}" = "true" ]; then
        echo "⏭️ Skipping Homebrew installation (configured)"
        return 0
    fi
    
    # Install if not present
    if ! command -v brew >/dev/null 2>&1; then
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    
    # Update Homebrew
    brew update
}

# Parallel formula installation
parallel_install_formulas() {
    echo "📦 Installing Homebrew formulas..."
    
    # Load configuration
    if [ -f Scripts/config_parser.sh ]; then
        source Scripts/config_parser.sh
        load_dotfiles_config
    fi
    
    # Get formulas from config
    if command -v get_homebrew_formulas >/dev/null 2>&1; then
        local formulas=($(get_homebrew_formulas))
    else
        local formulas=(age git jq)  # Fallback
    fi
    
    if [ ${#formulas[@]} -gt 0 ]; then
        brew install "${formulas[@]}"
    fi
}

# Parallel cask installation
parallel_install_casks() {
    echo "📱 Installing Homebrew casks..."
    
    # Load configuration
    if [ -f Scripts/config_parser.sh ]; then
        source Scripts/config_parser.sh
        load_dotfiles_config
    fi
    
    # Get casks from config
    if command -v get_homebrew_casks >/dev/null 2>&1; then
        local casks=($(get_homebrew_casks))
    else
        local casks=()  # Fallback to empty
    fi
    
    if [ ${#casks[@]} -gt 0 ]; then
        brew install --cask "${casks[@]}"
    fi
}

# Parallel QuickLook plugin installation
parallel_install_quicklook() {
    echo "👁️ Installing QuickLook plugins..."
    
    # Load configuration
    if [ -f Scripts/config_parser.sh ]; then
        source Scripts/config_parser.sh
        load_dotfiles_config
    fi
    
    # Get plugins from config
    if command -v get_quicklook_plugins >/dev/null 2>&1; then
        local plugins=($(get_quicklook_plugins))
    else
        local plugins=()  # Fallback to empty
    fi
    
    if [ ${#plugins[@]} -gt 0 ]; then
        brew install --cask "${plugins[@]}"
    fi
}

# Parallel MAS app installation
parallel_install_mas_apps() {
    echo "🍏 Installing Mac App Store apps..."
    
    # Check if should skip
    if [ "${SKIP_MAS_APPS:-false}" = "true" ]; then
        echo "⏭️ Skipping MAS apps installation (configured)"
        return 0
    fi
    
    # Load configuration
    if [ -f Scripts/config_parser.sh ]; then
        source Scripts/config_parser.sh
        load_dotfiles_config
    fi
    
    # Get MAS apps from config
    if command -v get_mas_apps >/dev/null 2>&1; then
        local mas_apps=$(get_mas_apps)
        if [ -n "$mas_apps" ]; then
            for app_entry in $mas_apps; do
                local app_id="${app_entry%:*}"
                mas install "$app_id"
            done
        fi
    fi
}

# Parallel Ruby gems installation
parallel_install_ruby_gems() {
    echo "💎 Installing Ruby gems..."
    
    # Check if should skip
    if [ "${SKIP_RUBY_INSTALL:-false}" = "true" ]; then
        echo "⏭️ Skipping Ruby gems installation (configured)"
        return 0
    fi
    
    # Install Ruby version if needed
    if [ -f ~/.ruby-version ] && command -v rbenv >/dev/null 2>&1; then
        local ruby_version=$(cat ~/.ruby-version)
        rbenv install "$ruby_version" || true
        rbenv global "$ruby_version"
    fi
    
    # Install bundler
    if command -v gem >/dev/null 2>&1; then
        gem install bundler
    fi
}

# Parallel Python packages installation
parallel_install_python_packages() {
    echo "🐍 Installing Python packages..."
    
    # Check if should skip
    if [ "${SKIP_PYTHON_INSTALL:-false}" = "true" ]; then
        echo "⏭️ Skipping Python packages installation (configured)"
        return 0
    fi
    
    # Install Python packages
    if command -v pip3 >/dev/null 2>&1; then
        pip3 install pyusb
    fi
}

################################################################################
### Help Documentation
################################################################################

show_parallel_help() {
    cat << 'EOF'
📖 parallel_operations.sh - Parallel execution management library

DESCRIPTION:
    Provides functions for running dotfiles setup operations in parallel
    with proper dependency management, logging, and error handling.

MAIN FUNCTIONS:
    run_parallel_with_dependencies    Run full parallel setup
    init_parallel                     Initialize parallel system
    queue_parallel_operation          Add operation to queue
    start_parallel_operation          Start operation in background
    wait_for_all_operations          Wait for completion
    get_operations_status            Show current status

PARALLEL PHASES:
    Phase 1: Independent operations (symlinks, user defaults, terminal)
    Phase 2: Homebrew installation (prerequisite for packages)
    Phase 3: Package installations (formulas, casks, MAS apps)
    Phase 4: Language packages (Ruby gems, Python packages)

USAGE:
    source Scripts/parallel_operations.sh
    run_parallel_with_dependencies

LOGS:
    Operation logs stored in: ~/.dotfiles_logs/parallel/

EOF
}

# Show help if script is run directly
if [ "${BASH_SOURCE[0]:-}" = "${0:-}" ]; then
    if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
        show_parallel_help
    else
        echo "This is a library file. Source it to use parallel functions."
        echo "Use --help for more information."
    fi
fi