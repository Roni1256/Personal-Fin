export function rupeesToPaise(value: number): number {
  if (!Number.isFinite(value) || value < 0) throw new RangeError('Amount must be a finite non-negative number');
  const paise = Math.round(value * 100);
  if (!Number.isSafeInteger(paise)) throw new RangeError('Amount exceeds safe integer range');
  return paise;
}

export function paiseToRupees(value: number): number {
  if (!Number.isSafeInteger(value)) throw new RangeError('Paise amount must be a safe integer');
  return value / 100;
}

export function formatPaise(value: number): string {
  return `₹${paiseToRupees(value).toFixed(2)}`;
}
