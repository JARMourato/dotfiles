#!/bin/bash

set -euo pipefail

################################################################################
### Comprehensive Caching System
################################################################################

# This library provides intelligent caching for downloads, packages, and
# computed configurations to significantly speed up setup operations

# Cache configuration
CACHE_ROOT="$HOME/.dotfiles_cache"
CACHE_VERSION="1.0"
CACHE_MAX_AGE_DAYS=30
CACHE_MAX_SIZE_MB=2000

# Cache directories
DOWNLOADS_CACHE="$CACHE_ROOT/downloads"
PACKAGES_CACHE="$CACHE_ROOT/packages"
CONFIG_CACHE="$CACHE_ROOT/config"
BREW_CACHE="$CACHE_ROOT/homebrew"
METADATA_CACHE="$CACHE_ROOT/metadata"

################################################################################
### Core Caching Functions
################################################################################

# Initialize cache system
init_cache() {
    echo "💾 Initializing cache system..."
    
    # Create cache directories
    mkdir -p "$DOWNLOADS_CACHE"
    mkdir -p "$PACKAGES_CACHE"
    mkdir -p "$CONFIG_CACHE"
    mkdir -p "$BREW_CACHE"
    mkdir -p "$METADATA_CACHE"
    
    # Set up Homebrew cache
    export HOMEBREW_CACHE="$BREW_CACHE"
    export HOMEBREW_NO_AUTO_UPDATE=1
    
    # Create cache metadata
    cat > "$CACHE_ROOT/cache_info.json" << EOF
{
    "version": "$CACHE_VERSION",
    "created": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
    "last_cleanup": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
    "max_age_days": $CACHE_MAX_AGE_DAYS,
    "max_size_mb": $CACHE_MAX_SIZE_MB
}
EOF
    
    echo "📁 Cache root: $CACHE_ROOT"
    echo "📊 Cache size: $(get_cache_size)"
}

# Get current cache size in human-readable format
get_cache_size() {
    if [ -d "$CACHE_ROOT" ]; then
        du -sh "$CACHE_ROOT" 2>/dev/null | cut -f1 || echo "0B"
    else
        echo "0B"
    fi
}

# Get cache size in MB
get_cache_size_mb() {
    if [ -d "$CACHE_ROOT" ]; then
        du -sm "$CACHE_ROOT" 2>/dev/null | cut -f1 || echo "0"
    else
        echo "0"
    fi
}

# Check if cache entry is valid (exists and not too old)
is_cache_valid() {
    local cache_file="$1"
    local max_age_seconds="${2:-$((CACHE_MAX_AGE_DAYS * 86400))}"
    
    if [ ! -f "$cache_file" ]; then
        return 1  # File doesn't exist
    fi
    
    # Check age
    local file_age=$(($(date +%s) - $(stat -f %m "$cache_file" 2>/dev/null || echo 0)))
    if [ $file_age -gt $max_age_seconds ]; then
        return 1  # File is too old
    fi
    
    return 0  # Cache is valid
}

# Generate cache key from content
generate_cache_key() {
    local content="$1"
    echo "$content" | shasum -a 256 | cut -d' ' -f1
}

################################################################################
### Download Caching
################################################################################

# Download file with caching
download_with_cache() {
    local url="$1"
    local cache_name="${2:-$(basename "$url")}"
    local max_age_days="${3:-7}"
    local max_age_seconds=$((max_age_days * 86400))
    
    local cache_file="$DOWNLOADS_CACHE/$cache_name"
    local cache_metadata="$cache_file.metadata"
    
    # Check if cached version is valid
    if is_cache_valid "$cache_file" "$max_age_seconds"; then
        echo "📋 Using cached download: $cache_name"
        echo "$cache_file"
        return 0
    fi
    
    echo "📥 Downloading: $url"
    
    # Create metadata
    cat > "$cache_metadata" << EOF
{
    "url": "$url",
    "downloaded": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
    "size": 0,
    "checksum": ""
}
EOF
    
    # Download with progress
    if curl -fsSL "$url" > "$cache_file.tmp"; then
        mv "$cache_file.tmp" "$cache_file"
        
        # Update metadata
        local file_size=$(stat -f %z "$cache_file" 2>/dev/null || echo 0)
        local checksum=$(shasum -a 256 "$cache_file" | cut -d' ' -f1)
        
        cat > "$cache_metadata" << EOF
{
    "url": "$url",
    "downloaded": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
    "size": $file_size,
    "checksum": "$checksum"
}
EOF
        
        echo "✅ Downloaded and cached: $cache_name ($(format_bytes $file_size))"
        echo "$cache_file"
        return 0
    else
        rm -f "$cache_file.tmp" "$cache_metadata"
        echo "❌ Download failed: $url"
        return 1
    fi
}

