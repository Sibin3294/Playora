import type { Request, Response } from 'express';
import mongoose from 'mongoose';

/** Always 200 so Render health checks pass even if Mongo is still connecting. */
export function get(_req: Request, res: Response): void {
  const mongoReady = mongoose.connection.readyState === 1;
  res.status(200).json({
    ok: true,
    mongo: mongoReady,
    service: 'playora-api',
  });
}
