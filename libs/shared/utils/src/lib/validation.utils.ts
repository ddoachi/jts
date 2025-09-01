// Generated from spec: E01-F03-T02 (Configure Shared Libraries Infrastructure)
// Spec ID: 995e1fda

export function isValidEmail(email: string): boolean {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return emailRegex.test(email);
}

export function isValidUrl(url: string): boolean {
  try {
    new URL(url);
    return true;
  } catch {
    return false;
  }
}

export function isValidSymbol(symbol: string): boolean {
  // Trading symbol validation (e.g., BTC/USDT, AAPL, 005930)
  const symbolRegex = /^[A-Z0-9]+([\/\-][A-Z0-9]+)?$/;
  return symbolRegex.test(symbol.toUpperCase());
}

export function isValidPrice(price: number): boolean {
  return price > 0 && Number.isFinite(price) && !Number.isNaN(price);
}

export function isValidQuantity(quantity: number): boolean {
  return quantity > 0 && Number.isFinite(quantity) && !Number.isNaN(quantity);
}

export function validateRange(
  value: number,
  min: number,
  max: number
): { valid: boolean; error?: string } {
  if (value < min) {
    return { valid: false, error: `Value ${value} is below minimum ${min}` };
  }
  if (value > max) {
    return { valid: false, error: `Value ${value} exceeds maximum ${max}` };
  }
  return { valid: true };
}

export function validateRequiredFields<T extends object>(
  obj: T,
  requiredFields: (keyof T)[]
): { valid: boolean; missingFields: string[] } {
  const missingFields: string[] = [];
  
  for (const field of requiredFields) {
    if (obj[field] === undefined || obj[field] === null || obj[field] === '') {
      missingFields.push(String(field));
    }
  }
  
  return {
    valid: missingFields.length === 0,
    missingFields,
  };
}

export function sanitizeString(str: string): string {
  return str
    .trim()
    .replace(/[<>]/g, '') // Remove potential HTML tags
    .replace(/\s+/g, ' '); // Normalize whitespace
}

export function validateApiKey(apiKey: string): boolean {
  // Basic API key validation (adjust pattern as needed)
  return apiKey.length >= 32 && /^[A-Za-z0-9\-_]+$/.test(apiKey);
}

export function validateOrderParams(order: {
  symbol: string;
  side: string;
  type: string;
  quantity: number;
  price?: number;
}): { valid: boolean; errors: string[] } {
  const errors: string[] = [];
  
  if (!isValidSymbol(order.symbol)) {
    errors.push('Invalid symbol format');
  }
  
  if (!['BUY', 'SELL'].includes(order.side.toUpperCase())) {
    errors.push('Invalid order side');
  }
  
  if (!['MARKET', 'LIMIT', 'STOP', 'STOP_LIMIT'].includes(order.type.toUpperCase())) {
    errors.push('Invalid order type');
  }
  
  if (!isValidQuantity(order.quantity)) {
    errors.push('Invalid quantity');
  }
  
  if (order.type.toUpperCase() === 'LIMIT' && !isValidPrice(order.price || 0)) {
    errors.push('Invalid price for limit order');
  }
  
  return {
    valid: errors.length === 0,
    errors,
  };
}