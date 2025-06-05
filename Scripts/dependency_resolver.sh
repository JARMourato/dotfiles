#!/bin/bash
set -euo pipefail

################################################################################
### Smart Dependency Resolution System
################################################################################
# Intelligent dependency detection, resolution, and installation with fallbacks
# Scans dotfiles, projects, and scripts to identify required tools automatically

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"
DEPENDENCY_LOG="$HOME/.dotfiles_dependencies.log"
MISSING_DEPS_FILE="$HOME/.dotfiles_missing_deps.json"
DEPENDENCY_GRAPH="$HOME/.dotfiles_dependency_graph.txt"

# Load progress indicators
source "$SCRIPT_DIR/progress_indicators.sh" 2>/dev/null || true

################################################################################
### Dependency Scanning
################################################################################

scan_all_dependencies() {
    echo "🔍 Scanning for required dependencies..."
    
    # Create temporary file to collect all dependencies
    local all_deps_file=$(mktemp)
    
    # Scan different sources and combine results
    scan_dotfiles_dependencies >> "$all_deps_file"
    scan_project_dependencies >> "$all_deps_file"
    scan_script_dependencies >> "$all_deps_file"
    scan_package_file_dependencies >> "$all_deps_file"
    
    # Remove duplicates, filter out noise, and sort
    grep -E '^[a-zA-Z0-9_-]+$' "$all_deps_file" 2>/dev/null | \
        grep -vE '^(echo|printf|cat|head|tail|awk|sed|grep|find|sort|uniq|wc|rm|mkdir|touch|Scanning|configurations|dependencies|dotfiles|files|manager|package|project|scripts)$' | \
        grep -vE '^(📁|📦|📜|🏗️)$' | \
        grep -E '^[a-zA-Z][a-zA-Z0-9_-]*$' | \
        sort -u > /tmp/all_dependencies.txt
    
    rm -f "$all_deps_file"
    
    echo "📊 Found $(wc -l < /tmp/all_dependencies.txt) unique dependencies"
    
    # Analyze what's missing
    analyze_missing_dependencies
}

scan_dotfiles_dependencies() {
    echo "  📁 Scanning dotfiles configurations..."
    
    local temp_deps=$(mktemp)
    
    # Scan shell configs for command usage
    if [ -f "$HOME/.zshrc" ]; then
        # Extract commands from common patterns
        grep -ho 'command -v [a-zA-Z0-9_-]*\|which [a-zA-Z0-9_-]*\|brew install [a-zA-Z0-9_-]*' "$HOME/.zshrc" 2>/dev/null | \
            awk '{print $NF}' | sed 's/[^a-zA-Z0-9_-]//g' | grep -v '^$' >> "$temp_deps"
    fi
    
    # Scan aliases for tools
    if [ -f "$HOME/.aliases" ]; then
        grep -o "alias [^=]*=['\"].*['\"]" "$HOME/.aliases" 2>/dev/null | \
            sed "s/alias [^=]*=['\"]//; s/['\"].*$//" | awk '{print $1}' >> "$temp_deps"
    fi
    
    # Scan functions for commands
    if [ -f "$HOME/.functions" ]; then
        grep -ho '\b[a-zA-Z0-9_-]*\b' "$HOME/.functions" 2>/dev/null | \
            grep -E '^(git|brew|npm|node|python|docker|kubectl|aws|terraform|ansible)' >> "$temp_deps"
    fi
    
    # Output unique dependencies
    sort -u "$temp_deps" 2>/dev/null || true
    rm -f "$temp_deps"
}

