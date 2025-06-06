#!/bin/bash

################################################################################
### YAML Configuration Validation Script
################################################################################
# This script validates YAML configuration files and tests the parsing
# Run this before committing changes to ensure configurations work correctly

set -euo pipefail

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Available profiles
PROFILES=("dev" "personal" "server")

################################################################################
### Utility Functions
################################################################################

print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

################################################################################
### Validation Functions
################################################################################

check_python_and_yaml() {
    print_header "Checking Prerequisites"
    
    # Check if Python 3 is available
    if ! command -v python3 >/dev/null 2>&1; then
        print_error "Python 3 is required but not found"
        print_info "Install Python 3: brew install python"
        return 1
    fi
    print_success "Python 3 found: $(python3 --version)"
    
    # Check if PyYAML is available
    if ! python3 -c "import yaml" 2>/dev/null; then
        print_warning "PyYAML not found, attempting to install..."
        if pip3 install PyYAML; then
            print_success "PyYAML installed successfully"
        else
            print_error "Failed to install PyYAML"
            print_info "Try: pip3 install PyYAML"
            return 1
        fi
    else
        print_success "PyYAML is available"
    fi
    
    return 0
}

validate_yaml_syntax() {
    local config_file="$1"
    local config_name="$2"
    
    print_info "Validating YAML syntax: $config_name"
    
    if [ ! -f "$config_file" ]; then
        print_warning "Configuration file not found: $config_file"
        return 1
    fi
    
    # Test YAML syntax
    if python3 -c "
import yaml
try:
    with open('$config_file', 'r') as f:
        yaml.safe_load(f)
    print('✅ Valid YAML syntax')
except yaml.YAMLError as e:
    print(f'❌ YAML syntax error: {e}')
    exit(1)
"; then
        print_success "$config_name has valid YAML syntax"
        return 0
    else
        print_error "$config_name has invalid YAML syntax"
        return 1
    fi
}

test_config_parsing() {
    local profile="$1"
    
    print_info "Testing configuration parsing for profile: $profile"
    
    # Test the Python parser
    if output=$(python3 "$SCRIPT_DIR/yaml_parser.py" "$profile" 2>&1); then
        print_success "Successfully parsed $profile configuration"
        
        # Show some key variables that were parsed
        echo "Sample parsed variables:"
        echo "$output" | head -10 | sed 's/^/  /'
        
        if [ $(echo "$output" | wc -l) -gt 10 ]; then
            echo "  ... and $(echo "$output" | wc -l | tr -d ' ') total variables"
        fi
        
        return 0
    else
        print_error "Failed to parse $profile configuration"
        echo "$output" | sed 's/^/  /'
        return 1
    fi
}

