# Spec Folder Structure Migration Guide

## Current Structure Problems

### 1. Redundant Naming
```
specs/1001-feature-storage-infrastructure/
└── 1001-feature-storage-infrastructure.spec.md  ← Repetitive!
```

### 2. Long Paths
```
specs/1000-epic-foundation-infrastructure/1001-feature-storage-infrastructure/1014-task-cold-storage-nas.spec.md
```
Total: 115 characters!

### 3. Unclear Hierarchy
- Mixing epic folders with feature files
- Sub-specs buried in feature folders
- No clear separation of deliverables

## Proposed New Structure

### Design Principles
1. **Shorter paths** - Use IDs as folder names
2. **Clear hierarchy** - Epic → Feature → Task
3. **Co-located assets** - Keep deliverables with specs
4. **Consistent naming** - Always `spec.md` and `context.md`

### New Folder Layout

```
specs/
├── 1000/                              # Epic: Foundation Infrastructure
│   ├── epic.md                        # Epic spec (was: 1000-epic-*.spec.md)
│   ├── context.md                     # Epic-level context
│   ├── README.md                      # Epic overview and navigation
│   │
│   ├── 1001/                          # Feature: Storage Infrastructure
│   │   ├── spec.md                    # Feature spec
│   │   ├── context.md                 # Feature implementation context
│   │   ├── 1011.md                    # Task: Hot Storage (inline)
│   │   ├── 1011.context.md            # Task context
│   │   ├── 1012.md                    # Task: Database Mount
│   │   ├── 1013.md                    # Task: Warm Storage
│   │   ├── 1014.md                    # Task: Cold Storage
│   │   ├── 1014.context.md            # Cold Storage context
│   │   │
│   │   └── deliverables/              # Feature deliverables
│   │       ├── scripts/
│   │       │   ├── nas-setup.sh
│   │       │   └── health-check.sh
│   │       ├── docs/
│   │       │   └── storage-guide.md
│   │       └── config/
│   │           └── fstab.example
│   │
│   ├── 1002/                          # Feature: Development Environment
│   │   ├── spec.md
│   │   ├── context.md
│   │   └── deliverables/
│   │
│   └── 1003/                          # Feature: Monorepo Structure
│       ├── spec.md
│       └── context.md
│
├── 2000/                              # Epic: Broker Integration
│   ├── epic.md
│   ├── context.md
│   ├── 2100.md                        # Feature specs at epic level
│   ├── 2101.md                        # (for simpler epics)
│   └── 2102.md
│
└── index.md                           # Master spec index
```

### Path Comparison

| Content | Old Path | New Path | Savings |
|---------|----------|----------|---------|
| Epic spec | `1000-epic-foundation-infrastructure/1000-epic-foundation-infrastructure.spec.md` | `1000/epic.md` | 75 chars |
| Feature spec | `1000-epic-foundation-infrastructure/1001-feature-storage-infrastructure/1001-feature-storage-infrastructure.spec.md` | `1000/1001/spec.md` | 98 chars |
| Task spec | `1000-epic-foundation-infrastructure/1001-feature-storage-infrastructure/1014-task-cold-storage-nas.spec.md` | `1000/1001/1014.md` | 91 chars |

## File Naming Conventions

### Standard Files
- `epic.md` - Epic-level specifications
- `spec.md` - Feature-level specifications  
- `context.md` - Implementation context/journal
- `README.md` - Navigation and overview
- `{id}.md` - Task-level specifications (e.g., `1014.md`)

### Benefits
- Shorter, cleaner paths
- No redundant information
- Consistent naming pattern
- Easy to understand hierarchy

## Migration Script

