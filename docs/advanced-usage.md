# Advanced Usage Guide

This guide covers advanced features for power users, including plugin development, custom scripts, automation, and extending the dotfiles system.

## Plugin Development

### Creating Custom Plugins

The plugin system allows you to extend the dotfiles functionality with custom workflows:

```bash
# Create a new plugin
plugin-create my-workflow

# This creates:
# ~/.dotfiles/plugins/my-workflow/
# ├── plugin.conf          # Plugin configuration
# ├── install.sh           # Installation script
# ├── health-check.sh      # Health monitoring integration
# ├── sync-hook.sh         # Multi-machine sync integration
# └── README.md            # Plugin documentation
```

### Plugin Structure

#### plugin.conf
```bash
# Plugin metadata
PLUGIN_NAME="my-workflow"
PLUGIN_VERSION="1.0.0"
PLUGIN_DESCRIPTION="Custom workflow automation"
PLUGIN_AUTHOR="Your Name"

# Dependencies
REQUIRED_TOOLS="jq curl git"
HOMEBREW_FORMULAS="custom-tool another-tool"
HOMEBREW_CASKS="custom-app"

# Integration points
ENABLE_HEALTH_CHECK=true
ENABLE_SYNC_HOOK=true
ENABLE_AUTO_UPDATE=false
```

#### install.sh
```bash
#!/bin/bash
# Plugin installation script

source "$(dirname "$0")/../lib/plugin-utils.sh"

plugin_install() {
    log_info "Installing my-workflow plugin..."
    
    # Install dependencies
    install_homebrew_formulas "custom-tool another-tool"
    
    # Create configuration
    create_config_file "$HOME/.my-workflow.conf" <<EOF
# My workflow configuration
WORKFLOW_ENABLED=true
CUSTOM_SETTING="value"
EOF
    
    # Set up aliases
    add_alias "my-command" "custom-tool --config ~/.my-workflow.conf"
    
    log_success "my-workflow plugin installed successfully"
}

plugin_install "$@"
```

#### health-check.sh
```bash
#!/bin/bash
# Health check integration

plugin_health_check() {
    local status="healthy"
    local messages=()
    
    # Check if custom tool is working
    if ! command -v custom-tool >/dev/null; then
        status="error"
        messages+=("custom-tool not found")
    fi
    
    # Check configuration
    if [[ ! -f "$HOME/.my-workflow.conf" ]]; then
        status="warning"
        messages+=("Configuration file missing")
    fi
    
    # Output health status
    echo "status:$status"
    for msg in "${messages[@]}"; do
        echo "message:$msg"
    done
}

plugin_health_check "$@"
```

### Plugin Management

```bash
# List available plugins
plugin-list

# Enable/disable plugins
plugin-enable my-workflow
plugin-disable my-workflow

# Update plugins
plugin-update my-workflow
plugin-update --all

# Remove plugins
plugin-remove my-workflow

# Plugin information
plugin-info my-workflow
```

## Custom Scripts and Automation

### Creating Custom Scripts

Add your own scripts to the system:

```bash
# Create custom script directory
mkdir -p ~/.dotfiles/custom/scripts

# Create a custom script
cat > ~/.dotfiles/custom/scripts/my-automation.sh << 'EOF'
#!/bin/bash
# Custom automation script

source ~/.dotfiles/Scripts/lib/common.sh

my_automation() {
    log_info "Running custom automation..."
    
    # Your automation logic here
    
    log_success "Automation completed"
}

my_automation "$@"
EOF

# Make it executable
chmod +x ~/.dotfiles/custom/scripts/my-automation.sh

# Add alias
echo 'alias my-automation="~/.dotfiles/custom/scripts/my-automation.sh"' >> ~/.dotfiles/.aliases
```

### Automation Hooks

The system provides hooks for custom automation:

