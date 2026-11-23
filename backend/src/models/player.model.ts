import mongoose, { Schema, type HydratedDocument } from 'mongoose';

export interface IPlayer {
  deviceId?: string;
  email?: string;
  passwordHash?: string;
  name?: string;
  totalPoints: number;
  campaignCleared: boolean;
  selectedLevelId: number;
  createdAt: Date;
  updatedAt: Date;
}

export type PlayerDocument = HydratedDocument<IPlayer>;

const playerSchema = new Schema<IPlayer>(
  {
    // Omit unset fields so sparse unique indexes allow many account/guest docs.
    deviceId: { type: String, required: false, unique: true, sparse: true },
    email: {
      type: String,
      required: false,
      unique: true,
      sparse: true,
      lowercase: true,
      trim: true,
    },
    passwordHash: { type: String, required: false, select: false },
    name: { type: String, required: false, trim: true },
    totalPoints: { type: Number, default: 0 },
    campaignCleared: { type: Boolean, default: false },
    selectedLevelId: { type: Number, default: 1 },
  },
  { timestamps: true },
);

export const Player = mongoose.model<IPlayer>('Player', playerSchema);
