// Generated from spec: E01-F03-T02 (Configure Shared Libraries Infrastructure)
// Spec ID: 995e1fda

export interface ITradingStrategy {
  name: string;
  version: string;
  initialize(params: StrategyParams): Promise<void>;
  execute(marketData: MarketSnapshot): Promise<TradingSignal | null>;
  validate(): boolean;
  getPerformanceMetrics(): PerformanceMetrics;
  stop(): Promise<void>;
}

export interface StrategyParams {
  symbol: string;
  timeframe: Timeframe;
  riskLimit: number;
  positionSize: number;
  stopLoss?: number;
  takeProfit?: number;
  maxDrawdown?: number;
  parameters: Record<string, any>;
}

export interface MarketSnapshot {
  symbol: string;
  timestamp: Date;
  price: number;
  volume: number;
  bid: number;
  ask: number;
  indicators?: Record<string, number>;
  orderBook?: OrderBookSnapshot;
  recentTrades?: Trade[];
}

export interface TradingSignal {
  timestamp: Date;
  symbol: string;
  action: SignalAction;
  price?: number;
  quantity: number;
  confidence: number;
  reason: string;
  stopLoss?: number;
  takeProfit?: number;
  metadata?: Record<string, any>;
}

export interface PerformanceMetrics {
  totalTrades: number;
  winningTrades: number;
  losingTrades: number;
  winRate: number;
  totalPnl: number;
  avgWin: number;
  avgLoss: number;
  sharpeRatio: number;
  maxDrawdown: number;
  profitFactor: number;
}

export interface OrderBookSnapshot {
  timestamp: Date;
  bids: PriceLevel[];
  asks: PriceLevel[];
  spread: number;
  midPrice: number;
}

export interface PriceLevel {
  price: number;
  quantity: number;
  orderCount?: number;
}

export interface Trade {
  id: string;
  timestamp: Date;
  price: number;
  quantity: number;
  side: 'BUY' | 'SELL';
  isMaker: boolean;
}

export enum SignalAction {
  BUY = 'BUY',
  SELL = 'SELL',
  HOLD = 'HOLD',
  CLOSE = 'CLOSE',
  CLOSE_LONG = 'CLOSE_LONG',
  CLOSE_SHORT = 'CLOSE_SHORT',
}

export enum Timeframe {
  M1 = '1m',
  M5 = '5m',
  M15 = '15m',
  M30 = '30m',
  H1 = '1h',
  H4 = '4h',
  D1 = '1d',
  W1 = '1w',
  MN1 = '1M',
}