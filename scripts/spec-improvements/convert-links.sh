#!/bin/bash

# Generated from improvement request for spec_work command
# Purpose: Convert commits, PRs, and file paths to Markdown links in spec files

# Removed set -e to handle errors more gracefully

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

# Function to get relative path from file to target
get_relative_path() {
    local from_file="$1"
    local to_file="$2"
    
    # Use Python for reliable relative path calculation
    python3 -c "
import os
from_dir = os.path.dirname('$from_file')
rel_path = os.path.relpath('$to_file', from_dir)
print(rel_path)
"
}

# Function to convert commit references to Markdown links
convert_commits() {
    local file="$1"
    local content="$2"
    local modified=false
    
    # Pattern 1: Commit hash with message (e.g., "abc1234 - feat: description")
    if echo "$content" | grep -qE '\b[a-f0-9]{7,40}\b\s*-\s*.+'; then
        content=$(echo "$content" | sed -E "s/\b([a-f0-9]{7,40})\b\s*-\s*(.+)/[\`\1\` - \2]($REPO_URL\/commit\/\1)/g")
        modified=true
    fi
    
    # Pattern 2: Standalone commit hash
    if echo "$content" | grep -qE '^\s*-?\s*\b[a-f0-9]{7,40}\b\s*$'; then
        content=$(echo "$content" | sed -E "s/^\s*-?\s*\b([a-f0-9]{7,40})\b\s*$/- [\`\1\`]($REPO_URL\/commit\/\1)/g")
        modified=true
    fi
    
    # Pattern 3: In context.md "Commit: hash - message" format
    if echo "$content" | grep -qE '\*\*Commit\*\*:\s*`?[a-f0-9]{7,40}`?\s*-'; then
        content=$(echo "$content" | sed -E "s/\*\*Commit\*\*:\s*\`?([a-f0-9]{7,40})\`?\s*-\s*(.+)$/**Commit**: [\`\1\` - \2]($REPO_URL\/commit\/\1)/g")
        modified=true
    fi
    
    echo "$content"
    [[ "$modified" == "true" ]] && return 0 || return 1
}