#### Pre/Post Installation Hooks
```bash
# ~/.dotfiles/hooks/pre-install.sh
#!/bin/bash
echo "Running pre-installation tasks..."
# Custom pre-installation logic

# ~/.dotfiles/hooks/post-install.sh
#!/bin/bash
echo "Running post-installation tasks..."
# Custom post-installation logic
```

#### Sync Hooks
```bash
# ~/.dotfiles/hooks/pre-sync.sh
#!/bin/bash
echo "Preparing for sync..."
# Custom pre-sync logic

# ~/.dotfiles/hooks/post-sync.sh
#!/bin/bash
echo "Sync completed, running post-sync tasks..."
# Custom post-sync logic
```

#### Health Check Hooks
```bash
# ~/.dotfiles/hooks/health-check.sh
#!/bin/bash
# Custom health checks
echo "status:healthy"
echo "message:Custom check passed"
```

## Custom Package Management

### Adding Custom Homebrew Taps

```bash
# Add custom taps to your configuration
cat >> ~/.dotfiles/.dotfiles.config << 'EOF'
# Custom Homebrew taps
CUSTOM_TAPS="homebrew/cask-fonts company/internal-tools"

# Packages from custom taps
CUSTOM_FORMULAS="font-fira-code internal-cli-tool"
CUSTOM_CASKS="company-app"
EOF
```

### Custom Package Sources

#### Manual Installation Scripts
```bash
# ~/.dotfiles/custom/installers/custom-tool.sh
#!/bin/bash

install_custom_tool() {
    if command -v custom-tool >/dev/null; then
        log_info "custom-tool already installed"
        return 0
    fi
    
    log_info "Installing custom-tool..."
    
    # Download and install
    curl -L "https://releases.example.com/custom-tool" -o /tmp/custom-tool
    chmod +x /tmp/custom-tool
    sudo mv /tmp/custom-tool /usr/local/bin/
    
    log_success "custom-tool installed"
}

install_custom_tool
```

#### Integration with Dependency Resolver
```bash
# Add to ~/.dotfiles/.dotfiles.config
CUSTOM_INSTALLERS="custom-tool another-tool"
```

## Advanced Configuration

### Environment-Specific Configurations

#### Per-Project Configurations
```bash
# ~/.dotfiles/lib/project-detection.sh
detect_project_type() {
    local project_dir="$1"
    
    if [[ -f "$project_dir/package.json" ]]; then
        echo "nodejs"
    elif [[ -f "$project_dir/Cargo.toml" ]]; then
        echo "rust"
    elif [[ -f "$project_dir/pyproject.toml" ]]; then
        echo "python"
    # Add more detection logic
    fi
}

setup_project_environment() {
    local project_type="$1"
    
    case "$project_type" in
        "nodejs")
            setup_nodejs_environment
            ;;
        "rust")
            setup_rust_environment
            ;;
        "python")
            setup_python_environment
            ;;
    esac
}
```

#### Dynamic Configuration Loading
```bash
# ~/.dotfiles/lib/dynamic-config.sh
load_dynamic_config() {
    local config_file="$1"
    
    # Load base configuration
    source ~/.dotfiles/.dotfiles.config
    
    # Load environment-specific overrides
    if [[ -f ~/.dotfiles/.dotfiles.${ENVIRONMENT}.config ]]; then
        source ~/.dotfiles/.dotfiles.${ENVIRONMENT}.config
    fi
    
    # Load machine-specific overrides
    if [[ -f ~/.dotfiles/.dotfiles.$(hostname).config ]]; then
        source ~/.dotfiles/.dotfiles.$(hostname).config
    fi
}
```

### Custom Health Checks

