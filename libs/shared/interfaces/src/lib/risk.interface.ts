// Generated from spec: E01-F03-T02 (Configure Shared Libraries Infrastructure)
// Spec ID: 995e1fda

export interface IRiskManager {
  evaluateRisk(position: RiskPosition): RiskAssessment;
  calculatePositionSize(params: PositionSizeParams): number;
  checkRiskLimits(order: RiskOrder): RiskValidation;
  calculateVaR(portfolio: Portfolio, confidence: number): number;
  getExposure(symbol?: string): ExposureInfo;
  updateRiskParameters(params: RiskParameters): void;
}

export interface RiskPosition {
  symbol: string;
  quantity: number;
  entryPrice: number;
  currentPrice: number;
  leverage: number;
  margin: number;
  stopLoss?: number;
  takeProfit?: number;
}

export interface RiskAssessment {
  riskScore: number;
  maxLoss: number;
  probabilityOfLoss: number;
  marginRequirement: number;
  recommendations: string[];
  warnings: RiskWarning[];
}

export interface PositionSizeParams {
  accountBalance: number;
  riskPercentage: number;
  entryPrice: number;
  stopLoss: number;
  leverage?: number;
  commission?: number;
}

export interface RiskOrder {
  symbol: string;
  side: 'BUY' | 'SELL';
  quantity: number;
  price: number;
  accountBalance: number;
  existingPositions: RiskPosition[];
}

export interface RiskValidation {
  isValid: boolean;
  errors: string[];
  warnings: string[];
  requiredMargin: number;
  availableMargin: number;
  exposureAfterOrder: number;
  riskScore: number;
}

export interface Portfolio {
  positions: RiskPosition[];
  totalValue: number;
  cashBalance: number;
  marginUsed: number;
  unrealizedPnl: number;
  realizedPnl: number;
}

export interface ExposureInfo {
  symbol?: string;
  totalExposure: number;
  longExposure: number;
  shortExposure: number;
  netExposure: number;
  percentOfPortfolio: number;
  marginUsed: number;
  availableMargin: number;
}

export interface RiskParameters {
  maxPositionSize: number;
  maxLeverage: number;
  maxDrawdown: number;
  dailyLossLimit: number;
  positionLimitPerSymbol: number;
  correlationThreshold: number;
  marginCallLevel: number;
  stopOutLevel: number;
}

export interface RiskWarning {
  level: RiskLevel;
  message: string;
  timestamp: Date;
  metric?: string;
  value?: number;
  threshold?: number;
}

export enum RiskLevel {
  LOW = 'LOW',
  MEDIUM = 'MEDIUM',
  HIGH = 'HIGH',
  CRITICAL = 'CRITICAL',
}