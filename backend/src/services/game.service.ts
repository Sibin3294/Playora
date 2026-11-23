import { Game, type GameDocument } from '../models/game.model';
import type { PlayerDocument } from '../models/player.model';
import * as playerService from './player.service';
import {
  applyGuess,
  CAMPAIGN_BONUS,
  levelById,
  LEVELS,
  newHunt,
  rollSecret,
  scoreFor,
  unlockedByPoints,
  type HuntState,
} from '../domain/gameRules';
import { AppError } from '../errors/AppError';

export async function listFinished(playerId: string): Promise<GameDocument[]> {
  return Game.find({
    playerId,
    status: { $in: ['won', 'lost'] },
  }).sort({ createdAt: -1 }).limit(40);
}

export async function start(input: {
  playerId?: string;
  levelId?: unknown;
}): Promise<{ game: GameDocument; player: PlayerDocument }> {
  const player = await playerService.getById(input.playerId);
  const level = levelById(input.levelId || player.selectedLevelId);
  if (!level) throw new AppError(400, 'Unknown level.');
  if (player.totalPoints < level.pointsToUnlock) {
    throw new AppError(403, 'That level is still locked.');
  }

  const hunt = newHunt(level, rollSecret(level));
  const game = await Game.create({ ...hunt, playerId: player._id });
  player.selectedLevelId = level.id;
  await player.save();
  return { game, player };
}

export async function getById(id: string): Promise<GameDocument> {
  const game = await Game.findById(id);
  if (!game) throw new AppError(404, 'Hunt not found.');
  return game;
}

export async function submitGuess(id: string, value: unknown): Promise<{
  game: GameDocument;
  player: PlayerDocument;
  unlockedLevelIds: number[];
}> {
  const game = await getById(id);
  const player = await playerService.getById(game.playerId);
  const before = player.totalPoints;
  const result = applyGuess(game as unknown as HuntState, Number(value));
  if (result.error) throw new AppError(400, result.error);

  let unlockedLevelIds: number[] = [];
  if (game.status !== 'playing') {
    const level = levelById(game.levelId);
    if (!level) throw new AppError(400, 'Unknown level.');
    if (game.status === 'won') {
      game.pointsEarned = scoreFor(level, game.guesses.length);
      player.totalPoints += game.pointsEarned;
      const lastLevel = LEVELS[LEVELS.length - 1];
      if (level.id === lastLevel.id && !player.campaignCleared) {
        game.campaignBonus = CAMPAIGN_BONUS;
        player.totalPoints += game.campaignBonus;
        player.campaignCleared = true;
      }
    }
    unlockedLevelIds = unlockedByPoints(before, player.totalPoints);
    await player.save();
  }

  game.markModified('guesses');
  await game.save();
  return { game, player, unlockedLevelIds };
}
