import test from 'node:test';
import assert from 'node:assert/strict';
import { AppError } from '../src/errors/AppError';
import * as authService from '../src/services/auth.service';

test('updateProfile rejects an empty name', async () => {
  await assert.rejects(
    () =>
      authService.updateProfile(
        { name: 'Hunter', save: async () => undefined } as never,
        { name: '   ' },
      ),
    (error: unknown) =>
      error instanceof AppError &&
      error.status === 400 &&
      /Name is required/.test(error.message),
  );
});
