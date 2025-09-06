# E13-F04: Caching & Performance Layer

## Spec Information

- **Spec ID**: E13-F04
- **Title**: Caching & Performance Layer
- **Parent**: E13
- **Type**: Feature
- **Status**: Draft
- **Priority**: High
- **Created**: 2025-09-05
- **Updated**: 2025-09-05
- **Dependencies**: E13-F01, E13-F02

## Description

Redis-based caching strategy with multi-level optimization for sub-200ms response times. This feature implements a sophisticated caching layer that significantly improves API performance through intelligent caching, precomputation, and cache invalidation strategies.

## Context

The caching layer is critical for achieving the performance requirements of the spec API. With potentially thousands of spec files and complex hierarchical relationships, computing responses on-demand would be too slow. This feature implements a multi-tier caching strategy using Redis for persistence and in-memory caching for hot data.

## Scope

### In Scope

- Redis integration and configuration
- In-memory LRU cache implementation
- Cache key strategy and namespacing
- Cache invalidation on file changes
- Lazy HTML rendering and caching
- Query result caching
- Cache warming on startup
- Cache statistics and monitoring

### Out of Scope

- CDN caching (infrastructure level)
- Browser caching headers (handled by F02)
- Database query caching (no DB in this epic)
- Static asset caching

## Acceptance Criteria

- [ ] < 50ms response time for cached data
- [ ] < 200ms response time for cache miss
- [ ] Cache hit ratio > 80% in production
- [ ] Automatic invalidation within 100ms of changes
- [ ] < 100MB Redis memory usage for 1000 specs
- [ ] Zero cache inconsistencies
- [ ] Graceful degradation if Redis unavailable
- [ ] Cache statistics endpoint available

## Tasks

### T01: Redis Integration

**Status**: Draft
**Priority**: Critical

Set up Redis connection with NestJS cache manager and proper configuration.

**Deliverables**:

- Redis module configuration
- Connection pooling setup
- Retry logic for connection failures
- Health check for Redis status
- Environment-based configuration

---

### T02: Cache Key Strategy

**Status**: Draft
**Priority**: Critical

Design and implement consistent cache key patterns with proper namespacing.

**Deliverables**:

- Key naming conventions (spec:{id}, tree:{root}, stats:global)
- Namespace prefixing for environments
- TTL strategy per cache type
- Key generation utilities
- Cache key documentation

---

### T03: In-Memory LRU Cache

**Status**: Draft
**Priority**: High

Implement fast in-memory cache for frequently accessed data with LRU eviction.

**Deliverables**:

- LRU cache implementation with size limits
- Two-tier caching (memory → Redis)
- Hot data identification
- Memory usage monitoring
- Configurable cache sizes

---

### T04: Cache Invalidation System

**Status**: Draft
**Priority**: High

Implement intelligent cache invalidation triggered by file system changes.

**Deliverables**:

- Event-driven invalidation from file watcher
- Cascading invalidation for related specs
- Batch invalidation for multiple changes
- Invalidation patterns (exact, wildcard)
- Cache versioning support

---

### T05: HTML Rendering Cache

**Status**: Draft
**Priority**: Medium

Lazy render and cache HTML versions of markdown content for API responses.

**Deliverables**:

- On-demand HTML rendering
- Rendered HTML caching in Redis
- Markdown→HTML conversion with markdown-it
- Cache warming for popular specs
- Render queue for batch processing

---

### T06: Query Result Caching

**Status**: Draft
**Priority**: Medium

Cache complex query results like tree structures and statistics.

**Deliverables**:

- Query fingerprinting for cache keys
- Result set caching with pagination
- Statistics pre-computation
- Tree structure caching
- Cache tags for grouped invalidation

---

### T07: Cache Monitoring & Stats

**Status**: Draft
**Priority**: Low

Implement cache performance monitoring and statistics collection.

**Deliverables**:

- Hit/miss ratio tracking
- Cache size monitoring
- Performance metrics collection
- Cache debug endpoints
- Prometheus metrics export

## Technical Architecture

### Module Structure

```
apps/spec-api/src/modules/cache/
├── services/
│   ├── cache-manager.service.ts
│   ├── redis-cache.service.ts
│   ├── memory-cache.service.ts
│   ├── invalidation.service.ts
│   └── cache-stats.service.ts
├── strategies/
│   ├── key-generator.strategy.ts
│   ├── ttl.strategy.ts
│   └── eviction.strategy.ts
├── decorators/
│   ├── cacheable.decorator.ts
│   └── cache-invalidate.decorator.ts
└── cache.module.ts
```

### Cache Architecture

```
┌─────────────┐
│   Client    │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│   API       │
└──────┬──────┘
       │
       ▼
┌─────────────┐     miss    ┌─────────────┐
│  Memory LRU ├─────────────►│    Redis    │
└──────┬──────┘              └──────┬──────┘
       │ hit                        │ miss
       ▼                            ▼
   [Response]                ┌─────────────┐
                            │   Parser    │
                            └─────────────┘
```

