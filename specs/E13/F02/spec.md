# E13-F02: Spec API Gateway

## Spec Information
- **Spec ID**: E13-F02
- **Title**: Spec API Gateway
- **Parent**: E13
- **Type**: Feature
- **Status**: Draft
- **Priority**: Critical
- **Created**: 2025-09-05
- **Updated**: 2025-09-05
- **Dependencies**: E13-F01

## Description

RESTful API endpoints providing comprehensive spec data access with support for multiple response formats. This feature implements the HTTP interface layer that exposes parsed spec data to external consumers like the JTS Spec Dashboard.

## Context

The API Gateway serves as the primary interface between the spec parser service and external consumers. It needs to provide a clean, well-documented REST API that supports various query patterns, filtering, and response formats while maintaining sub-200ms response times.

## Scope

### In Scope
- RESTful endpoints for spec data retrieval
- OpenAPI/Swagger documentation
- Response DTOs with validation
- Query parameter support for filtering
- Pagination for large datasets
- Content negotiation (JSON, HTML, Markdown)
- CORS configuration
- Error response standardization

### Out of Scope
- WebSocket endpoints (handled by F03)
- Caching implementation (handled by F04)
- Authentication/authorization (handled by F06)
- Spec modification endpoints (read-only API)

## Acceptance Criteria

- [ ] All endpoints respond within 200ms for cached data
- [ ] OpenAPI documentation auto-generated and accessible
- [ ] Support for JSON, HTML, and raw markdown responses
- [ ] Pagination works for datasets > 100 items
- [ ] Proper HTTP status codes for all scenarios
- [ ] CORS configured for dashboard domain
- [ ] 100% endpoint test coverage
- [ ] DTOs validate all input/output

## Tasks

### T01: Core REST Controllers
**Status**: Draft
**Priority**: Critical

Implement NestJS controllers for primary spec endpoints with proper decorators and routing.

**Deliverables**:
- SpecController with route handlers
- GET /api/specs - List all specs
- GET /api/specs/:id - Get single spec
- GET /api/specs/tree - Hierarchical view
- Proper HTTP status codes

---

### T02: Response DTOs & Validation
**Status**: Draft
**Priority**: Critical

Create Data Transfer Objects with class-validator decorators for request/response validation.

**Deliverables**:
- SpecResponseDto with metadata fields
- SpecListResponseDto with pagination
- TreeNodeDto for hierarchical data
- QueryParamsDto for filtering
- Validation pipes configuration

---

### T03: Statistics Endpoint
**Status**: Draft
**Priority**: High

Implement aggregated statistics endpoint for dashboard metrics and progress tracking.

**Deliverables**:
- GET /api/specs/stats endpoint
- StatsResponseDto with counts and percentages
- Progress calculations by status
- Aggregation by epic/feature/task levels

---

### T04: Content Format Negotiation
**Status**: Draft
**Priority**: Medium

Support multiple response formats based on Accept headers and query parameters.

**Deliverables**:
- JSON response formatting (default)
- HTML rendering with markdown-it
- Raw markdown passthrough
- Format selection via Accept header
- Query parameter override (?format=html)

---

### T05: OpenAPI Documentation
**Status**: Draft
**Priority**: High

Configure Swagger/OpenAPI documentation with proper schemas and examples.

**Deliverables**:
- Swagger module configuration
- API decorators on all endpoints
- Response schema documentation
- Example requests/responses
- Interactive API explorer at /api/docs

---

### T06: Pagination & Filtering
**Status**: Draft
**Priority**: Medium

Implement query capabilities for large datasets with efficient pagination.

**Deliverables**:
- Pagination query parameters (page, limit)
- Filtering by status, type, priority
- Sorting options (created, updated, title)
- Metadata in response (total, pages, current)
- Cursor-based pagination option

## Technical Architecture

### Module Structure
```
apps/spec-api/src/modules/api/
├── controllers/
│   ├── spec.controller.ts
│   └── stats.controller.ts
├── dto/
│   ├── spec-response.dto.ts
│   ├── spec-list-response.dto.ts
│   ├── tree-node.dto.ts
│   ├── stats-response.dto.ts
│   └── query-params.dto.ts
├── pipes/
│   └── validation.pipe.ts
├── interceptors/
│   └── transform.interceptor.ts
└── api.module.ts
```

### API Endpoints

#### Spec Listing
```
GET /api/specs
Query Parameters:
  - page: number (default: 1)
  - limit: number (default: 20, max: 100)
  - status: string (draft|in_progress|completed)
  - type: string (epic|feature|task)
  - sort: string (created|updated|title)
  - order: string (asc|desc)

Response: {
  data: Spec[]
  meta: {
    total: number
    page: number
    limit: number
    pages: number
  }
}
```

#### Single Spec
```
GET /api/specs/:id
Parameters:
  - id: string (e.g., "E13-F02")
Query Parameters:
  - format: string (json|html|markdown)
  - include: string[] (children|parent|dependencies)

Response: {
  metadata: SpecMetadata
  content: string
  relationships: {
    parent?: Spec
    children?: Spec[]
    dependencies?: Spec[]
  }
}
```

#### Hierarchical Tree
```
GET /api/specs/tree
Query Parameters:
  - root: string (optional root spec ID)
  - depth: number (max tree depth)

Response: TreeNode {
  id: string
  title: string
  type: string
  status: string
  children: TreeNode[]
}
```

#### Statistics
```
GET /api/specs/stats
Query Parameters:
  - groupBy: string (type|status|priority)

Response: {
  total: number
  byStatus: Record<string, number>
  byType: Record<string, number>
  progress: {
    completed: number
    percentage: number
  }
  lastUpdated: string
}
```

### Response DTOs

```typescript
class SpecResponseDto {
  @ApiProperty()
  id: string

  @ApiProperty()
  title: string

  @ApiProperty()
  type: 'epic' | 'feature' | 'task'

  @ApiProperty()
  status: 'draft' | 'in_progress' | 'completed'

  @ApiProperty()
  priority: string

  @ApiProperty()
  created: string

  @ApiProperty()
  updated: string

  @ApiPropertyOptional()
  parent?: string

  @ApiPropertyOptional()
  content?: string

  @ApiPropertyOptional()
  html?: string
}
```

### Dependencies
- **@nestjs/swagger**: ^10.2.1 - OpenAPI documentation
- **class-transformer**: ^0.5.1 - DTO transformation
- **class-validator**: ^0.14.0 - Request validation
- **markdown-it**: ^13.0.2 - HTML rendering

## Risk Analysis

| Risk | Impact | Mitigation |
|------|--------|------------|
| Large response payloads | High | Implement pagination, field selection |
| Slow HTML rendering | Medium | Lazy rendering, caching layer |
| API contract changes | High | Versioning strategy, deprecation notices |
| Invalid query parameters | Low | Comprehensive validation, clear errors |

## Success Metrics

- < 200ms average response time
- Zero 5xx errors in production
- 100% API documentation coverage
- < 1% request validation errors
- Support 1000+ concurrent requests

## References

- [NestJS Controllers Documentation](https://docs.nestjs.com/controllers)
- [OpenAPI Specification](https://swagger.io/specification/)
- [E13-F01 Spec Parser Service](../F01/spec.md)
- [E13 Epic Spec](../E13.spec.md)