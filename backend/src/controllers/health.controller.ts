import type { Request, Response } from 'express';
import mongoose from 'mongoose';

export function get(_req: Request, res: Response): void {
  const connected = mongoose.connection.readyState === 1;
  res.json({ ok: connected, database: 'number_hunter' });
}
