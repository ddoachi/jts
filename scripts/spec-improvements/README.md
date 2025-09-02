# Spec Improvement Scripts

This directory contains scripts to improve and standardize the spec documentation system.

## Scripts Overview

### 1. `rename-spec-files.sh`
Renames spec.md and context.md files to include hierarchy strings.
- `spec.md` → `E01-F01-T01.spec.md`
- `context.md` → `E01-F01-T01.context.md`

### 2. `convert-links.sh`
Converts references to Markdown links:
- Commit hashes → `[hash](github.com/repo/commit/hash)`
- Issue/PR refs → `[#123: Title](github.com/repo/issues/123)`
- File paths → `[/path/file.ts](../relative/path/file.ts)`

### 3. `restructure-spec.sh`
Restructures spec.md files:
- Moves dependencies, blocks, related from YAML to body
- Removes pull_requests, commits, context_file from YAML
- Formats as Markdown links in appropriate sections

### 4. `restructure-context.sh`
Standardizes context.md format following E01-F03-T03 template:
- Adds link to related spec.md at top
- Formats GitHub issues as single Markdown link
- Structures with Implementation Timeline (YYYY-MM-DD HH:MM)
- Adds verification and acceptance criteria sections

### 5. `add-verification-docs.sh`
Adds verification documentation:
- Setup and execution instructions
- Manual verification steps
- Expected output examples
- Troubleshooting guidance
- Creates missing context files with verification template

### 6. `master-improvement.sh`
Orchestrates all improvements:
- Runs scripts in correct order
- Creates backup before modifications
- Provides progress feedback
- Shows comprehensive summary

## Usage

### Run All Improvements

```bash
# Dry run to preview changes
./master-improvement.sh --dry-run

# Apply all improvements
./master-improvement.sh

# Verbose mode with no backup
./master-improvement.sh --verbose --no-backup
```

### Run Individual Scripts

```bash
# Rename files (dry run)
DRY_RUN=true ./rename-spec-files.sh

# Convert to Markdown links
./convert-links.sh

# Restructure spec files
./restructure-spec.sh --verbose

# Restructure context files
./restructure-context.sh

# Add verification docs
./add-verification-docs.sh
```

## Options

All scripts support:
- `--dry-run`: Preview changes without modifying files
- `--verbose`: Show detailed output
- `--help`: Display usage information

Environment variables:
- `DRY_RUN=true`: Same as --dry-run
- `VERBOSE=true`: Same as --verbose

## Execution Order

The master script runs improvements in this order:

1. **Phase 1: File Renaming**
   - Rename spec.md and context.md files

2. **Phase 2: Content Transformation**
   - Convert references to Markdown links
   - Restructure spec.md files
   - Restructure context.md files

3. **Phase 3: Documentation Enhancement**
   - Add verification documentation

## Safety Features

- **Dry Run Mode**: Test changes before applying
- **Automatic Backup**: Creates timestamped backup of specs directory
- **Git Integration**: Commits changes at appropriate points
- **Error Handling**: Stops on critical errors

## Requirements

- Bash 4.0+
- Python 3 (for relative path calculations)
- Git (for commit tracking)
- GitHub CLI (optional, for issue titles)

## Examples

### Test Individual Script
```bash
# See what would be renamed
./rename-spec-files.sh --dry-run --verbose
```

### Apply All Changes
```bash
# Full execution with backup
./master-improvement.sh
```

### Custom Execution
```bash
# No backup, verbose output
BACKUP=false VERBOSE=true ./master-improvement.sh
```

## Verification

After running the scripts:

1. Review changes: `git diff --staged`
2. Test spec_work command with updated files
3. Update spec index: `/spec_work --update-index`
4. Verify all context files have proper structure
5. Check that all links are working correctly

## Troubleshooting

### Script Not Executable
```bash
chmod +x *.sh
```

### Python Not Found
Install Python 3 for relative path calculations.

### GitHub CLI Not Available
Install `gh` for automatic issue title fetching, or links will be created without titles.

## Notes

- Scripts are idempotent - safe to run multiple times
- Each script commits its changes separately
- Backup directory format: `specs.backup.YYYYMMDD-HHMMSS`
- All file paths converted to relative links from current file