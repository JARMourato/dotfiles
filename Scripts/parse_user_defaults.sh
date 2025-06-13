#!/bin/bash

################################################################################
### Parse user defaults from YAML configuration
################################################################################

# Function to parse user defaults from YAML and generate shell variables
parse_user_defaults() {
    local yaml_file="$1"
    local output_file="$2"
    
    if [[ ! -f "$yaml_file" ]]; then
        echo "❌ YAML file not found: $yaml_file"
        return 1
    fi
    
    echo "# User Defaults Configuration (parsed from YAML)" >> "$output_file"
    echo "" >> "$output_file"
    
    # Check if user_defaults section exists
    if ! grep -q "user_defaults:" "$yaml_file"; then
        echo "# No user_defaults section found in YAML" >> "$output_file"
        return 0
    fi
    
    # Parse Activity Monitor settings
    parse_section "activity_monitor" "$yaml_file" "$output_file" "ACTIVITY_MONITOR_"
    
    # Parse App Store settings  
    parse_section "app_store" "$yaml_file" "$output_file" "APP_STORE_"
    
    # Parse Dock settings
    parse_section "dock" "$yaml_file" "$output_file" "DOCK_"
    
    # Parse Finder settings
    parse_section "finder" "$yaml_file" "$output_file" "FINDER_"
    
    # Parse Keyboard settings
    parse_section "keyboard" "$yaml_file" "$output_file" "KEYBOARD_"
    
    # Parse Language & Region settings
    parse_section "language_region" "$yaml_file" "$output_file" "LANGUAGE_"
    
    # Parse Mouse settings
    parse_section "mouse" "$yaml_file" "$output_file" "MOUSE_"
    
    # Parse Trackpad settings
    parse_section "trackpad" "$yaml_file" "$output_file" "TRACKPAD_"
    
    # Parse Power settings
    parse_section "power" "$yaml_file" "$output_file" "POWER_"
    
    # Parse Screen settings
    parse_section "screen" "$yaml_file" "$output_file" "SCREEN_"
    
    # Parse Menu Bar settings
    parse_section "menu_bar" "$yaml_file" "$output_file" "MENU_BAR_"
    
    # Parse Terminal settings
    parse_section "terminal" "$yaml_file" "$output_file" "TERMINAL_"
    
    # Parse Time Machine settings
    parse_section "time_machine" "$yaml_file" "$output_file" "TIME_MACHINE_"
    
    # Parse Hot Corners settings
    parse_section "hot_corners" "$yaml_file" "$output_file" "HOT_CORNERS_"
    
    # Parse Xcode settings
    parse_section "xcode" "$yaml_file" "$output_file" "XCODE_"
    
    echo "" >> "$output_file"
}

# Function to parse a specific section from YAML
parse_section() {
    local section="$1"
    local yaml_file="$2" 
    local output_file="$3"
    local prefix="$4"
    
    # Extract the section from YAML
    local in_section=false
    local section_found=false
    
    while IFS= read -r line; do
        # Check if we're entering the section
        if [[ "$line" =~ ^[[:space:]]*${section}:[[:space:]]*$ ]]; then
            in_section=true
            section_found=true
            continue
        fi
        
        # Check if we're leaving the section (new section at same level)
        if [[ "$in_section" == true ]] && [[ "$line" =~ ^[[:space:]]*[a-zA-Z_]+:[[:space:]]*$ ]] && [[ ! "$line" =~ ^[[:space:]]{6,} ]]; then
            break
        fi
        
        # Parse settings within the section
        if [[ "$in_section" == true ]] && [[ "$line" =~ ^[[:space:]]+([a-zA-Z_]+):[[:space:]]*(.+)$ ]]; then
            local key="${BASH_REMATCH[1]}"
            local value="${BASH_REMATCH[2]}"
            
            # Clean up the value (remove quotes, comments)
            value=$(echo "$value" | sed 's/#.*$//' | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//' | sed 's/^"//' | sed 's/"$//')
            
            # Convert key to uppercase and replace underscores
            local var_name="${prefix}$(echo "$key" | tr '[:lower:]' '[:upper:]')"
            
            # Handle arrays (for languages)
            if [[ "$value" =~ ^\[.*\]$ ]]; then
                # Remove brackets and quotes, convert to space-separated
                value=$(echo "$value" | sed 's/^\[//' | sed 's/\]$//' | sed 's/"//g' | sed 's/,/ /g')
            fi
            
            echo "${var_name}=\"${value}\"" >> "$output_file"
        fi
    done < "$yaml_file"
    
    if [[ "$section_found" == false ]]; then
        echo "# Section '$section' not found in YAML" >> "$output_file"
    fi
}

# Export the function so it can be used by other scripts
export -f parse_user_defaults
export -f parse_section