#!/bin/bash

# Generated from improvement request for spec_work command
# Purpose: Add verification documentation to existing context files

# Removed set -e to handle errors more gracefully

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

# Function to check if verification docs exist
has_verification_docs() {
    local file="$1"
    
    # Check for verification-related sections
    if grep -qE "(Verification|How to Verify|Testing Instructions|Execution Steps)" "$file" 2>/dev/null; then
        return 0
    fi
    return 1
}

# Function to add verification documentation template
add_verification_docs() {
    local file="$1"
    local spec_id=""
    
    # Extract spec ID from path
    if [[ $file =~ specs/([^/]+(/[^/]+)?(/[^/]+)?)/.*context\.md$ ]]; then
        spec_id=$(echo "${BASH_REMATCH[1]}" | sed 's/\//\-/g')
    fi
    
    # Check if verification docs already exist
    if has_verification_docs "$file"; then
        [[ "$VERBOSE" == "true" ]] && log_info "Verification docs already exist in: $file"
        return 1
    fi
    
    # Get current datetime
    local current_datetime=$(date '+%Y-%m-%d %H:%M')
    
    # Create verification documentation section
    local verification_docs="

## Verification Documentation

### ${current_datetime}: Added Verification Requirements

#### How to Verify Implementation

##### 1. Setup Requirements
\`\`\`bash
# Environment setup
cd /path/to/project
npm install  # or appropriate setup command
\`\`\`

##### 2. Running Tests
\`\`\`bash
# Unit tests
npm run test:unit ${spec_id}

# Integration tests  
npm run test:integration ${spec_id}

# E2E tests
npm run test:e2e ${spec_id}
\`\`\`

##### 3. Manual Verification Steps
1. **Step 1**: Description of first verification step
   - Expected result: What should happen
   - How to check: Command or action to verify
   
2. **Step 2**: Description of second verification step
   - Expected result: What should happen
   - How to check: Command or action to verify

##### 4. Expected Outputs
\`\`\`
# Example of expected output
Service started successfully on port 3000
Database connected
Ready to accept requests
\`\`\`

##### 5. Common Issues and Solutions
- **Issue**: Description of common issue
  - **Solution**: How to resolve it
  
- **Issue**: Another common issue
  - **Solution**: How to resolve it

#### Performance Verification
- **Metric 1**: Expected value or range
- **Metric 2**: Expected value or range
- **How to measure**: Commands or tools to use

#### Security Verification
- [ ] No sensitive data in logs
- [ ] Proper authentication implemented
- [ ] Input validation in place
- [ ] Error messages don't expose internals
"
    
    # Append to file
    if [[ "$DRY_RUN" == "true" ]]; then
        echo "Would add verification docs to: $file"
        if [[ "$VERBOSE" == "true" ]]; then
            echo "=== Verification docs to add ==="
            echo "$verification_docs"
            echo "================================"
        fi
    else
        echo "$verification_docs" >> "$file"
        git add "$file"
        log_info "Added verification docs to: $file"
    fi
    
    return 0
}

# Function to create missing context files with verification
create_context_with_verification() {
    local spec_file="$1"
    local context_file="${spec_file/spec.md/context.md}"
    
    # Skip if context already exists
    if [[ -f "$context_file" ]]; then
        return 1
    fi
    
    # Extract spec info
    local spec_id=""
    local spec_title=""
    
    if [[ $spec_file =~ specs/([^/]+(/[^/]+)?(/[^/]+)?)/.*spec\.md$ ]]; then
        spec_id=$(echo "${BASH_REMATCH[1]}" | sed 's/\//\-/g')
    fi
    
    # Try to extract title from spec file
    if [[ -f "$spec_file" ]]; then
        spec_title=$(grep -E "^title:" "$spec_file" 2>/dev/null | head -1 | sed 's/title:[[:space:]]*//' | sed 's/["'\'']//g')
    fi
    
    [[ -z "$spec_title" ]] && spec_title="Implementation Task"
    
    # Get current datetime
    local current_datetime=$(date '+%Y-%m-%d %H:%M')
    
    # Create context with verification
    local content="# Implementation Context for ${spec_id}: ${spec_title}

## Related Spec

- [spec.md](./spec.md)

## Overview

This document tracks the implementation progress of ${spec_title}.

## GitHub Issue

- *To be created*

## Implementation Timeline

### ${current_datetime}: Context Created

- Created context documentation
- Added verification requirements

## Verification Documentation

### How to Verify Implementation

#### 1. Setup Requirements
\`\`\`bash
# Environment setup
cd /path/to/project
npm install
\`\`\`

#### 2. Running Tests
\`\`\`bash
# Run all tests
npm test

# Run specific tests
npm test -- --grep \"${spec_id}\"
\`\`\`

#### 3. Manual Verification Steps
1. **Setup**: Initialize the environment
   - Expected: All dependencies installed
   - Verify: \`npm list\`

2. **Execution**: Run the implementation
   - Expected: Successful execution
   - Verify: Check logs for success messages

#### 4. Expected Outputs
\`\`\`
Implementation completed successfully
All tests passing
No errors in console
\`\`\`

## Files Created/Modified

### Created Files
1. *To be documented*

### Modified Files
1. *To be documented*

## Acceptance Criteria Status

- ⬜ *To be documented*

## Next Steps

1. Implement the specification
2. Run verification tests
3. Update documentation

## Notes

- Context created: ${current_datetime}
- Includes verification documentation template
"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        echo "Would create context with verification: $context_file"
        if [[ "$VERBOSE" == "true" ]]; then
            echo "=== New context content ==="
            echo "$content"
            echo "=========================="
        fi
    else
        echo "$content" > "$context_file"
        git add "$context_file"
        log_info "Created context with verification: $context_file"
    fi
    
    return 0
}

# Main execution
main() {
    log_info "Starting verification documentation additions..."
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_warn "DRY RUN MODE - No files will be modified"
    fi
    
    local updated_count=0
    local created_count=0
    local skipped_count=0
    
    # Process existing context files
    log_info "Adding verification docs to existing context files..."
    while IFS= read -r file; do
        if add_verification_docs "$file"; then
            ((updated_count++))
        else
            ((skipped_count++))
        fi
    done < <(find specs -type f \( -name "context.md" -o -name "*.context.md" \) 2>/dev/null | sort)
    
    # Commit updates
    if [[ "$DRY_RUN" != "true" ]] && [[ $updated_count -gt 0 ]]; then
        git commit -m "docs(specs): Add verification documentation to context files

- Added setup and execution instructions
- Added manual verification steps
- Added expected output examples
- Added troubleshooting guidance
- Updated $updated_count context files"
        log_info "Committed verification documentation additions"
    fi
    
    # Create missing context files with verification
    log_info "Creating missing context files with verification..."
    while IFS= read -r spec_file; do
        if create_context_with_verification "$spec_file"; then
            ((created_count++))
        fi
    done < <(find specs -type f \( -name "spec.md" -o -name "*.spec.md" \) 2>/dev/null | sort)
    
    # Commit new files
    if [[ "$DRY_RUN" != "true" ]] && [[ $created_count -gt 0 ]]; then
        git commit -m "docs(specs): Create missing context files with verification

- Created context files for specs without them
- Included verification documentation template
- Added execution and testing instructions
- Created $created_count new context files"
        log_info "Committed new context files"
    fi
    
    # Summary
    echo ""
    log_info "=== Verification Documentation Summary ==="
    log_info "Existing contexts updated: $updated_count"
    log_info "New contexts created: $created_count"
    log_info "Files skipped (already have docs): $skipped_count"
    log_info "Total contexts now: $((updated_count + created_count + skipped_count))"
    
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
            echo "  --verbose    Show verbose output including content"
            echo "  --help       Show this help message"
            echo ""
            echo "This script:"
            echo "  - Adds verification documentation to existing context files"
            echo "  - Creates missing context files with verification templates"
            echo "  - Includes setup, execution, and testing instructions"
            echo "  - Adds expected outputs and troubleshooting guidance"
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