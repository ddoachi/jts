/**
 * JTS Library Generator
 *
 * WHY: Ensures consistent library creation with proper scoping
 * HOW: Uses Nx devkit to generate standardized TypeScript libraries
 * WHAT: Creates shared libraries with correct import paths and structure
 *
 * FLOW:
 * 1. Validate scope and normalize options
 * 2. Generate base TypeScript library
 * 3. Apply JTS-specific templates
 * 4. Configure import paths and exports
 * 5. Format files and install packages
 *
 * SCOPES:
 * - shared: Cross-cutting utilities and types
 * - domain: Business logic and domain models
 * - infrastructure: External service interfaces
 * - brokers: Broker-specific implementations
 *
 * RELATED: tools/generators/nestjs-service/index.ts
 *
 * @example
 * nx g @tools/generators/jts-library --name=common-types --scope=shared
 * // Creates: libs/shared/common-types with @jts/shared/common-types import
 */

import {
  Tree,
  formatFiles,
  installPackagesTask,
  names,
  generateFiles,
  joinPathFragments,
  updateJson,
  readProjectConfiguration,
  updateProjectConfiguration,
} from '@nx/devkit';
import { libraryGenerator } from '@nx/js';
import * as path from 'path';

// ═══════════════════════════════════════════════════════════════════
// ███ SECTION: Type Definitions ███
// ═══════════════════════════════════════════════════════════════════

export interface LibraryGeneratorSchema {
  name: string;
  directory?: string;
  scope: 'shared' | 'domain' | 'infrastructure' | 'brokers';
  buildable?: boolean;
  publishable?: boolean;
  strict?: boolean;
  tags?: string;
}

interface NormalizedOptions extends LibraryGeneratorSchema {
  projectName: string;
  projectRoot: string;
  projectDirectory: string;
  importPath: string;
  parsedTags: string[];
}

// ═══════════════════════════════════════════════════════════════════
// ███ SECTION: Main Generator Function ███
// ═══════════════════════════════════════════════════════════════════

/**
 * Main library generator entry point
 *
 * WHY: Orchestrates library generation with JTS conventions
 * HOW: Uses Nx library generator with custom templates
 * WHAT: Creates properly scoped TypeScript library
 */
export default async function jtsLibraryGenerator(
  tree: Tree,
  options: LibraryGeneratorSchema,
): Promise<() => void> {
  // Step 1: Normalize and validate options
  const normalizedOptions = normalizeOptions(tree, options);

  // Step 2: Generate base TypeScript library
  await libraryGenerator(tree, {
    name: normalizedOptions.name,
    directory: normalizedOptions.projectDirectory,
    tags: normalizedOptions.parsedTags.join(','),
    buildable: normalizedOptions.buildable ?? true,
    publishable: normalizedOptions.publishable ?? false,
    importPath: normalizedOptions.importPath,
    unitTestRunner: 'jest',
    linter: 'eslint',
    strict: normalizedOptions.strict ?? true,
    skipFormat: true,
  });

  // Step 3: Apply JTS-specific templates
  addCustomFiles(tree, normalizedOptions);

  // Step 4: Update library configuration
  updateLibraryConfig(tree, normalizedOptions);

  // Step 5: Generate standard exports
  generateStandardExports(tree, normalizedOptions);

  // Step 6: Update TypeScript paths
  updateTsConfig(tree, normalizedOptions);

  // Step 7: Format all generated files
  await formatFiles(tree);

  // Return installer task
  return () => {
    installPackagesTask(tree);
  };
}

// ═══════════════════════════════════════════════════════════════════
// ███ SECTION: Option Normalization ███
// ═══════════════════════════════════════════════════════════════════

/**
 * Normalize library generator options
 *
 * WHY: Ensures consistent naming and paths for libraries
 * HOW: Applies scope-based directory structure
 * WHAT: Returns normalized options with calculated paths
 *
 * GOTCHA: Import paths follow @jts/{scope}/{name} convention
 */
