import { createRequire } from 'node:module';
import compression from 'compression';
import cors from 'cors';
import express, { type RequestHandler } from 'express';
import { rateLimit } from 'express-rate-limit';
import type { HelmetOptions } from 'helmet';
import { env } from './config/env.js';
import { errorHandler, notFound } from './middleware/errors.js';
import advisorRouter from './routes/advisor.js';
import authRouter from './routes/auth.js';
import financeRouter from './routes/finance.js';
import profileRouter from './routes/profile.js';

const helmet = createRequire(import.meta.url)('helmet') as (options?: HelmetOptions) => RequestHandler;
const app = express();

app.set('trust proxy', 1);
app.use(helmet({ crossOriginResourcePolicy: false }));
app.use(cors({ origin: env.CORS_ORIGINS, credentials: true }));
app.use(compression());
app.use(express.json({ limit: '1mb' }));
app.use(express.urlencoded({ extended: true }));
app.use(rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 300,
  standardHeaders: true,
  legacyHeaders: false,
}));

app.get('/health', (_request, response) => {
  response.json({ ok: true, environment: env.NODE_ENV });
});

app.use(env.API_PREFIX, authRouter);
app.use(env.API_PREFIX, advisorRouter);
app.use(env.API_PREFIX, profileRouter);
app.use(env.API_PREFIX, financeRouter);
app.use(notFound);
app.use(errorHandler);

export default app;
