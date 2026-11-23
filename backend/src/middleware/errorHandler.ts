import type { ErrorRequestHandler } from 'express';
import { AppError } from '../errors/AppError';

function isDuplicateKey(error: unknown): boolean {
  return Boolean(
    error &&
      typeof error === 'object' &&
      'code' in error &&
      (error as { code?: number }).code === 11000,
  );
}

export const errorHandler: ErrorRequestHandler = (error, _req, res, _next) => {
  if (error instanceof AppError) {
    res.status(error.status).json({ error: error.message });
    return;
  }
  if (error instanceof Error && error.name === 'CastError') {
    res.status(400).json({ error: 'That id is not valid.' });
    return;
  }
  if (isDuplicateKey(error)) {
    const key = (error as { keyPattern?: Record<string, unknown> }).keyPattern;
    if (key?.email) {
      res.status(409).json({ error: 'That email is already registered.' });
      return;
    }
    res.status(409).json({ error: 'That account already exists.' });
    return;
  }
  console.error(error);
  res.status(500).json({ error: 'Something went wrong.' });
};
