import { createHash, createHmac, randomBytes, randomInt, timingSafeEqual } from 'node:crypto';
import { env } from '../config/env.js';

export function hashOtp(code: string): string {
  return createHash('sha256').update(`${code}:${env.JWT_REFRESH_SECRET}`).digest('hex');
}

export function verifyHash(actual: string, expected: string): boolean {
  const left = Buffer.from(actual, 'hex');
  const right = Buffer.from(expected, 'hex');
  return left.length === right.length && timingSafeEqual(left, right);
}

export function hashRefreshToken(token: string): string {
  return createHmac('sha256', env.JWT_REFRESH_SECRET).update(token).digest('hex');
}

export function createOtp(): string {
  return randomInt(0, 1_000_000).toString().padStart(6, '0');
}

export function createOpaqueToken(): string {
  return randomBytes(48).toString('base64url');
}
