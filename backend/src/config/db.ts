import mongoose from 'mongoose';
import { Player } from '../models/player.model';

const DEFAULT_URI = 'mongodb://127.0.0.1:27017/number_hunter';

export function mongoUri(): string {
  return process.env.MONGODB_URI || DEFAULT_URI;
}

export async function connectDb(): Promise<string> {
  const uri = mongoUri();
  await mongoose.connect(uri);
  // Older guest/account docs stored null for unused ids, which breaks unique sparse indexes.
  await Player.updateMany(
    { $or: [{ deviceId: null }, { deviceId: '' }] },
    { $unset: { deviceId: 1 } },
  );
  await Player.updateMany(
    { $or: [{ email: null }, { email: '' }] },
    { $unset: { email: 1 } },
  );
  await Player.syncIndexes();
  return uri;
}