function normalizeOptions(tree: Tree, options: LibraryGeneratorSchema): NormalizedOptions {
  // Validate scope
  const validScopes = ['shared', 'domain', 'infrastructure', 'brokers'];
  if (!validScopes.includes(options.scope)) {
    throw new Error(`Invalid scope: ${options.scope}. Must be one of: ${validScopes.join(', ')}`);
  }

  // Convert name to kebab-case
  const name = names(options.name).fileName;

  // Calculate directory based on scope
  // Structure: libs/{scope}/{directory}/{name} or libs/{scope}/{name}
  const projectDirectory = options.directory
    ? `${options.scope}/${names(options.directory).fileName}/${name}`
    : `${options.scope}/${name}`;

  // Project name for Nx
  const projectName = `${options.scope}-${name}`;

  // Project root path
  const projectRoot = `libs/${projectDirectory}`;

  // Import path follows @jts convention
  const importPath = `@jts/${options.scope}/${name}`;

  // Parse and add scope-based tags
  const defaultTags = [`scope:${options.scope}`, 'type:library'];
  const userTags = options.tags ? options.tags.split(',').map((s) => s.trim()) : [];
  const parsedTags = [...defaultTags, ...userTags];

  return {
    ...options,
    projectName,
    projectRoot,
    projectDirectory,
    importPath,
    parsedTags,
  };
}

// ═══════════════════════════════════════════════════════════════════
// ███ SECTION: Template Application ███
// ═══════════════════════════════════════════════════════════════════

/**
 * Add custom JTS template files
 *
 * WHY: Provides consistent structure across all libraries
 * HOW: Generates files from templates with scope-specific content
 * WHAT: Creates README, additional configs, and examples
 */
function addCustomFiles(tree: Tree, options: NormalizedOptions): void {
  const templateOptions = {
    ...options,
    ...names(options.name),
    template: '',
  };

  // Generate files from templates
  generateFiles(tree, path.join(__dirname, 'files'), options.projectRoot, templateOptions);

  // Add scope-specific templates
  addScopeSpecificFiles(tree, options);
}

/**
 * Add scope-specific files
 *
 * WHY: Different scopes have different requirements
 * HOW: Generates files based on library scope
 * WHAT: Creates scope-appropriate structures and examples
 */
function addScopeSpecificFiles(tree: Tree, options: NormalizedOptions): void {
  switch (options.scope) {
    case 'shared':
      generateSharedLibraryFiles(tree, options);
      break;
    case 'domain':
      generateDomainLibraryFiles(tree, options);
      break;
    case 'infrastructure':
      generateInfrastructureLibraryFiles(tree, options);
      break;
    case 'brokers':
      generateBrokersLibraryFiles(tree, options);
      break;
  }
}

/**
 * Generate files for shared libraries
 *
 * WHY: Shared libraries contain utilities and common types
 * HOW: Creates structure for constants, types, and utilities
 * WHAT: Standard shared library organization
 */
function generateSharedLibraryFiles(tree: Tree, options: NormalizedOptions): void {
  // Create directory structure
  const dirs = ['constants', 'types', 'utils', 'dto'];
  dirs.forEach((dir) => {
    const dirPath = `${options.projectRoot}/src/${dir}`;
    tree.write(`${dirPath}/.gitkeep`, '');
  });

  // Create barrel exports for each directory
  dirs.forEach((dir) => {
    const indexPath = `${options.projectRoot}/src/${dir}/index.ts`;
    tree.write(indexPath, `// Export all ${dir} from this file\n`);
  });
}

/**
 * Generate files for domain libraries
 *
 * WHY: Domain libraries contain business logic
 * HOW: Creates structure for entities, services, and events
 * WHAT: Domain-driven design structure
 */
function generateDomainLibraryFiles(tree: Tree, options: NormalizedOptions): void {
  // Create DDD structure
  const dirs = ['entities', 'value-objects', 'services', 'events', 'repositories'];
  dirs.forEach((dir) => {
    const dirPath = `${options.projectRoot}/src/${dir}`;
    tree.write(`${dirPath}/.gitkeep`, '');
  });

  // Create interfaces for repositories
  const repoInterfacePath = `${options.projectRoot}/src/repositories/repository.interface.ts`;
  tree.write(
    repoInterfacePath,
    `/**
 * Base Repository Interface
 *
 * WHY: Define contract for data access without implementation details
 * HOW: Domain defines interface, infrastructure provides implementation
 * WHAT: Standard CRUD operations for domain entities
 */
export interface Repository<T> {
  findById(id: string): Promise<T | null>;
  findAll(): Promise<T[]>;
  save(entity: T): Promise<T>;
  delete(id: string): Promise<void>;
}
`,
  );
}

/**
 * Generate files for infrastructure libraries
 *
 * WHY: Infrastructure libraries contain external integrations
 * HOW: Creates structure for adapters and clients
 * WHAT: Ports and adapters pattern implementation
 */
