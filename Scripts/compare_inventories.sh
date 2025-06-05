#!/bin/bash

set -euo pipefail

################################################################################
### System Inventory Comparison Tool
################################################################################

# Show help documentation
show_help() {
    cat << 'EOF'
📖 compare_inventories.sh - Compare system inventories between machines or time periods

DESCRIPTION:
    Compares two system inventory files to identify differences in installed
    packages, versions, and configurations. Useful for debugging setup differences.

USAGE:
    compare_inventories.sh <inventory1.json> <inventory2.json> [--format FORMAT]
    compare_inventories.sh --help

ARGUMENTS:
    inventory1.json      First inventory file (baseline)
    inventory2.json      Second inventory file (comparison target)

OPTIONS:
    --format FORMAT      Output format: detailed, summary, or diff (default: summary)
    --help, -h           Show this help message

OUTPUT FORMATS:
    summary     High-level differences summary
    detailed    Complete side-by-side comparison
    diff        Unix diff-style output

EXAMPLES:
    compare_inventories.sh machine1.json machine2.json
    compare_inventories.sh old_state.json current_state.json --format detailed
    compare_inventories.sh baseline.json test.json --format diff

COMPARISON INCLUDES:
    • System information differences
    • Missing/extra Homebrew packages
    • Version mismatches
    • Configuration drift
    • Setup completion status

USE CASES:
    • Debug why setup works on one machine but not another
    • Track changes over time
    • Ensure team environment consistency
    • Validate successful migrations

EOF
}

# Check if jq is available
require_jq() {
    if ! command -v jq >/dev/null 2>&1; then
        echo "Error: jq is required for inventory comparison"
        echo "Install with: brew install jq"
        exit 1
    fi
}

# Extract package names from JSON array
extract_package_names() {
    local json_data="$1"
    local package_type="$2"
    
    echo "$json_data" | jq -r ".homebrew.${package_type}[].name" 2>/dev/null | sort || true
}

# Extract MAS app names
extract_mas_names() {
    local json_data="$1"
    echo "$json_data" | jq -r '.mas_apps[].name' 2>/dev/null | sort || true
}

# Compare package lists
compare_packages() {
    local inventory1="$1"
    local inventory2="$2"
    local package_type="$3"
    local label="$4"
    
    local packages1=$(extract_package_names "$inventory1" "$package_type")
    local packages2=$(extract_package_names "$inventory2" "$package_type")
    
    local only_in_1=$(comm -23 <(echo "$packages1") <(echo "$packages2") || true)
    local only_in_2=$(comm -13 <(echo "$packages1") <(echo "$packages2") || true)
    local common=$(comm -12 <(echo "$packages1") <(echo "$packages2") || true)
    
    local count1=$(echo "$packages1" | wc -l | tr -d ' ')
    local count2=$(echo "$packages2" | wc -l | tr -d ' ')
    local count_common=$(echo "$common" | wc -l | tr -d ' ')
    
    echo "📦 $label PACKAGES"
    echo "Inventory 1: $count1 packages"
    echo "Inventory 2: $count2 packages"
    echo "Common: $count_common packages"
    
    if [ -n "$only_in_1" ]; then
        echo ""
        echo "❌ Only in Inventory 1:"
        echo "$only_in_1" | head -10
        if [ $(echo "$only_in_1" | wc -l) -gt 10 ]; then
            echo "... and $(( $(echo "$only_in_1" | wc -l) - 10 )) more"
        fi
    fi
    
    if [ -n "$only_in_2" ]; then
        echo ""
        echo "➕ Only in Inventory 2:"
        echo "$only_in_2" | head -10
        if [ $(echo "$only_in_2" | wc -l) -gt 10 ]; then
            echo "... and $(( $(echo "$only_in_2" | wc -l) - 10 )) more"
        fi
    fi
    
    echo ""
}

# Compare system information
compare_system_info() {
    local inventory1="$1"
    local inventory2="$2"
    
    echo "🖥️  SYSTEM INFORMATION"
    
    local hostname1=$(echo "$inventory1" | jq -r '.system_info.hostname')
    local hostname2=$(echo "$inventory2" | jq -r '.system_info.hostname')
    local os1=$(echo "$inventory1" | jq -r '.system_info.os_version')
    local os2=$(echo "$inventory2" | jq -r '.system_info.os_version')
    
    echo "Hostname: $hostname1 vs $hostname2"
    echo "OS Version: $os1 vs $os2"
    
    if [ "$os1" != "$os2" ]; then
        echo "⚠️  OS versions differ - this may explain package differences"
    fi
    
    echo ""
}

# Compare tool versions
compare_tool_versions() {
    local inventory1="$1"
    local inventory2="$2"
    
    echo "🔧 DEVELOPMENT TOOL VERSIONS"
    
    local tools1=$(echo "$inventory1" | jq -r '.tool_versions | keys[]' 2>/dev/null | sort || true)
    local tools2=$(echo "$inventory2" | jq -r '.tool_versions | keys[]' 2>/dev/null | sort || true)
    local all_tools=$(echo -e "$tools1\n$tools2" | sort -u)
    
    local differences=0
    
    while IFS= read -r tool; do
        local version1=$(echo "$inventory1" | jq -r ".tool_versions[\"$tool\"] // \"not installed\"" 2>/dev/null)
        local version2=$(echo "$inventory2" | jq -r ".tool_versions[\"$tool\"] // \"not installed\"" 2>/dev/null)
        
        if [ "$version1" != "$version2" ]; then
            echo "$tool: $version1 vs $version2"
            differences=$((differences + 1))
        fi
    done <<< "$all_tools"
    
    if [ $differences -eq 0 ]; then
        echo "✅ All tool versions match"
    else
        echo "⚠️  Found $differences version differences"
    fi
    
    echo ""
}

