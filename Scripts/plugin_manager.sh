#!/bin/bash
set -euo pipefail

################################################################################
### Plugin/Extension Architecture Manager
################################################################################
# This script provides a modular plugin system for dotfiles management
# allowing easy addition, removal, and management of feature extensions

# Plugin directories
PLUGIN_ROOT="$HOME/.dotfiles/plugins"
PLUGIN_AVAILABLE="$PLUGIN_ROOT/available"
PLUGIN_ENABLED="$PLUGIN_ROOT/enabled"
PLUGIN_CORE="$PLUGIN_ROOT/core"
PLUGIN_CUSTOM="$PLUGIN_ROOT/custom"

# Plugin registry and metadata
PLUGIN_REGISTRY="$PLUGIN_ROOT/registry.json"
PLUGIN_CACHE="$PLUGIN_ROOT/.plugin_cache"

################################################################################
### Plugin Directory Management
################################################################################

init_plugin_system() {
    echo "🔌 Initializing plugin system..."
    
    # Create plugin directories
    mkdir -p "$PLUGIN_AVAILABLE"
    mkdir -p "$PLUGIN_ENABLED" 
    mkdir -p "$PLUGIN_CORE"
    mkdir -p "$PLUGIN_CUSTOM"
    mkdir -p "$PLUGIN_CACHE"
    
    # Initialize registry if it doesn't exist
    if [ ! -f "$PLUGIN_REGISTRY" ]; then
        echo '{"plugins": {}, "version": "1.0", "last_updated": "'$(date -u +"%Y-%m-%dT%H:%M:%SZ")'"}' > "$PLUGIN_REGISTRY"
    fi
    
    echo "✅ Plugin system initialized"
}

################################################################################
### Plugin Discovery and Listing
################################################################################

