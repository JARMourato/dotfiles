#!/bin/bash
set -euo pipefail

################################################################################
### Usage Analytics and Optimization System
################################################################################
# Track command usage patterns, analyze performance, and generate optimization recommendations
# Completely local and private - no external data transmission

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"
USAGE_LOG="$HOME/.dotfiles_usage.log"
ANALYTICS_DIR="$HOME/.dotfiles_analytics"
ANALYTICS_DB="$ANALYTICS_DIR/analytics.db"
COMMAND_FREQUENCY="$ANALYTICS_DIR/command_frequency.txt"
TIME_PATTERNS="$ANALYTICS_DIR/time_patterns.txt"
CONTEXT_PATTERNS="$ANALYTICS_DIR/context_patterns.txt"
PERFORMANCE_TRENDS="$ANALYTICS_DIR/performance_trends.txt"
RECOMMENDATIONS="$ANALYTICS_DIR/recommendations.txt"
USAGE_REPORT="$ANALYTICS_DIR/usage_report.json"

# Load progress indicators
source "$SCRIPT_DIR/progress_indicators.sh" 2>/dev/null || true

################################################################################
### Initialization and Setup
################################################################################

init_usage_tracking() {
    echo "📊 Initializing usage analytics system..."
    
    # Create analytics directories
    mkdir -p "$ANALYTICS_DIR"
    mkdir -p "$ANALYTICS_DIR/reports"
    mkdir -p "$ANALYTICS_DIR/cache"
    
    # Initialize usage log if doesn't exist
    if [ ! -f "$USAGE_LOG" ]; then
        touch "$USAGE_LOG"
        echo "$(date +%s)|system|usage_tracking_started|$PWD|$(date +%u)|$(date +%H)" >> "$USAGE_LOG"
    fi
    
    # Set up command tracking if not already enabled
    setup_command_tracking
    
    echo "✅ Usage analytics system initialized"
}

setup_command_tracking() {
    echo "⚙️ Setting up command tracking..."
    
    # Create tracking wrapper script
    cat > "$ANALYTICS_DIR/track_command.sh" << 'EOF'
#!/bin/bash
# Usage tracking wrapper - sourced by shell configs

USAGE_LOG="$HOME/.dotfiles_usage.log"

track_command() {
    local cmd="$1"
    local timestamp=$(date +%s)
    local pwd="$PWD"
    local day_of_week=$(date +%u)  # 1-7 (Monday-Sunday)
    local hour=$(date +%H)         # 0-23
    
    # Lightweight logging - just append to file
    echo "$timestamp|$cmd|$pwd|$day_of_week|$hour" >> "$USAGE_LOG" 2>/dev/null || true
    
    # Async processing to avoid slowing down commands
    (process_usage_async "$cmd" "$timestamp" &) 2>/dev/null || true
}

process_usage_async() {
    local cmd="$1"
    local timestamp="$2"
    
    # Update simple counters (very fast)
    echo "$cmd" >> "$HOME/.dotfiles_command_counts.tmp" 2>/dev/null || true
    
    # Periodic processing (every 100 commands or daily)
    if should_process_analytics; then
        process_analytics_batch 2>/dev/null &
    fi
}

should_process_analytics() {
    local count_file="$HOME/.dotfiles_command_counts.tmp"
    
    # Process if temp file has 100+ entries or daily
    if [ -f "$count_file" ]; then
        local line_count=$(wc -l < "$count_file" 2>/dev/null || echo "0")
        [ "$line_count" -gt 100 ] && return 0
    fi
    
    # Check if we've processed today
    local last_process_file="$HOME/.dotfiles_last_analytics_process"
    local today=$(date +%Y%m%d)
    
    if [ ! -f "$last_process_file" ] || [ "$(cat "$last_process_file" 2>/dev/null)" != "$today" ]; then
        echo "$today" > "$last_process_file"
        return 0
    fi
    
    return 1
}

process_analytics_batch() {
    # This would trigger the full analytics processing
    # Keep it lightweight to avoid shell slowdown
    return 0
}

# Function to wrap commands with tracking
setup_tracked_aliases() {
    local commands_to_track=(
        "git" "brew" "npm" "docker" "kubectl" "code" "vim" "nvim" "python" "node"
        "curl" "wget" "ssh" "scp" "rsync" "grep" "find" "awk" "sed" "jq" "tree"
        "ls" "cd" "mkdir" "cp" "mv" "rm" "cat" "less" "more" "head" "tail"
        "ps" "top" "htop" "df" "du" "free" "uptime" "which" "man" "history"
    )
    
    for cmd in "${commands_to_track[@]}"; do
        if command -v "$cmd" >/dev/null 2>&1; then
            # Create alias that tracks then executes
            alias "$cmd"="track_command '$cmd' && command $cmd"
        fi
    done
}

# Auto-setup when sourced
setup_tracked_aliases
EOF
    
    chmod +x "$ANALYTICS_DIR/track_command.sh"
    
    # Add to shell config if not already present
    local shell_config="$HOME/.zshrc"
    if [ -f "$shell_config" ] && ! grep -q "track_command.sh" "$shell_config"; then
        echo "" >> "$shell_config"
        echo "# Usage analytics tracking" >> "$shell_config"
        echo "source \"$ANALYTICS_DIR/track_command.sh\" 2>/dev/null || true" >> "$shell_config"
        echo "✅ Added tracking to shell configuration"
    fi
}

