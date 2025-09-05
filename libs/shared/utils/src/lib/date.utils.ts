// Generated from spec: E01-F03-T02 (Configure Shared Libraries Infrastructure)
// Spec ID: 995e1fda

export function formatDate(date: Date, format: string = 'YYYY-MM-DD'): string {
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, '0');
  const day = String(date.getDate()).padStart(2, '0');
  const hours = String(date.getHours()).padStart(2, '0');
  const minutes = String(date.getMinutes()).padStart(2, '0');
  const seconds = String(date.getSeconds()).padStart(2, '0');

  return format
    .replace('YYYY', String(year))
    .replace('MM', month)
    .replace('DD', day)
    .replace('HH', hours)
    .replace('mm', minutes)
    .replace('ss', seconds);
}

export function addDays(date: Date, days: number): Date {
  const result = new Date(date);
  result.setDate(result.getDate() + days);
  return result;
}

export function addHours(date: Date, hours: number): Date {
  const result = new Date(date);
  result.setHours(result.getHours() + hours);
  return result;
}

export function getTimezoneOffset(timezone: string): number {
  const now = new Date();
  const tzString = now.toLocaleString('en-US', { timeZone: timezone });
  const tzDate = new Date(tzString);
  return (tzDate.getTime() - now.getTime()) / (1000 * 60 * 60);
}

export function isMarketOpen(
  currentTime: Date,
  marketOpen: { hour: number; minute: number },
  marketClose: { hour: number; minute: number },
): boolean {
  const hours = currentTime.getHours();
  const minutes = currentTime.getMinutes();
  const currentMinutes = hours * 60 + minutes;
  const openMinutes = marketOpen.hour * 60 + marketOpen.minute;
  const closeMinutes = marketClose.hour * 60 + marketClose.minute;

  return currentMinutes >= openMinutes && currentMinutes <= closeMinutes;
}

export function getNextTradingDay(date: Date): Date {
  const nextDay = new Date(date);
  nextDay.setDate(nextDay.getDate() + 1);

  // Skip weekends
  while (nextDay.getDay() === 0 || nextDay.getDay() === 6) {
    nextDay.setDate(nextDay.getDate() + 1);
  }

  return nextDay;
}

export function timeframeToMilliseconds(timeframe: string): number {
  const match = timeframe.match(/^(\d+)([smhdwM])$/);
  if (!match) throw new Error(`Invalid timeframe: ${timeframe}`);

  const [, value, unit] = match;
  const num = parseInt(value!, 10);

  switch (unit) {
    case 's':
      return num * 1000;
    case 'm':
      return num * 60 * 1000;
    case 'h':
      return num * 60 * 60 * 1000;
    case 'd':
      return num * 24 * 60 * 60 * 1000;
    case 'w':
      return num * 7 * 24 * 60 * 60 * 1000;
    case 'M':
      return num * 30 * 24 * 60 * 60 * 1000;
    default:
      throw new Error(`Unknown timeframe unit: ${unit}`);
  }
}

export function getTimeDifference(
  start: Date,
  end: Date,
): {
  days: number;
  hours: number;
  minutes: number;
  seconds: number;
  totalMilliseconds: number;
} {
  const diff = end.getTime() - start.getTime();
  const days = Math.floor(diff / (1000 * 60 * 60 * 24));
  const hours = Math.floor((diff % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60));
  const minutes = Math.floor((diff % (1000 * 60 * 60)) / (1000 * 60));
  const seconds = Math.floor((diff % (1000 * 60)) / 1000);

  return { days, hours, minutes, seconds, totalMilliseconds: diff };
}
