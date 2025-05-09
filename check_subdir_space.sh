#!/bin/bash

# Check space usage for each subdirectory and create a simple ASCII graph

# Directory to check (default is root)
BASE_DIR="${1:-/}"

# Log file location
LOG_FILE="/var/log/subdir_space_check.log"

# Function to log messages with timestamp
log_message() {
    local MESSAGE="$1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $MESSAGE" | tee -a $LOG_FILE
}

# Function to create an ASCII graph using '#' symbols based on space usage
generate_ascii_graph() {
    local size_in_bytes=$1
    local max_width=50 # Maximum width of the graph (number of '#' characters)

    # Calculate the number of '#' characters based on the size in bytes
    local graph_width=$((size_in_bytes / 1024 / 1024 / 10))  # Scale down the value

    # Limit the width to the maximum width
    if [ "$graph_width" -gt "$max_width" ]; then
        graph_width=$max_width
    fi

    # Generate the ASCII graph
    local graph=$(printf "%-${graph_width}s" "#" | tr ' ' '#')

    echo "$graph"
}

# Function to check space usage of each subdirectory and list files
check_subdir_space() {
    log_message "Starting to check space usage for subdirectories in $BASE_DIR"

    # List all subdirectories and get their sizes
    for subdir in "$BASE_DIR"/*/; do
        if [ -d "$subdir" ]; then
            # Get space usage of the subdirectory
            SUBDIR_SPACE=$(du -sh "$subdir" | awk '{print $1}')

            # Parse human-readable space into bytes
            local space_in_bytes
            if [[ "$SUBDIR_SPACE" =~ ([0-9]+)([KMGTP]) ]]; then
                local value="${BASH_REMATCH[1]}"
                local unit="${BASH_REMATCH[2]}"

                case "$unit" in
                    K) space_in_bytes=$((value * 1024)) ;;
                    M) space_in_bytes=$((value * 1024 * 1024)) ;;
                    G) space_in_bytes=$((value * 1024 * 1024 * 1024)) ;;
                    T) space_in_bytes=$((value * 1024 * 1024 * 1024 * 1024)) ;;
                    *) space_in_bytes=$value ;;
                esac
            else
                space_in_bytes=0
            fi

            # Log the space usage of the subdirectory
            log_message "Space usage for subdirectory: $subdir - $SUBDIR_SPACE"

            # Create the ASCII graph
            local graph=$(generate_ascii_graph $space_in_bytes)

            # Print the subdirectory name and its graph
            echo "$(basename "$subdir") $SUBDIR_SPACE"
            echo "$graph"
            echo
        fi
    done

    log_message "Completed checking space usage for subdirectories in $BASE_DIR"
}

# Run the subdirectory space check
check_subdir_space