#### System-Specific Health Checks
```bash
# ~/.dotfiles/custom/health-checks/custom-checks.sh
#!/bin/bash

check_custom_service() {
    if ! pgrep -f "my-service" >/dev/null; then
        echo "status:error"
        echo "message:my-service is not running"
        echo "fix:sudo systemctl start my-service"
        return 1
    fi
    
    echo "status:healthy"
    echo "message:my-service is running"
    return 0
}

check_disk_usage() {
    local usage=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')
    
    if [[ $usage -gt 90 ]]; then
        echo "status:error"
        echo "message:Disk usage is ${usage}%"
        echo "fix:cleanup or free up disk space"
        return 1
    elif [[ $usage -gt 80 ]]; then
        echo "status:warning"
        echo "message:Disk usage is ${usage}%"
        return 1
    fi
    
    echo "status:healthy"
    echo "message:Disk usage is ${usage}%"
    return 0
}

# Register custom checks
register_health_check "custom-service" check_custom_service
register_health_check "disk-usage" check_disk_usage
```

## API and Integration

### Dotfiles API

The system provides a simple API for integration:

```bash
# Source the API
source ~/.dotfiles/lib/api.sh

# Package management
dotfiles_install_package "homebrew" "git"
dotfiles_install_package "cask" "visual-studio-code"
dotfiles_install_package "mas" "904280696"  # Things 3

# Configuration management
dotfiles_set_config "CUSTOM_SETTING" "value"
dotfiles_get_config "CUSTOM_SETTING"

# Health monitoring
dotfiles_run_health_check
dotfiles_register_health_check "my-check" "my_check_function"

# Sync operations
dotfiles_sync_push
dotfiles_sync_pull
dotfiles_sync_status
```

### External Tool Integration

#### VS Code Integration
```bash
# ~/.dotfiles/integrations/vscode.sh
setup_vscode_integration() {
    # Install extensions
    local extensions=(
        "ms-python.python"
        "ms-vscode.vscode-typescript-next"
        "bradlc.vscode-tailwindcss"
    )
    
    for ext in "${extensions[@]}"; do
        code --install-extension "$ext"
    done
    
    # Configure settings
    setup_vscode_settings
}

setup_vscode_settings() {
    mkdir -p "$HOME/Library/Application Support/Code/User"
    
    cat > "$HOME/Library/Application Support/Code/User/settings.json" << 'EOF'
{
    "editor.fontSize": 14,
    "editor.fontFamily": "Fira Code",
    "editor.fontLigatures": true,
    "terminal.integrated.shell.osx": "/bin/zsh"
}
EOF
}
```

#### Git Integration
```bash
# ~/.dotfiles/integrations/git.sh
setup_advanced_git_config() {
    # Advanced Git configuration
    git config --global core.editor "code --wait"
    git config --global merge.tool "vscode"
    git config --global mergetool.vscode.cmd 'code --wait $MERGED'
    git config --global diff.tool "vscode"
    git config --global difftool.vscode.cmd 'code --wait --diff $LOCAL $REMOTE'
    
    # Git aliases
    git config --global alias.lg "log --oneline --graph --decorate --all"
    git config --global alias.s "status -s"
    git config --global alias.unstage "reset HEAD --"
}
```

## Continuous Integration

### GitHub Actions Integration

```yaml
# .github/workflows/dotfiles-test.yml
name: Test Dotfiles

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: macos-latest
    
    steps:
    - uses: actions/checkout@v2
    
    - name: Test Quick Setup
      run: |
        bash bootstrap.sh --quick --test-mode
    
    - name: Test Health Checks
      run: |
        source aliases.sh
        health-check
    
    - name: Test Plugin System
      run: |
        plugin-create test-plugin
        plugin-enable test-plugin
        plugin-list | grep test-plugin
```

### Automated Testing

