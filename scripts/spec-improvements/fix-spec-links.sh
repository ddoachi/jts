#!/bin/bash

# fix-spec-links.sh - Fix spec file links to use correct paths and titles

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

# Function to get spec file title
get_spec_title() {
    local spec_file="$1"
    local hierarchy="$2"
    
    if [[ -f "$spec_file" ]]; then
        # Extract title from YAML frontmatter
        local title=$(grep "^title:" "$spec_file" | head -1 | sed 's/^title:[[:space:]]*//' | sed 's/^"//' | sed 's/"$//')
        if [[ -n "$title" ]]; then
            echo "[$hierarchy] $title"
            return 0
        fi
    fi
    
    # Fallback to hierarchy only
    echo "[$hierarchy] spec"
    return 1
}

# Function to fix spec links in a file
fix_spec_links() {
    local spec_file="$1"
    local temp_file=$(mktemp)
    local modified=false
    local spec_dir=$(dirname "$spec_file")
    
    [[ "$VERBOSE" == "true" ]] && log_info "Processing: $spec_file"
    
    # Process the file line by line
    while IFS= read -r line; do
        local new_line="$line"
        
        # Check for spec file links - pattern: [anything](../HIERARCHY/HIERARCHY.spec.md)
        if echo "$line" | grep -q "\](\.\.\/[^/]*\/[^/]*\.spec\.md)" ; then
            # Extract the hierarchy from the filename part of the path
            local full_hierarchy=$(echo "$line" | sed -n 's/.*](\.\.\/[^/]*\/\([^/]*\)\.spec\.md).*/\1/p')
            
            if [[ -n "$full_hierarchy" ]]; then
                # Extract the last part for directory (T05 from E01-F01-T05, F01 from E01-F01)
                local dir_part=""
                if [[ "$full_hierarchy" =~ -([^-]+)$ ]]; then
                    dir_part="${BASH_REMATCH[1]}"
                else
                    # For single level like E01
                    dir_part="$full_hierarchy"
                fi
                
                # Calculate correct path and target file
                local correct_path="../$dir_part/$full_hierarchy.spec.md"
                local target_spec_file="$spec_dir/$correct_path"
                
                # Get the title for the spec
                local spec_title=$(get_spec_title "$target_spec_file" "$full_hierarchy")
                
                # Find the old link text to replace
                local old_link_text=$(echo "$line" | sed -n 's/.*\[\([^]]*\)\](\.\.\/[^/]*\/[^/]*\.spec\.md).*/\1/p')
                local old_path=$(echo "$line" | sed -n 's/.*\[\([^]]*\)\](\([^)]*\)).*/\2/p')
                
                # Replace the entire link with new format
                new_line=$(echo "$line" | sed "s|\[$old_link_text\]($old_path)|[$spec_title]($correct_path)|")
                
                if [[ "$new_line" != "$line" ]]; then
                    modified=true
                    [[ "$VERBOSE" == "true" ]] && log_info "  Fixed spec link: $full_hierarchy -> [$spec_title]($correct_path)"
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
    log_info "Starting spec link fixes..."
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_warn "DRY RUN MODE - No files will be modified"
    fi
    
    local files_processed=0
    local files_updated=0
    
    # Find all spec files
    while IFS= read -r spec_file; do
        ((files_processed++))
        
        if fix_spec_links "$spec_file"; then
            ((files_updated++))
        fi
    done < <(find specs -name "*.spec.md" -type f | sort)
    
    # Summary
    echo ""
    log_info "=== Spec Link Fix Summary ==="
    log_info "Files processed: $files_processed"
    log_info "Files updated: $files_updated"
    
    if [[ "$files_updated" -gt 0 ]] && [[ "$DRY_RUN" != "true" ]]; then
        # Stage and commit changes
        find specs -name "*.spec.md" -type f -exec git add {} \;
        git commit -m "fix(specs): Fix spec file links with correct paths and titles

- Fixed paths from ../HIERARCHY/HIERARCHY.spec.md to ../PART/HIERARCHY.spec.md  
- Updated link text to show [HIERARCHY] TITLE format
- Ensured all spec links use correct directory structure
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
            echo "Fix spec file links with correct paths and titles."
            echo ""
            echo "Options:"
            echo "  --dry-run    Show what would be changed without making changes"
            echo "  --verbose    Show verbose output"
            echo "  --help       Show this help message"
            echo ""
            echo "Fixes:"
            echo "  - Correct directory paths (../T05/ instead of ../E01-F01-T05/)"  
            echo "  - Show titles as [HIERARCHY] TITLE format"
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