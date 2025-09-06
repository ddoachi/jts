/**
 * Test Utilities for Spec Parser Service
 *
 * This file provides comprehensive testing utilities and helper functions
 * for testing the spec parser service components.
 *
 * WHAT THIS PROVIDES:
 * - File system mocking utilities
 * - Assertion helpers for spec validation
 * - Performance measurement tools
 * - Test data generators
 * - Mock service factories
 */

import * as fs from 'fs/promises';
import * as path from 'path';
import { EventEmitter } from 'events';

/**
 * Creates a temporary test directory with spec files
 * Useful for integration tests that need real file system
 *
 * @example
 * const testDir = await createTestSpecDirectory([
 *   { path: 'E13/E13.spec.md', content: validEpicContent },
 *   { path: 'E13/F01/spec.md', content: validFeatureContent }
 * ]);
 * // Run tests...
 * await cleanupTestDirectory(testDir);
 */
export async function createTestSpecDirectory(specs: Array<{ path: string; content: string }>) {
  // Create temp directory with timestamp to avoid conflicts
  const tempDir = path.join(process.cwd(), 'temp', `test-specs-${Date.now()}`);

  // Create all spec files
  for (const spec of specs) {
    const fullPath = path.join(tempDir, 'specs', spec.path);
    await fs.mkdir(path.dirname(fullPath), { recursive: true });
    await fs.writeFile(fullPath, spec.content, 'utf-8');
  }

  return tempDir;
}

/**
 * Cleans up temporary test directory
 * Always call this in afterEach or finally block
 */
export async function cleanupTestDirectory(testDir: string) {
  try {
    await fs.rm(testDir, { recursive: true, force: true });
  } catch (error) {
    console.warn(`Failed to cleanup test directory: ${testDir}`, error);
  }
}

/**
 * Creates a mock file system for unit tests
 * Avoids actual file I/O for faster tests
 *
 * @example
 * const mockFs = createMockFileSystem({
 *   '/specs/E13/E13.spec.md': 'file content here',
 *   '/specs/E13/F01/spec.md': 'another file'
 * });
 */
export function createMockFileSystem(files: Record<string, string>) {
  const fileSystem = new Map(Object.entries(files));

  return {
    // Mock fs.readFile
    readFile: jest.fn(async (path: string) => {
      if (!fileSystem.has(path)) {
        throw new Error(`ENOENT: no such file or directory, open '${path}'`);
      }
      return fileSystem.get(path);
    }),

    // Mock fs.stat
    stat: jest.fn(async (path: string) => {
      if (!fileSystem.has(path)) {
        throw new Error(`ENOENT: no such file or directory, stat '${path}'`);
      }
      return {
        isFile: () => true,
        isDirectory: () => false,
        size: fileSystem.get(path)!.length,
        mtime: new Date(),
      };
    }),

    // Mock glob pattern matching
    glob: jest.fn((pattern: string) => {
      const regex = pattern.replace(/\*\*/g, '.*').replace(/\*/g, '[^/]*').replace(/\?/g, '.');

      return Array.from(fileSystem.keys()).filter((path) => new RegExp(regex).test(path));
    }),

    // Add a file to mock filesystem
    addFile: (path: string, content: string) => {
      fileSystem.set(path, content);
    },

    // Remove a file from mock filesystem
    removeFile: (path: string) => {
      fileSystem.delete(path);
    },

    // Get all files
    getAllFiles: () => Array.from(fileSystem.entries()),
  };
}

/**
 * Assertion helper for validating parsed specs
 * Provides detailed error messages for test failures
 *
 * @example
 * const parsed = await parser.parseFile(path);
 * assertValidSpec(parsed, {
 *   id: 'E13-F01',
 *   type: 'feature',
 *   status: 'draft'
 * });
 */
export function assertValidSpec(actual: any, expected: Partial<any>) {
  // Check that actual is an object
  expect(actual).toBeDefined();
  expect(typeof actual).toBe('object');

  // Validate metadata exists
  if (expected.id !== undefined) {
    expect(actual.metadata?.id).toBe(expected.id);
  }

  if (expected.type !== undefined) {
    expect(actual.metadata?.type).toBe(expected.type);
  }

  if (expected.status !== undefined) {
    expect(actual.metadata?.status).toBe(expected.status);
  }

  if (expected.title !== undefined) {
    expect(actual.metadata?.title).toBe(expected.title);
  }

  // Validate hierarchy if provided
  if (expected.hierarchy) {
    expect(actual.hierarchy).toMatchObject(expected.hierarchy);
  }

  // Validate content exists
  expect(actual.content).toBeDefined();
  expect(typeof actual.content).toBe('string');

  // Validate path exists
  expect(actual.path).toBeDefined();
  expect(typeof actual.path).toBe('string');
}

