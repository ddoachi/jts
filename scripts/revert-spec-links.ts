#!/usr/bin/env -S npx tsx

import * as fs from 'fs';
import * as path from 'path';

function findSpecFiles(dir: string, files: string[] = []): string[] {
  const items = fs.readdirSync(dir);
  for (const item of items) {
    const fullPath = path.join(dir, item);
    const stat = fs.statSync(fullPath);
    if (stat.isDirectory()) {
      findSpecFiles(fullPath, files);
    } else if (item === 'spec.md') {
      files.push(fullPath);
    }
  }
  return files;
}

async function revertSpecLinks() {
  const specFiles = findSpecFiles('specs');
  
  console.log(`Found ${specFiles.length} spec.md files to process`);
  
  let totalReplacements = 0;
  
  for (const specFile of specFiles) {
    const content = fs.readFileSync(specFile, 'utf-8');
    let modifiedContent = content;
    let fileReplacements = 0;
    
    // Pattern to match links like [T03](../T03/spec.md), [F02](../../F02/spec.md), [E01](../../spec.md)
    const linkPattern = /\[([EFTD]\d{2})\]\([\.\/]*(?:[EFTD]\d{2}\/)?spec\.md\)/g;
    
    // Extract epic/feature/task IDs from the file path
    const pathParts = path.dirname(specFile).split('/').slice(1); // Remove 'specs' prefix
    const currentEpic = pathParts[0] || '';
    const currentFeature = pathParts[1] || '';
    const currentTask = pathParts[2] || '';
    
    modifiedContent = modifiedContent.replace(linkPattern, (match, id) => {
      fileReplacements++;
      
      // Determine the type and construct the full ID
      const type = id[0];
      let fullId = '';
      
      if (type === 'E') {
        fullId = id;
      } else if (type === 'F') {
        // Feature links need the epic prefix
        if (id === currentFeature) {
          // Self-reference
          fullId = `${currentEpic}-${id}`;
        } else {
          // Cross-reference - need to find the epic
          const targetFiles = findSpecFiles('specs').filter(f => f.includes(`/${id}/spec.md`));
          if (targetFiles.length > 0) {
            const targetEpic = targetFiles[0].split('/')[1];
            fullId = `${targetEpic}-${id}`;
          } else {
            // Fallback to current epic
            fullId = `${currentEpic}-${id}`;
          }
        }
      } else if (type === 'T' || type === 'D') {
        // Task/Decision links need epic and feature prefix
        if (id === currentTask) {
          // Self-reference
          fullId = `${currentEpic}-${currentFeature}-${id}`;
        } else if (currentFeature) {
          // Sibling task in same feature
          fullId = `${currentEpic}-${currentFeature}-${id}`;
        } else {
          // Cross-reference - need to find the epic and feature
          const targetFiles = findSpecFiles('specs').filter(f => f.endsWith(`/${id}/spec.md`));
          if (targetFiles.length > 0) {
            const parts = targetFiles[0].split('/');
            fullId = `${parts[1]}-${parts[2]}-${id}`;
          } else {
            // Fallback
            fullId = id;
          }
        }
      }
      
      return fullId || id;
    });
    
    // Also handle parent links in frontmatter
    const parentPattern = /^parent:\s*"\[([EFTD]\d{2})\]\([\.\/]*spec\.md\)"$/gm;
    modifiedContent = modifiedContent.replace(parentPattern, (match, id) => {
      fileReplacements++;
      
      const type = id[0];
      let fullId = '';
      
      if (type === 'E') {
        fullId = id;
      } else if (type === 'F') {
        fullId = `${currentEpic}-${id}`;
      }
      
      return `parent: "${fullId || id}"`;
    });
    
    // Handle epic links in frontmatter
    const epicPattern = /^epic:\s*"\[([E]\d{2})\]\([\.\/]*spec\.md\)"$/gm;
    modifiedContent = modifiedContent.replace(epicPattern, (match, id) => {
      fileReplacements++;
      return `epic: "${id}"`;
    });
    
    if (fileReplacements > 0) {
      fs.writeFileSync(specFile, modifiedContent);
      console.log(`✅ ${specFile}: ${fileReplacements} links reverted`);
      totalReplacements += fileReplacements;
    }
  }
  
  console.log(`\n✨ Total: ${totalReplacements} links reverted across ${specFiles.length} files`);
}

revertSpecLinks().catch(console.error);