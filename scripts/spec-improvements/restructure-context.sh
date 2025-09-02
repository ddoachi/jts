#!/bin/bash

# Generated from improvement request for spec_work command
# Purpose: Restructure context.md files to follow E01-F03-T03 format with proper Markdown links

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Script configuration
DRY_RUN=${DRY_RUN:-false}
VERBOSE=${VERBOSE:-false}
REPO_URL="https://github.com/ddoachi/jts"

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

# Function to get spec file path from context file
get_spec_file() {
    local context_file="$1"
    local dir=$(dirname "$context_file")
    
    # Look for spec.md or *.spec.md in same directory
    if [[ -f "$dir/spec.md" ]]; then
        echo "$dir/spec.md"
    else
        local spec_file=$(find "$dir" -maxdepth 1 -name "*.spec.md" 2>/dev/null | head -1)
        if [[ -n "$spec_file" ]]; then
            echo "$spec_file"
        fi
    fi
}

# Function to extract spec info from spec.md
extract_spec_info() {
    local spec_file="$1"
    local field="$2"
    
    if [[ ! -f "$spec_file" ]]; then
        return
    fi
    
    # Extract from YAML frontmatter
    awk -v field="$field" '
        /^---$/ { if (NR==1) in_yaml=1; else if (in_yaml) exit }
        in_yaml && $0 ~ "^" field ":" {
            sub("^" field ":[[:space:]]*", "")
            gsub(/^["'\'']|["'\'']$/, "")
            print
            exit
        }
    ' "$spec_file"
}

