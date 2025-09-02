#!/bin/bash

# restructure-spec.sh - Move metadata from YAML frontmatter to markdown body
# 
# This script processes spec.md and *.spec.md files to:
# 1. Move dependencies, blocks, related from YAML frontmatter to "## Related Specs" section
# 2. Remove pull_requests, commits, context_file from YAML frontmatter entirely
# 3. Keep files in YAML but also add them to "## Files" section as markdown links
# 4. Support dry-run mode and proper git commits

# Removed set -euo pipefail to handle errors more gracefully
set -u

# Global variables
DRY_RUN=false
VERBOSE=false
PROCESSED_COUNT=0
SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Usage function
usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Restructure spec files by moving metadata from YAML frontmatter to markdown body.

OPTIONS:
    -d, --dry-run       Show what would be changed without making changes
    -v, --verbose       Show verbose output
    -h, --help          Show this help message

EXAMPLES:
    $0                  Process all spec files and commit changes
    $0 --dry-run        Preview changes without modifying files
    $0 -v               Process with verbose output

This script will:
1. Find all spec.md and *.spec.md files (excluding backups)
2. Move dependencies, blocks, related to "## Related Specs" section
3. Remove pull_requests, commits, context_file from YAML entirely
4. Add "## Files" section with markdown links for all files
5. Commit changes with proper message
EOF
}

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_verbose() {
    if [[ "$VERBOSE" == "true" ]]; then
        echo -e "${BLUE}[VERBOSE]${NC} $1"
    fi
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -d|--dry-run)
                DRY_RUN=true
                shift
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                usage
                exit 1
                ;;
        esac
    done
}

# Find all spec files
find_spec_files() {
    find specs -name "*.spec.md" -o -name "spec.md" 2>/dev/null | \
        grep -v backup | \
        sort
}

