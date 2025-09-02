import * as fs from 'fs';
import * as path from 'path';
import { glob } from 'glob';
import matter from 'gray-matter';

interface SpecMetadata {
  id: string;
  hierarchical_id: string;
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

// Normalize status values to standard format
function normalizeStatus(status: string): string {
  const normalizedMap: Record<string, string> = {
    done: 'completed',
    finished: 'completed',
    'in-progress': 'in_progress',
    active: 'in_progress',
    todo: 'draft',
    pending: 'draft',
  };
  return normalizedMap[status] || status;
}

// Calculate parent status based on children
function calculateParentStatus(children: any, originalStatus: string): string {
  if (!children || Object.keys(children).length === 0) {
    return originalStatus; // No children, keep original status
  }

  const childStatuses = Object.values(children).map((child: any) => normalizeStatus(child.status));

  // If all children are completed, parent is completed
  if (childStatuses.every((status) => status === 'completed')) {
    return 'completed';
  }

  // If any child is not draft, parent is in_progress
  if (childStatuses.some((status) => status !== 'draft')) {
    return 'in_progress';
  }

  // All children are draft, parent stays draft
  return 'draft';
}

// Process hierarchy to normalize statuses and calculate parent statuses
function processHierarchy(hierarchy: any, specs: Record<string, SpecMetadata>): any {
  if (!hierarchy || typeof hierarchy !== 'object') {
    return hierarchy;
  }

  const result: any = {};

  for (const [key, item] of Object.entries(hierarchy)) {
    const processedItem = { ...(item as any) };

    // First process children recursively
    if (processedItem.children && Object.keys(processedItem.children).length > 0) {
      processedItem.children = processHierarchy(processedItem.children, specs);

      // Calculate parent status based on processed children
      const calculatedStatus = calculateParentStatus(processedItem.children, processedItem.status);
      processedItem.status = calculatedStatus;

      // Update the specs record with the calculated status
      if (specs[processedItem.hierarchical_id]) {
        specs[processedItem.hierarchical_id].status = calculatedStatus;
      }
    }

    // Normalize the item's own status
    processedItem.status = normalizeStatus(processedItem.status);

    result[key] = processedItem;
  }

  return result;
}

async function parseAllSpecs(): Promise<SpecData> {
  const specFiles = await glob('specs/**/*.spec.md');
  const specs: Record<string, SpecMetadata> = {};
  const hierarchy: Record<string, any> = {};

  // Parse each spec file and generate hierarchical IDs from directory structure
  for (const file of specFiles) {
    const content = fs.readFileSync(file, 'utf-8');
    const YAML = require('yaml');

    const { data } = matter(content, {
      engines: {
        yaml: {
          parse: (str: string) => {
            return YAML.parse(str, { schema: 'failsafe' });
          },
        },
      },
    });

    // Extract directory structure: specs/E01/F01/T01/spec.md -> [E01, F01, T01]
    const dir = path.dirname(file);
    const pathParts = dir.split('/').filter((part) => part !== 'specs');
    const dirId = pathParts[pathParts.length - 1]; // E01, F01, T01, etc. (directory name)

    // Generate hierarchical ID from directory path
    const hierarchicalId = pathParts.join('-'); // E01, E01-F01, E01-F01-T01, etc.

    specs[hierarchicalId] = {
      id: String(data.id), // Ensure ID is always a string
      hierarchical_id: hierarchicalId,
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
      hierarchy[dirId] = {
        ...specs[hierarchicalId],
        children: {},
      };
    } else if (data.type === 'feature' && data.parent) {
      if (!hierarchy[data.parent]) {
        hierarchy[data.parent] = {
          ...specs[data.parent],
          children: {},
        };
      }
      hierarchy[data.parent].children[dirId] = {
        ...specs[hierarchicalId],
        children: {},
      };
    } else if (data.type === 'task' && data.parent) {
      // Find parent feature in hierarchy within the same epic
      // Parent is in hierarchical format (e.g., "E01-F02"), extract the feature part
      const parentParts = data.parent.split('-');
      const epicId = parentParts[0]; // E01
      const featureId = parentParts[1]; // F02
      
      if (
        hierarchy[epicId] &&
        hierarchy[epicId].children &&
        hierarchy[epicId].children[featureId]
      ) {
        hierarchy[epicId].children[featureId].children[dirId] = {
          ...specs[hierarchicalId],
          children: {},
        };
      }
    } else if (data.type === 'subtask' && data.parent) {
      // Find parent task in hierarchy within the same epic
      // Parent is in hierarchical format (e.g., "E01-F02-T01"), extract the parts
      const parentParts = data.parent.split('-');
      const epicId = parentParts[0]; // E01
      const featureId = parentParts[1]; // F02
      const taskId = parentParts[2]; // T01
      
      if (hierarchy[epicId] && hierarchy[epicId].children) {
        const feature = hierarchy[epicId].children[featureId];
        if (feature && feature.children && feature.children[taskId]) {
          feature.children[taskId].children[dirId] = {
            ...specs[hierarchicalId],
            children: {},
          };
        }
      }
    }
  }

  // Process hierarchy to normalize statuses and calculate parent statuses
  const processedHierarchy = processHierarchy(hierarchy, specs);

  // Calculate statistics
  const stats = {
    total_epics: Object.values(specs).filter((s) => s.type === 'epic').length,
    total_features: Object.values(specs).filter((s) => s.type === 'feature').length,
    total_tasks: Object.values(specs).filter((s) => s.type === 'task').length,
    total_subtasks: Object.values(specs).filter((s) => s.type === 'subtask').length,
    completed: Object.keys(specs).filter((id) => specs[id].status === 'completed'),
    in_progress: Object.keys(specs).filter(
      (id) => specs[id].status === 'in_progress' || specs[id].status === 'in-progress',
    ),
    draft: Object.keys(specs).filter((id) => specs[id].status === 'draft'),
    blocked: Object.keys(specs).filter((id) => specs[id].status === 'blocked'),
  };

  const specData: SpecData = { specs, stats, hierarchy: processedHierarchy };

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
