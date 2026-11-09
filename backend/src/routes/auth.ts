import { Router } from 'express';
import { OAuth2Client } from 'google-auth-library';
import { Types } from 'mongoose';
import { z } from 'zod';
import { env } from '../config/env.js';
import { createOtp, hashOtp, hashRefreshToken, verifyHash } from '../utils/crypto.js';
import { createTokenPair } from '../utils/tokens.js';
import { OtpChallenge, Profile, RefreshSession, User } from '../models/index.js';
import { ApiError } from '../middleware/errors.js';
import { asyncHandler } from '../middleware/async-handler.js';
import { requireAuth, userIdFrom } from '../middleware/auth.js';

const router = Router();
const googleClient = new OAuth2Client(env.GOOGLE_CLIENT_ID || undefined);
const phoneSchema = z.string().regex(/^\+[1-9]\d{7,14}$/, 'Phone must be in E.164 format');
const requestOtpSchema = z.object({ phone: phoneSchema });
const verifyOtpSchema = z.object({ phone: phoneSchema, code: z.string().regex(/^\d{6}$/) });
const googleSchema = z.object({ idToken: z.string().min(20) });
const refreshSchema = z.object({ refreshToken: z.string().min(40) });

export function shouldUseDevOtp(envConfig: {
  NODE_ENV?: string;
  DEV_OTP_ENABLED?: boolean;
  IS_HOSTED?: boolean;
  TWILIO_ACCOUNT_SID?: string;
  TWILIO_AUTH_TOKEN?: string;
  TWILIO_VERIFY_SERVICE_SID?: string;
} = env): boolean {
  return !envConfig.IS_HOSTED && envConfig.NODE_ENV !== 'production' && Boolean(envConfig.DEV_OTP_ENABLED);
}

