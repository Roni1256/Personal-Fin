export function parseMonth(value: string): { year: number; month: number; start: Date; end: Date } {
  const match = /^(\d{4})-(0[1-9]|1[0-2])$/.exec(value);
  if (!match) throw new RangeError('Month must use YYYY-MM format');
  const year = Number(match[1]);
  const month = Number(match[2]);
  return {
    year,
    month,
    start: new Date(Date.UTC(year, month - 1, 1)),
    end: new Date(Date.UTC(year, month, 1)),
  };
}

export function monthsUntil(targetDate: Date, from = new Date()): number {
  const months = (targetDate.getUTCFullYear() - from.getUTCFullYear()) * 12
    + targetDate.getUTCMonth() - from.getUTCMonth();
  return Math.max(1, months);
}
