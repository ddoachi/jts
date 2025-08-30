import * as fs from 'fs';
import * as path from 'path';
import { glob } from 'glob';
import matter from 'gray-matter';

interface SpecMetadata {
  id: string;
  title: string;
  type: 'epic' | 'feature' | 'task' | 'subtask';
  parent?: string;
  status: string;
  priority: string;
  created: string;
  updated: string;
  children?: string[];
  estimated_hours?: number;
  actual_hours?: number;
  pull_requests?: string[];
  commits?: string[];
}

interface SpecData {
  specs: Record<string, SpecMetadata>;
  stats: {
    total_epics: number;
    total_features: number;
    total_tasks: number;
    total_subtasks: number;
    completed: string[];
    in_progress: string[];
    draft: string[];
    blocked: string[];
  };
  hierarchy: Record<string, any>;
}

async function parseAllSpecs(): Promise<SpecData> {
  const specFiles = await glob('specs/**/spec.md');
  const specs: Record<string, SpecMetadata> = {};
  const hierarchy: Record<string, any> = {};
  
  // Parse each spec file
  for (const file of specFiles) {
    const content = fs.readFileSync(file, 'utf-8');
    const { data } = matter(content);
    
    // Extract directory structure for type-prefixed naming
    const dir = path.dirname(file);
    const parts = dir.split('/');
    const specId = parts[parts.length - 1]; // E01, F01, T01, etc.
    
    specs[specId] = {
      id: specId,
      title: data.title,
      type: data.type,
      parent: data.parent,
      status: data.status || 'draft',
      priority: data.priority || 'medium',
      created: data.created,
      updated: data.updated,
      children: data.children,
      estimated_hours: data.estimated_hours,
      actual_hours: data.actual_hours,
      pull_requests: data.pull_requests,
      commits: data.commits,
    };
    
    // Build hierarchy with unified children structure
    if (data.type === 'epic') {
      hierarchy[specId] = {
        ...specs[specId],
        children: {}
      };
    } else if (data.type === 'feature' && data.parent) {
      if (!hierarchy[data.parent]) {
        hierarchy[data.parent] = { 
          ...specs[data.parent],
          children: {} 
        };
      }
      hierarchy[data.parent].children[specId] = {
        ...specs[specId],
        children: {}
      };
    } else if (data.type === 'task' && data.parent) {
      // Find parent feature in hierarchy
      for (const epicId in hierarchy) {
        const epic = hierarchy[epicId];
        if (epic.children && epic.children[data.parent]) {
          epic.children[data.parent].children[specId] = {
            ...specs[specId],
            children: {}
          };
          break;
        }
      }
    } else if (data.type === 'subtask' && data.parent) {
      // Find parent task in hierarchy
      for (const epicId in hierarchy) {
        const epic = hierarchy[epicId];
        if (epic.children) {
          for (const featureId in epic.children) {
            const feature = epic.children[featureId];
            if (feature.children && feature.children[data.parent]) {
              feature.children[data.parent].children[specId] = {
                ...specs[specId],
                children: {}
              };
              break;
            }
          }
        }
      }
    }
  }
  
  // Calculate statistics
  const stats = {
    total_epics: Object.values(specs).filter(s => s.type === 'epic').length,
    total_features: Object.values(specs).filter(s => s.type === 'feature').length,
    total_tasks: Object.values(specs).filter(s => s.type === 'task').length,
    total_subtasks: Object.values(specs).filter(s => s.type === 'subtask').length,
    completed: Object.keys(specs).filter(id => specs[id].status === 'completed'),
    in_progress: Object.keys(specs).filter(id => specs[id].status === 'in_progress' || specs[id].status === 'in-progress'),
    draft: Object.keys(specs).filter(id => specs[id].status === 'draft'),
    blocked: Object.keys(specs).filter(id => specs[id].status === 'blocked'),
  };
  
  const specData: SpecData = { specs, stats, hierarchy };
  
  // Save to JSON file
  fs.writeFileSync('specs-data.json', JSON.stringify(specData, null, 2));
  
  return specData;
}

// Run if called directly
if (require.main === module) {
  parseAllSpecs()
    .then(() => console.log('✅ Specs parsed successfully'))
    .catch(console.error);
}

export { parseAllSpecs, SpecMetadata, SpecData };