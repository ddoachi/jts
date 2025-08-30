#!/usr/bin/env python3
"""
Automated Spec Structure Migration Tool
Migrates specs from verbose structure to ID-based structure
"""

import os
import re
import shutil
import json
from pathlib import Path
from datetime import datetime
from typing import Dict, List, Tuple

class SpecMigration:
    def __init__(self, source_dir="specs", target_dir="specs_new"):
        self.source_dir = Path(source_dir)
        self.target_dir = Path(target_dir)
        self.backup_dir = Path(f"specs_backup_{datetime.now().strftime('%Y%m%d_%H%M%S')}")
        self.context_dir = Path("context")
        self.plan_dir = Path("plan")
        self.migration_log = []
        self.link_mappings = {}
        
    def run(self):
        """Execute full migration"""
        print("🚀 Starting Spec Migration")
        
        # Step 1: Backup
        self.create_backup()
        
        # Step 2: Analyze structure
        structure = self.analyze_structure()
        
        # Step 3: Create new structure
        self.create_new_structure(structure)
        
        # Step 4: Migrate context files
        self.migrate_context_files()
        
        # Step 5: Update all links
        self.update_all_links()
        
        # Step 6: Create index
        self.create_index()
        
        # Step 7: Generate report
        self.generate_report()
        
        print("✅ Migration Complete!")
        print(f"   New structure: {self.target_dir}")
        print(f"   Backup: {self.backup_dir}")
        
    def create_backup(self):
        """Create backup of current specs"""
        print("📦 Creating backup...")
        if self.source_dir.exists():
            shutil.copytree(self.source_dir, self.backup_dir)
            print(f"   ✓ Backup created: {self.backup_dir}")
        else:
            raise Exception(f"Source directory {self.source_dir} not found")
    
    def analyze_structure(self) -> Dict:
        """Analyze current spec structure"""
        print("🔍 Analyzing current structure...")
        structure = {
            'epics': {},
            'standalone_features': [],
            'orphaned_tasks': []
        }
        
        # Find all epic directories
        for epic_dir in self.source_dir.glob("*-epic-*/"):
            epic_id = self.extract_id(epic_dir.name)
            epic_spec = self.find_spec_file(epic_dir, 'epic')
            
            structure['epics'][epic_id] = {
                'path': epic_dir,
                'spec': epic_spec,
                'features': {},
                'standalone_features': []
            }
            
            # Find features within epic
            for feature_dir in epic_dir.glob("*-feature-*/"):
                feature_id = self.extract_id(feature_dir.name)
                feature_spec = self.find_spec_file(feature_dir, 'feature')
                
                structure['epics'][epic_id]['features'][feature_id] = {
                    'path': feature_dir,
                    'spec': feature_spec,
                    'tasks': []
                }
                
                # Find tasks within feature
                for task_file in feature_dir.glob("*-task-*.spec.md"):
                    task_id = self.extract_id(task_file.name)
                    structure['epics'][epic_id]['features'][feature_id]['tasks'].append({
                        'id': task_id,
                        'path': task_file
                    })
            
            # Find standalone features in epic dir
            for feature_file in epic_dir.glob("*-feature-*.spec.md"):
                if feature_file.is_file():
                    feature_id = self.extract_id(feature_file.name)
                    structure['epics'][epic_id]['standalone_features'].append({
                        'id': feature_id,
                        'path': feature_file
                    })
        
        print(f"   ✓ Found {len(structure['epics'])} epics")
        return structure
    
    def create_new_structure(self, structure: Dict):
        """Create new directory structure and copy files"""
        print("🏗️  Creating new structure...")
        
        # Clean target directory
        if self.target_dir.exists():
            shutil.rmtree(self.target_dir)
        self.target_dir.mkdir()
        
        # Process each epic
        for epic_id, epic_data in structure['epics'].items():
            epic_new_dir = self.target_dir / str(epic_id)
            epic_new_dir.mkdir()
            
            # Copy epic spec
            if epic_data['spec']:
                old_path = epic_data['spec']
                new_path = epic_new_dir / "epic.md"
                shutil.copy2(old_path, new_path)
                self.link_mappings[str(old_path)] = str(new_path)
                self.migration_log.append(f"Epic {epic_id}: {old_path} → {new_path}")
            
            # Process features
            for feature_id, feature_data in epic_data['features'].items():
                feature_new_dir = epic_new_dir / str(feature_id)
                feature_new_dir.mkdir()
                
                # Copy feature spec
                if feature_data['spec']:
                    old_path = feature_data['spec']
                    new_path = feature_new_dir / "spec.md"
                    shutil.copy2(old_path, new_path)
                    self.link_mappings[str(old_path)] = str(new_path)
                    self.migration_log.append(f"Feature {feature_id}: {old_path} → {new_path}")
                
                # Copy tasks
                for task in feature_data['tasks']:
                    old_path = task['path']
                    new_path = feature_new_dir / f"{task['id']}.md"
                    shutil.copy2(old_path, new_path)
                    self.link_mappings[str(old_path)] = str(new_path)
                    self.migration_log.append(f"Task {task['id']}: {old_path} → {new_path}")
            
            # Process standalone features
            for feature in epic_data['standalone_features']:
                old_path = feature['path']
                new_path = epic_new_dir / f"{feature['id']}.md"
                shutil.copy2(old_path, new_path)
                self.link_mappings[str(old_path)] = str(new_path)
                self.migration_log.append(f"Standalone Feature {feature['id']}: {old_path} → {new_path}")
        
        print(f"   ✓ Migrated {len(self.migration_log)} files")
    
    def migrate_context_files(self):
        """Migrate context and plan files to new structure"""
        print("📋 Migrating context files...")
        migrated = 0
        
        # Migrate from context/ directory
        if self.context_dir.exists():
            for context_file in self.context_dir.glob("*.context.md"):
                migrated += self.migrate_single_context(context_file)
        
        # Migrate from plan/ directory  
        if self.plan_dir.exists():
            for plan_file in self.plan_dir.glob("*.context.md"):
                migrated += self.migrate_single_context(plan_file)
        
        print(f"   ✓ Migrated {migrated} context files")
    
    def migrate_single_context(self, context_file: Path) -> int:
        """Migrate a single context file to appropriate location"""
        # Extract ID from filename (e.g., "2025-08-25.1014-task-cold-storage.context.md")
        match = re.search(r'\.(\d{4})[^\d]', context_file.name)
        if match:
            task_id = match.group(1)
            
            # Find corresponding spec in new structure
            for spec_path in self.target_dir.rglob(f"{task_id}.md"):
                if spec_path.is_file():
                    new_context_path = spec_path.parent / f"{task_id}.context.md"
                    shutil.copy2(context_file, new_context_path)
                    self.migration_log.append(f"Context: {context_file} → {new_context_path}")
                    return 1
        
        # Try epic/feature level context
        if "epic" in context_file.name.lower():
            # Find epic ID and place context there
            match = re.search(r'(\d{4})', context_file.name)
            if match:
                epic_id = match.group(1)
                epic_dir = self.target_dir / epic_id
                if epic_dir.exists():
                    new_context_path = epic_dir / "context.md"
                    shutil.copy2(context_file, new_context_path)
                    return 1
        
        return 0
    
    def update_all_links(self):
        """Update all internal links in markdown files"""
        print("🔗 Updating internal links...")
        updated_files = 0
        
        for md_file in self.target_dir.rglob("*.md"):
            if self.update_links_in_file(md_file):
                updated_files += 1
        
        print(f"   ✓ Updated links in {updated_files} files")
    
    def update_links_in_file(self, file_path: Path) -> bool:
        """Update links in a single file"""
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        original_content = content
        
        # Pattern replacements
        replacements = [
            # Epic links: [[../1000-epic-.../1000-epic-...spec.md]] → [[../1000/epic]]
            (r'\[\[\.\.\/(\d+)-epic-[^\/]*\/\1[^]]*\.spec\.md', r'[[../\1/epic'),
            
            # Feature links: [[../1001-feature-.../1001-feature-...spec.md]] → [[../1001/spec]]  
            (r'\[\[\.\.\/(\d+)-feature-[^\/]*\/\1[^]]*\.spec\.md', r'[[../\1/spec'),
            
            # Task links: [[1014-task-...spec.md]] → [[1014]]
            (r'\[\[(\d{4})-task-[^]]*\.spec\.md', r'[[\1'),
            
            # Remove .spec.md extensions
            (r'\.spec\.md([\|\]])', r'\1'),
            
            # Update paths in links
            (r'(\d{4})-epic-[^\/\]]+\/', r'\1/'),
            (r'(\d{4})-feature-[^\/\]]+\/', r'\1/'),
            (r'(\d{4})-task-[^\/\]]+', r'\1'),
        ]
        
        for pattern, replacement in replacements:
            content = re.sub(pattern, replacement, content)
        
        # Update file references (non-link)
        content = re.sub(r'specs/(\d+)-epic-[^/]+/', r'specs/\1/', content)
        content = re.sub(r'specs/(\d+)-feature-[^/]+/', r'specs/\1/', content)
        
        if content != original_content:
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(content)
            return True
        
        return False
    
    def create_index(self):
        """Create index.md file"""
        print("📚 Creating index file...")
        
        index_content = ["# JTS Specification Index\n", "## Epic Overview\n"]
        
        for epic_dir in sorted(self.target_dir.iterdir()):
            if epic_dir.is_dir() and epic_dir.name.isdigit():
                epic_id = epic_dir.name
                epic_file = epic_dir / "epic.md"
                
                if epic_file.exists():
                    epic_title = self.extract_title(epic_file)
                    index_content.append(f"\n### [{epic_id} - {epic_title}]({epic_id}/epic)\n")
                    
                    # Add features
                    for item in sorted(epic_dir.iterdir()):
                        if item.is_dir() and item.name.isdigit():
                            feature_id = item.name
                            feature_spec = item / "spec.md"
                            if feature_spec.exists():
                                feature_title = self.extract_title(feature_spec)
                                index_content.append(f"- [{feature_id} - {feature_title}]({epic_id}/{feature_id}/spec)\n")
                                
                                # Add tasks
                                for task_file in sorted(item.glob("*.md")):
                                    if task_file.name not in ['spec.md', 'context.md'] and not task_file.name.endswith('.context.md'):
                                        task_id = task_file.stem
                                        task_title = self.extract_title(task_file)
                                        index_content.append(f"  - [{task_id} - {task_title}]({epic_id}/{feature_id}/{task_id})\n")
                        
                        elif item.is_file() and item.suffix == '.md' and item.stem.isdigit():
                            feature_id = item.stem
                            feature_title = self.extract_title(item)
                            index_content.append(f"- [{feature_id} - {feature_title}]({epic_id}/{feature_id})\n")
        
        index_file = self.target_dir / "index.md"
        index_file.write_text(''.join(index_content))
        print(f"   ✓ Index created: {index_file}")
    
    def generate_report(self):
        """Generate migration report"""
        print("📊 Generating report...")
        
        # Count statistics
        stats = {
            'epics': len(list(self.target_dir.glob("*/epic.md"))),
            'features': len(list(self.target_dir.glob("*/*/spec.md"))) + len(list(self.target_dir.glob("*/[0-9]*.md"))),
            'tasks': len([f for f in self.target_dir.rglob("[0-9]*.md") 
                         if f.name not in ['epic.md', 'spec.md'] and not f.name.endswith('.context.md')]),
            'contexts': len(list(self.target_dir.rglob("*.context.md"))),
            'total_files': len(list(self.target_dir.rglob("*.md")))
        }
        
        report = f"""# Migration Report
Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}

## Statistics
- Epics: {stats['epics']}
- Features: {stats['features']}
- Tasks: {stats['tasks']}
- Context Files: {stats['contexts']}
- Total Files: {stats['total_files']}

## Directories
- Source: {self.source_dir}
- Target: {self.target_dir}
- Backup: {self.backup_dir}

## Migration Log
Total files migrated: {len(self.migration_log)}

## To Apply Migration
```bash
# Review the new structure
ls -la {self.target_dir}/

# If satisfied, apply:
mv {self.source_dir} {self.source_dir}_old
mv {self.target_dir} {self.source_dir}

# To rollback:
cp -r {self.backup_dir} {self.source_dir}
```

## Link Mappings
{len(self.link_mappings)} file paths updated
"""
        
        report_file = Path("migration-report.md")
        report_file.write_text(report)
        print(f"   ✓ Report saved: {report_file}")
        
        # Save detailed mappings as JSON
        mappings_file = Path("migration-mappings.json")
        with open(mappings_file, 'w') as f:
            json.dump({
                'mappings': self.link_mappings,
                'log': self.migration_log,
                'stats': stats
            }, f, indent=2)
        print(f"   ✓ Mappings saved: {mappings_file}")
    
    @staticmethod
    def extract_id(name: str) -> str:
        """Extract numeric ID from filename"""
        match = re.match(r'(\d+)', name)
        return match.group(1) if match else ''
    
    @staticmethod
    def find_spec_file(directory: Path, spec_type: str) -> Path:
        """Find spec file in directory"""
        patterns = [
            f"*{spec_type}*.spec.md",
            f"*{spec_type}*.md"
        ]
        
        for pattern in patterns:
            files = list(directory.glob(pattern))
            if files:
                return files[0]
        return None
    
    @staticmethod
    def extract_title(file_path: Path) -> str:
        """Extract title from markdown file"""
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                for line in f:
                    if line.startswith('# '):
                        # Remove "# " and clean up
                        title = line[2:].strip()
                        # Remove ID prefix if present
                        title = re.sub(r'^\d+\s*[-:]\s*', '', title)
                        return title
        except:
            pass
        return file_path.stem

if __name__ == "__main__":
    import sys
    
    # Check for dry-run mode
    dry_run = '--dry-run' in sys.argv
    
    if dry_run:
        print("🔍 DRY RUN MODE - No changes will be made")
        # TODO: Implement dry-run logic
    else:
        migrator = SpecMigration()
        migrator.run()