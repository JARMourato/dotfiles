#!/bin/bash

set -euo pipefail

################################################################################
### Cache Management Utilities
################################################################################

# This script provides convenient utilities for managing the dotfiles cache
# system including cleanup, statistics, health checks, and maintenance

# Load caching system
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/caching_system.sh" ]; then
    source "$SCRIPT_DIR/caching_system.sh"
else
    echo "❌ Error: caching_system.sh not found"
    exit 1
fi

################################################################################
### Cache Management Commands
################################################################################

# Show cache status dashboard
show_cache_dashboard() {
    clear
    echo "📊 Dotfiles Cache Management Dashboard"
    echo "======================================"
    echo ""
    
    # Cache health check
    if check_cache_health >/dev/null 2>&1; then
        echo "✅ Cache Status: Healthy"
    else
        echo "⚠️  Cache Status: Issues Detected"
    fi
    
    echo ""
    show_cache_stats
    echo ""
    
    # Recent cache activity
    echo "📈 Recent Activity:"
    echo "==================="
    
    # Show recent downloads
    if [ -d "$DOWNLOADS_CACHE" ]; then
        local recent_downloads=$(find "$DOWNLOADS_CACHE" -type f -mtime -1 | wc -l | tr -d ' ')
        echo "📥 Downloads (last 24h): $recent_downloads"
    fi
    
    # Show cached packages
    if [ -d "$PACKAGES_CACHE" ]; then
        local cached_packages=$(find "$PACKAGES_CACHE" -name "*.installed" | wc -l | tr -d ' ')
        echo "📦 Cached packages: $cached_packages"
    fi
    
    echo ""
}

# Interactive cache management menu
interactive_cache_menu() {
    while true; do
        show_cache_dashboard
        echo "🔧 Cache Management Options:"
        echo "1) Show detailed statistics"
        echo "2) Run health check"
        echo "3) Clean old entries"
        echo "4) Optimize Homebrew cache"
        echo "5) Reset entire cache"
        echo "6) Export cache report"
        echo "7) Import/Export cache"
        echo "8) Schedule maintenance"
        echo "q) Quit"
        echo ""
        read -p "Select option (1-8, q): " choice
        
        case $choice in
            1)
                show_cache_stats
                read -p "Press enter to continue..."
                ;;
            2)
                echo "🩺 Running health check..."
                check_cache_health
                read -p "Press enter to continue..."
                ;;
            3)
                cleanup_cache
                read -p "Press enter to continue..."
                ;;
            4)
                optimize_homebrew_cache
                read -p "Press enter to continue..."
                ;;
            5)
                echo "⚠️  This will delete ALL cached data!"
                read -p "Are you sure? (yes/no): " confirm
                if [ "$confirm" = "yes" ]; then
                    reset_cache
                fi
                read -p "Press enter to continue..."
                ;;
            6)
                export_cache_report
                read -p "Press enter to continue..."
                ;;
            7)
                manage_cache_backup
                read -p "Press enter to continue..."
                ;;
            8)
                setup_cache_maintenance
                read -p "Press enter to continue..."
                ;;
            q|Q)
                echo "👋 Goodbye!"
                break
                ;;
            *)
                echo "Invalid option. Press enter to continue..."
                read
                ;;
        esac
    done
}

################################################################################
### Cache Reporting and Analysis
################################################################################

# Export detailed cache report
export_cache_report() {
    local report_file="$HOME/dotfiles_cache_report_$(date +%Y%m%d_%H%M%S).txt"
    
    echo "📄 Generating cache report..."
    
    {
        echo "Dotfiles Cache Report"
        echo "Generated: $(date)"
        echo "=========================="
        echo ""
        
        show_cache_stats
        echo ""
        
        echo "📊 Detailed Breakdown:"
        echo "======================"
        
        # Analyze each cache directory
        for dir in downloads packages config homebrew metadata; do
            local dir_path="$CACHE_ROOT/$dir"
            if [ -d "$dir_path" ]; then
                echo ""
                echo "📁 $dir Directory:"
                echo "  Total size: $(du -sh "$dir_path" 2>/dev/null | cut -f1)"
                echo "  File count: $(find "$dir_path" -type f | wc -l | tr -d ' ')"
                echo "  Oldest file: $(find "$dir_path" -type f -exec ls -t {} + 2>/dev/null | tail -1 | xargs ls -la 2>/dev/null || echo 'None')"
                echo "  Newest file: $(find "$dir_path" -type f -exec ls -t {} + 2>/dev/null | head -1 | xargs ls -la 2>/dev/null || echo 'None')"
            fi
        done
        
        echo ""
        echo "🔍 Health Check Results:"
        echo "========================"
        check_cache_health 2>&1
        
    } > "$report_file"
    
    echo "✅ Report saved to: $report_file"
    echo "📊 Report size: $(du -sh "$report_file" | cut -f1)"
}

