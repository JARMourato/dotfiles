#!/usr/bin/env bats

# macOS-specific integration tests

@test "macOS system detection works" {
    run sw_vers -productVersion
    [ "$status" -eq 0 ]
    [[ "$output" =~ ^[0-9]+\.[0-9]+ ]]
    
    run uname -s
    [ "$status" -eq 0 ]
    [ "$output" = "Darwin" ]
}

@test "Homebrew architecture detection" {
    arch=$(uname -m)
    
    if [ "$arch" = "arm64" ]; then
        echo "Testing Apple Silicon paths"
        # On Apple Silicon, Homebrew should be in /opt/homebrew
        if command -v brew >/dev/null 2>&1; then
            run which brew
            [[ "$output" == "/opt/homebrew/bin/brew" ]] || echo "Homebrew not in expected Apple Silicon location"
        fi
    else
        echo "Testing Intel paths"
        # On Intel, Homebrew should be in /usr/local
        if command -v brew >/dev/null 2>&1; then
            run which brew
            [[ "$output" == "/usr/local/bin/brew" ]] || echo "Homebrew not in expected Intel location"
        fi
    fi
}

@test "macOS commands used in scripts exist" {
    # Test macOS-specific commands our scripts rely on
    run which defaults
    [ "$status" -eq 0 ]
    
    run which system_profiler
    [ "$status" -eq 0 ]
    
    run which stat
    [ "$status" -eq 0 ]
    
    run which sed
    [ "$status" -eq 0 ]
    
    run which find
    [ "$status" -eq 0 ]
}

@test "Xcode Command Line Tools detection" {
    # Test xcode-select behavior
    run xcode-select --print-path
    
    # Either installed (status 0) or not installed (status 2)
    [ "$status" -eq 0 ] || [ "$status" -eq 2 ]
    
    if [ "$status" -eq 0 ]; then
        echo "Xcode Command Line Tools are installed"
        [[ "$output" == "/Applications/Xcode.app/Contents/Developer" ]] || \
        [[ "$output" == "/Library/Developer/CommandLineTools" ]]
    else
        echo "Xcode Command Line Tools are not installed"
    fi
}

@test "mas command availability" {
    # Test if mas (Mac App Store CLI) is available
    if command -v mas >/dev/null 2>&1; then
        run mas version
        [ "$status" -eq 0 ]
        echo "mas CLI is available"
    else
        echo "mas CLI not installed (this is OK for testing)"
    fi
}

@test "macOS stat command format" {
    # Test that we use the correct stat format for macOS
    temp_file="/tmp/test_stat_$$"
    touch "$temp_file"
    
    # macOS stat uses -f, Linux uses -c
    run stat -f %Sm "$temp_file"
    [ "$status" -eq 0 ]
    
    # Cleanup
    rm -f "$temp_file"
}

@test "macOS sed command behavior" {
    # Test macOS sed requirements (needs empty string for -i)
    temp_file="/tmp/test_sed_$$"
    echo "test line" > "$temp_file"
    
    # macOS sed requires empty string after -i
    run sed -i '' 's/test/TEST/' "$temp_file"
    [ "$status" -eq 0 ]
    
    # Verify change
    run cat "$temp_file"
    [[ "$output" == "TEST line" ]]
    
    # Cleanup
    rm -f "$temp_file"
}

@test "Terminal detection and setup" {
    # Test that we can detect terminal environment
    [ -n "$TERM" ]
    
    # Test shell detection
    echo "Current shell: $SHELL"
    [[ "$SHELL" == *"zsh"* ]] || [[ "$SHELL" == *"bash"* ]]
}

@test "Directory structure assumptions" {
    # Test basic macOS directory structure our scripts assume
    [ -d /Applications ]
    [ -d /System ]
    [ -d /usr/local ] || [ -d /opt/homebrew ]
    [ -d "$HOME" ]
    [ -d "$HOME/Desktop" ] || echo "Desktop folder not found (OK in CI)"
}

@test "Network connectivity for downloads" {
    # Test basic network connectivity for download operations
    run ping -c 1 github.com
    [ "$status" -eq 0 ] || echo "No network connectivity (OK in some CI environments)"
    
    run ping -c 1 raw.githubusercontent.com
    [ "$status" -eq 0 ] || echo "No GitHub raw connectivity (OK in some CI environments)"
}