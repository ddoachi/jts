# Functional Requirements Extraction Prompt

Extract and list the key functional requirements from PRD content.

## Instructions

Analyze the PRD and identify:

- Core business functionality requirements
- User interaction requirements
- System behavior requirements
- Integration requirements
- Performance requirements
- Security requirements

## Output Format

Return results in JSON format:

```json
{
  "requirements": [
    "The system must support real-time trading execution",
    "Users must be able to configure trading strategies",
    "The system shall integrate with multiple broker APIs"
  ]
}
```

## Guidelines

- Focus on "must", "shall", "should" requirements
- Make requirements specific and testable
- Group related requirements logically
- Include both functional and non-functional requirements

## PRD Document

Please analyze {{CONTENT}}
