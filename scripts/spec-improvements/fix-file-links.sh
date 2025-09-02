#!/bin/bash

# fix-file-links.sh - Fix file link formats in spec files
# Purpose: 
# - For markdown files: use [TITLE](relative path) format
# - For non-markdown files: use [File Path](relative path) format

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

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_success() {
    echo -e "${BLUE}[SUCCESS]${NC} $1"
}

# Function to get markdown title from file
get_markdown_title() {
    local file_path="$1"
    
    if [[ -f "$file_path" ]] && [[ "$file_path" == *.md ]]; then
        # Extract first # title line
        local title=$(head -20 "$file_path" | grep -m1 '^#[^#]' | sed 's/^#[[:space:]]*//' | sed 's/[[:space:]]*$//')
        if [[ -n "$title" ]]; then
            echo "$title"
            return 0
        fi
    fi
    return 1
}

# Function to get file path relative to project root
get_project_relative_path() {
    local file_path="$1"
    # Remove leading ./ and ../../ patterns, get clean path
    echo "$file_path" | sed 's|^\(\.\./\)*||' | sed 's|^./||'
}

# Function to fix file links in a spec file
fix_file_links() {
    local spec_file="$1"
    local temp_file=$(mktemp)
    local modified=false
    
    [[ "$VERBOSE" == "true" ]] && log_info "Processing: $spec_file"
    
    # Process the file line by line
    while IFS= read -r line; do
        if echo "$line" | grep -q "^-[[:space:]]*\[.*\](.*)[[:space:]]*$"; then
            # Extract link text and path using sed
            local link_text=$(echo "$line" | sed -n 's/^-[[:space:]]*\[\([^]]*\)\](.*/\1/p')
            local link_path=$(echo "$line" | sed -n 's/^-[[:space:]]*\[[^]]*\](\([^)]*\)).*/\1/p')
            
            # Convert relative path to absolute path for checking
            local spec_dir=$(dirname "$spec_file")
            local absolute_path
            if [[ "$link_path" == /* ]]; then
                absolute_path="$link_path"
            else
                # Resolve relative to spec file directory using pushd/popd
                pushd "$spec_dir" >/dev/null
                absolute_path=$(realpath -m "$link_path" 2>/dev/null)
                popd >/dev/null
            fi
            
            # Try to get markdown title if it's a markdown file
            local new_link_text=""
            if [[ "$link_path" == *.md ]]; then
                if [[ -f "$absolute_path" ]]; then
                    new_link_text=$(get_markdown_title "$absolute_path")
                    if [[ -n "$new_link_text" ]]; then
                        [[ "$VERBOSE" == "true" ]] && log_info "  Found markdown title: '$new_link_text' for $link_path"
                    else
                        # Markdown file without title: keep original link text
                        new_link_text="$link_text"
                        [[ "$VERBOSE" == "true" ]] && log_info "  Markdown file without title, keeping original: '$new_link_text' for $link_path"
                    fi
                else
                    # Markdown file not found: keep original link text
                    new_link_text="$link_text"
                    [[ "$VERBOSE" == "true" ]] && log_info "  Markdown file not found at '$absolute_path', keeping original: '$new_link_text' for $link_path"
                fi
            else
                # Non-markdown file: use project relative path
                new_link_text=$(get_project_relative_path "$link_path")
                [[ "$VERBOSE" == "true" ]] && log_info "  Non-markdown file, using path: '$new_link_text' for $link_path"
            fi
            
            # Update the line if text changed
            if [[ "$new_link_text" != "$link_text" ]]; then
                local new_line="- [$new_link_text]($link_path)"
                echo "$new_line" >> "$temp_file"
                modified=true
                [[ "$VERBOSE" == "true" ]] && log_info "  Changed: '$link_text' → '$new_link_text'"
            else
                echo "$line" >> "$temp_file"
            fi
        else
            echo "$line" >> "$temp_file"
        fi
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
    log_info "Starting file link format fixes..."
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_warn "DRY RUN MODE - No files will be modified"
    fi
    
    local files_processed=0
    local files_updated=0
    
    # Find all spec files
    while IFS= read -r spec_file; do
        ((files_processed++))
        
        if fix_file_links "$spec_file"; then
            ((files_updated++))
        fi
    done < <(find specs -name "*.spec.md" -type f | sort)
    
    # Summary
    echo ""
    log_info "=== File Link Fix Summary ==="
    log_info "Files processed: $files_processed"
    log_info "Files updated: $files_updated"
    
    if [[ "$files_updated" -gt 0 ]] && [[ "$DRY_RUN" != "true" ]]; then
        # Stage and commit changes
        find specs -name "*.spec.md" -type f -exec git add {} \;
        git commit -m "refactor(specs): Fix file link formats

- Use markdown titles for .md files when available
- Use project-relative paths for non-markdown files
- Improved readability and consistency across spec files
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
            echo "Fix file link formats in spec files."
            echo ""
            echo "Options:"
            echo "  --dry-run    Show what would be changed without making changes"
            echo "  --verbose    Show verbose output"
            echo "  --help       Show this help message"
            echo ""
            echo "Link format rules:"
            echo "  - Markdown files: [TITLE](relative path)"
            echo "  - Other files:    [project/relative/path](relative path)"
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Run main function
main