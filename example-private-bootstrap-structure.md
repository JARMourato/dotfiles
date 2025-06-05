# Private Bootstrap Repository Structure

This document shows how to set up a private repository for company/project-specific bootstrapping.

## Repository Structure

Create a private repository (e.g., `jarmourato/private-dotfiles-bootstrap`) with this structure:

```
private-dotfiles-bootstrap/
├── README.md
└── projects/
    ├── tellus/
    │   ├── bootstrap.sh       # Main bootstrap script
    │   ├── repos.txt         # List of repositories to clone
    │   ├── packages.txt      # Additional packages needed
    │   └── secrets.sh        # Secrets setup (optional)
    ├── company2/
    │   ├── bootstrap.sh
    │   ├── repos.txt
    │   └── packages.txt
    └── personal-projects/
        ├── bootstrap.sh
        └── repos.txt
```

## Example: Tellus Project

### `projects/tellus/bootstrap.sh`
```bash
#!/bin/bash
# Description: Tellus project setup with iOS, Android, Backend, and E2E repos

set -e # Immediately rethrows exceptions

# Use environment variables provided by bootstrap system
PROJECT_NAME="${PROJECT_NAME:-tellus}"
PROJECT_CONFIG_DIR="${PROJECT_CONFIG_DIR:-$HOME/.dotfiles/private-configs/tellus}"
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/.dotfiles}"

echo "🚀 Setting up Tellus project environment..."

#################################################################################
#### Configure Directories
#################################################################################

echo "📁 Setting up directories..."
rm -rf ~/Workspace/Git/Tellus
mkdir -p ~/Workspace/Git/Tellus

#################################################################################
#### Clone all needed repos
#################################################################################

echo "📦 Cloning repositories..."

# Source the repos list if it exists
if [[ -f "repos.txt" ]]; then
    while IFS= read -r repo_line; do
        # Skip empty lines and comments
        [[ -z "$repo_line" || "$repo_line" =~ ^# ]] && continue
        
        # Parse: repo_url destination_name
        repo_url=$(echo "$repo_line" | awk '{print $1}')
        dest_name=$(echo "$repo_line" | awk '{print $2}')
        
        echo "  Cloning $dest_name..."
        git clone "$repo_url" "~/Workspace/Git/Tellus/$dest_name"
    done < repos.txt
else
    # Fallback to hardcoded repos
    git clone git@github.com:zillyinc/tellus-android.git ~/Workspace/Git/Tellus/tellus-android
    git clone git@github.com:zillyinc/tellus-e2e-ui.git ~/Workspace/Git/Tellus/tellus-e2e-ui
    git clone git@github.com:zillyinc/tellus-ios.git ~/Workspace/Git/Tellus/tellus-ios
    git clone git@github.com:zillyinc/zilly-backend.git ~/Workspace/Git/Tellus/zilly-backend
fi

#################################################################################
#### Install additional packages
#################################################################################

echo "📦 Installing additional packages..."
if [[ -f "packages.txt" ]]; then
    # Install additional Homebrew packages
    while IFS= read -r package; do
        [[ -z "$package" || "$package" =~ ^# ]] && continue
        echo "  Installing $package..."
        brew install "$package" 2>/dev/null || echo "    Already installed or failed: $package"
    done < packages.txt
fi

#################################################################################
#### Set up secrets (if secrets.sh exists and is executable)
#################################################################################

if [[ -f "secrets.sh" && -x "secrets.sh" ]]; then
    echo "🔐 Setting up secrets..."
    ./secrets.sh
else
    echo "🔐 Secrets setup skipped (no secrets.sh found)"
    echo "   You may need to manually configure:"
    echo "   - API keys and tokens"
    echo "   - Database connections"
    echo "   - Environment-specific configs"
fi

#################################################################################
#### Create project-specific aliases
#################################################################################

echo "⚡ Setting up project aliases..."
mkdir -p "$PROJECT_CONFIG_DIR"

cat > "$PROJECT_CONFIG_DIR/aliases.sh" << 'EOF'
# Tellus project aliases
alias tellus-ios="cd ~/Workspace/Git/Tellus/tellus-ios"
alias tellus-android="cd ~/Workspace/Git/Tellus/tellus-android"
alias tellus-backend="cd ~/Workspace/Git/Tellus/zilly-backend"
alias tellus-e2e="cd ~/Workspace/Git/Tellus/tellus-e2e-ui"
alias tellus-root="cd ~/Workspace/Git/Tellus"

# Project-specific commands
alias tellus-build-ios="tellus-ios && xcodebuild"
alias tellus-test-e2e="tellus-e2e && npm test"
alias tellus-logs="tellus-backend && docker-compose logs -f"
EOF

# Source the aliases in the main dotfiles
echo "source $PROJECT_CONFIG_DIR/aliases.sh" >> "$DOTFILES_DIR/.aliases"

echo "✅ Tellus project setup complete!"
echo ""
echo "Available commands:"
echo "  tellus-ios      - Go to iOS project"
echo "  tellus-android  - Go to Android project"  
echo "  tellus-backend  - Go to backend project"
echo "  tellus-e2e      - Go to E2E project"
echo "  tellus-root     - Go to Tellus root directory"
echo ""
echo "Next steps:"
echo "  1. Configure secrets in each repository"
echo "  2. Install project dependencies"
echo "  3. Run initial builds/tests"
```

