# /spec_work Enhancement Commands

## --update-index Command

Updates the `specs/index.md` file with current statistics and progress metrics.

```python
class IndexUpdater:
    """
    Automatically updates index.md with current spec statistics
    Uses parallel processing for efficiency
    """
    
    def update_index(self):
        """
        Main entry point for index updates
        """
        print("📊 Updating spec index with latest statistics...")
        
        # Gather stats in parallel for speed
        stats = self.gather_stats_parallel()
        
        # Update index file
        self.update_index_file(stats)
        
        print("✅ Index updated successfully!")
        return stats
    
    def gather_stats_parallel(self):
        """
        Gather statistics from all specs in parallel
        """
        import concurrent.futures
        
        tasks = [
            ('epics', self.count_epics),
            ('features', self.count_features),
            ('tasks', self.count_tasks),
            ('completed', self.count_completed),
            ('in_progress', self.count_in_progress),
            ('blocked', self.count_blocked),
            ('hours_logged', self.calculate_hours),
            ('recent_activity', self.get_recent_activity)
        ]
        
        stats = {}
        with concurrent.futures.ThreadPoolExecutor() as executor:
            futures = {executor.submit(func): name for name, func in tasks}
            for future in concurrent.futures.as_completed(futures):
                name = futures[future]
                stats[name] = future.result()
        
        # Calculate derived metrics
        stats['overall_progress'] = self.calculate_progress(stats)
        stats['velocity'] = self.calculate_velocity(stats)
        stats['epic_progress'] = self.calculate_epic_progress()
        
        return stats
    
    def update_index_file(self, stats):
        """
        Update the index.md file with new statistics
        """
        index_path = Path('specs/index.md')
        content = index_path.read_text()
        
        # Update Quick Stats section
        content = self.update_quick_stats(content, stats)
        
        # Update Motivation Metrics
        content = self.update_motivation_metrics(content, stats)
        
        # Update Progress Visualization
        content = self.update_progress_bars(content, stats)
        
        # Update Recent Activity
        content = self.update_recent_activity(content, stats)
        
        # Update timestamp
        from datetime import datetime
        timestamp = datetime.now().strftime('%Y-%m-%d %H:%M KST')
        content = re.sub(
            r'\*Last Updated: .*\*',
            f'*Last Updated: {timestamp}*',
            content
        )
        
        index_path.write_text(content)
    
    def update_quick_stats(self, content, stats):
        """
        Update the quick stats section with emojis for motivation
        """
        stats_text = f"""## 🎯 Quick Stats
<!-- These stats will be auto-updated by /spec_work --update-index -->
- **Total Epics**: {stats['epics']} 
- **Total Features**: {stats['features']}
- **Total Tasks**: {stats['tasks']}
- **Active Specs**: {stats['in_progress']}
- **Completed**: {stats['completed']} {'🔥' if stats['completed'] > 0 else ''}
- **Overall Progress**: {stats['overall_progress']:.1f}% ({stats['completed']}/{stats['features'] + stats['tasks']} items)"""
        
        # Replace the Quick Stats section
        pattern = r'## 🎯 Quick Stats.*?(?=##|\Z)'
        replacement = stats_text + '\n\n'
        return re.sub(pattern, replacement, content, flags=re.DOTALL)
    
    def update_motivation_metrics(self, content, stats):
        """
        Update motivation section with progress bars and achievements
        """
        progress = stats['overall_progress']
        bar_length = 20
        filled = int((progress / 100) * bar_length)
        bar = '█' * filled + '░' * (bar_length - filled)
        
        # Add motivational messages based on progress
        if progress < 10:
            message = "🚀 Just getting started!"
        elif progress < 25:
            message = "💪 Building momentum!"
        elif progress < 50:
            message = "🔥 On fire! Keep going!"
        elif progress < 75:
            message = "⚡ Amazing progress!"
        elif progress < 90:
            message = "🎯 Almost there!"
        else:
            message = "🏆 Victory is near!"
        
        motivation_text = f"""## 🚀 Motivation Metrics
```
Progress Bar: [{bar}] {progress:.1f}%
This Week: +{stats.get('completed_this_week', 0)} completed ✅
Velocity: {stats['velocity']} specs/week
Status: {message}
```"""
        
        pattern = r'## 🚀 Motivation Metrics.*?```.*?```'
        replacement = motivation_text
        return re.sub(pattern, replacement, content, flags=re.DOTALL)
    
    def calculate_epic_progress(self):
        """
        Calculate progress for each epic
        """
        epic_progress = {}
        
        for epic_dir in Path('specs').glob('[0-9]*'):
            if epic_dir.is_dir():
                epic_id = epic_dir.name
                total = 0
                completed = 0
                
                # Count features and tasks
                for spec_file in epic_dir.rglob('*.md'):
                    if 'context' not in spec_file.name and spec_file.name != 'epic.md':
                        total += 1
                        # Check if completed (look for context file)
                        context_file = spec_file.with_suffix('.context.md')
                        if context_file.exists():
                            context_content = context_file.read_text()
                            if 'Status**: completed' in context_content:
                                completed += 1
                
                progress = (completed / total * 100) if total > 0 else 0
                epic_progress[epic_id] = {
                    'total': total,
                    'completed': completed,
                    'progress': progress
                }
        
        return epic_progress
```

