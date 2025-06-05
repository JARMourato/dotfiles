# Health Monitoring Guide

The dotfiles system includes comprehensive health monitoring to keep your development environment running smoothly. This guide covers health checks, automated maintenance, and troubleshooting.

## Overview

The health monitoring system provides:

- **Automated diagnostics** to detect common issues
- **Predictive healing** to prevent problems before they occur
- **Performance monitoring** to optimize your system
- **Maintenance scheduling** for regular upkeep
- **Issue resolution** with automated fixes

## Basic Health Monitoring

### Running Health Checks

```bash
# Quick health check
health-check

# Detailed health dashboard
health-dashboard

# Check specific components
health-check --component=homebrew
health-check --component=git
health-check --component=ssh

# Run all checks with verbose output
health-check --verbose
```

### Understanding Health Status

Health checks return one of four statuses:

- **🟢 Healthy**: Everything is working correctly
- **🟡 Warning**: Minor issues that should be addressed
- **🟠 Degraded**: Issues affecting performance
- **🔴 Error**: Critical problems requiring immediate attention

### Example Health Check Output

```bash
$ health-check

=== System Health Report ===
🟢 Homebrew: Healthy (287 packages installed)
🟡 Git: Warning (old version detected: 2.39.0)
🟢 SSH: Healthy (keys configured, agent running)
🟠 Disk Space: Degraded (82% full)
🔴 Python: Error (pyenv not found)

=== Summary ===
- 2 components healthy
- 1 warning
- 1 degraded
- 1 error

Run 'health-check --fix' to attempt automatic repairs.
```

## Automated Health Checks

### Scheduling Regular Checks

```bash
# Enable daily health checks
health-monitor --schedule daily

# Enable hourly health checks  
health-monitor --schedule hourly

# Custom schedule (using cron syntax)
health-monitor --schedule "0 */4 * * *"  # Every 4 hours

# Disable scheduled checks
health-monitor --schedule off
```

### Background Monitoring

```bash
# Start health monitoring daemon
health-monitor --daemon start

# Stop monitoring daemon
health-monitor --daemon stop

# Check daemon status
health-monitor --daemon status

# View monitoring logs
health-monitor --logs
```

### Notification Settings

Configure how you receive health notifications:

```bash
# Enable desktop notifications
health-monitor --notify desktop

# Enable email notifications
health-monitor --notify email --email your@email.com

# Slack integration
health-monitor --notify slack --webhook-url "https://hooks.slack.com/..."

# Disable notifications
health-monitor --notify off
```

## Health Check Components

### System Components

#### Homebrew Health
```bash
# Check Homebrew status
health-check homebrew

# What it checks:
# - Homebrew installation
# - Outdated packages
# - Broken symlinks
# - Repository health
# - Permission issues
```

#### Git Configuration
```bash
# Check Git setup
health-check git

# What it checks:
# - Git installation and version
# - Global configuration (name, email)
# - SSH key configuration
# - Repository status
# - Credential helper setup
```

#### SSH Configuration
```bash
# Check SSH setup
health-check ssh

# What it checks:
# - SSH key existence
# - SSH agent status
# - GitHub connectivity
# - Key permissions
# - Known hosts
```

#### Development Environment
```bash
# Check development tools
health-check devenv

# What it checks:
# - Language runtimes (Node.js, Python, Ruby)
# - Package managers (npm, pip, gem)
# - Development tools (Xcode, VS Code)
# - Environment variables
# - Path configuration
```

### Custom Health Checks

Create your own health checks:

```bash
# Create custom health check
cat > ~/.dotfiles/custom/health-checks/my-check.sh << 'EOF'
#!/bin/bash

check_my_service() {
    if ! pgrep -f "my-service" >/dev/null; then
        echo "status:error"
        echo "message:my-service is not running"
        echo "fix:sudo systemctl start my-service"
        return 1
    fi
    
    echo "status:healthy"
    echo "message:my-service is running properly"
    return 0
}

# Register the check
register_health_check "my-service" check_my_service
EOF

# Make it executable
chmod +x ~/.dotfiles/custom/health-checks/my-check.sh

# Test the custom check
health-check my-service
```

## Predictive Healing

### Advanced Healing System

The advanced healing system proactively prevents issues:

```bash
# Run predictive healing
advanced-healing

# Enable automatic healing
advanced-healing --auto-enable

# Disable automatic healing
advanced-healing --auto-disable

# Check healing status
advanced-healing --status
```

### What Advanced Healing Does

- **Disk Space Management**: Automatically cleans temporary files when space is low
- **Package Updates**: Keeps critical packages updated
- **Permission Fixes**: Corrects common permission issues
- **Service Recovery**: Restarts failed services automatically
- **Configuration Repair**: Fixes broken configuration files

### Healing Configuration

```bash
# Configure healing thresholds
cat >> ~/.dotfiles/.dotfiles.config << 'EOF'
# Healing thresholds
DISK_WARNING_THRESHOLD=80      # Warn at 80% disk usage
DISK_CRITICAL_THRESHOLD=90     # Critical at 90% disk usage
AUTO_CLEAN_ENABLED=true        # Enable automatic cleanup
AUTO_UPDATE_ENABLED=false      # Disable automatic updates
HEALING_AGGRESSIVENESS=medium  # low, medium, high
EOF
```

## Performance Monitoring

### System Performance Metrics

```bash
# View performance dashboard
performance-dashboard

# Check startup time
performance-check startup

# Monitor resource usage
performance-monitor --duration=60

# Generate performance report
performance-report --output=html
```

### Performance Optimization

