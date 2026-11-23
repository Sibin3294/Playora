import test from 'node:test';
import assert from 'node:assert/strict';
import jwt from 'jsonwebtoken';
import { JWT_EXPIRES_IN, JWT_SECRET } from '../src/config/auth';
import { signToken } from '../src/services/auth.service';
import { AppError } from '../src/errors/AppError';
import * as authService from '../src/services/auth.service';

test('signToken embeds the player id and can be verified', () => {
  const token = signToken({
    _id: '507f1f77bcf86cd799439011',
    email: 'hunter@example.com',
  } as never);

  const payload = jwt.verify(token, JWT_SECRET) as {
    sub?: string;
    email?: string | null;
  };
  assert.equal(payload.sub, '507f1f77bcf86cd799439011');
  assert.equal(payload.email, 'hunter@example.com');
  assert.equal(typeof JWT_EXPIRES_IN, 'string');
});

test('register rejects short passwords before touching the database', async () => {
  await assert.rejects(
    () => authService.register({ email: 'a@b.co', password: '123' }),
    (error: unknown) =>
      error instanceof AppError &&
      error.status === 400 &&
      /Password must be at least 6 characters/.test(error.message),
  );
});

test('login rejects invalid email before touching the database', async () => {
  await assert.rejects(
    () => authService.login({ email: 'not-an-email', password: 'secret12' }),
    (error: unknown) =>
      error instanceof AppError &&
      error.status === 400 &&
      /valid email/.test(error.message),
  );
});
