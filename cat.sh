#!/bin/bash

# Script to recursively print content of all files in current directory and subdirectories
# Usage: ./recursive_cat.sh

# Print header with script information
echo "====================================================================="
echo "  RECURSIVE FILE CONTENT PRINTER"
echo "  Printing content of all files in current directory and subdirectories"
echo "  Current directory: $(pwd)"
echo "====================================================================="
echo ""

# Function to print file content with header
print_file_content() {
    local file="$1"
    
    # Skip if it's a directory, binary file, or not readable
    if [ -d "$file" ] || ! [ -r "$file" ] || file "$file" | grep -q "binary"; then
        return
    fi
    
    # Get file size
    local size=$(du -h "$file" | cut -f1)
    
    echo "====================================================================="
    echo "FILE: $file"
    echo "SIZE: $size"
    echo "====================================================================="
    echo ""
    cat "$file"
    echo ""
    echo "====================================================================="
    echo "END OF FILE: $file"
    echo "====================================================================="
    echo ""
}

# Find all files recursively and print their content
find . -type f | sort | while read -r file; do
    print_file_content "$file"
done

echo "Finished printing all file contents."
