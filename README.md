# macOS Dotfiles System

A comprehensive development environment management system for macOS that automates setup, manages configurations, and keeps your tools synchronized across multiple machines.

## Quick Start

```bash
# Try it out (30 seconds)
bash <(curl -Lks https://raw.githubusercontent.com/JARMourato/dotfiles/main/bootstrap.sh) --quick

# Development machine (full setup)
bash <(curl -Lks https://raw.githubusercontent.com/JARMourato/dotfiles/main/bootstrap.sh) --profile=dev

# Personal machine
bash <(curl -Lks https://raw.githubusercontent.com/JARMourato/dotfiles/main/bootstrap.sh) --profile=personal

# Server machine (Mac Mini)
bash <(curl -Lks https://raw.githubusercontent.com/JARMourato/dotfiles/main/bootstrap.sh) --profile=server
```

## What This System Does

- **Automates macOS setup** from a fresh machine to fully configured development environment
- **Manages packages and applications** through Homebrew, Mac App Store, and custom sources
- **Synchronizes configurations** across multiple machines with conflict resolution
- **Monitors system health** and automatically fixes common issues
- **Provides convenient aliases** for complex operations
- **Handles security** with encrypted file sync and SSH key management

## Documentation

### 🚀 **[Getting Started](docs/getting-started.md)**
Complete walkthrough for setting up your Mac from scratch. Covers setup modes, what gets installed, and step-by-step instructions.

### ⚙️ **[Configuration Guide](docs/configuration.md)**
Learn how to customize what gets installed. Includes examples for different developer types, work vs personal setups, and package management.

### 🔄 **[Multi-Machine Sync](docs/sync-guide.md)**
Keep configurations synchronized across multiple machines. Covers profiles, conflict resolution, and security.

### 📋 **[Command Reference](docs/commands.md)**
Complete list of available commands and aliases with examples.

### 🏥 **[Health Monitoring](docs/health-monitoring.md)**
System health checks, automated maintenance, and troubleshooting.

### 🔧 **[Advanced Usage](docs/advanced-usage.md)**
Plugin development, custom scripts, and extending the system.

### 🏢 **[Private Bootstrap Setup](docs/private-bootstrap-howto.md)**
Create private repositories for company/project-specific environment setup.

### 🔐 **[Keychain Encryption](docs/encryption-keychain.md)**
Secure, password-free encryption using macOS Keychain integration.

### 🆘 **[Troubleshooting](TROUBLESHOOTING.md)**
Common issues and solutions.

## System Overview

### Core Components

| Component | Purpose | Key Scripts |
|-----------|---------|-------------|
| **Bootstrap** | Initial setup and environment detection | `bootstrap.sh`, `quick_start.sh` |
| **Package Management** | Install and manage development tools | `dependency_resolver.sh`, `set_up_dependencies.sh` |
| **Configuration** | Manage dotfiles and system settings | `manage_config.sh`, `set_up_symlinks.sh` |
| **Sync System** | Multi-machine synchronization | `machine_sync.sh`, `dotfiles_sync_with_remote.sh` |
| **Health System** | Monitoring and automated maintenance | `health_monitor.sh`, `advanced_healing.sh` |
| **Security** | Encryption and key management | `encrypt_files.sh`, `rotate_secrets.sh` |

### Supported Development Environments

The system automatically detects and configures tools for:

- **Swift/iOS Development**: Xcode, SwiftLint, SwiftFormat, iOS Simulator
- **Web Development**: Node.js, TypeScript, modern browsers, VS Code
- **Python Development**: pyenv, pip, data science tools
- **DevOps/Cloud**: Docker, Kubernetes, Terraform, AWS CLI
- **General Development**: Git, terminal tools, editors, productivity apps

## Installation Modes

### Quick Start (30 seconds)
Essential tools only - perfect for trying the system:
```bash
bash <(curl -Lks https://raw.githubusercontent.com/JARMourato/dotfiles/main/bootstrap.sh) --quick
```

