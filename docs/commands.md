# Command Reference

Complete reference for all available commands and aliases in the dotfiles system.

## Quick Reference

### Setup Commands
```bash
setup-wizard           # Interactive setup with guided configuration
setup-deps             # Install dependencies and packages
setup-symlinks         # Create configuration symlinks
setup-user-defaults    # Configure macOS system preferences
setup-terminal         # Configure terminal and shell
setup-xcode            # Configure Xcode environment
```

### Health Monitoring
```bash
health-check           # Run system health diagnostics
health-dashboard       # Live monitoring interface
health-drift           # Check for configuration drift
health-autofix         # Auto-resolve detected issues
advanced-healing       # Predictive issue prevention
```

### Multi-Machine Sync
```bash
machine-sync           # Multi-machine synchronization
machine-sync init      # Initialize sync system
machine-sync status    # Check sync status
machine-sync pull      # Get latest configurations
machine-sync push      # Share local configurations
machine-sync resolve   # Handle merge conflicts
```

### Package Management
```bash
deps-scan              # Scan for missing dependencies
deps-resolve           # Install missing dependencies  
deps-graph             # Show dependency relationships
```

### Plugin System
```bash
plugin-init            # Initialize plugin system
plugin-list            # List available plugins
plugin-enable <name>   # Enable specific plugin
plugin-create <name>   # Create new plugin
plugin-disable <name>  # Disable plugin
plugin-remove <name>   # Remove plugin
```

### Utilities
```bash
create-snapshot        # Create system state snapshot
git-commit             # Smart git commit with analysis
backup-github          # Backup GitHub repositories
cleanup                # Clean temporary files and caches
```

## Detailed Command Reference

### Setup and Installation

#### setup-wizard
Interactive setup wizard with guided configuration.

```bash
setup-wizard [OPTIONS]

Options:
  --interactive         Guided setup with explanations
  --reconfigure        Re-run configuration setup
  --dry-run           Show what would be done without executing
  --help              Show help information

Examples:
  setup-wizard --interactive     # Guided first-time setup
  setup-wizard --reconfigure     # Update existing configuration
  setup-wizard --dry-run         # Preview changes
```

#### setup-deps
Install and manage system dependencies.

```bash
setup-deps [OPTIONS] [CATEGORY]

Categories:
  homebrew             Install Homebrew packages
  casks               Install GUI applications
  mas                 Install Mac App Store apps
  python              Set up Python environment
  node                Set up Node.js environment
  
Options:
  --update            Update existing packages
  --force             Force reinstallation
  --dry-run          Show what would be installed
  --minimal          Install only essential packages
  
Examples:
  setup-deps                     # Install all dependencies
  setup-deps homebrew           # Install only Homebrew packages
  setup-deps --update           # Update existing packages
  setup-deps --dry-run          # Preview installations
```

#### setup-symlinks
Create and manage configuration file symlinks.

```bash
setup-symlinks [OPTIONS]

Options:
  --force             Force overwrite existing files
  --backup           Create backups of existing files
  --remove           Remove existing symlinks
  --verify           Verify symlink integrity
  
Examples:
  setup-symlinks                # Create all symlinks
  setup-symlinks --backup      # Backup existing files first
  setup-symlinks --verify      # Check symlink status
```

### Health Monitoring

#### health-check
Run comprehensive system health diagnostics.

```bash
health-check [OPTIONS] [COMPONENT]

Components:
  homebrew            Check Homebrew installation
  git                 Check Git configuration
  ssh                 Check SSH setup
  python              Check Python environment
  node                Check Node.js environment
  
Options:
  --fix              Attempt automatic fixes
  --verbose          Show detailed output
  --json             Output results in JSON format
  --component=NAME   Check specific component
  
Examples:
  health-check                  # Check all components
  health-check homebrew        # Check only Homebrew
  health-check --fix           # Run checks and auto-fix issues
  health-check --verbose       # Detailed diagnostic output
```

#### health-dashboard
Live monitoring interface for system health.

```bash
health-dashboard [OPTIONS]

Options:
  --refresh=SECONDS   Set refresh interval (default: 5)
  --web              Start web interface
  --port=PORT        Web interface port (default: 8080)
  
Examples:
  health-dashboard              # Terminal dashboard
  health-dashboard --web        # Web interface
  health-dashboard --refresh=10 # 10-second refresh rate
```

