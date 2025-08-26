# /spec_work Split Operations Extension

## Extended Command Syntax for Splitting

```bash
# Split epic into features
/spec_work 2000 --split features

# Split feature into tasks  
/spec_work 2101 --split tasks

# Split task into subtasks
/spec_work 1014 --split subtasks

# Interactive splitting (asks what to split into)
/spec_work 2000 --split
```

## Implementation for Split Operations

```python
class SpecWorkCommand:
    def execute(self, spec_id: str, action: str = 'start', split: str = None, **kwargs):
        """
        Extended execute with split capability
        
        CRITICAL FOR SPLITS:
        - Always uses Opus 4.1 for intelligent spec analysis
        - Runs multiple subagents in parallel:
          * software-architect: Design feature boundaries
          * system-trading-specialist: Trading domain expertise
          * test-automation-specialist: Test coverage planning
        - Parallel processing for maximum efficiency
        """
        
        if split:
            return self.split_spec(spec_id, split)
        
        # ... original implementation
    
    def split_spec(self, spec_id: str, split_type: str = None):
        """
        Split a spec into child specs
        """
        spec_path = self.find_spec(spec_id)
        spec_level = self.determine_spec_level(spec_id)  # epic/feature/task
        
        if not split_type:
            # Interactive mode
            split_type = self.prompt_split_type(spec_level)
        
        if spec_level == 'epic' and split_type == 'features':
            return self.split_epic_to_features(spec_id, spec_path)
        elif spec_level == 'feature' and split_type == 'tasks':
            return self.split_feature_to_tasks(spec_id, spec_path)
        elif spec_level == 'task' and split_type == 'subtasks':
            return self.split_task_to_subtasks(spec_id, spec_path)
        else:
            return f"Cannot split {spec_level} into {split_type}"
    
    def split_epic_to_features(self, epic_id: str, epic_path: Path):
        """
        Split epic (2000) into features (2100, 2101, 2102...)
        
        Uses Opus 4.1 with parallel subagent analysis:
        1. software-architect: Feature boundaries & dependencies
        2. system-trading-specialist: Domain-specific requirements
        3. test-automation-specialist: Testability considerations
        """
        print(f"🧠 Analyzing Epic {epic_id} with Opus 4.1 and specialized agents...")
        
        # Run multiple agents in PARALLEL for comprehensive analysis
        parallel_tasks = [
            ('software-architect', 'Break down epic into logical features with clear boundaries'),
            ('system-trading-specialist', 'Identify trading-specific feature requirements'),
            ('test-automation-specialist', 'Plan test coverage for each feature')
        ]
        
        # Execute all agents simultaneously
        results = self.run_parallel_agents(parallel_tasks, epic_path)
        features = self.merge_agent_results(results)
        
        # 2. Create feature specs
        created_features = []
        for feature in features:
            feature_id = feature['id']  # e.g., 2100
            feature_path = f"specs/{epic_id}/{feature_id}.md"
            
            # Create feature spec
            self.create_spec_file(feature_path, feature)
            created_features.append(feature_id)
            
            print(f"✅ Created feature {feature_id}: {feature['title']}")
        
        # 3. Update epic spec with feature links
        self.update_parent_spec(epic_path, created_features, 'features')
        
        # 4. Update epic context
        epic_context = f"specs/{epic_id}/context.md"
        self.log_split_action(epic_context, 'features', created_features)
        
        return f"Split epic {epic_id} into {len(created_features)} features"
    
    def split_feature_to_tasks(self, feature_id: str, feature_path: Path):
        """
        Split feature (2101) into tasks (2101.1, 2101.2, 2101.3...)
        Or for 1001 → 1011, 1012, 1013...
        
        Opus 4.1 orchestrates parallel analysis:
        - Technical complexity assessment
        - Implementation dependencies
        - Testing requirements per task
        """
        print(f"🧠 Analyzing Feature {feature_id} with Opus 4.1...")
        
        # Parallel agent execution for task breakdown
        parallel_analysis = self.run_parallel_agents([
            ('software-architect', 'Define task boundaries and dependencies'),
            ('nestjs-testing-expert', 'Identify testing needs per task')
        ], feature_path)
        
        # Determine task numbering scheme
        if len(feature_id) == 4:  # e.g., 2101
            task_prefix = f"{feature_id}."  # Will create 2101.1, 2101.2
        else:  # e.g., 1001
            task_prefix = f"{feature_id[0:2]}{feature_id[2:]}"  # Will create 1011, 1012
        
        # 1. Analyze feature for tasks
        tasks = self.analyze_feature_tasks(feature_path)
        
        # 2. Create task specs
        created_tasks = []
        for i, task in enumerate(tasks, 1):
            if len(feature_id) == 4:
                task_id = f"{feature_id}.{i}"  # 2101.1
            else:
                task_id = f"{task_prefix}{i}"  # 1011
            
            # Create in feature directory
            feature_dir = feature_path.parent
            task_path = feature_dir / f"{task_id}.md"
            
            self.create_spec_file(task_path, task)
            created_tasks.append(task_id)
            
            print(f"✅ Created task {task_id}: {task['title']}")
        
        # 3. Update feature spec
        self.update_parent_spec(feature_path, created_tasks, 'tasks')
        
        # 4. Update feature context
        self.log_split_action(feature_path.with_name('context.md'), 'tasks', created_tasks)
        
        return f"Split feature {feature_id} into {len(created_tasks)} tasks"
    
    def split_task_to_subtasks(self, task_id: str, task_path: Path):
        """
        Split task (1014) into subtasks (1014/1014.1, 1014/1014.2...)
        Using Option A: Subfolder structure
        
        Even for subtasks, uses intelligent analysis:
        - Opus 4.1 for complex decomposition
        - Parallel processing when beneficial
        """
        print(f"🧠 Analyzing Task {task_id} for subtask breakdown...")
        
        # For subtasks, still use intelligent analysis
        subtask_analysis = self.analyze_with_opus('Break down into atomic, testable subtasks', task_path)
        
        # 1. Analyze task for subtasks
        subtasks = self.analyze_task_subtasks(task_path)
        
        # 2. Create subtask directory
        subtask_dir = task_path.parent / task_id
        subtask_dir.mkdir(exist_ok=True)
        
        # 3. Create subtask specs
        created_subtasks = []
        for i, subtask in enumerate(subtasks, 1):
            subtask_id = f"{task_id}.{i}"
            subtask_path = subtask_dir / f"{subtask_id}.md"
            
            self.create_spec_file(subtask_path, subtask)
            created_subtasks.append(subtask_id)
            
            print(f"✅ Created subtask {subtask_id}: {subtask['title']}")
        
        # 4. Update task spec with subtask links
        self.update_parent_spec(task_path, created_subtasks, 'subtasks')
        
        # 5. Update task context
        task_context = task_path.with_suffix('.context.md')
        self.log_split_action(task_context, 'subtasks', created_subtasks)
        
        return f"Split task {task_id} into {len(created_subtasks)} subtasks"
```

