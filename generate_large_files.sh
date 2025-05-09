#!/bin/bash

# Function to generate a file of a specified size using dd
generate_dd_file() {
    local file_name="$1"
    local size="$2"
    echo "Generating file $file_name with size $size using dd..."
    dd if=/dev/zero of="$file_name" bs=1M count="$size" status=progress
}

# Function to generate a file of a specified size using fallocate
generate_fallocate_file() {
    local file_name="$1"
    local size="$2"
    echo "Generating file $file_name with size $size using fallocate..."
    fallocate -l "$size" "$file_name"
}

# Function to generate a file of a specified size using truncate
generate_truncate_file() {
    local file_name="$1"
    local size="$2"
    echo "Generating file $file_name with size $size using truncate..."
    truncate -s "$size" "$file_name"
}

# Function to generate a file with random data using head and /dev/urandom
generate_random_file() {
    local file_name="$1"
    local size="$2"
    echo "Generating random file $file_name with size $size..."
    head -c "$size" </dev/urandom >"$file_name"
}

# Main script logic
usage() {
    echo "Usage: $0 [method] [size] [count]"
    echo "method: dd, fallocate, truncate, random"
    echo "size: size of the file (e.g., 1G, 10M)"
    echo "count: number of files to generate (default 1)"
    exit 1
}

# Ensure the correct number of arguments are passed
if [ $# -lt 2 ]; then
    usage
fi

METHOD="$1"
SIZE="$2"
COUNT="${3:-1}"  # Default to 1 if count is not specified

# Loop to create the requested number of files
for ((i=1; i<=COUNT; i++)); do
    FILE_NAME="testfile${i}_${SIZE}_${METHOD}"

    case "$METHOD" in
        dd)
            generate_dd_file "$FILE_NAME" "$SIZE"
            ;;
        fallocate)
            generate_fallocate_file "$FILE_NAME" "$SIZE"
            ;;
        truncate)
            generate_truncate_file "$FILE_NAME" "$SIZE"
            ;;
        random)
            generate_random_file "$FILE_NAME" "$SIZE"
            ;;
        *)
            echo "Invalid method: $METHOD"
            usage
            ;;
    esac
    echo "Created $FILE_NAME"
done

echo "File generation completed."
