# Complexity Estimation Prompt

Assess the implementation complexity of the system described in the PRD.

## Instructions

Analyze complexity factors:

- Technical complexity (algorithms, integrations, performance)
- Integration complexity (external systems, APIs, protocols)
- Data complexity (volume, variety, velocity)
- UI/UX complexity (interfaces, workflows, responsiveness)
- Infrastructure complexity (scalability, reliability, security)
- Team complexity (skills required, coordination)

## Output Format

Return results in JSON format:

```json
{
  "complexity_score": 7.5,
  "reasoning": "High complexity due to real-time trading requirements, multiple broker integrations, and complex risk management algorithms. Moderate UI complexity with dashboard and configuration interfaces.",
  "factors": {
    "technical": 8,
    "integration": 9,
    "data": 7,
    "ui_ux": 6,
    "infrastructure": 8,
    "team": 7
  },
  "risks": [
    "Real-time performance requirements",
    "Multiple broker API integrations",
    "Financial data accuracy requirements"
  ],
  "recommendations": [
    "Start with core trading engine",
    "Build robust testing framework early",
    "Consider phased delivery approach"
  ]
}
```

## Guidelines

- Rate complexity from 1-10 (1 = simple, 10 = extremely complex)
- Provide specific reasoning for the score
- Identify key risk factors
- Suggest mitigation strategies

## PRD Document

Please analyze {{CONTENT}}