list_plugins() {
    local filter="${1:-all}"
    
    echo "📦 Plugin Status Report"
    echo "======================="
    
    case "$filter" in
        enabled)
            echo "🟢 Enabled Plugins:"
            if [ -d "$PLUGIN_ENABLED" ] && [ "$(ls -A "$PLUGIN_ENABLED" 2>/dev/null)" ]; then
                for plugin in "$PLUGIN_ENABLED"/*.plugin.sh; do
                    [ -f "$plugin" ] && show_plugin_info "$(basename "$plugin" .plugin.sh)" "enabled"
                done
            else
                echo "  No plugins currently enabled"
            fi
            ;;
        available)
            echo "🔌 Available Plugins:"
            if [ -d "$PLUGIN_AVAILABLE" ] && [ "$(ls -A "$PLUGIN_AVAILABLE" 2>/dev/null)" ]; then
                for plugin in "$PLUGIN_AVAILABLE"/*.plugin.sh; do
                    [ -f "$plugin" ] && show_plugin_info "$(basename "$plugin" .plugin.sh)" "available"
                done
            else
                echo "  No plugins available"
            fi
            ;;
        core)
            echo "🧬 Core Plugins:"
            if [ -d "$PLUGIN_CORE" ] && [ "$(ls -A "$PLUGIN_CORE" 2>/dev/null)" ]; then
                for plugin in "$PLUGIN_CORE"/*.plugin.sh; do
                    [ -f "$plugin" ] && show_plugin_info "$(basename "$plugin" .plugin.sh)" "core"
                done
            else
                echo "  No core plugins found"
            fi
            ;;
        all|*)
            list_plugins "enabled"
            echo ""
            list_plugins "available" 
            echo ""
            list_plugins "core"
            ;;
    esac
}

show_plugin_info() {
    local plugin_name="$1"
    local status="$2"
    local plugin_file
    
    # Find the plugin file
    case "$status" in
        enabled) plugin_file="$PLUGIN_ENABLED/$plugin_name.plugin.sh" ;;
        core) plugin_file="$PLUGIN_CORE/$plugin_name.plugin.sh" ;;
        *) plugin_file="$PLUGIN_AVAILABLE/$plugin_name.plugin.sh" ;;
    esac
    
    if [ ! -f "$plugin_file" ]; then
        echo "  ❌ $plugin_name (file not found)"
        return
    fi
    
    # Extract plugin info
    local description=""
    local version=""
    local dependencies=""
    
    if grep -q "plugin_info()" "$plugin_file"; then
        # Source the plugin to get info (safely)
        local temp_info
        temp_info=$(bash -c "
            source '$plugin_file' 2>/dev/null || exit 1
            if declare -f plugin_info >/dev/null; then
                plugin_info
            fi
        " 2>/dev/null || echo "")
        
        description=$(echo "$temp_info" | grep "description:" | cut -d: -f2- | xargs)
        version=$(echo "$temp_info" | grep "version:" | cut -d: -f2- | xargs)
        dependencies=$(echo "$temp_info" | grep "dependencies:" | cut -d: -f2- | xargs)
    fi
    
    # Format output
    local status_icon
    case "$status" in
        enabled) status_icon="🟢" ;;
        core) status_icon="🧬" ;;
        *) status_icon="🔌" ;;
    esac
    
    echo "  $status_icon $plugin_name${version:+ v$version}${description:+ - $description}"
    [ -n "$dependencies" ] && echo "    📋 Dependencies: $dependencies"
}

################################################################################
### Plugin Management
################################################################################

enable_plugin() {
    local plugin_name="$1"
    local plugin_file="$PLUGIN_AVAILABLE/$plugin_name.plugin.sh"
    local enabled_file="$PLUGIN_ENABLED/$plugin_name.plugin.sh"
    
    # Validation
    if [ ! -f "$plugin_file" ]; then
        echo "❌ Plugin '$plugin_name' not found in available plugins"
        echo "💡 Use 'plugin_manager.sh list available' to see available plugins"
        return 1
    fi
    
    if [ -L "$enabled_file" ] || [ -f "$enabled_file" ]; then
        echo "⚠️  Plugin '$plugin_name' is already enabled"
        return 0
    fi
    
    echo "🔌 Enabling plugin: $plugin_name"
    
    # Check dependencies
    if ! check_plugin_dependencies "$plugin_name"; then
        echo "❌ Cannot enable '$plugin_name' due to missing dependencies"
        return 1
    fi
    
    # Create symlink
    ln -sf "../../available/$plugin_name.plugin.sh" "$enabled_file"
    
    # Run plugin installation
    if source "$plugin_file" && declare -f plugin_install >/dev/null; then
        echo "📦 Running plugin installation..."
        if plugin_install; then
            echo "✅ Plugin '$plugin_name' enabled successfully"
            update_plugin_registry "$plugin_name" "enabled"
        else
            echo "❌ Plugin installation failed, disabling..."
            rm -f "$enabled_file"
            return 1
        fi
    else
        echo "✅ Plugin '$plugin_name' enabled (no installation required)"
        update_plugin_registry "$plugin_name" "enabled"
    fi
}

disable_plugin() {
    local plugin_name="$1"
    local enabled_file="$PLUGIN_ENABLED/$plugin_name.plugin.sh"
    local plugin_file="$PLUGIN_AVAILABLE/$plugin_name.plugin.sh"
    
    if [ ! -L "$enabled_file" ] && [ ! -f "$enabled_file" ]; then
        echo "⚠️  Plugin '$plugin_name' is not currently enabled"
        return 0
    fi
    
    echo "🔌 Disabling plugin: $plugin_name"
    
    # Run plugin uninstallation if available
    if [ -f "$plugin_file" ] && source "$plugin_file" && declare -f plugin_uninstall >/dev/null; then
        echo "🗑️  Running plugin uninstallation..."
        plugin_uninstall || echo "⚠️  Plugin uninstallation had issues"
    fi
    
    # Remove symlink
    rm -f "$enabled_file"
    
    echo "✅ Plugin '$plugin_name' disabled"
    update_plugin_registry "$plugin_name" "disabled"
}

check_plugin_dependencies() {
    local plugin_name="$1"
    local plugin_file="$PLUGIN_AVAILABLE/$plugin_name.plugin.sh"
    
    if [ ! -f "$plugin_file" ]; then
        return 1
    fi
    
    # Get dependencies
    local dependencies
    dependencies=$(bash -c "
        source '$plugin_file' 2>/dev/null || exit 1
        if declare -f plugin_info >/dev/null; then
            plugin_info | grep 'dependencies:' | cut -d: -f2- | xargs
        fi
    " 2>/dev/null || echo "")
    
    if [ -z "$dependencies" ] || [ "$dependencies" = "none" ]; then
        return 0
    fi
    
    # Check each dependency
    local missing_deps=()
    for dep in ${dependencies//,/ }; do
        dep=$(echo "$dep" | xargs) # trim whitespace
        
        case "$dep" in
            homebrew)
                if ! command -v brew >/dev/null; then
                    missing_deps+=("homebrew")
                fi
                ;;
            git)
                if ! command -v git >/dev/null; then
                    missing_deps+=("git")
                fi
                ;;
            *)
                # Check if it's another plugin
                if [ ! -f "$PLUGIN_ENABLED/$dep.plugin.sh" ] && [ ! -f "$PLUGIN_CORE/$dep.plugin.sh" ]; then
                    missing_deps+=("$dep")
                fi
                ;;
        esac
    done
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        echo "❌ Missing dependencies: ${missing_deps[*]}"
        return 1
    fi
    
    return 0
}

################################################################################
### Plugin Registry Management
################################################################################

update_plugin_registry() {
    local plugin_name="$1"
    local status="$2"
    
    # Create a simple registry update (JSON manipulation in bash is limited)
    local temp_file
    temp_file=$(mktemp)
    
    if [ -f "$PLUGIN_REGISTRY" ]; then
        # For now, just append to a simple log format
        echo "$(date -u +"%Y-%m-%dT%H:%M:%SZ"): $plugin_name -> $status" >> "$PLUGIN_CACHE/plugin_history.log"
    fi
    
    rm -f "$temp_file"
}

################################################################################
### Plugin Installation and Creation
################################################################################

install_plugin() {
    local source_path="$1"
    local plugin_name="${2:-}"
    
    if [ -z "$plugin_name" ]; then
        plugin_name=$(basename "$source_path" .plugin.sh)
    fi
    
    echo "📦 Installing plugin: $plugin_name"
    
    # Handle different source types
    if [[ "$source_path" =~ ^https?:// ]]; then
        # Download from URL
        echo "🌐 Downloading from: $source_path"
        if curl -fsSL "$source_path" -o "$PLUGIN_AVAILABLE/$plugin_name.plugin.sh"; then
            chmod +x "$PLUGIN_AVAILABLE/$plugin_name.plugin.sh"
            echo "✅ Plugin downloaded successfully"
        else
            echo "❌ Failed to download plugin"
            return 1
        fi
    elif [ -f "$source_path" ]; then
        # Copy from local file
        echo "📁 Copying from: $source_path"
        cp "$source_path" "$PLUGIN_AVAILABLE/$plugin_name.plugin.sh"
        chmod +x "$PLUGIN_AVAILABLE/$plugin_name.plugin.sh"
        echo "✅ Plugin copied successfully"
    else
        echo "❌ Invalid source path: $source_path"
        return 1
    fi
    
    # Validate plugin format
    if validate_plugin "$plugin_name"; then
        echo "✅ Plugin '$plugin_name' installed and validated"
        update_plugin_registry "$plugin_name" "installed"
    else
        echo "❌ Plugin validation failed"
        rm -f "$PLUGIN_AVAILABLE/$plugin_name.plugin.sh"
        return 1
    fi
}

validate_plugin() {
    local plugin_name="$1"
    local plugin_file="$PLUGIN_AVAILABLE/$plugin_name.plugin.sh"
    
    # Basic validation
    if [ ! -f "$plugin_file" ]; then
        echo "❌ Plugin file not found"
        return 1
    fi
    
    # Check for required functions
    if ! grep -q "plugin_info()" "$plugin_file"; then
        echo "⚠️  Plugin missing plugin_info() function"
    fi
    
    # Syntax check
    if ! bash -n "$plugin_file"; then
        echo "❌ Plugin has syntax errors"
        return 1
    fi
    
    echo "✅ Plugin validation passed"
    return 0
}

create_plugin_template() {
    local plugin_name="$1"
    local plugin_file="$PLUGIN_CUSTOM/$plugin_name.plugin.sh"
    
    if [ -f "$plugin_file" ]; then
        echo "❌ Plugin '$plugin_name' already exists"
        return 1
    fi
    
    echo "📝 Creating plugin template: $plugin_name"
    
    cat > "$plugin_file" << 'EOF'
#!/bin/bash
################################################################################
### Custom Plugin Template
################################################################################

plugin_info() {
    echo "name: PLUGIN_NAME"
    echo "description: Brief description of what this plugin does"
    echo "version: 1.0.0"
    echo "dependencies: none"
    echo "conflicts: none"
}

plugin_install() {
    echo "🔌 Installing PLUGIN_NAME..."
    
    # Add your installation logic here
    # Examples:
    # - Install packages: brew install package-name
    # - Create symlinks: ln -sf source target
    # - Configure settings: configure_settings
    # - Add aliases: add_aliases
    
    echo "✅ PLUGIN_NAME installed successfully"
}

plugin_uninstall() {
    echo "🗑️ Uninstalling PLUGIN_NAME..."
    
    # Add your uninstallation logic here
    # Examples:
    # - Remove packages: brew uninstall package-name
    # - Remove symlinks: rm -f target
    # - Clean configurations: clean_settings
    # - Remove aliases: remove_aliases
    
    echo "✅ PLUGIN_NAME uninstalled successfully"
}

plugin_update() {
    echo "🔄 Updating PLUGIN_NAME..."
    
    # Add your update logic here
    # Examples:
    # - Update packages: brew upgrade package-name
    # - Refresh configurations: refresh_settings
    
    echo "✅ PLUGIN_NAME updated successfully"
}

plugin_health_check() {
    echo "🔍 Checking PLUGIN_NAME health..."
    
    # Add health check logic here
    # Examples:
    # - Check if files exist: [ -f /path/to/file ]
    # - Verify commands work: command -v tool >/dev/null
    # - Test configurations: test_config
    
    echo "✅ PLUGIN_NAME is healthy"
}

# Additional helper functions
configure_settings() {
    # Plugin-specific configuration
    :
}

add_aliases() {
    # Add plugin-specific aliases
    :
}

# Plugin-specific variables
PLUGIN_CONFIG_DIR="$HOME/.config/plugin-name"
PLUGIN_DATA_DIR="$HOME/.local/share/plugin-name"
EOF

    # Replace template placeholders
    sed -i '' "s/PLUGIN_NAME/$plugin_name/g" "$plugin_file"
    chmod +x "$plugin_file"
    
    echo "✅ Plugin template created: $plugin_file"
    echo "💡 Edit the file to customize your plugin"
}

################################################################################
### Plugin Operations
################################################################################

update_plugins() {
    echo "🔄 Updating all enabled plugins..."
    
    local updated_count=0
    local failed_count=0
    
    for plugin_file in "$PLUGIN_ENABLED"/*.plugin.sh; do
        [ ! -f "$plugin_file" ] && continue
        
        local plugin_name
        plugin_name=$(basename "$plugin_file" .plugin.sh)
        
        echo "📦 Updating plugin: $plugin_name"
        
        if source "$plugin_file" && declare -f plugin_update >/dev/null; then
            if plugin_update; then
                echo "✅ $plugin_name updated successfully"
                ((updated_count++))
            else
                echo "❌ Failed to update $plugin_name"
                ((failed_count++))
            fi
        else
            echo "⚠️  $plugin_name has no update function"
        fi
    done
    
    echo "📊 Update summary: $updated_count updated, $failed_count failed"
}

health_check_plugins() {
    echo "🔍 Running health checks on enabled plugins..."
    
    local healthy_count=0
    local unhealthy_count=0
    
    for plugin_file in "$PLUGIN_ENABLED"/*.plugin.sh; do
        [ ! -f "$plugin_file" ] && continue
        
        local plugin_name
        plugin_name=$(basename "$plugin_file" .plugin.sh)
        
        echo "🩺 Checking plugin: $plugin_name"
        
        if source "$plugin_file" && declare -f plugin_health_check >/dev/null; then
            if plugin_health_check; then
                echo "✅ $plugin_name is healthy"
                ((healthy_count++))
            else
                echo "❌ $plugin_name has health issues"
                ((unhealthy_count++))
            fi
        else
            echo "⚠️  $plugin_name has no health check"
        fi
    done
    
    echo "📊 Health summary: $healthy_count healthy, $unhealthy_count with issues"
}

################################################################################
### Main Command Interface
################################################################################

show_help() {
    cat << 'EOF'
🔌 Plugin Manager - Modular Dotfiles Extensions

USAGE:
    ./plugin_manager.sh <command> [options]

COMMANDS:
    init                    Initialize the plugin system
    list [all|enabled|available|core]  List plugins by status
    enable <plugin>         Enable a plugin
    disable <plugin>        Disable a plugin
    install <source> [name] Install plugin from source
    create <name>           Create a new plugin template
    update                  Update all enabled plugins
    health                  Run health checks on enabled plugins
    info <plugin>           Show detailed plugin information
    search <term>           Search for plugins
    clean                   Clean up plugin cache and orphans

EXAMPLES:
    ./plugin_manager.sh init
    ./plugin_manager.sh list enabled
    ./plugin_manager.sh enable swift-dev
    ./plugin_manager.sh install ~/my-plugin.sh custom-tools
    ./plugin_manager.sh create my-workflow
    ./plugin_manager.sh update
    ./plugin_manager.sh health

PLUGIN DIRECTORIES:
    ~/.dotfiles/plugins/core/       - Core system plugins (always loaded)
    ~/.dotfiles/plugins/available/  - Available plugins
    ~/.dotfiles/plugins/enabled/    - Enabled plugins (symlinks)
    ~/.dotfiles/plugins/custom/     - Custom user plugins

For more information, visit the dotfiles documentation.
EOF
}

# Main command dispatcher
main() {
    case "${1:-help}" in
        init)
            init_plugin_system
            ;;
        list)
            list_plugins "${2:-all}"
            ;;
        enable)
            if [ -z "${2:-}" ]; then
                echo "❌ Usage: $0 enable <plugin_name>"
                exit 1
            fi
            enable_plugin "$2"
            ;;
        disable)
            if [ -z "${2:-}" ]; then
                echo "❌ Usage: $0 disable <plugin_name>"
                exit 1
            fi
            disable_plugin "$2"
            ;;
        install)
            if [ -z "${2:-}" ]; then
                echo "❌ Usage: $0 install <source> [plugin_name]"
                exit 1
            fi
            install_plugin "$2" "${3:-}"
            ;;
        create)
            if [ -z "${2:-}" ]; then
                echo "❌ Usage: $0 create <plugin_name>"
                exit 1
            fi
            create_plugin_template "$2"
            ;;
        update)
            update_plugins
            ;;
        health)
            health_check_plugins
            ;;
        info)
            if [ -z "${2:-}" ]; then
                echo "❌ Usage: $0 info <plugin_name>"
                exit 1
            fi
            show_plugin_info "$2" "detailed"
            ;;
        clean)
            echo "🧹 Cleaning plugin cache..."
            rm -rf "$PLUGIN_CACHE"/*
            echo "✅ Plugin cache cleaned"
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            echo "❌ Unknown command: $1"
            echo "💡 Use '$0 help' for usage information"
            exit 1
            ;;
    esac
}

# Initialize if needed and run main
if [ ! -d "$PLUGIN_ROOT" ]; then
    init_plugin_system
fi

main "$@"