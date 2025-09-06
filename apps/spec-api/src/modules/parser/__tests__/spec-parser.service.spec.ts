/**
 * Unit Tests for SpecParserService
 * 
 * This test file validates the core parsing functionality of the SpecParserService.
 * It tests YAML frontmatter extraction, content parsing, error handling, and validation.
 * 
 * TEST COVERAGE:
 * - Valid spec parsing (all hierarchy levels)
 * - YAML frontmatter extraction
 * - Malformed YAML handling
 * - Missing required fields validation
 * - Special character handling
 * - Performance benchmarks
 */

import { SpecParserService } from '../services/spec-parser.service';
import {
  VALID_EPIC_SPEC,
  VALID_FEATURE_SPEC,
  VALID_TASK_SPEC,
  MALFORMED_YAML_SPEC,
  MISSING_FIELDS_SPEC,
  EMPTY_YAML_SPEC,
  NO_FRONTMATTER_SPEC,
  SPECIAL_CHARS_SPEC,
  LARGE_CONTENT_SPEC,
  INVALID_ID_SPEC,
  createMockSpec
} from './fixtures/mock-specs';
import {
  createMockFileSystem,
  assertValidSpec,
  PerformanceMonitor,
  createMockLogger,
  createTestSandbox
} from './helpers/test-utils';