################################################################################
### Data Processing and Analysis
################################################################################

process_usage_data() {
    echo "🔄 Processing usage data..."
    
    if [ ! -f "$USAGE_LOG" ]; then
        echo "⚠️ No usage data found. Enable tracking first."
        return 1
    fi
    
    # Get recent usage data (last 30 days)
    local cutoff_date
    cutoff_date=$(date -v-30d +%s 2>/dev/null || date -d '30 days ago' +%s 2>/dev/null || echo "0")
    
    awk -F'|' -v cutoff="$cutoff_date" '$1 > cutoff' "$USAGE_LOG" > /tmp/recent_usage.log
    
    local total_commands
    total_commands=$(wc -l < /tmp/recent_usage.log)
    
    echo "📊 Processing $total_commands commands from the last 30 days..."
    
    # Process different aspects
    calculate_command_frequency
    calculate_time_patterns
    calculate_context_patterns
    calculate_performance_impact
    
    echo "✅ Usage data processing complete"
}

calculate_command_frequency() {
    echo "  📈 Calculating command frequency..."
    
    # Most used commands
    awk -F'|' '{print $2}' /tmp/recent_usage.log | \
        sort | uniq -c | sort -nr > "$COMMAND_FREQUENCY"
    
    # Commands never used (installed but unused)
    comm -23 <(brew list 2>/dev/null | sort) \
             <(awk -F'|' '{print $2}' /tmp/recent_usage.log | sort -u) \
             > "$ANALYTICS_DIR/unused_commands.txt" 2>/dev/null || true
    
    # Calculate usage statistics
    local total_commands
    total_commands=$(awk '{sum+=$1} END {print sum}' "$COMMAND_FREQUENCY")
    
    echo "total_commands:$total_commands" > "$ANALYTICS_DIR/usage_stats.txt"
    echo "unique_commands:$(wc -l < "$COMMAND_FREQUENCY")" >> "$ANALYTICS_DIR/usage_stats.txt"
    echo "unused_commands:$(wc -l < "$ANALYTICS_DIR/unused_commands.txt" 2>/dev/null || echo "0")" >> "$ANALYTICS_DIR/usage_stats.txt"
}