```bash
# ~/.dotfiles/tests/advanced-tests.sh
#!/bin/bash

test_plugin_system() {
    # Test plugin creation
    plugin-create test-plugin
    assert_file_exists ~/.dotfiles/plugins/test-plugin/plugin.conf
    
    # Test plugin installation
    plugin-enable test-plugin
    assert_command_succeeds plugin-list | grep test-plugin
    
    # Cleanup
    plugin-remove test-plugin
}

test_custom_health_checks() {
    # Create custom health check
    create_custom_health_check
    
    # Test health check registration
    health-check --list | grep custom-check
    
    # Test health check execution
    assert_command_succeeds health-check custom-check
}

run_advanced_tests() {
    test_plugin_system
    test_custom_health_checks
    echo "All advanced tests passed!"
}

run_advanced_tests
```

## Performance Optimization

### Lazy Loading

```bash
# ~/.dotfiles/lib/lazy-loading.sh
lazy_load() {
    local trigger_command="$1"
    local load_function="$2"
    
    eval "$trigger_command() {
        unset -f $trigger_command
        $load_function
        $trigger_command \"\$@\"
    }"
}

# Example: Lazy load Docker completion
lazy_load docker '_load_docker_completion'

_load_docker_completion() {
    source /Applications/Docker.app/Contents/Resources/etc/docker.bash-completion
}
```

### Parallel Operations

```bash
# ~/.dotfiles/lib/parallel.sh
run_parallel() {
    local -a pids=()
    local -a commands=("$@")
    
    # Start all commands in background
    for cmd in "${commands[@]}"; do
        eval "$cmd" &
        pids+=($!)
    done
    
    # Wait for all to complete
    for pid in "${pids[@]}"; do
        wait "$pid"
    done
}

# Example usage
run_parallel \
    "brew update" \
    "pip install --upgrade pip" \
    "npm update -g"
```

## Debugging and Troubleshooting

### Debug Mode

```bash
# Enable debug mode
export DOTFILES_DEBUG=1

# Run commands with debug output
setup-deps --debug
health-check --verbose
machine-sync status --debug
```

### Logging System

```bash
# ~/.dotfiles/lib/logging.sh
setup_logging() {
    export DOTFILES_LOG_LEVEL="${DOTFILES_LOG_LEVEL:-INFO}"
    export DOTFILES_LOG_FILE="${DOTFILES_LOG_FILE:-$HOME/.dotfiles/logs/dotfiles.log}"
    
    mkdir -p "$(dirname "$DOTFILES_LOG_FILE")"
}

log_debug() { [[ $DOTFILES_LOG_LEVEL == "DEBUG" ]] && echo "[DEBUG] $*" | tee -a "$DOTFILES_LOG_FILE"; }
log_info() { echo "[INFO] $*" | tee -a "$DOTFILES_LOG_FILE"; }
log_warn() { echo "[WARN] $*" | tee -a "$DOTFILES_LOG_FILE"; }
log_error() { echo "[ERROR] $*" | tee -a "$DOTFILES_LOG_FILE"; }
```

### Advanced Diagnostics

```bash
# ~/.dotfiles/Scripts/advanced_diagnostics.sh
run_advanced_diagnostics() {
    echo "=== Advanced Dotfiles Diagnostics ==="
    
    # System information
    system_info
    
    # Package status
    package_status
    
    # Configuration validation
    validate_configuration
    
    # Performance metrics
    performance_metrics
    
    # Plugin status
    plugin_status
}

system_info() {
    echo "macOS Version: $(sw_vers -productVersion)"
    echo "Architecture: $(uname -m)"
    echo "Shell: $SHELL"
    echo "Homebrew: $(brew --version | head -1)"
}

package_status() {
    echo "Installed Homebrew Formulas: $(brew list --formula | wc -l)"
    echo "Installed Homebrew Casks: $(brew list --cask | wc -l)"
    echo "Outdated Packages: $(brew outdated | wc -l)"
}
```

## Next Steps

- **[Getting Started](getting-started.md)** - Basic setup walkthrough
- **[Configuration Guide](configuration.md)** - Customize what gets installed
- **[Multi-Machine Sync](sync-guide.md)** - Sync configs across machines
- **[Health Monitoring](health-monitoring.md)** - Keep your system healthy