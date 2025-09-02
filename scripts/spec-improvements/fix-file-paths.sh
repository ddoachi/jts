#!/bin/bash

# fix-file-paths.sh - Fix file paths in spec files
# Purpose: 
# 1. Update external file paths to project-local paths
# 2. Fix incorrect spec file paths

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

# Function to fix file paths in a spec file
fix_file_paths() {
    local spec_file="$1"
    local temp_file=$(mktemp)
    local modified=false
    
    [[ "$VERBOSE" == "true" ]] && log_info "Processing: $spec_file"
    
    # Process the file line by line
    while IFS= read -r line; do
        local new_line="$line"
        
        # Fix external file paths
        if [[ "$line" =~ /usr/local/bin/jts-storage-monitor\.sh ]]; then
            new_line=$(echo "$line" | sed 's|/usr/local/bin/jts-storage-monitor\.sh|scripts/monitoring/jts-storage-monitor.sh|g')
            # Also fix the relative path
            new_line=$(echo "$new_line" | sed 's|\.\./\.\./\./usr/local/bin/|../../scripts/monitoring/|g')
            modified=true
            [[ "$VERBOSE" == "true" ]] && log_info "  Fixed external file path: jts-storage-monitor.sh"
        fi
        
        # Fix incorrect spec file paths - missing the hierarchy prefix
        # Pattern: ../E01-F01-T03/spec.md should be ../E01-F01-T03/E01-F01-T03.spec.md
        if [[ "$line" =~ \[(E[0-9]+-F[0-9]+(-T[0-9]+)?)/spec\.md\] ]]; then
            local hierarchy="${BASH_REMATCH[1]}"
            new_line=$(echo "$line" | sed "s|\[${hierarchy}/spec\.md\]|\[${hierarchy}/${hierarchy}.spec.md\]|g")
            modified=true
            [[ "$VERBOSE" == "true" ]] && log_info "  Fixed spec path: ${hierarchy}/spec.md -> ${hierarchy}/${hierarchy}.spec.md"
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
    log_info "Starting file path fixes..."
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_warn "DRY RUN MODE - No files will be modified"
    fi
    
    local files_processed=0
    local files_updated=0
    
    # Find all spec files
    while IFS= read -r spec_file; do
        ((files_processed++))
        
        if fix_file_paths "$spec_file"; then
            ((files_updated++))
        fi
    done < <(find specs -name "*.spec.md" -type f | sort)
    
    # Summary
    echo ""
    log_info "=== File Path Fix Summary ==="
    log_info "Files processed: $files_processed"
    log_info "Files updated: $files_updated"
    
    if [[ "$files_updated" -gt 0 ]] && [[ "$DRY_RUN" != "true" ]]; then
        # Stage and commit changes
        git add scripts/monitoring/jts-storage-monitor.sh
        find specs -name "*.spec.md" -type f -exec git add {} \;
        git commit -m "fix(specs): Fix file paths and copy external files to project

- Moved /usr/local/bin/jts-storage-monitor.sh to scripts/monitoring/
- Fixed incorrect spec file paths (missing hierarchy prefix)
- Updated relative paths to point to correct locations
- Added missing monitoring script to project structure
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
            echo "Fix file paths in spec files."
            echo ""
            echo "Options:"
            echo "  --dry-run    Show what would be changed without making changes"
            echo "  --verbose    Show verbose output"
            echo "  --help       Show this help message"
            echo ""
            echo "Fixes:"
            echo "  - Copy external files to project and update paths"
            echo "  - Fix incorrect spec file paths (missing hierarchy)"
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