### Cache Layers

#### Level 1: In-Memory LRU

```typescript
class MemoryCache {
  private cache: LRUCache<string, CachedItem>;

  constructor(options: {
    maxSize: number; // Max items
    maxAge: number; // TTL in ms
    sizeCalculation?: (item: any) => number;
  });

  get<T>(key: string): T | undefined;
  set<T>(key: string, value: T, ttl?: number): void;
  delete(key: string): void;
  clear(): void;
  stats(): CacheStats;
}
```

#### Level 2: Redis Cache

```typescript
class RedisCache {
  async get<T>(key: string): Promise<T | null>;
  async set<T>(key: string, value: T, ttl?: number): Promise<void>;
  async delete(key: string | string[]): Promise<void>;
  async exists(key: string): Promise<boolean>;
  async ttl(key: string): Promise<number>;
  async scan(pattern: string): Promise<string[]>;
}
```

### Cache Key Patterns

```typescript
enum CacheKeys {
  // Individual specs
  SPEC = 'spec:{id}', // spec:E13-F04
  SPEC_HTML = 'spec:{id}:html', // spec:E13-F04:html

  // Collections
  SPEC_LIST = 'specs:list:{hash}', // specs:list:abc123
  SPEC_TREE = 'specs:tree:{root}', // specs:tree:E13

  // Statistics
  STATS_GLOBAL = 'stats:global', // stats:global
  STATS_BY_TYPE = 'stats:type:{type}', // stats:type:feature

  // Metadata
  SPEC_CHILDREN = 'spec:{id}:children', // spec:E13:children
  SPEC_DEPS = 'spec:{id}:deps', // spec:E13-F04:deps
}
```

### Cache Configuration

```typescript
interface CacheConfig {
  redis: {
    host: string;
    port: number;
    password?: string;
    db: number;
    keyPrefix: string; // e.g., 'jts:spec:'
  };
  memory: {
    maxSize: number; // e.g., 1000 items
    maxMemory: string; // e.g., '100mb'
    ttl: number; // Default TTL in seconds
  };
  ttls: {
    spec: number; // e.g., 3600 (1 hour)
    list: number; // e.g., 300 (5 min)
    tree: number; // e.g., 600 (10 min)
    stats: number; // e.g., 60 (1 min)
    html: number; // e.g., 86400 (1 day)
  };
}
```

### Invalidation Strategy

```typescript
class InvalidationService {
  // Single spec update
  async invalidateSpec(specId: string): Promise<void> {
    // Delete spec cache
    await this.cache.delete(`spec:${specId}`);
    await this.cache.delete(`spec:${specId}:html`);

    // Invalidate parent's children cache
    const parentId = this.getParentId(specId);
    if (parentId) {
      await this.cache.delete(`spec:${parentId}:children`);
    }

    // Invalidate lists and stats
    await this.invalidatePattern('specs:list:*');
    await this.cache.delete('stats:global');
  }

  // Pattern-based invalidation
  async invalidatePattern(pattern: string): Promise<void>;

  // Cascade invalidation
  async cascadeInvalidate(specId: string): Promise<void>;
}
```

### Cache Decorators

```typescript
// Method-level caching
@Cacheable({
  key: (id: string) => `spec:${id}`,
  ttl: 3600
})
async getSpec(id: string): Promise<Spec> {
  return this.parser.parse(id)
}

// Cache invalidation
@CacheInvalidate({
  keys: (id: string) => [`spec:${id}`, 'stats:global']
})
async updateSpec(id: string, data: any): Promise<void> {
  // Update logic
}
```

### Dependencies

- **redis**: ^4.6.0 - Redis client
- **cache-manager**: ^5.3.0 - Cache abstraction
- **cache-manager-redis-store**: ^3.0.1 - Redis adapter
- **lru-cache**: ^10.1.0 - In-memory LRU cache
- **markdown-it**: ^13.0.2 - HTML rendering

## Risk Analysis

| Risk                | Impact | Mitigation                                     |
| ------------------- | ------ | ---------------------------------------------- |
| Redis failure       | High   | Fallback to memory cache, graceful degradation |
| Memory overflow     | Medium | Size limits, LRU eviction, monitoring          |
| Cache inconsistency | High   | Event-driven invalidation, versioning          |
| Invalidation storms | Medium | Batch invalidation, debouncing                 |

## Success Metrics

- < 50ms cached response time
- > 80% cache hit ratio
- < 100MB Redis memory usage
- Zero cache inconsistencies
- < 100ms invalidation latency

## References

- [Redis Best Practices](https://redis.io/docs/manual/patterns/)
- [NestJS Caching](https://docs.nestjs.com/techniques/caching)
- [E13-F01 Spec Parser Service](../F01/spec.md)
- [E13-F02 Spec API Gateway](../F02/spec.md)
- [E13 Epic Spec](../E13.spec.md)
