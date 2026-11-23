import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { Player, type PlayerDocument } from '../models/player.model';
import { AppError } from '../errors/AppError';
import { JWT_EXPIRES_IN, JWT_SECRET } from '../config/auth';

export interface AuthResult {
  player: PlayerDocument;
  token: string;
}

function normalizeEmail(email: unknown): string {
  return String(email || '').trim().toLowerCase();
}

function normalizeName(name: unknown): string {
  return String(name || '').trim();
}

function assertPassword(password: unknown): string {
  const value = String(password || '');
  if (value.length < 6) {
    throw new AppError(400, 'Password must be at least 6 characters.');
  }
  return value;
}

function assertEmail(email: string): void {
  if (!email || !email.includes('@') || email.length < 5) {
    throw new AppError(400, 'Enter a valid email address.');
  }
}

export function signToken(player: PlayerDocument): string {
  return jwt.sign(
    { sub: String(player._id), email: player.email || null },
    JWT_SECRET,
    { expiresIn: JWT_EXPIRES_IN } as jwt.SignOptions,
  );
}

export async function register(input: {
  email?: unknown;
  password?: unknown;
  name?: unknown;
}): Promise<AuthResult> {
  const email = normalizeEmail(input.email);
  const password = assertPassword(input.password);
  const name = normalizeName(input.name) || email.split('@')[0];
  assertEmail(email);

  const existing = await Player.findOne({ email });
  if (existing) throw new AppError(409, 'That email is already registered.');

  const passwordHash = await bcrypt.hash(password, 10);
  const player = await Player.create({
    email,
    passwordHash,
    name,
  });

  return { player, token: signToken(player) };
}

export async function login(input: {
  email?: unknown;
  password?: unknown;
}): Promise<AuthResult> {
  const email = normalizeEmail(input.email);
  const password = String(input.password || '');
  assertEmail(email);
  if (!password) throw new AppError(400, 'Password is required.');

  const player = await Player.findOne({ email }).select('+passwordHash');
  if (!player || !player.passwordHash) {
    throw new AppError(401, 'Email or password is wrong.');
  }

  const matches = await bcrypt.compare(password, player.passwordHash);
  if (!matches) throw new AppError(401, 'Email or password is wrong.');

  return { player, token: signToken(player) };
}

export async function playerFromToken(token: string): Promise<PlayerDocument> {
  try {
    const payload = jwt.verify(token, JWT_SECRET) as { sub?: string };
    if (!payload.sub) throw new AppError(401, 'Invalid token.');
    const player = await Player.findById(payload.sub);
    if (!player) throw new AppError(401, 'Player not found.');
    return player;
  } catch (error) {
    if (error instanceof AppError) throw error;
    throw new AppError(401, 'Invalid or expired token.');
  }
}

export async function updateProfile(
  player: PlayerDocument,
  input: { name?: unknown },
): Promise<PlayerDocument> {
  if (input.name === undefined) {
    throw new AppError(400, 'Nothing to update.');
  }
  const name = normalizeName(input.name);
  if (!name) throw new AppError(400, 'Name is required.');
  if (name.length > 40) throw new AppError(400, 'Name is too long.');
  player.name = name;
  await player.save();
  return player;
}

export async function changePassword(
  playerId: string,
  input: { currentPassword?: unknown; newPassword?: unknown },
): Promise<void> {
  const currentPassword = String(input.currentPassword || '');
  const newPassword = assertPassword(input.newPassword);
  if (!currentPassword) throw new AppError(400, 'Current password is required.');

  const player = await Player.findById(playerId).select('+passwordHash');
  if (!player || !player.passwordHash) {
    throw new AppError(400, 'Password change is only for registered accounts.');
  }

  const matches = await bcrypt.compare(currentPassword, player.passwordHash);
  if (!matches) throw new AppError(401, 'Current password is wrong.');

  player.passwordHash = await bcrypt.hash(newPassword, 10);
  await player.save();
}