```bash
# Run performance optimization
performance-optimize

# Optimize shell startup
performance-optimize shell

# Optimize Homebrew
performance-optimize homebrew

# Clean caches and temporary files
performance-optimize cleanup
```

### Performance Alerts

Set up alerts for performance issues:

```bash
# Alert when shell startup exceeds 2 seconds
performance-alert --metric=shell_startup --threshold=2000ms

# Alert when memory usage exceeds 80%
performance-alert --metric=memory_usage --threshold=80%

# Alert when disk I/O is high
performance-alert --metric=disk_io --threshold=high
```

## Automated Maintenance

### Daily Maintenance

```bash
# Install daily maintenance
auto-maintenance --install-daemon

# Configure daily tasks
auto-maintenance --configure << 'EOF'
# Daily maintenance tasks
- update_homebrew: true
- clean_logs: true
- backup_configs: true
- check_updates: true
- verify_symlinks: true
EOF

# Run maintenance manually
auto-maintenance --daily
```

### Weekly Maintenance

```bash
# Configure weekly tasks
auto-maintenance --weekly << 'EOF'
# Weekly maintenance tasks
- deep_clean: true
- update_packages: true
- rotate_logs: true
- system_diagnostics: true
- performance_analysis: true
EOF
```

### Maintenance Logs

```bash
# View maintenance logs
auto-maintenance --logs

# View specific maintenance run
auto-maintenance --logs --date=2024-01-15

# Export maintenance report
auto-maintenance --report --format=pdf
```

## Troubleshooting Health Issues

### Common Issues and Solutions

#### Homebrew Issues

**Problem**: Outdated packages
```bash
# Solution: Update packages
brew update && brew upgrade
```

**Problem**: Broken symlinks
```bash
# Solution: Fix symlinks
brew doctor
brew cleanup
```

**Problem**: Permission issues
```bash
# Solution: Fix permissions
sudo chown -R $(whoami) /usr/local/Homebrew/
```

#### Git Issues

**Problem**: No global Git configuration
```bash
# Solution: Configure Git
git config --global user.name "Your Name"
git config --global user.email "your@email.com"
```

**Problem**: SSH key not configured
```bash
# Solution: Generate and configure SSH key
ssh-keygen -t ed25519 -C "your@email.com"
gh auth login
```

#### Python/Node Issues

**Problem**: Multiple Python versions causing conflicts
```bash
# Solution: Use pyenv for version management
pyenv install 3.11.0
pyenv global 3.11.0
```

**Problem**: npm permission issues
```bash
# Solution: Use nvm or fix npm permissions
nvm install node
nvm use node
```

### Diagnostic Tools

#### System Diagnostics

```bash
# Run comprehensive diagnostics
system-diagnostics

# Check specific system component
system-diagnostics --component=networking
system-diagnostics --component=filesystem
system-diagnostics --component=security
```

#### Environment Diagnostics

```bash
# Check development environment
env-diagnostics

# Verify PATH configuration
env-diagnostics --path

# Check environment variables
env-diagnostics --env-vars
```

#### Package Diagnostics

```bash
# Check package installations
package-diagnostics

# Verify package dependencies
package-diagnostics --dependencies

# Check for package conflicts
package-diagnostics --conflicts
```

### Recovery Mode

If your system is severely broken:

```bash
# Enter recovery mode
dotfiles-recovery

# Minimal recovery (essential tools only)
dotfiles-recovery --minimal

# Full recovery (restore from backup)
dotfiles-recovery --restore

# Reset to clean state
dotfiles-recovery --reset
```

## Health Monitoring Best Practices

### Regular Monitoring

1. **Daily**: Quick health check
2. **Weekly**: Full system diagnostics
3. **Monthly**: Performance analysis and optimization
4. **After major changes**: Comprehensive health check

### Preventive Measures

1. **Enable automated healing** for common issues
2. **Set up monitoring alerts** for critical metrics
3. **Keep regular backups** of your configuration
4. **Monitor disk space** and clean regularly
5. **Update packages** regularly but not automatically

### Emergency Procedures

1. **System not booting**: Use recovery mode
2. **Package manager broken**: Reinstall Homebrew
3. **Configuration corrupted**: Restore from backup
4. **Performance degraded**: Run optimization tools

## Integration with Other Tools

### VS Code Integration

```bash
# Install VS Code health check extension
code --install-extension dotfiles.health-monitor

# Configure VS Code to show health status
echo '{"dotfiles.healthCheck.enabled": true}' >> ~/Library/Application\ Support/Code/User/settings.json
```

### Terminal Integration

Add health status to your shell prompt:

```bash
# Add to ~/.zshrc or ~/.bashrc
function dotfiles_health_status() {
    local status=$(health-check --status-only 2>/dev/null)
    case "$status" in
        "healthy") echo "🟢" ;;
        "warning") echo "🟡" ;;
        "degraded") echo "🟠" ;;
        "error") echo "🔴" ;;
        *) echo "" ;;
    esac
}

# Add to prompt
PS1="$(dotfiles_health_status) $PS1"
```

### Monitoring Dashboards

Set up web dashboard for health monitoring:

```bash
# Start health monitoring web server
health-dashboard --web --port=8080

# Access dashboard at http://localhost:8080
open http://localhost:8080
```

## Next Steps

- **[Getting Started](getting-started.md)** - Basic setup walkthrough
- **[Configuration Guide](configuration.md)** - Customize what gets installed
- **[Multi-Machine Sync](sync-guide.md)** - Sync configs across machines
- **[Advanced Usage](advanced-usage.md)** - Plugin development and customization