scan_project_dependencies() {
    echo "  🏗️ Scanning project files..."
    
    local temp_deps=$(mktemp)
    
    # Node.js projects
    find . -maxdepth 3 -name "package.json" 2>/dev/null | while read -r package_file; do
        if command -v jq >/dev/null 2>&1; then
            # Extract global dependencies that might be needed
            jq -r '.scripts // {} | to_entries[] | .value' "$package_file" 2>/dev/null | \
                grep -ho '\b[a-zA-Z0-9_-]*\b' | \
                grep -E '^(webpack|vite|typescript|eslint|prettier|jest|cypress)' >> "$temp_deps"
        fi
        echo "node" >> "$temp_deps"
        echo "npm" >> "$temp_deps"
    done
    
    # Python projects
    find . -maxdepth 3 -name "requirements.txt" -o -name "Pipfile" -o -name "pyproject.toml" 2>/dev/null | while read -r python_file; do
        echo "python" >> "$temp_deps"
        echo "pip" >> "$temp_deps"
        [[ "$python_file" == *"Pipfile"* ]] && echo "pipenv" >> "$temp_deps"
        [[ "$python_file" == *"pyproject.toml"* ]] && echo "poetry" >> "$temp_deps"
    done
    
    # Swift projects
    if find . -maxdepth 3 -name "Package.swift" -o -name "*.xcodeproj" -o -name "*.xcworkspace" 2>/dev/null | grep -q .; then
        echo "swift" >> "$temp_deps"
        echo "swiftlint" >> "$temp_deps"
        echo "swiftformat" >> "$temp_deps"
    fi
    
    # Docker projects
    find . -maxdepth 3 -name "Dockerfile" -o -name "docker-compose.yml" -o -name "docker-compose.yaml" 2>/dev/null | while read -r docker_file; do
        echo "docker" >> "$temp_deps"
        [[ "$docker_file" == *"compose"* ]] && echo "docker-compose" >> "$temp_deps"
    done
    
    # Kubernetes projects
    if find . -maxdepth 3 -name "*.yaml" -o -name "*.yml" 2>/dev/null | xargs grep -l "apiVersion\|kind:" 2>/dev/null | grep -q .; then
        echo "kubectl" >> "$temp_deps"
    fi
    
    # Terraform projects
    if find . -maxdepth 3 -name "*.tf" 2>/dev/null | grep -q .; then
        echo "terraform" >> "$temp_deps"
    fi
    
    # Go projects
    if find . -maxdepth 3 -name "go.mod" -o -name "*.go" 2>/dev/null | grep -q .; then
        echo "go" >> "$temp_deps"
    fi
    
    # Rust projects
    if find . -maxdepth 3 -name "Cargo.toml" 2>/dev/null | grep -q .; then
        echo "rust" >> "$temp_deps"
        echo "cargo" >> "$temp_deps"
    fi
    
    # Output unique dependencies
    sort -u "$temp_deps" 2>/dev/null || true
    rm -f "$temp_deps"
}

scan_script_dependencies() {
    echo "  📜 Scanning scripts for dependencies..."
    
    local temp_deps=$(mktemp)
    
    # Scan all shell scripts in dotfiles
    find "$DOTFILES_DIR" -name "*.sh" -type f 2>/dev/null | while read -r script; do
        # Check shebangs for interpreters
        local shebang
        shebang=$(head -1 "$script" 2>/dev/null)
        case "$shebang" in
            *python*) echo "python" >> "$temp_deps" ;;
            *node*) echo "node" >> "$temp_deps" ;;
            *ruby*) echo "ruby" >> "$temp_deps" ;;
            *perl*) echo "perl" >> "$temp_deps" ;;
        esac
        
        # Extract commonly used commands
        grep -ho '\b[a-zA-Z0-9_-]*\b' "$script" 2>/dev/null | \
            grep -E '^(curl|wget|jq|yq|git|brew|mas|docker|kubectl|aws|gcloud|az|terraform|ansible|rsync|ssh|scp|gpg)$' >> "$temp_deps"
    done
    
    # Output unique dependencies
    sort -u "$temp_deps" 2>/dev/null || true
    rm -f "$temp_deps"
}

scan_package_file_dependencies() {
    echo "  📦 Scanning package manager files..."
    
    local temp_deps=$(mktemp)
    
    # Brewfile
    if [ -f "$DOTFILES_DIR/Brewfile" ]; then
        # Extract formulas and casks
        awk '/^brew |^cask / {gsub(/["'"'"']/, "", $2); print $2}' "$DOTFILES_DIR/Brewfile" >> "$temp_deps"
    fi
    
    # Check if mas is used
    if [ -f "$DOTFILES_DIR/Brewfile" ] && grep -q "^mas " "$DOTFILES_DIR/Brewfile"; then
        echo "mas" >> "$temp_deps"
    fi
    
    # Output unique dependencies
    sort -u "$temp_deps" 2>/dev/null || true
    rm -f "$temp_deps"
}