#### advanced-healing
Predictive healing system for proactive issue prevention.

```bash
advanced-healing [OPTIONS]

Options:
  --auto-enable      Enable automatic healing
  --auto-disable     Disable automatic healing
  --status           Show healing status
  --aggressive       Use aggressive healing mode
  --gentle           Use gentle healing mode
  
Examples:
  advanced-healing              # Run healing once
  advanced-healing --auto-enable # Enable automatic healing
  advanced-healing --status     # Check healing configuration
```

### Multi-Machine Sync

#### machine-sync
Synchronize configurations across multiple machines.

```bash
machine-sync COMMAND [OPTIONS]

Commands:
  init               Initialize sync system
  status             Show sync status
  pull               Get latest configurations
  push               Share local configurations
  resolve            Handle merge conflicts
  profile            Manage machine profiles
  
Options:
  --force            Force operation
  --dry-run         Show what would be synced
  --encrypt         Encrypt sensitive files
  
Examples:
  machine-sync init             # Initialize sync
  machine-sync status           # Check sync status
  machine-sync pull --dry-run   # Preview incoming changes
  machine-sync push --force     # Force push changes
```

#### machine-sync profile
Manage machine profiles for different environments.

```bash
machine-sync profile [COMMAND] [PROFILE]

Commands:
  set PROFILE        Set machine profile
  get               Show current profile
  list              List available profiles
  
Profiles:
  work              Work machine configuration
  personal          Personal machine configuration
  development       Development-focused configuration
  minimal           Minimal configuration
  
Examples:
  machine-sync profile set work    # Set work profile
  machine-sync profile get         # Show current profile
  machine-sync profile list        # List all profiles
```

### Package Management

#### deps-scan
Scan system for missing dependencies and packages.

```bash
deps-scan [OPTIONS]

Options:
  --missing          Show only missing dependencies
  --outdated         Show outdated packages
  --unused           Show unused packages
  --json             Output in JSON format
  
Examples:
  deps-scan                     # Scan all dependencies
  deps-scan --missing          # Show only missing packages
  deps-scan --outdated         # Show packages needing updates
```

#### deps-resolve
Resolve and install missing dependencies.

```bash
deps-resolve [OPTIONS] [PACKAGES...]

Options:
  --auto             Auto-resolve without prompts
  --update           Update existing packages
  --reinstall        Reinstall packages
  
Examples:
  deps-resolve                  # Install missing dependencies
  deps-resolve git node         # Install specific packages
  deps-resolve --auto          # Auto-install without prompts
```

### Plugin System

#### plugin-manager
Manage plugins and extensions.

```bash
plugin-manager COMMAND [OPTIONS] [PLUGIN]

Commands:
  init               Initialize plugin system
  list               List available plugins
  enable PLUGIN      Enable plugin
  disable PLUGIN     Disable plugin
  create PLUGIN      Create new plugin
  remove PLUGIN      Remove plugin
  update [PLUGIN]    Update plugins
  
Options:
  --all              Apply to all plugins
  --force            Force operation
  
Examples:
  plugin-manager init           # Initialize plugin system
  plugin-manager list           # Show available plugins
  plugin-manager enable swift   # Enable Swift development plugin
  plugin-manager update --all   # Update all plugins
```

### Development Tools

#### git-commit
Smart Git commit with automated analysis and suggestions.

```bash
git-commit [OPTIONS] [MESSAGE]

Options:
  --analyze          Analyze changes before commit
  --suggest          Suggest commit message
  --lint             Run linting before commit
  --test             Run tests before commit
  
Examples:
  git-commit                    # Interactive commit
  git-commit "Fix bug"          # Commit with message
  git-commit --analyze          # Analyze changes first
  git-commit --suggest          # Get message suggestions
```

#### create-snapshot
Create system state snapshots for backup and rollback.