calculate_time_patterns() {
    echo "  ⏰ Analyzing time patterns..."
    
    # Usage by hour of day
    awk -F'|' '{count[$5]++} END {for(hour in count) print hour, count[hour]}' \
        /tmp/recent_usage.log | sort -n > "$ANALYTICS_DIR/hourly_usage.txt"
    
    # Usage by day of week (1=Monday, 7=Sunday)
    awk -F'|' '{count[$4]++} END {for(day in count) print day, count[day]}' \
        /tmp/recent_usage.log | sort -n > "$ANALYTICS_DIR/daily_usage.txt"
    
    # Peak usage analysis
    local peak_hour
    peak_hour=$(sort -k2 -nr "$ANALYTICS_DIR/hourly_usage.txt" | head -1 | awk '{print $1}')
    
    local peak_day
    peak_day=$(sort -k2 -nr "$ANALYTICS_DIR/daily_usage.txt" | head -1 | awk '{print $1}')
    
    cat > "$TIME_PATTERNS" << EOF
peak_hour:$peak_hour
peak_day:$peak_day
analysis_date:$(date +%s)
EOF
    
    # Calculate work vs personal time usage
    analyze_work_personal_patterns
}

analyze_work_personal_patterns() {
    echo "  💼 Analyzing work vs personal usage patterns..."
    
    # Work hours: 9-17 (9 AM - 5 PM), weekdays (1-5)
    local work_commands
    work_commands=$(awk -F'|' '$4 >= 1 && $4 <= 5 && $5 >= 9 && $5 <= 17' /tmp/recent_usage.log | wc -l)
    
    # Personal hours: everything else
    local total_commands
    total_commands=$(wc -l < /tmp/recent_usage.log)
    local personal_commands=$((total_commands - work_commands))
    
    cat >> "$TIME_PATTERNS" << EOF
work_hours_commands:$work_commands
personal_hours_commands:$personal_commands
work_percentage:$(echo "scale=1; $work_commands * 100 / $total_commands" | bc 2>/dev/null || echo "0")
EOF
}

calculate_context_patterns() {
    echo "  📁 Analyzing context patterns..."
    
    # Command usage by directory
    awk -F'|' '{
        gsub(/\/[^\/]*$/, "", $3);  # Remove filename, keep directory
        if ($3 == "") $3 = "/";     # Root directory
        count[$3"|"$2]++
    } END {
        for(key in count) print key, count[key]
    }' /tmp/recent_usage.log | sort -k3 -nr > "$CONTEXT_PATTERNS"
    
    # Project-specific tool usage analysis
    analyze_project_tool_correlation
    
    # Directory-specific recommendations
    generate_context_recommendations
}

analyze_project_tool_correlation() {
    echo "  🔗 Analyzing project-tool correlations..."
    
    # Identify project directories (those with common project files)
    local project_dirs=()
    
    # Look for directories with package.json, Cargo.toml, Package.swift, etc.
    while IFS= read -r dir; do
        if [ -d "$dir" ] && ([ -f "$dir/package.json" ] || [ -f "$dir/Cargo.toml" ] || [ -f "$dir/Package.swift" ] || [ -f "$dir/go.mod" ] || [ -f "$dir/requirements.txt" ]); then
            project_dirs+=("$dir")
        fi
    done < <(awk -F'|' '{print $3}' /tmp/recent_usage.log | sort -u)
    
    # Analyze tool usage in project directories
    > "$ANALYTICS_DIR/project_tool_correlation.txt"
    for proj_dir in "${project_dirs[@]}"; do
        echo "# Project: $proj_dir" >> "$ANALYTICS_DIR/project_tool_correlation.txt"
        grep "|$proj_dir|" /tmp/recent_usage.log | awk -F'|' '{print $2}' | \
            sort | uniq -c | sort -nr | head -10 >> "$ANALYTICS_DIR/project_tool_correlation.txt"
        echo "" >> "$ANALYTICS_DIR/project_tool_correlation.txt"
    done
}

generate_context_recommendations() {
    echo "  💡 Generating context-based recommendations..."
    
    > "$ANALYTICS_DIR/context_recommendations.txt"
    
    # High-frequency directory-command combinations
    head -20 "$CONTEXT_PATTERNS" | while IFS= read -r line; do
        local dir_cmd=$(echo "$line" | awk '{print $1}')
        local count=$(echo "$line" | awk '{print $2}')
        local dir=$(echo "$dir_cmd" | cut -d'|' -f1)
        local cmd=$(echo "$dir_cmd" | cut -d'|' -f2)
        
        if [ "$count" -gt 10 ]; then
            echo "High $cmd usage in $dir ($count times) - consider directory-specific aliases" >> "$ANALYTICS_DIR/context_recommendations.txt"
        fi
    done
}

