# Spec Workflow Documentation

This folder contains all documentation and tools related to the specification workflow system.

## Documentation

### Core System Documentation
- [Spec Workflow System](docs/spec-workflow-system.md) - Complete workflow system design
- [Folder Migration Guide](docs/spec-folder-migration.md) - Guide for migrating to new structure
- [Workflow Examples](docs/spec-workflow-example.md) - Practical examples of the workflow

## Tools and Scripts

### Migration Scripts
- [Python Migration Tool](scripts/migrate-specs-structure.py) - Advanced migration with link handling
- [Shell Migration Tool](scripts/migrate-specs-structure.sh) - Simple bash migration script

### Dashboard and Monitoring  
- [Spec Dashboard](scripts/spec-dashboard.sh) - Live progress dashboard for separate terminal

## Usage

### Running the Dashboard
```bash
# Open in separate terminal for live monitoring
./specs/workflow/scripts/spec-dashboard.sh
```

### Using Migration Tools
```bash
# Run Python migration tool (recommended)
python3 specs/workflow/scripts/migrate-specs-structure.py

# Or use shell script
./specs/workflow/scripts/migrate-specs-structure.sh
```

### Commands Available
- `/spec_work {spec-id}` - Start working on a spec
- `/spec_work --dashboard` - Show interactive dashboard
- `/spec_work --update-index` - Update index.md with latest stats
- `/spec_work {spec-id} --split features` - Split epic into features

## File Structure

```
specs/workflow/
├── README.md                           # This file
├── docs/                              # Documentation
│   ├── spec-workflow-system.md        # Core system design
│   ├── spec-folder-migration.md       # Migration guide
│   └── spec-workflow-example.md       # Usage examples
└── scripts/                          # Automation tools
    ├── migrate-specs-structure.py    # Python migration tool
    ├── migrate-specs-structure.sh    # Shell migration tool
    └── spec-dashboard.sh             # Live dashboard
```

This workflow system provides complete traceability, mobile-friendly navigation, and motivational progress tracking for all specification work.