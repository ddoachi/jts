# /spec_work Command Implementation

## Command Overview

**Purpose**: Manage complete lifecycle of spec implementation with full traceability, context preservation, and deliverable tracking.

**Key Features**:
- Creates and maintains context files alongside specs
- Tracks all implementation actions in timeline format
- Manages deliverables with bidirectional links
- Preserves complete implementation history
- Supports session-based work with resume capability
- **Uses Opus 4.1 for critical analysis and planning**
- **Leverages specialized subagents in parallel for maximum efficiency**
- **Sonnet 4 for implementation execution**

## Command Syntax

```bash
# Start new implementation
/spec_work {spec-id}

# Resume previous work
/spec_work {spec-id} --resume

# Check implementation status
/spec_work {spec-id} --status

# Generate deliverables report
/spec_work {spec-id} --deliverables

# With custom session title
/spec_work {spec-id} --session "Performance Optimization"

# Update index with current stats
/spec_work --update-index

# Show dashboard with progress metrics
/spec_work --dashboard
```

## Implementation Details

```python
# Command implementation structure
class SpecWorkCommand:
    def execute(self, spec_id: str = None, action: str = 'start', session: str = None, update_index: bool = False, dashboard: bool = False):
        """
        Main entry point for spec_work command
        
        CRITICAL: Uses Opus 4.1 for analysis and planning phases
        Leverages specialized subagents in parallel:
        - software-architect: For system design decisions
        - nestjs-testing-expert: For test planning
        - test-automation-specialist: For quality assurance
        
        Implementation uses Sonnet 4 for efficiency
        """
        
        # Handle index/dashboard operations
        if update_index:
            return self.update_spec_index()
        if dashboard:
            return self.show_dashboard()
        # 1. Locate spec file
        spec_path = self.find_spec(spec_id)
        if not spec_path:
            return f"Spec {spec_id} not found"
        
        # 2. Load or create context file
        context_path = spec_path.replace('.md', '.context.md')
        context = self.load_or_create_context(context_path, spec_path)
        
        # 3. Execute requested action
        if action == 'start' or action == 'resume':
            return self.work_on_spec(spec_path, context, session)
        elif action == 'status':
            return self.show_status(context)
        elif action == 'deliverables':
            return self.show_deliverables(context)
    
    def work_on_spec(self, spec_path, context, session_title):
        """
        Interactive implementation session
        
        WORKFLOW:
        1. Planning Phase - Uses Opus 4.1 with parallel subagents
        2. Implementation Phase - Uses Sonnet 4 for execution
        3. Quality Phase - Uses test-automation-specialist
        """
        
        # Phase 1: Analysis with Opus 4.1 and subagents in parallel
        print("🧠 Using Opus 4.1 for deep analysis...")
        analysis_tasks = [
            ('software-architect', 'Design optimal implementation approach'),
            ('nestjs-testing-expert', 'Plan comprehensive test strategy'),
            ('test-automation-specialist', 'Identify quality checkpoints')
        ]
        
        # Run subagents in parallel for maximum efficiency
        results = self.run_parallel_agents(analysis_tasks)
        
        # Create new session in context
        session = context.add_session(session_title or "Implementation")
        session.add_analysis(results)
        
        # Show current progress
        self.display_progress(context)
        
        # Implementation loop
        while True:
            action = self.prompt_next_action()
            
            if action == 'implement':
                # Record implementation steps
                step = self.get_implementation_details()
                session.add_implementation(step)
                context.save()
                
            elif action == 'deliverable':
                # Create and track deliverable
                deliverable = self.create_deliverable(spec_path)
                session.add_deliverable(deliverable)
                self.update_spec_deliverables(spec_path, deliverable)
                context.save()
                
            elif action == 'test':
                # Record test results
                test_results = self.run_tests()
                session.add_test_results(test_results)
                context.save()
                
            elif action == 'commit':
                # Git commit with proper message
                commit = self.create_commit()
                session.add_commit(commit)
                context.save()
                
            elif action == 'done':
                # Finalize session
                session.finalize()
                context.save()
                return self.generate_summary(session)
    
    def create_deliverable(self, spec_path):
        """
        Create a deliverable with proper tracking
        """
        # Determine deliverable type and location
        dtype = self.prompt_deliverable_type()  # script/doc/config
        name = self.prompt_deliverable_name()
        
        # Create deliverable path (co-located with spec)
        spec_dir = os.path.dirname(spec_path)
        deliverable_path = f"{spec_dir}/deliverables/{dtype}/{name}"
        
        # Generate content with traceback headers
        content = self.generate_deliverable_content()
        content = self.add_traceback_headers(content, spec_path)
        
        # Save deliverable
        self.save_file(deliverable_path, content)
        
        # Return deliverable metadata
        return {
            'type': dtype,
            'name': name,
            'path': deliverable_path,
            'markdown_link': f"[{name}](deliverables/{dtype}/{name})"
        }
```