################################################################################
### Dependency Analysis
################################################################################

analyze_missing_dependencies() {
    echo "🔍 Analyzing missing dependencies..."
    
    local missing_deps=()
    local available_deps=()
    
    if [ ! -f /tmp/all_dependencies.txt ]; then
        echo "⚠️ No dependencies file found. Run scan first."
        return 1
    fi
    
    while IFS= read -r dep; do
        if command -v "$dep" >/dev/null 2>&1; then
            available_deps+=("$dep")
        elif brew list "$dep" >/dev/null 2>&1; then
            available_deps+=("$dep")
        else
            missing_deps+=("$dep")
        fi
    done < /tmp/all_dependencies.txt
    
    echo "✅ Available dependencies: ${#available_deps[@]}"
    echo "❌ Missing dependencies: ${#missing_deps[@]}"
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        # Create missing dependencies JSON
        create_missing_dependencies_json "${missing_deps[@]}"
        
        echo ""
        echo "📋 Missing dependencies:"
        printf '  • %s\n' "${missing_deps[@]}"
        
        # Build dependency graph for missing tools
        build_dependency_graph "${missing_deps[@]}"
    else
        echo "🎉 All dependencies are satisfied!"
        echo '{"missing": [], "resolved": true}' > "$MISSING_DEPS_FILE"
    fi
}

create_missing_dependencies_json() {
    local missing_deps=("$@")
    
    cat > "$MISSING_DEPS_FILE" << EOF
{
    "last_scan": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
    "missing_count": ${#missing_deps[@]},
    "missing": [
EOF
    
    for i in "${!missing_deps[@]}"; do
        local dep="${missing_deps[i]}"
        local comma=""
        [ $i -lt $((${#missing_deps[@]} - 1)) ] && comma=","
        
        cat >> "$MISSING_DEPS_FILE" << EOF
        {
            "name": "$dep",
            "category": "$(categorize_dependency "$dep")",
            "installation_methods": $(get_installation_methods "$dep"),
            "priority": "$(get_dependency_priority "$dep")"
        }$comma
EOF
    done
    
    cat >> "$MISSING_DEPS_FILE" << EOF
    ],
    "resolved": false
}
EOF
}

categorize_dependency() {
    local dep="$1"
    
    case "$dep" in
        git|svn|hg) echo "version_control" ;;
        docker|kubectl|terraform|ansible) echo "devops" ;;
        node|npm|yarn|python|pip|ruby|gem|go|rust|cargo) echo "programming_language" ;;
        curl|wget|jq|yq) echo "utility" ;;
        aws|gcloud|az) echo "cloud" ;;
        mysql|postgresql|redis|mongodb) echo "database" ;;
        *) echo "general" ;;
    esac
}

get_installation_methods() {
    local dep="$1"
    local methods=()
    
    # Check if available via Homebrew
    if brew search "$dep" 2>/dev/null | grep -q "^$dep$"; then
        methods+=("\"homebrew\"")
    fi
    
    # Check if available as cask
    if brew search --cask "$dep" 2>/dev/null | grep -q "^$dep$"; then
        methods+=("\"homebrew_cask\"")
    fi
    
    # Check if available via mas
    if mas search "$dep" 2>/dev/null | grep -q "$dep"; then
        methods+=("\"mas\"")
    fi
    
    # Check for manual installation methods
    case "$dep" in
        node|nodejs) methods+=("\"nvm\"" "\"direct_download\"") ;;
        python) methods+=("\"pyenv\"" "\"direct_download\"") ;;
        go) methods+=("\"gvm\"" "\"direct_download\"") ;;
        rust) methods+=("\"rustup\"") ;;
        bun) methods+=("\"curl_install\"") ;;
        deno) methods+=("\"curl_install\"") ;;
    esac
    
    if [ ${#methods[@]} -eq 0 ]; then
        methods+=("\"manual\"")
    fi
    
    echo "[$(IFS=,; echo "${methods[*]}")]"
}

get_dependency_priority() {
    local dep="$1"
    
    case "$dep" in
        git|curl|wget) echo "critical" ;;
        brew|mas) echo "critical" ;;
        node|python|docker) echo "high" ;;
        jq|tree|htop) echo "medium" ;;
        *) echo "low" ;;
    esac
}

