#!/usr/bin/env bats

# Unit tests for bootstrap.sh

@test "bootstrap script shows help" {
    run ./bootstrap.sh --help
    
    [ "$status" -eq 0 ]
    [[ "$output" == *"bootstrap.sh - Complete macOS dotfiles setup"* ]]
}

@test "bootstrap script requires encryption password" {
    run ./bootstrap.sh
    
    [ "$status" -eq 1 ]
    [[ "$output" == *"Encryption password missing"* ]]
}

@test "bootstrap script accepts all setup modes" {
    for mode in minimal dev-only work quick; do
        run ./bootstrap.sh "test_password" --$mode --dry-run
        [ "$status" -eq 0 ]
        [[ "$output" == *"DRY RUN MODE"* ]]
    done
}

@test "bootstrap script handles invalid arguments" {
    run ./bootstrap.sh "test_password" --invalid-mode
    
    [ "$status" -eq 1 ]
    [[ "$output" == *"Unknown option"* ]]
}

@test "bootstrap script dry-run doesn't make changes" {
    run ./bootstrap.sh "test_password" --minimal --dry-run
    
    [ "$status" -eq 0 ]
    [[ "$output" == *"DRY RUN MODE"* ]]
    
    # Verify no actual changes were made
    [ ! -d ~/.dotfiles ]
}

@test "bootstrap script validates snapshot names" {
    run ./bootstrap.sh "test_password" --snapshot "test_snap" --dry-run
    
    [ "$status" -eq 0 ]
    [[ "$output" == *"Would create snapshot: test_snap"* ]]
}

@test "bootstrap script handles config file parameter" {
    # Create temporary config
    echo "SKIP_XCODE=true" > test_bootstrap.config
    
    run ./bootstrap.sh "test_password" --config test_bootstrap.config --dry-run
    
    [ "$status" -eq 0 ]
    
    # Cleanup
    rm -f test_bootstrap.config
}

@test "bootstrap script shows configuration summary" {
    run ./bootstrap.sh "test_password" --minimal --dry-run
    
    [ "$status" -eq 0 ]
    [[ "$output" == *"Mode: minimal"* ]]
    [[ "$output" == *"Dry run: true"* ]]
}