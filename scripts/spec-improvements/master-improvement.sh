#!/bin/bash

# Master orchestration script for spec improvements
# Purpose: Run all spec improvement scripts in the correct order

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Script configuration
DRY_RUN=${DRY_RUN:-false}
VERBOSE=${VERBOSE:-false}
BACKUP=${BACKUP:-true}
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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

log_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

log_success() {
    echo -e "${CYAN}[SUCCESS]${NC} $1"
}

# Function to check if script exists
check_script() {
    local script="$1"
    if [[ ! -f "$SCRIPT_DIR/$script" ]]; then
        log_error "Script not found: $script"
        return 1
    fi
    if [[ ! -x "$SCRIPT_DIR/$script" ]]; then
        log_warn "Script not executable: $script"
        chmod +x "$SCRIPT_DIR/$script"
        log_info "Made executable: $script"
    fi
    return 0
}

# Function to run a script with proper flags
run_script() {
    local script="$1"
    local description="$2"
    
    log_step "$description"
    
    local cmd="$SCRIPT_DIR/$script"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        cmd="$cmd --dry-run"
    fi
    
    if [[ "$VERBOSE" == "true" ]]; then
        cmd="$cmd --verbose"
    fi
    
    if $cmd; then
        log_success "Completed: $description"
        return 0
    else
        log_error "Failed: $description"
        return 1
    fi
}

# Function to create backup
create_backup() {
    if [[ "$BACKUP" != "true" ]]; then
        return 0
    fi
    
    log_info "Creating backup of specs directory..."
    
    local backup_dir="specs.backup.$(date +%Y%m%d-%H%M%S)"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        echo "Would create backup: $backup_dir"
    else
        cp -r specs "$backup_dir"
        log_info "Backup created: $backup_dir"
    fi
}

# Function to show summary
show_summary() {
    echo ""
    echo "======================================"
    echo -e "${CYAN}   SPEC IMPROVEMENT SUMMARY${NC}"
    echo "======================================"
    echo ""
    
    # Count files
    local spec_count=$(find specs -name "*.spec.md" -o -name "spec.md" 2>/dev/null | wc -l)
    local context_count=$(find specs -name "*.context.md" -o -name "context.md" 2>/dev/null | wc -l)
    
    log_info "Total spec files: $spec_count"
    log_info "Total context files: $context_count"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        echo ""
        log_warn "This was a DRY RUN - no files were modified"
        echo ""
        echo "To apply all changes, run:"
        echo "  DRY_RUN=false $0"
        echo ""
        echo "To apply individual scripts, run:"
        echo "  DRY_RUN=false $SCRIPT_DIR/rename-spec-files.sh"
        echo "  DRY_RUN=false $SCRIPT_DIR/convert-links.sh"
        echo "  DRY_RUN=false $SCRIPT_DIR/restructure-spec.sh"
        echo "  DRY_RUN=false $SCRIPT_DIR/restructure-context.sh"
        echo "  DRY_RUN=false $SCRIPT_DIR/add-verification-docs.sh"
    else
        echo ""
        log_success "All improvements have been applied!"
        echo ""
        echo "Next steps:"
        echo "1. Review the changes with: git diff --staged"
        echo "2. Test the spec_work command with updated specs"
        echo "3. Update the spec index: /spec_work --update-index"
    fi
}

# Main execution
main() {
    echo "======================================"
    echo -e "${CYAN}   SPEC IMPROVEMENT MASTER SCRIPT${NC}"
    echo "======================================"
    echo ""
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_warn "DRY RUN MODE - No files will be modified"
    fi
    
    # Check all scripts exist
    log_info "Checking required scripts..."
    local scripts=(
        "rename-spec-files.sh"
        "convert-links.sh"
        "restructure-spec.sh"
        "restructure-context.sh"
        "add-verification-docs.sh"
    )
    
    for script in "${scripts[@]}"; do
        if ! check_script "$script"; then
            log_error "Missing required script: $script"
            exit 1
        fi
    done
    log_success "All required scripts found"
    
    # Create backup
    if [[ "$BACKUP" == "true" ]]; then
        create_backup
    fi
    
    echo ""
    echo "======================================"
    echo "   PHASE 1: FILE RENAMING"
    echo "======================================"
    echo ""
    
    # Run rename script
    if ! run_script "rename-spec-files.sh" "Renaming spec and context files with hierarchy"; then
        log_error "Failed to rename files. Stopping."
        exit 1
    fi
    
    echo ""
    echo "======================================"
    echo "   PHASE 2: CONTENT TRANSFORMATION"
    echo "======================================"
    echo ""
    
    # Run content transformation scripts
    run_script "convert-links.sh" "Converting references to Markdown links"
    run_script "restructure-spec.sh" "Restructuring spec.md files"
    run_script "restructure-context.sh" "Restructuring context.md files"
    
    echo ""
    echo "======================================"
    echo "   PHASE 3: DOCUMENTATION ENHANCEMENT"
    echo "======================================"
    echo ""
    
    # Add verification documentation
    run_script "add-verification-docs.sh" "Adding verification documentation"
    
    # Show summary
    show_summary
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
        --no-backup)
            BACKUP=false
            shift
            ;;
        --help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Master orchestration script for spec improvements."
            echo "Runs all improvement scripts in the correct order."
            echo ""
            echo "Options:"
            echo "  --dry-run     Show what would be changed without modifying files"
            echo "  --verbose     Show verbose output from all scripts"
            echo "  --no-backup   Skip creating backup of specs directory"
            echo "  --help        Show this help message"
            echo ""
            echo "Scripts executed in order:"
            echo "  1. rename-spec-files.sh      - Add hierarchy to filenames"
            echo "  2. convert-links.sh          - Convert to Markdown links"
            echo "  3. restructure-spec.sh       - Move metadata to body"
            echo "  4. restructure-context.sh    - Standardize context format"
            echo "  5. add-verification-docs.sh  - Add verification docs"
            echo ""
            echo "Environment variables:"
            echo "  DRY_RUN=true    Same as --dry-run"
            echo "  VERBOSE=true    Same as --verbose"
            echo "  BACKUP=false    Same as --no-backup"
            echo ""
            echo "Examples:"
            echo "  # Dry run to see what would change"
            echo "  $0 --dry-run"
            echo ""
            echo "  # Apply all improvements"
            echo "  $0"
            echo ""
            echo "  # Apply with verbose output, no backup"
            echo "  $0 --verbose --no-backup"
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Check if we're in the right directory
if [[ ! -d "specs" ]]; then
    log_error "No 'specs' directory found. Are you in the project root?"
    exit 1
fi

# Run main function
main