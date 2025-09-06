# JTS Documentation Structure

This documentation follows a three-layer approach for comprehensive understanding:

## 📁 Directory Structure

```
docs/
├── architecture/       # System-level documentation
│   └── {spec_id}/     # Per-spec architecture docs
│       ├── system-overview.md
│       └── data-flow.md
│
├── walkthroughs/      # Step-by-step implementation guides
│   └── {spec_id}.md   # Detailed code walkthrough per spec
│
├── decisions/         # Architecture Decision Records
│   └── ADR-{num}-{spec_id}.md
│
└── learning/          # Educational resources
    ├── concepts/      # Trading and technical concepts
    ├── patterns/      # Design patterns used
    └── troubleshooting/ # Common issues and solutions
```

## 📚 Documentation Layers

### 1. Architecture Level

High-level system design, component relationships, and data flows using visual diagrams.

### 2. Module Level

Component interfaces, API contracts, and service interactions.

### 3. Code Level

Inline documentation with WHY/HOW/WHAT comments explaining implementation details.

## 🔄 Documentation Workflow

### Phase 1: Pre-Implementation

- Create GitHub issue for tracking
- Generate architecture diagrams
- Document technical decisions

### Phase 2: Implementation

- Add comprehensive inline comments
- Include section markers for organization
- Provide real-world examples

### Phase 3: Post-Implementation

- Create walkthrough guides
- Document test scenarios
- Close GitHub issue with summary

## 📝 Documentation Standards

Every piece of code includes:

- **WHY**: Business requirement being solved
- **HOW**: Technical approach and algorithms
- **WHAT**: Expected inputs/outputs
- **FLOW**: Step-by-step execution
- **GOTCHAS**: Edge cases and non-obvious behaviors
- **EXAMPLES**: Real-world usage scenarios

## 🔗 Related Resources

- Spec documents: `/specs/`
- Implementation commands: `/.claude/commands/spec_work/`
- Project configuration: `/CLAUDE.md`
