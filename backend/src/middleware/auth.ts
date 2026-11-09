import type { NextFunction, Request, Response } from 'express';
import jwt from 'jsonwebtoken';
import { Types } from 'mongoose';
import { env } from '../config/env.js';
import { ApiError } from './errors.js';

declare global {
  namespace Express {
    interface Request {
      userId?: Types.ObjectId;
    }
  }
}

export function requireAuth(request: Request, _response: Response, next: NextFunction): void {
  const header = request.header('authorization');
  const token = header?.startsWith('Bearer ') ? header.slice(7) : undefined;
  if (!token) return next(new ApiError(401, 'Unauthorized', 'A bearer access token is required.'));

  try {
    const payload = jwt.verify(token, env.JWT_ACCESS_SECRET, { algorithms: ['HS256'] });
    if (typeof payload === 'string' || payload.typ !== 'access' || typeof payload.sub !== 'string' || !Types.ObjectId.isValid(payload.sub)) {
      return next(new ApiError(401, 'Unauthorized', 'The access token is invalid.'));
    }
    request.userId = new Types.ObjectId(payload.sub);
    next();
  } catch {
    next(new ApiError(401, 'Unauthorized', 'The access token is invalid or expired.'));
  }
}

export function userIdFrom(request: Request): Types.ObjectId {
  if (!request.userId) throw new ApiError(401, 'Unauthorized', 'Authentication is required.');
  return request.userId;
}
