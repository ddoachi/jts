# E13-F01: Spec Parser Service

## Spec Information

- **Spec ID**: E13-F01
- **Title**: Spec Parser Service
- **Parent**: E13
- **Type**: Feature
- **Status**: Draft
- **Priority**: Critical (Foundation)
- **Created**: 2025-09-05
- **Updated**: 2025-09-05

## Description

Foundation service for parsing and processing .spec.md files with YAML frontmatter extraction, hierarchical relationship building, and in-memory registry management. This service acts as the core data provider for all spec-related operations in the API.

## Context

The parser service is the foundation layer that all other features depend upon. It needs to efficiently discover, parse, and maintain an in-memory representation of all spec files while handling malformed content gracefully.

## Scope

### In Scope

- Spec file discovery and indexing from filesystem
- YAML frontmatter parsing using gray-matter
- Markdown content extraction and preservation
- Hierarchical ID parsing (E13, E13-F01, E13-F01-T01)
- Parent-child relationship building
- In-memory spec registry with fast lookups
- File watcher for change detection
- Error handling for malformed specs

### Out of Scope

- HTML rendering (handled by F02)
- Caching strategies (handled by F04)
- WebSocket notifications (handled by F03)
- Progress calculations (handled by F05)

## Acceptance Criteria

- [ ] Successfully parses all valid spec files in specs/ directory
- [ ] Extracts YAML frontmatter with proper type validation
- [ ] Builds complete hierarchical tree of specs
- [ ] Handles malformed files without service crash
- [ ] Detects file changes within 100ms
- [ ] Provides O(1) spec lookup by ID
- [ ] Maintains parent-child relationships
- [ ] 95% test coverage for parsing logic

## Tasks

### T01: Core Parser Implementation

**Status**: Draft
**Priority**: Critical

Implement the fundamental parsing logic using gray-matter for YAML frontmatter extraction.

**Deliverables**:

- SpecParser class with gray-matter integration
- YAML frontmatter extraction and validation
- Markdown content preservation
- Error handling for malformed YAML

---

### T02: File Discovery Service

**Status**: Draft
**Priority**: Critical

Implement filesystem scanning to discover and index all spec files.

**Deliverables**:

- SpecDiscovery service with glob pattern matching
- Recursive directory traversal
- File filtering for .spec.md extension
- Initial spec loading on startup

---

### T03: Hierarchical ID Resolver

**Status**: Draft
**Priority**: High

Parse spec IDs to understand hierarchical relationships and build parent-child mappings.

**Deliverables**:

- ID parsing logic (E13 → Epic, E13-F01 → Feature)
- Parent ID extraction from child IDs
- Relationship mapping data structures
- Validation for ID format consistency

---

### T04: In-Memory Registry

**Status**: Draft
**Priority**: High

Implement efficient in-memory storage with fast lookups and relationship traversal.

**Deliverables**:

- SpecRegistry class with Map-based storage
- O(1) lookup by spec ID
- Tree traversal methods
- Memory optimization for large spec sets

---

### T05: File Watcher Integration

**Status**: Draft
**Priority**: Medium

Implement file system monitoring to detect spec file changes in real-time.

**Deliverables**:

- Chokidar integration for file watching
- Change event detection (add, update, delete)
- Incremental parsing for changed files
- Event emission for downstream consumers

## Technical Architecture

### Module Structure

```
apps/spec-api/src/modules/parser/
├── services/
│   ├── spec-parser.service.ts
│   ├── spec-discovery.service.ts
│   ├── spec-registry.service.ts
│   └── file-watcher.service.ts
├── entities/
│   ├── spec.entity.ts
│   └── spec-metadata.entity.ts
├── utils/
│   ├── id-resolver.util.ts
│   └── validation.util.ts
└── parser.module.ts
```

### Core Components

#### SpecParser Service

```typescript
interface ISpecParser {
  parseFile(path: string): Promise<ParsedSpec>;
  parseContent(content: string): ParsedSpec;
  extractFrontmatter(content: string): SpecMetadata;
  validateMetadata(metadata: any): SpecMetadata;
}
```

#### Spec Registry

```typescript
interface ISpecRegistry {
  get(id: string): Spec | undefined;
  getAll(): Spec[];
  getChildren(parentId: string): Spec[];
  getTree(): SpecTreeNode;
  upsert(spec: Spec): void;
  delete(id: string): void;
}
```

#### Data Models

```typescript
interface ParsedSpec {
  metadata: SpecMetadata;
  content: string;
  path: string;
  hierarchy: {
    level: 'epic' | 'feature' | 'task';
    parentId?: string;
    childIds: string[];
  };
}

interface SpecMetadata {
  id: string;
  title: string;
  type: string;
  status: string;
  priority: string;
  created: string;
  updated: string;
  parent?: string;
  dependencies?: string[];
}
```

### Dependencies

- **gray-matter**: ^4.0.3 - YAML frontmatter parsing
- **chokidar**: ^3.5.3 - File system watching
- **glob**: ^10.3.10 - File discovery patterns
- **joi**: ^17.11.0 - Metadata validation

## Risk Analysis

| Risk                                    | Impact | Mitigation                                     |
| --------------------------------------- | ------ | ---------------------------------------------- |
| Memory consumption with large spec sets | High   | Implement pagination, lazy loading for content |
| File system performance bottleneck      | Medium | Use caching, batch file operations             |
| Malformed YAML breaking parser          | High   | Comprehensive error handling, validation       |
| Race conditions during file updates     | Medium | Queue-based processing, file locks             |

## Success Metrics

- Parse 1000+ spec files in < 5 seconds
- < 100ms file change detection
- Zero crashes from malformed files
- < 100MB memory usage for 1000 specs
- O(1) spec lookup performance

## References

- [gray-matter documentation](https://github.com/jonschlinkert/gray-matter)
- [chokidar documentation](https://github.com/paulmillr/chokidar)
- [E13 Epic Spec](../E13.spec.md)