/**
 * Performance testing utility
 * Measures execution time and memory usage
 *
 * @example
 * const perf = new PerformanceMonitor('Parser');
 * perf.start();
 * await parser.parseFile(path);
 * const metrics = perf.end();
 * expect(metrics.duration).toBeLessThan(100); // ms
 */
export class PerformanceMonitor {
  private name: string;
  private startTime?: number;
  private startMemory?: number;

  constructor(name: string) {
    this.name = name;
  }

  start() {
    this.startTime = Date.now();
    if (global.gc) global.gc(); // Force GC if available
    this.startMemory = process.memoryUsage().heapUsed;
  }

  end() {
    if (!this.startTime || !this.startMemory) {
      throw new Error('PerformanceMonitor.start() must be called first');
    }

    const duration = Date.now() - this.startTime;
    const memoryDelta = process.memoryUsage().heapUsed - this.startMemory;

    return {
      name: this.name,
      duration, // milliseconds
      memoryDelta, // bytes
      memoryDeltaMB: memoryDelta / 1024 / 1024,
    };
  }

  // Log performance metrics
  log() {
    const metrics = this.end();
    console.log(
      `[PERF] ${metrics.name}: ${metrics.duration}ms, ${metrics.memoryDeltaMB.toFixed(2)}MB`,
    );
    return metrics;
  }
}

/**
 * Creates a mock EventEmitter for testing event-driven components
 * Tracks all emitted events for assertions
 *
 * @example
 * const emitter = createMockEventEmitter();
 * service.on('spec:updated', emitter.handler);
 * await service.updateSpec(spec);
 * expect(emitter.events).toContainEqual({
 *   event: 'spec:updated',
 *   data: expect.objectContaining({ id: 'E13-F01' })
 * });
 */
export function createMockEventEmitter() {
  const events: Array<{ event: string; data: any }> = [];
  const emitter = new EventEmitter();

  // Track all events
  const originalEmit = emitter.emit.bind(emitter);
  emitter.emit = (event: string, ...args: any[]) => {
    events.push({ event, data: args[0] });
    return originalEmit(event, ...args);
  };

  return {
    emitter,
    events,
    handler: (data: any) => {
      // Generic handler for testing
    },

    // Helper to wait for specific event
    waitForEvent: (eventName: string, timeout = 1000) => {
      return new Promise((resolve, reject) => {
        const timer = setTimeout(() => {
          reject(new Error(`Timeout waiting for event: ${eventName}`));
        }, timeout);

        emitter.once(eventName, (data) => {
          clearTimeout(timer);
          resolve(data);
        });
      });
    },

    // Clear all tracked events
    clear: () => {
      events.length = 0;
    },
  };
}

/**
 * Creates a mock logger for testing
 * Captures all log messages for assertions
 *
 * @example
 * const logger = createMockLogger();
 * service.setLogger(logger);
 * await service.parseFile('invalid.md');
 * expect(logger.errors).toContainEqual(
 *   expect.stringContaining('Failed to parse')
 * );
 */
export function createMockLogger() {
  const logs = {
    debug: [] as string[],
    info: [] as string[],
    warn: [] as string[],
    error: [] as string[],
  };

  return {
    debug: jest.fn((msg: string, ...args: any[]) => logs.debug.push(msg)),
    info: jest.fn((msg: string, ...args: any[]) => logs.info.push(msg)),
    warn: jest.fn((msg: string, ...args: any[]) => logs.warn.push(msg)),
    error: jest.fn((msg: string, ...args: any[]) => logs.error.push(msg)),

    // Access to captured logs
    logs,

    // Clear all logs
    clear: () => {
      Object.keys(logs).forEach((key) => {
        (logs as any)[key].length = 0;
      });
    },

    // Check if specific message was logged
    hasLog: (level: keyof typeof logs, pattern: string | RegExp) => {
      return logs[level].some((msg) =>
        typeof pattern === 'string' ? msg.includes(pattern) : pattern.test(msg),
      );
    },
  };
}

