import mongoose, { Schema, type HydratedDocument } from 'mongoose';

export type RoomStatus = 'waiting' | 'open' | 'ready' | 'finished' | 'closed';

export interface IRoomPlayer {
  playerId: string;
  name: string;
  squad?: Record<string, unknown> | null;
  ready: boolean;
}

export interface IRoom {
  code: string;
  status: RoomStatus;
  host: IRoomPlayer;
  guest?: IRoomPlayer | null;
  matchResult?: Record<string, unknown> | null;
  createdAt: Date;
  updatedAt: Date;
}

export type RoomDocument = HydratedDocument<IRoom>;

const roomPlayerSchema = new Schema<IRoomPlayer>(
  {
    playerId: { type: String, required: true },
    name: { type: String, required: true, trim: true },
    squad: { type: Schema.Types.Mixed, required: false, default: null },
    ready: { type: Boolean, default: false },
  },
  { _id: false },
);

const roomSchema = new Schema<IRoom>(
  {
    code: { type: String, required: true, unique: true, uppercase: true, trim: true },
    status: {
      type: String,
      enum: ['waiting', 'open', 'ready', 'finished', 'closed'],
      default: 'waiting',
    },
    host: { type: roomPlayerSchema, required: true },
    guest: { type: roomPlayerSchema, required: false, default: null },
    matchResult: { type: Schema.Types.Mixed, required: false, default: null },
  },
  { timestamps: true },
);

roomSchema.index({ createdAt: 1 }, { expireAfterSeconds: 60 * 60 * 6 });

export const Room = mongoose.model<IRoom>('Room', roomSchema);