## Context File Operations

```python
class ContextFile:
    """
    Manages spec context file with timeline-based tracking
    """
    
    def __init__(self, path, spec_path):
        self.path = path
        self.spec_path = spec_path
        self.data = self.load() or self.create_new()
    
    def create_new(self):
        """
        Initialize new context file
        """
        return {
            'spec': self.create_markdown_link(self.spec_path),
            'status': 'planning',
            'created': datetime.now(),
            'sessions': [],
            'deliverables': [],
            'metrics': {}
        }
    
    def add_session(self, title):
        """
        Start new implementation session
        """
        session = {
            'id': len(self.sessions) + 1,
            'title': title,
            'date': datetime.now(),
            'duration': 0,
            'planning': [],
            'spec_changes': [],
            'implementation': [],
            'testing': [],
            'commits': [],
            'issues': []
        }
        self.sessions.append(session)
        return Session(session, self)
    
    def save(self):
        """
        Save context to markdown file with proper formatting
        """
        content = self.render_markdown()
        with open(self.path, 'w') as f:
            f.write(content)
    
    def render_markdown(self):
        """
        Generate markdown representation of context
        """
        md = f"""# Context: {self.get_spec_title()}

**Spec**: {self.data['spec']}
**Status**: {self.data['status']}
**Created**: {self.data['created']}
**Updated**: {datetime.now()}

## Summary
{self.data.get('summary', 'Implementation in progress...')}

## Implementation Timeline
"""
        
        for session in self.data['sessions']:
            md += self.render_session(session)
        
        md += self.render_deliverables()
        md += self.render_metrics()
        
        return md
```

## Bidirectional Link Management

```python
class LinkManager:
    """
    Manages markdown-compatible bidirectional links
    """
    
    def create_link(self, source_file, target_file, link_text=None):
        """
        Create markdown-compatible link
        """
        # Calculate relative path from source to target
        rel_path = os.path.relpath(target_file, os.path.dirname(source_file))
        
        # Format as markdown link
        if link_text:
            return f"[{link_text}]({rel_path})"
        else:
            # Use filename without extension as link text
            filename = os.path.basename(rel_path)
            if filename.endswith('.md'):
                filename = filename[:-3]
            return f"[{filename}]({rel_path})"
    
    def update_spec_deliverables(self, spec_file, deliverable):
        """
        Add deliverable link to spec file
        """
        # Read spec file
        spec_content = self.read_file(spec_file)
        
        # Find or create deliverables section
        if "## Deliverables" not in spec_content:
            spec_content += "\n## Deliverables\n"
        
        # Add deliverable link in appropriate category
        category = f"### {deliverable['type'].title()}"
        if category not in spec_content:
            spec_content += f"\n{category}\n"
        
        # Insert link
        link = self.create_link(spec_file, deliverable['path'], deliverable['name'])
        spec_content = spec_content.replace(
            category,
            f"{category}\n- {link} - {deliverable.get('description', '')}"
        )
        
        # Save updated spec
        self.save_file(spec_file, spec_content)
    
    def add_traceback_to_deliverable(self, deliverable_file, spec_file):
        """
        Add traceback comments to deliverable
        """
        content = self.read_file(deliverable_file)
        
        # Determine comment style based on file extension
        ext = os.path.splitext(deliverable_file)[1]
        comment_style = self.get_comment_style(ext)
        
        # Create traceback header
        spec_link = self.create_link(deliverable_file, spec_file, "Original Spec")
        context_link = self.create_link(
            deliverable_file, 
            spec_file.replace('.md', '.context.md'),
            "Implementation Context"
        )
        
        header = f"""{comment_style['start']}
Generated from: {spec_link}
Context: {context_link}
Created: {datetime.now()}
Purpose: {self.get_deliverable_purpose(deliverable_file)}
{comment_style['end']}"""
        
        # Prepend header to content
        content = header + "\n\n" + content
        
        # Save updated deliverable
        self.save_file(deliverable_file, content)
```

