# Dotfiles Test Suite

This directory contains comprehensive tests for the macOS dotfiles setup system.

## Test Structure

### Unit Tests
- **`test_bootstrap.bats`** - Tests for the main bootstrap script
- **`test_manage_config.bats`** - Tests for configuration management
- **`test_security.bats`** - Tests for encryption and security features

### Integration Tests  
- **`test_macos_integration.bats`** - macOS-specific integration tests
- **`test_config_parser.bats`** - Configuration parsing functionality
- **`test_snapshot_rollback.bats`** - Snapshot and rollback system tests
- **`test_macos_compatibility.bats`** - macOS command compatibility tests

## Running Tests

### Prerequisites
```bash
# Install test framework
brew install bats-core

# Or use the Makefile
make install-deps
```

### Run All Tests
```bash
# Using bats directly
bats tests/*.bats

# Using Makefile
make test

# Run macOS-specific tests
make test-macos
```

### Run Specific Test Files
```bash
# Run bootstrap tests only
bats tests/test_bootstrap.bats

# Run security tests only  
bats tests/test_security.bats
```

### Run Individual Tests
```bash
# Run specific test by name
bats -f "bootstrap script shows help" tests/test_bootstrap.bats
```

## Test Categories

### 🔧 **Functionality Tests**
- Script argument parsing
- Configuration loading and validation
- Setup mode switching
- Help documentation

### 🍎 **macOS Compatibility Tests**
- Architecture detection (Apple Silicon vs Intel)
- macOS command availability and syntax
- Homebrew path detection
- System requirements validation

### 🔐 **Security Tests**
- Encryption/decryption workflow
- Password requirement validation
- Age vs OpenSSL fallback logic
- Secrets rotation functionality

### 📦 **Integration Tests**
- End-to-end workflow validation
- Configuration template creation
- Snapshot and rollback operations
- Error handling scenarios

## Test Environment

### CI/CD Integration
Tests automatically run on:
- **GitHub Actions**: Every push and PR
- **Multiple macOS versions**: macOS 12, 13, 14
- **Both architectures**: Intel and Apple Silicon
- **Weekly schedule**: Catch dependency changes

### Local Development
```bash
# Set up development environment
make setup-dev

# Run full CI suite locally
make ci

# Quick validation
make lint && make test
```

## Writing New Tests

### Test File Naming
- `test_<component>.bats` for unit tests
- `test_<system>_integration.bats` for integration tests

### Test Function Naming
```bash
@test "component does specific thing" {
    # Test implementation
}
```

### Common Patterns
```bash
# Test command success
run ./script.sh --help
[ "$status" -eq 0 ]

# Test output content
[[ "$output" == *"expected text"* ]]

# Test file existence
[ -f "expected_file" ]

# Test with cleanup
setup() {
    export TEST_DIR="/tmp/test_$$"
    mkdir -p "$TEST_DIR"
}

teardown() {
    rm -rf "$TEST_DIR"
}
```

## Debugging Tests

### Verbose Output
```bash
# Run with verbose output
bats -t tests/test_bootstrap.bats

# Show all output including successful tests
bats --verbose-run tests/test_bootstrap.bats
```

### Debug Individual Tests
```bash
# Add debug output to tests
@test "debug example" {
    echo "Debug: Testing something" >&3
    run ./script.sh
    echo "Debug: Exit status $status" >&3
    echo "Debug: Output: $output" >&3
    [ "$status" -eq 0 ]
}
```

## Test Coverage

Current test coverage includes:
- ✅ All script help documentation
- ✅ Configuration parsing and validation
- ✅ Setup mode functionality
- ✅ Error handling scenarios
- ✅ macOS compatibility checks
- ✅ Security feature validation
- ✅ Snapshot/rollback operations

## Continuous Integration

### GitHub Actions Workflows
- **Test Setup**: Tests all setup modes and configurations
- **Lint & Test**: Code quality and unit tests
- **Dependency Updates**: Automated package update testing

### Quality Gates
All PRs must pass:
- ShellCheck linting
- Unit test suite
- Integration tests
- macOS compatibility tests
- Configuration validation

## Performance Testing

### Benchmark Commands
```bash
# Time full setup process
time ./bootstrap.sh "password" --minimal --dry-run

# Time individual components
time ./Scripts/create_snapshot.sh "perf_test" --quick
```

### Memory Usage
```bash
# Monitor memory during tests
/usr/bin/time -l bats tests/*.bats
```

This comprehensive test suite ensures the dotfiles system works reliably across different macOS environments and configurations.