### `projects/tellus/repos.txt`
```
# Tellus repositories
# Format: git_url destination_name
git@github.com:zillyinc/tellus-android.git tellus-android
git@github.com:zillyinc/tellus-e2e-ui.git tellus-e2e-ui
git@github.com:zillyinc/tellus-ios.git tellus-ios
git@github.com:zillyinc/zilly-backend.git zilly-backend
```

### `projects/tellus/packages.txt`
```
# Additional packages needed for Tellus development
fastlane
swiftlint
ktlint
docker-compose
node
yarn
```

### `projects/tellus/secrets.sh` (optional)
```bash
#!/bin/bash
# Secrets setup for Tellus project
# This file should handle secrets configuration

echo "🔐 Setting up Tellus secrets..."

# Example: Copy secrets from encrypted dotfiles
if [[ -f "$DOTFILES_DIR/.tellus.encrypted" ]]; then
    echo "  Decrypting Tellus configuration..."
    # Use the existing decrypt_files.sh script
    "$DOTFILES_DIR/Scripts/decrypt_files.sh"
fi

# Create environment files for each project
echo "  Creating environment configurations..."

# iOS project secrets
cat > ~/Workspace/Git/Tellus/tellus-ios/.env << 'EOF'
# Tellus iOS Environment
API_BASE_URL=https://api.tellus.com
ENVIRONMENT=development
EOF

# Backend secrets  
cat > ~/Workspace/Git/Tellus/zilly-backend/.env << 'EOF'
# Zilly Backend Environment
DATABASE_URL=postgresql://localhost:5432/tellus_dev
REDIS_URL=redis://localhost:6379
ENVIRONMENT=development
EOF

echo "  ✅ Secrets configuration complete"
echo "     Remember to update with actual values!"
```

## Usage

### Set up the private repository
1. Create a private repository: `jarmourato/private-dotfiles-bootstrap`
2. Add the structure above
3. Configure SSH access to the private repo

### Bootstrap a project
```bash
# Bootstrap Tellus project
bootstrap-project tellus

# List available projects
bootstrap-project --list

# Dry run to see what would happen
bootstrap-project tellus --dry-run

# Use custom private repository
bootstrap-project myproject --repo git@github.com:mycompany/bootstrap.git
```

### Add to aliases
Add this to your `aliases.sh`:
```bash
alias bootstrap-project="$DOTFILES_DIR/Scripts/bootstrap_project.sh"
alias bootstrap="bootstrap-project"  # Short alias
```

## Security Notes

1. **Never commit secrets** - Use the `secrets.sh` script to handle sensitive data
2. **Use SSH keys** - Ensure SSH access is configured for private repositories
3. **Separate secrets** - Keep secrets in encrypted dotfiles, not in the bootstrap repo
4. **Review scripts** - Always review bootstrap scripts before running them
5. **Access control** - Limit access to private bootstrap repositories

## Benefits

1. **Consistent setup** - Same environment across team members
2. **Version controlled** - Track changes to project setup
3. **Secure** - Private repositories keep company data safe
4. **Flexible** - Each project can have different requirements
5. **Automated** - One command sets up entire development environment