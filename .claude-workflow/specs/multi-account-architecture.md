# Multi-Account KIS Architecture for Momentum Trading

## Overview
Leverage multiple KIS accounts to achieve massive parallel data collection for real-time momentum detection across the entire Korean stock market.

## Account Management Architecture

```
┌──────────────────────────────────────────────────────────┐
│                  Account Manager Service                  │
│                 (Centralized Control)                     │
└──────────────────────────────────────────────────────────┘
                            │
        ┌───────────────────┼───────────────────┐
        │                   │                   │
┌──────────────┐   ┌──────────────┐   ┌──────────────┐
│ KIS Account 1│   │ KIS Account 2│   │ KIS Account 3│
│ Rate: 20/sec │   │ Rate: 20/sec │   │ Rate: 20/sec │
│ Symbols: 600 │   │ Symbols: 600 │   │ Symbols: 600 │
└──────────────┘   └──────────────┘   └──────────────┘
        │                   │                   │
        └───────────────────┼───────────────────┘
                            │
                    ┌──────────────┐
                    │    Kafka     │
                    │ Market Data  │
                    └──────────────┘
                            │
                ┌──────────────────────┐
                │   Strategy Engine    │
                │  (Surge Detection)   │
                └──────────────────────┘
                            │
                ┌──────────────────────┐
                │  Order Router        │
                │ (Load Balancing)     │
                └──────────────────────┘
```

## Implementation Strategy

### 1. Account Pool Management

```typescript
interface KISAccount {
  accountId: string;
  apiKey: string;
  apiSecret: string;
  accountNumber: string;
  rateLimiter: RateLimiter;
  assignedSymbols: Set<string>;
  connectionHealth: 'healthy' | 'degraded' | 'failed';
  metrics: {
    requestsPerSecond: number;
    successRate: number;
    averageLatency: number;
  };
}

class KISAccountPool {
  private accounts: Map<string, KISAccount> = new Map();
  private symbolToAccount: Map<string, string> = new Map();
  
  constructor(private readonly config: AccountPoolConfig) {}
  
  // Distribute symbols across accounts for optimal load balancing
  distributeSymbols(symbols: string[]): void {
    const accountList = Array.from(this.accounts.values())
      .filter(acc => acc.connectionHealth === 'healthy');
    
    const symbolsPerAccount = Math.ceil(symbols.length / accountList.length);
    
    symbols.forEach((symbol, index) => {
      const accountIndex = Math.floor(index / symbolsPerAccount);
      const account = accountList[accountIndex];
      
      account.assignedSymbols.add(symbol);
      this.symbolToAccount.set(symbol, account.accountId);
    });
  }
  
  // Get the best account for placing an order (least loaded)
  getBestAccountForOrder(): KISAccount {
    return Array.from(this.accounts.values())
      .filter(acc => acc.connectionHealth === 'healthy')
      .sort((a, b) => a.metrics.requestsPerSecond - b.metrics.requestsPerSecond)[0];
  }
}
```

### 2. Parallel Data Collection Service

```typescript
class ParallelMarketDataCollector {
  private batchSize = 30; // Max symbols per API call
  private requestInterval = 50; // 50ms = 20 requests/second
  
  async collectMarketData(account: KISAccount): Promise<void> {
    const symbolBatches = this.createBatches(
      Array.from(account.assignedSymbols), 
      this.batchSize
    );
    
    for (const batch of symbolBatches) {
      await this.rateLimitedRequest(account, async () => {
        const data = await this.fetchBatchQuotes(account, batch);
        await this.publishToKafka(data);
      });
      
      await this.sleep(this.requestInterval);
    }
  }
  
  private async fetchBatchQuotes(
    account: KISAccount, 
    symbols: string[]
  ): Promise<MarketData[]> {
    const response = await fetch(
      `${KIS_API_URL}/uapi/domestic-stock/v1/quotations/inquire-multiple`,
      {
        headers: {
          'authorization': `Bearer ${account.apiKey}`,
          'tr_id': 'FHKST11300006' // Multi-symbol quote API
        },
        body: JSON.stringify({ symbols })
      }
    );
    
    return this.normalizeMarketData(response);
  }
}
```

