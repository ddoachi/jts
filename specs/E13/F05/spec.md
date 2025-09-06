# E13-F05: Progress Calculation Engine

## Spec Information

- **Spec ID**: E13-F05
- **Title**: Progress Calculation Engine
- **Parent**: E13
- **Type**: Feature
- **Status**: Draft
- **Priority**: Medium
- **Created**: 2025-09-05
- **Updated**: 2025-09-05
- **Dependencies**: E13-F01

## Description

Automated progress tracking with statistical analysis and dependency-aware calculations. This feature computes completion percentages, velocity metrics, and provides insights into spec implementation progress across epics, features, and tasks.

## Context

The progress calculation engine provides quantitative metrics about spec implementation status. It analyzes spec hierarchies, aggregates completion data, and generates statistics that help stakeholders understand project progress and velocity trends.

## Scope

### In Scope

- Status-based completion calculations
- Hierarchical progress aggregation
- Weighted progress by priority
- Dependency chain impact analysis
- Velocity and trend calculations
- Burndown/burnup metrics
- Estimated completion dates
- Progress history tracking

### Out of Scope

- Time tracking integration
- Developer assignment tracking
- Cost/budget calculations
- External tool integrations (Jira, etc.)
- Automated status updates

## Acceptance Criteria

- [ ] Accurate progress calculation for all spec levels
- [ ] Real-time progress updates on spec changes
- [ ] Dependency-aware completion predictions
- [ ] Historical trend data for velocity
- [ ] < 100ms calculation time for 1000 specs
- [ ] Support for custom weight configurations
- [ ] Export metrics in multiple formats
- [ ] 95% test coverage for calculations

## Tasks

### T01: Core Progress Calculator

**Status**: Draft
**Priority**: Critical

Implement fundamental progress calculation logic based on spec statuses.

**Deliverables**:

- ProgressCalculator service
- Status to percentage mapping
- Weighted average calculations
- Progress aggregation logic
- Percentage precision handling

---

### T02: Hierarchical Aggregation

**Status**: Draft
**Priority**: Critical

Calculate rolled-up progress for epics and features based on child completion.

**Deliverables**:

- Bottom-up aggregation algorithm
- Parent progress from children
- Weighted aggregation by type
- Handling of mixed status levels
- Recursive calculation optimization

---

### T03: Dependency Analysis

**Status**: Draft
**Priority**: High

Analyze dependency chains to understand blocked progress and critical paths.

**Deliverables**:

- Dependency graph builder
- Blocked spec identification
- Critical path calculation
- Dependency completion impact
- Circular dependency detection

---

### T04: Velocity Metrics

**Status**: Draft
**Priority**: Medium

Calculate velocity based on historical completion rates and status changes.

**Deliverables**:

- Status change tracking
- Daily/weekly/monthly velocity
- Moving average calculations
- Velocity trend analysis
- Sprint velocity if applicable

---

### T05: Prediction Engine

**Status**: Draft
**Priority**: Medium

Estimate completion dates based on current velocity and remaining work.

**Deliverables**:

- Remaining work calculation
- Velocity-based predictions
- Confidence intervals
- Monte Carlo simulations
- Risk-adjusted estimates

---

### T06: Metrics Export

**Status**: Draft
**Priority**: Low

Export progress metrics in various formats for reporting and visualization.

**Deliverables**:

- JSON metrics export
- CSV report generation
- Burndown chart data
- Gantt chart compatibility
- Dashboard-ready formats

## Technical Architecture

### Module Structure

```
apps/spec-api/src/modules/analytics/
├── services/
│   ├── progress-calculator.service.ts
│   ├── aggregation.service.ts
│   ├── dependency-analyzer.service.ts
│   ├── velocity.service.ts
│   └── prediction.service.ts
├── entities/
│   ├── progress.entity.ts
│   ├── velocity.entity.ts
│   └── prediction.entity.ts
├── utils/
│   ├── statistics.util.ts
│   └── weighted-average.util.ts
└── analytics.module.ts
```

### Progress Calculation Models

#### Status Weights

```typescript
enum StatusWeight {
  DRAFT = 0,
  IN_PROGRESS = 0.5,
  REVIEW = 0.75,
  COMPLETED = 1.0,
  BLOCKED = 0.25,
  CANCELLED = 0,
}

interface ProgressConfig {
  statusWeights: Record<string, number>;
  typeWeights: {
    epic: number; // e.g., 1.0
    feature: number; // e.g., 0.8
    task: number; // e.g., 0.6
  };
  priorityWeights: {
    critical: number; // e.g., 2.0
    high: number; // e.g., 1.5
    medium: number; // e.g., 1.0
    low: number; // e.g., 0.5
  };
}
```

#### Progress Calculation