/**
 * Waits for a condition to become true
 * Useful for testing async operations
 *
 * @example
 * await waitFor(() => registry.get('E13-F01') !== undefined, {
 *   timeout: 5000,
 *   interval: 100,
 *   message: 'Spec not found in registry'
 * });
 */
export async function waitFor(
  condition: () => boolean | Promise<boolean>,
  options: {
    timeout?: number;
    interval?: number;
    message?: string;
  } = {},
) {
  const { timeout = 5000, interval = 100, message = 'Condition not met' } = options;
  const startTime = Date.now();

  while (Date.now() - startTime < timeout) {
    const result = await condition();
    if (result) return;

    await new Promise((resolve) => setTimeout(resolve, interval));
  }

  throw new Error(`Timeout: ${message}`);
}

/**
 * Creates a test sandbox with all mocks configured
 * Provides a complete testing environment
 *
 * @example
 * const sandbox = createTestSandbox();
 * const parser = new SpecParser(sandbox.fs, sandbox.logger);
 * // Run tests...
 * sandbox.cleanup();
 */
export function createTestSandbox() {
  const fs = createMockFileSystem({});
  const logger = createMockLogger();
  const events = createMockEventEmitter();
  const performance = new PerformanceMonitor('Test');

  return {
    fs,
    logger,
    events,
    performance,

    // Cleanup all mocks
    cleanup: () => {
      jest.clearAllMocks();
      events.clear();
      logger.clear();
    },

    // Reset to initial state
    reset: () => {
      fs.getAllFiles().forEach(([path]) => fs.removeFile(path));
      events.clear();
      logger.clear();
    },
  };
}

/**
 * Generates random spec data for stress testing
 *
 * @example
 * const specs = generateRandomSpecs(100);
 * for (const spec of specs) {
 *   await registry.upsert(spec);
 * }
 */
export function generateRandomSpecs(count: number) {
  const specs = [];
  const statuses = ['draft', 'in-progress', 'completed'];
  const priorities = ['low', 'medium', 'high', 'critical'];
  const types = ['epic', 'feature', 'task'];

  for (let i = 0; i < count; i++) {
    const type = types[i % 3];
    let id = '';

    if (type === 'epic') {
      id = `E${Math.floor(i / 10)}`;
    } else if (type === 'feature') {
      id = `E${Math.floor(i / 100)}-F${Math.floor(i / 10) % 10}`;
    } else {
      id = `E${Math.floor(i / 100)}-F${Math.floor(i / 10) % 10}-T${i % 10}`;
    }

    specs.push({
      id,
      metadata: {
        id,
        title: `Generated Spec ${i}`,
        type,
        status: statuses[Math.floor(Math.random() * statuses.length)],
        priority: priorities[Math.floor(Math.random() * priorities.length)],
        created: new Date(Date.now() - Math.random() * 30 * 24 * 60 * 60 * 1000).toISOString(),
        updated: new Date().toISOString(),
      },
      content: `# ${id}: Generated Spec ${i}\n\n${'Lorem ipsum '.repeat(100)}`,
      path: `/specs/${id.replace(/-/g, '/')}/spec.md`,
      hierarchy: {
        level: type as any,
        parentId: type === 'epic' ? undefined : id.substring(0, id.lastIndexOf('-')),
        childIds: [],
        depth: type === 'epic' ? 0 : type === 'feature' ? 1 : 2,
      },
    });
  }

  return specs;
}

/**
 * Snapshot testing helper for spec structures
 *
 * @example
 * const tree = registry.getTree();
 * expectSpecSnapshot(tree, 'spec-tree-structure');
 */
export function expectSpecSnapshot(data: any, snapshotName: string) {
  // Remove dynamic fields that change between test runs
  const cleaned = JSON.parse(
    JSON.stringify(data, (key, value) => {
      if (key === 'parsedAt' || key === 'checksum') return '[DYNAMIC]';
      if (key === 'updated' && value.includes('T')) return '[TIMESTAMP]';
      return value;
    }),
  );

  expect(cleaned).toMatchSnapshot(snapshotName);
}