# Verify cached download integrity
verify_cached_download() {
    local cache_file="$1"
    local cache_metadata="$cache_file.metadata"
    
    if [ ! -f "$cache_metadata" ]; then
        return 1  # No metadata
    fi
    
    # Get expected checksum
    local expected_checksum=$(jq -r '.checksum' "$cache_metadata" 2>/dev/null || echo "")
    if [ -z "$expected_checksum" ]; then
        return 1  # No checksum in metadata
    fi
    
    # Calculate actual checksum
    local actual_checksum=$(shasum -a 256 "$cache_file" | cut -d' ' -f1)
    
    if [ "$expected_checksum" = "$actual_checksum" ]; then
        return 0  # Integrity verified
    else
        echo "⚠️  Cache integrity check failed for $(basename "$cache_file")"
        return 1  # Integrity check failed
    fi
}

################################################################################
### Package Installation Caching
################################################################################

# Check if package is already installed and cached
is_package_cached() {
    local package_type="$1"  # formula, cask, mas
    local package_name="$2"
    local cache_file="$PACKAGES_CACHE/${package_type}_${package_name}.installed"
    
    # Check if cache entry exists and package is actually installed
    if [ -f "$cache_file" ]; then
        case "$package_type" in
            "formula")
                brew list --formula "$package_name" >/dev/null 2>&1
                ;;
            "cask")
                brew list --cask "$package_name" >/dev/null 2>&1
                ;;
            "mas")
                mas list | grep -q "^$package_name "
                ;;
            *)
                return 1
                ;;
        esac
    else
        return 1
    fi
}

# Mark package as installed in cache
mark_package_cached() {
    local package_type="$1"
    local package_name="$2"
    local cache_file="$PACKAGES_CACHE/${package_type}_${package_name}.installed"
    
    # Create cache entry with metadata
    cat > "$cache_file" << EOF
{
    "package": "$package_name",
    "type": "$package_type",
    "installed": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
    "version": "$(get_package_version "$package_type" "$package_name")"
}
EOF
}

# Get package version
get_package_version() {
    local package_type="$1"
    local package_name="$2"
    
    case "$package_type" in
        "formula")
            brew list --versions "$package_name" 2>/dev/null | head -1 | cut -d' ' -f2- || echo "unknown"
            ;;
        "cask")
            brew list --cask --versions "$package_name" 2>/dev/null | head -1 | cut -d' ' -f2- || echo "unknown"
            ;;
        "mas")
            mas list | grep "^$package_name " | cut -d' ' -f2 || echo "unknown"
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

# Install package with caching
install_package_with_cache() {
    local package_type="$1"
    local package_name="$2"
    
    # Check if already cached and installed
    if is_package_cached "$package_type" "$package_name"; then
        echo "✅ $package_name (cached)"
        return 0
    fi
    
    echo "📦 Installing $package_name..."
    
    # Install package
    local install_success=false
    case "$package_type" in
        "formula")
            if brew install "$package_name"; then
                install_success=true
            fi
            ;;
        "cask")
            if brew install --cask "$package_name"; then
                install_success=true
            fi
            ;;
        "mas")
            if mas install "$package_name"; then
                install_success=true
            fi
            ;;
    esac
    
    if [ "$install_success" = true ]; then
        mark_package_cached "$package_type" "$package_name"
        echo "✅ $package_name (installed and cached)"
        return 0
    else
        echo "❌ Failed to install $package_name"
        return 1
    fi
}

################################################################################
### Configuration Caching
################################################################################

# Cache computed configuration
cache_config() {
    local config_file="${1:-$PWD/.dotfiles.config}"
    local config_hash=$(shasum -a 256 "$config_file" | cut -d' ' -f1)
    local cache_file="$CONFIG_CACHE/config_$config_hash.computed"
    
    if [ -f "$cache_file" ]; then
        echo "📋 Loading cached configuration..."
        source "$cache_file"
        return 0
    fi
    
    echo "🔄 Computing configuration state..."
    
    # Load and process configuration
    if [ -f Scripts/config_parser.sh ]; then
        source Scripts/config_parser.sh
        load_dotfiles_config "$config_file"
        export_config_vars
    fi
    
    # Cache the computed environment variables
    {
        echo "# Cached configuration computed at $(date)"
        echo "# Config file hash: $config_hash"
        env | grep -E '^(HOMEBREW_|SKIP_|MAS_|ENCRYPTION_|DOTFILES_)' || true
    } > "$cache_file"
    
    echo "💾 Configuration state cached"
    return 0
}

# Invalidate configuration cache
invalidate_config_cache() {
    echo "🗑️  Invalidating configuration cache..."
    rm -f "$CONFIG_CACHE"/config_*.computed
    echo "✅ Configuration cache cleared"
}

################################################################################
### Homebrew Caching Enhancements
################################################################################

