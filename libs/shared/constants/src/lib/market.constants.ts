// Generated from spec: E01-F03-T02 (Configure Shared Libraries Infrastructure)
// Spec ID: 995e1fda

export const MARKET_HOURS = {
  KRX: {
    // Korea Exchange
    open: { hour: 9, minute: 0 },
    close: { hour: 15, minute: 30 },
    timezone: 'Asia/Seoul',
  },
  NYSE: {
    // New York Stock Exchange
    open: { hour: 9, minute: 30 },
    close: { hour: 16, minute: 0 },
    timezone: 'America/New_York',
  },
  NASDAQ: {
    open: { hour: 9, minute: 30 },
    close: { hour: 16, minute: 0 },
    timezone: 'America/New_York',
  },
  CRYPTO: {
    // 24/7
    open: { hour: 0, minute: 0 },
    close: { hour: 23, minute: 59 },
    timezone: 'UTC',
  },
};

export const BROKER_LIMITS = {
  CREON: {
    requestsPerMinute: 200,
    requestsPerSecond: 20,
    maxOrdersPerDay: 1000,
    maxPositions: 200,
  },
  KIS: {
    requestsPerMinute: 60,
    requestsPerSecond: 1,
    maxOrdersPerDay: 500,
    maxPositions: 100,
  },
  BINANCE: {
    requestsPerMinute: 1200,
    requestsPerSecond: 10,
    maxOrdersPerDay: 10000,
    maxPositions: 500,
  },
  UPBIT: {
    requestsPerMinute: 600,
    requestsPerSecond: 10,
    maxOrdersPerDay: 5000,
    maxPositions: 300,
  },
};

export const ORDER_TYPES = {
  MARKET: 'MARKET',
  LIMIT: 'LIMIT',
  STOP: 'STOP',
  STOP_LIMIT: 'STOP_LIMIT',
  TRAILING_STOP: 'TRAILING_STOP',
} as const;

export const ORDER_SIDES = {
  BUY: 'BUY',
  SELL: 'SELL',
} as const;

export const POSITION_SIDES = {
  LONG: 'LONG',
  SHORT: 'SHORT',
} as const;

export const TIME_IN_FORCE = {
  GTC: 'GTC', // Good Till Cancel
  IOC: 'IOC', // Immediate or Cancel
  FOK: 'FOK', // Fill or Kill
  GTD: 'GTD', // Good Till Date
} as const;

export const TIMEFRAMES = {
  M1: '1m',
  M5: '5m',
  M15: '15m',
  M30: '30m',
  H1: '1h',
  H4: '4h',
  D1: '1d',
  W1: '1w',
  MN1: '1M',
} as const;