### 3. Surge Detection DSL

```typescript
strategy("MomentumSurgeScanner") {
  parameters {
    surge_threshold = "3%"      // 3% price increase
    volume_multiplier = 2        // 2x average volume
    time_window = "5m"          // Within 5 minutes
    min_price = 1000            // Minimum stock price
    max_price = 500000          // Maximum stock price
  }
  
  scan {
    // Real-time surge detection across all symbols
    when (
      price_change_percent(time_window) > surge_threshold AND
      volume > average_volume(20) * volume_multiplier AND
      price between [min_price, max_price] AND
      rsi(14) < 70  // Not yet overbought
    ) {
      signal("SURGE_DETECTED", {
        symbol: symbol,
        surge_percent: price_change_percent(time_window),
        volume_ratio: volume / average_volume(20),
        entry_price: ask_price
      })
    }
  }
  
  entry {
    on signal("SURGE_DETECTED") {
      // Use available account with lowest load
      buy(
        quantity: calculate_position_size(),
        type: "market",
        account: select_best_account()
      )
    }
  }
  
  exit {
    // Quick profit taking
    when (
      position_profit_percent > 2 OR     // 2% profit
      position_loss_percent > 1 OR        // 1% stop loss
      time_since_entry > minutes(30)      // 30 minute time stop
    ) {
      sell(quantity: "all", type: "market")
    }
  }
}
```

### 4. Symbol Distribution Strategy

```yaml
# Symbol allocation per account based on market cap and liquidity
Account_1:  # Primary - Large caps
  - KOSPI200 components (200 symbols)
  - High liquidity ETFs (50 symbols)
  - Blue chip stocks (350 symbols)
  Total: 600 symbols

Account_2:  # Secondary - Mid caps
  - KOSDAQ150 components (150 symbols)
  - Mid-cap momentum stocks (300 symbols)
  - Sector leaders (150 symbols)
  Total: 600 symbols

Account_3:  # Tertiary - Small caps & speculative
  - Small-cap high volatility (400 symbols)
  - IPO stocks < 1 year (100 symbols)
  - Theme stocks (100 symbols)
  Total: 600 symbols
```

### 5. Performance Optimization

#### Batch Processing
```typescript
// Optimize API calls with maximum batch size
const BATCH_CONFIG = {
  quoteBatchSize: 30,        // Max symbols per quote request
  orderBatchSize: 1,         // Orders must be individual
  intervalMs: 50,            // 20 requests/second
  retryAttempts: 3,
  backoffMs: 100
};
```

#### Caching Strategy
```typescript
// Use Redis for ultra-fast surge detection
class SurgeDetectionCache {
  private redis: RedisClient;
  
  async updatePrice(symbol: string, price: number, volume: number): Promise<boolean> {
    const key = `price:${symbol}`;
    const previous = await this.redis.get(key);
    
    // Calculate surge in Redis for minimal latency
    const surgeDetected = this.detectSurge(previous, price, volume);
    
    // Store with 5-minute sliding window
    await this.redis.setex(key, 300, JSON.stringify({ price, volume, timestamp: Date.now() }));
    
    return surgeDetected;
  }
}
```

### 6. Risk Management

```typescript
class MultiAccountRiskManager {
  private maxExposurePerAccount = 100_000_000; // 100M KRW per account
  private maxTotalExposure = 250_000_000;      // 250M KRW total
  private maxPositionsPerAccount = 10;
  private maxConcurrentOrders = 5;
  
  async validateOrder(order: Order, account: KISAccount): Promise<boolean> {
    const checks = await Promise.all([
      this.checkAccountExposure(account),
      this.checkTotalExposure(),
      this.checkPositionCount(account),
      this.checkOrderRate()
    ]);
    
    return checks.every(check => check === true);
  }
}
```

