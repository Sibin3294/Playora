import * as gameService from '../services/game.service';
import { toPublicGame, toPublicPlayer } from '../domain/gameRules';
import { asyncHandler } from '../middleware/asyncHandler';
import type { AuthedRequest } from '../middleware/auth';
import { AppError } from '../errors/AppError';

export const listForPlayer = asyncHandler(async (req: AuthedRequest, res) => {
  if (req.player && String(req.player._id) !== req.params.id) {
    throw new AppError(403, 'You can only access your own hunts.');
  }
  const games = await gameService.listFinished(req.params.id);
  res.json({ games: games.map((game) => toPublicGame(game)) });
});

export const create = asyncHandler(async (req: AuthedRequest, res) => {
  const playerId = req.playerId || req.body.playerId;
  const { game, player } = await gameService.start({
    playerId,
    levelId: req.body.levelId,
  });
  res.status(201).json({
    game: toPublicGame(game),
    player: toPublicPlayer(player),
  });
});

export const getById = asyncHandler(async (req, res) => {
  const game = await gameService.getById(req.params.id);
  res.json({ game: toPublicGame(game) });
});

export const guess = asyncHandler(async (req, res) => {
  const result = await gameService.submitGuess(req.params.id, req.body.value);
  res.json({
    game: toPublicGame(result.game),
    player: toPublicPlayer(result.player),
    unlockedLevelIds: result.unlockedLevelIds,
  });
});
