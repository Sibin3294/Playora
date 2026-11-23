import mongoose, { Schema, Types, type HydratedDocument } from 'mongoose';
import type { GameStatus, Guess } from '../domain/gameRules';

export interface IGame {
  playerId: Types.ObjectId;
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
  createdAt: Date;
  updatedAt: Date;
}

export type GameDocument = HydratedDocument<IGame>;

const guessSchema = new Schema<Guess>(
  {
    value: { type: Number, required: true },
    direction: { type: String, required: true },
    heat: { type: String, required: true },
  },
  { _id: false },
);

const gameSchema = new Schema<IGame>(
  {
    playerId: { type: Schema.Types.ObjectId, ref: 'Player', required: true, index: true },
    levelId: { type: Number, required: true },
    secretNumber: { type: Number, required: true },
    minValue: { type: Number, required: true },
    maxValue: { type: Number, required: true },
    maxAttempts: { type: Number, required: true },
    lowBound: { type: Number, required: true },
    highBound: { type: Number, required: true },
    guesses: { type: [guessSchema], default: [] },
    status: { type: String, default: 'playing' },
    pointsEarned: { type: Number, default: 0 },
    campaignBonus: { type: Number, default: 0 },
  },
  { timestamps: true },
);

export const Game = mongoose.model<IGame>('Game', gameSchema);
