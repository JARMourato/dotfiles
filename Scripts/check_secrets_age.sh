#!/bin/bash

set -euo pipefail

################################################################################
### Check Secrets Age and Rotation Status
################################################################################

# Colors for output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Get file modification time in days
get_file_age_days() {
    local file="$1"
    if [ -f "$file" ]; then
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS
            echo $(( ($(date +%s) - $(stat -f %m "$file")) / 86400 ))
        else
            # Linux
            echo $(( ($(date +%s) - $(stat -c %Y "$file")) / 86400 ))
        fi
    else
        echo "-1"
    fi
}

# Check if rotation is recommended
check_rotation_needed() {
    local age_days="$1"
    local warn_days=90
    local urgent_days=180
    
    if [ "$age_days" -lt 0 ]; then
        echo "MISSING"
    elif [ "$age_days" -gt "$urgent_days" ]; then
        echo "URGENT"
    elif [ "$age_days" -gt "$warn_days" ]; then
        echo "WARNING"
    else
        echo "OK"
    fi
}

# Show help documentation
show_help() {
    cat << 'EOF'
📖 check_secrets_age.sh - Monitor encrypted secrets rotation status

DESCRIPTION:
    Checks the age of encrypted secret files and provides rotation recommendations.
    Helps maintain security by identifying secrets that need rotation.

USAGE:
    check_secrets_age.sh
    check_secrets_age.sh --help

OPTIONS:
    --help, -h           Show this help message

ROTATION GUIDELINES:
    • Recommended rotation: every 90 days (WARNING status)
    • Urgent rotation needed: after 180 days (URGENT status)
    • Missing files are flagged as urgent

FILES MONITORED:
    ~/.secrets.*.encrypted       API keys, tokens, credentials
    ~/.zsh_history.*.encrypted   Shell command history
    ~/.z.*.encrypted             Directory jump history  
    ~/.tellus.*.encrypted        Application-specific secrets

OUTPUT:
    ✅ OK        - Secret is current (< 90 days)
    ⚠️  WARNING  - Should rotate soon (90-180 days)
    🚨 URGENT    - Needs immediate rotation (> 180 days)
    ❌ MISSING   - Encrypted file not found

EXIT CODES:
    0    All secrets are current
    1    Some secrets need rotation (WARNING)
    2    Urgent rotation required

EXAMPLES:
    check_secrets_age.sh
    check_secrets_age.sh | grep URGENT

SEE ALSO:
    rotate_secrets.sh - Rotate secrets with new encryption key

EOF
}

# Main function
main() {
    # Check for help flag
    if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
        show_help
        exit 0
    fi
    
    echo "🔐 Checking encrypted secrets status..."
    echo ""
    
    local repo_path="${DOTFILES_DIR:-$(pwd)}"
    
    # Define secrets to check
    declare -a SECRETS=(
        ".tellus"
        ".secrets"
        ".z"
        ".zsh_history"
    )
    
    local any_urgent=false
    local any_warning=false
    
    printf "%-15s %-20s %-8s %s\n" "Secret" "Last Modified" "Age" "Status"
    printf "%-15s %-20s %-8s %s\n" "------" "-------------" "---" "------"
    
    for secret in "${SECRETS[@]}"; do
        # Check both age and openssl encrypted versions
        local age_file="$repo_path/$secret.age.encrypted"
        local openssl_file="$repo_path/$secret.encrypted"
        local file_to_check=""
        local encryption_type=""
        
        if [ -f "$age_file" ]; then
            file_to_check="$age_file"
            encryption_type="(age)"
        elif [ -f "$openssl_file" ]; then
            file_to_check="$openssl_file"
            encryption_type="(openssl)"
        fi
        
        if [ -n "$file_to_check" ]; then
            local age_days=$(get_file_age_days "$file_to_check")
            local status=$(check_rotation_needed "$age_days")
            local last_modified=""
            
            if [[ "$OSTYPE" == "darwin"* ]]; then
                last_modified=$(stat -f %Sm -t %Y-%m-%d "$file_to_check")
            else
                last_modified=$(stat -c %y "$file_to_check" | cut -d' ' -f1)
            fi
            
            case "$status" in
                "OK")
                    printf "%-15s %-20s ${GREEN}%-8s %s${NC}\n" "$secret" "$last_modified" "${age_days}d" "✅ $status $encryption_type"
                    ;;
                "WARNING")
                    printf "%-15s %-20s ${YELLOW}%-8s %s${NC}\n" "$secret" "$last_modified" "${age_days}d" "⚠️  $status $encryption_type"
                    any_warning=true
                    ;;
                "URGENT")
                    printf "%-15s %-20s ${RED}%-8s %s${NC}\n" "$secret" "$last_modified" "${age_days}d" "🚨 $status $encryption_type"
                    any_urgent=true
                    ;;
            esac
        else
            printf "%-15s %-20s ${RED}%-8s %s${NC}\n" "$secret" "N/A" "N/A" "❌ MISSING"
            any_urgent=true
        fi
    done
    
    echo ""
    echo "📋 Rotation Guidelines:"
    echo "   • Recommended rotation: every 90 days"
    echo "   • Urgent rotation needed: after 180 days"
    echo ""
    
    if [ "$any_urgent" = true ]; then
        echo -e "${RED}🚨 URGENT: Some secrets need immediate rotation!${NC}"
        echo "   Run: Scripts/rotate_secrets.sh '<new_password>'"
        echo ""
        return 2
    elif [ "$any_warning" = true ]; then
        echo -e "${YELLOW}⚠️  WARNING: Some secrets should be rotated soon.${NC}"
        echo "   Run: Scripts/rotate_secrets.sh '<new_password>'"
        echo ""
        return 1
    else
        echo -e "${GREEN}✅ All secrets are current.${NC}"
        echo ""
        return 0
    fi
}

# Execute main function
main "$@"