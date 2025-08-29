#!/usr/bin/env python3
"""
Migrate spec structure from numeric IDs to type-prefixed IDs with unique identifiers.

Migration changes:
- 1000/1001/1013.md → E01/F01/T03/spec.md
- Adds unique_id field to each spec
- Updates all internal references
- Creates backup before migration
"""

import os
import re
import shutil
import yaml
import json
import hashlib
import time
from pathlib import Path
from typing import Dict, List, Tuple, Optional
from datetime import datetime

# Configuration
SPECS_DIR = Path("specs")
BACKUP_DIR = Path(f"specs_backup_{datetime.now().strftime('%Y%m%d_%H%M%S')}")
MIGRATION_LOG = Path("migration_log.json")

# Type prefixes
TYPE_PREFIXES = {
    "epic": "E",
    "feature": "F", 
    "task": "T",
    "subtask": "S",
    "bug": "B",
    "spike": "K"
}

class SpecMigrator:
    def __init__(self):
        self.spec_map = {}  # old_id -> new_id mapping
        self.unique_ids = {}  # old_id -> unique_id mapping
        self.specs_data = {}  # old_id -> spec metadata
        self.migration_log = []
        
    def generate_short_uuid(self, seed: str = None) -> str:
        """Generate a short 8-character UUID."""
        if seed:
            # Use seed for deterministic generation (useful for testing)
            hash_obj = hashlib.md5(seed.encode())
        else:
            # Use time-based randomness
            hash_obj = hashlib.md5(f"{time.time()}{os.urandom(8).hex()}".encode())
        return hash_obj.hexdigest()[:8]
    
    def parse_yaml_frontmatter(self, content: str) -> Tuple[dict, str]:
        """Parse YAML frontmatter from markdown content."""
        if not content.startswith('---'):
            return {}, content
            
        try:
            # Find the closing ---
            end_match = re.search(r'\n---\n', content[3:])
            if not end_match:
                return {}, content
                
            yaml_content = content[3:end_match.start() + 3]
            body_content = content[end_match.end() + 3:]
            
            # Simple approach: just remove inline comments after values
            yaml_lines = []
            for line in yaml_content.split('\n'):
                # Skip pure comment lines
                if line.strip().startswith('#'):
                    continue
                    
                # For lines with values and comments, keep everything before the comment
                # But be careful with # inside strings
                if '#' in line:
                    # Simple heuristic: if the line has quotes, keep everything
                    if '"#' in line or "'#" in line:
                        yaml_lines.append(line)
                    else:
                        # Remove comment at end of line
                        parts = line.split('#', 1)
                        yaml_lines.append(parts[0].rstrip())
                else:
                    yaml_lines.append(line)
                    
            metadata = yaml.safe_load('\n'.join(yaml_lines))
            return metadata or {}, body_content
            
        except yaml.YAMLError as e:
            # For debugging - show which file failed
            print(f"YAML Error: {e}")
            # Try without any comment processing
            try:
                # Just extract the raw YAML without comment processing
                raw_yaml = yaml_content.replace('# ', '@ ').replace('#', '')
                metadata = yaml.safe_load(raw_yaml)
                return metadata or {}, body_content
            except:
                return {}, content
        except Exception as e:
            print(f"Unexpected error parsing YAML: {e}")
            return {}, content
    
    def load_all_specs(self):
        """Load all spec files and build the mapping."""
        print("Loading all specs...")
        
        # Find all spec files - include both .spec.md and regular .md files
        spec_files = list(SPECS_DIR.glob("**/*.md"))
        # Filter out non-spec files
        spec_files = [f for f in spec_files 
                     if 'deliverables' not in str(f) 
                     and 'workflow' not in str(f)
                     and 'context' not in f.name
                     and 'README' not in f.name]
        
        for spec_file in spec_files:
            # Read and parse the file
            try:
                content = spec_file.read_text(encoding='utf-8')
                metadata, body = self.parse_yaml_frontmatter(content)
                
                if metadata and 'id' in metadata:
                    old_id = str(metadata['id'])
                    spec_type = metadata.get('type', 'task')
                    
                    # Store spec data
                    self.specs_data[old_id] = {
                        'metadata': metadata,
                        'body': body,
                        'file_path': spec_file,
                        'type': spec_type
                    }
                    
                    # Generate unique ID
                    self.unique_ids[old_id] = self.generate_short_uuid(old_id)
            except Exception as e:
                print(f"Warning: Could not process {spec_file}: {e}")
                continue
                
        print(f"Loaded {len(self.specs_data)} specs")
        
    def build_hierarchy_map(self):
        """Build the new ID mapping based on hierarchy."""
        print("Building hierarchy map...")
        
        # Debug: Print all loaded IDs and types
        print(f"Debug: Loaded specs: {sorted(self.specs_data.keys())}")
        
        # Group specs by type and parent
        epics = {}
        features_by_parent = {}
        tasks_by_parent = {}
        subtasks_by_parent = {}
        
        for old_id, spec_info in self.specs_data.items():
            metadata = spec_info['metadata']
            spec_type = spec_info['type']
            parent = str(metadata.get('parent', '')) if metadata.get('parent') else ''
            
            if spec_type == 'epic':
                epics[old_id] = metadata
            elif spec_type == 'feature':
                if parent not in features_by_parent:
                    features_by_parent[parent] = []
                features_by_parent[parent].append(old_id)
            elif spec_type == 'task':
                if parent not in tasks_by_parent:
                    tasks_by_parent[parent] = []
                tasks_by_parent[parent].append(old_id)
            elif spec_type == 'subtask':
                if parent not in subtasks_by_parent:
                    subtasks_by_parent[parent] = []
                subtasks_by_parent[parent].append(old_id)
        
        # Debug: Print groupings
        print(f"Debug: Epics found: {list(epics.keys())}")
        print(f"Debug: Features by parent: {[(p, len(f)) for p, f in features_by_parent.items()]}")
        print(f"Debug: Tasks by parent: {[(p, len(t)) for p, t in tasks_by_parent.items()]}")
        
        # Sort for consistent numbering
        epic_ids = sorted(epics.keys(), key=lambda x: int(x) if x.isdigit() else 0)
        
        # Assign new IDs
        epic_counter = 1
        for epic_id in epic_ids:
            new_epic_id = f"E{epic_counter:02d}"
            self.spec_map[epic_id] = new_epic_id
            epic_counter += 1
            
            # Process features under this epic
            if epic_id in features_by_parent:
                feature_ids = sorted(features_by_parent[epic_id], 
                                   key=lambda x: int(x) if x.isdigit() else 0)
                feature_counter = 1
                for feature_id in feature_ids:
                    new_feature_id = f"F{feature_counter:02d}"
                    self.spec_map[feature_id] = new_feature_id
                    feature_counter += 1
                    
                    # Process tasks under this feature
                    if feature_id in tasks_by_parent:
                        task_ids = sorted(tasks_by_parent[feature_id],
                                        key=lambda x: int(x) if x.isdigit() else 0)
                        task_counter = 1
                        for task_id in task_ids:
                            new_task_id = f"T{task_counter:02d}"
                            self.spec_map[task_id] = new_task_id
                            task_counter += 1
                            
                            # Process subtasks under this task
                            if task_id in subtasks_by_parent:
                                subtask_ids = sorted(subtasks_by_parent[task_id],
                                                   key=lambda x: int(x) if x.isdigit() else 0)
                                subtask_counter = 1
                                for subtask_id in subtask_ids:
                                    new_subtask_id = f"S{subtask_counter:02d}"
                                    self.spec_map[subtask_id] = new_subtask_id
                                    subtask_counter += 1
        
        # Handle any orphaned specs
        for old_id in self.specs_data:
            if old_id not in self.spec_map:
                spec_type = self.specs_data[old_id]['type']
                prefix = TYPE_PREFIXES.get(spec_type, 'T')
                # Use high numbers for orphaned specs
                self.spec_map[old_id] = f"{prefix}99_{old_id}"
                
        print(f"Mapped {len(self.spec_map)} spec IDs")
        
    def get_new_path(self, old_id: str) -> Path:
        """Get the new file path for a spec."""
        spec_info = self.specs_data[old_id]
        metadata = spec_info['metadata']
        parent = metadata.get('parent', '')
        
        # Build path based on hierarchy
        path_parts = ['specs']
        
        # Walk up the hierarchy to build the full path
        current_id = old_id
        hierarchy = []
        
        while current_id:
            hierarchy.insert(0, self.spec_map[current_id])
            parent_id = self.specs_data[current_id]['metadata'].get('parent', '')
            if parent_id and parent_id in self.specs_data:
                current_id = parent_id
            else:
                break
        
        path_parts.extend(hierarchy)
        return Path(*path_parts)
    
    def update_spec_content(self, old_id: str) -> str:
        """Update spec content with new IDs and references."""
        spec_info = self.specs_data[old_id]
        metadata = spec_info['metadata'].copy()
        body = spec_info['body']
        
        # Update ID to unique short UUID (remove unique_id field if it exists)
        if 'unique_id' in metadata:
            del metadata['unique_id']
        metadata['id'] = self.unique_ids[old_id]
        
        # Update parent reference
        if 'parent' in metadata and metadata['parent']:
            old_parent = metadata['parent']
            if old_parent in self.spec_map:
                metadata['parent'] = self.spec_map[old_parent]
        
        # Update children references
        if 'children' in metadata and metadata['children']:
            new_children = []
            for child in metadata['children']:
                if str(child) in self.spec_map:
                    new_children.append(self.spec_map[str(child)])
            metadata['children'] = new_children
        
        # Update epic reference
        if 'epic' in metadata and metadata['epic']:
            old_epic = str(metadata['epic'])
            if old_epic in self.spec_map:
                metadata['epic'] = self.spec_map[old_epic]
        
        # Update dependencies
        for field in ['dependencies', 'blocks', 'related']:
            if field in metadata and metadata[field]:
                new_refs = []
                for ref in metadata[field]:
                    ref_str = str(ref)
                    if ref_str in self.spec_map:
                        new_refs.append(self.spec_map[ref_str])
                metadata[field] = new_refs
        
        # Update references in body content
        for old_ref, new_ref in self.spec_map.items():
            # Update spec references like "1013" or "Feature 1013"
            body = re.sub(rf'\b{old_ref}\b(?!\.md)', new_ref, body)
            # Update file references like "1013.md"
            body = body.replace(f'{old_ref}.md', f'{new_ref}/spec.md')
        
        # Rebuild the markdown with updated frontmatter
        yaml_content = yaml.dump(metadata, default_flow_style=False, sort_keys=False)
        
        # Add comments back to maintain structure
        yaml_lines = yaml_content.split('\n')
        formatted_yaml = ['---']
        formatted_yaml.append('# ============================================================================')
        formatted_yaml.append('# SPEC METADATA - This entire frontmatter section contains the spec metadata')
        formatted_yaml.append('# ============================================================================')
        formatted_yaml.append('')
        formatted_yaml.append('# === IDENTIFICATION ===')
        
        # Process YAML lines and add section headers
        current_section = 'identification'
        for line in yaml_lines:
            if line.startswith('id:'):
                formatted_yaml.append(f"{line} # Unique identifier (never changes)")
            elif line.startswith('parent:'):
                if current_section != 'hierarchy':
                    formatted_yaml.append('')
                    formatted_yaml.append('# === HIERARCHY ===')
                    current_section = 'hierarchy'
                formatted_yaml.append(line)
            elif line.startswith('status:'):
                if current_section != 'workflow':
                    formatted_yaml.append('')
                    formatted_yaml.append('# === WORKFLOW ===')
                    current_section = 'workflow'
                formatted_yaml.append(line)
            elif line.startswith('created:'):
                if current_section != 'tracking':
                    formatted_yaml.append('')
                    formatted_yaml.append('# === TRACKING ===')
                    current_section = 'tracking'
                formatted_yaml.append(line)
            elif line.startswith('dependencies:'):
                if current_section != 'dependencies':
                    formatted_yaml.append('')
                    formatted_yaml.append('# === DEPENDENCIES ===')
                    current_section = 'dependencies'
                formatted_yaml.append(line)
            elif line.startswith('pull_requests:'):
                if current_section != 'implementation':
                    formatted_yaml.append('')
                    formatted_yaml.append('# === IMPLEMENTATION ===')
                    current_section = 'implementation'
                formatted_yaml.append(line)
            elif line.startswith('tags:'):
                if current_section != 'metadata':
                    formatted_yaml.append('')
                    formatted_yaml.append('# === METADATA ===')
                    current_section = 'metadata'
                formatted_yaml.append(line)
            else:
                formatted_yaml.append(line)
        
        formatted_yaml.append('---')
        
        return '\n'.join(formatted_yaml) + '\n' + body
    
    def migrate_context_files(self):
        """Migrate context files to new structure."""
        print("Migrating context files...")
        
        context_files = list(SPECS_DIR.glob("**/*.context.md"))
        
        for context_file in context_files:
            # Extract the ID from filename (e.g., "1013.context.md" -> "1013")
            match = re.match(r'(\d+)\.context\.md', context_file.name)
            if match:
                old_id = match.group(1)
                if old_id in self.spec_map:
                    new_path = self.get_new_path(old_id)
                    new_context_path = new_path / "context.md"
                    
                    # Create directory if needed
                    new_context_path.parent.mkdir(parents=True, exist_ok=True)
                    
                    # Copy context file
                    content = context_file.read_text(encoding='utf-8')
                    
                    # Update any references in context file
                    for old_ref, new_ref in self.spec_map.items():
                        content = re.sub(rf'\b{old_ref}\b', new_ref, content)
                    
                    new_context_path.write_text(content, encoding='utf-8')
                    
                    self.migration_log.append({
                        'type': 'context',
                        'old_path': str(context_file),
                        'new_path': str(new_context_path)
                    })
    
    def create_backup(self):
        """Create backup of current specs directory."""
        print(f"Creating backup at {BACKUP_DIR}...")
        if BACKUP_DIR.exists():
            shutil.rmtree(BACKUP_DIR)
        shutil.copytree(SPECS_DIR, BACKUP_DIR)
        print("Backup created successfully")
    
    def perform_migration(self):
        """Perform the actual migration."""
        print("Starting migration...")
        
        # Create new directory structure and migrate specs
        migrated_specs = set()
        
        for old_id, spec_info in self.specs_data.items():
            new_path = self.get_new_path(old_id)
            spec_path = new_path / "spec.md"
            
            # Create directory
            spec_path.parent.mkdir(parents=True, exist_ok=True)
            
            # Write updated spec content
            new_content = self.update_spec_content(old_id)
            spec_path.write_text(new_content, encoding='utf-8')
            
            migrated_specs.add(str(spec_info['file_path']))
            
            self.migration_log.append({
                'type': 'spec',
                'old_id': old_id,
                'new_id': self.spec_map[old_id],
                'unique_id': self.unique_ids[old_id],
                'old_path': str(spec_info['file_path']),
                'new_path': str(spec_path)
            })
            
            print(f"Migrated {old_id} -> {self.spec_map[old_id]} ({spec_path})")
        
        # Migrate context files
        self.migrate_context_files()
        
        # Clean up old files
        print("Cleaning up old structure...")
        for old_id, spec_info in self.specs_data.items():
            old_file = spec_info['file_path']
            if old_file.exists():
                old_file.unlink()
        
        # Remove empty directories
        for dir_path in sorted(SPECS_DIR.rglob("*"), reverse=True):
            if dir_path.is_dir() and not any(dir_path.iterdir()):
                dir_path.rmdir()
        
        print(f"Migration completed! Migrated {len(migrated_specs)} specs")
    
    def save_migration_log(self):
        """Save migration log for reference."""
        log_data = {
            'timestamp': datetime.now().isoformat(),
            'backup_dir': str(BACKUP_DIR),
            'spec_mappings': self.spec_map,
            'unique_ids': self.unique_ids,
            'migrations': self.migration_log
        }
        
        with open(MIGRATION_LOG, 'w') as f:
            json.dump(log_data, f, indent=2)
        
        print(f"Migration log saved to {MIGRATION_LOG}")
    
    def create_rollback_script(self):
        """Create a rollback script."""
        rollback_script = f'''#!/bin/bash
# Rollback script for spec migration
# Generated: {datetime.now().isoformat()}

echo "Rolling back spec migration..."

# Remove new structure
rm -rf specs/

# Restore backup
cp -r {BACKUP_DIR}/ specs/

echo "Rollback complete!"
echo "Original structure restored from {BACKUP_DIR}"
'''
        
        rollback_path = Path("rollback_migration.sh")
        rollback_path.write_text(rollback_script)
        rollback_path.chmod(0o755)
        
        print(f"Rollback script created: {rollback_path}")
    
    def run(self):
        """Run the complete migration process."""
        print("=" * 60)
        print("SPEC STRUCTURE MIGRATION")
        print("=" * 60)
        
        # Step 1: Create backup
        self.create_backup()
        
        # Step 2: Load all specs
        self.load_all_specs()
        
        # Step 3: Build hierarchy map
        self.build_hierarchy_map()
        
        # Step 4: Perform migration
        self.perform_migration()
        
        # Step 5: Save migration log
        self.save_migration_log()
        
        # Step 6: Create rollback script
        self.create_rollback_script()
        
        print("=" * 60)
        print("MIGRATION COMPLETE!")
        print(f"Backup saved to: {BACKUP_DIR}")
        print(f"Migration log: {MIGRATION_LOG}")
        print("To rollback, run: ./rollback_migration.sh")
        print("=" * 60)


def main():
    import sys
    
    # Check if we're in the right directory
    if not SPECS_DIR.exists():
        print("Error: 'specs' directory not found.")
        print("Please run this script from the project root directory.")
        return 1
    
    # Check for --force flag
    if '--force' not in sys.argv:
        # Confirm migration
        print("This will migrate your spec structure from numeric IDs to type-prefixed IDs.")
        print(f"A backup will be created at: {BACKUP_DIR}")
        print("Run with --force to skip confirmation")
        
        try:
            response = input("Do you want to proceed? (yes/no): ")
            if response.lower() != 'yes':
                print("Migration cancelled.")
                return 0
        except EOFError:
            print("\nNo input provided. Run with --force to skip confirmation.")
            return 1
    else:
        print("Running migration with --force flag...")
    
    # Run migration
    migrator = SpecMigrator()
    migrator.run()
    
    return 0


if __name__ == "__main__":
    exit(main())