## --dashboard Command

Shows a live, interactive dashboard with real-time progress tracking.

```python
class SpecDashboard:
    """
    Interactive dashboard for spec progress visualization
    Updates in real-time using terminal colors and formatting
    """
    
    def show_dashboard(self):
        """
        Display interactive dashboard
        """
        import os
        os.system('clear')  # Clear terminal
        
        print(self.render_header())
        print(self.render_stats())
        print(self.render_epic_progress())
        print(self.render_recent_activity())
        print(self.render_next_actions())
        
        # Auto-refresh option
        refresh = input("\n🔄 Auto-refresh? (y/n): ")
        if refresh.lower() == 'y':
            self.auto_refresh_dashboard()
    
    def render_header(self):
        """
        Render dashboard header with ASCII art
        """
        return """
╔══════════════════════════════════════════════════════════════╗
║             📊 JTS SPECIFICATION DASHBOARD 📊                ║
║                  Real-time Progress Tracker                  ║
╚══════════════════════════════════════════════════════════════╝
        """
    
    def render_stats(self):
        """
        Render key statistics with colors
        """
        stats = self.gather_stats_parallel()
        
        return f"""
📈 KEY METRICS
├─ Total Specs: {self.colorize(stats['features'] + stats['tasks'], 'blue')}
├─ Completed: {self.colorize(stats['completed'], 'green')} ✅
├─ In Progress: {self.colorize(stats['in_progress'], 'yellow')} 🚧
├─ Blocked: {self.colorize(stats['blocked'], 'red')} ❌
├─ Overall Progress: {self.render_progress_bar(stats['overall_progress'])}
└─ Velocity: {self.colorize(f"{stats['velocity']} specs/week", 'cyan')}
        """
    
    def render_epic_progress(self):
        """
        Render progress for each epic with visual bars
        """
        epic_progress = self.calculate_epic_progress()
        epic_names = {
            '1000': 'Foundation',
            '2000': 'Broker Integration',
            '3000': 'Market Data',
            '4000': 'Strategy Engine',
            '5000': 'Risk Management',
            '6000': 'Order Execution',
            '7000': 'User Interface',
            '8000': 'Monitoring',
            '9000': 'Backtesting',
            '10000': 'Cryptocurrency',
            '11000': 'Performance',
            '12000': 'Deployment'
        }
        
        output = "\n📁 EPIC PROGRESS\n"
        for epic_id, data in sorted(epic_progress.items()):
            name = epic_names.get(epic_id, f"Epic {epic_id}")
            bar = self.render_progress_bar(data['progress'])
            status = "✅" if data['progress'] == 100 else "🚧" if data['progress'] > 0 else "📋"
            output += f"├─ {name:20} {bar} {data['completed']}/{data['total']} {status}\n"
        
        return output
    
    def render_progress_bar(self, percentage, width=20):
        """
        Render a colored progress bar
        """
        filled = int((percentage / 100) * width)
        bar = '█' * filled + '░' * (width - filled)
        
        # Color based on progress
        if percentage < 25:
            color = 'red'
        elif percentage < 50:
            color = 'yellow'
        elif percentage < 75:
            color = 'blue'
        else:
            color = 'green'
        
        return f"{self.colorize(bar, color)} {percentage:.1f}%"
    
    def render_recent_activity(self):
        """
        Show recent spec activity
        """
        activities = self.get_recent_activity(limit=5)
        
        output = "\n📅 RECENT ACTIVITY\n"
        for activity in activities:
            emoji = "✅" if "completed" in activity.lower() else "🚧"
            output += f"├─ {activity} {emoji}\n"
        
        return output
    
    def render_next_actions(self):
        """
        Suggest next actions based on current state
        """
        suggestions = self.get_smart_suggestions()
        
        output = "\n🎯 SUGGESTED NEXT ACTIONS\n"
        for i, suggestion in enumerate(suggestions[:3], 1):
            output += f"{i}. {suggestion}\n"
        
        return output
    
    def get_smart_suggestions(self):
        """
        AI-powered suggestions for next actions
        Uses Opus 4.1 to analyze current state and suggest priorities
        """
        # This would use Opus 4.1 to analyze the current state
        # and provide intelligent suggestions
        return [
            "Complete Hot Storage NVMe setup (1011) - Foundation critical path",
            "Start Development Environment (1002) - Unblocks 3 other specs",
            "Review and update Broker Integration plan - High complexity item"
        ]
    
    def colorize(self, text, color):
        """
        Add ANSI color codes to text
        """
        colors = {
            'red': '\033[91m',
            'green': '\033[92m',
            'yellow': '\033[93m',
            'blue': '\033[94m',
            'cyan': '\033[96m',
            'reset': '\033[0m'
        }
        return f"{colors.get(color, '')}{text}{colors['reset']}"
    
    def auto_refresh_dashboard(self, interval=5):
        """
        Auto-refresh dashboard every N seconds
        """
        import time
        import os
        
        try:
            while True:
                os.system('clear')
                print(self.render_header())
                print(self.render_stats())
                print(self.render_epic_progress())
                print(self.render_recent_activity())
                print(self.render_next_actions())
                print(f"\n⏱️ Auto-refreshing every {interval}s (Ctrl+C to stop)")
                time.sleep(interval)
        except KeyboardInterrupt:
            print("\n👋 Dashboard closed")
```