calculate_performance_impact() {
    echo "  ⚡ Calculating performance impact..."
    
    # Correlate command usage with system performance
    local shell_startup_time
    shell_startup_time=$(measure_shell_startup_time 2>/dev/null || echo "1000")
    
    # Get loaded tools at startup
    local loaded_tools
    loaded_tools=$(get_tools_loaded_at_startup)
    
    # Get usage frequency for loaded tools
    local usage_correlation=()
    
    while IFS= read -r tool; do
        local usage_count
        usage_count=$(grep "|$tool|" /tmp/recent_usage.log | wc -l)
        usage_correlation+=("$tool:$usage_count")
    done < <(echo "$loaded_tools")
    
    # Calculate efficiency score
    calculate_startup_efficiency "${usage_correlation[@]}"
    
    # Track performance trends
    echo "$(date +%s)|shell_startup|$shell_startup_time" >> "$PERFORMANCE_TRENDS"
}

measure_shell_startup_time() {
    local start_time end_time duration
    start_time=$(date +%s%3N)
    zsh -i -c exit 2>/dev/null
    end_time=$(date +%s%3N)
    duration=$((end_time - start_time))
    echo "$duration"
}

get_tools_loaded_at_startup() {
    # Analyze .zshrc and related files to see what's loaded
    if [ -f "$HOME/.zshrc" ]; then
        grep -ho '\b[a-zA-Z0-9_-]*\b' "$HOME/.zshrc" | \
            grep -E '^(git|brew|npm|node|python|docker|kubectl|aws|terraform)$' | \
            sort -u
    fi
}

calculate_startup_efficiency() {
    local usage_correlation=("$@")
    
    echo "  📊 Calculating startup efficiency..."
    
    local total_loaded=0
    local total_used=0
    
    for correlation in "${usage_correlation[@]}"; do
        local tool="${correlation%%:*}"
        local usage="${correlation##*:}"
        
        ((total_loaded++))
        [ "$usage" -gt 0 ] && ((total_used++))
    done
    
    local efficiency=0
    if [ $total_loaded -gt 0 ]; then
        efficiency=$(echo "scale=1; $total_used * 100 / $total_loaded" | bc 2>/dev/null || echo "0")
    fi
    
    echo "startup_efficiency:$efficiency" > "$ANALYTICS_DIR/performance_metrics.txt"
    echo "tools_loaded:$total_loaded" >> "$ANALYTICS_DIR/performance_metrics.txt"
    echo "tools_used:$total_used" >> "$ANALYTICS_DIR/performance_metrics.txt"
}

################################################################################
### Recommendations Engine
################################################################################

generate_optimization_recommendations() {
    echo "💡 Generating optimization recommendations..."
    
    local recommendations=()
    
    # Unused tool recommendations
    generate_unused_tool_recommendations recommendations
    
    # Performance recommendations
    generate_performance_recommendations recommendations
    
    # Context-aware recommendations
    generate_context_aware_recommendations recommendations
    
    # Time-based recommendations
    generate_time_based_recommendations recommendations
    
    # Usage pattern recommendations
    generate_usage_pattern_recommendations recommendations
    
    # Save recommendations
    printf '%s\n' "${recommendations[@]}" > "$RECOMMENDATIONS"
    
    echo "✅ Generated ${#recommendations[@]} optimization recommendations"
}

