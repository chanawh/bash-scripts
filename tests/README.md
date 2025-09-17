# Test Framework for Bash Scripts

This directory contains a simple testing framework for validating the bash scripts in this repository.

## Files

- `test_utils.sh` - Common utilities and functions for testing bash scripts
- `run_tests.sh` - Main test runner that executes all tests

## Running Tests

To run all tests:

```bash
./tests/run_tests.sh
```

Or from the project root:

```bash
bash tests/run_tests.sh
```

## Test Types

The framework includes several types of tests:

### Basic Tests (for all scripts)
- **Shebang check**: Verifies each script has a proper `#!/bin/bash` or `#!/bin/sh` shebang
- **Syntax check**: Uses `bash -n` to validate script syntax without execution

### Functional Tests
- **check_subdir_space.sh**: Tests with a temporary directory structure
- **generate_large_files.sh**: Validates usage message display
- **user_management.sh**: Checks function definitions are properly loaded

## Test Output

The test runner provides colored output:
- ✅ Green checkmarks for passing tests
- ❌ Red X marks for failing tests
- Summary statistics at the end

## Adding New Tests

To add tests for a new script:

1. Add the script path to the `SCRIPTS` array in `run_tests.sh`
2. Add any specific functional tests in the "Running specific functional tests" section
3. Use the utility functions from `test_utils.sh`:
   - `test_syntax(script_path)`
   - `test_shebang(script_path)`
   - `run_safe_test(test_name, command)`
   - `print_test_result(test_name, result, message)`

## Safety

Tests are designed to be safe and non-destructive:
- Use temporary directories and files when needed
- Don't require root privileges
- Handle permission errors gracefully
- Clean up test artifacts automatically