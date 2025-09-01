#!/usr/bin/env python3
"""
Fix spec ID fields to use UUIDs instead of hierarchical strings.

This script updates the existing specs to change the 'id' field from 
hierarchical strings (E01, F02, T03) to short UUIDs while keeping
the directory structure unchanged.
"""

import re
import yaml
from pathlib import Path
from typing import Dict, Tuple
import uuid


def parse_yaml_frontmatter(content: str) -> Tuple[dict, str]:
    """Parse YAML frontmatter from markdown content."""
    if not content.startswith('---'):
        return {}, content
    
    try:
        end_match = re.search(r'\n---\n', content[3:])
        if not end_match:
            return {}, content
        
        yaml_content = content[3:end_match.start() + 3]
        body_content = content[end_match.end() + 3:]
        
        # Simple approach: just remove inline comments after values
        yaml_lines = []
        for line in yaml_content.split('\n'):
            if line.strip().startswith('#'):
                continue
            if '#' in line:
                if '"#' in line or "'#" in line:
                    yaml_lines.append(line)
                else:
                    parts = line.split('#', 1)
                    yaml_lines.append(parts[0].rstrip())
            else:
                yaml_lines.append(line)
        
        metadata = yaml.safe_load('\n'.join(yaml_lines))
        return metadata or {}, body_content
        
    except Exception as e:
        print(f"Error parsing YAML frontmatter: {e}")
        return {}, content


def format_yaml_with_comments(metadata: dict) -> str:
    """Format YAML metadata with appropriate comments and sections."""
    yaml_lines = yaml.dump(metadata, default_flow_style=False, sort_keys=False).strip().split('\n')
    formatted_yaml = [
        '---',
        '# ============================================================================',
        '# SPEC METADATA - This entire frontmatter section contains the spec metadata',
        '# ============================================================================',
        '',
        '# === IDENTIFICATION ==='
    ]
    
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
        elif line.startswith('tags:'):
            if current_section != 'metadata':
                formatted_yaml.append('')
                formatted_yaml.append('# === METADATA ===')
                current_section = 'metadata'
            formatted_yaml.append(line)
        else:
            formatted_yaml.append(line)
    
    formatted_yaml.append('---')
    return '\n'.join(formatted_yaml)


def fix_spec_ids():
    """Fix spec ID fields to use UUIDs instead of hierarchical strings."""
    root_path = Path('.')
    spec_files = list(root_path.glob("specs/**/spec.md"))
    
    print(f"Found {len(spec_files)} spec files")
    
    updated_count = 0
    
    for spec_file in spec_files:
        try:
            # Read current content
            content = spec_file.read_text(encoding='utf-8')
            metadata, body = parse_yaml_frontmatter(content)
            
            if not metadata or 'id' not in metadata:
                print(f"Skipping {spec_file}: no ID field found")
                continue
            
            current_id = str(metadata['id'])
            
            # Check if ID is already a UUID (8 hex characters)
            if re.match(r'^[a-f0-9]{8}$', current_id):
                print(f"Skipping {spec_file}: ID already looks like UUID ({current_id})")
                continue
            
            # Use existing unique_id if available, otherwise generate new one
            if 'unique_id' in metadata:
                new_id = metadata['unique_id']
                # Remove the unique_id field since we're moving it to id
                del metadata['unique_id']
            else:
                new_id = str(uuid.uuid4())[:8]
            
            # Update the ID field
            metadata['id'] = new_id
            
            print(f"Updating {spec_file}: {current_id} -> {new_id}")
            
            # Create new content
            formatted_yaml = format_yaml_with_comments(metadata)
            new_content = f"{formatted_yaml}\n\n{body}"
            
            # Write back to file
            spec_file.write_text(new_content, encoding='utf-8')
            updated_count += 1
            
        except Exception as e:
            print(f"Error processing {spec_file}: {e}")
    
    print(f"\nUpdated {updated_count} spec files")


if __name__ == "__main__":
    print("Fixing spec ID fields...")
    fix_spec_ids()
    print("Done!")