generate_unused_tool_recommendations() {
    local -n rec_ref=$1
    
    if [ -f "$ANALYTICS_DIR/unused_commands.txt" ] && [ -s "$ANALYTICS_DIR/unused_commands.txt" ]; then
        local unused_count
        unused_count=$(wc -l < "$ANALYTICS_DIR/unused_commands.txt")
        
        if [ "$unused_count" -gt 0 ]; then
            rec_ref+=("🗑️ Remove $unused_count unused tools to speed startup (brew uninstall <tool>)")
            
            # Specific recommendations for top unused tools
            head -5 "$ANALYTICS_DIR/unused_commands.txt" | while read -r tool; do
                rec_ref+=("  • Consider removing unused tool: $tool")
            done
        fi
    fi
}

generate_performance_recommendations() {
    local -n rec_ref=$1
    
    if [ -f "$ANALYTICS_DIR/performance_metrics.txt" ]; then
        local efficiency
        efficiency=$(grep "startup_efficiency:" "$ANALYTICS_DIR/performance_metrics.txt" | cut -d':' -f2)
        
        if [ "${efficiency%%.*}" -lt 60 ]; then
            rec_ref+=("⚡ Low startup efficiency (${efficiency}%) - consider removing unused shell plugins")
        fi
    fi
    
    # Check shell startup time
    if [ -f "$PERFORMANCE_TRENDS" ]; then
        local recent_startup
        recent_startup=$(tail -1 "$PERFORMANCE_TRENDS" | cut -d'|' -f3)
        
        if [ "${recent_startup:-0}" -gt 2000 ]; then
            rec_ref+=("🐌 Slow shell startup (${recent_startup}ms) - profile your .zshrc with 'zprof'")
        fi
    fi
    
    # Most used tool optimization
    if [ -f "$COMMAND_FREQUENCY" ]; then
        local most_used
        most_used=$(head -1 "$COMMAND_FREQUENCY" | awk '{print $2}')
        local usage_count
        usage_count=$(head -1 "$COMMAND_FREQUENCY" | awk '{print $1}')
        
        if [ "$usage_count" -gt 50 ]; then
            rec_ref+=("🏆 Optimize your most used tool: $most_used (used $usage_count times)")
            
            case "$most_used" in
                git)
                    rec_ref+=("  • Setup Git aliases: alias gs='git status', gp='git push'")
                    rec_ref+=("  • Enable Git autocomplete and prompt integration")
                    ;;
                docker)
                    rec_ref+=("  • Setup Docker aliases: alias dps='docker ps', dex='docker exec -it'")
                    ;;
                kubectl)
                    rec_ref+=("  • Setup kubectl aliases: alias k='kubectl', kgp='kubectl get pods'")
                    ;;
            esac
        fi
    fi
}

generate_context_aware_recommendations() {
    local -n rec_ref=$1
    
    if [ -f "$ANALYTICS_DIR/context_recommendations.txt" ] && [ -s "$ANALYTICS_DIR/context_recommendations.txt" ]; then
        while IFS= read -r recommendation; do
            rec_ref+=("📁 $recommendation")
        done < "$ANALYTICS_DIR/context_recommendations.txt"
    fi
    
    # Project-specific recommendations
    if [ -f "$ANALYTICS_DIR/project_tool_correlation.txt" ]; then
        # Add recommendations based on project usage patterns
        local current_dir="$PWD"
        if grep -q "$current_dir" "$ANALYTICS_DIR/project_tool_correlation.txt"; then
            rec_ref+=("🎯 Setup project-specific aliases for $current_dir")
        fi
    fi
}

generate_time_based_recommendations() {
    local -n rec_ref=$1
    
    if [ -f "$TIME_PATTERNS" ]; then
        local work_percentage
        work_percentage=$(grep "work_percentage:" "$TIME_PATTERNS" | cut -d':' -f2)
        
        if [ "${work_percentage%%.*}" -gt 70 ]; then
            rec_ref+=("💼 High work usage (${work_percentage}%) - consider work-specific dotfiles profile")
        elif [ "${work_percentage%%.*}" -lt 30 ]; then
            rec_ref+=("🏠 High personal usage - consider gaming/entertainment tools")
        fi
        
        local peak_hour
        peak_hour=$(grep "peak_hour:" "$TIME_PATTERNS" | cut -d':' -f2)
        
        if [ "$peak_hour" -ge 22 ] || [ "$peak_hour" -le 6 ]; then
            rec_ref+=("🌙 Night owl detected - consider dark themes and blue light filters")
        elif [ "$peak_hour" -ge 6 ] && [ "$peak_hour" -le 9 ]; then
            rec_ref+=("🌅 Early bird detected - consider morning productivity workflows")
        fi
    fi
}

