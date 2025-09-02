#!/bin/bash

# Generated from improvement request for spec_work command
# Purpose: Rename spec.md and context.md files to include hierarchy string

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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

# Function to extract hierarchy from path
get_hierarchy_string() {
    local path="$1"
    local hierarchy=""
    
    # Extract E01/F02/T03 pattern from path
    if [[ $path =~ specs/([^/]+)/([^/]+)/([^/]+)/(spec|context)\.md$ ]]; then
        # Task level: E01-F02-T03
        hierarchy="${BASH_REMATCH[1]}-${BASH_REMATCH[2]}-${BASH_REMATCH[3]}"
    elif [[ $path =~ specs/([^/]+)/([^/]+)/(spec|context)\.md$ ]]; then
        # Feature level: E01-F02
        hierarchy="${BASH_REMATCH[1]}-${BASH_REMATCH[2]}"
    elif [[ $path =~ specs/([^/]+)/(spec|context)\.md$ ]]; then
        # Epic level: E01
        hierarchy="${BASH_REMATCH[1]}"
    fi
    
    echo "$hierarchy"
}

# Function to rename a file
rename_file() {
    local old_path="$1"
    local file_type="$2" # spec or context
    
    local dir=$(dirname "$old_path")
    local hierarchy=$(get_hierarchy_string "$old_path")
    
    if [[ -z "$hierarchy" ]]; then
        log_warn "Could not extract hierarchy from: $old_path"
        return 1
    fi
    
    local new_name="${hierarchy}.${file_type}.md"
    local new_path="${dir}/${new_name}"
    
    if [[ "$old_path" == "$new_path" ]]; then
        [[ "$VERBOSE" == "true" ]] && log_info "Already renamed: $old_path"
        return 0
    fi
    
    if [[ -f "$new_path" ]]; then
        log_warn "Target already exists: $new_path"
        return 1
    fi
    
    if [[ "$DRY_RUN" == "true" ]]; then
        echo "Would rename: $old_path -> $new_path"
    else
        mv "$old_path" "$new_path"
        git add "$old_path" "$new_path"
        log_info "Renamed: $old_path -> $new_path"
    fi
    
    return 0
}

# Main execution
main() {
    log_info "Starting spec file renaming..."
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_warn "DRY RUN MODE - No files will be modified"
    fi
    
    local spec_count=0
    local context_count=0
    local error_count=0
    
    # Process spec.md files
    log_info "Processing spec.md files..."
    while IFS= read -r file; do
        if rename_file "$file" "spec"; then
            ((spec_count++))
        else
            ((error_count++))
        fi
    done < <(find specs -name "spec.md" -type f 2>/dev/null | sort)
    
    # Commit spec.md renames
    if [[ "$DRY_RUN" != "true" ]] && [[ $spec_count -gt 0 ]]; then
        git commit -m "refactor(specs): Rename spec.md files to include hierarchy string

- Renamed $spec_count spec.md files to {hierarchy}.spec.md format
- Format: E01.spec.md, E01-F01.spec.md, E01-F01-T01.spec.md
- Improves file identification and navigation"
        log_info "Committed spec.md renames"
    fi
    
    # Process context.md files
    log_info "Processing context.md files..."
    while IFS= read -r file; do
        if rename_file "$file" "context"; then
            ((context_count++))
        else
            ((error_count++))
        fi
    done < <(find specs -name "context.md" -type f 2>/dev/null | sort)
    
    # Commit context.md renames
    if [[ "$DRY_RUN" != "true" ]] && [[ $context_count -gt 0 ]]; then
        git commit -m "refactor(specs): Rename context.md files to include hierarchy string

- Renamed $context_count context.md files to {hierarchy}.context.md format
- Maintains consistency with spec.md naming convention
- Improves file identification and navigation"
        log_info "Committed context.md renames"
    fi
    
    # Summary
    echo ""
    log_info "=== Renaming Summary ==="
    log_info "Spec files renamed: $spec_count"
    log_info "Context files renamed: $context_count"
    if [[ $error_count -gt 0 ]]; then
        log_warn "Errors encountered: $error_count"
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
            echo "Options:"
            echo "  --dry-run    Show what would be renamed without making changes"
            echo "  --verbose    Show verbose output"
            echo "  --help       Show this help message"
            echo ""
            echo "Environment variables:"
            echo "  DRY_RUN=true   Same as --dry-run"
            echo "  VERBOSE=true   Same as --verbose"
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