# Set up enhanced Homebrew caching
setup_homebrew_cache() {
    echo "🍺 Setting up Homebrew cache..."
    
    # Configure Homebrew cache location
    export HOMEBREW_CACHE="$BREW_CACHE"
    export HOMEBREW_NO_AUTO_UPDATE=1
    export HOMEBREW_NO_ANALYTICS=1
    
    # Create Homebrew cache directories
    mkdir -p "$BREW_CACHE/downloads"
    mkdir -p "$BREW_CACHE/api"
    mkdir -p "$BREW_CACHE/cask"
    
    echo "📁 Homebrew cache: $BREW_CACHE"
    echo "📊 Homebrew cache size: $(du -sh "$BREW_CACHE" 2>/dev/null | cut -f1 || echo '0B')"
}

# Optimize Homebrew cache
optimize_homebrew_cache() {
    echo "🧹 Optimizing Homebrew cache..."
    
    # Clean old downloads
    find "$BREW_CACHE/downloads" -type f -mtime +7 -delete 2>/dev/null || true
    
    # Clean old API cache
    find "$BREW_CACHE/api" -type f -mtime +1 -delete 2>/dev/null || true
    
    # Run Homebrew cleanup
    brew cleanup --prune=7 >/dev/null 2>&1 || true
    
    echo "✅ Homebrew cache optimized"
}

################################################################################
### Cache Management
################################################################################

# Clean old cache entries
cleanup_cache() {
    echo "🧹 Cleaning up cache..."
    
    local cleaned_files=0
    local freed_space=0
    
    # Remove files older than max age
    if [ -d "$CACHE_ROOT" ]; then
        while IFS= read -r -d '' file; do
            local file_size=$(stat -f %z "$file" 2>/dev/null || echo 0)
            rm -f "$file"
            cleaned_files=$((cleaned_files + 1))
            freed_space=$((freed_space + file_size))
        done < <(find "$CACHE_ROOT" -type f -mtime +$CACHE_MAX_AGE_DAYS -print0 2>/dev/null)
    fi
    
    echo "🗑️  Removed $cleaned_files old files ($(format_bytes $freed_space) freed)"
    
    # Check total cache size and clean if necessary
    local current_size_mb=$(get_cache_size_mb)
    if [ "$current_size_mb" -gt "$CACHE_MAX_SIZE_MB" ]; then
        echo "⚠️  Cache size ($current_size_mb MB) exceeds limit ($CACHE_MAX_SIZE_MB MB)"
        
        # Remove oldest files until under limit
        find "$CACHE_ROOT" -type f -exec ls -t {} + 2>/dev/null | \
        while read -r file; do
            if [ "$(get_cache_size_mb)" -le "$CACHE_MAX_SIZE_MB" ]; then
                break
            fi
            rm -f "$file"
            cleaned_files=$((cleaned_files + 1))
        done
        
        echo "🗑️  Cleaned additional files to stay under size limit"
    fi
    
    # Update cleanup timestamp
    if [ -f "$CACHE_ROOT/cache_info.json" ]; then
        local temp_file=$(mktemp)
        jq ".last_cleanup = \"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\"" "$CACHE_ROOT/cache_info.json" > "$temp_file"
        mv "$temp_file" "$CACHE_ROOT/cache_info.json"
    fi
    
    echo "✅ Cache cleanup completed"
    echo "📊 Current cache size: $(get_cache_size)"
}

# Show cache statistics
show_cache_stats() {
    echo "📊 Cache Statistics"
    echo "==================="
    echo ""
    
    if [ ! -d "$CACHE_ROOT" ]; then
        echo "❌ Cache not initialized"
        return 1
    fi
    
    echo "📁 Cache location: $CACHE_ROOT"
    echo "📊 Total size: $(get_cache_size)"
    echo "📈 Size limit: ${CACHE_MAX_SIZE_MB}MB"
    echo "🕐 Max age: ${CACHE_MAX_AGE_DAYS} days"
    echo ""
    
    # Breakdown by category
    for dir in downloads packages config homebrew metadata; do
        local dir_path="$CACHE_ROOT/$dir"
        if [ -d "$dir_path" ]; then
            local dir_size=$(du -sh "$dir_path" 2>/dev/null | cut -f1)
            local file_count=$(find "$dir_path" -type f | wc -l | tr -d ' ')
            printf "  %-12s %8s (%s files)\n" "$dir:" "$dir_size" "$file_count"
        fi
    done
    echo ""
    
    # Cache hit rates (if available)
    if [ -f "$CACHE_ROOT/cache_info.json" ]; then
        echo "🕐 Created: $(jq -r '.created' "$CACHE_ROOT/cache_info.json")"
        echo "🧹 Last cleanup: $(jq -r '.last_cleanup' "$CACHE_ROOT/cache_info.json")"
    fi
}

