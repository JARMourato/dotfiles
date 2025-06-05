#!/bin/bash

# Private Bootstrap Repository Generator
# Creates a template private repository for company/project bootstrapping

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() { echo -e "${BLUE}[INFO]${NC} $*"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; }

show_usage() {
    cat << 'EOF'
🏗️  Private Bootstrap Repository Generator

DESCRIPTION:
    Creates a template private repository for company/project bootstrapping.
    Generates the repository structure, example projects, and documentation.

USAGE:
    create_private_bootstrap.sh [options]
    
OPTIONS:
    --repo-name NAME    Name for the private repository (default: private-dotfiles-bootstrap)
    --github-user USER  GitHub username (default: current git user)
    --create-repo       Create the GitHub repository automatically
    --push-repo         Push to remote repository after creation
    --example-company   Name for example company (default: acme)
    --output-dir DIR    Directory to create repository (default: ~/Workspace/Git)
    --help              Show this help message
    
EXAMPLES:
    # Create repository locally with defaults
    create_private_bootstrap.sh
    
    # Create with custom settings
    create_private_bootstrap.sh --repo-name my-bootstrap --github-user myusername
    
    # Create and push to GitHub automatically
    create_private_bootstrap.sh --create-repo --push-repo
    
    # Custom company example
    create_private_bootstrap.sh --example-company mycompany
    
WHAT IT CREATES:
    • Private repository structure
    • Example company project template
    • Documentation and README
    • GitHub repository (if --create-repo specified)
    • Automatic push to remote (if --push-repo specified)
    
AFTER CREATION:
    • Update your .dotfiles.config with the new repository URL
    • Add your actual company projects using the template
    • Test with: bootstrap <company-name>
    
EOF
}

# Get current Git user
get_git_user() {
    git config user.name 2>/dev/null || echo ""
}

# Get current Git email
get_git_email() {
    git config user.email 2>/dev/null || echo ""
}