################################################################################
### Dependency Graph and Installation Order
################################################################################

build_dependency_graph() {
    local missing_deps=("$@")
    
    echo "🔗 Building dependency graph..."
    
    # Define dependency relationships
    declare -A DEPENDENCIES=(
        ["docker-compose"]="docker"
        ["kubectl"]="docker"
        ["npm"]="node"
        ["yarn"]="node"
        ["pip"]="python"
        ["pipenv"]="python pip"
        ["poetry"]="python pip"
        ["gem"]="ruby"
        ["cargo"]="rust"
        ["swiftlint"]="swift"
        ["swiftformat"]="swift"
        ["terraform"]="git"
        ["ansible"]="python"
    )
    
    # Create dependency graph file
    > "$DEPENDENCY_GRAPH"
    
    for dep in "${missing_deps[@]}"; do
        local prereqs="${DEPENDENCIES[$dep]:-}"
        echo "$dep: $prereqs" >> "$DEPENDENCY_GRAPH"
    done
    
    echo "✅ Dependency graph created: $DEPENDENCY_GRAPH"
}

calculate_installation_order() {
    local deps_to_install=("$@")
    
    echo "📊 Calculating optimal installation order..."
    
    local ordered_deps=()
    local processed=()
    
    # Simple topological sort
    for dep in "${deps_to_install[@]}"; do
        add_to_order "$dep" ordered_deps processed
    done
    
    # Remove duplicates while preserving order
    printf '%s\n' "${ordered_deps[@]}" | awk '!seen[$0]++'
}

add_to_order() {
    local dep="$1"
    local -n ordered_ref=$2
    local -n processed_ref=$3
    
    # Skip if already processed
    for proc in "${processed_ref[@]}"; do
        [ "$proc" = "$dep" ] && return
    done
    
    # Get dependencies for this tool
    local prereqs
    prereqs=$(grep "^$dep:" "$DEPENDENCY_GRAPH" 2>/dev/null | cut -d':' -f2 | xargs)
    
    # Recursively add prerequisites first
    for prereq in $prereqs; do
        [ -n "$prereq" ] && add_to_order "$prereq" ordered_ref processed_ref
    done
    
    # Add this dependency
    ordered_ref+=("$dep")
    processed_ref+=("$dep")
}

################################################################################
### Smart Installation
################################################################################

resolve_dependencies() {
    echo "🔧 Starting smart dependency resolution..."
    
    if [ ! -f "$MISSING_DEPS_FILE" ]; then
        echo "⚠️ No missing dependencies file found. Run scan first."
        return 1
    fi
    
    local missing_deps
    missing_deps=($(jq -r '.missing[].name' "$MISSING_DEPS_FILE" 2>/dev/null))
    
    if [ ${#missing_deps[@]} -eq 0 ]; then
        echo "✅ No missing dependencies to resolve"
        return 0
    fi
    
    echo "📦 Found ${#missing_deps[@]} dependencies to install"
    
    # Calculate installation order
    local installation_order
    installation_order=($(calculate_installation_order "${missing_deps[@]}"))
    
    echo "🔄 Installation order:"
    for i in "${!installation_order[@]}"; do
        echo "  $((i+1)). ${installation_order[i]}"
    done
    
    # Install in order
    local success_count=0
    local failed_installs=()
    
    for dep in "${installation_order[@]}"; do
        echo ""
        echo "📦 Installing: $dep"
        if install_dependency "$dep"; then
            ((success_count++))
            log_dependency_action "INSTALLED" "$dep" "Successfully installed"
        else
            failed_installs+=("$dep")
            log_dependency_action "FAILED" "$dep" "Installation failed"
        fi
    done
    
    echo ""
    echo "📊 Installation Results:"
    echo "  ✅ Successfully installed: $success_count"
    echo "  ❌ Failed to install: ${#failed_installs[@]}"
    
    if [ ${#failed_installs[@]} -gt 0 ]; then
        echo ""
        echo "⚠️ Failed installations:"
        for failed in "${failed_installs[@]}"; do
            echo "  • $failed"
            suggest_manual_installation "$failed"
        done
    fi
    
    # Update missing dependencies file
    update_missing_dependencies_status
}

install_dependency() {
    local dep="$1"
    
    echo "🔍 Resolving installation for: $dep"
    
    # Try installation methods in order of preference
    case "$dep" in
        node|nodejs)
            try_nvm_install || try_brew_install "node" || try_direct_download_node
            ;;
        python|python3)
            try_pyenv_install || try_brew_install "python" || try_system_python
            ;;
        go|golang)
            try_gvm_install || try_brew_install "go" || try_direct_go_install
            ;;
        rust)
            try_rustup_install || try_brew_install "rust"
            ;;
        docker)
            try_docker_desktop || try_brew_install "docker"
            ;;
        bun)
            try_bun_install || try_brew_install "bun"
            ;;
        deno)
            try_deno_install || try_brew_install "deno"
            ;;
        *)
            # Generic resolution strategy
            try_brew_install "$dep" || \
            try_mas_install "$dep" || \
            try_manual_install "$dep"
            ;;
    esac
}

