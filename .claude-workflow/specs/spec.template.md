---
# ============================================================================
# SPEC METADATA - This entire frontmatter section contains the spec metadata
# ============================================================================

# === IDENTIFICATION ===
id: '{{ id }}' # Numeric ID for stable reference (e.g., "2110")
title: '{{ title }}' # Human-readable title
type: '{{ type }}' # prd | epic | feature | task | subtask | bug | spike

# === HIERARCHY ===
parent: '' # Parent spec ID (leave empty for top-level)
children: [] # Child spec IDs (if any)
epic: '' # Root epic ID for this work
domain: '' # Business domain (e.g., "authentication", "user-management")

# === WORKFLOW ===
status: 'draft' # draft | reviewing | approved | in-progress | testing | done
priority: 'medium' # high | medium | low
assignee: '' # Who's working on this
reviewer: '' # Who should review (optional)

# === TRACKING ===
created: '{{ date }}' # YYYY-MM-DD (auto-filled by Claude)
updated: '{{ date }}' # YYYY-MM-DD (auto-updated by Claude)
due_date: '' # YYYY-MM-DD (optional)
estimated_hours: 0 # Time estimate in hours
actual_hours: 0 # Time spent so far

# === DEPENDENCIES ===
dependencies: [] # Must be done before this (spec IDs)
blocks: [] # This blocks these specs (spec IDs)
related: [] # Related but not blocking (spec IDs)

# === IMPLEMENTATION ===
pull_requests: [] # GitHub PR numbers (e.g., ["#123", "#456"])
commits: [] # Key implementation commits (e.g., ["abc1234", "def5678"])
context_file: '' # Implementation journal (e.g., "context.md")
worktree: '' # Worktree path (optional, e.g., "../worktrees/oauth")
files: [] # Key files to modify (e.g., ["src/auth/oauth.ts"])
deliverables: [] # Generated artifacts (e.g., ["docs/setup.md", "scripts/install.sh"])

# === METADATA ===
tags: [] # Searchable tags (e.g., ["oauth", "security"])
effort: 'medium' # small | medium | large | epic
risk: 'low' # low | medium | high
acceptance_criteria: 0 # Total acceptance criteria (update when defined)
acceptance_met: 0 # Completed criteria (update during implementation)
test_coverage: 0 # Test coverage percentage (update when tested)

# ============================================================================
---

# {{ title }}

## Overview

[Brief description of what this spec accomplishes and why it's needed]

## Acceptance Criteria

- [ ] [Specific, testable criterion 1]
- [ ] [Specific, testable criterion 2]
- [ ] [Specific, testable criterion 3]

## Technical Approach

[Describe the technical implementation approach]

### Key Components

[List main technical components or modules]

### Implementation Steps

1. **[Step 1 Name]**
   - [Sub-step detail]
   - [Sub-step detail]
2. **[Step 2 Name]**
   - [Sub-step detail]
   - [Sub-step detail]

## Dependencies

[Describe what must be completed before this work can start]

- **[ID]**: [Description of dependency]

## Testing Plan

[How will this be tested?]

- [Testing approach 1]
- [Testing approach 2]

## Claude Code Instructions

```
When creating a new spec from this template:
1. Create appropriate folder structure based on hierarchy:
   - Epic: specs/epic-authentication/epic-authentication.spec.md
   - Feature: specs/epic-authentication/feature-oauth-login/feature-oauth-login.spec.md
   - Task: specs/epic-authentication/feature-oauth-login/task-google-oauth/task-google-oauth.spec.md
   - Subtask: specs/epic-authentication/feature-oauth-login/task-google-oauth/subtask-api-integration/subtask-api-integration.spec.md

2. Generate a unique numeric ID following the domain numbering system
3. Fill in all empty fields in the frontmatter metadata
4. Replace all [bracketed placeholders] with actual content
5. Set parent/children relationships correctly in the hierarchy
6. Update the title and overview to match your specific requirements
7. Set status to "draft" and update as work progresses

Folder Structure Example:
specs/
├── authentication-epic/
│   ├── authentication-epic.spec.md
│   ├── oauth-login-feature/
│   │   ├── oauth-login-feature.spec.md
│   │   ├── google-oauth-task/
│   │   │   └── google-oauth-task.spec.md
│   │   └── github-oauth-task/
│   │       └── github-oauth-task.spec.md
│   └── registration-feature/
│       └── registration-feature.spec.md

When implementing this spec:
1. [Specific instruction for Claude]
2. [Implementation guidance]
3. [Important considerations]

Template Distribution:
- Copy this file to any new project: .claude-workflow/specs/spec.template.md
- Use the setup script: scripts/setup_spec_template.sh /path/to/project
- Or use VS Code command: "Claude Workflow: Initialize Spec Template"
```

## Notes

[Any additional notes, caveats, or important considerations]

## Status Updates

[Keep a log of major status changes]

- **[Date]**: [Status change and brief description]
