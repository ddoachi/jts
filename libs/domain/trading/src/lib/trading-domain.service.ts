// Generated from spec: E01-F03-T02 (Configure Shared Libraries Infrastructure)
// Spec ID: 995e1fda

import { Position, PositionSide } from '@jts/shared/interfaces';

export interface PositionCalculation {
  quantity: number;
  totalValue: number;
  averagePrice: number;
  unrealizedPnl: number;
  realizedPnl: number;
  percentageReturn: number;
}

export class TradingDomainService {
  calculatePosition(
    entryPrice: number,
    currentPrice: number,
    quantity: number,
    side: PositionSide
  ): PositionCalculation {
    const totalValue = currentPrice * quantity;
    const entryValue = entryPrice * quantity;
    
    let unrealizedPnl: number;
    if (side === PositionSide.LONG) {
      unrealizedPnl = (currentPrice - entryPrice) * quantity;
    } else {
      unrealizedPnl = (entryPrice - currentPrice) * quantity;
    }
    
    const percentageReturn = (unrealizedPnl / entryValue) * 100;
    
    return {
      quantity,
      totalValue,
      averagePrice: entryPrice,
      unrealizedPnl,
      realizedPnl: 0,
      percentageReturn,
    };
  }
  
  calculatePositionSize(
    accountBalance: number,
    riskPercentage: number,
    entryPrice: number,
    stopLoss: number
  ): number {
    const riskAmount = accountBalance * (riskPercentage / 100);
    const priceRisk = Math.abs(entryPrice - stopLoss);
    
    if (priceRisk === 0) {
      throw new Error('Stop loss cannot be equal to entry price');
    }
    
    return Math.floor(riskAmount / priceRisk);
  }
  
  calculateBreakeven(
    positions: Array<{ price: number; quantity: number }>
  ): number {
    if (positions.length === 0) return 0;
    
    let totalQuantity = 0;
    let totalValue = 0;
    
    for (const position of positions) {
      totalQuantity += position.quantity;
      totalValue += position.price * position.quantity;
    }
    
    return totalQuantity > 0 ? totalValue / totalQuantity : 0;
  }
  
  calculateProfitTarget(
    entryPrice: number,
    riskRewardRatio: number,
    stopLoss: number
  ): number {
    const risk = Math.abs(entryPrice - stopLoss);
    const reward = risk * riskRewardRatio;
    
    return stopLoss < entryPrice
      ? entryPrice + reward
      : entryPrice - reward;
  }
  
  validateOrderSize(
    quantity: number,
    minSize: number,
    maxSize: number,
    stepSize: number
  ): { valid: boolean; adjustedQuantity?: number; error?: string } {
    if (quantity < minSize) {
      return {
        valid: false,
        error: `Quantity ${quantity} is below minimum ${minSize}`,
      };
    }
    
    if (quantity > maxSize) {
      return {
        valid: false,
        error: `Quantity ${quantity} exceeds maximum ${maxSize}`,
      };
    }
    
    const remainder = (quantity - minSize) % stepSize;
    if (remainder !== 0) {
      const adjustedQuantity = quantity - remainder;
      return {
        valid: true,
        adjustedQuantity,
      };
    }
    
    return { valid: true };
  }
}