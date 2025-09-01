// Generated from spec: E01-F03-T02 (Configure Shared Libraries Infrastructure)
// Spec ID: 995e1fda

export interface IBrokerService {
  connect(): Promise<void>;
  disconnect(): Promise<void>;
  isConnected(): boolean;
  getMarketData(symbol: string): Promise<MarketDataDto>;
  submitOrder(order: OrderDto): Promise<OrderResult>;
  cancelOrder(orderId: string): Promise<boolean>;
  getAccountInfo(): Promise<AccountInfo>;
  getPositions(): Promise<Position[]>;
  getOrderHistory(symbol?: string, limit?: number): Promise<Order[]>;
}

export interface MarketDataDto {
  symbol: string;
  timestamp: Date;
  price: number;
  volume: number;
  bid: number;
  ask: number;
  bidSize: number;
  askSize: number;
  open: number;
  high: number;
  low: number;
  close: number;
  change: number;
  changePercent: number;
}

export interface OrderDto {
  symbol: string;
  side: OrderSide;
  type: OrderType;
  quantity: number;
  price?: number;
  stopPrice?: number;
  timeInForce?: TimeInForce;
  clientOrderId?: string;
}

export interface OrderResult {
  orderId: string;
  clientOrderId?: string;
  symbol: string;
  status: OrderStatus;
  executedQty: number;
  executedPrice?: number;
  timestamp: Date;
  message?: string;
}

export interface AccountInfo {
  accountId: string;
  balance: number;
  availableBalance: number;
  currency: string;
  margin: number;
  marginRatio: number;
  positions: number;
  openOrders: number;
}

export interface Position {
  symbol: string;
  side: PositionSide;
  quantity: number;
  entryPrice: number;
  currentPrice: number;
  unrealizedPnl: number;
  realizedPnl: number;
  margin: number;
  marginRatio: number;
}

export interface Order {
  orderId: string;
  clientOrderId?: string;
  symbol: string;
  side: OrderSide;
  type: OrderType;
  status: OrderStatus;
  quantity: number;
  executedQty: number;
  price?: number;
  executedPrice?: number;
  stopPrice?: number;
  timestamp: Date;
  updateTime: Date;
}

export enum OrderSide {
  BUY = 'BUY',
  SELL = 'SELL',
}

export enum OrderType {
  MARKET = 'MARKET',
  LIMIT = 'LIMIT',
  STOP = 'STOP',
  STOP_LIMIT = 'STOP_LIMIT',
  TRAILING_STOP = 'TRAILING_STOP',
}

export enum OrderStatus {
  NEW = 'NEW',
  PARTIALLY_FILLED = 'PARTIALLY_FILLED',
  FILLED = 'FILLED',
  CANCELED = 'CANCELED',
  REJECTED = 'REJECTED',
  EXPIRED = 'EXPIRED',
}

export enum TimeInForce {
  GTC = 'GTC', // Good Till Cancel
  IOC = 'IOC', // Immediate or Cancel
  FOK = 'FOK', // Fill or Kill
  GTD = 'GTD', // Good Till Date
}

export enum PositionSide {
  LONG = 'LONG',
  SHORT = 'SHORT',
}