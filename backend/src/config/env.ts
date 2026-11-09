import dotenv from 'dotenv';
import { z } from 'zod';

dotenv.config();

const schema = z.object({
  NODE_ENV: z.enum(['development', 'test', 'production']).default('development'),
  PORT: z.coerce.number().int().positive().default(3000),
  API_PREFIX: z.string().default('/api/v1'),
  CORS_ORIGINS: z.string().default(''),
  MONGODB_URI: z.string().min(1).default('mongodb://127.0.0.1:27017/personalfin'),
  JWT_ACCESS_SECRET: z.string().default(''),
  JWT_REFRESH_SECRET: z.string().default(''),
  ACCESS_TOKEN_TTL: z.string().default('15m'),
  REFRESH_TOKEN_TTL_DAYS: z.coerce.number().int().positive().default(30),
  DEV_OTP_ENABLED: z.string().default('true'),
  TWILIO_ACCOUNT_SID: z.string().default(''),
  TWILIO_AUTH_TOKEN: z.string().default(''),
  TWILIO_VERIFY_SERVICE_SID: z.string().default(''),
  GOOGLE_CLIENT_ID: z.string().default(''),
  GEMINI_API_KEY: z.string().default(''),
  GEMINI_MODEL: z.string().default('gemini-2.5-flash'),
});

const parsed = schema.safeParse(process.env);
if (!parsed.success) {
  throw new Error(`Invalid environment configuration: ${parsed.error.message}`);
}

const isVercel = process.env.VERCEL === '1';
const isProduction = parsed.data.NODE_ENV === 'production' || isVercel;

if (isProduction) {
  const requiredProductionValues = [
    'JWT_ACCESS_SECRET',
    'JWT_REFRESH_SECRET',
    'MONGODB_URI',
    'GEMINI_API_KEY',
  ] as const;
  const missing = requiredProductionValues.filter((key) => !process.env[key]?.trim());
  if (missing.length) throw new Error(`Missing required production secrets: ${missing.join(', ')}`);
  if (parsed.data.DEV_OTP_ENABLED.toLowerCase() !== 'false') {
    throw new Error('DEV_OTP_ENABLED must be false in production.');
  }
  const productionOrigins = parsed.data.CORS_ORIGINS.split(',').map((origin) => origin.trim()).filter(Boolean);
  if (productionOrigins.some((origin) => !origin.startsWith('https://'))) {
    throw new Error('CORS_ORIGINS must contain only HTTPS origins in production.');
  }
  if (/localhost|127\.0\.0\.1/.test(parsed.data.MONGODB_URI)) {
    throw new Error('MONGODB_URI must not point to localhost in production.');
  }
}

export const env = {
  ...parsed.data,
  NODE_ENV: isProduction ? 'production' as const : parsed.data.NODE_ENV,
  IS_HOSTED: isVercel,
  DEV_OTP_ENABLED: !isVercel && parsed.data.DEV_OTP_ENABLED.toLowerCase() === 'true',
  CORS_ORIGINS: (parsed.data.CORS_ORIGINS || (isProduction ? '' : 'http://localhost:*,http://127.0.0.1:*'))
    .split(',').map((origin) => origin.trim()).filter(Boolean),
  JWT_ACCESS_SECRET: parsed.data.JWT_ACCESS_SECRET || 'local-development-access-secret-change-me',
  JWT_REFRESH_SECRET: parsed.data.JWT_REFRESH_SECRET || 'local-development-refresh-secret-change-me',
};