### Full Setup (5-10 minutes)
Complete development environment:
```bash
bash <(curl -Lks https://raw.githubusercontent.com/JARMourato/dotfiles/main/bootstrap.sh)
```

### Interactive Setup
Guided setup with explanations and choices:
```bash
# After quick start:
cd ~/.dotfiles
./Scripts/setup_wizard.sh --interactive
```

## Key Features

### Intelligent Package Management
- **Auto-detection**: Scans your projects to install relevant tools
- **Customizable**: Configure exactly what you want installed
- **Profile-based**: Different configurations for work/personal/development machines
- **Conflict resolution**: Handles package conflicts intelligently

### Multi-Machine Synchronization
- **Profile support**: Work, personal, and development machine types
- **Encrypted sync**: Sensitive files are encrypted during sync
- **Conflict resolution**: Interactive and automatic conflict resolution
- **Selective sync**: Choose what to sync between machines

### Health Monitoring
- **System health checks**: Automated diagnostics and issue detection
- **Predictive healing**: Detect and fix issues before they impact productivity
- **Performance monitoring**: Track system performance and optimization opportunities
- **Automated maintenance**: Schedule regular maintenance tasks

### Security Features
- **SSH key management**: Automatic generation and GitHub integration
- **File encryption**: Encrypt sensitive configuration files
- **Secret rotation**: Automated rotation of keys and secrets
- **Secure sync**: End-to-end encryption for multi-machine sync

## Common Use Cases

### New Mac Setup
1. Run quick start to get basic tools
2. Customize configuration for your needs
3. Run full setup to get complete environment
4. Set up sync for other machines

### Multi-Machine Developer
1. Set up primary machine completely
2. Configure sync with appropriate profile
3. Use sync to replicate environment on other machines
4. Keep configurations synchronized

### Team/Organization
1. Create base configuration for team
2. Allow personal customizations
3. Enforce security policies
4. Share common development environments

## System Requirements

- **macOS 10.15+** (Catalina or newer)
- **Intel x64** or **Apple Silicon** (M1/M2/M3/M4)
- **2GB** available storage space
- **Internet connection** for initial setup and sync

## Command Aliases

The system creates convenient aliases for common operations:

```bash
# Setup and configuration
setup-wizard          # Interactive setup
setup-deps            # Install dependencies
setup-symlinks        # Create configuration symlinks

# Health monitoring
health-check          # Run system diagnostics
health-dashboard      # Live monitoring interface
advanced-healing      # Predictive issue prevention

# Multi-machine sync
machine-sync          # Synchronization commands
machine-sync status   # Check sync status
machine-sync pull     # Get latest configurations

# Development tools
create-snapshot       # Create system state snapshot
git-commit           # Smart git commit with analysis
backup-github        # Backup GitHub repositories
```

## Project Structure

```
dotfiles/
├── README.md              # This file
├── bootstrap.sh           # Main entry point
├── aliases.sh            # Command aliases
├── TROUBLESHOOTING.md    # Common issues and solutions
├── docs/                 # Detailed documentation
│   ├── getting-started.md
│   ├── configuration.md
│   ├── sync-guide.md
│   └── ...
├── Scripts/              # Core functionality
│   ├── setup_wizard.sh
│   ├── health_monitor.sh
│   ├── machine_sync.sh
│   └── ...
├── Terminal/             # Terminal configuration
├── Xcode/               # Xcode configuration
└── Templates/           # Project templates
```

## Getting Help

- **Start here**: [Getting Started Guide](docs/getting-started.md)
- **Need to customize**: [Configuration Guide](docs/configuration.md)
- **Having issues**: [Troubleshooting Guide](TROUBLESHOOTING.md)
- **Advanced users**: [Advanced Usage Guide](docs/advanced-usage.md)

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make changes and add tests
4. Run `make test` to verify
5. Submit a pull request

## License

MIT License - see [LICENSE](LICENSE) for details.