```bash
create-snapshot [OPTIONS] [NAME]

Options:
  --description=TEXT Set snapshot description
  --include=PATTERN  Include specific files/directories
  --exclude=PATTERN  Exclude files/directories
  
Examples:
  create-snapshot               # Create timestamped snapshot
  create-snapshot "pre-update"  # Named snapshot
  create-snapshot --description="Before major changes"
```

#### backup-github
Backup GitHub repositories and settings.

```bash
backup-github [OPTIONS]

Options:
  --repos            Backup repositories only
  --settings         Backup account settings
  --destination=DIR  Set backup destination
  --compress         Compress backup files
  
Examples:
  backup-github                 # Full backup
  backup-github --repos         # Backup only repositories
  backup-github --destination=/backup
```

### Maintenance and Utilities

#### cleanup
Clean temporary files, caches, and unused data.

```bash
cleanup [OPTIONS] [CATEGORY]

Categories:
  caches             Clear system and app caches
  logs               Clean old log files
  downloads          Clean Downloads folder
  trash             Empty trash
  
Options:
  --aggressive       More thorough cleaning
  --dry-run         Show what would be cleaned
  --size-limit=SIZE  Only clean files larger than SIZE
  
Examples:
  cleanup                       # Standard cleanup
  cleanup caches               # Clean only caches
  cleanup --aggressive         # Thorough cleanup
  cleanup --dry-run            # Preview cleanup actions
```

#### auto-maintenance
Automated maintenance scheduling and execution.

```bash
auto-maintenance [OPTIONS]

Options:
  --install-daemon   Install maintenance daemon
  --daily           Run daily maintenance
  --weekly          Run weekly maintenance
  --schedule=CRON   Set custom schedule
  --status          Show maintenance status
  
Examples:
  auto-maintenance --install-daemon  # Install automation
  auto-maintenance --daily          # Run daily tasks
  auto-maintenance --status         # Check status
```

### System Information

#### system-info
Display comprehensive system information.

```bash
system-info [OPTIONS]

Options:
  --hardware         Show hardware information
  --software         Show software versions
  --network          Show network configuration
  --performance      Show performance metrics
  
Examples:
  system-info                   # Show all information
  system-info --hardware        # Hardware details only
  system-info --performance     # Performance metrics
```

## Configuration Commands

### Configuration Management

#### manage-config
Manage dotfiles configuration.

```bash
manage-config [COMMAND] [OPTIONS]

Commands:
  validate           Validate configuration syntax
  backup            Create configuration backup
  restore           Restore from backup
  edit              Edit configuration file
  
Examples:
  manage-config validate        # Check configuration
  manage-config backup          # Backup current config
  manage-config edit            # Edit configuration
```

### Environment Variables

All commands respect these environment variables:

```bash
DOTFILES_DEBUG=1              # Enable debug output
DOTFILES_VERBOSE=1            # Enable verbose output
DOTFILES_DRY_RUN=1           # Default to dry-run mode
DOTFILES_AUTO_YES=1          # Auto-confirm prompts
DOTFILES_LOG_LEVEL=DEBUG     # Set logging level
DOTFILES_CONFIG_FILE=path    # Custom config file path
```

### Examples:
```bash
# Run health check with debug output
DOTFILES_DEBUG=1 health-check

# Verbose package installation
DOTFILES_VERBOSE=1 setup-deps

# Auto-confirm all prompts
DOTFILES_AUTO_YES=1 setup-wizard
```

## Exit Codes

Commands use standard exit codes:

- **0**: Success
- **1**: General error
- **2**: Invalid arguments
- **3**: Configuration error
- **4**: Network error
- **5**: Permission error
- **130**: Interrupted by user (Ctrl+C)

## Command Completion

Enable command completion in your shell:

```bash
# For Zsh (add to ~/.zshrc)
source ~/.dotfiles/completion/dotfiles.zsh

# For Bash (add to ~/.bashrc)
source ~/.dotfiles/completion/dotfiles.bash
```

## Getting Help

Every command supports the `--help` flag:

```bash
setup-wizard --help
health-check --help
machine-sync --help
```

For detailed documentation:
- **[Getting Started](getting-started.md)** - Basic setup walkthrough
- **[Configuration Guide](configuration.md)** - Customize your setup
- **[Troubleshooting](../TROUBLESHOOTING.md)** - Common issues and solutions