// Generated from spec: E01-F03-T02 (Configure Shared Libraries Infrastructure)
// Spec ID: 995e1fda

export function roundToDecimal(value: number, decimals: number): number {
  const factor = Math.pow(10, decimals);
  return Math.round(value * factor) / factor;
}

export function calculatePercentageChange(oldValue: number, newValue: number): number {
  if (oldValue === 0) return 0;
  return ((newValue - oldValue) / Math.abs(oldValue)) * 100;
}

export function calculateAverage(values: number[]): number {
  if (values.length === 0) return 0;
  return values.reduce((sum, val) => sum + val, 0) / values.length;
}

export function calculateMedian(values: number[]): number {
  if (values.length === 0) return 0;
  const sorted = [...values].sort((a, b) => a - b);
  const mid = Math.floor(sorted.length / 2);
  return sorted.length % 2 !== 0 ? sorted[mid]! : (sorted[mid - 1]! + sorted[mid]!) / 2;
}

export function calculateStandardDeviation(values: number[]): number {
  if (values.length === 0) return 0;
  const avg = calculateAverage(values);
  const squareDiffs = values.map((value) => Math.pow(value - avg, 2));
  const avgSquareDiff = calculateAverage(squareDiffs);
  return Math.sqrt(avgSquareDiff);
}

export function clamp(value: number, min: number, max: number): number {
  return Math.min(Math.max(value, min), max);
}

export function lerp(start: number, end: number, amount: number): number {
  return start + (end - start) * clamp(amount, 0, 1);
}

export function calculateCompoundReturn(principal: number, rate: number, periods: number): number {
  return principal * Math.pow(1 + rate, periods);
}

export function calculateSharpeRatio(returns: number[], riskFreeRate: number = 0): number {
  if (returns.length === 0) return 0;
  const avgReturn = calculateAverage(returns);
  const stdDev = calculateStandardDeviation(returns);
  if (stdDev === 0) return 0;
  return (avgReturn - riskFreeRate) / stdDev;
}

export function calculateMaxDrawdown(values: number[]): number {
  if (values.length === 0) return 0;
  let maxDrawdown = 0;
  let peak = values[0]!;

  for (const value of values) {
    if (value > peak) {
      peak = value;
    }
    const drawdown = (peak - value) / peak;
    if (drawdown > maxDrawdown) {
      maxDrawdown = drawdown;
    }
  }

  return maxDrawdown * 100;
}

export function isWithinTolerance(value: number, target: number, tolerance: number): boolean {
  return Math.abs(value - target) <= tolerance;
}

export function calculateEMA(values: number[], period: number): number[] {
  if (values.length === 0) return [];
  const k = 2 / (period + 1);
  const ema: number[] = [values[0]!];

  for (let i = 1; i < values.length; i++) {
    ema.push(values[i]! * k + ema[i - 1]! * (1 - k));
  }

  return ema;
}
