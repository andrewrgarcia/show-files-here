#!/bin/bash

# Function to output the content of a file
output_file_content() {
    local file="$1"
    echo "===== Content of $file ====="
    cat "$file"
    echo "============================"
}

# Default directories to ignore
ignore_dirs=("venv" "build" "__pycache__")

# Parse arguments
extensions=()
additional_ignore_dirs=()
head_count=0
tail_count=0
while [[ $# -gt 0 ]]; do
    case "$1" in
        --ignore)
            shift
            while [[ $# -gt 0 && $1 != --* ]]; do
                additional_ignore_dirs+=("$1")
                shift
            done
            ;;
        --head=*)
            head_count="${1#*=}"
            shift
            ;;
        --tail=*)
            tail_count="${1#*=}"
            shift
            ;;
        *)
            extensions+=("$1")
            shift
            ;;
    esac
done

# Merge default ignore directories with additional ones
ignore_dirs+=("${additional_ignore_dirs[@]}")

# Convert ignore directories to find -path arguments
ignore_find_args=()
for dir in "${ignore_dirs[@]}"; do
    ignore_find_args+=(-path "./$dir" -prune -o)
done

# Set default extension if none provided
if [ ${#extensions[@]} -eq 0 ]; then
    extensions=("py")
fi

# Create a temporary file to hold the output
temp_file=$(mktemp)

# Print the directory structure index of all files with the given extensions
{
    echo "Index of files with the extensions: ${extensions[*]} in the directory structure (excluding ${ignore_dirs[*]}):"
    for ext in "${extensions[@]}"; do
        find . "${ignore_find_args[@]}" -type f -name "*.$ext" -print
    done

    # Add a separator between the index and the file contents
    echo "==============================================="
    echo

    # Export the function so it can be used with find
    export -f output_file_content

    # Find all files with the given extensions recursively and output their content with headers
    for ext in "${extensions[@]}"; do
        find . "${ignore_find_args[@]}" -type f -name "*.$ext" -exec bash -c 'output_file_content "$0"' {} \;
    done
} > "$temp_file"

# Apply head or tail to the full output if specified
if [ "$head_count" -gt 0 ]; then
    head -n "$head_count" "$temp_file"
elif [ "$tail_count" -gt 0 ]; then
    tail -n "$tail_count" "$temp_file"
else
    cat "$temp_file"
fi

# Remove the temporary file
rm "$temp_file"
