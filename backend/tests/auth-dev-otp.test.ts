import { describe, expect, it } from 'vitest';
import { shouldUseDevOtp } from '../src/routes/auth.js';

describe('shouldUseDevOtp', () => {
  it('prefers the free local OTP flow when Twilio credentials are missing', () => {
    expect(shouldUseDevOtp({
      NODE_ENV: 'development',
      DEV_OTP_ENABLED: true,
      TWILIO_ACCOUNT_SID: '',
      TWILIO_AUTH_TOKEN: '',
      TWILIO_VERIFY_SERVICE_SID: '',
    })).toBe(true);
  });

  it('uses Twilio only when the app is configured for it', () => {
    expect(shouldUseDevOtp({
      NODE_ENV: 'production',
      DEV_OTP_ENABLED: false,
      TWILIO_ACCOUNT_SID: 'AC123',
      TWILIO_AUTH_TOKEN: 'token',
      TWILIO_VERIFY_SERVICE_SID: 'VA123',
    })).toBe(false);
  });

  it('never enables development OTP in production, even without SMS credentials', () => {
    expect(shouldUseDevOtp({
      NODE_ENV: 'production',
      DEV_OTP_ENABLED: true,
      TWILIO_ACCOUNT_SID: '',
      TWILIO_AUTH_TOKEN: '',
      TWILIO_VERIFY_SERVICE_SID: '',
    })).toBe(false);
  });
});