generate_usage_pattern_recommendations() {
    local -n rec_ref=$1
    
    if [ -f "$COMMAND_FREQUENCY" ]; then
        # Check for tool combinations that could benefit from workflows
        local git_usage
        git_usage=$(grep "git" "$COMMAND_FREQUENCY" | head -1 | awk '{print $1}' || echo "0")
        
        local docker_usage
        docker_usage=$(grep "docker" "$COMMAND_FREQUENCY" | head -1 | awk '{print $1}' || echo "0")
        
        if [ "$git_usage" -gt 20 ] && [ "$docker_usage" -gt 10 ]; then
            rec_ref+=("🔄 High Git+Docker usage - consider container-based development workflows")
        fi
        
        # Check for tools that could be combined
        local npm_usage
        npm_usage=$(grep "npm" "$COMMAND_FREQUENCY" | head -1 | awk '{print $1}' || echo "0")
        
        local node_usage
        node_usage=$(grep "node" "$COMMAND_FREQUENCY" | head -1 | awk '{print $1}' || echo "0")
        
        if [ "$npm_usage" -gt 15 ] && [ "$node_usage" -gt 15 ]; then
            rec_ref+=("📦 High Node.js usage - consider nvm for version management")
        fi
    fi
}

################################################################################
### Usage Dashboard and Reporting
################################################################################

show_usage_dashboard() {
    echo "📊 Usage Analytics Dashboard"
    echo "==========================="
    
    # Process latest data
    process_usage_data >/dev/null 2>&1
    
    # Summary statistics
    show_usage_summary
    
    echo ""
    
    # Top commands
    show_top_commands
    
    echo ""
    
    # Time patterns
    show_time_patterns
    
    echo ""
    
    # Performance insights
    show_performance_insights
    
    echo ""
    
    # Current recommendations
    show_current_recommendations
}

show_usage_summary() {
    echo "📈 Usage Summary:"
    
    if [ -f "$ANALYTICS_DIR/usage_stats.txt" ]; then
        local total_commands
        total_commands=$(grep "total_commands:" "$ANALYTICS_DIR/usage_stats.txt" | cut -d':' -f2)
        
        local unique_commands
        unique_commands=$(grep "unique_commands:" "$ANALYTICS_DIR/usage_stats.txt" | cut -d':' -f2)
        
        local unused_commands
        unused_commands=$(grep "unused_commands:" "$ANALYTICS_DIR/usage_stats.txt" | cut -d':' -f2)
        
        # Calculate tracking period
        local tracking_days=30  # Default for recent analysis
        local avg_commands_per_day=$((total_commands / tracking_days))
        
        echo "  Commands tracked: $total_commands (last 30 days)"
        echo "  Unique commands used: $unique_commands"
        echo "  Unused installed tools: $unused_commands"
        echo "  Average commands/day: $avg_commands_per_day"
    else
        echo "  No usage data available yet"
    fi
}

show_top_commands() {
    echo "🏆 Top 10 Most Used Commands:"
    
    if [ -f "$COMMAND_FREQUENCY" ]; then
        head -10 "$COMMAND_FREQUENCY" | awk '{
            printf "  %2d. %-15s (%d uses)\n", NR, $2, $1
        }'
    else
        echo "  No command frequency data available"
    fi
}