try_brew_install() {
    local tool="$1"
    echo "  📦 Trying Homebrew installation..."
    
    if brew search "$tool" 2>/dev/null | grep -q "^$tool$"; then
        brew install "$tool" && return 0
    elif brew search --cask "$tool" 2>/dev/null | grep -q "^$tool$"; then
        brew install --cask "$tool" && return 0
    fi
    
    return 1
}

try_mas_install() {
    local tool="$1"
    echo "  🍎 Trying Mac App Store installation..."
    
    if command -v mas >/dev/null 2>&1; then
        local app_id
        app_id=$(mas search "$tool" | head -1 | awk '{print $1}')
        if [ -n "$app_id" ] && [ "$app_id" != "No" ]; then
            mas install "$app_id" && return 0
        fi
    fi
    
    return 1
}

try_nvm_install() {
    echo "  📦 Trying Node.js via NVM..."
    
    if command -v nvm >/dev/null 2>&1; then
        nvm install node && nvm use node && return 0
    fi
    
    return 1
}

try_pyenv_install() {
    echo "  🐍 Trying Python via pyenv..."
    
    if command -v pyenv >/dev/null 2>&1; then
        local latest_python
        latest_python=$(pyenv install --list | grep -E "^  3\.[0-9]+\.[0-9]+$" | tail -1 | xargs)
        pyenv install "$latest_python" && pyenv global "$latest_python" && return 0
    fi
    
    return 1
}

try_gvm_install() {
    echo "  🔧 Trying Go via GVM..."
    
    if command -v gvm >/dev/null 2>&1; then
        gvm install go1.21 && gvm use go1.21 --default && return 0
    fi
    
    return 1
}

try_rustup_install() {
    echo "  🦀 Trying Rust via rustup..."
    
    if ! command -v rustup >/dev/null 2>&1; then
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        source "$HOME/.cargo/env"
        return 0
    fi
    
    return 1
}

try_docker_desktop() {
    echo "  🐳 Trying Docker Desktop..."
    
    try_brew_install "docker" && return 0
    return 1
}

try_bun_install() {
    echo "  🧅 Trying Bun via curl installer..."
    
    curl -fsSL https://bun.sh/install | bash && return 0
    return 1
}

try_deno_install() {
    echo "  🦕 Trying Deno via curl installer..."
    
    curl -fsSL https://deno.land/x/install/install.sh | sh && return 0
    return 1
}

try_manual_install() {
    local tool="$1"
    echo "  🔧 Checking for manual installation options..."
    
    # This would contain specific manual installation procedures
    case "$tool" in
        kubectl)
            curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/darwin/amd64/kubectl"
            chmod +x kubectl && sudo mv kubectl /usr/local/bin/
            return 0
            ;;
        terraform)
            local version="1.6.0"
            wget "https://releases.hashicorp.com/terraform/${version}/terraform_${version}_darwin_amd64.zip"
            unzip "terraform_${version}_darwin_amd64.zip" && sudo mv terraform /usr/local/bin/
            return 0
            ;;
    esac
    
    return 1
}

