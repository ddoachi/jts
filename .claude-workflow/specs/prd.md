# JTS Automated Trading System - Product Requirements Document

## Executive Summary

JTS (자동매매시스템) is a comprehensive automated trading platform designed for Korean retail investors. The system integrates multiple brokers (Creon, KIS, Binance, Upbit) through a unified microservices architecture, enabling systematic trading strategies across Korean equities and global cryptocurrency markets.

## System Overview

### Architecture Foundation

The system follows a layered microservices architecture with clear separation of concerns:

- **Presentation Layer**: PWA web app with push notifications and mobile interfaces
- **Gateway Layer**: API routing, authentication, and rate limiting
- **Business Layer**: Core trading logic (Strategy Engine, Risk Management, Order Execution, Portfolio Tracker)
- **Integration Layer**: Market data collection and notification services
- **Messaging Layer**: Kafka event streaming and Redis caching/distributed locks
- **Brokers Layer**: Exchange-specific API integrations with individual rate limiters
- **Data Layer**: PostgreSQL (transactions), ClickHouse (time-series), MongoDB (configs), File Storage

### Communication Architecture

#### Layer Communication Rules

- **Vertical Communication**: Upper layers can only call lower layers (Presentation → Gateway → Business → Integration → Brokers → Data)
- **Horizontal Communication**: Services within the same layer communicate only through the Messaging Layer (Kafka/Redis)
- **Synchronous Calls**: HTTP/gRPC for real-time requests requiring immediate response
- **Asynchronous Events**: Kafka for event-driven communication and data streaming

#### Protocol Selection Criteria

| Communication Type     | Protocol | Use Case                     | JTS Example                         |
| ---------------------- | -------- | ---------------------------- | ----------------------------------- |
| Real-time sync request | gRPC     | Low latency, type safety     | Strategy Engine → Risk Management   |
| Simple REST API        | HTTP     | Developer convenience        | Web App → API Gateway               |
| Event-based async      | Kafka    | Scalability, fault tolerance | Order Execution → Portfolio Tracker |
| External API           | HTTP     | Standard compatibility       | KIS, Binance, Upbit APIs            |

### Service Architecture Diagram

```
┌──────────────────────────────────────────────────────────────────┐
│                    Presentation Layer                            │
│                 (PWA with Service Workers + Mobile)              │
└──────────────────────────────────────────────────────────────────┘
                               │
┌──────────────────────────────────────────────────────────────────┐
│                      Gateway Layer                               │
│              (API Gateway with Auth & Rate Limiting)             │
└──────────────────────────────────────────────────────────────────┘
                               │
┌──────────────────────────────────────────────────────────────────┐
│                    Business Layer                                │
├────────────────┬────────────────┬────────────────┬───────────────┤
│    Strategy    │   Risk         │    Portfolio   │    Order      │
│    Engine      │   Management   │    Tracker     │    Execution  │
└────────────────┴────────────────┴────────────────┴───────────────┘
                               │
┌──────────────────────────────────────────────────────────────────┐
│                   Integration Layer                              │
├───────────────────────────────┬──────────────────────────────────┤
│     Market Data Collector     │     Notification Service         │
└───────────────────────────────┴──────────────────────────────────┘
                               │
┌──────────────────────────────────────────────────────────────────┐
│                    Messaging Layer                               │
├───────────────────────────────┬──────────────────────────────────┤
│      Kafka (Event Stream)     │     Redis (Cache/Lock/Session)   │
└───────────────────────────────┴──────────────────────────────────┘
                               │
┌──────────────────────────────────────────────────────────────────┐
│                     Brokers Layer                                │
├─────────────┬─────────────┬─────────────┬───────────────────────┤
│Creon Service│ KIS Service │Binance Serv.│    Upbit Service      │
│ (Windows)   │  (Linux)    │  (Linux)    │     (Linux)           │
│Rate: 15s/60 │Rate: 1s/20  │Rate: 1m/1200│   Rate: 1s/10         │
└─────────────┴─────────────┴─────────────┴───────────────────────┘
                               │
┌──────────────────────────────────────────────────────────────────┐
│                      Data Layer                                  │
├──────────────┬──────────────┬──────────────┬────────────────────┤
│ PostgreSQL   │ ClickHouse   │   MongoDB    │   File Storage     │
│(Transactions)│(Time Series) │(Configuration)│  (Logs/Backups)   │
└──────────────┴──────────────┴──────────────┴────────────────────┘
```

