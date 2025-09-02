#!/bin/bash

# fix-relative-paths.sh - Fix incorrect relative paths in spec files

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script configuration
DRY_RUN=${DRY_RUN:-false}
VERBOSE=${VERBOSE:-false}

# Function to print colored output
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_success() {
    echo -e "${BLUE}[SUCCESS]${NC} $1"
}

# Function to calculate correct relative path
calculate_relative_path() {
    local from_file="$1"
    local to_file="$2"
    
    # Get the directory of the from_file
    local from_dir=$(dirname "$from_file")
    
    # Calculate relative path using realpath
    local relative_path=$(realpath --relative-to="$from_dir" "$to_file" 2>/dev/null)
    
    echo "$relative_path"
}

# Function to fix relative paths in a spec file
fix_relative_paths() {
    local spec_file="$1"
    local temp_file=$(mktemp)
    local modified=false
    
    [[ "$VERBOSE" == "true" ]] && log_info "Processing: $spec_file"
    
    # Process the file line by line
    while IFS= read -r line; do
        local new_line="$line"
        
        # Check for file links with relative paths starting with ../
        if echo "$line" | grep -q "\[.*\](\.\..*)" ; then
            # Extract link text and path using sed
            local link_text=$(echo "$line" | sed -n 's/.*\[\([^]]*\)\](.*/\1/p' | head -1)
            local old_path=$(echo "$line" | sed -n 's/.*\[[^]]*\](\([^)]*\)).*/\1/p' | head -1)
            
            # Only process if we successfully extracted both parts
            if [[ -n "$link_text" ]] && [[ -n "$old_path" ]] && [[ "$old_path" == ../* ]]; then
                # Extract the target file path (remove leading ../ patterns)
                local target_file=$(echo "$old_path" | sed 's|^\(\.\./\)*||')
                
                # Calculate correct relative path
                local correct_path=$(calculate_relative_path "$spec_file" "$target_file")
                
                if [[ "$correct_path" != "$old_path" ]] && [[ -n "$correct_path" ]]; then
                    new_line=$(echo "$line" | sed "s|\[$link_text\]($old_path)|\[$link_text\]($correct_path)|g")
                    modified=true
                    [[ "$VERBOSE" == "true" ]] && log_info "  Fixed path: $old_path -> $correct_path"
                fi
            fi
        fi
        
        echo "$new_line" >> "$temp_file"
    done < "$spec_file"
    
    # Apply changes if any were made
    if [[ "$modified" == "true" ]]; then
        if [[ "$DRY_RUN" == "true" ]]; then
            echo "Would update: $spec_file"
            rm "$temp_file"
        else
            mv "$temp_file" "$spec_file"
            log_success "Updated: $spec_file"
        fi
        return 0
    else
        rm "$temp_file"
        [[ "$VERBOSE" == "true" ]] && log_info "  No changes needed"
        return 1
    fi
}

# Main function
main() {
    log_info "Starting relative path fixes..."
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_warn "DRY RUN MODE - No files will be modified"
    fi
    
    local files_processed=0
    local files_updated=0
    
    # Find all spec files
    while IFS= read -r spec_file; do
        ((files_processed++))
        
        if fix_relative_paths "$spec_file"; then
            ((files_updated++))
        fi
    done < <(find specs -name "*.spec.md" -type f | sort)
    
    # Summary
    echo ""
    log_info "=== Relative Path Fix Summary ==="
    log_info "Files processed: $files_processed"
    log_info "Files updated: $files_updated"
    
    if [[ "$files_updated" -gt 0 ]] && [[ "$DRY_RUN" != "true" ]]; then
        # Stage and commit changes
        find specs -name "*.spec.md" -type f -exec git add {} \;
        git commit -m "fix(specs): Fix incorrect relative file paths

- Corrected relative paths to use proper number of ../
- Fixed paths that were missing directory levels  
- Ensured all file links point to correct locations
- Updated $files_updated spec files

🤖 Generated with [Claude Code](https://claude.ai/code)

Co-Authored-By: Claude <noreply@anthropic.com>"
        log_success "Changes committed successfully"
    fi
    
    if [[ "$DRY_RUN" == "true" ]]; then
        echo ""
        log_warn "This was a dry run. To apply changes, run:"
        echo "  DRY_RUN=false $0"
    fi
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --verbose)
            VERBOSE=true
            shift
            ;;
        --help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Fix incorrect relative paths in spec files."
            echo ""
            echo "Options:"
            echo "  --dry-run    Show what would be changed without making changes"
            echo "  --verbose    Show verbose output"
            echo "  --help       Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Run main function
main