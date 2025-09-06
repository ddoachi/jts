/**
 * Mock Spec Test Fixtures
 *
 * This file provides comprehensive test fixtures for testing the spec parser service.
 * Each fixture represents different scenarios and edge cases that the parser must handle.
 *
 * USAGE:
 * Import these fixtures in your test files to ensure consistent test data:
 * ```typescript
 * import { VALID_SPEC, MALFORMED_YAML_SPEC } from './fixtures/mock-specs';
 * ```
 */

/**
 * Valid Epic Spec
 * Represents a properly formatted epic-level spec with all required fields
 */
export const VALID_EPIC_SPEC = {
  content: `---
id: E13
title: Spec Management API
type: epic
status: in-progress
priority: high
created: 2025-01-05
updated: 2025-01-06
tags:
  - api
  - spec-management
---

# E13: Spec Management API

## Description

This epic covers the development of a comprehensive spec management API.

## Features

- F01: Parser Service
- F02: Renderer Service
- F03: WebSocket Updates`,

  path: '/specs/E13/E13.spec.md',

  expected: {
    id: 'E13',
    title: 'Spec Management API',
    type: 'epic',
    status: 'in-progress',
    priority: 'high',
    hierarchy: {
      level: 'epic',
      parentId: undefined,
      childIds: [],
      depth: 0,
    },
  },
};

/**
 * Valid Feature Spec
 * Represents a feature-level spec with parent reference
 */
export const VALID_FEATURE_SPEC = {
  content: `---
id: E13-F01
title: Spec Parser Service
parent: E13
type: feature
status: draft
priority: critical
created: 2025-01-05
updated: 2025-01-06
dependencies:
  - E13-F02
assignee: dev-team
---

# E13-F01: Spec Parser Service

Foundation service for parsing spec files.`,

  path: '/specs/E13/F01/spec.md',

  expected: {
    id: 'E13-F01',
    title: 'Spec Parser Service',
    parent: 'E13',
    type: 'feature',
    status: 'draft',
    priority: 'critical',
    hierarchy: {
      level: 'feature',
      parentId: 'E13',
      childIds: [],
      depth: 1,
    },
  },
};

/**
 * Valid Task Spec
 * Represents a task-level spec with full hierarchy
 */
export const VALID_TASK_SPEC = {
  content: `---
id: E13-F01-T01
title: Core Parser Implementation
parent: E13-F01
type: task
status: completed
priority: high
created: 2025-01-05
updated: 2025-01-06
assignee: john.doe
---

# Task: Core Parser Implementation

Implement the core parsing logic.`,

  path: '/specs/E13/F01/T01/spec.md',

  expected: {
    id: 'E13-F01-T01',
    title: 'Core Parser Implementation',
    parent: 'E13-F01',
    type: 'task',
    status: 'completed',
    priority: 'high',
    hierarchy: {
      level: 'task',
      parentId: 'E13-F01',
      childIds: [],
      depth: 2,
    },
  },
};

/**
 * Malformed YAML Spec
 * Tests error handling for invalid YAML syntax
 */
export const MALFORMED_YAML_SPEC = {
  content: `---
id: E13-F02
title: Broken Spec
type: feature
status: draft
priority: [high, medium] # Invalid: should be single value
created: not-a-date
tags
  - missing-colon
---

# Malformed Spec

This spec has YAML errors.`,

  path: '/specs/E13/F02/spec.md',

  expectedError: 'YAML parsing error',
};

/**
 * Missing Required Fields Spec
 * Tests validation when required fields are absent
 */
export const MISSING_FIELDS_SPEC = {
  content: `---
title: Incomplete Spec
---

# Incomplete Spec

This spec is missing required fields like id, type, status.`,

  path: '/specs/incomplete.spec.md',

  expectedError: 'Missing required field: id',
};

/**
 * Empty YAML Spec
 * Tests handling of empty frontmatter
 */
export const EMPTY_YAML_SPEC = {
  content: `---
---

# Empty Frontmatter

This spec has empty YAML frontmatter.`,

  path: '/specs/empty.spec.md',

  expectedError: 'Empty frontmatter',
};

/**
 * No Frontmatter Spec
 * Tests handling when YAML frontmatter is completely missing
 */
export const NO_FRONTMATTER_SPEC = {
  content: `# Regular Markdown File

This is just a regular markdown file without frontmatter.
It should be handled gracefully.`,

  path: '/specs/no-frontmatter.spec.md',

  expectedError: 'No frontmatter found',
};

/**
 * Special Characters Spec
 * Tests handling of special characters in content
 */
