# 📊 Spec Dashboard

> Auto-generated from spec files on {{calculated.lastUpdated}}

## 🎯 Quick Stats

- **Total Epics**: {{stats.total_epics}}
- **Total Features**: {{stats.total_features}}
- **Total Tasks**: {{stats.total_tasks}}
- **Total Subtasks**: {{stats.total_subtasks}}
- **Completed**: {{stats.completed.length}} 🔥
- **In Progress**: {{stats.in_progress.length}}
- **Overall Progress**: {{calculated.progressPercentage}}%

## 🚀 Progress

```
Progress Bar: [{{calculated.progressBar}}] {{calculated.progressPercentage}}%
Completed: {{stats.completed.length}}/{{calculated.totalSpecs}}
```

## 📁 Specifications

{{#each hierarchy as |epic epicKey|}}

### {{statusIcon epic.status}} [{{epicKey}} - {{{epic.title}}}]({{epicKey}}/spec.md)

> Status: `{{epic.status}}` | Priority: `{{epic.priority}}`

{{#if epic.children}}
{{#each epic.children as |feature featureKey|}}

- {{statusIcon feature.status}} [{{featureKey}} - {{{feature.title}}}]({{specPath epicKey featureKey}}/spec.md) `{{feature.status}}`
  {{#if feature.children}}
  {{#each feature.children as |task taskKey|}}
  - {{statusIcon task.status}} [{{taskKey}} - {{{task.title}}}]({{specPath epicKey featureKey taskKey}}/spec.md) `{{task.status}}`
    {{#if task.children}}
    {{#each task.children as |subtask subtaskKey|}} - {{statusIcon subtask.status}} [{{subtaskKey}} - {{{subtask.title}}}]({{specPath epicKey featureKey taskKey subtaskKey}}/spec.md) `{{subtask.status}}`
    {{/each}}
    {{/if}}
    {{/each}}
    {{/if}}
    {{/each}}
    {{/if}}

{{/each}}

---

_Generated automatically by GitHub Actions_
