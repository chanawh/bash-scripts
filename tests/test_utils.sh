#!/bin/bash

# Test utilities for bash-scripts repository
# Provides basic testing framework for bash scripts

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Function to print test results
print_test_result() {
    local test_name="$1"
    local result="$2"
    local message="$3"
    
    TESTS_RUN=$((TESTS_RUN + 1))
    
    if [ "$result" = "PASS" ]; then
        echo -e "${GREEN}✓ PASS${NC}: $test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗ FAIL${NC}: $test_name"
        if [ -n "$message" ]; then
            echo -e "  ${YELLOW}Reason:${NC} $message"
        fi
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# Function to test script syntax
test_syntax() {
    local script_path="$1"
    local script_name=$(basename "$script_path")
    
    if bash -n "$script_path" 2>/dev/null; then
        print_test_result "Syntax check for $script_name" "PASS"
        return 0
    else
        local error_msg=$(bash -n "$script_path" 2>&1)
        print_test_result "Syntax check for $script_name" "FAIL" "$error_msg"
        return 1
    fi
}

# Function to test if script exists and is executable
test_executable() {
    local script_path="$1"
    local script_name=$(basename "$script_path")
    
    if [ -f "$script_path" ] && [ -x "$script_path" ]; then
        print_test_result "Executable check for $script_name" "PASS"
        return 0
    else
        print_test_result "Executable check for $script_name" "FAIL" "File not found or not executable"
        return 1
    fi
}

# Function to test if script has proper shebang
test_shebang() {
    local script_path="$1"
    local script_name=$(basename "$script_path")
    
    if head -n1 "$script_path" | grep -E '^#!/bin/(bash|sh)' >/dev/null; then
        print_test_result "Shebang check for $script_name" "PASS"
        return 0
    else
        print_test_result "Shebang check for $script_name" "FAIL" "Missing or invalid shebang"
        return 1
    fi
}

# Function to print final test summary
print_test_summary() {
    echo
    echo -e "${BLUE}=========================="
    echo -e "Test Summary"
    echo -e "==========================${NC}"
    echo -e "Tests run: $TESTS_RUN"
    echo -e "${GREEN}Passed: $TESTS_PASSED${NC}"
    
    if [ $TESTS_FAILED -gt 0 ]; then
        echo -e "${RED}Failed: $TESTS_FAILED${NC}"
        return 1
    else
        echo -e "${GREEN}All tests passed!${NC}"
        return 0
    fi
}

# Function to run a command safely and capture output
run_safe_test() {
    local test_name="$1"
    local command="$2"
    
    if eval "$command" >/dev/null 2>&1; then
        print_test_result "$test_name" "PASS"
        return 0
    else
        print_test_result "$test_name" "FAIL" "Command failed: $command"
        return 1
    fi
}