function generateInfrastructureLibraryFiles(tree: Tree, options: NormalizedOptions): void {
  // Create infrastructure structure
  const dirs = ['adapters', 'clients', 'config'];
  dirs.forEach((dir) => {
    const dirPath = `${options.projectRoot}/src/${dir}`;
    tree.write(`${dirPath}/.gitkeep`, '');
  });
}

/**
 * Generate files for broker libraries
 *
 * WHY: Broker libraries contain trading platform integrations
 * HOW: Creates structure for broker-specific implementations
 * WHAT: Standardized broker adapter pattern
 */
function generateBrokersLibraryFiles(tree: Tree, options: NormalizedOptions): void {
  // Create broker adapter structure
  const adapterPath = `${options.projectRoot}/src/adapter.ts`;
  tree.write(
    adapterPath,
    `/**
 * ${options.className} Broker Adapter
 *
 * WHY: Provides standardized interface to ${options.name} broker
 * HOW: Implements common broker interface with platform-specific logic
 * WHAT: Trading operations, market data, and account management
 */
export class ${options.className}Adapter {
  constructor(private config: any) {}

  async connect(): Promise<void> {
    // Implementation here
  }

  async disconnect(): Promise<void> {
    // Implementation here
  }

  async placeOrder(order: any): Promise<any> {
    // Implementation here
  }

  async getMarketData(symbol: string): Promise<any> {
    // Implementation here
  }
}
`,
  );
}

// ═══════════════════════════════════════════════════════════════════
// ███ SECTION: Standard Exports ███
// ═══════════════════════════════════════════════════════════════════

/**
 * Generate standard export structure
 *
 * WHY: Ensures consistent API surface for all libraries
 * HOW: Creates barrel exports with clear organization
 * WHAT: Main index.ts with organized exports
 */
function generateStandardExports(tree: Tree, options: NormalizedOptions): void {
  const indexPath = `${options.projectRoot}/src/index.ts`;

  let exportContent = `/**
 * ${options.className} Library
 * Scope: ${options.scope}
 * Import: ${options.importPath}
 */

`;

  // Add scope-specific exports
  switch (options.scope) {
    case 'shared':
      exportContent += `// Constants
export * from './constants';

// Types
export * from './types';

// Utilities
export * from './utils';

// DTOs
export * from './dto';
`;
      break;

    case 'domain':
      exportContent += `// Entities
export * from './entities';

// Value Objects
export * from './value-objects';

// Services
export * from './services';

// Events
export * from './events';

// Repository Interfaces
export * from './repositories';
`;
      break;

    case 'infrastructure':
      exportContent += `// Adapters
export * from './adapters';

// Clients
export * from './clients';

// Configuration
export * from './config';
`;
      break;

    case 'brokers':
      exportContent += `// Broker Adapter
export * from './adapter';
`;
      break;
  }

  tree.write(indexPath, exportContent);
}

// ═══════════════════════════════════════════════════════════════════
// ███ SECTION: Configuration Updates ███
// ═══════════════════════════════════════════════════════════════════

/**
 * Update library project configuration
 *
 * WHY: Adds JTS-specific build configurations
 * HOW: Modifies project.json with additional options
 * WHAT: Build optimization and output settings
 */
function updateLibraryConfig(tree: Tree, options: NormalizedOptions): void {
  const projectConfig = readProjectConfiguration(tree, options.projectName);

  // Add custom targets
  projectConfig.targets = {
    ...projectConfig.targets,
    validate: {
      executor: '@nx/js:tsc',
      options: {
        tsConfig: `${options.projectRoot}/tsconfig.lib.json`,
        noEmit: true,
      },
    },
  };

  // Update project configuration
  updateProjectConfiguration(tree, options.projectName, projectConfig);
}

/**
 * Update TypeScript configuration
 *
 * WHY: Ensures proper import resolution
 * HOW: Updates tsconfig.base.json with path mapping
 * WHAT: Adds library to TypeScript paths
 */
function updateTsConfig(tree: Tree, options: NormalizedOptions): void {
  updateJson(tree, 'tsconfig.base.json', (json) => {
    json.compilerOptions = json.compilerOptions || {};
    json.compilerOptions.paths = json.compilerOptions.paths || {};

    // Add path mapping for the library
    json.compilerOptions.paths[options.importPath] = [`${options.projectRoot}/src/index.ts`];

    // Add wildcard path for deep imports
    json.compilerOptions.paths[`${options.importPath}/*`] = [`${options.projectRoot}/src/*`];

    return json;
  });
}