## Usage Examples

### Split Epic to Features
```bash
/spec_work 2000 --split features

# Output:
Analyzing Epic 2000 for feature breakdown...
Using software-architect agent...
✅ Created feature 2100: Unified Broker Interface
✅ Created feature 2101: KIS REST API Integration
✅ Created feature 2102: KIS WebSocket Real-time
...
Split epic 2000 into 11 features
```

### Split Feature to Tasks
```bash
/spec_work 1001 --split tasks

# Output:
Analyzing Feature 1001 for task breakdown...
✅ Created task 1011: Hot Storage NVMe
✅ Created task 1012: Database Mount Integration
✅ Created task 1013: Warm Storage SATA
✅ Created task 1014: Cold Storage NAS
Split feature 1001 into 4 tasks
```

### Split Task to Subtasks
```bash
/spec_work 1014 --split subtasks

# Output:
Analyzing Task 1014 for subtask breakdown...
Creating subtask directory: specs/1000/1001/1014/
✅ Created subtask 1014.1: Network Buffer Optimization
✅ Created subtask 1014.2: Directory Structure Setup
✅ Created subtask 1014.3: Health Monitoring Script
Split task 1014 into 3 subtasks
```

### Interactive Splitting
```bash
/spec_work 2000 --split

# Output:
Detected spec level: Epic

What would you like to split this epic into?
1. Features (20-40 hour chunks)
2. Skip and go directly to tasks
3. Cancel

Your choice: 1
```

## Split Operation Context Logging

When splitting occurs, the parent's context file is updated:

```markdown
### Session 3: 2025-08-26 - Split Operation
**Action**: Split epic into features
**Method**: Software architect analysis
**Created Specs**:
- [[2100|Feature 2100: Unified Broker Interface]]
- [[2101|Feature 2101: KIS REST API]]
- [[2102|Feature 2102: KIS WebSocket]]
**Rationale**: Each feature represents 20-40 hours of focused work
**Commit**: abc123 - Split epic 2000 into 11 features
```