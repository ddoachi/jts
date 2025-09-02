#!/bin/bash

# cleanup-duplicates.sh - Remove duplicate sections in spec files

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

# Function to remove duplicate sections
cleanup_duplicates() {
    local spec_file="$1"
    local temp_file=$(mktemp)
    local modified=false
    local in_files_section=false
    local files_section_count=0
    local current_section=""
    
    [[ "$VERBOSE" == "true" ]] && log_info "Processing: $spec_file"
    
    while IFS= read -r line; do
        # Check if we're starting a new section
        if [[ "$line" =~ ^##[[:space:]].* ]]; then
            current_section=$(echo "$line" | sed 's/^##[[:space:]]*//')
            
            if [[ "$current_section" == "Files" ]]; then
                ((files_section_count++))
                if [[ $files_section_count -eq 1 ]]; then
                    # Keep the first Files section
                    echo "$line" >> "$temp_file"
                    in_files_section=true
                else
                    # Skip duplicate Files sections
                    [[ "$VERBOSE" == "true" ]] && log_info "  Skipping duplicate Files section #$files_section_count"
                    in_files_section=false
                    modified=true
                    continue
                fi
            else
                # Not a Files section
                echo "$line" >> "$temp_file"
                in_files_section=false
            fi
        elif [[ "$line" =~ ^#[[:space:]].* ]] || [[ "$line" =~ ^#{3,}[[:space:]].* ]]; then
            # Other header levels
            echo "$line" >> "$temp_file"
            in_files_section=false
        else
            # Regular content line
            if [[ $files_section_count -gt 1 ]] && [[ "$in_files_section" == "false" ]] && [[ "$line" =~ ^-[[:space:]]*\[.*\]\(.*\)[[:space:]]*$ ]]; then
                # This is a file link that belongs to a duplicate Files section - skip it
                [[ "$VERBOSE" == "true" ]] && log_info "  Skipping duplicate file link: $line"
                modified=true
                continue
            else
                echo "$line" >> "$temp_file"
            fi
        fi
    done < "$spec_file"
    
    # Apply changes if any were made
    if [[ "$modified" == "true" ]]; then
        if [[ "$DRY_RUN" == "true" ]]; then
            echo "Would clean up: $spec_file (found $files_section_count Files sections)"
            rm "$temp_file"
        else
            mv "$temp_file" "$spec_file"
            log_success "Cleaned up: $spec_file (removed $((files_section_count - 1)) duplicate Files sections)"
        fi
        return 0
    else
        rm "$temp_file"
        [[ "$VERBOSE" == "true" ]] && log_info "  No duplicate sections found"
        return 1
    fi
}

# Main function
main() {
    log_info "Starting duplicate section cleanup..."
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_warn "DRY RUN MODE - No files will be modified"
    fi
    
    local files_processed=0
    local files_updated=0
    
    # Find all spec files
    while IFS= read -r spec_file; do
        ((files_processed++))
        
        if cleanup_duplicates "$spec_file"; then
            ((files_updated++))
        fi
    done < <(find specs -name "*.spec.md" -type f | sort)
    
    # Summary
    echo ""
    log_info "=== Cleanup Summary ==="
    log_info "Files processed: $files_processed"
    log_info "Files cleaned: $files_updated"
    
    if [[ "$files_updated" -gt 0 ]] && [[ "$DRY_RUN" != "true" ]]; then
        # Stage and commit changes
        find specs -name "*.spec.md" -type f -exec git add {} \;
        git commit -m "fix(specs): Remove duplicate Files sections

- Removed duplicate ## Files sections created by previous restructure scripts
- Consolidated file lists into single Files section per spec file
- Cleaned up $files_updated spec files

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
            echo "Remove duplicate sections in spec files."
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