# Reset entire cache
reset_cache() {
    echo "⚠️  Resetting entire cache..."
    
    if [ -d "$CACHE_ROOT" ]; then
        local old_size=$(get_cache_size)
        rm -rf "$CACHE_ROOT"
        echo "🗑️  Removed cache directory ($old_size freed)"
    fi
    
    # Reinitialize
    init_cache
    echo "✅ Cache reset and reinitialized"
}

################################################################################
### Utility Functions
################################################################################

# Format bytes in human-readable format
format_bytes() {
    local bytes=$1
    local units=("B" "KB" "MB" "GB" "TB")
    local unit=0
    
    while [ $bytes -ge 1024 ] && [ $unit -lt ${#units[@]} ]; do
        bytes=$((bytes / 1024))
        unit=$((unit + 1))
    done
    
    echo "${bytes}${units[$unit]}"
}

# Check cache health
check_cache_health() {
    echo "🩺 Checking cache health..."
    
    local issues=0
    
    # Check if cache directories exist
    for dir in downloads packages config homebrew metadata; do
        if [ ! -d "$CACHE_ROOT/$dir" ]; then
            echo "⚠️  Missing directory: $dir"
            issues=$((issues + 1))
        fi
    done
    
    # Check cache size
    local current_size_mb=$(get_cache_size_mb)
    if [ "$current_size_mb" -gt "$CACHE_MAX_SIZE_MB" ]; then
        echo "⚠️  Cache size ($current_size_mb MB) exceeds limit ($CACHE_MAX_SIZE_MB MB)"
        issues=$((issues + 1))
    fi
    
    # Check for very old files
    local old_files=$(find "$CACHE_ROOT" -type f -mtime +$((CACHE_MAX_AGE_DAYS * 2)) 2>/dev/null | wc -l | tr -d ' ')
    if [ "$old_files" -gt 0 ]; then
        echo "⚠️  Found $old_files very old files (>$((CACHE_MAX_AGE_DAYS * 2)) days)"
        issues=$((issues + 1))
    fi
    
    if [ $issues -eq 0 ]; then
        echo "✅ Cache is healthy"
        return 0
    else
        echo "❌ Found $issues cache issues"
        return 1
    fi
}

################################################################################
### Help Documentation
################################################################################

show_cache_help() {
    cat << 'EOF'
📖 caching_system.sh - Comprehensive caching system for dotfiles

DESCRIPTION:
    Provides intelligent caching for downloads, packages, and configurations
    to dramatically speed up repeated setup operations.

CORE FUNCTIONS:
    init_cache                     Initialize cache system
    cleanup_cache                  Clean old cache entries
    show_cache_stats              Display cache statistics
    reset_cache                   Reset entire cache
    check_cache_health            Verify cache integrity

DOWNLOAD CACHING:
    download_with_cache           Download with intelligent caching
    verify_cached_download        Verify download integrity

PACKAGE CACHING:
    install_package_with_cache    Install packages with cache tracking
    is_package_cached             Check if package is cached
    mark_package_cached           Mark package as installed

CONFIGURATION CACHING:
    cache_config                  Cache computed configuration
    invalidate_config_cache       Clear configuration cache

HOMEBREW CACHING:
    setup_homebrew_cache          Configure Homebrew caching
    optimize_homebrew_cache       Clean Homebrew cache

CACHE LOCATIONS:
    ~/.dotfiles_cache/downloads   Downloaded files
    ~/.dotfiles_cache/packages    Package installation status
    ~/.dotfiles_cache/config      Computed configurations
    ~/.dotfiles_cache/homebrew    Homebrew package cache
    ~/.dotfiles_cache/metadata    Cache metadata

EXAMPLES:
    # Initialize cache
    init_cache
    
    # Download with caching
    installer=$(download_with_cache "https://example.com/installer.sh" "installer.sh")
    
    # Install packages with caching
    install_package_with_cache "formula" "git"
    install_package_with_cache "cask" "google-chrome"
    
    # Cache configuration
    cache_config ".dotfiles.config"
    
    # Show statistics
    show_cache_stats

EOF
}

# Show help if script is run directly
if [ "${BASH_SOURCE[0]:-}" = "${0:-}" ]; then
    case "${1:-}" in
        --help|-h)
            show_cache_help
            ;;
        --stats)
            show_cache_stats
            ;;
        --cleanup)
            cleanup_cache
            ;;
        --reset)
            reset_cache
            ;;
        --health)
            check_cache_health
            ;;
        *)
            echo "This is a library file. Source it to use caching functions."
            echo "Use --help for more information, or:"
            echo "  --stats    Show cache statistics"
            echo "  --cleanup  Clean old cache entries"
            echo "  --reset    Reset entire cache"
            echo "  --health   Check cache health"
            ;;
    esac
fi