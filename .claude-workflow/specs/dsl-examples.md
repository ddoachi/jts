# DSL Strategy Engine - Extended Examples

## Basic Strategy Patterns

### 1. Simple Moving Average Crossover
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

### 2. RSI Mean Reversion
```typescript
strategy("RSI_MeanReversion") {
  parameters {
    oversold_level = 30
    overbought_level = 70
    position_size = "10%"
  }
  
  indicators {
    rsi = RSI(period: 14)
  }
  
  entry.long {
    when (rsi < oversold_level AND price > SMA(200)) {
      buy(
        quantity: position_size,
        type: "limit",
        price: close * 0.995,
        stop_loss: "2%",
        take_profit: "5%"
      )
    }
  }
  
  entry.short {
    when (rsi > overbought_level AND price < SMA(200)) {
      sell_short(
        quantity: position_size,
        type: "limit",
        price: close * 1.005
      )
    }
  }
}
```

### 3. Bollinger Bands Breakout
```typescript
strategy("BB_Breakout") {
  timeframe = "15m"
  
  indicators {
    bb = BollingerBands(period: 20, std_dev: 2)
    volume_sma = SMA(source: volume, period: 20)
  }
  
  filters {
    high_volume = volume > volume_sma * 1.5
    trend_up = close > SMA(50)
  }
  
  entry.long {
    when (close crosses above bb.upper AND high_volume AND trend_up) {
      buy(
        quantity: calculate_kelly_criterion(),
        type: "stop",
        stop_price: bb.upper * 1.01
      )
    }
  }
  
  risk_management {
    max_position_size = "20%"
    trailing_stop = "3%"
    daily_loss_limit = "5%"
  }
}
```

## Advanced Strategy Patterns

### 4. Multi-Timeframe Strategy
```typescript
strategy("MultiTimeframe_Momentum") {
  timeframes {
    daily = "1d"
    hourly = "1h"
    minute15 = "15m"
  }
  
  indicators {
    on daily {
      trend = SMA(period: 50)
      momentum = MACD(fast: 12, slow: 26, signal: 9)
    }
    
    on hourly {
      rsi = RSI(period: 14)
      stoch = Stochastic(k: 14, d: 3)
    }
    
    on minute15 {
      entry_signal = MACD(fast: 5, slow: 13, signal: 5)
    }
  }
  
  entry.long {
    when (
      daily.close > daily.trend AND
      daily.momentum.histogram > 0 AND
      hourly.rsi between [40, 60] AND
      minute15.entry_signal crosses above 0
    ) {
      buy(quantity: "10%", type: "market")
    }
  }
}
```

### 5. Pair Trading Strategy
```typescript
strategy("PairTrading_Cointegration") {
  symbols = ["005930", "000660"]  // Samsung Electronics, SK Hynix
  
  indicators {
    spread = price[symbols[0]] / price[symbols[1]]
    spread_mean = SMA(source: spread, period: 20)
    spread_std = STD(source: spread, period: 20)
    z_score = (spread - spread_mean) / spread_std
  }
  
  entry.pair_long {
    when (z_score < -2) {
      buy(symbol: symbols[0], quantity: "50%")
      sell_short(symbol: symbols[1], quantity: "50%")
    }
  }
  
  entry.pair_short {
    when (z_score > 2) {
      sell_short(symbol: symbols[0], quantity: "50%")
      buy(symbol: symbols[1], quantity: "50%")
    }
  }
  
  exit.all {
    when (abs(z_score) < 0.5) {
      close_all_positions()
    }
  }
}
```

### 6. Event-Driven Strategy
```typescript
strategy("Earnings_Momentum") {
  events {
    earnings_release = corporate_calendar.earnings
    dividend_ex_date = corporate_calendar.dividend
  }
  
  indicators {
    price_momentum = ROC(period: 20)
    volume_surge = volume / SMA(volume, 20)
  }
  
  entry.long {
    when (
      days_until(earnings_release) between [1, 5] AND
      price_momentum > 10 AND
      volume_surge > 2
    ) {
      buy(
        quantity: "15%",
        type: "market",
        hold_until: earnings_release + days(2)
      )
    }
  }
  
  risk_management {
    event_risk {
      reduce_position_before(earnings_release, by: "50%")
    }
  }
}
```

## Complex Strategy Patterns

### 7. Machine Learning Integration
```typescript
strategy("ML_Signal_Integration") {
  models {
    price_prediction = load_model("./models/price_predictor.pkl")
    sentiment_score = external_api("sentiment_analysis")
  }
  
  indicators {
    technical_score = weighted_average(
      RSI(14): 0.3,
      MACD.signal: 0.3,
      BB.position: 0.4
    )
  }
  
  signals {
    ml_signal = price_prediction.predict(
      features: [close, volume, technical_score]
    )
    sentiment = sentiment_score.get(symbol)
  }
  
  entry.long {
    when (
      ml_signal > 0.7 AND
      sentiment > 0.5 AND
      technical_score > 0.6
    ) {
      buy(
        quantity: scale_position(ml_signal * sentiment),
        type: "market"
      )
    }
  }
}
```

### 8. Portfolio-Level Strategy
```typescript
strategy("Sector_Rotation") {
  universe = KOSPI200.filter(market_cap > 1_000_000_000_000)
  
  portfolio {
    max_positions = 10
    rebalance_frequency = "monthly"
    sector_limits = {
      "Technology": "30%",
      "Finance": "20%",
      "Healthcare": "15%"
    }
  }
  
  ranking {
    momentum_score = ROC(period: 60)
    quality_score = ROE * (1 - debt_ratio)
    combined_score = momentum_score * 0.6 + quality_score * 0.4
  }
  
  rebalance {
    when (is_first_trading_day_of_month()) {
      top_stocks = universe
        .sort_by(combined_score, descending: true)
        .take(max_positions)
      
      adjust_portfolio(top_stocks, equal_weight: true)
    }
  }
}
```

## DSL Architecture Components

### Core Language Features
```typescript
// Variable declarations
let threshold = 0.5
const MAX_RISK = 0.02

// Conditional logic
if (rsi < 30) {
  signal = "oversold"
} else if (rsi > 70) {
  signal = "overbought"
}

// Loops
for symbol in watchlist {
  evaluate_signal(symbol)
}

// Functions
function calculate_position_size(risk_amount, stop_distance) {
  return risk_amount / stop_distance
}

// State management
state {
  last_signal_time: DateTime
  consecutive_losses: Integer
  daily_profit: Decimal
}
```

### Built-in Functions
```typescript
// Market data
current_price()
highest(period: 20)
lowest(period: 20)
volume_weighted_average_price()

// Position management
open_positions()
position_size(symbol)
unrealized_pnl()
realized_pnl(period: "today")

// Risk calculations
calculate_kelly_criterion()
calculate_sharpe_ratio()
max_drawdown()
value_at_risk(confidence: 0.95)

// Time functions
market_hours()
is_holiday()
bars_since(condition)
time_since(event)
```

### Execution Modes
```typescript
strategy("Adaptive_Strategy") {
  mode {
    backtest {
      start_date = "2023-01-01"
      end_date = "2023-12-31"
      initial_capital = 100_000_000
      commission = 0.00015
      slippage = 0.0001
    }
    
    paper_trading {
      enabled = true
      capital = 10_000_000
    }
    
    live_trading {
      enabled = false
      max_capital = 50_000_000
      require_confirmation = true
    }
  }
}
```