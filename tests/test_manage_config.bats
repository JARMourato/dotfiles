#!/usr/bin/env bats

# Unit tests for manage_config.sh

setup() {
    export TEST_CONFIG_DIR="/tmp/test_config_$RANDOM"
    mkdir -p "$TEST_CONFIG_DIR"
    export TEST_CONFIG_FILE="$TEST_CONFIG_DIR/test.config"
    
    # Create a basic test config
    cat > "$TEST_CONFIG_FILE" << 'EOF'
SKIP_XCODE=false
HOMEBREW_FORMULAS="git age jq"
HOMEBREW_CASKS="google-chrome"
ENCRYPTION_METHOD="age"
EOF
}

teardown() {
    rm -rf "$TEST_CONFIG_DIR"
}

@test "manage_config shows help" {
    run ./Scripts/manage_config.sh --help
    
    [ "$status" -eq 0 ]
    [[ "$output" == *"manage_config.sh - Manage dotfiles configuration"* ]]
}

@test "manage_config validates existing config" {
    # Copy test config to expected location
    cp "$TEST_CONFIG_FILE" .dotfiles.config
    
    run ./Scripts/manage_config.sh validate
    
    [ "$status" -eq 0 ]
    [[ "$output" == *"Configuration is valid"* ]]
    
    # Cleanup
    rm -f .dotfiles.config
}

@test "manage_config creates templates" {
    for template in minimal developer work server; do
        run ./Scripts/manage_config.sh create-template $template
        [ "$status" -eq 0 ]
        [ -f "$template.config" ]
        rm -f "$template.config"
    done
}

@test "manage_config sets and gets values" {
    # Copy test config to expected location
    cp "$TEST_CONFIG_FILE" .dotfiles.config
    
    # Set a value
    run ./Scripts/manage_config.sh set TEST_VALUE "test123"
    [ "$status" -eq 0 ]
    
    # Get the value
    run ./Scripts/manage_config.sh get TEST_VALUE
    [ "$status" -eq 0 ]
    [[ "$output" == *"TEST_VALUE=test123"* ]]
    
    # Cleanup
    rm -f .dotfiles.config .dotfiles.config.backup.*
}

@test "manage_config handles missing config file" {
    run ./Scripts/manage_config.sh validate
    
    [ "$status" -eq 1 ]
    [[ "$output" == *"Configuration file not found"* ]]
}

@test "manage_config creates backup when setting values" {
    # Copy test config to expected location
    cp "$TEST_CONFIG_FILE" .dotfiles.config
    
    run ./Scripts/manage_config.sh set BACKUP_TEST "value"
    
    [ "$status" -eq 0 ]
    # Should create a backup file
    [ -f .dotfiles.config.backup.* ]
    
    # Cleanup
    rm -f .dotfiles.config .dotfiles.config.backup.*
}

@test "manage_config switch-mode works" {
    # Copy test config to expected location
    cp "$TEST_CONFIG_FILE" .dotfiles.config
    
    for mode in minimal dev-only work quick; do
        run ./Scripts/manage_config.sh switch-mode $mode
        [ "$status" -eq 0 ]
        [[ "$output" == *"$mode Mode Configuration"* ]]
    done
    
    # Cleanup
    rm -f .dotfiles.config
}