## Status and Reporting

```python
class StatusReporter:
    """
    Generate status and deliverables reports
    """
    
    def show_status(self, context):
        """
        Display implementation status
        """
        total_tasks = len(context.get_all_tasks())
        completed_tasks = len(context.get_completed_tasks())
        progress = (completed_tasks / total_tasks * 100) if total_tasks > 0 else 0
        
        status = f"""
# Spec {context.spec_id}: {context.spec_title}

## Progress: {progress:.0f}% Complete ({completed_tasks}/{total_tasks} tasks)

### Completed:
{self.format_task_list(context.get_completed_tasks(), '✅')}

### In Progress:
{self.format_task_list(context.get_in_progress_tasks(), '⏳')}

### Blocked:
{self.format_task_list(context.get_blocked_tasks(), '❌')}

### Deliverables Created:
{self.summarize_deliverables(context.deliverables)}

### Time Spent:
{self.summarize_time(context.sessions)}

### Last Activity: {context.last_activity}
"""
        return status
    
    def show_deliverables(self, context):
        """
        Generate comprehensive deliverables report
        """
        report = f"""
# Deliverables Report: {context.spec_title}

## Created Artifacts

{self.format_deliverables_by_type(context.deliverables)}

## Usage by Other Specs

{self.find_deliverable_usage(context.deliverables)}

## Integration Points

{self.identify_integration_points(context.deliverables)}

## Metrics

{self.calculate_deliverable_metrics(context.deliverables)}
"""
        return report
```

## Usage Examples

### Starting New Implementation
```
User: /spec_work 1014

Claude: Loading spec 1014 (Cold Storage NAS Integration)...
No existing context found. Creating new context file.

Current status: Not started
Estimated effort: 3 hours

Would you like to:
1. Review spec requirements
2. Create implementation plan
3. Begin implementation
4. View dependencies

Your choice:
```

### Resuming Work
```
User: /spec_work 1014 --resume

Claude: Resuming spec 1014 (Cold Storage NAS Integration)

Previous session: 2025-08-26 (2.5 hours)
Progress: 3/7 tasks completed

Ready to continue with:
Task 4: Create directory structure for data organization

Proceed? (yes/no/review):
```

### Creating Deliverable
```
Claude: Creating health monitoring script...

Deliverable type: script
Location: specs/1000/1001/deliverables/scripts/nas-health-check.sh
Added traceback headers linking to spec and context
Updated spec file with deliverable link
Context file updated with deliverable entry

Script created successfully.
```

## Benefits

1. **Complete Traceability**
   - Every action logged with timestamp
   - Full implementation history preserved
   - Git commits linked to spec progress

2. **Organized Deliverables**
   - Co-located with specs
   - Bidirectional links for navigation
   - Clear origin tracking

3. **Session Management**
   - Resume work anytime
   - Track time per session
   - Preserve context between sessions

4. **Universal Compatibility**
   - Standard markdown links work everywhere
   - Easy navigation in any markdown viewer
   - GitHub-compatible formatting

5. **Team Collaboration**
   - Clear handoff between developers
   - Complete context preservation
   - Decisions and rationale documented

## Configuration

Create `.claude/spec_work.config.json`:

```json
{
  "defaultSessionTitle": "Implementation Session",
  "autoCommit": true,
  "deliverableTypes": ["script", "doc", "config", "test"],
  "linkStyle": "markdown",
  "contextFileLocation": "adjacent",
  "deliverableLocation": "colocated",
  "trackingLevel": "detailed",
  "gitIntegration": true
}
```

## Summary

The `/spec_work` command provides:
- **Full lifecycle management** of spec implementation
- **Complete traceability** of all actions and decisions
- **Organized deliverables** with bidirectional links
- **Session-based workflow** with resume capability
- **Comprehensive reporting** of status and deliverables

This solves all the issues you identified:
1. ✅ Preserves all implementation records
2. ✅ Creates proper markdown links between files
3. ✅ Tracks deliverables with clear origin
4. ✅ Provides smarter folder structure