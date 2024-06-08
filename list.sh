#!/bin/bash

# Loop through each subdirectory
for dir in */ ; do
    # Check if it's a directory
    if [ -d "$dir" ]; then
        echo "Processing directory: $dir"
        
        # Change to the directory
        cd "$dir"
        
        # Run terraform state list
        terraform state list
        
        # Change back to the parent directory
        cd ..
    fi
done