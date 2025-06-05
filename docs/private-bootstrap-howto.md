# How to Create Private Bootstrap Repository

This guide shows you how to create a private repository for company/project-specific environment setup.

## Quick Setup

### Option 1: Automatic Setup (Recommended)

Create and push to GitHub automatically:

```bash
# Create with all defaults and push to GitHub
create-private-bootstrap --create-repo --push-repo

# Or with custom settings
create-private-bootstrap \
  --repo-name my-company-bootstrap \
  --github-user yourusername \
  --example-company mycompany \
  --create-repo \
  --push-repo
```

### Option 2: Manual Setup

Create locally first, then push manually:

```bash
# Create repository locally
create-private-bootstrap

# Review the generated files
ls ~/Workspace/Git/private-dotfiles-bootstrap

# Create GitHub repo and push manually
cd ~/Workspace/Git/private-dotfiles-bootstrap
gh repo create yourusername/private-dotfiles-bootstrap --private
git remote add origin git@github.com:yourusername/private-dotfiles-bootstrap.git
git add . && git commit -m "Initial setup"
git push -u origin main
```

## What Gets Created

### Repository Structure
```
private-dotfiles-bootstrap/
├── README.md                    # Main documentation
├── docs/
│   ├── adding-projects.md       # Guide for adding new projects
│   └── security.md             # Security best practices
└── projects/
    ├── template/               # Template for new projects
    │   ├── bootstrap.sh        # Template bootstrap script
    │   ├── repos.txt          # Template repo list
    │   └── packages.txt       # Template package list
    └── acme/                  # Example company
        ├── bootstrap.sh       # Example bootstrap script
        ├── repos.txt         # Example repositories
        ├── packages.txt      # Example packages
        └── secrets.sh        # Example secrets setup
```

### Example Company (ACME)

The generator creates a complete example company setup with:

- **bootstrap.sh**: Complete setup script with directory creation, repo cloning, package installation
- **repos.txt**: Example repository list format
- **packages.txt**: Example additional packages
- **secrets.sh**: Example secrets handling
- **Aliases**: Project-specific command shortcuts

## Adding Your Actual Company (e.g., Tellus)

### Step 1: Copy Template

```bash
cd ~/Workspace/Git/private-dotfiles-bootstrap
cp -r projects/template projects/tellus
```

### Step 2: Configure Bootstrap Script

Edit `projects/tellus/bootstrap.sh`:

```bash
vim projects/tellus/bootstrap.sh
```

Update the repositories section:

```bash
#################################################################################
#### Clone repositories
#################################################################################

echo "📦 Cloning repositories..."
git clone git@github.com:zillyinc/tellus-android.git "$WORKSPACE_DIR/tellus-android"
git clone git@github.com:zillyinc/tellus-e2e-ui.git "$WORKSPACE_DIR/tellus-e2e-ui"
git clone git@github.com:zillyinc/tellus-ios.git "$WORKSPACE_DIR/tellus-ios"
git clone git@github.com:zillyinc/zilly-backend.git "$WORKSPACE_DIR/zilly-backend"
```

Update the aliases section:

```bash
cat > "$PROJECT_CONFIG_DIR/aliases.sh" << 'ALIASES_EOF'
# Tellus project aliases
alias tellus-ios="cd $WORKSPACE_DIR/tellus-ios"
alias tellus-android="cd $WORKSPACE_DIR/tellus-android"
alias tellus-backend="cd $WORKSPACE_DIR/zilly-backend"
alias tellus-e2e="cd $WORKSPACE_DIR/tellus-e2e-ui"
alias tellus-root="cd $WORKSPACE_DIR"
ALIASES_EOF
```

### Step 3: Configure Repository List

Edit `projects/tellus/repos.txt`:

```
# Tellus repositories
git@github.com:zillyinc/tellus-android.git tellus-android
git@github.com:zillyinc/tellus-e2e-ui.git tellus-e2e-ui
git@github.com:zillyinc/tellus-ios.git tellus-ios
git@github.com:zillyinc/zilly-backend.git zilly-backend
```

### Step 4: Configure Additional Packages

Edit `projects/tellus/packages.txt`:

```
# Tellus development tools
fastlane
swiftlint
swiftformat
ktlint
```

### Step 5: Test and Commit

```bash
# Test the setup
bootstrap tellus --dry-run

# If it looks good, commit the changes
git add projects/tellus/
git commit -m "Add Tellus project configuration"
git push
```

## Using Your Private Bootstrap

### First Time Setup

Update your dotfiles configuration:

```bash
echo 'PRIVATE_BOOTSTRAP_REPO="git@github.com:yourusername/private-dotfiles-bootstrap.git"' >> ~/.dotfiles/.dotfiles.config
```

### Bootstrap a Project

```bash
# Bootstrap Tellus project
bootstrap tellus

# List available projects
bootstrap --list

# Preview what would happen
bootstrap tellus --dry-run
```

## Command Reference

### create-private-bootstrap Options

```bash
# Basic usage
create-private-bootstrap [options]

# Options:
--repo-name NAME        # Repository name (default: private-dotfiles-bootstrap)
--github-user USER      # GitHub username (default: current git user)
--create-repo          # Create GitHub repository automatically
--push-repo            # Push to remote after creation
--example-company NAME  # Name for example company (default: acme)
--output-dir DIR       # Where to create repository (default: ~/Workspace/Git)
--help                 # Show help
```

### Examples

```bash
# Create with all defaults
create-private-bootstrap

# Create with custom company example
create-private-bootstrap --example-company mycompany

# Create and push to GitHub automatically
create-private-bootstrap --create-repo --push-repo

# Create with custom repository name
create-private-bootstrap \
  --repo-name my-bootstrap \
  --github-user myusername \
  --example-company mycompany \
  --create-repo \
  --push-repo
```

## Security Considerations

### Repository Security
- Always make the repository **private**
- Only grant access to team members who need it
- Use SSH keys for authentication

### Secrets Management
- Never commit actual secrets to the repository
- Use the `secrets.sh` script for sensitive setup
- Keep actual secrets in encrypted dotfiles
- Use environment variables for runtime secrets

### Access Control
- Use GitHub teams for access management
- Regularly review who has access
- Audit changes to bootstrap configurations

## Troubleshooting

### Common Issues

#### "gh command not found"
```bash
# Install GitHub CLI
brew install gh

# Authenticate
gh auth login
```

#### "Permission denied (publickey)"
```bash
# Generate SSH key
ssh-keygen -t ed25519 -C "your.email@example.com"

# Add to GitHub
cat ~/.ssh/id_ed25519.pub
# Copy and paste to GitHub Settings > SSH Keys
```

#### "Repository already exists"
```bash
# Remove existing directory
rm -rf ~/Workspace/Git/private-dotfiles-bootstrap

# Or use a different name
create-private-bootstrap --repo-name my-new-bootstrap
```

## Next Steps

1. **Create your private repository** using `create-private-bootstrap`
2. **Add your actual company projects** by copying the template
3. **Test the setup** with `bootstrap --dry-run`
4. **Share with your team** by giving them access to the private repo
5. **Maintain and update** as your project structure evolves

## Related Documentation

- **[Getting Started](getting-started.md)** - Basic dotfiles setup
- **[Configuration Guide](configuration.md)** - Customize your environment
- **[Multi-Machine Sync](sync-guide.md)** - Sync across machines
- **[Command Reference](commands.md)** - All available commands