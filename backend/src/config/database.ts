import mongoose from 'mongoose';
import { env } from './env.js';

let connectionPromise: Promise<unknown> | null = null;

export async function connectDatabase(): Promise<void> {
  mongoose.set('strictQuery', true);
  if (mongoose.connection.readyState === 1) return;
  if (!connectionPromise) {
    connectionPromise = mongoose.connect(env.MONGODB_URI, {
      autoIndex: env.NODE_ENV !== 'production',
      maxPoolSize: 10,
      serverSelectionTimeoutMS: 10_000,
    }).catch((error: unknown) => {
      connectionPromise = null;
      throw error;
    });
  }
  await connectionPromise;
}

export async function disconnectDatabase(): Promise<void> {
  await mongoose.disconnect();
  connectionPromise = null;
}