### Multi-Broker Strategy

The system leverages both Creon and multiple KIS accounts to achieve comprehensive market coverage and optimal execution:

#### Broker Capabilities Comparison

| Feature | Creon | KIS | Combined Advantage |
|---------|-------|-----|-------------------|
| **Rate Limit** | 60 req/15s | 20 req/s per account | Massive parallel capacity |
| **Historical Data** | Excellent | Good | Redundant data sources |
| **Real-time Data** | COM-based | REST/WebSocket | Multiple channels |
| **Platform** | Windows only | Cross-platform | Distributed architecture |
| **Multi-Account** | Single | Multiple supported | Scale with N accounts |
| **API Type** | COM objects | REST API | Best of both worlds |

#### Coverage Strategy
- **Creon**: Primary for top 600 liquid stocks (KOSPI200 + blue chips)
- **KIS Account 1**: Mid-cap stocks (symbols 601-1200)
- **KIS Account 2**: Small-cap momentum stocks (symbols 1201-1800)
- **KIS Account 3+**: Overflow and specialized strategies

#### Execution Strategy
- **Data Collection**: Parallel from all sources for redundancy
- **Order Routing**: Intelligent selection based on:
  - Current rate limit availability
  - Account balance and positions
  - Historical execution quality
  - Broker-specific advantages

### Platform Strategy

#### Hardware Distribution

- **Linux Server (Primary)**: All business logic, messaging, and data services

  - CPU: Intel i7-13700K (16 cores/24 threads)
  - RAM: 128GB DDR5
  - Storage: 1TB NVMe (OS) + 4TB Samsung 990 PRO (Data)
  - OS: Ubuntu 22.04 LTS
  - Services: Business, Integration, Messaging, Data layers

- **Windows 11 Pro (Creon Only)**: Dedicated Creon API wrapper

  - CPU: AMD Ryzen 5600 (6 cores/12 threads)
  - RAM: 32GB DDR4
  - Storage: 1TB NVMe
  - Service: FastAPI wrapper for Creon COM objects
  - Rate Limit: 15 seconds/60 requests

- **Synology NAS (Backup)**: Data archiving and disaster recovery
  - Model: DS1821+
  - RAM: 32GB
  - Available: 16.4TB
  - Purpose: Automated backups, historical data, logs

#### Cross-Platform Communication

- **Linux ↔ Windows**: HTTP REST API for Creon integration
- **Service Discovery**: Consul or fixed IP configuration
- **Network**: Bridge network for Docker containers
- **Failover**: Circuit breaker pattern for Windows service failures

## Broker Rate Limiter Architecture

### Rate Limiting Strategy

Each broker service implements its own rate limiter with broker-specific constraints:

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Market Data   │    │ Strategy Engine │    │ Order Execution │
│   Collector     │    │                 │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
                    ┌─────────────────┐
                    │     Kafka       │
                    │ (Request Queue) │
                    └─────────────────┘
                                 │
         ┌───────────────────────┼───────────────────────┐
         │                       │                       │
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│  Creon Service  │    │   KIS Service   │    │ Binance Service │
│ ┌─────────────┐ │    │ ┌─────────────┐ │    │ ┌─────────────┐ │
│ │Rate Limiter │ │    │ │Rate Limiter │ │    │ │Rate Limiter │ │
│ │15초/60건    │ │    │ │1초/20건     │ │    │ │1분/1200건   │ │
│ └─────────────┘ │    │ └─────────────┘ │    │ └─────────────┘ │
└─────────────────┘    └─────────────────┘    └─────────────────┘
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

### Priority Queue Strategy

- **High Priority**: Order executions, risk checks
- **Medium Priority**: Real-time market data
- **Low Priority**: Historical data, account info

## Phase 1: Foundation & Unified Broker Architecture (Weeks 1-6)

### 1.0 Monorepo Project Structure & Unified Broker Interface (Week 1)

**Objective**: Establish Nx-based monorepo with unified broker interface for parallel development

**Deliverables**:

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

**Unified Broker Interface**:

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

**Acceptance Criteria**:

- Nx workspace with unified broker interface
- Parallel development structure for Creon & KIS
- Docker compose for multi-platform services
- Shared DTOs and normalization layer

### 1.1 Parallel Broker Implementation (Weeks 1-2)

**Objective**: Develop Creon and KIS brokers simultaneously with common interface

#### Creon Service (Windows)
- **Platform**: Windows 11 FastAPI server
- **Features**:
  - COM interface integration
  - Rate limiter (15 seconds/60 requests)
  - Real-time data via StockCur
  - Historical data via CpSysDib
  - Order execution via CpTrade

#### KIS Service (Linux)
- **Platform**: Linux Node.js/TypeScript
- **Features**:
  - REST API integration
  - Multi-account support (N accounts × 20 req/sec)
  - WebSocket for real-time data
  - OAuth2 authentication
  - Batch quote requests (30 symbols/call)

**Common Endpoints**:
```typescript
// Both brokers implement these endpoints
POST /api/v1/market-data/quotes      // Get real-time quotes
POST /api/v1/market-data/candles     // Get historical candles
POST /api/v1/trading/orders          // Place order
DELETE /api/v1/trading/orders/:id    // Cancel order
GET /api/v1/account/positions        // Get positions
GET /api/v1/account/balance          // Get balance
```

### 1.2 Multi-Account Architecture (Week 2)

**Objective**: Implement account pool management for scalable data collection

**Features**:

- Account pool manager for multiple KIS accounts
- Symbol distribution across accounts
- Load balancing for order execution
- Failover and health monitoring
- Parallel data collection (600 × N symbols)

**Implementation**:

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

### 1.3 Unified Market Data Collector (Week 3)

**Objective**: Aggregate real-time data from multiple brokers and accounts

**Components**:

- Parallel data collection from Creon + multiple KIS accounts
- Data normalization and deduplication
- ClickHouse time-series storage
- Redis cache for surge detection

**Data Schema**:

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

### 1.4 Unified Order Execution (Week 4)

**Objective**: Implement intelligent order routing across multiple brokers/accounts

**Features**:

- Smart order routing (best execution venue)
- Multi-account order distribution
- Order status synchronization
- Position aggregation across accounts
- Transaction reconciliation

**Order Routing Logic**:

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

**Message Flow**:

```
Strategy Engine → Smart Order Router → [Creon | KIS Account 1 | KIS Account 2] → Exchange
                         ↓
                   Kafka (Order Events)
```

### 1.5 DSL Strategy Engine with Surge Detection (Week 5)

**Objective**: Implement domain-specific language for strategy definition

**DSL Syntax Examples**:

```typescript
// Basic Strategy
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

// Advanced Multi-Timeframe Strategy
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

**Components**:

- **DSL Parser**: ANTLR4 or custom recursive descent parser
- **Compiler**: Transpiles DSL to TypeScript/JavaScript
- **Surge Detector**: Real-time momentum scanner across all symbols
- **Rule Engine**: Event-driven evaluation with sub-second latency
- **State Manager**: Maintains strategy state in Redis
- **Signal Generator**: Produces trading signals for immediate execution
- **Backtesting Engine**: Historical validation with multi-broker data

**Surge Detection Implementation**:

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

### 1.6 Monitoring Dashboard & System Integration (Week 6)

**Objective**: Implement unified monitoring and system integration

**Multi-Broker Dashboard**:

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

**System Integration Features**:

- Unified API gateway for all brokers
- Centralized authentication and authorization
- Aggregated rate limit management
- Cross-broker position reconciliation
- Real-time health monitoring
- Alert system for critical events

**PWA Push Notification System**:

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

**Notification Types**:

- **Trade Execution**: Real-time order fills
- **Risk Alerts**: Portfolio risk warnings
- **System Errors**: Critical system failures
- **Daily Summary**: End-of-day performance report

## Phase 2: Advanced Trading Features & Optimization (Weeks 7-10)

### 2.1 PWA Dashboard with Multi-Account View (Week 7-8)

**Objective**: Build real-time trading dashboard

**Core Components**:

- **Multi-Broker Overview**: Unified view of all brokers/accounts
- **Surge Monitor**: Real-time surge detection across 1,800+ symbols
- **Account Manager**: Individual account performance and health
- **Position Aggregator**: Combined positions across all accounts
- **Execution Analytics**: Order routing effectiveness
- **Heat Map**: Market-wide momentum visualization

**Technology Stack**:

- React with TypeScript
- WebSocket for real-time updates
- Service Worker for offline support
- Push notifications

### 2.2 Advanced Risk Management (Week 9)

**Objective**: Implement multi-account risk controls and position sizing

**Features**:

- **Per-Account Risk Limits**:
  - Maximum positions per account
  - Account-level exposure limits
  - Daily loss limits per account
  
- **Cross-Account Risk Management**:
  - Total exposure across all accounts
  - Symbol concentration limits
  - Correlation risk monitoring
  
- **Dynamic Position Sizing**:
  - Kelly Criterion with multi-account adjustment
  - Volatility-based sizing
  - Account balance consideration

### 2.3 Performance Analytics Service (Week 10)

**Objective**: Track and analyze performance across multiple brokers/accounts

**Features**:

- **Aggregated Metrics**:
  - Combined P&L across all accounts
  - Broker-specific performance comparison
  - Strategy effectiveness by market condition
  
- **Surge Trading Analytics**:
  - Surge detection accuracy
  - Entry/exit timing analysis
  - Optimal holding period determination
  
- **Account Optimization**:
  - Symbol allocation effectiveness
  - API utilization rates
  - Execution quality by broker

## Phase 3: Broker Expansion & Optimization (Weeks 11-14)

### 3.1 Additional KIS Accounts & Scaling (Week 11)

**Objective**: Scale up to 3-5 KIS accounts for complete market coverage

**Scaling Strategy**:

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

**Implementation**:

- Automated account provisioning
- Dynamic symbol reallocation
- Load balancing optimization
- Account health monitoring
- Automatic failover handling

### 3.2 Binance Service Implementation (Week 12)

**Objective**: Integrate Binance cryptocurrency exchange

**Features**:

- WebSocket market data streaming
- REST API for trading
- Rate limiter (1 minute/1200 requests)
- USDT/BTC pairs support

### 3.3 Upbit Service Implementation (Week 13)

**Objective**: Integrate Korean cryptocurrency exchange

**Features**:

- WebSocket real-time data
- KRW trading pairs
- Korean regulatory compliance
- Tax reporting support

### 3.4 Broker Optimization & Fine-tuning (Week 14)

**Objective**: Optimize multi-broker system for maximum performance

**Features**:

- **Latency Optimization**:
  - Connection pooling per broker
  - Request batching strategies
  - Cache optimization
  
- **Execution Quality**:
  - Broker selection algorithms
  - Slippage analysis
  - Fill rate optimization
  
- **System Resilience**:
  - Automated failover
  - Circuit breakers
  - Self-healing mechanisms

## Phase 4: Machine Learning & Advanced Strategies (Weeks 15-18)

### 4.1 Multi-Broker Backtesting Framework (Week 15-16)

**Objective**: Historical testing with multi-broker data sources

**Features**:

- **Data Integration**:
  - Combine historical data from Creon and KIS
  - Handle data discrepancies
  - Multi-timeframe analysis
  
- **Realistic Simulation**:
  - Multi-account constraints
  - Actual rate limits simulation
  - Broker-specific latencies
  - Realistic slippage by broker
  
- **Optimization**:
  - Surge threshold tuning
  - Holding period optimization
  - Position sizing calibration

### 4.2 ML-Enhanced Surge Detection (Week 17)

**Objective**: Improve surge detection with machine learning

**Features**:

- **Pattern Recognition**:
  - Historical surge pattern analysis
  - Feature engineering for surge prediction
  - Real-time ML inference
  
- **Predictive Models**:
  - Surge magnitude prediction
  - Optimal exit timing
  - False positive filtering
  
- **Adaptive Strategies**:
  - Dynamic threshold adjustment
  - Market regime detection
  - Self-optimizing parameters

### 4.3 Production Monitoring & Alerting (Week 18)

**Objective**: Comprehensive system monitoring

**Components**:

- **Multi-Broker Monitoring**:
  - Per-broker/account metrics
  - API usage tracking
  - Latency monitoring by endpoint
  
- **Trading Analytics**:
  - Surge detection effectiveness
  - Execution quality metrics
  - P&L attribution by account
  
- **System Health**:
  - Broker connection status
  - Rate limit utilization
  - Data quality monitoring
  
- **Alerting Rules**:
  - Account disconnection
  - Rate limit approaching
  - Unusual surge patterns
  - Risk limit breaches

## Phase 5: Production Readiness (Weeks 19-20)

### 5.1 Performance Optimization

**Objectives**:

- Database query optimization
- Caching strategy refinement
- Network latency reduction
- Memory usage optimization

### 5.2 Security Hardening

**Objectives**:

- API authentication enhancement
- Encryption at rest and in transit
- Audit logging
- Penetration testing

### 5.3 Deployment & Documentation

**Objectives**:

- Production deployment scripts
- Disaster recovery procedures
- User documentation
- API documentation

## Technical Specifications

### Infrastructure Requirements

**Linux Server (Primary)**:

- CPU: Intel i7-13700K (16 cores/24 threads)
- RAM: 128GB DDR5
- Storage: 1TB NVMe (OS) + 4TB Samsung 990 PRO (Data)
- OS: Ubuntu 22.04 LTS
- Services: All business logic, Kafka, Redis, databases

**Windows Server (Creon)**:

- CPU: AMD Ryzen 5600 (6 cores/12 threads)
- RAM: 32GB DDR4
- Storage: 1TB NVMe
- OS: Windows 11 Pro
- Services: Creon API FastAPI wrapper only

**NAS (Backup)**:

- Model: Synology DS1821+
- RAM: 32GB
- Available: 16.4TB
- Purpose: Backups, historical data archive

### Message Queue Configuration

**Kafka Topics**:

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

**Redis Usage**:

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

### Database Schema

**PostgreSQL (Transactions)**:

- Orders table
- Accounts table
- Positions table
- Strategies table

**ClickHouse (Time Series)**:

- Candles table (partitioned by month)
- Ticks table (7-day retention)
- Backtesting results

**MongoDB (Configuration)**:

- Strategy definitions (DSL)
- User preferences
- System configuration

## Success Criteria

### Phase 1 Completion Metrics

- Unified broker interface supporting Creon + multiple KIS accounts
- Parallel data collection from 1,800+ symbols
- Surge detection latency <100ms across all symbols
- Order execution <500ms through optimal broker selection
- Multi-account management with automatic failover
- 95% test coverage for core components

### Overall Project Success Metrics

- **Data Coverage**: Monitor 1,800+ symbols simultaneously
- **API Utilization**: 80-90% of available rate limits
- **Surge Detection**: 20-50 opportunities identified daily
- **Execution Speed**: <2 seconds from surge to order placement
- **System Reliability**: 99.9% uptime during market hours
- **Trading Performance**:
  - Win rate: 60-70% on momentum trades
  - Average profit per trade: 1-3%
  - Daily trading volume: 10-30 trades
  - Risk/Reward ratio: 1:2 or better
- **Scalability**: Support for 5+ broker accounts
- **Zero critical security vulnerabilities**

## Risk Mitigation

### Technical Risks

- **Creon API limitations**: Implement intelligent request queuing and caching
- **Windows server stability**: Automated health checks and restart procedures
- **Network latency**: Colocate critical services, use connection pooling
- **Data consistency**: Event sourcing pattern with replay capability

### Operational Risks

- **Hardware failure**: Automated backups to NAS, quick recovery procedures
- **Exchange API changes**: Automated API documentation monitoring
- **Regulatory compliance**: Audit trail for all trades, tax reporting features

## Development Methodology

### Agile Approach

- 2-week sprints
- Daily standups (self-review)
- Weekly demos to stakeholders
- Continuous integration/deployment

### AI-Assisted Development

- Taskmaster AI for task breakdown
- Claude Code for implementation
- GitHub Copilot for code completion
- Automated testing with AI-generated test cases

## Appendix

### Glossary

- **DSL**: Domain-Specific Language for strategy definition
- **PWA**: Progressive Web App with offline capabilities
- **Kelly Criterion**: Mathematical formula for optimal position sizing
- **Correlation ID**: Unique identifier for distributed tracing

### References

- Creon Plus API Documentation
- Kafka Streams Documentation
- ClickHouse Time-Series Best Practices
- PWA Service Worker Specifications