# Generate summary comparison
summary_comparison() {
    local inventory1="$1"
    local inventory2="$2"
    
    echo "📊 INVENTORY COMPARISON SUMMARY"
    echo "================================"
    echo ""
    
    compare_system_info "$inventory1" "$inventory2"
    compare_packages "$inventory1" "$inventory2" "formulas" "HOMEBREW"
    compare_packages "$inventory1" "$inventory2" "casks" "CASK"
    
    # Compare MAS apps
    local mas1=$(extract_mas_names "$inventory1")
    local mas2=$(extract_mas_names "$inventory2")
    local mas_diff=$(comm -3 <(echo "$mas1") <(echo "$mas2") | wc -l | tr -d ' ')
    
    echo "📱 MAC APP STORE APPS"
    echo "Inventory 1: $(echo "$mas1" | wc -l | tr -d ' ') apps"
    echo "Inventory 2: $(echo "$mas2" | wc -l | tr -d ' ') apps"
    if [ $mas_diff -gt 0 ]; then
        echo "⚠️  $mas_diff differences found"
    else
        echo "✅ App lists match"
    fi
    echo ""
    
    compare_tool_versions "$inventory1" "$inventory2"
}

# Generate detailed comparison
detailed_comparison() {
    local inventory1="$1"
    local inventory2="$2"
    
    summary_comparison "$inventory1" "$inventory2"
    
    echo "📋 DETAILED PACKAGE ANALYSIS"
    echo "============================="
    echo ""
    
    # Detailed package differences
    for package_type in "formulas" "casks"; do
        local packages1=$(extract_package_names "$inventory1" "$package_type")
        local packages2=$(extract_package_names "$inventory2" "$package_type")
        
        echo "🔍 $package_type differences:"
        diff -u <(echo "$packages1") <(echo "$packages2") || true
        echo ""
    done
}

# Generate diff-style comparison
diff_comparison() {
    local inventory1="$1"
    local inventory2="$2"
    
    echo "📄 DIFF-STYLE COMPARISON"
    echo "========================"
    echo ""
    
    # Create temporary sorted files for comparison
    local temp1=$(mktemp)
    local temp2=$(mktemp)
    
    # Sort and format for better diffing
    echo "$inventory1" | jq --sort-keys . > "$temp1"
    echo "$inventory2" | jq --sort-keys . > "$temp2"
    
    diff -u "$temp1" "$temp2" || true
    
    rm -f "$temp1" "$temp2"
}

# Main function
main() {
    local format="summary"
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --help|-h)
                show_help
                exit 0
                ;;
            --format)
                format="$2"
                shift 2
                ;;
            -*)
                echo "Unknown option: $1"
                echo "Use --help for usage information"
                exit 1
                ;;
            *)
                break
                ;;
        esac
    done
    
    # Check required arguments
    if [ $# -lt 2 ]; then
        echo "Error: Two inventory files required"
        echo "Usage: $0 <inventory1.json> <inventory2.json>"
        echo "Use --help for more information"
        exit 1
    fi
    
    local file1="$1"
    local file2="$2"
    
    # Validate files exist
    if [ ! -f "$file1" ]; then
        echo "Error: File not found: $file1"
        exit 1
    fi
    
    if [ ! -f "$file2" ]; then
        echo "Error: File not found: $file2"
        exit 1
    fi
    
    # Validate format
    if [[ ! "$format" =~ ^(summary|detailed|diff)$ ]]; then
        echo "Error: Invalid format '$format'. Must be summary, detailed, or diff"
        exit 1
    fi
    
    require_jq
    
    echo "🔍 Comparing inventories..."
    echo "File 1: $file1"
    echo "File 2: $file2"
    echo ""
    
    # Load inventories
    local inventory1=$(cat "$file1")
    local inventory2=$(cat "$file2")
    
    # Validate JSON
    if ! echo "$inventory1" | jq . >/dev/null 2>&1; then
        echo "Error: Invalid JSON in $file1"
        exit 1
    fi
    
    if ! echo "$inventory2" | jq . >/dev/null 2>&1; then
        echo "Error: Invalid JSON in $file2"
        exit 1
    fi
    
    # Generate comparison based on format
    case "$format" in
        summary)
            summary_comparison "$inventory1" "$inventory2"
            ;;
        detailed)
            detailed_comparison "$inventory1" "$inventory2"
            ;;
        diff)
            diff_comparison "$inventory1" "$inventory2"
            ;;
    esac
    
    echo ""
    echo "💡 Tip: Use 'track_system_state.sh' to generate new inventories"
}

# Execute main function with all arguments
main "$@"