## Usage Examples

### Update Index
```bash
/spec_work --update-index

# Output:
📊 Updating spec index with latest statistics...
  ✓ Counted 12 epics
  ✓ Counted 21 features
  ✓ Counted 7 tasks
  ✓ Found 1 completed specs
  ✓ Found 2 in-progress specs
  ✓ Calculated 4.8% overall progress
  ✓ Updated motivation metrics
  ✓ Updated progress visualizations
✅ Index updated successfully!
```

### Show Dashboard
```bash
/spec_work --dashboard

# Shows interactive colored dashboard with:
# - Real-time stats
# - Progress bars for each epic
# - Recent activity feed
# - Smart suggestions for next actions
# - Auto-refresh option
```

## Motivational Features

### Achievement Badges
When certain milestones are reached, special badges appear in the index:

- 🥇 **First Spec Completed** - Awarded when first spec is done
- 🔟 **10% Progress** - Reached 10% completion
- 🚀 **Velocity Champion** - Completed 3+ specs in a week
- 💯 **Epic Master** - Completed an entire epic
- 🏆 **Half Way There** - Reached 50% overall progress

### Progress Celebrations
The system automatically adds celebration messages:

```python
def get_celebration_message(progress):
    milestones = {
        10: "🎉 Double digits! You've reached 10% completion!",
        25: "🌟 Quarter way there! 25% complete!",
        50: "🔥 HALF WAY! You're crushing it! 50% done!",
        75: "⚡ Three quarters complete! The finish line is in sight!",
        90: "🏁 The final stretch! 90% complete!",
        100: "🏆 VICTORY! 100% Complete! You did it!"
    }
    
    for milestone, message in milestones.items():
        if abs(progress - milestone) < 0.5:
            return message
    return None
```

### Weekly Summary
Every Monday, the dashboard shows a weekly summary:

```
📊 WEEKLY SUMMARY (Week of 2025-08-26)
├─ Specs Completed: 3 ✅
├─ Hours Invested: 12.5
├─ Velocity Trend: ↗️ Increasing
├─ Streak: 5 days 🔥
└─ Next Milestone: 10% overall (2 specs away)
```

## Configuration

Create `.claude/spec_work_dashboard.json`:

```json
{
  "auto_refresh_interval": 5,
  "show_achievements": true,
  "celebration_mode": "emoji_fireworks",
  "progress_bar_style": "blocks",
  "color_theme": "vibrant",
  "motivation_level": "high",
  "weekly_summary_day": "monday"
}
```