# Extract YAML frontmatter section
extract_yaml_section() {
    local file="$1"
    local section_name="$2"
    
    # Extract the section with proper YAML parsing
    python3 << EOF
import re
import sys

try:
    with open('$file', 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Find YAML frontmatter
    yaml_match = re.match(r'^---\n(.*?)\n---\n', content, re.DOTALL)
    if not yaml_match:
        sys.exit(0)
    
    yaml_content = yaml_match.group(1)
    
    # Extract the specific section - handle both list and array formats
    # More precise patterns that stop at the next YAML field
    section_patterns = {
        'dependencies': [
            r'^dependencies:\s*\n((?:  - [^\n]*\n)*?)(?=\S|\Z)',  # List format - stop at next non-indented line
            r'^dependencies:\s*(\[[^\]]*\])'                      # Array format
        ],
        'blocks': [
            r'^blocks:\s*\n((?:  - [^\n]*\n)*?)(?=\S|\Z)',
            r'^blocks:\s*(\[[^\]]*\])'
        ],
        'related': [
            r'^related:\s*\n((?:  - [^\n]*\n)*?)(?=\S|\Z)',
            r'^related:\s*(\[[^\]]*\])'
        ],
        'files': [
            r'^files:\s*\n((?:  - [^\n]*\n)*?)(?=\S|\Z)',
            r'^files:\s*(\[[^\]]*\])'
        ]
    }
    
    if '$section_name' not in section_patterns:
        sys.exit(0)
    
    items = []
    for pattern in section_patterns['$section_name']:
        match = re.search(pattern, yaml_content, re.MULTILINE | re.DOTALL)
        if match:
            match_content = match.group(1).strip()
            if not match_content or match_content == '[]':
                continue
                
            if pattern.endswith(r'\]'):  # Array format
                # Parse array format: ["item1", "item2"] or ['item1', 'item2']
                array_items = re.findall(r'["\']([^"\']*)["\']', match_content)
                items.extend([item.strip() for item in array_items if item.strip()])
            else:  # List format
                # Parse list format
                for line in match_content.split('\n'):
                    if line.strip().startswith('- '):
                        item = line.strip()[2:].strip('"\'')
                        if item:
                            items.append(item)
            break
    
    for item in items:
        print(item)

except Exception as e:
    # Silently handle errors - debug: print(f"Error: {e}", file=sys.stderr)
    pass
EOF
}

# Convert spec ID to markdown link
spec_id_to_link() {
    local spec_id="$1"
    echo "[${spec_id}](../${spec_id}/spec.md)"
}

# Convert file path to markdown link
file_to_link() {
    local file_path="$1"
    # Remove trailing slash and get basename for display
    local clean_path="${file_path%/}"
    local display_name="${clean_path##*/}"
    
    # If it's a directory, append trailing slash for clarity
    if [[ "$file_path" == */ ]]; then
        display_name="${display_name}/"
    fi
    
    echo "[${display_name}](../../${file_path})"
}

# Process a single spec file
process_spec_file() {
    local file="$1"
    
    log_verbose "Processing file: $file"
    
    # Check if file is readable
    if [[ ! -r "$file" ]]; then
        log_warning "Cannot read file: $file, skipping"
        return
    fi
    
    # Read the original file
    local original_content
    original_content=$(cat "$file")
    
    # Check if file has YAML frontmatter
    if ! echo "$original_content" | head -1 | grep -q "^---$"; then
        log_warning "File $file does not have YAML frontmatter, skipping"
        return
    fi
    
    # Extract metadata sections
    local dependencies blocks related files
    dependencies=($(extract_yaml_section "$file" "dependencies"))
    blocks=($(extract_yaml_section "$file" "blocks"))
    related=($(extract_yaml_section "$file" "related"))
    files=($(extract_yaml_section "$file" "files"))
    
    # Check if there are any changes to make
    if [[ ${#dependencies[@]} -eq 0 && ${#blocks[@]} -eq 0 && ${#related[@]} -eq 0 && ${#files[@]} -eq 0 ]]; then
        log_verbose "No metadata to move in $file"
        return
    fi
    
    # Create new content using Python for complex YAML manipulation
    local new_content
    new_content=$(python3 - "$file" "$(IFS=,; echo "${dependencies[*]}")" "$(IFS=,; echo "${blocks[*]}")" "$(IFS=,; echo "${related[*]}")" "$(IFS=,; echo "${files[*]}")" << 'EOF'
import re
import sys

if len(sys.argv) < 6:
    # If not enough arguments, just return original content
    if len(sys.argv) >= 2:
        with open(sys.argv[1], 'r', encoding='utf-8') as f:
            print(f.read())
    sys.exit(0)

file_path = sys.argv[1]
# Safely get arguments with defaults
deps_arg = sys.argv[2] if len(sys.argv) > 2 else ""
blocks_arg = sys.argv[3] if len(sys.argv) > 3 else ""
related_arg = sys.argv[4] if len(sys.argv) > 4 else ""
files_arg = sys.argv[5] if len(sys.argv) > 5 else ""

dependencies = [d.strip() for d in deps_arg.split(',') if d.strip()] if deps_arg else []
blocks = [b.strip() for b in blocks_arg.split(',') if b.strip()] if blocks_arg else []
related = [r.strip() for r in related_arg.split(',') if r.strip()] if related_arg else []
files = [f.strip() for f in files_arg.split(',') if f.strip()] if files_arg else []

try:
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Split into YAML frontmatter and body
    yaml_match = re.match(r'^(---\n.*?\n---\n)(.*)', content, re.DOTALL)
    if not yaml_match:
        print(content)
        sys.exit(0)
    
    yaml_part = yaml_match.group(1)
    body_part = yaml_match.group(2)
    
    # Remove dependencies, blocks, related, pull_requests, commits, context_file from YAML
    # But keep files in YAML
    yaml_lines = yaml_part.split('\n')
    new_yaml_lines = []
    skip_section = False
    
    for line in yaml_lines:
        if line.startswith('dependencies:') or line.startswith('blocks:') or line.startswith('related:'):
            skip_section = True
            continue
        elif line.startswith('pull_requests:') or line.startswith('commits:') or line.startswith('context_file:'):
            skip_section = True
            continue
        elif skip_section and (line.startswith('  - ') or (line.strip() == '' and skip_section)):
            continue
        elif line.strip() != '' and not line.startswith('  ') and not line.startswith('#') and ':' in line:
            skip_section = False
            new_yaml_lines.append(line)
        else:
            if not skip_section:
                new_yaml_lines.append(line)
    
    new_yaml = '\n'.join(new_yaml_lines)
    
    # Find insertion point for new sections (after ## Acceptance Criteria if it exists)
    body_lines = body_part.split('\n')
    insertion_point = len(body_lines)
    
    # Look for ## Acceptance Criteria or ## Technical Approach/Implementation
    for i, line in enumerate(body_lines):
        if line.startswith('## Acceptance Criteria'):
            # Insert after this section
            j = i + 1
            while j < len(body_lines) and not body_lines[j].startswith('##'):
                j += 1
            insertion_point = j
            break
        elif line.startswith('## Technical'):
            insertion_point = i
            break
    
    # Prepare sections to insert
    sections_to_add = []
    
    # Add Related Specs section
    if dependencies or blocks or related:
        sections_to_add.append('## Related Specs')
        sections_to_add.append('')
        
        if dependencies:
            sections_to_add.append('**Dependencies:**')
            for dep in dependencies:
                if dep.strip():
                    sections_to_add.append(f'- [{dep.strip()}](../{dep.strip()}/spec.md)')
            sections_to_add.append('')
        
        if blocks:
            sections_to_add.append('**Blocks:**')
            for block in blocks:
                if block.strip():
                    sections_to_add.append(f'- [{block.strip()}](../{block.strip()}/spec.md)')
            sections_to_add.append('')
        
        if related:
            sections_to_add.append('**Related:**')
            for rel in related:
                if rel.strip():
                    sections_to_add.append(f'- [{rel.strip()}](../{rel.strip()}/spec.md)')
            sections_to_add.append('')
    
    # Add Files section
    if files:
        sections_to_add.append('## Files')
        sections_to_add.append('')
        for file_path in files:
            if file_path.strip():
                clean_path = file_path.strip().rstrip('/')
                display_name = clean_path.split('/')[-1] if '/' in clean_path else clean_path
                if file_path.strip().endswith('/'):
                    display_name += '/'
                sections_to_add.append(f'- [{display_name}](../../{file_path.strip()})')
        sections_to_add.append('')
    
    # Insert sections
    if sections_to_add:
        body_lines = body_lines[:insertion_point] + sections_to_add + body_lines[insertion_point:]
    
    new_body = '\n'.join(body_lines)
    
    # Combine new YAML and body
    print(new_yaml + new_body)

except Exception as e:
    # If there's an error, return original content
    with open(file_path, 'r', encoding='utf-8') as f:
        print(f.read())

EOF
)
    
    # Check if content actually changed
    if [[ "$original_content" == "$new_content" ]]; then
        log_verbose "No changes needed for $file"
        return
    fi
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "Would modify: $file"
        if [[ "$VERBOSE" == "true" ]]; then
            echo "--- Original sections to move ---"
            [[ ${#dependencies[@]} -gt 0 ]] && echo "Dependencies: ${dependencies[*]}"
            [[ ${#blocks[@]} -gt 0 ]] && echo "Blocks: ${blocks[*]}"
            [[ ${#related[@]} -gt 0 ]] && echo "Related: ${related[*]}"
            [[ ${#files[@]} -gt 0 ]] && echo "Files: ${files[*]}"
        fi
    else
        # Write the new content
        echo "$new_content" > "$file"
        log_success "Modified: $file"
    fi
    
    ((PROCESSED_COUNT++))
}

# Main processing function
main() {
    parse_args "$@"
    
    log_info "Starting spec file restructuring..."
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_warning "DRY RUN MODE - No files will be modified"
    fi
    
    # Find all spec files
    local spec_files
    mapfile -t spec_files < <(find_spec_files)
    
    if [[ ${#spec_files[@]} -eq 0 ]]; then
        log_warning "No spec files found"
        exit 0
    fi
    
    log_info "Found ${#spec_files[@]} spec files to process"
    
    # Process each file
    for file in "${spec_files[@]}"; do
        if [[ -f "$file" ]]; then
            process_spec_file "$file"
        fi
    done
    
    log_info "Processed $PROCESSED_COUNT files"
    
    if [[ "$DRY_RUN" == "false" && "$PROCESSED_COUNT" -gt 0 ]]; then
        # Commit changes
        log_info "Committing changes..."
        
        cd "$PROJECT_ROOT"
        
        # Add all modified spec files
        git add specs/*/spec.md 2>/dev/null || true
        find . -name "*.spec.md" -not -path "./specs_backup/*" -exec git add {} \; 2>/dev/null || true
        
        # Check if there are changes to commit
        if git diff --cached --quiet; then
            log_warning "No changes to commit"
        else
            # Create commit
            git commit -m "feat(scripts): Add restructure-spec.sh to move metadata to body

- Moves dependencies, blocks, related from YAML to body
- Removes pull_requests, commits, context_file from YAML
- Formats related specs and files as Markdown links
- Preserves existing content structure"
            
            log_success "Changes committed successfully"
        fi
    fi
    
    log_success "Spec file restructuring completed"
}

# Run main function with all arguments
main "$@"