# PRD Epic Analysis

Analyze the PRD and return structured epic specifications.

## Task

Break down the PRD into epic-level specifications. Return a simple JSON with the epic information.

## Output Format

Return ONLY a JSON object in this exact format:

```json
{
  "epics": [
    {
      "id": "epic-001",
      "title": "Specific Epic Title from PRD",
      "description": "Clear description of what this epic accomplishes",
      "acceptanceCriteria": [
        "Specific measurable criterion 1",
        "Specific measurable criterion 2",
        "Specific measurable criterion 3"
      ],
      "estimatedHours": 80,
      "complexity": "medium",
      "priority": "high",
      "dependencies": []
    }
  ]
}
```

## Guidelines

- **id**: Use format "epic-001", "epic-002", etc.
- **title**: Specific, descriptive title based on PRD content
- **description**: 1-2 sentences explaining the epic's purpose
- **acceptanceCriteria**: 3-5 specific, testable criteria
- **estimatedHours**: Realistic estimate (40-120 hours per epic)
- **complexity**: "low", "medium", or "high"
- **priority**: "low", "medium", or "high"
- **dependencies**: Array of epic IDs that must be completed first

## Important

- Focus on the actual domain and requirements in the PRD
- Create epics that represent major functional areas
- Make titles and descriptions specific to the business domain
- Keep the output simple and parseable

## PRD Document

Please analyze {{CONTENT}}