```typescript
interface Progress {
  specId: string;
  percentage: number; // 0-100
  completed: number; // Count of completed items
  total: number; // Total items
  weighted: number; // Weighted progress
  children?: Progress[]; // Child progress
  blockedBy?: string[]; // Blocking dependencies
  lastUpdated: Date;
}

class ProgressCalculator {
  // Simple progress
  calculateSimple(specs: Spec[]): number {
    const completed = specs.filter((s) => s.status === 'completed').length;
    return (completed / specs.length) * 100;
  }

  // Weighted progress
  calculateWeighted(specs: Spec[], config: ProgressConfig): number {
    return (
      (specs.reduce((sum, spec) => {
        const statusWeight = config.statusWeights[spec.status];
        const priorityWeight = config.priorityWeights[spec.priority];
        return sum + statusWeight * priorityWeight;
      }, 0) /
        specs.length) *
      100
    );
  }

  // Hierarchical progress
  calculateHierarchical(epic: Spec): Progress {
    const features = this.getFeatures(epic.id);
    const featureProgress = features.map((f) => this.calculateFeature(f));

    return {
      specId: epic.id,
      percentage: this.aggregateProgress(featureProgress),
      completed: featureProgress.filter((p) => p.percentage === 100).length,
      total: features.length,
      children: featureProgress,
      lastUpdated: new Date(),
    };
  }
}
```

### Velocity Tracking

```typescript
interface VelocityMetrics {
  period: 'daily' | 'weekly' | 'monthly';
  completedCount: number;
  completedPoints?: number;
  averageVelocity: number;
  trend: 'increasing' | 'stable' | 'decreasing';
  history: VelocityPoint[];
}

interface VelocityPoint {
  date: Date;
  completed: number;
  inProgress: number;
  velocity: number;
}

class VelocityService {
  calculateVelocity(specs: Spec[], period: string, lookback: number): VelocityMetrics {
    // Group completions by period
    // Calculate moving average
    // Determine trend
    // Return metrics
  }

  predictCompletion(remaining: number, velocity: number, confidence: number): PredictionResult {
    // Monte Carlo simulation
    // Calculate confidence intervals
    // Return prediction
  }
}
```

### Dependency Analysis

```typescript
interface DependencyImpact {
  specId: string;
  blockedSpecs: string[];
  criticalPath: boolean;
  impactScore: number; // 0-1, how much this blocks progress
  totalBlocked: number; // Total downstream specs blocked
}

class DependencyAnalyzer {
  analyzeDependencies(specs: Spec[]): DependencyGraph {
    // Build dependency graph
    // Identify cycles
    // Calculate critical path
    // Return analysis
  }

  getBlockedProgress(specId: string): number {
    // Calculate progress impact of blocked spec
  }

  getCriticalPath(specs: Spec[]): string[] {
    // Find longest dependency chain
    // Return critical path spec IDs
  }
}
```

### Statistics API

```typescript
interface SpecStatistics {
  overview: {
    total: number;
    byStatus: Record<string, number>;
    byType: Record<string, number>;
    byPriority: Record<string, number>;
  };
  progress: {
    overall: number;
    byEpic: Record<string, number>;
    byFeature: Record<string, number>;
    weighted: number;
  };
  velocity: {
    current: number;
    average: number;
    trend: string;
  };
  predictions: {
    estimatedCompletion: Date;
    confidence: number;
    remainingWork: number;
    criticalPath: string[];
  };
  dependencies: {
    totalBlocked: number;
    criticalBlocking: string[];
    cycles: string[][];
  };
}
```

### Calculation Algorithms

#### Weighted Average

```typescript
function calculateWeightedProgress(items: Array<{ value: number; weight: number }>): number {
  const weightedSum = items.reduce((sum, item) => sum + item.value * item.weight, 0);
  const totalWeight = items.reduce((sum, item) => sum + item.weight, 0);
  return totalWeight > 0 ? weightedSum / totalWeight : 0;
}
```

#### Moving Average

```typescript
function calculateMovingAverage(values: number[], window: number): number[] {
  return values.map((_, index) => {
    const start = Math.max(0, index - window + 1);
    const windowValues = values.slice(start, index + 1);
    return windowValues.reduce((a, b) => a + b, 0) / windowValues.length;
  });
}
```

### Dependencies

- **simple-statistics**: ^7.8.3 - Statistical calculations
- **date-fns**: ^2.30.0 - Date calculations
- **graphlib**: ^2.1.8 - Dependency graph analysis

## Risk Analysis

| Risk                             | Impact | Mitigation                        |
| -------------------------------- | ------ | --------------------------------- |
| Inaccurate progress calculations | High   | Comprehensive testing, validation |
| Performance with large datasets  | Medium | Caching, incremental updates      |
| Complex dependency cycles        | Medium | Cycle detection, clear warnings   |
| Misleading predictions           | High   | Confidence intervals, disclaimers |

## Success Metrics

- 100% accurate progress calculations
- < 100ms calculation for 1000 specs
- Velocity predictions within 20% accuracy
- Zero calculation errors in production
- 95% test coverage

## References

- [Agile Metrics Guide](https://www.agilealliance.org/agile101/agile-glossary/)
- [E13-F01 Spec Parser Service](../F01/spec.md)
- [E13 Epic Spec](../E13.spec.md)