# Create the repository structure
create_repository_structure() {
    local repo_dir="$1"
    local example_company="$2"
    local git_user="$3"
    local git_email="$4"
    
    log_info "Creating repository structure..."
    
    mkdir -p "$repo_dir"
    cd "$repo_dir"
    
    # Initialize git repository
    git init
    
    # Create main README
    cat > README.md << EOF
# Private Dotfiles Bootstrap

This repository contains private company/project bootstrap configurations for automated development environment setup.

## Quick Start

\`\`\`bash
# Bootstrap a project
bootstrap <project-name>

# List available projects
bootstrap --list

# Preview what would happen
bootstrap <project-name> --dry-run
\`\`\`

## Repository Structure

\`\`\`
private-dotfiles-bootstrap/
├── README.md
├── docs/
│   ├── adding-projects.md
│   └── security.md
└── projects/
    ├── ${example_company}/
    │   ├── bootstrap.sh      # Main setup script
    │   ├── repos.txt         # Repositories to clone
    │   ├── packages.txt      # Additional packages
    │   └── secrets.sh        # Secrets setup (optional)
    └── template/
        ├── bootstrap.sh      # Template for new projects
        ├── repos.txt
        └── packages.txt
\`\`\`

## Adding New Projects

1. Copy the \`template\` directory:
   \`\`\`bash
   cp -r projects/template projects/your-company
   \`\`\`

2. Edit the files in \`projects/your-company/\`:
   - Update \`bootstrap.sh\` with your setup logic
   - Add repositories to \`repos.txt\`
   - Add packages to \`packages.txt\`

3. Test the setup:
   \`\`\`bash
   bootstrap your-company --dry-run
   bootstrap your-company
   \`\`\`

## Security

- This repository should be **private**
- Never commit secrets or credentials
- Use the \`secrets.sh\` script for sensitive setup
- Keep secrets in encrypted dotfiles instead

## Configuration

Add this to your \`~/.dotfiles/.dotfiles.config\`:

\`\`\`bash
PRIVATE_BOOTSTRAP_REPO="git@github.com:${git_user}/$(basename "$repo_dir").git"
\`\`\`

## Created by

**User**: ${git_user} <${git_email}>  
**Date**: $(date '+%Y-%m-%d %H:%M:%S')  
**Generated with**: dotfiles/Scripts/create_private_bootstrap.sh
EOF

    # Create docs directory
    mkdir -p docs
    
    # Create documentation files
    create_documentation "$example_company"
    
    # Create projects structure
    mkdir -p projects
    
    # Create template project
    create_template_project
    
    # Create example company project
    create_example_project "$example_company"
    
    log_success "Repository structure created successfully"
}

# Create documentation files
create_documentation() {
    local example_company="$1"
    
    # Adding projects guide
    cat > docs/adding-projects.md << EOF
# Adding New Projects

## Step 1: Create Project Directory

Copy the template to create a new project:

\`\`\`bash
cp -r projects/template projects/your-company-name
cd projects/your-company-name
\`\`\`

## Step 2: Configure Bootstrap Script

Edit \`bootstrap.sh\` to customize for your company:

\`\`\`bash
vim bootstrap.sh
\`\`\`

Key areas to customize:
- **Description**: Update the description comment
- **Directories**: Change workspace paths if needed  
- **Repositories**: Update the repository URLs
- **Packages**: Add company-specific tools
- **Aliases**: Create helpful project shortcuts

## Step 3: Configure Repository List

Edit \`repos.txt\` to list your repositories:

\`\`\`
# Format: git_url destination_directory
git@github.com:company/frontend.git frontend
git@github.com:company/backend.git backend
git@github.com:company/mobile.git mobile
\`\`\`

## Step 4: Configure Additional Packages

Edit \`packages.txt\` for company-specific tools:

\`\`\`
# Development tools
company-cli-tool
specific-linter
custom-build-tool
\`\`\`

## Step 5: Test Your Configuration

\`\`\`bash
# Preview what would happen
bootstrap your-company-name --dry-run

# Run the actual bootstrap
bootstrap your-company-name
\`\`\`

## Example: ${example_company^} Company

See \`projects/${example_company}/\` for a complete example of how to structure a company project.
EOF

    # Security guide
    cat > docs/security.md << EOF
# Security Guide

## Repository Security

### Private Repository
- This repository MUST be private
- Only grant access to team members who need it
- Regularly review access permissions

### SSH Keys
- Ensure all team members have SSH keys configured
- Use ed25519 keys for better security
- Rotate keys periodically

## Secrets Management

### Never Commit Secrets
❌ **Don't do this:**
- API keys in bootstrap scripts
- Database passwords in configuration files
- Private certificates or keys

✅ **Do this instead:**
- Use the \`secrets.sh\` script for sensitive setup
- Keep secrets in encrypted dotfiles
- Use environment variables for runtime secrets

### Secrets Script Example

\`\`\`bash
#!/bin/bash
# secrets.sh - Handle sensitive configuration

# Decrypt existing secrets from dotfiles
if [[ -f "\$DOTFILES_DIR/.company-secrets.encrypted" ]]; then
    "\$DOTFILES_DIR/Scripts/decrypt_files.sh" .company-secrets.encrypted
fi

# Create environment files with placeholders
cat > ~/Workspace/Git/Company/backend/.env << 'ENV_EOF'
# Environment configuration
DATABASE_URL=postgresql://localhost:5432/company_dev
API_KEY=<your-api-key-here>
ENVIRONMENT=development
ENV_EOF

echo "⚠️  Remember to update .env files with actual values!"
\`\`\`

## Access Control

### Team Access
- Use GitHub teams for access control
- Separate repositories for different security levels
- Document who has access to what

### Audit Trail
- Regular review of access logs
- Track changes to bootstrap configurations
- Monitor repository access

## Best Practices

1. **Principle of Least Privilege**: Only grant necessary access
2. **Regular Reviews**: Audit access and configurations quarterly
3. **Secure Defaults**: Bootstrap scripts should create secure configurations
4. **Documentation**: Keep security procedures documented and updated
5. **Incident Response**: Have a plan for when security issues arise
EOF
}

# Create template project
create_template_project() {
    mkdir -p projects/template
    
    cat > projects/template/bootstrap.sh << 'EOF'
#!/bin/bash
# Description: Template for new company/project bootstrap

set -e # Immediately rethrows exceptions

# Use environment variables provided by bootstrap system
PROJECT_NAME="${PROJECT_NAME:-template}"
PROJECT_CONFIG_DIR="${PROJECT_CONFIG_DIR:-$HOME/.dotfiles/private-configs/template}"
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/.dotfiles}"

echo "🚀 Setting up ${PROJECT_NAME} project environment..."

#################################################################################
#### Configure Directories
#################################################################################

echo "📁 Setting up directories..."
WORKSPACE_DIR="$HOME/Workspace/Git/${PROJECT_NAME^}"
rm -rf "$WORKSPACE_DIR"
mkdir -p "$WORKSPACE_DIR"

#################################################################################
#### Clone repositories
#################################################################################

echo "📦 Cloning repositories..."

# Read repositories from repos.txt if it exists
if [[ -f "repos.txt" ]]; then
    while IFS= read -r repo_line; do
        # Skip empty lines and comments
        [[ -z "$repo_line" || "$repo_line" =~ ^# ]] && continue
        
        # Parse: repo_url destination_name
        repo_url=$(echo "$repo_line" | awk '{print $1}')
        dest_name=$(echo "$repo_line" | awk '{print $2}')
        
        if [[ -n "$repo_url" && -n "$dest_name" ]]; then
            echo "  Cloning $dest_name..."
            git clone "$repo_url" "$WORKSPACE_DIR/$dest_name"
        fi
    done < repos.txt
else
    echo "  No repos.txt found - add your repositories there"
fi

#################################################################################
#### Install additional packages
#################################################################################

echo "📦 Installing additional packages..."
if [[ -f "packages.txt" ]]; then
    while IFS= read -r package; do
        [[ -z "$package" || "$package" =~ ^# ]] && continue
        echo "  Installing $package..."
        brew install "$package" 2>/dev/null || echo "    Already installed or failed: $package"
    done < packages.txt
fi

#################################################################################
#### Set up secrets
#################################################################################

if [[ -f "secrets.sh" && -x "secrets.sh" ]]; then
    echo "🔐 Setting up secrets..."
    ./secrets.sh
else
    echo "🔐 Secrets setup skipped (no executable secrets.sh found)"
fi

#################################################################################
#### Create project aliases
#################################################################################

echo "⚡ Setting up project aliases..."
mkdir -p "$PROJECT_CONFIG_DIR"

cat > "$PROJECT_CONFIG_DIR/aliases.sh" << ALIASES_EOF
# ${PROJECT_NAME^} project aliases
alias ${PROJECT_NAME}-root="cd $WORKSPACE_DIR"

# Add more aliases here for your specific project structure
# alias ${PROJECT_NAME}-frontend="cd $WORKSPACE_DIR/frontend"
# alias ${PROJECT_NAME}-backend="cd $WORKSPACE_DIR/backend"
ALIASES_EOF

# Add to main aliases if not already there
if ! grep -q "source $PROJECT_CONFIG_DIR/aliases.sh" "$DOTFILES_DIR/.aliases" 2>/dev/null; then
    echo "source $PROJECT_CONFIG_DIR/aliases.sh" >> "$DOTFILES_DIR/.aliases"
fi

echo "✅ ${PROJECT_NAME^} project setup complete!"
echo ""
echo "Available commands:"
echo "  ${PROJECT_NAME}-root    - Go to project root directory"
echo ""
echo "Next steps:"
echo "  1. Customize this script for your specific needs"
echo "  2. Add your repositories to repos.txt"
echo "  3. Add required packages to packages.txt"
echo "  4. Create secrets.sh if you need secrets setup"
EOF

    chmod +x projects/template/bootstrap.sh
    
    cat > projects/template/repos.txt << 'EOF'
# Repository list for template project
# Format: git_url destination_directory
# Example:
# git@github.com:company/frontend.git frontend
# git@github.com:company/backend.git backend
# git@github.com:company/mobile.git mobile
EOF

    cat > projects/template/packages.txt << 'EOF'
# Additional packages for template project
# Add one package per line
# Example:
# company-cli-tool
# specific-linter
# custom-debugger
EOF
}

# Create example project
create_example_project() {
    local company="$1"
    
    mkdir -p "projects/$company"
    
    cat > "projects/$company/bootstrap.sh" << EOF
#!/bin/bash
# Description: ${company^} company development environment setup

set -e # Immediately rethrows exceptions

# Use environment variables provided by bootstrap system
PROJECT_NAME="\${PROJECT_NAME:-$company}"
PROJECT_CONFIG_DIR="\${PROJECT_CONFIG_DIR:-\$HOME/.dotfiles/private-configs/$company}"
DOTFILES_DIR="\${DOTFILES_DIR:-\$HOME/.dotfiles}"

echo "🚀 Setting up ${company^} company environment..."

#################################################################################
#### Configure Directories
#################################################################################

echo "📁 Setting up directories..."
WORKSPACE_DIR="\$HOME/Workspace/Git/${company^}"
rm -rf "\$WORKSPACE_DIR"
mkdir -p "\$WORKSPACE_DIR"

#################################################################################
#### Clone repositories
#################################################################################

echo "📦 Cloning repositories..."

# Read repositories from repos.txt
if [[ -f "repos.txt" ]]; then
    while IFS= read -r repo_line; do
        # Skip empty lines and comments
        [[ -z "\$repo_line" || "\$repo_line" =~ ^# ]] && continue
        
        # Parse: repo_url destination_name
        repo_url=\$(echo "\$repo_line" | awk '{print \$1}')
        dest_name=\$(echo "\$repo_line" | awk '{print \$2}')
        
        if [[ -n "\$repo_url" && -n "\$dest_name" ]]; then
            echo "  Cloning \$dest_name..."
            git clone "\$repo_url" "\$WORKSPACE_DIR/\$dest_name"
        fi
    done < repos.txt
fi

#################################################################################
#### Install additional packages
#################################################################################

echo "📦 Installing additional packages..."
if [[ -f "packages.txt" ]]; then
    while IFS= read -r package; do
        [[ -z "\$package" || "\$package" =~ ^# ]] && continue
        echo "  Installing \$package..."
        brew install "\$package" 2>/dev/null || echo "    Already installed or failed: \$package"
    done < packages.txt
fi

#################################################################################
#### Set up secrets
#################################################################################

if [[ -f "secrets.sh" && -x "secrets.sh" ]]; then
    echo "🔐 Setting up secrets..."
    ./secrets.sh
else
    echo "🔐 Secrets setup skipped"
    echo "   Create secrets.sh for sensitive configuration"
fi

#################################################################################
#### Create project aliases
#################################################################################

echo "⚡ Setting up project aliases..."
mkdir -p "\$PROJECT_CONFIG_DIR"

cat > "\$PROJECT_CONFIG_DIR/aliases.sh" << 'ALIASES_EOF'
# ${company^} company aliases
alias $company-root="cd \$WORKSPACE_DIR"
alias $company-frontend="cd \$WORKSPACE_DIR/frontend"
alias $company-backend="cd \$WORKSPACE_DIR/backend"
alias $company-mobile="cd \$WORKSPACE_DIR/mobile"

# ${company^} development commands
alias $company-build="$company-root && make build"
alias $company-test="$company-root && make test"
alias $company-deploy="$company-root && make deploy"
ALIASES_EOF

# Add to main aliases if not already there
if ! grep -q "source \$PROJECT_CONFIG_DIR/aliases.sh" "\$DOTFILES_DIR/.aliases" 2>/dev/null; then
    echo "source \$PROJECT_CONFIG_DIR/aliases.sh" >> "\$DOTFILES_DIR/.aliases"
fi

echo "✅ ${company^} company setup complete!"
echo ""
echo "Available commands:"
echo "  $company-root       - Go to company root directory"
echo "  $company-frontend   - Go to frontend project"
echo "  $company-backend    - Go to backend project"
echo "  $company-mobile     - Go to mobile project"
echo "  $company-build      - Build all projects"
echo "  $company-test       - Run all tests"
echo "  $company-deploy     - Deploy projects"
echo ""
echo "Next steps:"
echo "  1. Configure secrets if needed"
echo "  2. Install project dependencies"
echo "  3. Run initial builds and tests"
EOF

    chmod +x "projects/$company/bootstrap.sh"
    
    cat > "projects/$company/repos.txt" << EOF
# ${company^} company repositories
# Format: git_url destination_directory
git@github.com:${company}corp/frontend.git frontend
git@github.com:${company}corp/backend.git backend
git@github.com:${company}corp/mobile.git mobile
EOF

    cat > "projects/$company/packages.txt" << EOF
# Additional packages for ${company^} development
docker-compose
kubernetes-cli
${company}-cli
company-linter
EOF

    # Create example secrets.sh
    cat > "projects/$company/secrets.sh" << EOF
#!/bin/bash
# ${company^} secrets setup

echo "🔐 Setting up ${company^} secrets..."

# Create environment files
echo "  Creating environment configurations..."

# Frontend environment
cat > "\$WORKSPACE_DIR/frontend/.env.local" << 'ENV_EOF'
# ${company^} Frontend Environment
NEXT_PUBLIC_API_URL=http://localhost:3001
NEXT_PUBLIC_ENVIRONMENT=development
ENV_EOF

# Backend environment
cat > "\$WORKSPACE_DIR/backend/.env" << 'ENV_EOF'
# ${company^} Backend Environment
DATABASE_URL=postgresql://localhost:5432/${company}_dev
REDIS_URL=redis://localhost:6379
JWT_SECRET=your-jwt-secret-here
ENVIRONMENT=development
ENV_EOF

echo "  ✅ Environment files created"
echo "     Remember to update with actual values!"
EOF

    chmod +x "projects/$company/secrets.sh"
}

# Create GitHub repository
create_github_repo() {
    local repo_name="$1"
    local github_user="$2"
    
    log_info "Creating GitHub repository..."
    
    # Check if gh CLI is available
    if ! command -v gh >/dev/null 2>&1; then
        log_error "GitHub CLI (gh) is not installed"
        log_info "Install with: brew install gh"
        log_info "Then authenticate with: gh auth login"
        return 1
    fi
    
    # Check if authenticated
    if ! gh auth status >/dev/null 2>&1; then
        log_error "Not authenticated with GitHub CLI"
        log_info "Run: gh auth login"
        return 1
    fi
    
    # Create the repository
    if gh repo create "$github_user/$repo_name" --private --clone=false >/dev/null 2>&1; then
        log_success "GitHub repository created: $github_user/$repo_name"
        return 0
    else
        log_warn "Repository might already exist or creation failed"
        return 1
    fi
}

# Push to remote repository
push_to_remote() {
    local repo_name="$1"
    local github_user="$2"
    
    log_info "Pushing to remote repository..."
    
    # Add remote
    git remote add origin "git@github.com:$github_user/$repo_name.git"
    
    # Add all files
    git add .
    
    # Commit
    git commit -m "Initial private bootstrap repository setup

- Add template project structure
- Add example company ($example_company) configuration
- Include documentation and security guidelines
- Generated with dotfiles create_private_bootstrap.sh"
    
    # Push
    if git push -u origin main; then
        log_success "Repository pushed successfully"
        return 0
    else
        log_error "Failed to push to remote repository"
        return 1
    fi
}

# Update dotfiles configuration
update_dotfiles_config() {
    local repo_name="$1"
    local github_user="$2"
    
    local dotfiles_config="$HOME/.dotfiles/.dotfiles.config"
    local repo_url="git@github.com:$github_user/$repo_name.git"
    
    log_info "Updating dotfiles configuration..."
    
    # Check if config exists
    if [[ ! -f "$dotfiles_config" ]]; then
        log_warn "Dotfiles config not found, creating it..."
        touch "$dotfiles_config"
    fi
    
    # Add or update the private repo URL
    if grep -q "PRIVATE_BOOTSTRAP_REPO=" "$dotfiles_config"; then
        # Update existing line
        sed -i.bak "s|PRIVATE_BOOTSTRAP_REPO=.*|PRIVATE_BOOTSTRAP_REPO=\"$repo_url\"|" "$dotfiles_config"
        rm -f "$dotfiles_config.bak"
    else
        # Add new line
        echo "" >> "$dotfiles_config"
        echo "# Private bootstrap repository" >> "$dotfiles_config"
        echo "PRIVATE_BOOTSTRAP_REPO=\"$repo_url\"" >> "$dotfiles_config"
    fi
    
    log_success "Dotfiles configuration updated"
    log_info "Repository URL: $repo_url"
}

# Main execution
main() {
    local repo_name="private-dotfiles-bootstrap"
    local github_user=""
    local create_repo=false
    local push_repo=false
    local example_company="acme"
    local output_dir="$HOME/Workspace/Git"
    
    # Get default GitHub user
    github_user=$(get_git_user)
    if [[ -z "$github_user" ]]; then
        github_user="your-username"
    fi
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --repo-name)
                repo_name="$2"
                shift 2
                ;;
            --github-user)
                github_user="$2"
                shift 2
                ;;
            --create-repo)
                create_repo=true
                shift
                ;;
            --push-repo)
                push_repo=true
                shift
                ;;
            --example-company)
                example_company="$2"
                shift 2
                ;;
            --output-dir)
                output_dir="$2"
                shift 2
                ;;
            --help|-h)
                show_usage
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    local repo_dir="$output_dir/$repo_name"
    local git_user=$(get_git_user)
    local git_email=$(get_git_email)
    
    # Validate inputs
    if [[ -z "$git_user" ]]; then
        log_error "Git user not configured. Run: git config --global user.name 'Your Name'"
        exit 1
    fi
    
    if [[ -z "$git_email" ]]; then
        log_error "Git email not configured. Run: git config --global user.email 'your@email.com'"
        exit 1
    fi
    
    # Check if directory already exists
    if [[ -d "$repo_dir" ]]; then
        log_error "Directory already exists: $repo_dir"
        read -p "Remove existing directory and continue? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm -rf "$repo_dir"
        else
            exit 1
        fi
    fi
    
    # Create the repository structure
    create_repository_structure "$repo_dir" "$example_company" "$git_user" "$git_email"
    
    # Create GitHub repository if requested
    if [[ "$create_repo" == true ]]; then
        create_github_repo "$repo_name" "$github_user"
    fi
    
    # Push to remote if requested
    if [[ "$push_repo" == true ]]; then
        push_to_remote "$repo_name" "$github_user"
        update_dotfiles_config "$repo_name" "$github_user"
    fi
    
    # Final instructions
    echo ""
    log_success "Private bootstrap repository created successfully!"
    echo ""
    echo "📁 Repository location: $repo_dir"
    echo "🏢 Example company: $example_company"
    echo ""
    echo "Next steps:"
    echo "1. Review the generated files in $repo_dir"
    
    if [[ "$create_repo" == false ]]; then
        echo "2. Create GitHub repository manually:"
        echo "   gh repo create $github_user/$repo_name --private"
    fi
    
    if [[ "$push_repo" == false ]]; then
        echo "3. Push to GitHub:"
        echo "   cd $repo_dir"
        echo "   git remote add origin git@github.com:$github_user/$repo_name.git"
        echo "   git add . && git commit -m 'Initial setup'"
        echo "   git push -u origin main"
        echo "4. Update your dotfiles config:"
        echo "   echo 'PRIVATE_BOOTSTRAP_REPO=\"git@github.com:$github_user/$repo_name.git\"' >> ~/.dotfiles/.dotfiles.config"
    fi
    
    echo "5. Test the setup:"
    echo "   bootstrap $example_company --dry-run"
    echo "   bootstrap $example_company"
    echo ""
    echo "6. Add your actual company projects:"
    echo "   cp -r $repo_dir/projects/template $repo_dir/projects/your-company"
    echo "   # Edit the files in projects/your-company/"
    echo ""
}

# Run main function with all arguments
main "$@"