# Analyze cache efficiency
analyze_cache_efficiency() {
    echo "📊 Analyzing cache efficiency..."
    
    local total_downloads=0
    local cached_downloads=0
    
    if [ -d "$DOWNLOADS_CACHE" ]; then
        # Count downloads (approximate based on metadata files)
        total_downloads=$(find "$DOWNLOADS_CACHE" -name "*.metadata" | wc -l | tr -d ' ')
        
        # Calculate hit ratio (this is simplified)
        echo "📥 Total downloads cached: $total_downloads"
        
        if [ $total_downloads -gt 0 ]; then
            echo "💾 Cache hit ratio: Estimated based on reuse patterns"
            
            # Show most frequently accessed files
            echo "🔥 Most accessed cached files:"
            find "$DOWNLOADS_CACHE" -type f ! -name "*.metadata" -exec ls -lt {} + 2>/dev/null | head -5 || echo "No access data available"
        fi
    fi
    
    # Package cache analysis
    if [ -d "$PACKAGES_CACHE" ]; then
        local cached_packages=$(find "$PACKAGES_CACHE" -name "*.installed" | wc -l | tr -d ' ')
        echo "📦 Packages tracked in cache: $cached_packages"
    fi
}

################################################################################
### Cache Backup and Restore
################################################################################

# Manage cache backup and restore
manage_cache_backup() {
    echo "💾 Cache Backup Management"
    echo "=========================="
    echo "1) Create backup"
    echo "2) Restore from backup"
    echo "3) List backups"
    echo "4) Delete old backups"
    echo ""
    read -p "Select option (1-4): " choice
    
    case $choice in
        1)
            create_cache_backup
            ;;
        2)
            restore_cache_backup
            ;;
        3)
            list_cache_backups
            ;;
        4)
            cleanup_cache_backups
            ;;
        *)
            echo "Invalid option"
            ;;
    esac
}

# Create cache backup
create_cache_backup() {
    local backup_dir="$HOME/.dotfiles_cache_backups"
    local backup_name="cache_backup_$(date +%Y%m%d_%H%M%S)"
    local backup_path="$backup_dir/$backup_name.tar.gz"
    
    mkdir -p "$backup_dir"
    
    echo "💾 Creating cache backup..."
    echo "📁 Backup location: $backup_path"
    
    if [ -d "$CACHE_ROOT" ]; then
        tar -czf "$backup_path" -C "$(dirname "$CACHE_ROOT")" "$(basename "$CACHE_ROOT")"
        echo "✅ Backup created successfully"
        echo "📊 Backup size: $(du -sh "$backup_path" | cut -f1)"
    else
        echo "❌ No cache directory found to backup"
    fi
}