describe('SpecParserService', () => {
  let parser: SpecParserService;
  let mockFs: ReturnType<typeof createMockFileSystem>;
  let mockLogger: ReturnType<typeof createMockLogger>;
  let sandbox: ReturnType<typeof createTestSandbox>;

  /**
   * Setup before each test
   * Creates fresh instances of parser and mocks
   */
  beforeEach(() => {
    sandbox = createTestSandbox();
    mockFs = sandbox.fs;
    mockLogger = sandbox.logger;
    
    // Initialize parser with mocked dependencies
    parser = new SpecParserService(mockLogger);
    
    // Add test files to mock filesystem
    mockFs.addFile(VALID_EPIC_SPEC.path, VALID_EPIC_SPEC.content);
    mockFs.addFile(VALID_FEATURE_SPEC.path, VALID_FEATURE_SPEC.content);
    mockFs.addFile(VALID_TASK_SPEC.path, VALID_TASK_SPEC.content);
  });

  /**
   * Cleanup after each test
   */
  afterEach(() => {
    sandbox.cleanup();
  });

  describe('parseContent()', () => {
    /**
     * Test: Should successfully parse valid epic spec
     * Validates that epic-level specs are parsed correctly
     */
    it('should parse valid epic spec content', () => {
      // Act: Parse the epic spec content
      const result = parser.parseContent(VALID_EPIC_SPEC.content);
      
      // Assert: Validate the parsed result
      expect(result).toBeDefined();
      expect(result.metadata).toMatchObject({
        id: 'E13',
        title: 'Spec Management API',
        type: 'epic',
        status: 'in-progress',
        priority: 'high'
      });
      expect(result.content).toContain('# E13: Spec Management API');
      expect(result.content).not.toContain('---'); // Frontmatter should be removed
    });

    /**
     * Test: Should successfully parse valid feature spec
     * Validates parent references and feature-level parsing
     */
    it('should parse valid feature spec with parent reference', () => {
      // Act: Parse the feature spec
      const result = parser.parseContent(VALID_FEATURE_SPEC.content);
      
      // Assert: Check parent reference and metadata
      expect(result.metadata).toMatchObject({
        id: 'E13-F01',
        title: 'Spec Parser Service',
        parent: 'E13',
        type: 'feature',
        status: 'draft',
        priority: 'critical'
      });
      expect(result.metadata.dependencies).toEqual(['E13-F02']);
      expect(result.metadata.assignee).toBe('dev-team');
    });

    /**
     * Test: Should successfully parse valid task spec
     * Validates task-level parsing with full hierarchy
     */
    it('should parse valid task spec with complete hierarchy', () => {
      // Act: Parse the task spec
      const result = parser.parseContent(VALID_TASK_SPEC.content);
      
      // Assert: Validate task metadata
      expect(result.metadata).toMatchObject({
        id: 'E13-F01-T01',
        title: 'Core Parser Implementation',
        parent: 'E13-F01',
        type: 'task',
        status: 'completed',
        priority: 'high'
      });
      expect(result.metadata.assignee).toBe('john.doe');
    });

    /**
     * Test: Should handle malformed YAML gracefully
     * Ensures the parser doesn't crash on invalid YAML
     */
    it('should handle malformed YAML without crashing', () => {
      // Act & Assert: Should throw a specific error
      expect(() => {
        parser.parseContent(MALFORMED_YAML_SPEC.content);
      }).toThrow('YAML parsing error');
      
      // Verify error was logged
      expect(mockLogger.error).toHaveBeenCalledWith(
        expect.stringContaining('Failed to parse YAML'),
        expect.any(Object)
      );
    });

    /**
     * Test: Should validate required fields
     * Ensures specs without required fields are rejected
     */
    it('should throw error for missing required fields', () => {
      // Act & Assert: Should validate required fields
      expect(() => {
        parser.parseContent(MISSING_FIELDS_SPEC.content);
      }).toThrow('Missing required field: id');
      
      // Check that appropriate warning was logged
      expect(mockLogger.warn).toHaveBeenCalledWith(
        expect.stringContaining('Missing required fields'),
        expect.any(Object)
      );
    });

    /**
     * Test: Should handle empty YAML frontmatter
     * Tests behavior when frontmatter exists but is empty
     */
    it('should handle empty YAML frontmatter', () => {
      // Act & Assert: Should throw for empty frontmatter
      expect(() => {
        parser.parseContent(EMPTY_YAML_SPEC.content);
      }).toThrow('Empty frontmatter');
    });

    /**
     * Test: Should handle missing frontmatter
     * Tests behavior when no YAML frontmatter is present
     */
    it('should handle content without frontmatter', () => {
      // Act & Assert: Should throw for missing frontmatter
      expect(() => {
        parser.parseContent(NO_FRONTMATTER_SPEC.content);
      }).toThrow('No frontmatter found');
    });

    /**
     * Test: Should handle special characters correctly
     * Validates that special chars in content don't break parsing
     */
    it('should correctly parse specs with special characters', () => {
      // Act: Parse spec with special characters
      const result = parser.parseContent(SPECIAL_CHARS_SPEC.content);
      
      // Assert: Special characters preserved correctly
      expect(result.metadata.title).toBe("Spec with 'Special' Characters & Symbols");
      expect(result.content).toContain('const code = "with special chars: ${variable}"');
      expect(result.content).toContain('你好 🚀 ñ é ü');
    });

    /**
     * Test: Should preserve markdown formatting
     * Ensures markdown content is preserved after parsing
     */
    it('should preserve markdown content and formatting', () => {
      const specWithFormatting = createMockSpec({
        id: 'E20-F01',
        title: 'Formatted Spec'
      });
      
      // Add markdown formatting to content
      specWithFormatting.content = `---
id: E20-F01
title: Formatted Spec
type: feature
status: draft
priority: medium
created: 2025-01-05
updated: 2025-01-06
---

# Heading 1

## Heading 2

- Bullet point 1
- Bullet point 2

\`\`\`javascript
const code = true;
\`\`\`

**Bold text** and *italic text*

[Link](https://example.com)`;
      
      // Act: Parse the formatted content
      const result = parser.parseContent(specWithFormatting.content);
      
      // Assert: All formatting preserved
      expect(result.content).toContain('# Heading 1');
      expect(result.content).toContain('## Heading 2');
      expect(result.content).toContain('- Bullet point 1');
      expect(result.content).toContain('```javascript');
      expect(result.content).toContain('**Bold text**');
      expect(result.content).toContain('[Link](https://example.com)');
    });
  });

  describe('parseFile()', () => {
    /**
     * Test: Should read and parse file from filesystem
     * Tests integration with file system
     */
    it('should read and parse file from filesystem', async () => {
      // Setup: Mock file read
      mockFs.readFile = jest.fn().mockResolvedValue(VALID_EPIC_SPEC.content);
      
      // Act: Parse file
      const result = await parser.parseFile(VALID_EPIC_SPEC.path);
      
      // Assert: File was read and parsed
      expect(mockFs.readFile).toHaveBeenCalledWith(VALID_EPIC_SPEC.path, 'utf-8');
      assertValidSpec(result, VALID_EPIC_SPEC.expected);
      expect(result.path).toBe(VALID_EPIC_SPEC.path);
    });

    /**
     * Test: Should handle file read errors
     * Tests error handling for file system failures
     */
    it('should handle file read errors gracefully', async () => {
      // Setup: Mock file read error
      mockFs.readFile = jest.fn().mockRejectedValue(
        new Error('ENOENT: no such file or directory')
      );
      
      // Act & Assert: Should propagate error
      await expect(parser.parseFile('/non/existent/file.md'))
        .rejects.toThrow('ENOENT');
      
      // Verify error was logged
      expect(mockLogger.error).toHaveBeenCalledWith(
        expect.stringContaining('Failed to read file'),
        expect.any(Object)
      );
    });

    /**
     * Test: Should include file path in parsed result
     * Ensures the file path is preserved in the result
     */
    it('should include file path in parsed result', async () => {
      // Setup: Mock file read
      mockFs.readFile = jest.fn().mockResolvedValue(VALID_FEATURE_SPEC.content);
      
      // Act: Parse file
      const result = await parser.parseFile(VALID_FEATURE_SPEC.path);
      
      // Assert: Path is included
      expect(result.path).toBe(VALID_FEATURE_SPEC.path);
      expect(result.metadata.id).toBe('E13-F01');
    });
  });

  describe('extractFrontmatter()', () => {
    /**
     * Test: Should extract YAML frontmatter correctly
     * Tests the frontmatter extraction logic
     */
    it('should extract YAML frontmatter from content', () => {
      // Act: Extract frontmatter
      const result = parser.extractFrontmatter(VALID_EPIC_SPEC.content);
      
      // Assert: Frontmatter extracted correctly
      expect(result.data).toMatchObject({
        id: 'E13',
        title: 'Spec Management API',
        type: 'epic',
        status: 'in-progress'
      });
      expect(result.content).not.toContain('---');
      expect(result.matter).toContain('id: E13');
    });

    /**
     * Test: Should handle arrays in YAML
     * Tests parsing of array values in frontmatter
     */
    it('should correctly parse arrays in YAML frontmatter', () => {
      // Act: Extract frontmatter with arrays
      const result = parser.extractFrontmatter(VALID_FEATURE_SPEC.content);
      
      // Assert: Arrays parsed correctly
      expect(result.data.dependencies).toBeInstanceOf(Array);
      expect(result.data.dependencies).toEqual(['E13-F02']);
    });

    /**
     * Test: Should handle multiline YAML values
     * Tests parsing of multiline strings in YAML
     */
    it('should handle multiline YAML values', () => {
      const multilineSpec = `---
id: E21-F01
title: Multiline Test
description: |
  This is a multiline
  description that spans
  multiple lines
type: feature
status: draft
priority: medium
created: 2025-01-05
updated: 2025-01-06
---

# Content`;
      
      // Act: Extract frontmatter
      const result = parser.extractFrontmatter(multilineSpec);
      
      // Assert: Multiline value preserved
      expect(result.data.description).toContain('This is a multiline');
      expect(result.data.description).toContain('multiple lines');
    });
  });

  describe('validateMetadata()', () => {
    /**
     * Test: Should validate required fields
     * Ensures all required fields are present
     */
    it('should validate all required fields are present', () => {
      // Setup: Valid metadata
      const validMetadata = {
        id: 'E13-F01',
        title: 'Test Spec',
        type: 'feature',
        status: 'draft',
        priority: 'medium',
        created: '2025-01-05',
        updated: '2025-01-06'
      };
      
      // Act: Validate metadata
      const result = parser.validateMetadata(validMetadata);
      
      // Assert: Validation passed
      expect(result).toEqual(validMetadata);
    });

    /**
     * Test: Should reject invalid spec ID format
     * Validates ID format validation
     */
    it('should reject invalid spec ID format', () => {
      // Setup: Invalid ID format
      const invalidMetadata = {
        id: 'invalid-format',
        title: 'Test',
        type: 'feature',
        status: 'draft',
        priority: 'medium',
        created: '2025-01-05',
        updated: '2025-01-06'
      };
      
      // Act & Assert: Should reject invalid ID
      expect(() => {
        parser.validateMetadata(invalidMetadata);
      }).toThrow('Invalid spec ID format');
    });

    /**
     * Test: Should validate enum fields
     * Ensures enum fields only accept valid values
     */
    it('should validate enum fields (type, status, priority)', () => {
      const metadata = {
        id: 'E13',
        title: 'Test',
        type: 'invalid-type', // Invalid
        status: 'draft',
        priority: 'medium',
        created: '2025-01-05',
        updated: '2025-01-06'
      };
      
      // Act & Assert: Should reject invalid enum value
      expect(() => {
        parser.validateMetadata(metadata);
      }).toThrow('Invalid type value');
    });

    /**
     * Test: Should apply default values
     * Tests that missing optional fields get defaults
     */
    it('should apply default values for optional fields', () => {
      // Setup: Minimal metadata
      const minimalMetadata = {
        id: 'E13',
        title: 'Minimal Spec',
        type: 'epic'
        // Missing: status, priority, created, updated
      };
      
      // Act: Validate with defaults
      const result = parser.validateMetadata(minimalMetadata);
      
      // Assert: Defaults applied
      expect(result.status).toBe('draft');
      expect(result.priority).toBe('medium');
      expect(result.created).toBeDefined();
      expect(result.updated).toBeDefined();
    });

    /**
     * Test: Should preserve optional fields
     * Ensures optional fields are preserved when present
     */
    it('should preserve optional fields when present', () => {
      // Setup: Metadata with optional fields
      const metadata = {
        id: 'E13-F01',
        title: 'Full Spec',
        type: 'feature',
        status: 'in-progress',
        priority: 'high',
        created: '2025-01-05',
        updated: '2025-01-06',
        parent: 'E13',
        assignee: 'john.doe',
        tags: ['api', 'parser'],
        dependencies: ['E13-F02', 'E13-F03']
      };
      
      // Act: Validate metadata
      const result = parser.validateMetadata(metadata);
      
      // Assert: All fields preserved
      expect(result.parent).toBe('E13');
      expect(result.assignee).toBe('john.doe');
      expect(result.tags).toEqual(['api', 'parser']);
      expect(result.dependencies).toEqual(['E13-F02', 'E13-F03']);
    });
  });

  describe('Performance', () => {
    /**
     * Test: Should parse files within performance targets
     * Validates parsing speed meets requirements
     */
    it('should parse file in less than 100ms', async () => {
      // Setup: Mock file read
      mockFs.readFile = jest.fn().mockResolvedValue(VALID_EPIC_SPEC.content);
      
      // Act: Measure parse time
      const perf = new PerformanceMonitor('parseFile');
      perf.start();
      await parser.parseFile(VALID_EPIC_SPEC.path);
      const metrics = perf.end();
      
      // Assert: Performance within target
      expect(metrics.duration).toBeLessThan(100);
    });

    /**
     * Test: Should handle large files efficiently
     * Tests performance with large content
     */
    it('should handle large content files efficiently', () => {
      // Act: Parse large content
      const perf = new PerformanceMonitor('largeParse');
      perf.start();
      const result = parser.parseContent(LARGE_CONTENT_SPEC.content);
      const metrics = perf.end();
      
      // Assert: Still performs well with large content
      expect(metrics.duration).toBeLessThan(200);
      expect(result.content.length).toBeGreaterThan(10000);
    });

    /**
     * Test: Should parse multiple files in parallel
     * Tests concurrent parsing performance
     */
    it('should efficiently parse multiple files in parallel', async () => {
      // Setup: Create multiple mock specs
      const specs = Array.from({ length: 10 }, (_, i) => 
        createMockSpec({ id: `E${i}`, title: `Spec ${i}` })
      );
      
      specs.forEach(spec => {
        mockFs.addFile(spec.path, spec.content);
      });
      
      mockFs.readFile = jest.fn((path) => {
        const spec = specs.find(s => s.path === path);
        return Promise.resolve(spec?.content || '');
      });
      
      // Act: Parse all files in parallel
      const perf = new PerformanceMonitor('parallelParse');
      perf.start();
      const results = await Promise.all(
        specs.map(spec => parser.parseFile(spec.path))
      );
      const metrics = perf.end();
      
      // Assert: All parsed successfully and quickly
      expect(results).toHaveLength(10);
      expect(metrics.duration).toBeLessThan(500); // Should be fast even for 10 files
      results.forEach((result, i) => {
        expect(result.metadata.id).toBe(`E${i}`);
      });
    });
  });

  describe('Error Recovery', () => {
    /**
     * Test: Should continue parsing after encountering errors
     * Ensures one bad spec doesn't break everything
     */
    it('should continue parsing other files after error', async () => {
      // Setup: Mix of valid and invalid specs
      const specs = [
        VALID_EPIC_SPEC,
        MALFORMED_YAML_SPEC,
        VALID_FEATURE_SPEC
      ];
      
      specs.forEach(spec => {
        mockFs.addFile(spec.path, spec.content);
      });
      
      mockFs.readFile = jest.fn((path) => {
        const spec = specs.find(s => s.path === path);
        return Promise.resolve(spec?.content || '');
      });
      
      // Act: Try to parse all specs
      const results = await Promise.allSettled(
        specs.map(spec => parser.parseFile(spec.path))
      );
      
      // Assert: Valid specs parsed, invalid spec rejected
      expect(results[0].status).toBe('fulfilled');
      expect(results[1].status).toBe('rejected');
      expect(results[2].status).toBe('fulfilled');
      
      if (results[0].status === 'fulfilled') {
        expect(results[0].value.metadata.id).toBe('E13');
      }
      if (results[2].status === 'fulfilled') {
        expect(results[2].value.metadata.id).toBe('E13-F01');
      }
    });

    /**
     * Test: Should provide helpful error messages
     * Ensures errors contain enough context for debugging
     */
    it('should provide detailed error messages with context', () => {
      // Act: Try to parse invalid content
      try {
        parser.parseContent(MISSING_FIELDS_SPEC.content);
      } catch (error: any) {
        // Assert: Error message is helpful
        expect(error.message).toContain('Missing required field');
        expect(error.message).toContain('id');
      }
    });
  });
});