validate_required_fields() {
    local profile="$1"
    
    print_info "Validating required fields for profile: $profile"
    
    # Parse the configuration and check for required fields
    if output=$(python3 "$SCRIPT_DIR/yaml_parser.py" "$profile" 2>/dev/null); then
        local missing_fields=()
        
        # Check for essential fields
        if ! echo "$output" | grep -q "GIT_NAME="; then
            missing_fields+=("git.name")
        fi
        
        if ! echo "$output" | grep -q "GIT_EMAIL="; then
            missing_fields+=("git.email")
        fi
        
        if ! echo "$output" | grep -q "HOMEBREW_FORMULAS="; then
            missing_fields+=("packages.homebrew.formulas")
        fi
        
        if [ ${#missing_fields[@]} -eq 0 ]; then
            print_success "All required fields present for $profile"
            return 0
        else
            print_error "Missing required fields for $profile:"
            for field in "${missing_fields[@]}"; do
                echo "  - $field"
            done
            return 1
        fi
    else
        print_error "Could not validate required fields (parsing failed)"
        return 1
    fi
}

show_config_summary() {
    local profile="$1"
    
    print_header "Configuration Summary: $profile"
    
    if output=$(python3 "$SCRIPT_DIR/yaml_parser.py" "$profile" 2>/dev/null); then
        # Extract and display key information
        local formulas=$(echo "$output" | grep "HOMEBREW_FORMULAS=" | cut -d'"' -f2)
        local casks=$(echo "$output" | grep "HOMEBREW_CASKS=" | cut -d'"' -f2)
        local git_name=$(echo "$output" | grep "GIT_NAME=" | cut -d'"' -f2)
        local git_email=$(echo "$output" | grep "GIT_EMAIL=" | cut -d'"' -f2)
        local skip_xcode=$(echo "$output" | grep "SKIP_XCODE=" | cut -d'"' -f2)
        
        echo "Git Configuration:"
        echo "  Name: $git_name"
        echo "  Email: $git_email"
        echo ""
        
        echo "Homebrew Formulas ($(echo $formulas | wc -w | tr -d ' ')):"
        if [ -n "$formulas" ]; then
            echo "$formulas" | tr ' ' '\n' | sed 's/^/  - /'
        else
            echo "  (none)"
        fi
        echo ""
        
        echo "Homebrew Casks ($(echo $casks | wc -w | tr -d ' ')):"
        if [ -n "$casks" ]; then
            echo "$casks" | tr ' ' '\n' | sed 's/^/  - /'
        else
            echo "  (none)"
        fi
        echo ""
        
        echo "Xcode Installation: $([ "$skip_xcode" = "true" ] && echo "Disabled" || echo "Enabled")"
        
        return 0
    else
        print_error "Could not generate configuration summary"
        return 1
    fi
}

################################################################################
### Main Validation Logic
################################################################################

main() {
    cd "$DOTFILES_DIR"
    
    print_header "YAML Configuration Validation"
    echo "Validating dotfiles YAML configurations..."
    echo ""
    
    local overall_success=true
    
    # Check prerequisites
    if ! check_python_and_yaml; then
        exit 1
    fi
    echo ""
    
    # Validate base configuration
    print_header "Base Configuration"
    if ! validate_yaml_syntax ".dotfiles.yaml" "Base configuration"; then
        overall_success=false
    fi
    echo ""
    
    # Validate each profile
    for profile in "${PROFILES[@]}"; do
        print_header "Profile: $profile"
        
        local profile_success=true
        
        # Check if profile file exists
        local profile_file=".dotfiles.${profile}.yaml"
        if [ ! -f "$profile_file" ]; then
            print_warning "Profile file not found: $profile_file"
            continue
        fi
        
        # Validate YAML syntax
        if ! validate_yaml_syntax "$profile_file" "$profile configuration"; then
            profile_success=false
            overall_success=false
        fi
        
        # Test parsing
        if ! test_config_parsing "$profile"; then
            profile_success=false
            overall_success=false
        fi
        
        # Validate required fields
        if ! validate_required_fields "$profile"; then
            profile_success=false
            overall_success=false
        fi
        
        # Show summary if validation passed
        if [ "$profile_success" = true ]; then
            echo ""
            show_config_summary "$profile"
        fi
        
        echo ""
    done
    
    # Final result
    print_header "Validation Results"
    if [ "$overall_success" = true ]; then
        print_success "All configurations are valid! ✨"
        print_info "You can safely commit these changes"
        exit 0
    else
        print_error "Some configurations have issues"
        print_info "Please fix the errors above before committing"
        exit 1
    fi
}

################################################################################
### Help and Usage
################################################################################

show_help() {
    echo "YAML Configuration Validator"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -h, --help     Show this help message"
    echo "  -p, --profile  Validate specific profile only"
    echo ""
    echo "Examples:"
    echo "  $0              # Validate all configurations"
    echo "  $0 -p dev       # Validate only dev profile"
    echo ""
    echo "This script validates:"
    echo "  - YAML syntax correctness"
    echo "  - Configuration parsing"
    echo "  - Required fields presence"
    echo "  - Shows configuration summaries"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -p|--profile)
            if [ -n "${2:-}" ]; then
                PROFILES=("$2")
                shift 2
            else
                print_error "Profile name required after -p/--profile"
                exit 1
            fi
            ;;
        *)
            print_error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Run main function
main