## Advantages of Multi-Account Architecture

### 1. **Market Coverage**
- Monitor 1,800+ symbols simultaneously (with 3 accounts)
- Detect opportunities across entire market
- No blind spots in momentum detection

### 2. **Execution Speed**
- Parallel order placement across accounts
- Reduced queue time during high volatility
- Better fill rates on momentum trades

### 3. **Risk Distribution**
- Spread positions across multiple accounts
- Account-level risk limits
- Easier compliance with broker limits

### 4. **Operational Resilience**
- Account failover capability
- Continued operation if one account has issues
- Load balancing during peak times

## Implementation Phases

### Phase 1: Dual Account (Week 1-2)
- Set up 2 KIS accounts
- Implement account pool manager
- Test with 1,200 symbols
- Basic surge detection

### Phase 2: Triple Account (Week 3-4)
- Add 3rd account
- Optimize symbol distribution
- Advanced surge patterns
- Performance tuning

### Phase 3: Full Automation (Week 5-6)
- Automated position management
- ML-based surge prediction
- Portfolio optimization
- Risk analytics dashboard

## Configuration Example

```yaml
# config/kis-accounts.yaml
accounts:
  - id: "KIS_001"
    name: "Primary Account"
    api_key: "${KIS_API_KEY_1}"
    api_secret: "${KIS_API_SECRET_1}"
    account_number: "${KIS_ACCOUNT_1}"
    max_positions: 15
    max_exposure: 100000000
    symbol_allocation: "large_cap"
    
  - id: "KIS_002"
    name: "Secondary Account"
    api_key: "${KIS_API_KEY_2}"
    api_secret: "${KIS_API_SECRET_2}"
    account_number: "${KIS_ACCOUNT_2}"
    max_positions: 10
    max_exposure: 80000000
    symbol_allocation: "mid_cap"
    
  - id: "KIS_003"
    name: "Momentum Account"
    api_key: "${KIS_API_KEY_3}"
    api_secret: "${KIS_API_SECRET_3}"
    account_number: "${KIS_ACCOUNT_3}"
    max_positions: 20
    max_exposure: 50000000
    symbol_allocation: "high_volatility"

rate_limits:
  per_account_per_second: 20
  batch_size: 30
  cooldown_ms: 50

surge_detection:
  min_surge_percent: 3.0
  min_volume_ratio: 2.0
  time_window_minutes: 5
  max_positions_per_surge: 3
```

## Expected Performance

### Data Collection
- **Symbols Monitored**: 1,800 (3 accounts)
- **Update Frequency**: Every 3 seconds per symbol
- **Latency**: < 100ms surge detection
- **Throughput**: 60 API calls/second total

### Trading Performance
- **Opportunities/Day**: 20-50 surges detected
- **Win Rate Target**: 60-70%
- **Average Profit**: 1-3% per trade
- **Daily Trades**: 10-20
- **Risk/Reward**: 1:2 ratio

## Monitoring Dashboard

```typescript
interface AccountMetrics {
  accountId: string;
  currentPositions: number;
  totalExposure: number;
  dailyPnL: number;
  apiCallsPerSecond: number;
  successRate: number;
  surgesDetected: number;
  ordersPlaced: number;
  winRate: number;
}

// Real-time dashboard showing all accounts
class MultiAccountDashboard {
  async getSystemHealth(): Promise<SystemHealth> {
    return {
      totalSymbolsCovered: 1800,
      activeAccounts: 3,
      surgesDetectedToday: 47,
      positionsOpen: 23,
      totalExposure: 180_000_000,
      dailyPnL: 3_500_000,
      apiUtilization: '85%',
      systemLatency: '73ms'
    };
  }
}
```

This architecture maximizes your momentum trading strategy by leveraging multiple accounts for comprehensive market coverage and rapid execution!