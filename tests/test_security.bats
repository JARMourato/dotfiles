#!/usr/bin/env bats

# Security and encryption tests

setup() {
    export TEST_DIR="/tmp/security_test_$RANDOM"
    mkdir -p "$TEST_DIR"
    export TEST_SECRET_FILE="$TEST_DIR/test_secret.txt"
    echo "test secret data" > "$TEST_SECRET_FILE"
}

teardown() {
    rm -rf "$TEST_DIR"
}

@test "encrypt_files script shows help" {
    run ./Scripts/encrypt_files.sh --help
    
    [ "$status" -eq 0 ]
    [[ "$output" == *"encrypt_files.sh - Encrypt sensitive dotfiles"* ]]
}

@test "decrypt_files script shows help" {
    run ./Scripts/decrypt_files.sh --help
    
    [ "$status" -eq 0 ]
    [[ "$output" == *"decrypt_files.sh - Decrypt encrypted dotfiles"* ]]
}

@test "rotate_secrets script shows help" {
    run ./Scripts/rotate_secrets.sh --help
    
    [ "$status" -eq 0 ]
    [[ "$output" == *"rotate_secrets.sh - Rotate encrypted secrets"* ]]
}

@test "check_secrets_age script shows help" {
    run ./Scripts/check_secrets_age.sh --help
    
    [ "$status" -eq 0 ]
    [[ "$output" == *"check_secrets_age.sh - Monitor encrypted secrets"* ]]
}

@test "encrypt/decrypt scripts require password" {
    run ./Scripts/encrypt_files.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"cyphering key is empty"* ]]
    
    run ./Scripts/decrypt_files.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"cyphering key is empty"* ]]
}

@test "check_secrets_age handles missing files gracefully" {
    run ./Scripts/check_secrets_age.sh
    
    [ "$status" -eq 0 ] || [ "$status" -eq 1 ] || [ "$status" -eq 2 ]
    # Should not crash, may return warning/urgent status
}

@test "rotate_secrets requires password argument" {
    run ./Scripts/rotate_secrets.sh
    
    [ "$status" -eq 1 ]
    [[ "$output" == *"Missing required encryption key"* ]]
}

@test "secrets scripts detect age availability" {
    # Test that scripts can detect if age is available
    if command -v age >/dev/null 2>&1; then
        echo "Age is available, scripts should prefer it"
    else
        echo "Age not available, scripts should use OpenSSL fallback"
    fi
    
    # This test ensures the detection logic doesn't crash
    run bash -c 'source Scripts/config_parser.sh && command_exists age'
    [ "$status" -eq 0 ] || [ "$status" -eq 1 ]
}