# JTS Implementation Roadmap

## Phase-Based Implementation Strategy

### Phase 1: Foundation (Week 1-2)
**Goal**: Core infrastructure and basic trading capability with Creon

#### Infrastructure Setup
```bash
# 1. Initialize Nx workspace
npx create-nx-workspace@latest jts --preset=nest --packageManager=npm

# 2. Add Next.js for web app
npm install --save-dev @nx/next
nx g @nx/next:app presentation/web-app

# 3. Add shared libraries
nx g @nx/workspace:lib shared/dto
nx g @nx/workspace:lib shared/interfaces
nx g @nx/workspace:lib shared/utils
nx g @nx/workspace:lib infrastructure/messaging
nx g @nx/workspace:lib infrastructure/database
```

#### Services to Implement
1. **Creon Service** (Windows - Python FastAPI)
   - Basic API wrapper for Creon COM objects
   - Rate limiter (60 requests/15 seconds)
   - REST endpoints for market data and orders

2. **Market Data Collector** (Linux - NestJS)
   - Connect to Creon service via HTTP
   - Store data in ClickHouse
   - Publish to Kafka topics

3. **Basic Strategy Engine** (Linux - NestJS)
   - Simple moving average strategy
   - Subscribe to market data from Kafka
   - Generate basic trading signals

4. **Order Execution** (Linux - NestJS)
   - Receive signals from Kafka
   - Send orders to Creon service
   - Basic order management

#### Database Setup
```sql
-- PostgreSQL: Core tables
CREATE TABLE strategies (
    id UUID PRIMARY KEY,
    name VARCHAR(255),
    dsl_code TEXT,
    status VARCHAR(50),
    created_at TIMESTAMP
);

CREATE TABLE orders (
    id UUID PRIMARY KEY,
    strategy_id UUID,
    symbol VARCHAR(50),
    side VARCHAR(10),
    quantity DECIMAL,
    price DECIMAL,
    status VARCHAR(50),
    broker VARCHAR(50),
    created_at TIMESTAMP
);

-- ClickHouse: Time-series data
CREATE TABLE market_data (
    timestamp DateTime64(3),
    symbol LowCardinality(String),
    open Float64,
    high Float64,
    low Float64,
    close Float64,
    volume UInt64
) ENGINE = MergeTree()
ORDER BY (symbol, timestamp);
```

### Phase 2: Risk & Portfolio (Week 3-4)
**Goal**: Add risk management and portfolio tracking

#### New Services
1. **Risk Management Service**
   - Position sizing with Kelly Criterion
   - Drawdown monitoring
   - Risk limit enforcement

2. **Portfolio Tracker**
   - Real-time P&L calculation
   - Position aggregation
   - Performance metrics

3. **API Gateway**
   - JWT authentication
   - Rate limiting
   - Request routing

#### Integration Points
```typescript
// Risk checks before order execution
class OrderExecutionService {
  async processSignal(signal: TradingSignal) {
    // 1. Risk check via gRPC
    const riskApproval = await this.riskService.checkRisk(signal);
    
    // 2. Execute if approved
    if (riskApproval.approved) {
      await this.executeTrade(signal);
    }
  }
}
```

### Phase 3: Multi-Broker Support (Week 5-6)
**Goal**: Add KIS, Binance, Upbit integrations

#### Broker Services
```bash
# Generate broker services
nx g @nestjs/schematics:app brokers/kis-service
nx g @nestjs/schematics:app brokers/binance-service
nx g @nestjs/schematics:app brokers/upbit-service

# Create unified broker interface
nx g @nx/workspace:lib brokers/common
```

#### Account Pool Management
```typescript
// KIS account distribution for 1800 symbols
const accountConfig = {
  kis_account_1: { symbols: 600, focus: 'KOSPI large-cap' },
  kis_account_2: { symbols: 600, focus: 'KOSDAQ tech' },
  kis_account_3: { symbols: 600, focus: 'Small-cap momentum' }
};
```

### Phase 4: Advanced Features (Week 7-8)
**Goal**: DSL engine, backtesting, notifications

#### Components
1. **Advanced Strategy Engine**
   - Full DSL parser and compiler
   - Multi-timeframe support
   - Complex indicator library

2. **Backtesting Engine**
   - Historical simulation
   - Performance analytics
   - Strategy optimization

3. **Notification Service**
   - PWA push notifications
   - Email/SMS alerts
   - Trading summaries

### Phase 5: Production Readiness (Week 9-10)
**Goal**: Monitoring, optimization, deployment

#### Production Setup
1. **Monitoring Stack**
   ```yaml
   # docker-compose.monitoring.yml
   services:
     prometheus:
       image: prom/prometheus
     grafana:
       image: grafana/grafana
     alertmanager:
       image: prom/alertmanager
   ```

2. **Performance Optimization**
   - Database query optimization
   - Caching strategy implementation
   - Service auto-scaling

3. **Security Hardening**
   - SSL/TLS everywhere
   - API key rotation
   - Audit logging

## Nx Workspace Configuration

### nx.json Configuration
```json
{
  "tasksRunnerOptions": {
    "default": {
      "runner": "nx/tasks-runners/default",
      "options": {
        "cacheableOperations": ["build", "lint", "test", "e2e"],
        "parallel": 4
      }
    }
  },
  "targetDefaults": {
    "build": {
      "dependsOn": ["^build"],
      "inputs": ["production", "^production"]
    },
    "test": {
      "inputs": ["default", "^production", "{workspaceRoot}/jest.preset.js"]
    }
  },
  "generators": {
    "@nx/nest": {
      "application": {
        "linter": "eslint",
        "unitTestRunner": "jest"
      }
    }
  }
}
```

### Project Tags and Constraints
```json
{
  "projects": {
    "strategy-engine": {
      "tags": ["scope:business", "type:service", "domain:trading"]
    },
    "creon-service": {
      "tags": ["scope:brokers", "type:service", "platform:windows"]
    },
    "shared-dto": {
      "tags": ["scope:shared", "type:lib"]
    }
  }
}
```

### ESLint Module Boundaries
```json
{
  "rules": {
    "@nx/enforce-module-boundaries": [
      "error",
      {
        "depConstraints": [
          {
            "sourceTag": "scope:business",
            "onlyDependOnLibsWithTags": ["scope:shared", "scope:domain", "scope:infrastructure"]
          },
          {
            "sourceTag": "scope:brokers",
            "onlyDependOnLibsWithTags": ["scope:shared", "scope:infrastructure"]
          },
          {
            "sourceTag": "scope:shared",
            "onlyDependOnLibsWithTags": ["scope:shared"]
          }
        ]
      }
    ]
  }
}
```

## Development Commands

### Service Development
```bash
# Start specific service
nx serve strategy-engine

# Run affected tests
nx affected:test --base=main

# Build for production
nx build strategy-engine --configuration=production

# Generate new feature
nx g @nx/nest:resource trading --project=strategy-engine

# Check module boundaries
nx lint strategy-engine
```

### Multi-Platform Development
```bash
# Linux development (exclude Windows services)
npm run serve:linux

# Windows development (Creon only)
npm run serve:windows

# Full system (requires both platforms)
npm run serve:all
```

## Testing Strategy

### Unit Testing
```typescript
// libs/shared/utils/src/lib/math.utils.spec.ts
describe('MathUtils', () => {
  describe('calculateSMA', () => {
    it('should calculate simple moving average', () => {
      const prices = [100, 102, 101, 103, 105];
      const sma = MathUtils.calculateSMA(prices, 3);
      expect(sma).toEqual([101, 102, 103]);
    });
  });
});
```

### Integration Testing
```typescript
// apps/business/order-execution/src/app/order.service.integration.spec.ts
describe('OrderService Integration', () => {
  let kafkaProducer: KafkaProducer;
  let orderService: OrderService;
  
  beforeEach(async () => {
    const module = await Test.createTestingModule({
      imports: [KafkaModule, DatabaseModule],
      providers: [OrderService]
    }).compile();
    
    orderService = module.get<OrderService>(OrderService);
    kafkaProducer = module.get<KafkaProducer>(KafkaProducer);
  });
  
  it('should publish order to Kafka', async () => {
    const order = { symbol: 'AAPL', quantity: 100, side: 'buy' };
    await orderService.placeOrder(order);
    
    expect(kafkaProducer.send).toHaveBeenCalledWith({
      topic: 'orders.pending',
      value: expect.objectContaining(order)
    });
  });
});
```

### E2E Testing
```typescript
// apps/business/strategy-engine/src/app/strategy.e2e.spec.ts
describe('Strategy Engine E2E', () => {
  it('should generate signal on price cross', async () => {
    // 1. Create strategy
    const strategy = await createStrategy('SMA_Cross');
    
    // 2. Send market data
    await sendMarketData({ symbol: 'AAPL', price: 150 });
    
    // 3. Verify signal generation
    const signals = await waitForSignals();
    expect(signals).toContainEqual({
      type: 'BUY',
      symbol: 'AAPL'
    });
  });
});
```

## CI/CD Pipeline

### GitHub Actions Workflow
```yaml
name: CI/CD Pipeline

on:
  push:
    branches: [main, develop]
  pull_request:

jobs:
  affected:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
        with:
          fetch-depth: 0
      
      - name: Setup Node
        uses: actions/setup-node@v3
        with:
          node-version: 20
          cache: npm
      
      - name: Install dependencies
        run: npm ci
      
      - name: Run affected tests
        run: npx nx affected:test --base=origin/main
      
      - name: Build affected
        run: npx nx affected:build --base=origin/main
      
      - name: Deploy (if main branch)
        if: github.ref == 'refs/heads/main'
        run: |
          npx nx affected --target=deploy --base=origin/main~1
```

## Deployment Strategy

### Docker Deployment
```yaml
# docker-compose.production.yml
version: '3.8'

services:
  strategy-engine:
    image: jts/strategy-engine:${VERSION}
    environment:
      - NODE_ENV=production
      - KAFKA_BROKERS=kafka:9092
    deploy:
      replicas: 2
      resources:
        limits:
          memory: 2G
          cpus: '1.0'
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
```

### Kubernetes Deployment (Future)
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: strategy-engine
spec:
  replicas: 3
  selector:
    matchLabels:
      app: strategy-engine
  template:
    metadata:
      labels:
        app: strategy-engine
    spec:
      containers:
      - name: strategy-engine
        image: jts/strategy-engine:latest
        resources:
          requests:
            memory: "1Gi"
            cpu: "500m"
          limits:
            memory: "2Gi"
            cpu: "1"
```

## Success Metrics

### Technical Metrics
- API response time < 100ms (p95)
- Order execution latency < 500ms
- System availability > 99.9%
- Test coverage > 80%

### Business Metrics
- Daily trade execution success rate > 95%
- Strategy backtest accuracy > 90%
- Risk limit breach incidents < 1/month
- Portfolio tracking accuracy > 99.9%

## Risk Mitigation

### Technical Risks
1. **Broker API failures**: Circuit breakers, fallback strategies
2. **Data inconsistency**: Event sourcing, audit logs
3. **Performance degradation**: Auto-scaling, caching
4. **Security breaches**: Regular audits, penetration testing

### Operational Risks
1. **Service outages**: Multi-region deployment, backups
2. **Data loss**: Regular backups, disaster recovery plan
3. **Compliance issues**: Audit trails, regulatory reporting

This roadmap provides a structured approach to implementing the JTS platform, ensuring each phase builds upon the previous one while maintaining system stability and scalability.