```bash
#!/bin/bash
# migrate-specs.sh - Migrate to new spec structure

# Create new structure
echo "Creating new spec structure..."

# Migrate Epic 1000
mkdir -p specs_new/1000
mv specs/1000-epic-foundation-infrastructure/1000-epic-foundation-infrastructure.spec.md \
   specs_new/1000/epic.md

# Migrate Features
for feature in specs/1000-epic-foundation-infrastructure/100*/; do
  if [[ -d "$feature" ]]; then
    feature_id=$(basename "$feature" | cut -d'-' -f1)
    mkdir -p "specs_new/1000/$feature_id"
    
    # Move feature spec
    mv "$feature/${feature_id}-*.spec.md" \
       "specs_new/1000/$feature_id/spec.md"
    
    # Move task specs
    for task in "$feature"/10*.spec.md; do
      if [[ -f "$task" ]]; then
        task_id=$(basename "$task" | cut -d'-' -f1)
        mv "$task" "specs_new/1000/$feature_id/${task_id}.md"
      fi
    done
  fi
done

# Update internal links
echo "Updating internal links..."
find specs_new -name "*.md" -exec sed -i \
  -e 's/\[\[.*\/\([0-9]\+\)-[^]]*\.spec\.md/[[\1\/spec/g' \
  -e 's/\.spec\.md/\.md/g' {} \;

echo "Migration complete!"
```

## Link Update Examples

### Before
```markdown
[[../1001-feature-storage-infrastructure/1001-feature-storage-infrastructure.spec.md|Storage Infrastructure]]
[[1014-task-cold-storage-nas.spec.md|Cold Storage Task]]
```

### After  
```markdown
[[../1001/spec|Storage Infrastructure]]
[[1014|Cold Storage Task]]
```

## Index File Structure

Create `specs/index.md` for navigation:

```markdown
# JTS Specification Index

## Epic Overview

### [1000 - Foundation Infrastructure](1000/epic)
- [1001 - Storage Infrastructure](1000/1001/spec)
  - [1011 - Hot Storage NVMe](1000/1001/1011)
  - [1012 - Database Mount](1000/1001/1012)
  - [1013 - Warm Storage SATA](1000/1001/1013)
  - [1014 - Cold Storage NAS](1000/1001/1014)
- [1002 - Development Environment](1000/1002/spec)
- [1003 - Monorepo Structure](1000/1003/spec)

### [2000 - Broker Integration](2000/epic)
- [2100 - Unified Broker Interface](2000/2100)
- [2101 - KIS REST API](2000/2101)
- [2102 - KIS WebSocket](2000/2102)

## Implementation Status

### In Progress
- [[1000/1001/context|Storage Infrastructure]] - 71% complete
- [[2000/context|Broker Integration]] - Planning phase

### Completed
- [[1000/1001/1014.context|Cold Storage NAS]] ✅

### Blocked
- None

## Recent Updates
- 2025-08-26: Cold Storage NAS implementation completed
- 2025-08-25: Broker Integration epic split into features
- 2025-08-24: Foundation Infrastructure restructured
```

## Advantages of New Structure

### 1. Shorter Paths
- Average path length reduced by 60%
- Easier to type and remember
- Better for command-line usage

### 2. Clear Hierarchy
```
Epic (1000/) → Feature (1001/) → Task (1014.md)
```
- Instantly understand relationships
- Natural navigation pattern
- Consistent at all levels

### 3. Co-located Deliverables
- Scripts, docs, configs in `deliverables/`
- No more searching across project
- Clear ownership of artifacts

### 4. Simplified Naming
- No redundant prefixes
- Standard file names (`spec.md`, `context.md`)
- IDs only where needed

### 5. Better Organization
- Related files grouped together
- Context files adjacent to specs
- Deliverables with their source

## Migration Timeline

### Phase 1: Setup (Day 1)
1. Create migration script
2. Test on small subset
3. Backup current structure

### Phase 2: Migration (Day 2)
1. Run migration script
2. Update all internal links
3. Verify file integrity

### Phase 3: Validation (Day 3)
1. Test all links work
2. Update documentation
3. Update commands/tools

### Phase 4: Cleanup (Day 4)
1. Archive old structure
2. Update team documentation
3. Communicate changes

## Rollback Plan

If issues arise:
```bash
# Restore from backup
mv specs specs_failed
mv specs_backup specs

# Or use git
git checkout -- specs/
```

## Summary

The new structure provides:
- **60% shorter paths** on average
- **Clearer hierarchy** with consistent naming
- **Co-located deliverables** for better organization
- **Simplified navigation** with standard file names
- **Better scalability** for large projects

This migration will make the spec system more maintainable and user-friendly, especially for mobile review and command-line usage.