# Restore cache from backup
restore_cache_backup() {
    local backup_dir="$HOME/.dotfiles_cache_backups"
    
    if [ ! -d "$backup_dir" ]; then
        echo "❌ No backup directory found"
        return 1
    fi
    
    echo "📋 Available backups:"
    ls -la "$backup_dir"/*.tar.gz 2>/dev/null || {
        echo "❌ No backups found"
        return 1
    }
    
    echo ""
    read -p "Enter backup filename: " backup_file
    
    local backup_path="$backup_dir/$backup_file"
    if [ -f "$backup_path" ]; then
        echo "⚠️  This will replace the current cache!"
        read -p "Continue? (yes/no): " confirm
        
        if [ "$confirm" = "yes" ]; then
            echo "🔄 Restoring cache from backup..."
            rm -rf "$CACHE_ROOT"
            tar -xzf "$backup_path" -C "$(dirname "$CACHE_ROOT")"
            echo "✅ Cache restored successfully"
        fi
    else
        echo "❌ Backup file not found: $backup_path"
    fi
}

# List available backups
list_cache_backups() {
    local backup_dir="$HOME/.dotfiles_cache_backups"
    
    if [ -d "$backup_dir" ]; then
        echo "📋 Available cache backups:"
        echo "============================"
        ls -lah "$backup_dir"/*.tar.gz 2>/dev/null || echo "No backups found"
    else
        echo "❌ No backup directory found"
    fi
}

# Cleanup old backups
cleanup_cache_backups() {
    local backup_dir="$HOME/.dotfiles_cache_backups"
    
    if [ ! -d "$backup_dir" ]; then
        echo "❌ No backup directory found"
        return 1
    fi
    
    echo "🧹 Cleaning up old cache backups..."
    
    # Remove backups older than 30 days
    find "$backup_dir" -name "*.tar.gz" -mtime +30 -delete 2>/dev/null || true
    
    echo "✅ Old backups cleaned up"
    list_cache_backups
}

################################################################################
### Cache Maintenance Scheduling
################################################################################

# Setup automated cache maintenance
setup_cache_maintenance() {
    echo "⏰ Cache Maintenance Scheduling"
    echo "==============================="
    echo "1) Setup daily cleanup"
    echo "2) Setup weekly optimization"
    echo "3) View current schedules"
    echo "4) Remove schedules"
    echo ""
    read -p "Select option (1-4): " choice
    
    case $choice in
        1)
            setup_daily_cleanup
            ;;
        2)
            setup_weekly_optimization
            ;;
        3)
            view_maintenance_schedules
            ;;
        4)
            remove_maintenance_schedules
            ;;
        *)
            echo "Invalid option"
            ;;
    esac
}

# Setup daily cache cleanup via cron
setup_daily_cleanup() {
    local cron_command="$SCRIPT_DIR/cache_utils.sh --cleanup"
    local cron_entry="0 2 * * * $cron_command # Dotfiles cache cleanup"
    
    echo "⏰ Setting up daily cache cleanup at 2 AM..."
    
    # Check if cron entry already exists
    if crontab -l 2>/dev/null | grep -q "Dotfiles cache cleanup"; then
        echo "✅ Daily cleanup already scheduled"
    else
        # Add to crontab
        (crontab -l 2>/dev/null; echo "$cron_entry") | crontab -
        echo "✅ Daily cleanup scheduled for 2 AM"
    fi
}

# Setup weekly optimization
setup_weekly_optimization() {
    local cron_command="$SCRIPT_DIR/cache_utils.sh --optimize"
    local cron_entry="0 3 * * 0 $cron_command # Dotfiles cache optimization"
    
    echo "⏰ Setting up weekly cache optimization on Sundays at 3 AM..."
    
    # Check if cron entry already exists
    if crontab -l 2>/dev/null | grep -q "Dotfiles cache optimization"; then
        echo "✅ Weekly optimization already scheduled"
    else
        # Add to crontab
        (crontab -l 2>/dev/null; echo "$cron_entry") | crontab -
        echo "✅ Weekly optimization scheduled for Sundays at 3 AM"
    fi
}

# View current maintenance schedules
view_maintenance_schedules() {
    echo "📅 Current maintenance schedules:"
    echo "================================="
    
    if crontab -l 2>/dev/null | grep -q "Dotfiles cache"; then
        crontab -l 2>/dev/null | grep "Dotfiles cache"
    else
        echo "❌ No maintenance schedules found"
    fi
}

# Remove maintenance schedules
remove_maintenance_schedules() {
    echo "🗑️  Removing cache maintenance schedules..."
    
    # Remove dotfiles cache entries from crontab
    crontab -l 2>/dev/null | grep -v "Dotfiles cache" | crontab -
    
    echo "✅ Maintenance schedules removed"
}

################################################################################
### Help Documentation
################################################################################

show_cache_utils_help() {
    cat << 'EOF'
📖 cache_utils.sh - Cache management utilities for dotfiles

DESCRIPTION:
    Provides convenient utilities for managing the dotfiles cache system
    including cleanup, statistics, health checks, and maintenance.

USAGE:
    cache_utils.sh [COMMAND] [OPTIONS]
    cache_utils.sh --help

COMMANDS:
    --interactive, -i        Interactive cache management menu
    --dashboard, -d          Show cache status dashboard
    --stats, -s              Show cache statistics
    --health, -h             Run cache health check
    --cleanup, -c            Clean old cache entries
    --optimize, -o           Optimize caches (Homebrew, etc.)
    --reset                  Reset entire cache (WARNING: destructive)
    --report                 Export detailed cache report
    --backup                 Create cache backup
    --restore                Restore cache from backup
    --schedule               Setup maintenance scheduling
    --analyze                Analyze cache efficiency

EXAMPLES:
    # Interactive management
    cache_utils.sh --interactive
    
    # Quick health check
    cache_utils.sh --health
    
    # Daily maintenance
    cache_utils.sh --cleanup --optimize
    
    # Generate report
    cache_utils.sh --report

AUTOMATION:
    # Add to crontab for daily cleanup
    0 2 * * * ~/Scripts/cache_utils.sh --cleanup
    
    # Weekly optimization
    0 3 * * 0 ~/Scripts/cache_utils.sh --optimize

EOF
}

################################################################################
### Main Command Processing
################################################################################

# Process command line arguments
main() {
    case "${1:-}" in
        --interactive|-i)
            interactive_cache_menu
            ;;
        --dashboard|-d)
            show_cache_dashboard
            ;;
        --stats|-s)
            show_cache_stats
            ;;
        --health)
            check_cache_health
            ;;
        --cleanup|-c)
            cleanup_cache
            ;;
        --optimize|-o)
            optimize_homebrew_cache
            ;;
        --reset)
            echo "⚠️  This will delete ALL cached data!"
            read -p "Are you sure? (yes/no): " confirm
            if [ "$confirm" = "yes" ]; then
                reset_cache
            fi
            ;;
        --report)
            export_cache_report
            ;;
        --backup)
            create_cache_backup
            ;;
        --restore)
            restore_cache_backup
            ;;
        --schedule)
            setup_cache_maintenance
            ;;
        --analyze)
            analyze_cache_efficiency
            ;;
        --help|-h)
            show_cache_utils_help
            ;;
        "")
            echo "Cache management utilities for dotfiles"
            echo "Use --help for more information or --interactive for menu"
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
}

# Run main function if script is executed directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi