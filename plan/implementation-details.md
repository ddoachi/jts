# JTS Implementation Details

## Technical Architecture Details

### Project Structure
```
jts/
├── apps/
│   ├── presentation/                   # UI Layer
│   │   ├── web-app/                   # React PWA with Service Workers
│   │   └── mobile-app/                # React Native (optional)
│   ├── gateway/                       # API Gateway Layer
│   │   └── api-gateway/               # Kong/Express gateway
│   ├── business/                      # Business Logic Layer
│   │   ├── strategy-engine/           # DSL parser and executor
│   │   ├── risk-management/           # Risk controls and Kelly Criterion
│   │   ├── portfolio-tracker/         # P&L and position tracking
│   │   └── order-execution/           # Order routing and management
│   ├── integration/                   # Integration Services
│   │   ├── market-data-collector/     # Real-time and historical data
│   │   └── notification-service/      # PWA push notifications
│   ├── brokers/                       # Broker APIs
│   │   ├── creon-service/            # Windows FastAPI (Creon)
│   │   ├── kis-service/              # Linux Node.js (KIS)
│   │   ├── binance-service/          # Linux Node.js (Binance)
│   │   └── upbit-service/            # Linux Node.js (Upbit)
│   └── platform/                      # Platform Services
│       ├── monitoring-service/        # Prometheus/Grafana integration
│       └── configuration-service/     # Centralized config management
├── libs/
│   ├── shared/                        # Shared DTOs and utilities
│   │   ├── dto/                      # Common data transfer objects
│   │   ├── utils/                    # Helper functions
│   │   └── constants/                # System constants
│   ├── messaging/                     # Message broker integration
│   │   ├── kafka/                    # Kafka producer/consumer
│   │   ├── redis/                    # Redis client and caching
│   │   └── rate-limiter/             # Distributed rate limiting
│   └── data/                          # Data access layer
│       ├── postgres/                  # PostgreSQL client
│       ├── clickhouse/                # ClickHouse client
│       └── mongodb/                   # MongoDB client
└── infrastructure/
    ├── docker/                        # Docker configurations
    │   ├── linux/                    # Linux service containers
    │   └── windows/                  # Windows Creon container
    ├── kafka/                         # Kafka cluster setup
    ├── databases/                     # Database schemas and migrations
    └── kubernetes/                    # K8s manifests (optional)
```

## Interface Implementations

### Unified Broker Interface
```typescript
interface IBroker {
  // Market Data
  getRealtimeQuote(symbols: string[]): Observable<Quote>;
  getHistoricalCandles(symbol: string, period: Period): Promise<Candle[]>;
  getOrderbook(symbol: string): Promise<Orderbook>;
  
  // Trading
  placeOrder(order: Order): Promise<OrderResult>;
  cancelOrder(orderId: string): Promise<CancelResult>;
  getPositions(): Promise<Position[]>;
  getBalance(): Promise<Balance>;
  
  // Account Management
  getAccountInfo(): Promise<AccountInfo>;
  getRateLimitStatus(): RateLimitStatus;
}

class CreonBroker implements IBroker { /* Creon implementation */ }
class KISBroker implements IBroker { /* KIS implementation */ }
class BinanceBroker implements IBroker { /* Binance implementation */ }
```

### Common Endpoints Implementation
```typescript
// Both brokers implement these endpoints
POST /api/v1/market-data/quotes      // Get real-time quotes
POST /api/v1/market-data/candles     // Get historical candles
POST /api/v1/trading/orders          // Place order
DELETE /api/v1/trading/orders/:id    // Cancel order
GET /api/v1/account/positions        // Get positions
GET /api/v1/account/balance          // Get balance
```

### Rate Limiter Implementation
```typescript
interface BrokerApiRequest {
  requestId: string;
  correlationId: string;
  brokerType: "creon" | "kis" | "binance" | "upbit";
  apiMethod: string;
  params: Record<string, any>;
  priority: "high" | "medium" | "low";
  timestamp: number;
}

class BrokerRateLimiter {
  private requestQueue: PriorityQueue<BrokerApiRequest>;
  private requestCount: number = 0;
  private windowStart: number = Date.now();

  async processRequest(request: BrokerApiRequest): Promise<BrokerApiResponse> {
    // Add to priority queue
    await this.requestQueue.enqueue(request, request.priority);

    // Check and enforce rate limit
    await this.waitForRateLimit();

    // Execute API call
    return await this.executeBrokerApi(request);
  }

  private async waitForRateLimit(): Promise<void> {
    // Sliding window rate limiting algorithm
    // with exponential backoff for violations
  }
}
```

### Account Pool Implementation
```typescript
class BrokerAccountPool {
  private accounts: Map<string, IBroker> = new Map();
  
  // Add multiple KIS accounts
  addKISAccount(credentials: KISCredentials): void;
  
  // Add Creon account
  addCreonAccount(credentials: CreonCredentials): void;
  
  // Distribute symbols optimally
  distributeSymbols(symbols: string[]): void;
  
  // Get best account for order
  selectAccountForOrder(): IBroker;
}
```

### Smart Order Router Implementation
```typescript
class SmartOrderRouter {
  async routeOrder(order: Order): Promise<OrderResult> {
    // 1. Check which broker has the symbol
    const availableBrokers = this.getAvailableBrokers(order.symbol);
    
    // 2. Select best broker based on:
    //    - Current rate limit status
    //    - Account balance
    //    - Historical execution quality
    //    - Current positions
    const selectedBroker = this.selectOptimalBroker(availableBrokers, order);
    
    // 3. Execute order
    return await selectedBroker.placeOrder(order);
  }
}
```

## Database Schemas

### ClickHouse Schema
```sql
CREATE TABLE candles (
    timestamp DateTime64(3),
    symbol LowCardinality(String),
    broker LowCardinality(String),  -- Track data source
    open Float64,
    high Float64,
    low Float64,
    close Float64,
    volume UInt64,
    bid Float64,
    ask Float64
) ENGINE = MergeTree()
PARTITION BY toYYYYMM(timestamp)
ORDER BY (symbol, timestamp, broker);

-- Surge detection table
CREATE TABLE surge_events (
    timestamp DateTime64(3),
    symbol LowCardinality(String),
    surge_percent Float32,
    volume_ratio Float32,
    detection_latency_ms UInt32,
    broker LowCardinality(String)
) ENGINE = MergeTree()
ORDER BY (timestamp, symbol);
```

## DSL Implementation Examples

### Basic Strategy
```typescript
strategy("SMA_Crossover") {
  indicators {
    sma20 = SMA(period: 20)
    sma50 = SMA(period: 50)
  }

  entry.long {
    when (sma20 crosses above sma50) {
      buy(quantity: "5%", type: "market")
    }
  }

  exit.long {
    when (sma20 crosses below sma50) {
      sell(quantity: "all", type: "market")
    }
  }
}
```

### Multi-Timeframe Strategy
```typescript
strategy("MultiTimeframe_Momentum") {
  timeframes {
    daily = "1d"
    hourly = "1h"
  }

  indicators {
    on daily {
      trend = SMA(period: 50)
      momentum = MACD(fast: 12, slow: 26, signal: 9)
    }
    on hourly {
      rsi = RSI(period: 14)
    }
  }

  entry.long {
    when (
      daily.close > daily.trend AND
      daily.momentum.histogram > 0 AND
      hourly.rsi between [40, 60]
    ) {
      buy(quantity: calculate_kelly_criterion())
    }
  }

  risk_management {
    max_position_size = "20%"
    trailing_stop = "3%"
    daily_loss_limit = "5%"
  }
}
```

### Surge Detection Strategy
```typescript
strategy("UnifiedSurgeScanner") {
  sources {
    creon: symbols[0..600]      // First 600 symbols from Creon
    kis_account_1: symbols[601..1200]  // Next 600 from KIS Account 1
    kis_account_2: symbols[1201..1800] // Next 600 from KIS Account 2
  }
  
  surge_detection {
    when (
      price_change(5m) > 3% AND
      volume > avg_volume(20) * 2 AND
      spread < 0.5%
    ) {
      execute_immediately({
        broker: select_fastest_broker(),
        size: calculate_kelly_criterion()
      })
    }
  }
}
```

## PWA Service Worker Implementation

```typescript
// Service Worker Implementation
self.addEventListener("push", (event) => {
  const data = event.data.json();
  const options = {
    body: data.message,
    icon: "/icons/jts-icon-192.png",
    badge: "/icons/jts-badge-72.png",
    data: {
      correlationId: data.correlationId,
      tradeType: data.tradeType,
      url: data.url,
    },
    actions: [
      { action: "view-trade", title: "View Trade" },
      { action: "close", title: "Close" },
    ],
    requireInteraction: data.priority === "high",
    vibrate: data.priority === "high" ? [200, 100, 200] : [100],
  };

  event.waitUntil(self.registration.showNotification(data.title, options));
});
```

## Dashboard Interface Implementation

```typescript
interface UnifiedDashboard {
  // Real-time metrics
  totalSymbolsCovered: number;        // e.g., 1,800
  activeBrokers: BrokerStatus[];      // Creon + KIS accounts
  dataLatency: Map<string, number>;   // Per broker latency
  
  // Trading metrics
  surgesDetected: number;              // Today's surge count
  positionsOpen: Position[];           // Across all accounts
  orderSuccessRate: number;            // Execution success %
  
  // Performance
  dailyPnL: number;                    // Aggregated P&L
  winRate: number;                     // Success rate
  sharpeRatio: number;                 // Risk-adjusted returns
}
```

## Kafka Topics Configuration

```yaml
# Market Data Topics
market-data.krx.ticks       # Real-time tick data (1 day retention)
market-data.krx.candles     # OHLCV candles (7 day retention)
market-data.crypto.ticks    # Crypto tick data (1 day retention)
market-data.crypto.candles  # Crypto OHLCV (7 day retention)

# Trading Signal Topics
signals.entry.buy           # Buy signals (30 day retention)
signals.entry.sell          # Sell signals (30 day retention)
signals.exit.all           # Exit all positions (30 day retention)

# Order Management Topics
orders.pending             # Pending orders (1 day retention)
orders.executions         # Executed orders (30 day retention)
orders.failures           # Failed orders (7 day retention)

# Portfolio & Risk Topics
portfolio.updates         # Portfolio changes (30 day retention)
risk.alerts              # Risk warnings (7 day retention)
risk.metrics             # Risk metrics (1 day retention)

# System Topics
system.health            # Service health (3 day retention)
system.errors           # System errors (7 day retention)
system.metrics          # Performance metrics (1 day retention)

# Backtesting Topics
backtest.requests       # Backtest jobs (1 day retention)
backtest.results       # Backtest results (30 day retention)
```

## Account Distribution Configuration

```yaml
Account Distribution:
  KIS_Account_1: 
    symbols: 600 (KOSPI large-cap)
    focus: Blue chips, high liquidity
    
  KIS_Account_2:
    symbols: 600 (KOSDAQ tech)
    focus: Tech stocks, high volatility
    
  KIS_Account_3:
    symbols: 600 (Small-cap momentum)
    focus: Penny stocks, new listings
    
  KIS_Account_4: (Optional)
    symbols: 600 (Sector rotation)
    focus: Thematic plays
    
  KIS_Account_5: (Optional)
    symbols: 600 (Reserve/Backup)
    focus: Failover, overflow handling
```

## Hardware Specifications

### Linux Server (Primary)
- CPU: Intel i7-13700K (16 cores/24 threads)
- RAM: 128GB DDR5
- Storage: 1TB NVMe (OS) + 4TB Samsung 990 PRO (Data)
- OS: Ubuntu 22.04 LTS
- Services: All business logic, Kafka, Redis, databases

### Windows Server (Creon)
- CPU: AMD Ryzen 5600 (6 cores/12 threads)
- RAM: 32GB DDR4
- Storage: 1TB NVMe
- OS: Windows 11 Pro
- Services: Creon API FastAPI wrapper only

### NAS (Backup)
- Model: Synology DS1821+
- RAM: 32GB
- Available: 16.4TB
- Purpose: Backups, historical data archive

## Rate Limit Specifications

| Broker | Rate Limit | Window | Strategy |
|--------|------------|--------|----------|
| Creon | 60 requests | 15 seconds | Queue with sliding window |
| KIS | 20 requests/sec | Per account | Multiple accounts for scaling |
| Binance | 1200 requests | 1 minute | Weight-based limiting |
| Upbit | 10 requests | 1 second | Simple rate limiting |

## Redis Cache Configuration

- **Price Caching**: Real-time prices with 5-minute TTL
- **Session Management**: User sessions and JWT tokens
- **Distributed Locks**: Critical section synchronization
  - Order placement locks
  - Portfolio update locks
  - Strategy execution locks
- **Rate Limiter State**: Per-broker request counts and windows
  - Creon: 15-second sliding window
  - KIS: 1-second sliding window
  - Binance: 1-minute sliding window
- **Circuit Breaker State**: Service failure tracking
- **Strategy State**: Active strategy configurations
- **WebSocket Connections**: Connection pool management

## Priority Queue Strategy

- **High Priority**: Order executions, risk checks
- **Medium Priority**: Real-time market data
- **Low Priority**: Historical data, account info

## Communication Protocols

| Communication Type | Protocol | Use Case | JTS Example |
|--------------------|----------|----------|-------------|
| Real-time sync request | gRPC | Low latency, type safety | Strategy Engine → Risk Management |
| Simple REST API | HTTP | Developer convenience | Web App → API Gateway |
| Event-based async | Kafka | Scalability, fault tolerance | Order Execution → Portfolio Tracker |
| External API | HTTP | Standard compatibility | KIS, Binance, Upbit APIs |

## Layer Communication Rules

- **Vertical Communication**: Upper layers can only call lower layers (Presentation → Gateway → Business → Integration → Brokers → Data)
- **Horizontal Communication**: Services within the same layer communicate only through the Messaging Layer (Kafka/Redis)
- **Synchronous Calls**: HTTP/gRPC for real-time requests requiring immediate response
- **Asynchronous Events**: Kafka for event-driven communication and data streaming