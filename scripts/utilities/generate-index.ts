import * as fs from 'fs';
import * as handlebars from 'handlebars';
import { SpecMetadata } from './parse-specs';

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
function calculateParentStatus(children: any): string {
  if (!children || Object.keys(children).length === 0) {
    return 'draft'; // No children, keep original status
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

// Register Handlebars helpers
handlebars.registerHelper('percentage', (completed: number, total: number) => {
  return ((completed / total) * 100).toFixed(1);
});

handlebars.registerHelper('progressBar', (percentage: number) => {
  const filled = Math.round(percentage / 5);
  const empty = 20 - filled;
  return '█'.repeat(filled) + '░'.repeat(empty);
});

handlebars.registerHelper('statusIcon', (status: string) => {
  const normalizedStatus = normalizeStatus(status);
  const icons: Record<string, string> = {
    completed: '✅',
    in_progress: '🚧',
    draft: '📋',
    blocked: '🚫',
  };
  return icons[normalizedStatus] || '';
});

// Helper to build correct spec file paths
handlebars.registerHelper('specPath', (...args: any[]) => {
  // Remove the last argument (Handlebars options object)
  const keys = args.slice(0, -1).filter((k) => k);
  return keys.join('/');
});

// Process hierarchy to normalize statuses and calculate parent statuses
function processHierarchy(hierarchy: any): any {
  if (!hierarchy || typeof hierarchy !== 'object') {
    return hierarchy;
  }

  const result: any = {};

  for (const [key, item] of Object.entries(hierarchy)) {
    const processedItem = { ...(item as any) };

    // First process children recursively
    if (processedItem.children && Object.keys(processedItem.children).length > 0) {
      processedItem.children = processHierarchy(processedItem.children);

      // Calculate parent status based on processed children
      processedItem.status = calculateParentStatus(processedItem.children);
    }

    // Normalize the item's own status
    processedItem.status = normalizeStatus(processedItem.status);

    result[key] = processedItem;
  }

  return result;
}

function sortSpecHierarchy(hierarchy: any): any {
  if (!hierarchy || typeof hierarchy !== 'object') {
    return hierarchy;
  }

  const sortedKeys = Object.keys(hierarchy).sort((a, b) => {
    const prefixOrder: Record<string, number> = { E: 1, F: 2, T: 3, S: 4 };
    const aPrefix = a.charAt(0);
    const bPrefix = b.charAt(0);

    if (prefixOrder[aPrefix] !== prefixOrder[bPrefix]) {
      return prefixOrder[aPrefix] - prefixOrder[bPrefix];
    }

    return parseInt(a.slice(1)) - parseInt(b.slice(1));
  });

  // Create sorted result object and handle recursion
  const result: any = {};
  for (const key of sortedKeys) {
    result[key] = { ...hierarchy[key] };

    // Recursively sort children if they exist
    if (result[key].children) {
      result[key].children = sortSpecHierarchy(result[key].children);
    }
  }

  return result;
}

function generateIndex() {
  // Load spec data
  const specData = JSON.parse(fs.readFileSync('specs-data.json', 'utf-8'));

  // Process hierarchy to normalize statuses and calculate parent statuses
  specData.hierarchy = processHierarchy(specData.hierarchy);
  specData.hierarchy = sortSpecHierarchy(specData.hierarchy);

  // Calculate additional stats
  const totalSpecs =
    specData.stats.total_epics +
    specData.stats.total_features +
    specData.stats.total_tasks +
    specData.stats.total_subtasks;

  const completedCount = specData.stats.completed.length;
  const progressPercentage = totalSpecs > 0 ? (completedCount / totalSpecs) * 100 : 0;

  // Add calculated values
  specData.calculated = {
    totalSpecs,
    completedCount,
    progressPercentage: progressPercentage.toFixed(1),
    progressBar:
      '█'.repeat(Math.round(progressPercentage / 5)) +
      '░'.repeat(20 - Math.round(progressPercentage / 5)),
    lastUpdated: new Date().toISOString().split('T')[0], // Format: YYYY-MM-DD
  };

  // Load template
  const templatePath = 'templates/index.template.md';
  const template = fs.readFileSync(templatePath, 'utf-8');

  // Compile and generate
  const compiled = handlebars.compile(template);
  const output = compiled(specData);

  // Write index.md
  fs.writeFileSync('specs/index.md', output);
  console.log('✅ index.md generated successfully');
  console.log(`   Total specs: ${totalSpecs}`);
  console.log(`   Completed: ${completedCount}`);
  console.log(`   Progress: ${progressPercentage.toFixed(1)}%`);
}

// Run if called directly
if (require.main === module) {
  generateIndex();
}

export { generateIndex };
