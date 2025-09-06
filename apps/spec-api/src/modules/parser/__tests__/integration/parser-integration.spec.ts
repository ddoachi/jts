/**
 * Integration Tests for Spec Parser Service
 *
 * These tests validate the complete parser workflow with real file system operations,
 * file watching, and end-to-end spec processing. They ensure all components work
 * together correctly in realistic scenarios.
 *
 * TEST SCENARIOS:
 * - Complete spec discovery and parsing workflow
 * - File watcher integration with real-time updates
 * - Multi-file relationship building
 * - Error recovery in production scenarios
 * - Performance with real file I/O
 */

import * as fs from 'fs/promises';
import * as path from 'path';
import { EventEmitter } from 'events';
import { SpecParserService } from '../../services/spec-parser.service';
import { SpecDiscoveryService } from '../../services/spec-discovery.service';
import { SpecRegistryService } from '../../services/spec-registry.service';
import { FileWatcherService } from '../../services/file-watcher.service';
import { ParserModule } from '../../parser.module';
import {
  createTestSpecDirectory,
  cleanupTestDirectory,
  PerformanceMonitor,
  waitFor,
  createMockLogger,
} from '../helpers/test-utils';

describe('Parser Integration Tests', () => {
  let testDir: string;
  let parser: SpecParserService;
  let discovery: SpecDiscoveryService;
  let registry: SpecRegistryService;
  let watcher: FileWatcherService;
  let eventBus: EventEmitter;
  let mockLogger: ReturnType<typeof createMockLogger>;

  /**
   * Setup test environment with real files
   */
  beforeEach(async () => {
    // Create test directory structure
    testDir = await createTestSpecDirectory([
      {
        path: 'E13/E13.spec.md',
        content: `---
id: E13
title: Spec Management API
type: epic
status: in-progress
priority: high
created: 2025-01-05
updated: 2025-01-06
---

# E13: Spec Management API

Complete spec management system.`,
      },
      {
        path: 'E13/F01/spec.md',
        content: `---
id: E13-F01
title: Parser Service
parent: E13
type: feature
status: draft
priority: critical
created: 2025-01-05
updated: 2025-01-06
---

# Parser Service

Core parsing functionality.`,
      },
      {
        path: 'E13/F01/T01/spec.md',
        content: `---
id: E13-F01-T01
title: Core Parser
parent: E13-F01
type: task
status: completed
priority: high
created: 2025-01-05
updated: 2025-01-06
---

# Core Parser Task`,
      },
      {
        path: 'E13/F02/spec.md',
        content: `---
id: E13-F02
title: Renderer Service
parent: E13
type: feature
status: draft
priority: high
created: 2025-01-05
updated: 2025-01-06
---

# Renderer Service`,
      },
      {
        path: 'E14/E14.spec.md',
        content: `---
id: E14
title: Analytics System
type: epic
status: draft
priority: medium
created: 2025-01-05
updated: 2025-01-06
---

# Analytics System`,
      },
    ]);

    // Initialize services
    eventBus = new EventEmitter();
    mockLogger = createMockLogger();

    parser = new SpecParserService(mockLogger);
    discovery = new SpecDiscoveryService(mockLogger);
    registry = new SpecRegistryService(eventBus, mockLogger);
    watcher = new FileWatcherService(eventBus, mockLogger);
  });

  /**
   * Cleanup test environment
   */
  afterEach(async () => {
    // Stop file watcher
    if (watcher) {
      await watcher.stop();
    }

    // Clean up test directory
    await cleanupTestDirectory(testDir);

    // Clear mocks
    jest.clearAllMocks();
  });

  describe('Complete Discovery and Parsing Workflow', () => {
    /**
     * Test: Should discover and parse all spec files
     * Validates the complete initialization workflow
     */
    it('should discover and parse all spec files on startup', async () => {
      // Act: Discover all spec files
      const specPaths = await discovery.discoverSpecs(path.join(testDir, 'specs'));

      // Parse each discovered file
      for (const specPath of specPaths) {
        const parsed = await parser.parseFile(specPath);
        registry.upsert(parsed);
      }

      // Assert: All specs discovered and parsed
      expect(specPaths).toHaveLength(5);
      expect(registry.getAll()).toHaveLength(5);

      // Verify hierarchy is correct
      const e13 = registry.get('E13');
      expect(e13).toBeDefined();

      const e13Children = registry.getChildren('E13');
      expect(e13Children).toHaveLength(2); // F01 and F02

      const e13f01Children = registry.getChildren('E13-F01');
      expect(e13f01Children).toHaveLength(1); // T01
    });

    /**
     * Test: Should handle mixed valid and invalid specs
     * Validates error recovery during discovery
     */
    it('should continue processing when encountering invalid specs', async () => {
      // Add an invalid spec file
      const invalidPath = path.join(testDir, 'specs', 'invalid.spec.md');
      await fs.writeFile(
        invalidPath,
        `---
title: Missing ID
---

# Invalid spec without ID`,
        'utf-8',
      );

      // Act: Discover and process all files
      const specPaths = await discovery.discoverSpecs(path.join(testDir, 'specs'));
      const results = await Promise.allSettled(
        specPaths.map(async (specPath) => {
          const parsed = await parser.parseFile(specPath);
          return registry.upsert(parsed);
        }),
      );

      // Assert: Valid specs processed, invalid spec rejected
      const successful = results.filter((r) => r.status === 'fulfilled');
      const failed = results.filter((r) => r.status === 'rejected');

      expect(successful).toHaveLength(5); // Original 5 valid specs
      expect(failed).toHaveLength(1); // The invalid spec
      expect(registry.getAll()).toHaveLength(5);
    });

    /**
     * Test: Should build complete spec tree from files
     * Validates tree generation from file system
     */
    it('should build complete hierarchical tree from discovered specs', async () => {
      // Act: Complete discovery and parsing
      const specPaths = await discovery.discoverSpecs(path.join(testDir, 'specs'));

      for (const specPath of specPaths) {
        const parsed = await parser.parseFile(specPath);
        registry.upsert(parsed);
      }

      const tree = registry.getTree();

      // Assert: Tree structure matches file hierarchy
      expect(tree).toHaveLength(2); // E13 and E14 at root

      const e13Node = tree.find((n) => n.spec.id === 'E13');
      expect(e13Node?.children).toHaveLength(2); // F01 and F02

      const f01Node = e13Node?.children.find((n) => n.spec.id === 'E13-F01');
      expect(f01Node?.children).toHaveLength(1); // T01

      const e14Node = tree.find((n) => n.spec.id === 'E14');
      expect(e14Node?.children).toHaveLength(0); // No children
    });
  });

  describe('File Watcher Integration', () => {
    /**
     * Test: Should detect new spec files
     * Validates file addition detection
     */
    it('should detect and parse newly added spec files', async () => {
      // Setup: Initialize with existing specs
      const specPaths = await discovery.discoverSpecs(path.join(testDir, 'specs'));
      for (const specPath of specPaths) {
        const parsed = await parser.parseFile(specPath);
        registry.upsert(parsed);
      }

      // Start watching
      await watcher.startWatching([path.join(testDir, 'specs')]);

      // Track events
      let newSpecDetected = false;
      eventBus.on('spec:created', (spec) => {
        if (spec.id === 'E15') {
          newSpecDetected = true;
        }
      });

      // Act: Add new spec file
      const newSpecPath = path.join(testDir, 'specs', 'E15', 'E15.spec.md');
      await fs.mkdir(path.dirname(newSpecPath), { recursive: true });
      await fs.writeFile(
        newSpecPath,
        `---
id: E15
title: New Epic
type: epic
status: draft
priority: low
created: 2025-01-06
updated: 2025-01-06
---

# New Epic`,
        'utf-8',
      );

      // Wait for file to be detected and processed
      await waitFor(() => newSpecDetected, {
        timeout: 2000,
        message: 'New spec not detected',
      });

      // Assert: New spec added to registry
      const newSpec = registry.get('E15');
      expect(newSpec).toBeDefined();
      expect(newSpec?.metadata.title).toBe('New Epic');
    });

    /**
     * Test: Should detect spec file updates
     * Validates file modification detection
     */
    it('should detect and reparse modified spec files', async () => {
      // Setup: Initialize with existing specs
      const specPaths = await discovery.discoverSpecs(path.join(testDir, 'specs'));
      for (const specPath of specPaths) {
        const parsed = await parser.parseFile(specPath);
        registry.upsert(parsed);
      }

      // Start watching
      await watcher.startWatching([path.join(testDir, 'specs')]);

      // Track updates
      let updateDetected = false;
      eventBus.on('spec:updated', (spec) => {
        if (spec.id === 'E13-F01' && spec.metadata.status === 'in-progress') {
          updateDetected = true;
        }
      });

      // Act: Modify existing spec
      const specPath = path.join(testDir, 'specs', 'E13', 'F01', 'spec.md');
      const content = await fs.readFile(specPath, 'utf-8');
      const updatedContent = content.replace('status: draft', 'status: in-progress');
      await fs.writeFile(specPath, updatedContent, 'utf-8');

      // Wait for update to be detected
      await waitFor(() => updateDetected, {
        timeout: 2000,
        message: 'Spec update not detected',
      });

      // Assert: Spec updated in registry
      const updatedSpec = registry.get('E13-F01');
      expect(updatedSpec?.metadata.status).toBe('in-progress');
    });

    /**
     * Test: Should detect spec file deletion
     * Validates file deletion detection
     */
    it('should detect and handle deleted spec files', async () => {
      // Setup: Initialize with existing specs
      const specPaths = await discovery.discoverSpecs(path.join(testDir, 'specs'));
      for (const specPath of specPaths) {
        const parsed = await parser.parseFile(specPath);
        registry.upsert(parsed);
      }

      // Start watching
      await watcher.startWatching([path.join(testDir, 'specs')]);

      // Track deletions
      let deleteDetected = false;
      eventBus.on('spec:deleted', (spec) => {
        if (spec.id === 'E14') {
          deleteDetected = true;
        }
      });

      // Act: Delete spec file
      const specPath = path.join(testDir, 'specs', 'E14', 'E14.spec.md');
      await fs.unlink(specPath);

      // Wait for deletion to be detected
      await waitFor(() => deleteDetected, {
        timeout: 2000,
        message: 'Spec deletion not detected',
      });

      // Assert: Spec removed from registry
      const deletedSpec = registry.get('E14');
      expect(deletedSpec).toBeUndefined();
    });

    /**
     * Test: Should handle rapid file changes
     * Validates debouncing of rapid changes
     */
    it('should debounce rapid file changes', async () => {
      // Setup: Initialize and start watching
      const specPaths = await discovery.discoverSpecs(path.join(testDir, 'specs'));
      for (const specPath of specPaths) {
        const parsed = await parser.parseFile(specPath);
        registry.upsert(parsed);
      }

      await watcher.startWatching([path.join(testDir, 'specs')]);

      // Track update events
      const updateEvents: any[] = [];
      eventBus.on('spec:updated', (spec) => {
        if (spec.id === 'E13') {
          updateEvents.push(spec);
        }
      });

      // Act: Make rapid changes to same file
      const specPath = path.join(testDir, 'specs', 'E13', 'E13.spec.md');
      for (let i = 0; i < 5; i++) {
        const content = await fs.readFile(specPath, 'utf-8');
        const updatedContent = content.replace(/title: .*/, `title: Updated Title ${i}`);
        await fs.writeFile(specPath, updatedContent, 'utf-8');
        await new Promise((resolve) => setTimeout(resolve, 20)); // Small delay
      }

      // Wait for debounced update
      await new Promise((resolve) => setTimeout(resolve, 500));

      // Assert: Updates were debounced
      expect(updateEvents.length).toBeLessThan(5); // Should be debounced

      const finalSpec = registry.get('E13');
      expect(finalSpec?.metadata.title).toContain('Updated Title');
    });
  });

  describe('Performance with Real Files', () => {
    /**
     * Test: Should handle large number of spec files
     * Validates performance with many files
     */
    it('should efficiently process 100+ spec files', async () => {
      // Setup: Create many spec files
      const specPromises = [];
      for (let e = 0; e < 10; e++) {
        for (let f = 0; f < 10; f++) {
          const specPath = path.join(testDir, 'specs', `E${e}`, `F${f}`, 'spec.md');
          const content = `---
id: E${e}-F${f}
title: Feature ${e}-${f}
parent: E${e}
type: feature
status: draft
priority: medium
created: 2025-01-05
updated: 2025-01-06
---

# Feature ${e}-${f}`;

          specPromises.push(
            fs
              .mkdir(path.dirname(specPath), { recursive: true })
              .then(() => fs.writeFile(specPath, content, 'utf-8')),
          );
        }
      }

      await Promise.all(specPromises);

      // Act: Measure discovery and parsing time
      const perf = new PerformanceMonitor('bulkProcess');
      perf.start();

      const specPaths = await discovery.discoverSpecs(path.join(testDir, 'specs'));

      const parsePromises = specPaths.map(async (specPath) => {
        const parsed = await parser.parseFile(specPath);
        registry.upsert(parsed);
      });

      await Promise.all(parsePromises);

      const metrics = perf.end();

      // Assert: Processed efficiently
      expect(specPaths.length).toBeGreaterThanOrEqual(100);
      expect(registry.getAll().length).toBeGreaterThanOrEqual(100);
      expect(metrics.duration).toBeLessThan(5000); // < 5 seconds for 100+ files
    });

    /**
     * Test: Should handle deep directory structures
     * Validates recursive directory traversal
     */
    it('should discover specs in deeply nested directories', async () => {
      // Setup: Create deep directory structure
      const deepPath = path.join(
        testDir,
        'specs',
        'level1',
        'level2',
        'level3',
        'level4',
        'level5',
      );
      await fs.mkdir(deepPath, { recursive: true });

      const specContent = `---
id: E99-F99-T99
title: Deep Spec
parent: E99-F99
type: task
status: draft
priority: low
created: 2025-01-05
updated: 2025-01-06
---

# Deep Spec`;

      await fs.writeFile(path.join(deepPath, 'deep.spec.md'), specContent, 'utf-8');

      // Act: Discover specs including deep ones
      const specPaths = await discovery.discoverSpecs(path.join(testDir, 'specs'));

      // Assert: Deep spec discovered
      const deepSpecPath = specPaths.find((p) => p.includes('deep.spec.md'));
      expect(deepSpecPath).toBeDefined();

      if (deepSpecPath) {
        const parsed = await parser.parseFile(deepSpecPath);
        expect(parsed.metadata.id).toBe('E99-F99-T99');
      }
    });
  });

  describe('Error Recovery Scenarios', () => {
    /**
     * Test: Should recover from file system errors
     * Validates handling of permission errors, etc.
     */
    it('should handle file permission errors gracefully', async () => {
      // Setup: Create a spec file
      const restrictedPath = path.join(testDir, 'specs', 'restricted.spec.md');
      await fs.writeFile(
        restrictedPath,
        `---
id: E99
title: Restricted
type: epic
status: draft
priority: medium
created: 2025-01-05
updated: 2025-01-06
---

# Restricted`,
        'utf-8',
      );

      // Make file unreadable (simulate permission error)
      await fs.chmod(restrictedPath, 0o000);

      // Act: Try to discover and parse
      const specPaths = await discovery.discoverSpecs(path.join(testDir, 'specs'));
      const results = await Promise.allSettled(
        specPaths.map((specPath) => parser.parseFile(specPath)),
      );

      // Restore permissions for cleanup
      await fs.chmod(restrictedPath, 0o644);

      // Assert: Other files processed despite error
      const successful = results.filter((r) => r.status === 'fulfilled');
      expect(successful.length).toBeGreaterThan(0);

      // Verify error was logged
      expect(mockLogger.error).toHaveBeenCalledWith(
        expect.stringContaining('Failed to read file'),
        expect.any(Object),
      );
    });

    /**
     * Test: Should handle corrupted spec files
     * Validates recovery from corrupted content
     */
    it('should continue processing when encountering corrupted files', async () => {
      // Setup: Create a corrupted spec file (binary content)
      const corruptedPath = path.join(testDir, 'specs', 'corrupted.spec.md');
      const binaryContent = Buffer.from([0xff, 0xfe, 0x00, 0x00, 0xff, 0xff]);
      await fs.writeFile(corruptedPath, binaryContent);

      // Act: Process all files
      const specPaths = await discovery.discoverSpecs(path.join(testDir, 'specs'));
      const results = await Promise.allSettled(
        specPaths.map(async (specPath) => {
          try {
            const parsed = await parser.parseFile(specPath);
            registry.upsert(parsed);
            return parsed;
          } catch (error) {
            // Log but continue
            console.log(`Failed to parse ${specPath}: ${error}`);
            throw error;
          }
        }),
      );

      // Assert: Valid files processed
      const successful = results.filter((r) => r.status === 'fulfilled');
      expect(successful).toHaveLength(5); // Original 5 valid files
      expect(registry.getAll()).toHaveLength(5);
    });

    /**
     * Test: Should handle file system race conditions
     * Validates handling of files that disappear during processing
     */
    it('should handle files that disappear during processing', async () => {
      // Setup: Create a temporary spec
      const tempPath = path.join(testDir, 'specs', 'temp.spec.md');
      await fs.writeFile(
        tempPath,
        `---
id: TEMP
title: Temporary
type: epic
status: draft
priority: low
created: 2025-01-05
updated: 2025-01-06
---

# Temp`,
        'utf-8',
      );

      // Act: Discover files, then delete one before parsing
      const specPaths = await discovery.discoverSpecs(path.join(testDir, 'specs'));

      // Delete the temp file
      await fs.unlink(tempPath);

      // Try to parse all discovered files
      const results = await Promise.allSettled(
        specPaths.map((specPath) => parser.parseFile(specPath)),
      );

      // Assert: Other files still processed
      const successful = results.filter((r) => r.status === 'fulfilled');
      const failed = results.filter((r) => r.status === 'rejected');

      expect(successful).toHaveLength(5); // Original 5 files
      expect(failed).toHaveLength(1); // The deleted temp file
    });
  });

  describe('Module Integration', () => {
    /**
     * Test: Should initialize complete parser module
     * Validates module initialization and dependency injection
     */
    it('should initialize parser module with all services', async () => {
      // Act: Initialize parser module
      const module = new ParserModule({
        specsDirectory: path.join(testDir, 'specs'),
        watchEnabled: true,
        logger: mockLogger,
      });

      await module.initialize();

      // Assert: All services initialized
      expect(module.getParser()).toBeDefined();
      expect(module.getRegistry()).toBeDefined();
      expect(module.getDiscovery()).toBeDefined();
      expect(module.getWatcher()).toBeDefined();

      // Verify specs loaded
      const specs = module.getRegistry().getAll();
      expect(specs).toHaveLength(5);

      // Cleanup
      await module.shutdown();
    });

    /**
     * Test: Should handle module lifecycle correctly
     * Validates proper startup and shutdown
     */
    it('should handle module lifecycle (init, run, shutdown)', async () => {
      // Setup: Track lifecycle events
      const lifecycleEvents: string[] = [];

      eventBus.on('module:initializing', () => lifecycleEvents.push('initializing'));
      eventBus.on('module:ready', () => lifecycleEvents.push('ready'));
      eventBus.on('module:shutting-down', () => lifecycleEvents.push('shutting-down'));
      eventBus.on('module:shutdown', () => lifecycleEvents.push('shutdown'));

      // Act: Run full lifecycle
      const module = new ParserModule({
        specsDirectory: path.join(testDir, 'specs'),
        watchEnabled: false,
        logger: mockLogger,
        eventBus,
      });

      await module.initialize();
      await new Promise((resolve) => setTimeout(resolve, 100)); // Let it run
      await module.shutdown();

      // Assert: Lifecycle events in correct order
      expect(lifecycleEvents).toEqual(['initializing', 'ready', 'shutting-down', 'shutdown']);
    });
  });
});
