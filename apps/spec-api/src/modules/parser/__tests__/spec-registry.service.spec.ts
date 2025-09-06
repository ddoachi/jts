/**
 * Unit Tests for SpecRegistryService
 * 
 * This test file validates the in-memory spec registry functionality.
 * It tests CRUD operations, relationship management, tree building, and event emission.
 * 
 * TEST COVERAGE:
 * - Spec storage and retrieval (O(1) performance)
 * - Parent-child relationship management
 * - Tree structure generation
 * - Event emission on changes
 * - Memory efficiency with large datasets
 * - Concurrent access handling
 */

import { SpecRegistryService } from '../services/spec-registry.service';
import {
  VALID_EPIC_SPEC,
  VALID_FEATURE_SPEC,
  VALID_TASK_SPEC,
  createMockSpec
} from './fixtures/mock-specs';
import {
  createMockEventEmitter,
  PerformanceMonitor,
  generateRandomSpecs,
  waitFor,
  expectSpecSnapshot,
  createMockLogger
} from './helpers/test-utils';

describe('SpecRegistryService', () => {
  let registry: SpecRegistryService;
  let mockEvents: ReturnType<typeof createMockEventEmitter>;
  let mockLogger: ReturnType<typeof createMockLogger>;

  /**
   * Helper to create a parsed spec object
   */
  const createParsedSpec = (id: string, type: 'epic' | 'feature' | 'task', parentId?: string) => {
    return {
      id,
      metadata: {
        id,
        title: `${type} ${id}`,
        type,
        status: 'draft' as const,
        priority: 'medium' as const,
        created: '2025-01-05',
        updated: '2025-01-06',
        parent: parentId
      },
      content: `# ${id}\n\nContent for ${id}`,
      path: `/specs/${id.replace(/-/g, '/')}/spec.md`,
      hierarchy: {
        level: type,
        parentId,
        childIds: [],
        depth: type === 'epic' ? 0 : type === 'feature' ? 1 : 2
      },
      parsedAt: new Date(),
      checksum: `hash-${id}`
    };
  };

  beforeEach(() => {
    mockEvents = createMockEventEmitter();
    mockLogger = createMockLogger();
    registry = new SpecRegistryService(mockEvents.emitter, mockLogger);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('Core CRUD Operations', () => {
    /**
     * Test: Should store and retrieve specs
     * Validates basic storage functionality
     */
    it('should store and retrieve specs by ID', () => {
      // Arrange: Create test spec
      const spec = createParsedSpec('E13', 'epic');
      
      // Act: Store spec
      registry.upsert(spec);
      
      // Assert: Can retrieve spec
      const retrieved = registry.get('E13');
      expect(retrieved).toBeDefined();
      expect(retrieved?.id).toBe('E13');
      expect(retrieved?.metadata.title).toBe('epic E13');
    });

    /**
     * Test: Should update existing specs
     * Validates update functionality
     */
    it('should update existing spec when upserted', () => {
      // Arrange: Create and store initial spec
      const spec = createParsedSpec('E13-F01', 'feature', 'E13');
      registry.upsert(spec);
      
      // Act: Update spec with new data
      const updatedSpec = {
        ...spec,
        metadata: {
          ...spec.metadata,
          status: 'in-progress' as const,
          title: 'Updated Feature'
        }
      };
      registry.upsert(updatedSpec);
      
      // Assert: Spec was updated
      const retrieved = registry.get('E13-F01');
      expect(retrieved?.metadata.status).toBe('in-progress');
      expect(retrieved?.metadata.title).toBe('Updated Feature');
    });

    /**
     * Test: Should delete specs
     * Validates deletion functionality
     */
    it('should delete spec and clean up relationships', () => {
      // Arrange: Create parent and child specs
      const parent = createParsedSpec('E13', 'epic');
      const child = createParsedSpec('E13-F01', 'feature', 'E13');
      
      registry.upsert(parent);
      registry.upsert(child);
      
      // Act: Delete child spec
      registry.delete('E13-F01');
      
      // Assert: Child deleted, parent's children updated
      expect(registry.get('E13-F01')).toBeUndefined();
      expect(registry.getChildren('E13')).toHaveLength(0);
    });

    /**
     * Test: Should return undefined for non-existent specs
     * Validates behavior for missing specs
     */
    it('should return undefined for non-existent spec IDs', () => {
      // Act & Assert: Non-existent spec returns undefined
      expect(registry.get('NON-EXISTENT')).toBeUndefined();
      expect(registry.getChildren('NON-EXISTENT')).toEqual([]);
    });

    /**
     * Test: Should get all specs
     * Validates retrieval of all stored specs
     */
    it('should retrieve all stored specs', () => {
      // Arrange: Store multiple specs
      const specs = [
        createParsedSpec('E13', 'epic'),
        createParsedSpec('E13-F01', 'feature', 'E13'),
        createParsedSpec('E13-F02', 'feature', 'E13'),
        createParsedSpec('E14', 'epic')
      ];
      
      specs.forEach(spec => registry.upsert(spec));
      
      // Act: Get all specs
      const allSpecs = registry.getAll();
      
      // Assert: All specs returned
      expect(allSpecs).toHaveLength(4);
      expect(allSpecs.map(s => s.id).sort()).toEqual([
        'E13', 'E13-F01', 'E13-F02', 'E14'
      ]);
    });
  });

  describe('Relationship Management', () => {
    /**
     * Test: Should maintain parent-child relationships
     * Validates hierarchical structure management
     */
    it('should maintain parent-child relationships correctly', () => {
      // Arrange: Create hierarchical specs
      const epic = createParsedSpec('E13', 'epic');
      const feature1 = createParsedSpec('E13-F01', 'feature', 'E13');
      const feature2 = createParsedSpec('E13-F02', 'feature', 'E13');
      const task1 = createParsedSpec('E13-F01-T01', 'task', 'E13-F01');
      const task2 = createParsedSpec('E13-F01-T02', 'task', 'E13-F01');
      
      // Act: Store all specs
      [epic, feature1, feature2, task1, task2].forEach(spec => 
        registry.upsert(spec)
      );
      
      // Assert: Relationships are correct
      expect(registry.getChildren('E13')).toHaveLength(2);
      expect(registry.getChildren('E13').map(s => s.id)).toContain('E13-F01');
      expect(registry.getChildren('E13').map(s => s.id)).toContain('E13-F02');
      
      expect(registry.getChildren('E13-F01')).toHaveLength(2);
      expect(registry.getChildren('E13-F01').map(s => s.id)).toContain('E13-F01-T01');
      expect(registry.getChildren('E13-F01').map(s => s.id)).toContain('E13-F01-T02');
      
      expect(registry.getChildren('E13-F02')).toHaveLength(0);
    });

    /**
     * Test: Should update children when parent is deleted
     * Validates orphan handling
     */
    it('should handle orphaned specs when parent is deleted', () => {
      // Arrange: Create parent-child relationship
      const parent = createParsedSpec('E13-F01', 'feature', 'E13');
      const child = createParsedSpec('E13-F01-T01', 'task', 'E13-F01');
      
      registry.upsert(parent);
      registry.upsert(child);
      
      // Act: Delete parent
      registry.delete('E13-F01');
      
      // Assert: Child becomes orphaned but still exists
      const orphan = registry.get('E13-F01-T01');
      expect(orphan).toBeDefined();
      expect(orphan?.hierarchy.parentId).toBe('E13-F01'); // Parent ID preserved
      
      // Verify warning was logged
      expect(mockLogger.warn).toHaveBeenCalledWith(
        expect.stringContaining('Orphaned spec'),
        expect.objectContaining({ specId: 'E13-F01-T01' })
      );
    });

    /**
     * Test: Should handle circular parent references
     * Validates protection against circular dependencies
     */
    it('should prevent circular parent references', () => {
      // Arrange: Create two specs
      const spec1 = createParsedSpec('E13-F01', 'feature', 'E13-F02');
      const spec2 = createParsedSpec('E13-F02', 'feature', 'E13-F01');
      
      // Act: Try to create circular reference
      registry.upsert(spec1);
      registry.upsert(spec2);
      
      // Assert: Circular reference detected and logged
      expect(mockLogger.error).toHaveBeenCalledWith(
        expect.stringContaining('Circular reference detected'),
        expect.any(Object)
      );
    });
  });

  describe('Tree Structure Generation', () => {
    /**
     * Test: Should build complete tree structure
     * Validates tree generation from flat structure
     */
    it('should build complete hierarchical tree', () => {
      // Arrange: Create complete hierarchy
      const specs = [
        createParsedSpec('E13', 'epic'),
        createParsedSpec('E13-F01', 'feature', 'E13'),
        createParsedSpec('E13-F01-T01', 'task', 'E13-F01'),
        createParsedSpec('E13-F01-T02', 'task', 'E13-F01'),
        createParsedSpec('E13-F02', 'feature', 'E13'),
        createParsedSpec('E14', 'epic'),
        createParsedSpec('E14-F01', 'feature', 'E14')
      ];
      
      specs.forEach(spec => registry.upsert(spec));
      
      // Act: Get tree structure
      const tree = registry.getTree();
      
      // Assert: Tree structure is correct
      expect(tree).toHaveLength(2); // Two root epics
      
      const e13Tree = tree.find(node => node.spec.id === 'E13');
      expect(e13Tree).toBeDefined();
      expect(e13Tree?.children).toHaveLength(2); // Two features
      
      const e13f01Tree = e13Tree?.children.find(node => node.spec.id === 'E13-F01');
      expect(e13f01Tree).toBeDefined();
      expect(e13f01Tree?.children).toHaveLength(2); // Two tasks
    });

    /**
     * Test: Should handle empty registry
     * Validates tree generation with no specs
     */
    it('should return empty tree for empty registry', () => {
      // Act: Get tree from empty registry
      const tree = registry.getTree();
      
      // Assert: Empty array returned
      expect(tree).toEqual([]);
    });

    /**
     * Test: Should handle orphaned specs in tree
     * Validates tree with missing parents
     */
    it('should include orphaned specs at root level', () => {
      // Arrange: Create orphaned specs (missing parents)
      const specs = [
        createParsedSpec('E13', 'epic'),
        createParsedSpec('E13-F01', 'feature', 'E13'),
        createParsedSpec('E99-F01-T01', 'task', 'E99-F01') // Orphaned - parent doesn't exist
      ];
      
      specs.forEach(spec => registry.upsert(spec));
      
      // Act: Get tree
      const tree = registry.getTree();
      
      // Assert: Orphaned spec appears at root
      expect(tree).toHaveLength(2); // E13 and orphaned task
      const orphanNode = tree.find(node => node.spec.id === 'E99-F01-T01');
      expect(orphanNode).toBeDefined();
    });

    /**
     * Test: Should preserve tree node metadata
     * Validates additional tree node properties
     */
    it('should include expanded state in tree nodes', () => {
      // Arrange: Create specs
      const specs = [
        createParsedSpec('E13', 'epic'),
        createParsedSpec('E13-F01', 'feature', 'E13')
      ];
      
      specs.forEach(spec => registry.upsert(spec));
      
      // Act: Get tree
      const tree = registry.getTree();
      
      // Assert: Tree nodes have expanded property
      expect(tree[0].expanded).toBeDefined();
      expect(typeof tree[0].expanded).toBe('boolean');
    });
  });

  describe('Event Emission', () => {
    /**
     * Test: Should emit events on spec changes
     * Validates event system integration
     */
    it('should emit spec:created event on new spec', async () => {
      // Arrange: Create spec
      const spec = createParsedSpec('E13', 'epic');
      
      // Act: Insert spec
      registry.upsert(spec);
      
      // Assert: Event emitted
      await waitFor(() => mockEvents.events.length > 0);
      expect(mockEvents.events).toContainEqual({
        event: 'spec:created',
        data: expect.objectContaining({ id: 'E13' })
      });
    });

    /**
     * Test: Should emit spec:updated event on update
     * Validates update event emission
     */
    it('should emit spec:updated event on existing spec update', async () => {
      // Arrange: Create and store spec
      const spec = createParsedSpec('E13', 'epic');
      registry.upsert(spec);
      mockEvents.clear();
      
      // Act: Update spec
      const updated = { ...spec, metadata: { ...spec.metadata, status: 'completed' as const } };
      registry.upsert(updated);
      
      // Assert: Update event emitted
      await waitFor(() => mockEvents.events.length > 0);
      expect(mockEvents.events).toContainEqual({
        event: 'spec:updated',
        data: expect.objectContaining({ id: 'E13' })
      });
    });

    /**
     * Test: Should emit spec:deleted event
     * Validates deletion event emission
     */
    it('should emit spec:deleted event on deletion', async () => {
      // Arrange: Create and store spec
      const spec = createParsedSpec('E13', 'epic');
      registry.upsert(spec);
      mockEvents.clear();
      
      // Act: Delete spec
      registry.delete('E13');
      
      // Assert: Delete event emitted
      await waitFor(() => mockEvents.events.length > 0);
      expect(mockEvents.events).toContainEqual({
        event: 'spec:deleted',
        data: expect.objectContaining({ id: 'E13' })
      });
    });

    /**
     * Test: Should emit registry:changed event
     * Validates global change event
     */
    it('should emit registry:changed event on any modification', async () => {
      // Arrange: Create spec
      const spec = createParsedSpec('E13', 'epic');
      
      // Act: Multiple operations
      registry.upsert(spec);
      registry.delete('E13');
      
      // Assert: Changed events emitted
      const changedEvents = mockEvents.events.filter(e => e.event === 'registry:changed');
      expect(changedEvents.length).toBeGreaterThanOrEqual(2);
    });
  });

  describe('Performance', () => {
    /**
     * Test: Should provide O(1) lookup performance
     * Validates fast retrieval even with many specs
     */
    it('should maintain O(1) lookup performance with 1000+ specs', () => {
      // Arrange: Generate and store many specs
      const specs = generateRandomSpecs(1000);
      specs.forEach(spec => registry.upsert(spec));
      
      // Act: Measure lookup time
      const perf = new PerformanceMonitor('lookup');
      perf.start();
      
      // Perform 100 lookups
      for (let i = 0; i < 100; i++) {
        const randomId = specs[Math.floor(Math.random() * specs.length)].id;
        registry.get(randomId);
      }
      
      const metrics = perf.end();
      
      // Assert: Fast lookups
      expect(metrics.duration).toBeLessThan(10); // 100 lookups in < 10ms
    });

    /**
     * Test: Should handle large tree generation efficiently
     * Validates tree building performance
     */
    it('should generate tree structure efficiently with many specs', () => {
      // Arrange: Create deep hierarchy
      const specs = [];
      for (let e = 0; e < 10; e++) {
        specs.push(createParsedSpec(`E${e}`, 'epic'));
        for (let f = 0; f < 10; f++) {
          specs.push(createParsedSpec(`E${e}-F${f}`, 'feature', `E${e}`));
          for (let t = 0; t < 5; t++) {
            specs.push(createParsedSpec(`E${e}-F${f}-T${t}`, 'task', `E${e}-F${f}`));
          }
        }
      }
      
      specs.forEach(spec => registry.upsert(spec));
      
      // Act: Measure tree generation
      const perf = new PerformanceMonitor('tree');
      perf.start();
      const tree = registry.getTree();
      const metrics = perf.end();
      
      // Assert: Tree generated quickly
      expect(tree).toHaveLength(10); // 10 root epics
      expect(metrics.duration).toBeLessThan(50); // < 50ms for 510 specs
    });

    /**
     * Test: Should maintain reasonable memory usage
     * Validates memory efficiency
     */
    it('should maintain reasonable memory usage with many specs', () => {
      // Arrange: Measure initial memory
      if (global.gc) global.gc();
      const initialMemory = process.memoryUsage().heapUsed;
      
      // Act: Store 1000 specs
      const specs = generateRandomSpecs(1000);
      specs.forEach(spec => registry.upsert(spec));
      
      // Measure final memory
      if (global.gc) global.gc();
      const finalMemory = process.memoryUsage().heapUsed;
      const memoryUsedMB = (finalMemory - initialMemory) / 1024 / 1024;
      
      // Assert: Memory usage is reasonable
      expect(memoryUsedMB).toBeLessThan(100); // < 100MB for 1000 specs
    });
  });

  describe('Concurrent Access', () => {
    /**
     * Test: Should handle concurrent writes safely
     * Validates thread safety (simulated)
     */
    it('should handle concurrent upserts without data loss', async () => {
      // Arrange: Create specs for concurrent insertion
      const specs = Array.from({ length: 100 }, (_, i) => 
        createParsedSpec(`E${i}`, 'epic')
      );
      
      // Act: Insert specs concurrently
      await Promise.all(
        specs.map(spec => 
          Promise.resolve().then(() => registry.upsert(spec))
        )
      );
      
      // Assert: All specs stored correctly
      expect(registry.getAll()).toHaveLength(100);
      specs.forEach(spec => {
        expect(registry.get(spec.id)).toBeDefined();
      });
    });

    /**
     * Test: Should handle mixed concurrent operations
     * Validates concurrent reads/writes/deletes
     */
    it('should handle mixed concurrent operations safely', async () => {
      // Arrange: Initial specs
      const initialSpecs = Array.from({ length: 50 }, (_, i) => 
        createParsedSpec(`E${i}`, 'epic')
      );
      initialSpecs.forEach(spec => registry.upsert(spec));
      
      // Act: Perform mixed operations concurrently
      const operations = [
        // Inserts
        ...Array.from({ length: 25 }, (_, i) => 
          Promise.resolve().then(() => 
            registry.upsert(createParsedSpec(`E${50 + i}`, 'epic'))
          )
        ),
        // Updates
        ...Array.from({ length: 25 }, (_, i) => 
          Promise.resolve().then(() => {
            const spec = registry.get(`E${i}`);
            if (spec) {
              registry.upsert({
                ...spec,
                metadata: { ...spec.metadata, status: 'completed' as const }
              });
            }
          })
        ),
        // Deletes
        ...Array.from({ length: 10 }, (_, i) => 
          Promise.resolve().then(() => registry.delete(`E${40 + i}`))
        ),
        // Reads
        ...Array.from({ length: 100 }, () => 
          Promise.resolve().then(() => registry.getAll())
        )
      ];
      
      await Promise.all(operations);
      
      // Assert: Registry is in consistent state
      const finalSpecs = registry.getAll();
      expect(finalSpecs.length).toBeGreaterThan(0);
      expect(finalSpecs.length).toBeLessThanOrEqual(75); // Max possible after operations
      
      // Verify no corrupted data
      finalSpecs.forEach(spec => {
        expect(spec.id).toBeDefined();
        expect(spec.metadata).toBeDefined();
      });
    });
  });

  describe('Edge Cases', () => {
    /**
     * Test: Should handle specs with special characters in IDs
     * Validates ID validation
     */
    it('should handle special characters in spec data', () => {
      // Arrange: Spec with special characters
      const spec = createParsedSpec('E13-F01', 'feature', 'E13');
      spec.metadata.title = "Spec with 'quotes' and & symbols";
      spec.content = "Content with émojis 🚀 and ñ special çhars";
      
      // Act: Store and retrieve
      registry.upsert(spec);
      const retrieved = registry.get('E13-F01');
      
      // Assert: Special characters preserved
      expect(retrieved?.metadata.title).toBe("Spec with 'quotes' and & symbols");
      expect(retrieved?.content).toContain("émojis 🚀");
    });

    /**
     * Test: Should handle very deep hierarchies
     * Validates deep nesting support
     */
    it('should handle very deep spec hierarchies', () => {
      // Arrange: Create deep hierarchy (unusual but valid)
      const specs = [
        createParsedSpec('E1', 'epic'),
        createParsedSpec('E1-F1', 'feature', 'E1'),
        createParsedSpec('E1-F1-T1', 'task', 'E1-F1'),
        // Simulate deeper levels with task sub-tasks (edge case)
        { ...createParsedSpec('E1-F1-T1-ST1', 'task', 'E1-F1-T1'), 
          hierarchy: { level: 'task', parentId: 'E1-F1-T1', childIds: [], depth: 3 } },
        { ...createParsedSpec('E1-F1-T1-ST1-SST1', 'task', 'E1-F1-T1-ST1'),
          hierarchy: { level: 'task', parentId: 'E1-F1-T1-ST1', childIds: [], depth: 4 } }
      ];
      
      specs.forEach(spec => registry.upsert(spec as any));
      
      // Act: Build tree
      const tree = registry.getTree();
      
      // Assert: Deep hierarchy preserved
      let currentNode: any = tree[0];
      let depth = 0;
      while (currentNode?.children?.length > 0) {
        currentNode = currentNode.children[0];
        depth++;
      }
      expect(depth).toBeGreaterThanOrEqual(4);
    });

    /**
     * Test: Should handle rapid updates to same spec
     * Validates update deduplication
     */
    it('should handle rapid updates to same spec', async () => {
      // Arrange: Initial spec
      const spec = createParsedSpec('E13', 'epic');
      registry.upsert(spec);
      
      // Act: Rapid updates
      const updates = Array.from({ length: 100 }, (_, i) => ({
        ...spec,
        metadata: { ...spec.metadata, title: `Update ${i}` }
      }));
      
      updates.forEach(update => registry.upsert(update));
      
      // Assert: Last update wins
      const final = registry.get('E13');
      expect(final?.metadata.title).toBe('Update 99');
      
      // Verify reasonable number of events (may be debounced)
      const updateEvents = mockEvents.events.filter(e => 
        e.event === 'spec:updated' && e.data.id === 'E13'
      );
      expect(updateEvents.length).toBeGreaterThan(0);
    });
  });
});