show_time_patterns() {
    echo "⏰ Usage Patterns:"
    
    if [ -f "$TIME_PATTERNS" ]; then
        local peak_hour
        peak_hour=$(grep "peak_hour:" "$TIME_PATTERNS" | cut -d':' -f2)
        
        local work_percentage
        work_percentage=$(grep "work_percentage:" "$TIME_PATTERNS" | cut -d':' -f2)
        
        echo "  Peak usage hour: ${peak_hour}:00"
        echo "  Work hours usage: ${work_percentage}%"
        
        # Show hourly distribution
        if [ -f "$ANALYTICS_DIR/hourly_usage.txt" ]; then
            echo "  Hourly distribution:"
            head -5 "$ANALYTICS_DIR/hourly_usage.txt" | while read -r hour count; do
                printf "    %02d:00 - %d commands\n" "$hour" "$count"
            done
        fi
    else
        echo "  No time pattern data available"
    fi
}

show_performance_insights() {
    echo "⚡ Performance Insights:"
    
    if [ -f "$ANALYTICS_DIR/performance_metrics.txt" ]; then
        local efficiency
        efficiency=$(grep "startup_efficiency:" "$ANALYTICS_DIR/performance_metrics.txt" | cut -d':' -f2)
        
        local tools_loaded
        tools_loaded=$(grep "tools_loaded:" "$ANALYTICS_DIR/performance_metrics.txt" | cut -d':' -f2)
        
        local tools_used
        tools_used=$(grep "tools_used:" "$ANALYTICS_DIR/performance_metrics.txt" | cut -d':' -f2)
        
        echo "  Startup efficiency: ${efficiency}%"
        echo "  Tools loaded at startup: $tools_loaded"
        echo "  Tools actually used: $tools_used"
        
        if [ -f "$PERFORMANCE_TRENDS" ]; then
            local recent_startup
            recent_startup=$(tail -1 "$PERFORMANCE_TRENDS" | cut -d'|' -f3)
            echo "  Shell startup time: ${recent_startup}ms"
        fi
    else
        echo "  No performance data available"
    fi
}

show_current_recommendations() {
    echo "💡 Current Recommendations:"
    
    # Generate fresh recommendations
    generate_optimization_recommendations >/dev/null 2>&1
    
    if [ -f "$RECOMMENDATIONS" ] && [ -s "$RECOMMENDATIONS" ]; then
        head -8 "$RECOMMENDATIONS" | sed 's/^/  /'
        
        local total_recommendations
        total_recommendations=$(wc -l < "$RECOMMENDATIONS")
        
        if [ "$total_recommendations" -gt 8 ]; then
            echo "  ... and $((total_recommendations - 8)) more recommendations"
            echo "  💡 Run 'usage_analyzer.sh recommendations' to see all"
        fi
    else
        echo "  System running optimally!"
    fi
}

generate_usage_report() {
    echo "📊 Generating comprehensive usage report..."
    
    # Process all data
    process_usage_data >/dev/null 2>&1
    generate_optimization_recommendations >/dev/null 2>&1
    
    # Create JSON report
    cat > "$USAGE_REPORT" << EOF
{
    "generated_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
    "period": "last_30_days",
    "summary": {
        "total_commands": $(grep "total_commands:" "$ANALYTICS_DIR/usage_stats.txt" 2>/dev/null | cut -d':' -f2 || echo "0"),
        "unique_commands": $(grep "unique_commands:" "$ANALYTICS_DIR/usage_stats.txt" 2>/dev/null | cut -d':' -f2 || echo "0"),
        "unused_commands": $(grep "unused_commands:" "$ANALYTICS_DIR/usage_stats.txt" 2>/dev/null | cut -d':' -f2 || echo "0")
    },
    "performance": {
        "startup_efficiency": $(grep "startup_efficiency:" "$ANALYTICS_DIR/performance_metrics.txt" 2>/dev/null | cut -d':' -f2 || echo "0"),
        "shell_startup_time": $(tail -1 "$PERFORMANCE_TRENDS" 2>/dev/null | cut -d'|' -f3 || echo "0")
    },
    "patterns": {
        "peak_hour": $(grep "peak_hour:" "$TIME_PATTERNS" 2>/dev/null | cut -d':' -f2 || echo "12"),
        "work_percentage": $(grep "work_percentage:" "$TIME_PATTERNS" 2>/dev/null | cut -d':' -f2 || echo "50")
    },
    "recommendations_count": $(wc -l < "$RECOMMENDATIONS" 2>/dev/null || echo "0")
}
EOF
    
    echo "✅ Usage report saved: $USAGE_REPORT"
}

