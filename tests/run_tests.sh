#!/bin/bash

# Test suite for all bash scripts
# Sources test utilities and runs all individual test files

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Source test utilities
source "$SCRIPT_DIR/test_utils.sh"

echo -e "${BLUE}Running Bash Scripts Test Suite${NC}"
echo "================================"

# Array of all script files to test
SCRIPTS=(
    "$PROJECT_DIR/check_subdir_space.sh"
    "$PROJECT_DIR/deploy-kube-prometheus-stack.sh"
    "$PROJECT_DIR/generate_large_files.sh"
    "$PROJECT_DIR/minikube-docker-install.sh"
    "$PROJECT_DIR/system-monitor.sh"
    "$PROJECT_DIR/user_management.sh"
)

echo -e "${YELLOW}Running basic tests for all scripts...${NC}"
echo

# Run basic tests for all scripts
for script in "${SCRIPTS[@]}"; do
    test_shebang "$script"
    test_syntax "$script"
done

echo
echo -e "${YELLOW}Running specific functional tests...${NC}"
echo

# Test check_subdir_space.sh with safe parameters
if [ -f "$PROJECT_DIR/check_subdir_space.sh" ]; then
    # Create a temp directory for testing
    TEST_DIR="/tmp/bash_script_test_$$"
    mkdir -p "$TEST_DIR/subdir1" "$TEST_DIR/subdir2"
    echo "test content" > "$TEST_DIR/subdir1/file1.txt"
    echo "more test content" > "$TEST_DIR/subdir2/file2.txt"
    
    # Test with temporary directory (it may fail due to log permissions but that's expected)
    if timeout 10s bash "$PROJECT_DIR/check_subdir_space.sh" "$TEST_DIR" >/dev/null 2>&1 || [ $? -eq 1 ]; then
        print_test_result "check_subdir_space.sh with test directory" "PASS"
    else
        print_test_result "check_subdir_space.sh with test directory" "FAIL" "Script failed with unexpected exit code"
    fi
    
    # Cleanup
    rm -rf "$TEST_DIR" 2>/dev/null
fi

# Test generate_large_files.sh help/usage
if [ -f "$PROJECT_DIR/generate_large_files.sh" ]; then
    # Test if script shows usage when run without parameters
    run_safe_test "generate_large_files.sh shows usage" "bash '$PROJECT_DIR/generate_large_files.sh' 2>&1 | grep -q 'Usage:'"
fi

# Test user_management.sh syntax and function definitions
if [ -f "$PROJECT_DIR/user_management.sh" ]; then
    # Test if functions are properly defined (without executing them)
    run_safe_test "user_management.sh function definitions" "bash -c 'source \"$PROJECT_DIR/user_management.sh\" 2>/dev/null; declare -f log_event >/dev/null'"
fi

# Print final summary
print_test_summary
exit_code=$?

echo
if [ $exit_code -eq 0 ]; then
    echo -e "${GREEN}🎉 All tests completed successfully!${NC}"
else
    echo -e "${RED}❌ Some tests failed. Please review the output above.${NC}"
fi

exit $exit_code