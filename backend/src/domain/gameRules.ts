import { existsSync, readFileSync } from 'fs';
import { join } from 'path';

export const CAMPAIGN_BONUS = 250;

export type GameStatus = 'playing' | 'won' | 'lost';
export type Direction = 'correct' | 'tooLow' | 'tooHigh';
export type Heat = 'scorching' | 'hot' | 'warm' | 'chilly' | 'ice';

export interface Level {
  id: number;
  name: string;
  minValue: number;
  maxValue: number;
  maxAttempts: number;
  pointsToUnlock: number;
  multiplier: number;
}

export interface Guess {
  value: number;
  direction: Direction;
  heat: Heat;
}

export interface HuntState {
  _id?: unknown;
  id?: unknown;
  levelId: number;
  secretNumber: number;
  minValue: number;
  maxValue: number;
  maxAttempts: number;
  lowBound: number;
  highBound: number;
  guesses: Guess[];
  status: GameStatus;
  pointsEarned: number;
  campaignBonus: number;
  createdAt?: Date | null;
}

export interface PublicGame {
  id: string;
  levelId: number;
  minValue: number;
  maxValue: number;
  maxAttempts: number;
  lowBound: number;
  highBound: number;
  status: GameStatus;
  guesses: Guess[];
  hints: string[];
  attemptsUsed: number;
  attemptsLeft: number;
  pointsEarned: number;
  campaignBonus: number;
  secretNumber: number | null;
  closestDistance: number | null;
  createdAt: Date | null;
}

export interface PublicPlayer {
  id: string;
  totalPoints: number;
  campaignCleared: boolean;
  selectedLevelId: number;
  email: string | null;
  name: string | null;
  isGuest: boolean;
}

function loadLevelsFromCatalog(): Level[] {
  const candidates = [
    join(__dirname, '../catalog/data/hunt_levels.json'),
    join(process.cwd(), 'src/catalog/data/hunt_levels.json'),
    join(process.cwd(), 'dist/catalog/data/hunt_levels.json'),
  ];
  for (const file of candidates) {
    if (!existsSync(file)) continue;
    const rows = JSON.parse(readFileSync(file, 'utf8')) as Array<Record<string, unknown>>;
    return rows.map((row) => ({
      id: Number(row.id),
      name: String(row.name),
      minValue: Number(row.minValue),
      maxValue: Number(row.maxValue),
      maxAttempts: Number(row.maxAttempts),
      pointsToUnlock: Number(row.pointsToUnlock ?? 0),
      multiplier: Number(row.multiplier ?? 1),
    }));
  }
  return [
    { id: 1, name: 'SCOUT', minValue: 1, maxValue: 50, maxAttempts: 10, pointsToUnlock: 0, multiplier: 1 },
    { id: 2, name: 'HUNTER', minValue: 1, maxValue: 100, maxAttempts: 12, pointsToUnlock: 70, multiplier: 1.25 },
    { id: 3, name: 'RANGER', minValue: 1, maxValue: 250, maxAttempts: 12, pointsToUnlock: 180, multiplier: 1.5 },
    { id: 4, name: 'ACE', minValue: 1, maxValue: 500, maxAttempts: 12, pointsToUnlock: 360, multiplier: 2 },
    { id: 5, name: 'PHANTOM', minValue: 1, maxValue: 1000, maxAttempts: 12, pointsToUnlock: 650, multiplier: 2.5 },
  ];
}

export const LEVELS: Level[] = loadLevelsFromCatalog();

export function levelById(id: unknown): Level | null {
  return LEVELS.find((level) => level.id === Number(id)) || null;
}

function clamp(value: number, low: number, high: number): number {
  return Math.min(high, Math.max(low, value));
}

export function scoreFor(level: Level, attemptsUsed: number): number {
  const leftover = level.maxAttempts - attemptsUsed + 1;
  let points = leftover * 10 * level.multiplier;
  if (attemptsUsed === 1) {
    points += 50 * level.multiplier;
  } else if (attemptsUsed <= 3) {
    points += 20 * level.multiplier;
  }
  return Math.round(points);
}

function heatFor(guess: number, secret: number, minValue: number, maxValue: number): Heat {
  const distance = Math.abs(guess - secret);
  const span = Math.max(1, maxValue - minValue);
  const pct = distance / span;
  if (distance <= 2 || pct <= 0.02) return 'scorching';
  if (pct <= 0.06) return 'hot';
  if (pct <= 0.12) return 'warm';
  if (pct <= 0.25) return 'chilly';
  return 'ice';
}

function failedGuesses(guesses: Guess[]): number {
  return guesses.filter((guess) => guess.direction !== 'correct').length;
}