async function sendTwilioVerification(phone: string): Promise<void> {
  const sid = env.TWILIO_VERIFY_SERVICE_SID;
  if (!env.TWILIO_ACCOUNT_SID || !env.TWILIO_AUTH_TOKEN || !sid) {
    throw new ApiError(503, 'OTP Unavailable', 'SMS verification is not configured.');
  }
  const credentials = Buffer.from(`${env.TWILIO_ACCOUNT_SID}:${env.TWILIO_AUTH_TOKEN}`).toString('base64');
  const response = await fetch(`https://verify.twilio.com/v2/Services/${sid}/Verifications`, {
    method: 'POST',
    headers: { Authorization: `Basic ${credentials}`, 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({ To: phone, Channel: 'sms' }),
    signal: AbortSignal.timeout(10_000),
  });
  if (!response.ok) throw new ApiError(502, 'OTP Delivery Failed', 'The verification provider could not send a code.');
}

async function verifyTwilioCode(phone: string, code: string): Promise<boolean> {
  const sid = env.TWILIO_VERIFY_SERVICE_SID;
  if (!env.TWILIO_ACCOUNT_SID || !env.TWILIO_AUTH_TOKEN || !sid) {
    throw new ApiError(503, 'OTP Unavailable', 'SMS verification is not configured.');
  }
  const credentials = Buffer.from(`${env.TWILIO_ACCOUNT_SID}:${env.TWILIO_AUTH_TOKEN}`).toString('base64');
  const response = await fetch(`https://verify.twilio.com/v2/Services/${sid}/VerificationCheck`, {
    method: 'POST',
    headers: { Authorization: `Basic ${credentials}`, 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({ To: phone, Code: code }),
    signal: AbortSignal.timeout(10_000),
  });
  if (!response.ok) return false;
  const body = await response.json() as { status?: string };
  return body.status === 'approved';
}

router.post('/otp/request', asyncHandler(async (request, response) => {
  const { phone } = requestOtpSchema.parse(request.body);
  if (shouldUseDevOtp()) {
    await OtpChallenge.deleteMany({ phone });
    const code = createOtp();
    await OtpChallenge.create({ phone, codeHash: hashOtp(code), expiresAt: new Date(Date.now() + 5 * 60_000) });
    response.status(200).json({ message: 'Development OTP created; it expires in five minutes.', devCode: code });
    return;
  }
  await sendTwilioVerification(phone);
  response.status(202).json({ message: 'Verification code sent.' });
}));

router.post('/otp/verify', asyncHandler(async (request, response) => {
  const { phone, code } = verifyOtpSchema.parse(request.body);
  let approved = false;
  if (shouldUseDevOtp()) {
    const challenge = await OtpChallenge.findOne({ phone, consumedAt: null, expiresAt: { $gt: new Date() } }).sort({ createdAt: -1 });
    if (!challenge || challenge.attempts >= 5) throw new ApiError(401, 'Invalid OTP', 'The code is invalid or expired.');
    challenge.attempts += 1;
    if (!verifyHash(hashOtp(code), challenge.codeHash)) {
      await challenge.save();
      throw new ApiError(401, 'Invalid OTP', 'The code is invalid or expired.');
    }
    challenge.consumedAt = new Date();
    await challenge.save();
    approved = true;
  } else {
    approved = await verifyTwilioCode(phone, code);
  }
  if (!approved) throw new ApiError(401, 'Invalid OTP', 'The code is invalid or expired.');

  let user = await User.findOne({ phone });
  if (!user) user = await User.create({ phone });
  if (user.status !== 'active') throw new ApiError(403, 'Account Unavailable', 'This account cannot sign in.');
  await Profile.updateOne({ userId: user._id }, { $setOnInsert: { userId: user._id } }, { upsert: true });
  const tokens = await createTokenPair(user._id);
  response.json({ user: { id: user._id.toString(), phone: user.phone, name: user.name }, ...tokens });
}));

router.post('/google', asyncHandler(async (request, response) => {
  if (!env.GOOGLE_CLIENT_ID) throw new ApiError(503, 'Google Sign-in Unavailable', 'Google authentication is not configured.');
  const { idToken } = googleSchema.parse(request.body);
  const ticket = await googleClient.verifyIdToken({ idToken, audience: env.GOOGLE_CLIENT_ID });
  const claims = ticket.getPayload();
  if (!claims?.sub || !claims.email || !claims.email_verified) throw new ApiError(401, 'Invalid Google Token', 'A verified Google account is required.');

  let user = await User.findOne({ googleSub: claims.sub });
  if (!user) user = await User.findOne({ email: claims.email.toLowerCase() });
  if (!user) user = await User.create({ googleSub: claims.sub, email: claims.email.toLowerCase(), name: claims.name });
  else {
    user.googleSub = claims.sub;
    user.email = claims.email.toLowerCase();
    user.name ??= claims.name;
    await user.save();
  }
  if (user.status !== 'active') throw new ApiError(403, 'Account Unavailable', 'This account cannot sign in.');
  await Profile.updateOne({ userId: user._id }, { $setOnInsert: { userId: user._id } }, { upsert: true });
  response.json({ user: { id: user._id.toString(), email: user.email, name: user.name }, ...(await createTokenPair(user._id)) });
}));

router.post('/refresh', asyncHandler(async (request, response) => {
  const { refreshToken } = refreshSchema.parse(request.body);
  const tokenHash = hashRefreshToken(refreshToken);
  const existing = await RefreshSession.findOne({ tokenHash });
  if (!existing) throw new ApiError(401, 'Invalid Refresh Token', 'The refresh token is invalid.');
  if (existing.revokedAt) {
    await RefreshSession.updateMany({ familyId: existing.familyId, revokedAt: null }, { $set: { revokedAt: new Date() } });
    throw new ApiError(401, 'Refresh Token Reuse Detected', 'The session has been revoked. Sign in again.');
  }
  const claimed = await RefreshSession.findOneAndUpdate(
    { _id: existing._id, revokedAt: null, expiresAt: { $gt: new Date() } },
    { $set: { revokedAt: new Date() } },
    { new: true },
  );
  if (!claimed) throw new ApiError(401, 'Invalid Refresh Token', 'The refresh token is expired or has already been used.');
  try {
    const tokens = await createTokenPair(existing.userId, existing.familyId);
    existing.replacedByTokenHash = hashRefreshToken(tokens.refreshToken);
    await existing.save();
    response.json(tokens);
  } catch (error) {
    await RefreshSession.updateMany({ familyId: existing.familyId, revokedAt: null }, { $set: { revokedAt: new Date() } });
    throw error;
  }
}));

router.post('/logout', requireAuth, asyncHandler(async (request, response) => {
  const { refreshToken } = refreshSchema.parse(request.body);
  const tokenHash = hashRefreshToken(refreshToken);
  await RefreshSession.updateOne({ userId: userIdFrom(request), tokenHash, revokedAt: null }, { $set: { revokedAt: new Date() } });
  response.status(204).end();
}));

router.get('/me', requireAuth, asyncHandler(async (request, response) => {
  const user = await User.findById(userIdFrom(request)).select('phone email name status locale');
  if (!user || user.status !== 'active') throw new ApiError(404, 'User Not Found', 'The signed-in user no longer exists.');
  response.json({ id: user._id.toString(), phone: user.phone, email: user.email, name: user.name, locale: user.locale });
}));

export default router;
