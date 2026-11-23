import { Player, type PlayerDocument } from '../models/player.model';
import { levelById } from '../domain/gameRules';
import { AppError } from '../errors/AppError';

export async function findOrCreate(deviceId: unknown): Promise<PlayerDocument> {
  const id = String(deviceId || '').trim();
  if (!id) throw new AppError(400, 'deviceId is required.');

  let player = await Player.findOne({ deviceId: id });
  if (!player) {
    player = await Player.create({ deviceId: id });
  }
  return player;
}

export async function getById(id: unknown): Promise<PlayerDocument> {
  const player = await Player.findById(id);
  if (!player) throw new AppError(404, 'Player not found.');
  return player;
}

export async function selectLevel(id: string, selectedLevelId: unknown): Promise<PlayerDocument> {
  return updatePlayer(id, { selectedLevelId });
}

export async function updatePlayer(
  id: string,
  input: { selectedLevelId?: unknown; name?: unknown },
): Promise<PlayerDocument> {
  const player = await getById(id);
  let changed = false;

  if (input.name !== undefined) {
    const name = String(input.name || '').trim();
    if (!name) throw new AppError(400, 'Name is required.');
    if (name.length > 40) throw new AppError(400, 'Name is too long.');
    player.name = name;
    changed = true;
  }

  if (input.selectedLevelId !== undefined) {
    const level = levelById(input.selectedLevelId);
    if (!level) throw new AppError(400, 'Unknown level.');
    if (player.totalPoints < level.pointsToUnlock) {
      throw new AppError(403, 'That level is still locked.');
    }
    player.selectedLevelId = level.id;
    changed = true;
  }

  if (!changed) throw new AppError(400, 'Nothing to update.');
  await player.save();
  return player;
}