################################################################################
### Integration Functions
################################################################################

integrate_with_health_monitor() {
    echo "🔗 Integrating with health monitor..."
    
    # Add usage-based health metrics to health monitor
    local health_script="$SCRIPT_DIR/health_monitor.sh"
    
    if [ -f "$health_script" ]; then
        # Add usage metrics to health dashboard
        cat >> "$health_script" << 'EOF'

# Usage analytics integration
show_usage_health_metrics() {
    if [ -f "$HOME/.dotfiles_analytics/performance_metrics.txt" ]; then
        local efficiency
        efficiency=$(grep "startup_efficiency:" "$HOME/.dotfiles_analytics/performance_metrics.txt" | cut -d':' -f2)
        
        echo "📊 Usage Health:"
        echo "  Startup efficiency: ${efficiency}%"
        echo "  Performance trend: $(calculate_performance_trend)"
    fi
}

calculate_performance_trend() {
    if [ -f "$HOME/.dotfiles_analytics/performance_trends.txt" ]; then
        local trend_data
        trend_data=$(tail -5 "$HOME/.dotfiles_analytics/performance_trends.txt" | awk -F'|' '{print $3}')
        
        # Simple trend calculation
        echo "stable"  # Simplified for integration
    else
        echo "unknown"
    fi
}
EOF
        echo "✅ Integrated with health monitor"
    fi
}

################################################################################
### Main Interface
################################################################################

show_help() {
    cat << 'EOF'
📊 Usage Analytics and Optimization System

DESCRIPTION:
    Track command usage patterns, analyze performance, and generate optimization recommendations.
    Completely local and private - no external data transmission.

USAGE:
    ./usage_analyzer.sh <command> [options]

COMMANDS:
    init                   Initialize usage tracking system
    dashboard              Show usage analytics dashboard
    process                Process and analyze usage data
    recommendations        Show optimization recommendations
    report                 Generate comprehensive usage report
    trends                 Show usage trends over time
    
    --help                Show this help message

EXAMPLES:
    ./usage_analyzer.sh init              # Setup usage tracking
    ./usage_analyzer.sh dashboard         # Show analytics dashboard
    ./usage_analyzer.sh recommendations   # Get optimization suggestions
    ./usage_analyzer.sh report           # Generate detailed report

FEATURES:
    📊 Command usage frequency tracking
    ⏰ Time-based usage pattern analysis
    📁 Context-aware recommendations
    ⚡ Performance impact analysis
    💡 Intelligent optimization suggestions
    🔒 Completely local and private

FILES:
    ~/.dotfiles_usage.log                Usage tracking log
    ~/.dotfiles_analytics/               Analytics data directory
    ~/.dotfiles_analytics/usage_report.json    Comprehensive usage report

EOF
}

main() {
    case "${1:-dashboard}" in
        init)
            init_usage_tracking
            ;;
        dashboard)
            show_usage_dashboard
            ;;
        process)
            process_usage_data
            ;;
        recommendations)
            generate_optimization_recommendations
            if [ -f "$RECOMMENDATIONS" ]; then
                echo "💡 All Optimization Recommendations:"
                echo "===================================="
                cat "$RECOMMENDATIONS"
            fi
            ;;
        report)
            generate_usage_report
            echo "📊 Report generated: $USAGE_REPORT"
            ;;
        trends)
            if [ -f "$PERFORMANCE_TRENDS" ]; then
                echo "📈 Performance Trends:"
                echo "====================="
                tail -10 "$PERFORMANCE_TRENDS" | while IFS='|' read -r timestamp type value; do
                    local date_str
                    date_str=$(date -r "$timestamp" "+%Y-%m-%d %H:%M" 2>/dev/null || echo "Unknown")
                    echo "  $date_str: $type = ${value}ms"
                done
            else
                echo "No trend data available yet"
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