export const SPECIAL_CHARS_SPEC = {
  content: `---
id: E14-F01
title: "Spec with 'Special' Characters & Symbols"
type: feature
status: draft
priority: medium
created: 2025-01-05
updated: 2025-01-06
description: |
  This tests various special characters:
  - Quotes: "double" and 'single'
  - Symbols: & < > @ # $ % ^ * ()
  - Unicode: 你好 🚀 ñ é ü
---

# Special Characters Test

\`\`\`javascript
const code = "with special chars: \${variable}";
const regex = /[a-z]+/gi;
\`\`\``,

  path: '/specs/E14/F01/spec.md',

  expected: {
    id: 'E14-F01',
    title: "Spec with 'Special' Characters & Symbols",
    type: 'feature',
    status: 'draft',
    priority: 'medium',
  },
};

/**
 * Large Content Spec
 * Tests performance with large markdown content
 */
export const LARGE_CONTENT_SPEC = {
  content: `---
id: E15
title: Large Content Spec
type: epic
status: draft
priority: low
created: 2025-01-05
updated: 2025-01-06
---

# Large Content Spec

${Array(1000).fill('This is a line of content. ').join('\n')}`,

  path: '/specs/E15/E15.spec.md',

  expected: {
    id: 'E15',
    contentLength: 30000, // Approximate
  },
};

/**
 * Circular Dependency Spec
 * Tests handling of circular dependencies
 */
export const CIRCULAR_DEPENDENCY_SPEC = {
  content: `---
id: E16-F01
title: Circular Dep A
parent: E16
type: feature
status: draft
priority: medium
created: 2025-01-05
updated: 2025-01-06
dependencies:
  - E16-F02
  - E16-F03
---

# Circular Dependency Test A`,

  path: '/specs/E16/F01/spec.md',

  related: {
    'E16-F02': ['E16-F03', 'E16-F01'], // F02 depends on F01 (circular)
    'E16-F03': ['E16-F01'], // F03 depends on F01 (circular)
  },
};

/**
 * Invalid ID Format Spec
 * Tests validation of spec ID format
 */
export const INVALID_ID_SPEC = {
  content: `---
id: invalid-id-format
title: Invalid ID
type: feature
status: draft
priority: medium
created: 2025-01-05
updated: 2025-01-06
---

# Invalid ID Format`,

  path: '/specs/invalid.spec.md',

  expectedError: 'Invalid spec ID format',
};

/**
 * Duplicate ID Specs
 * Tests handling when multiple specs have the same ID
 */
export const DUPLICATE_ID_SPECS = [
  {
    content: `---
id: E17-F01
title: Original Spec
type: feature
status: draft
priority: high
created: 2025-01-05
updated: 2025-01-06
---

# Original`,
    path: '/specs/E17/F01/spec.md',
  },
  {
    content: `---
id: E17-F01
title: Duplicate Spec
type: feature
status: draft
priority: low
created: 2025-01-06
updated: 2025-01-06
---

# Duplicate`,
    path: '/specs/E17/F01-duplicate/spec.md',
  },
];

/**
 * Helper function to create a mock spec with custom fields
 * Useful for dynamically generating test data
 *
 * @example
 * const customSpec = createMockSpec({
 *   id: 'E99-F01',
 *   title: 'Custom Test Spec',
 *   status: 'in-progress'
 * });
 */
export function createMockSpec(overrides: Partial<any> = {}) {
  const defaults = {
    id: 'E99-F99',
    title: 'Mock Spec',
    type: 'feature',
    status: 'draft',
    priority: 'medium',
    created: '2025-01-05',
    updated: '2025-01-06',
  };

  const metadata = { ...defaults, ...overrides };

  return {
    content: `---
${Object.entries(metadata)
  .map(([key, value]) => `${key}: ${value}`)
  .join('\n')}
---

# ${metadata.title}

Mock spec content.`,
    path: `/specs/${metadata.id.replace('-', '/')}/spec.md`,
    expected: metadata,
  };
}

/**
 * Collection of all valid specs for batch testing
 */
export const ALL_VALID_SPECS = [
  VALID_EPIC_SPEC,
  VALID_FEATURE_SPEC,
  VALID_TASK_SPEC,
  SPECIAL_CHARS_SPEC,
];

/**
 * Collection of all invalid specs for error testing
 */
export const ALL_INVALID_SPECS = [
  MALFORMED_YAML_SPEC,
  MISSING_FIELDS_SPEC,
  EMPTY_YAML_SPEC,
  NO_FRONTMATTER_SPEC,
  INVALID_ID_SPEC,
];