export function hintsFor(state: HuntState): string[] {
  const failed = failedGuesses(state.guesses);
  if (failed < 3) return [];
  const hints = [
    state.secretNumber % 2 === 0
      ? 'The number is even.'
      : 'The number is odd.',
  ];
  if (failed >= 6) {
    const window = Math.max(8, Math.floor((state.maxValue - state.minValue) / 8));
    const start = clamp(state.secretNumber - window, state.lowBound, state.highBound);
    const end = clamp(state.secretNumber + window, state.lowBound, state.highBound);
    hints.push(`It sits between ${start} and ${end}.`);
  }
  if (failed >= 9) {
    if (state.secretNumber < 10) {
      hints.push('It is a single-digit number.');
    } else if (state.secretNumber < 100) {
      hints.push(`It starts with ${Math.floor(state.secretNumber / 10)}.`);
    } else {
      hints.push(`It starts with ${String(state.secretNumber)[0]}.`);
    }
  }
  return hints;
}

function closestDistance(state: HuntState): number {
  if (!state.guesses.length) return state.maxValue;
  return state.guesses.reduce((best, guess) => {
    const distance = Math.abs(guess.value - state.secretNumber);
    return Math.min(best, distance);
  }, state.maxValue);
}

export function newHunt(level: Level, secretNumber: number): HuntState {
  return {
    levelId: level.id,
    secretNumber,
    minValue: level.minValue,
    maxValue: level.maxValue,
    maxAttempts: level.maxAttempts,
    lowBound: level.minValue,
    highBound: level.maxValue,
    guesses: [],
    status: 'playing',
    pointsEarned: 0,
    campaignBonus: 0,
  };
}

export function rollSecret(level: Level, random: () => number = Math.random): number {
  const span = level.maxValue - level.minValue + 1;
  return level.minValue + Math.floor(random() * span);
}

export function applyGuess(state: HuntState, guess: number): { error: string | null } {
  if (state.status !== 'playing') {
    return { error: 'This hunt is over. Play again!' };
  }
  if (!Number.isInteger(guess) || guess < state.minValue || guess > state.maxValue) {
    return { error: `Pick a number from ${state.minValue} to ${state.maxValue}.` };
  }
  if (state.guesses.some((item) => item.value === guess)) {
    return { error: 'You already tried that number.' };
  }

  const direction: Direction = guess === state.secretNumber
    ? 'correct'
    : (guess < state.secretNumber ? 'tooLow' : 'tooHigh');

  if (direction === 'tooLow') {
    state.lowBound = Math.max(state.lowBound, guess + 1);
  } else if (direction === 'tooHigh') {
    state.highBound = Math.min(state.highBound, guess - 1);
  }

  state.guesses.push({
    value: guess,
    direction,
    heat: heatFor(guess, state.secretNumber, state.minValue, state.maxValue),
  });

  if (direction === 'correct') {
    state.status = 'won';
  } else if (state.guesses.length >= state.maxAttempts) {
    state.status = 'lost';
  }

  return { error: null };
}

export function unlockedByPoints(before: number, after: number): number[] {
  return LEVELS
    .filter((level) => before < level.pointsToUnlock && after >= level.pointsToUnlock)
    .map((level) => level.id);
}

export function toPublicGame(game: HuntState): PublicGame {
  const finished = game.status !== 'playing';
  return {
    id: String(game._id || game.id || ''),
    levelId: game.levelId,
    minValue: game.minValue,
    maxValue: game.maxValue,
    maxAttempts: game.maxAttempts,
    lowBound: game.lowBound,
    highBound: game.highBound,
    status: game.status,
    guesses: game.guesses.map((guess) => ({
      value: guess.value,
      direction: guess.direction,
      heat: guess.heat,
    })),
    hints: hintsFor(game),
    attemptsUsed: game.guesses.length,
    attemptsLeft: game.maxAttempts - game.guesses.length,
    pointsEarned: game.pointsEarned || 0,
    campaignBonus: game.campaignBonus || 0,
    secretNumber: finished ? game.secretNumber : null,
    closestDistance: finished ? closestDistance(game) : null,
    createdAt: game.createdAt || null,
  };
}

export function toPublicPlayer(player: {
  _id: unknown;
  totalPoints: number;
  campaignCleared: boolean;
  selectedLevelId: number;
  email?: string | null;
  name?: string | null;
}): PublicPlayer {
  const email = player.email || null;
  return {
    id: String(player._id),
    totalPoints: player.totalPoints,
    campaignCleared: player.campaignCleared,
    selectedLevelId: player.selectedLevelId,
    email,
    name: player.name || null,
    isGuest: !email,
  };
}
