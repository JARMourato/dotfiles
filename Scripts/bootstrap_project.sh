#!/bin/bash

# Project Bootstrap System
# Allows bootstrapping private company/project environments

set -euo pipefail

# Configuration
PRIVATE_BOOTSTRAP_REPO="${PRIVATE_BOOTSTRAP_REPO:-git@github.com:jarmourato/private-dotfiles-bootstrap.git}"
BOOTSTRAP_CACHE_DIR="$HOME/.dotfiles/cache/bootstrap"
PROJECT_CONFIGS_DIR="$HOME/.dotfiles/private-configs"

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
🚀 Project Bootstrap System

USAGE:
    bootstrap_project.sh <project_name> [options]
    
ARGUMENTS:
    project_name    Name of the project/company to bootstrap
    
OPTIONS:
    --repo URL      Custom private repository URL
    --branch NAME   Specific branch to use (default: main)
    --force         Force re-download even if cached
    --dry-run       Show what would be done without executing
    --list          List available projects
    
EXAMPLES:
    bootstrap_project.sh tellus
    bootstrap_project.sh mycompany --repo git@github.com:company/bootstrap.git
    bootstrap_project.sh tellus --force
    bootstrap_project.sh --list
    
PRIVATE REPOSITORY STRUCTURE:
    private-bootstrap-repo/
    ├── projects/
    │   ├── tellus/
    │   │   ├── bootstrap.sh      # Main bootstrap script
    │   │   ├── repos.txt         # List of repositories to clone
    │   │   ├── packages.txt      # Additional packages needed
    │   │   └── secrets.sh        # Secrets setup (optional)
    │   └── company2/
    │       └── ...
    └── README.md
    
SECURITY:
    • Uses SSH keys for private repository access
    • Secrets are handled separately and never committed
    • Each project has isolated configuration
    
EOF
}

# Check if SSH key is configured for GitHub
check_ssh_access() {
    log_info "Checking SSH access to private repositories..."
    
    if ! ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
        log_error "SSH access to GitHub not configured"
        log_info "Run: ssh-keygen -t ed25519 -C 'your_email@example.com'"
        log_info "Then add the key to GitHub: cat ~/.ssh/id_ed25519.pub"
        return 1
    fi
    
    log_success "SSH access configured"
    return 0
}

# Clone or update private bootstrap repository
setup_private_repo() {
    local repo_url="$1"
    local force="$2"
    
    mkdir -p "$BOOTSTRAP_CACHE_DIR"
    
    if [[ -d "$BOOTSTRAP_CACHE_DIR/private-bootstrap" && "$force" != "true" ]]; then
        log_info "Updating existing private bootstrap repository..."
        cd "$BOOTSTRAP_CACHE_DIR/private-bootstrap"
        git pull
    else
        log_info "Cloning private bootstrap repository..."
        rm -rf "$BOOTSTRAP_CACHE_DIR/private-bootstrap"
        git clone "$repo_url" "$BOOTSTRAP_CACHE_DIR/private-bootstrap"
    fi
}

# List available projects
list_projects() {
    local projects_dir="$BOOTSTRAP_CACHE_DIR/private-bootstrap/projects"
    
    if [[ ! -d "$projects_dir" ]]; then
        log_error "No private bootstrap repository found. Run with a project name first."
        return 1
    fi
    
    log_info "Available projects:"
    echo ""
    
    for project_dir in "$projects_dir"/*; do
        if [[ -d "$project_dir" ]]; then
            local project_name=$(basename "$project_dir")
            local description=""
            
            # Try to get description from bootstrap script
            if [[ -f "$project_dir/bootstrap.sh" ]]; then
                description=$(grep "^# Description:" "$project_dir/bootstrap.sh" 2>/dev/null | cut -d':' -f2- | xargs || echo "")
            fi
            
            if [[ -n "$description" ]]; then
                echo "  📁 $project_name - $description"
            else
                echo "  📁 $project_name"
            fi
        fi
    done
    echo ""
}

# Bootstrap a specific project
bootstrap_project() {
    local project_name="$1"
    local dry_run="$2"
    
    local project_dir="$BOOTSTRAP_CACHE_DIR/private-bootstrap/projects/$project_name"
    local bootstrap_script="$project_dir/bootstrap.sh"
    
    if [[ ! -d "$project_dir" ]]; then
        log_error "Project '$project_name' not found in private repository"
        log_info "Available projects:"
        list_projects
        return 1
    fi
    
    if [[ ! -f "$bootstrap_script" ]]; then
        log_error "Bootstrap script not found: $bootstrap_script"
        return 1
    fi
    
    log_info "Bootstrapping project: $project_name"
    
    if [[ "$dry_run" == "true" ]]; then
        log_info "DRY RUN - Would execute:"
        echo "  Script: $bootstrap_script"
        
        # Show what repositories would be cloned
        if [[ -f "$project_dir/repos.txt" ]]; then
            echo "  Repositories to clone:"
            while IFS= read -r repo; do
                [[ -n "$repo" && ! "$repo" =~ ^# ]] && echo "    - $repo"
            done < "$project_dir/repos.txt"
        fi
        
        # Show additional packages
        if [[ -f "$project_dir/packages.txt" ]]; then
            echo "  Additional packages:"
            cat "$project_dir/packages.txt"
        fi
        
        return 0
    fi
    
    # Create project-specific config directory
    mkdir -p "$PROJECT_CONFIGS_DIR/$project_name"
    
    # Execute the bootstrap script
    log_info "Executing bootstrap script..."
    cd "$project_dir"
    chmod +x "$bootstrap_script"
    
    # Pass project name and config directory to the script
    export PROJECT_NAME="$project_name"
    export PROJECT_CONFIG_DIR="$PROJECT_CONFIGS_DIR/$project_name"
    export DOTFILES_DIR="$HOME/.dotfiles"
    
    "$bootstrap_script"
    
    log_success "Project '$project_name' bootstrapped successfully"
}

# Main execution
main() {
    local project_name=""
    local repo_url="$PRIVATE_BOOTSTRAP_REPO"
    local branch="main"
    local force="false"
    local dry_run="false"
    local list_only="false"
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --repo)
                repo_url="$2"
                shift 2
                ;;
            --branch)
                branch="$2"
                shift 2
                ;;
            --force)
                force="true"
                shift
                ;;
            --dry-run)
                dry_run="true"
                shift
                ;;
            --list)
                list_only="true"
                shift
                ;;
            --help|-h)
                show_usage
                exit 0
                ;;
            -*)
                log_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
            *)
                if [[ -z "$project_name" ]]; then
                    project_name="$1"
                else
                    log_error "Multiple project names specified"
                    exit 1
                fi
                shift
                ;;
        esac
    done
    
    # Check SSH access
    if ! check_ssh_access; then
        exit 1
    fi
    
    # Setup private repository
    setup_private_repo "$repo_url" "$force"
    
    # List projects if requested
    if [[ "$list_only" == "true" ]]; then
        list_projects
        exit 0
    fi
    
    # Bootstrap project
    if [[ -z "$project_name" ]]; then
        log_error "No project name specified"
        show_usage
        exit 1
    fi
    
    bootstrap_project "$project_name" "$dry_run"
}

# Run main function with all arguments
main "$@"