suggest_manual_installation() {
    local tool="$1"
    
    echo "💡 Manual installation suggestions for $tool:"
    
    case "$tool" in
        xcode)
            echo "  • Install from Mac App Store: mas install 497799835"
            echo "  • Or download from Apple Developer Portal"
            ;;
        docker)
            echo "  • Download Docker Desktop from https://www.docker.com/products/docker-desktop"
            ;;
        node)
            echo "  • Install Node Version Manager: curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash"
            echo "  • Then: nvm install node"
            ;;
        *)
            echo "  • Search Homebrew: brew search $tool"
            echo "  • Check project website for installation instructions"
            echo "  • Consider using a version manager if available"
            ;;
    esac
}

################################################################################
### Logging and Status
################################################################################

log_dependency_action() {
    local action="$1"
    local dependency="$2"
    local details="$3"
    
    echo "$(date -u +"%Y-%m-%dT%H:%M:%SZ") | $action | $dependency | $details" >> "$DEPENDENCY_LOG"
}

update_missing_dependencies_status() {
    echo "📊 Updating dependency status..."
    
    # Re-scan to update status
    scan_all_dependencies >/dev/null 2>&1
    
    echo "✅ Dependency status updated"
}

################################################################################
### Main Interface
################################################################################

show_help() {
    cat << 'EOF'
🔧 Smart Dependency Resolution System

DESCRIPTION:
    Intelligent dependency detection, resolution, and installation with fallbacks.
    Scans dotfiles, projects, and scripts to identify required tools automatically.

USAGE:
    ./dependency_resolver.sh <command> [options]

COMMANDS:
    scan                   Scan for all dependencies
    analyze               Analyze missing dependencies
    resolve               Install missing dependencies
    status                Show current dependency status
    graph                 Show dependency graph
    
    --help                Show this help message

EXAMPLES:
    ./dependency_resolver.sh scan           # Scan for dependencies
    ./dependency_resolver.sh analyze        # Find what's missing
    ./dependency_resolver.sh resolve        # Install missing tools
    ./dependency_resolver.sh status         # Show current status

FEATURES:
    🔍 Intelligent dependency scanning
    📊 Dependency graph and installation order
    🔧 Multiple installation fallbacks
    📦 Support for Homebrew, package managers, and manual installs
    🎯 Context-aware tool suggestions

FILES:
    ~/.dotfiles_dependencies.log          Dependency action log
    ~/.dotfiles_missing_deps.json         Missing dependencies analysis
    ~/.dotfiles_dependency_graph.txt      Dependency relationships

EOF
}

main() {
    case "${1:-scan}" in
        scan)
            scan_all_dependencies
            ;;
        analyze)
            analyze_missing_dependencies
            ;;
        resolve)
            resolve_dependencies
            ;;
        status)
            if [ -f "$MISSING_DEPS_FILE" ]; then
                echo "📊 Dependency Status"
                echo "==================="
                jq -r '"Last scan: " + .last_scan' "$MISSING_DEPS_FILE"
                jq -r '"Missing: " + (.missing_count | tostring)' "$MISSING_DEPS_FILE"
                jq -r '"Resolved: " + (.resolved | tostring)' "$MISSING_DEPS_FILE"
                
                local missing_count
                missing_count=$(jq -r '.missing_count' "$MISSING_DEPS_FILE")
                if [ "$missing_count" -gt 0 ]; then
                    echo ""
                    echo "Missing dependencies:"
                    jq -r '.missing[] | "  • " + .name + " (" + .category + ", priority: " + .priority + ")"' "$MISSING_DEPS_FILE"
                fi
            else
                echo "⚠️ No dependency analysis found. Run 'scan' first."
            fi
            ;;
        graph)
            if [ -f "$DEPENDENCY_GRAPH" ]; then
                echo "🔗 Dependency Graph"
                echo "=================="
                cat "$DEPENDENCY_GRAPH"
            else
                echo "⚠️ No dependency graph found. Run 'analyze' first."
            fi
            ;;
        --help|-h)
            show_help
            ;;
        *)
            echo "❌ Unknown command: $1"
            echo "💡 Use '$0 --help' for usage information"
            exit 1
            ;;
    esac
}

# Run main function if script is executed directly
if [ "${BASH_SOURCE[0]:-}" = "${0:-}" ]; then
    main "$@"
fi