# Function to format GitHub issue as Markdown link
format_github_issue() {
    local issue_text="$1"
    
    # Extract issue number
    if [[ "$issue_text" =~ Issue\ #([0-9]+):\ (.+) ]]; then
        local issue_num="${BASH_REMATCH[1]}"
        local issue_title="${BASH_REMATCH[2]}"
        echo "[Issue #${issue_num}: ${issue_title}](${REPO_URL}/issues/${issue_num})"
    elif [[ "$issue_text" =~ #([0-9]+) ]]; then
        local issue_num="${BASH_REMATCH[1]}"
        # Try to get title from GitHub
        if command -v gh &> /dev/null; then
            local title=$(gh issue view "$issue_num" --json title -q .title 2>/dev/null || echo "")
            if [[ -n "$title" ]]; then
                echo "[Issue #${issue_num}: ${title}](${REPO_URL}/issues/${issue_num})"
            else
                echo "[Issue #${issue_num}](${REPO_URL}/issues/${issue_num})"
            fi
        else
            echo "[Issue #${issue_num}](${REPO_URL}/issues/${issue_num})"
        fi
    else
        echo "$issue_text"
    fi
}

# Function to restructure context file to follow E01-F03-T03 format
restructure_context() {
    local file="$1"
    local spec_file=$(get_spec_file "$file")
    
    if [[ ! -f "$spec_file" ]]; then
        log_warn "No spec file found for: $file"
        return 1
    fi
    
    # Extract spec information
    local spec_id=$(extract_spec_info "$spec_file" "id")
    local spec_title=$(extract_spec_info "$spec_file" "title")
    
    # Get relative path to spec file
    local spec_basename=$(basename "$spec_file")
    
    # Read current content
    local content=$(cat "$file")
    
    # Create new structured content following E01-F03-T03 format
    local new_content="# Implementation Context for ${spec_id}: ${spec_title}

## Related Spec

- [${spec_basename}](./${spec_basename})

## Overview

This document tracks the implementation progress of ${spec_title}.

## GitHub Issue

"
    
    # Look for existing GitHub issue in content
    if echo "$content" | grep -qE "(Issue|issue).*#[0-9]+"; then
        local issue_line=$(echo "$content" | grep -E "(Issue|issue).*#[0-9]+" | head -1)
        new_content+="- $(format_github_issue "$issue_line")"
    else
        new_content+="- *To be created*"
    fi
    
    new_content+="

## Implementation Timeline
"
    
    # Add current date if starting fresh
    if ! echo "$content" | grep -qE "^###.*[0-9]{4}-[0-9]{2}-[0-9]{2}"; then
        local current_date=$(date +%Y-%m-%d)
        new_content+="
### ${current_date}: Initial Implementation
"
    fi
    
    # Try to preserve existing implementation timeline
    if echo "$content" | grep -qE "Implementation (Timeline|Log|Session)"; then
        # Extract implementation section
        local impl_section=$(echo "$content" | awk '
            /Implementation (Timeline|Log|Session)/ { found=1; next }
            /^##[^#]/ && found { exit }
            found { print }
        ')
        
        if [[ -n "$impl_section" ]]; then
            new_content+="$impl_section"
        fi
    elif echo "$content" | grep -qE "^###.*[0-9]{4}-[0-9]{2}-[0-9]{2}"; then
        # Extract date-based sections
        local date_sections=$(echo "$content" | awk '
            /^###.*[0-9]{4}-[0-9]{2}-[0-9]{2}/ { found=1 }
            /^##[^#]/ && found { exit }
            found { print }
        ')
        
        if [[ -n "$date_sections" ]]; then
            new_content+="$date_sections"
        fi
    else
        # Add placeholder for implementation steps
        new_content+="
#### 1. Planning Phase

- Analyzed requirements
- Designed implementation approach

#### 2. Implementation Phase

- *To be documented*

#### 3. Testing Phase

- *To be documented*
"
    fi
    
    # Add verification section
    new_content+="

## Verification Results

"
    
    # Try to preserve existing verification/test results
    if echo "$content" | grep -qE "(Verification|Test|Testing) (Results|Execution)"; then
        local verif_section=$(echo "$content" | awk '
            /(Verification|Test|Testing) (Results|Execution)/ { found=1; next }
            /^##[^#]/ && found { exit }
            found { print }
        ')
        
        if [[ -n "$verif_section" ]]; then
            new_content+="$verif_section"
        fi
    else
        new_content+="### Test Execution

- *To be documented*

### Build System

- *To be documented*
"
    fi
    
    # Add files section
    new_content+="

## Files Created/Modified
"
    
    # Try to preserve existing files section
    if echo "$content" | grep -qE "Files (Created|Modified)"; then
        local files_section=$(echo "$content" | awk '
            /Files (Created|Modified)/ { found=1; next }
            /^##[^#]/ && found { exit }
            found { print }
        ')
        
        if [[ -n "$files_section" ]]; then
            new_content+="$files_section"
        fi
    else
        new_content+="
### Created Files

1. *To be documented*

### Modified Files

1. *To be documented*
"
    fi
    
    # Add acceptance criteria status
    new_content+="

## Acceptance Criteria Status

"
    
    # Try to preserve existing acceptance criteria
    if echo "$content" | grep -qE "Acceptance Criteria"; then
        local criteria_section=$(echo "$content" | awk '
            /Acceptance Criteria/ { found=1; next }
            /^##[^#]/ && found { exit }
            found { print }
        ')
        
        if [[ -n "$criteria_section" ]]; then
            new_content+="$criteria_section"
        fi
    else
        new_content+="- ⬜ *To be documented*
"
    fi
    
    # Add next steps
    new_content+="

## Next Steps

"
    
    # Try to preserve existing next steps
    if echo "$content" | grep -qE "Next Steps"; then
        local next_section=$(echo "$content" | awk '
            /Next Steps/ { found=1; next }
            /^##[^#]/ && found { exit }
            found { print }
        ')
        
        if [[ -n "$next_section" ]]; then
            new_content+="$next_section"
        fi
    else
        new_content+="1. *To be determined*
"
    fi
    
    # Add notes section
    new_content+="

## Notes

"
    
    # Try to preserve existing notes
    if echo "$content" | grep -qE "^## Notes"; then
        local notes_section=$(echo "$content" | awk '
            /^## Notes/ { found=1; next }
            /^##[^#]/ && found { exit }
            found { print }
        ')
        
        if [[ -n "$notes_section" ]]; then
            new_content+="$notes_section"
        fi
    else
        new_content+="- *No additional notes*
"
    fi
    
    # Write the new content
    if [[ "$DRY_RUN" == "true" ]]; then
        echo "Would restructure: $file"
        if [[ "$VERBOSE" == "true" ]]; then
            echo "=== New structure preview ==="
            echo "$new_content"
            echo "============================="
        fi
    else
        echo "$new_content" > "$file"
        git add "$file"
        log_info "Restructured: $file"
    fi
    
    return 0
}

# Main execution
main() {
    log_info "Starting context.md restructuring..."
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_warn "DRY RUN MODE - No files will be modified"
    fi
    
    local count=0
    local error_count=0
    
    # Process all context.md and *.context.md files
    log_info "Processing context files..."
    while IFS= read -r file; do
        if restructure_context "$file"; then
            ((count++))
        else
            ((error_count++))
        fi
    done < <(find specs -type f \( -name "context.md" -o -name "*.context.md" \) 2>/dev/null | sort)
    
    # Commit changes
    if [[ "$DRY_RUN" != "true" ]] && [[ $count -gt 0 ]]; then
        git commit -m "refactor(specs): Restructure context.md files to follow E01-F03-T03 format

- Added link to related spec.md at top
- Formatted GitHub issues as Markdown links
- Structured with Implementation Timeline sections
- Added DateTime tracking placeholders
- Preserved existing content where available
- Updated $count context files"
        log_info "Committed context file restructuring"
    fi
    
    # Summary
    echo ""
    log_info "=== Restructuring Summary ==="
    log_info "Context files restructured: $count"
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
            echo "  --dry-run    Show what would be changed without modifying files"
            echo "  --verbose    Show verbose output including new structure"
            echo "  --help       Show this help message"
            echo ""
            echo "This script restructures context.md files to follow the E01-F03-T03 format:"
            echo "  - Adds link to related spec.md at top"
            echo "  - Formats GitHub issues as Markdown links"
            echo "  - Structures with Implementation Timeline"
            echo "  - Adds verification and acceptance criteria sections"
            echo "  - Preserves existing content where possible"
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