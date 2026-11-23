import * as authService from '../services/auth.service';
import { toPublicPlayer } from '../domain/gameRules';
import { asyncHandler } from '../middleware/asyncHandler';
import type { AuthedRequest } from '../middleware/auth';
import { AppError } from '../errors/AppError';

export const register = asyncHandler(async (req, res) => {
  const result = await authService.register(req.body);
  res.status(201).json({
    token: result.token,
    player: toPublicPlayer(result.player),
  });
});

export const login = asyncHandler(async (req, res) => {
  const result = await authService.login(req.body);
  res.json({
    token: result.token,
    player: toPublicPlayer(result.player),
  });
});

export const me = asyncHandler(async (req: AuthedRequest, res) => {
  if (!req.player) throw new AppError(401, 'Login required.');
  res.json({ player: toPublicPlayer(req.player) });
});

export const updateMe = asyncHandler(async (req: AuthedRequest, res) => {
  if (!req.player) throw new AppError(401, 'Login required.');
  const player = await authService.updateProfile(req.player, req.body);
  res.json({ player: toPublicPlayer(player) });
});

export const changePassword = asyncHandler(async (req: AuthedRequest, res) => {
  if (!req.playerId) throw new AppError(401, 'Login required.');
  await authService.changePassword(req.playerId, req.body);
  res.json({ ok: true });
});
