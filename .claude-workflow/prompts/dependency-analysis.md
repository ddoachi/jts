# Dependency Analysis Prompt

Analyze dependencies between different components/features mentioned in the PRD.

## Instructions

Identify:
- Component dependencies
- Feature dependencies
- Service dependencies
- Data dependencies
- Integration dependencies

## Output Format

Return results in JSON format with dependency graph structure:

```json
{
  "dependencies": {
    "nodes": [
      {"id": "epic-001", "title": "Authentication System"},
      {"id": "epic-002", "title": "User Dashboard"}
    ],
    "edges": [
      {"from": "epic-002", "to": "epic-001", "type": "depends_on"}
    ],
    "parallelGroups": [
      ["epic-003", "epic-004"],
      ["epic-005", "epic-006"]
    ],
    "criticalPath": ["epic-001", "epic-003", "epic-005"]
  }
}
```

## Guidelines

- Identify which components must be built first
- Group components that can be built in parallel
- Identify the critical path for delivery
- Consider both technical and business dependencies

## PRD Document

Please analyze {{CONTENT}}