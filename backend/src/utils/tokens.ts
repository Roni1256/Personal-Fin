import jwt, { type SignOptions } from 'jsonwebtoken';
import { env } from '../config/env.js';
import { createOpaqueToken, hashRefreshToken } from './crypto.js';
import { RefreshSession } from '../models/index.js';
import type { Types } from 'mongoose';

export interface TokenPair {
  accessToken: string;
  refreshToken: string;
  tokenType: 'Bearer';
  expiresInSeconds: number;
}

export async function createTokenPair(userId: Types.ObjectId, familyId?: string): Promise<TokenPair> {
  const accessToken = jwt.sign({ typ: 'access' }, env.JWT_ACCESS_SECRET, {
    subject: userId.toString(),
    expiresIn: env.ACCESS_TOKEN_TTL as SignOptions['expiresIn'],
    algorithm: 'HS256',
  });
  const refreshToken = createOpaqueToken();
  const tokenHash = hashRefreshToken(refreshToken);
  const expiresAt = new Date(Date.now() + env.REFRESH_TOKEN_TTL_DAYS * 86_400_000);
  await RefreshSession.create({ userId, familyId: familyId ?? createOpaqueToken(), tokenHash, expiresAt });
  return { accessToken, refreshToken, tokenType: 'Bearer', expiresInSeconds: 900 };
}
