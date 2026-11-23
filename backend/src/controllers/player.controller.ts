import * as playerService from '../services/player.service';
import { toPublicPlayer } from '../domain/gameRules';
import { asyncHandler } from '../middleware/asyncHandler';
import type { AuthedRequest } from '../middleware/auth';
import { AppError } from '../errors/AppError';

export const create = asyncHandler(async (req, res) => {
  const player = await playerService.findOrCreate(req.body.deviceId);
  res.json({ player: toPublicPlayer(player) });
});

export const getById = asyncHandler(async (req: AuthedRequest, res) => {
  if (req.player && String(req.player._id) !== req.params.id) {
    throw new AppError(403, 'You can only access your own profile.');
  }
  const player = await playerService.getById(req.params.id);
  res.json({ player: toPublicPlayer(player) });
});

export const update = asyncHandler(async (req: AuthedRequest, res) => {
  if (req.player && String(req.player._id) !== req.params.id) {
    throw new AppError(403, 'You can only update your own profile.');
  }
  const player = await playerService.updatePlayer(req.params.id, {
    selectedLevelId: req.body.selectedLevelId,
    name: req.body.name,
  });
  res.json({ player: toPublicPlayer(player) });
});