# Function to convert PR/Issue references to Markdown links
convert_issues_prs() {
    local file="$1"
    local content="$2"
    local modified=false
    
    # Pattern 1: Issue #N format
    if echo "$content" | grep -qE '#[0-9]+'; then
        # First, get issue titles using gh CLI if available
        if command -v gh &> /dev/null; then
            while read -r issue_num; do
                local title=$(gh issue view "$issue_num" --json title -q .title 2>/dev/null || echo "")
                if [[ -n "$title" ]]; then
                    content=$(echo "$content" | sed "s/#${issue_num}\b/[#${issue_num}: ${title}]($REPO_URL\/issues\/${issue_num})/g")
                else
                    content=$(echo "$content" | sed "s/#${issue_num}\b/[#${issue_num}]($REPO_URL\/issues\/${issue_num})/g")
                fi
                modified=true
            done < <(echo "$content" | grep -oE '#[0-9]+' | sed 's/#//' | sort -u)
        else
            # Fallback without title
            content=$(echo "$content" | sed -E "s/#([0-9]+)/[#\1]($REPO_URL\/issues\/\1)/g")
            modified=true
        fi
    fi
    
    # Pattern 2: "Issue #N: Title" format
    if echo "$content" | grep -qE 'Issue\s+#[0-9]+:'; then
        content=$(echo "$content" | sed -E "s/Issue\s+#([0-9]+):\s*([^]]+)/[Issue #\1: \2]($REPO_URL\/issues\/\1)/g")
        modified=true
    fi
    
    # Pattern 3: Separate Issue and Link lines (context.md format)
    if echo "$content" | grep -qE '^\s*-\s*Issue:.*\n\s*-\s*Link:'; then
        content=$(echo "$content" | awk '
            /^[[:space:]]*-[[:space:]]*Issue:/ {
                issue_line = $0
                gsub(/^[[:space:]]*-[[:space:]]*Issue:[[:space:]]*/, "", issue_line)
                getline
                if ($0 ~ /^[[:space:]]*-[[:space:]]*Link:/) {
                    link_line = $0
                    gsub(/^[[:space:]]*-[[:space:]]*Link:[[:space:]]*/, "", link_line)
                    print "- " issue_line " - [View Issue](" link_line ")"
                } else {
                    print "- Issue: " issue_line
                    print $0
                }
                next
            }
            { print }
        ')
        modified=true
    fi
    
    echo "$content"
    [[ "$modified" == "true" ]] && return 0 || return 1
}

# Function to convert file paths to Markdown links
convert_file_paths() {
    local file="$1"
    local content="$2"
    local modified=false
    local project_root="/home/joohan/dev/project-jts/worktrees/fix-spec-context"
    
    # Pattern 1: Files in backticks (e.g., `apps/service/src/main.ts`)
    while read -r filepath; do
        # Skip if already a markdown link
        if [[ "$filepath" =~ ^\[.*\]\(.*\)$ ]]; then
            continue
        fi
        
        # Clean the filepath
        local clean_path=$(echo "$filepath" | sed 's/`//g' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        
        # Skip URLs and already linked paths
        if [[ "$clean_path" =~ ^https?:// ]] || [[ "$clean_path" =~ ^\[.*\] ]]; then
            continue
        fi
        
        # Build the full path
        local full_path="$project_root/$clean_path"
        
        # Check if file exists
        if [[ -f "$full_path" ]] || [[ -d "$full_path" ]]; then
            local rel_path=$(get_relative_path "$file" "$full_path")
            # Escape special characters for sed
            local escaped_filepath=$(printf '%s\n' "$filepath" | sed 's/[[\.*^$()+?{|]/\\&/g')
            content=$(echo "$content" | sed "s|$escaped_filepath|[\`$clean_path\`]($rel_path)|g")
            modified=true
        fi
    done < <(echo "$content" | grep -oE '`[^`]+\.(ts|js|json|yml|yaml|md|sh|tsx|jsx)`' | sort -u)
    
    # Pattern 2: File lists in YAML frontmatter
    if echo "$content" | grep -qE '^\s*files:\s*$' || echo "$content" | grep -qE '^\s*-\s*[^/]*\.(ts|js|json|yml|yaml|md|sh|tsx|jsx)'; then
        content=$(echo "$content" | awk -v file="$file" -v root="$project_root" '
            BEGIN { in_files = 0 }
            /^files:/ { in_files = 1; print; next }
            /^[a-zA-Z_-]+:/ { in_files = 0 }
            in_files && /^[[:space:]]*-[[:space:]]/ {
                filepath = $0
                gsub(/^[[:space:]]*-[[:space:]]*/, "", filepath)
                gsub(/[[:space:]]*$/, "", filepath)
                
                # Build full path and get relative
                full_path = root "/" filepath
                cmd = "python3 -c \"import os; print(os.path.relpath('" full_path "', os.path.dirname('" file "')))\" 2>/dev/null"
                cmd | getline rel_path
                close(cmd)
                
                if (rel_path && rel_path != "") {
                    print "  - [`" filepath "`](" rel_path ")"
                } else {
                    print $0
                }
                next
            }
            { print }
        ')
        modified=true
    fi
    
    echo "$content"
    [[ "$modified" == "true" ]] && return 0 || return 1
}

# Function to process a single file
process_file() {
    local file="$1"
    local temp_file=$(mktemp)
    local original_content=$(cat "$file")
    local content="$original_content"
    local any_changes=false
    
    [[ "$VERBOSE" == "true" ]] && log_info "Processing: $file"
    
    # Apply conversions
    if new_content=$(convert_commits "$file" "$content"); then
        content="$new_content"
        any_changes=true
        [[ "$VERBOSE" == "true" ]] && log_info "  - Converted commit references"
    fi
    
    if new_content=$(convert_issues_prs "$file" "$content"); then
        content="$new_content"
        any_changes=true
        [[ "$VERBOSE" == "true" ]] && log_info "  - Converted issue/PR references"
    fi
    
    if new_content=$(convert_file_paths "$file" "$content"); then
        content="$new_content"
        any_changes=true
        [[ "$VERBOSE" == "true" ]] && log_info "  - Converted file paths"
    fi
    
    if [[ "$any_changes" == "true" ]]; then
        if [[ "$DRY_RUN" == "true" ]]; then
            echo "Would update: $file"
            if [[ "$VERBOSE" == "true" ]]; then
                echo "=== Changes preview ==="
                diff -u <(echo "$original_content") <(echo "$content") || true
                echo "======================="
            fi
        else
            echo "$content" > "$file"
            git add "$file"
            log_info "Updated: $file"
        fi
        return 0
    else
        [[ "$VERBOSE" == "true" ]] && log_info "  - No changes needed"
        return 1
    fi
}

# Main execution
main() {
    log_info "Starting link conversion..."
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_warn "DRY RUN MODE - No files will be modified"
    fi
    
    local spec_count=0
    local context_count=0
    local total_changes=0
    
    # Process all spec.md and *.spec.md files
    log_info "Processing spec files..."
    while IFS= read -r file; do
        if process_file "$file"; then
            ((spec_count++))
            ((total_changes++))
        fi
    done < <(find specs -type f \( -name "spec.md" -o -name "*.spec.md" \) 2>/dev/null | sort)
    
    # Commit spec file changes
    if [[ "$DRY_RUN" != "true" ]] && [[ $spec_count -gt 0 ]]; then
        git commit -m "refactor(specs): Convert references to Markdown links in spec files

- Converted commit hashes to GitHub commit links
- Converted issue/PR references to GitHub links
- Converted file paths to relative Markdown links
- Updated $spec_count spec files"
        log_info "Committed spec file link conversions"
    fi
    
    # Process all context.md and *.context.md files
    log_info "Processing context files..."
    while IFS= read -r file; do
        if process_file "$file"; then
            ((context_count++))
            ((total_changes++))
        fi
    done < <(find specs -type f \( -name "context.md" -o -name "*.context.md" \) 2>/dev/null | sort)
    
    # Commit context file changes
    if [[ "$DRY_RUN" != "true" ]] && [[ $context_count -gt 0 ]]; then
        git commit -m "refactor(specs): Convert references to Markdown links in context files

- Converted commit hashes to GitHub commit links
- Converted issue/PR references to GitHub links  
- Converted file paths to relative Markdown links
- Updated $context_count context files"
        log_info "Committed context file link conversions"
    fi
    
    # Summary
    echo ""
    log_info "=== Conversion Summary ==="
    log_info "Spec files updated: $spec_count"
    log_info "Context files updated: $context_count"
    log_info "Total files modified: $total_changes"
    
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
        --repo-url)
            REPO_URL="$2"
            shift 2
            ;;
        --help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --dry-run           Show what would be changed without modifying files"
            echo "  --verbose           Show verbose output including diffs"
            echo "  --repo-url URL      Set GitHub repository URL (default: https://github.com/ddoachi/jts)"
            echo "  --help              Show this help message"
            echo ""
            echo "Environment variables:"
            echo "  DRY_RUN=true        Same as --dry-run"
            echo "  VERBOSE=true        Same as --verbose"
            echo ""
            echo "This script converts:"
            echo "  - Commit hashes to GitHub links: abc1234 -> [abc1234](url)"
            echo "  - Issue/PR refs to GitHub links: #123 -> [#123: Title](url)"
            echo "  - File paths to relative links: file.ts -> [file.ts](../path/to/file.ts)"
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Check for required tools
if ! command -v python3 &> /dev/null; then
    log_error "Python 3 is required for relative path calculation"
    exit 1
fi

# Run main function
main