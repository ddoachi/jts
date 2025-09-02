#!/bin/bash
# Automated Spec Structure Migration Script
# Migrates from current structure to new ID-based structure

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
OLD_SPECS_DIR="specs"
NEW_SPECS_DIR="specs_new"
BACKUP_DIR="specs_backup_$(date +%Y%m%d_%H%M%S)"

echo -e "${GREEN}=== Spec Structure Migration Tool ===${NC}"
echo "This script will migrate your specs to the new structure"
echo ""

# Step 1: Create backup
echo -e "${YELLOW}Step 1: Creating backup...${NC}"
if [ -d "$OLD_SPECS_DIR" ]; then
    cp -r "$OLD_SPECS_DIR" "$BACKUP_DIR"
    echo -e "${GREEN}✓ Backup created: $BACKUP_DIR${NC}"
else
    echo -e "${RED}✗ No specs directory found${NC}"
    exit 1
fi

# Step 2: Create new structure
echo -e "${YELLOW}Step 2: Creating new structure...${NC}"
rm -rf "$NEW_SPECS_DIR"
mkdir -p "$NEW_SPECS_DIR"

# Function to extract ID from filename
extract_id() {
    echo "$1" | grep -oE '^[0-9]+'
}

# Function to migrate epic
migrate_epic() {
    local epic_dir="$1"
    local epic_file="$2"
    local epic_id=$(extract_id "$(basename "$epic_dir")")
    
    echo "  Migrating epic $epic_id..."
    
    # Create epic directory
    mkdir -p "$NEW_SPECS_DIR/$epic_id"
    
    # Copy and rename epic spec
    if [ -f "$epic_file" ]; then
        cp "$epic_file" "$NEW_SPECS_DIR/$epic_id/epic.md"
        echo "    ✓ Epic spec migrated"
    fi
    
    # Migrate features within epic
    for feature_dir in "$epic_dir"/*/; do
        if [ -d "$feature_dir" ]; then
            migrate_feature "$epic_id" "$feature_dir"
        fi
    done
    
    # Migrate standalone feature files in epic dir
    for feature_file in "$epic_dir"/*-feature-*.spec.md; do
        if [ -f "$feature_file" ]; then
            local feature_id=$(extract_id "$(basename "$feature_file")")
            echo "    Migrating standalone feature $feature_id..."
            cp "$feature_file" "$NEW_SPECS_DIR/$epic_id/$feature_id.md"
        fi
    done
}

# Function to migrate feature
migrate_feature() {
    local epic_id="$1"
    local feature_dir="$2"
    local feature_id=$(extract_id "$(basename "$feature_dir")")
    
    echo "    Migrating feature $feature_id..."
    
    # Create feature directory
    mkdir -p "$NEW_SPECS_DIR/$epic_id/$feature_id"
    
    # Find and copy feature spec
    local feature_spec=$(find "$feature_dir" -name "${feature_id}-*feature*.spec.md" -type f | head -1)
    if [ -f "$feature_spec" ]; then
        cp "$feature_spec" "$NEW_SPECS_DIR/$epic_id/$feature_id/spec.md"
        echo "      ✓ Feature spec migrated"
    fi
    
    # Migrate tasks within feature
    for task_file in "$feature_dir"/*-task-*.spec.md; do
        if [ -f "$task_file" ]; then
            local task_id=$(extract_id "$(basename "$task_file")")
            echo "      Migrating task $task_id..."
            cp "$task_file" "$NEW_SPECS_DIR/$epic_id/$feature_id/$task_id.md"
        fi
    done
}

# Step 3: Process each epic
echo -e "${YELLOW}Step 3: Migrating specs...${NC}"
for epic_dir in "$OLD_SPECS_DIR"/*-epic-*/; do
    if [ -d "$epic_dir" ]; then
        # Find epic spec file
        epic_id=$(extract_id "$(basename "$epic_dir")")
        epic_spec=$(find "$epic_dir" -maxdepth 1 -name "${epic_id}*epic*.spec.md" -type f | head -1)
        migrate_epic "$epic_dir" "$epic_spec"
    fi
done

# Step 4: Migrate context files
echo -e "${YELLOW}Step 4: Migrating context files...${NC}"
if [ -d "context" ]; then
    for context_file in context/*.context.md; do
        if [ -f "$context_file" ]; then
            # Extract ID from filename
            filename=$(basename "$context_file")
            if [[ $filename =~ ([0-9]+).*\.context\.md ]]; then
                task_id="${BASH_REMATCH[1]}"
                
                # Find where this task belongs
                # Try to find in new structure
                task_location=$(find "$NEW_SPECS_DIR" -name "$task_id.md" -type f | head -1)
                if [ -f "$task_location" ]; then
                    task_dir=$(dirname "$task_location")
                    cp "$context_file" "$task_dir/$task_id.context.md"
                    echo "  ✓ Migrated context for task $task_id"
                fi
            fi
        fi
    done
fi

# Step 5: Update internal links
echo -e "${YELLOW}Step 5: Updating internal links...${NC}"

# Function to update links in a file
update_links() {
    local file="$1"
    
    # Update epic links
    sed -i -E 's/\[\[\.\.\/([0-9]+)-[^\/]*\/\1[^]]*\.spec\.md/[[..\/\1\/epic/g' "$file"
    
    # Update feature links
    sed -i -E 's/\[\[\.\.\/([0-9]+)-[^\/]*\/([0-9]+)[^]]*\.spec\.md/[[..\/\1\/\2\/spec/g' "$file"
    
    # Update task links
    sed -i -E 's/\[\[([0-9]+)-task-[^]]*\.spec\.md/[[\1/g' "$file"
    
    # Remove .spec.md extensions
    sed -i 's/\.spec\.md\]/\]/g' "$file"
    
    # Update standalone feature links
    sed -i -E 's/([0-9]+)-feature-[^]]*\.spec\.md/\1/g' "$file"
}

# Update all markdown files
find "$NEW_SPECS_DIR" -name "*.md" -type f | while read -r file; do
    update_links "$file"
    echo "  ✓ Updated links in $(basename "$file")"
done

# Step 6: Create index file
echo -e "${YELLOW}Step 6: Creating index file...${NC}"
cat > "$NEW_SPECS_DIR/index.md" << 'EOF'
# JTS Specification Index

## Epic Overview

EOF

# Generate index dynamically
for epic_dir in "$NEW_SPECS_DIR"/*/; do
    if [ -d "$epic_dir" ] && [[ $(basename "$epic_dir") =~ ^[0-9]+$ ]]; then
        epic_id=$(basename "$epic_dir")
        epic_title=$(grep -m1 "^# " "$epic_dir/epic.md" 2>/dev/null | sed 's/^# //' || echo "Epic $epic_id")
        echo "### [$epic_id - $epic_title]($epic_id/epic)" >> "$NEW_SPECS_DIR/index.md"
        
        # Add features
        for feature_item in "$epic_dir"/*; do
            if [ -d "$feature_item" ] && [[ $(basename "$feature_item") =~ ^[0-9]+$ ]]; then
                feature_id=$(basename "$feature_item")
                if [ -f "$feature_item/spec.md" ]; then
                    feature_title=$(grep -m1 "^# " "$feature_item/spec.md" 2>/dev/null | sed 's/^# //' || echo "Feature $feature_id")
                    echo "- [$feature_id - $feature_title]($epic_id/$feature_id/spec)" >> "$NEW_SPECS_DIR/index.md"
                fi
            elif [ -f "$feature_item" ] && [[ $(basename "$feature_item") =~ ^[0-9]+\.md$ ]]; then
                feature_id=$(basename "$feature_item" .md)
                feature_title=$(grep -m1 "^# " "$feature_item" 2>/dev/null | sed 's/^# //' || echo "Feature $feature_id")
                echo "- [$feature_id - $feature_title]($epic_id/$feature_id)" >> "$NEW_SPECS_DIR/index.md"
            fi
        done
        echo "" >> "$NEW_SPECS_DIR/index.md"
    fi
done

echo -e "${GREEN}✓ Index file created${NC}"

# Step 7: Generate migration report
echo -e "${YELLOW}Step 7: Generating migration report...${NC}"
cat > "migration-report.md" << EOF
# Migration Report - $(date)

## Statistics
- Epics migrated: $(find "$NEW_SPECS_DIR" -maxdepth 1 -type d -regex '.*/[0-9]+' | wc -l)
- Features migrated: $(find "$NEW_SPECS_DIR" -name "spec.md" -type f | wc -l)
- Tasks migrated: $(find "$NEW_SPECS_DIR" -regex '.*/[0-9]+\.md' -type f | grep -v epic.md | grep -v spec.md | wc -l)
- Context files migrated: $(find "$NEW_SPECS_DIR" -name "*.context.md" -type f | wc -l)

## Backup Location
$BACKUP_DIR

## Next Steps
1. Review the migrated structure in $NEW_SPECS_DIR
2. Test navigation and links
3. If satisfied, run: mv specs specs_old && mv $NEW_SPECS_DIR specs
4. If issues found, restore from: cp -r $BACKUP_DIR specs
EOF

echo -e "${GREEN}✓ Migration report created${NC}"

# Final summary
echo ""
echo -e "${GREEN}=== Migration Complete ===${NC}"
echo "New structure created in: $NEW_SPECS_DIR"
echo "Backup saved in: $BACKUP_DIR"
echo "Report saved in: migration-report.md"
echo ""
echo "To apply the migration:"
echo "  mv specs specs_old && mv $NEW_SPECS_DIR specs"
echo ""
echo "To rollback:"
echo "  cp -r $BACKUP_DIR specs"