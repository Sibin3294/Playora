import type { Request } from 'express';
import type { PlayerDocument } from '../models/player.model';
import * as authService from '../services/auth.service';
import { AppError } from '../errors/AppError';
import { asyncHandler } from './asyncHandler';

export type AuthedRequest = Request & {
  player?: PlayerDocument;
  playerId?: string;
};

function readBearer(req: Request): string | null {
  const header = req.headers.authorization;
  if (!header) return null;
  const [type, token] = header.split(' ');
  if (type !== 'Bearer' || !token) return null;
  return token;
}

export const optionalAuth = asyncHandler(async (req: AuthedRequest, _res, next) => {
  const token = readBearer(req);
  if (!token) {
    next();
    return;
  }
  const player = await authService.playerFromToken(token);
  req.player = player;
  req.playerId = String(player._id);
  next();
});

export const requireAuth = asyncHandler(async (req: AuthedRequest, _res, next) => {
  const token = readBearer(req);
  if (!token) throw new AppError(401, 'Login required.');
  const player = await authService.playerFromToken(token);
  req.player = player;
  req.playerId = String(player._id);
  next();
});
