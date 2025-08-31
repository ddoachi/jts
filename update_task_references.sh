#!/bin/bash

# Script to update references to markdown links in task spec files
# This will update parent, dependencies, blocks, related, and context_file references

E01_PATH="/home/joohan/dev/project-jts/worktrees/fix-reference-link/specs/E01"

echo "Starting task reference updates..."

# Find all task spec.md files
find "$E01_PATH" -path "*/F*/T*/spec.md" | while read -r file; do
    echo "Processing: $file"
    
    # Get the feature and task from the path
    feature=$(echo "$file" | sed -E 's|.*/(F[0-9]+)/.*|\1|')
    task=$(echo "$file" | sed -E 's|.*/T([0-9]+)/spec\.md|\1|')
    task_full=$(echo "$file" | sed -E 's|.*/(T[0-9]+)/spec\.md|\1|')
    
    # Create a temporary file
    temp_file=$(mktemp)
    
    # Process the file line by line
    while IFS= read -r line; do
        # Update parent references
        if [[ $line =~ ^parent:\ ([FET][0-9]+)$ ]]; then
            if [[ ${BASH_REMATCH[1]} =~ ^F[0-9]+$ ]]; then
                echo "parent: [${BASH_REMATCH[1]}](../spec.md)"
            else
                echo "$line"
            fi
        # Update dependencies section
        elif [[ $line == "dependencies:" ]]; then
            echo "$line"
            # Read the following lines until we hit a different section
            while IFS= read -r dep_line; do
                if [[ $dep_line =~ ^[[:space:]]*-[[:space:]]+([FET][0-9]+)$ ]]; then
                    ref=${BASH_REMATCH[1]}
                    if [[ $ref =~ ^T[0-9]+$ ]]; then
                        # Task to task reference
                        echo "  - [$ref](../$ref/spec.md)"
                    elif [[ $ref =~ ^F[0-9]+$ ]]; then
                        # Task to feature reference  
                        echo "  - [$ref](../../$ref/spec.md)"
                    elif [[ $ref =~ ^E[0-9]+$ ]]; then
                        # Task to epic reference
                        echo "  - [$ref](../../../$ref/spec.md)"
                    else
                        echo "$dep_line"
                    fi
                elif [[ $dep_line =~ ^[a-zA-Z_]+: ]]; then
                    # Hit the next section, output this line and break
                    echo "$dep_line"
                    break
                elif [[ -z "$dep_line" || $dep_line =~ ^[[:space:]]*$ ]]; then
                    # Empty line
                    echo "$dep_line"
                else
                    # Other dependency format, keep as is
                    echo "$dep_line"
                fi
            done
        # Update blocks section
        elif [[ $line == "blocks:" ]]; then
            echo "$line"
            while IFS= read -r block_line; do
                if [[ $block_line =~ ^[[:space:]]*-[[:space:]]+([FET][0-9]+)$ ]]; then
                    ref=${BASH_REMATCH[1]}
                    if [[ $ref =~ ^T[0-9]+$ ]]; then
                        # Task to task reference
                        echo "  - [$ref](../$ref/spec.md)"
                    elif [[ $ref =~ ^F[0-9]+$ ]]; then
                        # Task to feature reference
                        echo "  - [$ref](../../$ref/spec.md)"
                    elif [[ $ref =~ ^E[0-9]+$ ]]; then
                        # Task to epic reference
                        echo "  - [$ref](../../../$ref/spec.md)"
                    else
                        echo "$block_line"
                    fi
                elif [[ $block_line =~ ^[a-zA-Z_]+: ]]; then
                    echo "$block_line"
                    break
                elif [[ -z "$block_line" || $block_line =~ ^[[:space:]]*$ ]]; then
                    echo "$block_line"
                else
                    echo "$block_line"
                fi
            done
        # Update related section  
        elif [[ $line == "related:" ]]; then
            echo "$line"
            while IFS= read -r rel_line; do
                if [[ $rel_line =~ ^[[:space:]]*-[[:space:]]+([FET][0-9]+)$ ]]; then
                    ref=${BASH_REMATCH[1]}
                    if [[ $ref =~ ^T[0-9]+$ ]]; then
                        # Task to task reference
                        echo "  - [$ref](../$ref/spec.md)"
                    elif [[ $ref =~ ^F[0-9]+$ ]]; then
                        # Task to feature reference
                        echo "  - [$ref](../../$ref/spec.md)"
                    elif [[ $ref =~ ^E[0-9]+$ ]]; then
                        # Task to epic reference
                        echo "  - [$ref](../../../$ref/spec.md)"
                    else
                        echo "$rel_line"
                    fi
                elif [[ $rel_line =~ ^[a-zA-Z_]+: ]]; then
                    echo "$rel_line"
                    break
                elif [[ -z "$rel_line" || $rel_line =~ ^[[:space:]]*$ ]]; then
                    echo "$rel_line"
                else
                    echo "$rel_line"
                fi
            done
        # Update context_file references
        elif [[ $line =~ ^context_file:[[:space:]]+(.+)$ ]]; then
            context_file="${BASH_REMATCH[1]}"
            # Remove quotes if present
            context_file=$(echo "$context_file" | sed "s/['\"]//g")
            if [[ $context_file != "" && $context_file != "null" ]]; then
                echo "context_file: [$context_file](./$context_file)"
            else
                echo "$line"
            fi
        else
            echo "$line"
        fi
    done < "$file" > "$temp_file"
    
    # Replace the original file
    mv "$temp_file" "$file"
    echo "Updated: $file"
done

echo "All task reference updates completed!"