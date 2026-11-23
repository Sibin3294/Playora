import { AppError } from '../errors/AppError';
import { Room, type IRoom, type IRoomPlayer, type RoomDocument } from '../models/room.model';

const CODE_ALPHABET = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

function makeCode(): string {
  let code = '';
  for (let i = 0; i < 6; i += 1) {
    code += CODE_ALPHABET[Math.floor(Math.random() * CODE_ALPHABET.length)];
  }
  return code;
}

function displayName(raw?: string | null): string {
  const trimmed = (raw ?? '').trim();
  return trimmed.length > 0 ? trimmed : 'Hunter';
}

function refreshStatus(room: RoomDocument): void {
  if (room.matchResult) {
    room.status = 'finished';
    return;
  }
  if (!room.guest) {
    room.status = 'waiting';
    return;
  }
  const hostReady = Boolean(room.host.squad) && room.host.ready;
  const guestReady = Boolean(room.guest.squad) && room.guest.ready;
  if (hostReady && guestReady) {
    room.status = 'ready';
    return;
  }
  room.status = 'open';
}

export function toPublicRoom(room: IRoom | RoomDocument, viewerPlayerId?: string) {
  const host = room.host;
  const guest = room.guest ?? null;
  const isHost = viewerPlayerId != null && viewerPlayerId === host.playerId;
  const isGuest = viewerPlayerId != null && guest?.playerId === viewerPlayerId;
  return {
    code: room.code,
    status: room.status,
    host: {
      playerId: host.playerId,
      name: host.name,
      hasSquad: Boolean(host.squad),
      ready: host.ready,
    },
    guest: guest
      ? {
          playerId: guest.playerId,
          name: guest.name,
          hasSquad: Boolean(guest.squad),
          ready: guest.ready,
        }
      : null,
    youAreHost: isHost,
    youAreGuest: isGuest,
    bothReady: room.status === 'ready' || room.status === 'finished',
    matchResult: room.matchResult ?? null,
    hostSquad: isHost || room.status === 'finished' || room.status === 'ready' ? host.squad ?? null : null,
    guestSquad:
      isGuest || room.status === 'finished' || room.status === 'ready' ? guest?.squad ?? null : null,
  };
}

async function uniqueCode(): Promise<string> {
  for (let attempt = 0; attempt < 12; attempt += 1) {
    const code = makeCode();
    const existing = await Room.exists({ code });
    if (!existing) return code;
  }
  throw new AppError(500, 'Could not create a room code. Try again.');
}

export async function createRoom(input: {
  playerId: string;
  name?: string;
}): Promise<RoomDocument> {
  if (!input.playerId?.trim()) {
    throw new AppError(400, 'playerId is required.');
  }
  const code = await uniqueCode();
  return Room.create({
    code,
    status: 'waiting',
    host: {
      playerId: input.playerId.trim(),
      name: displayName(input.name),
      squad: null,
      ready: false,
    },
    guest: null,
    matchResult: null,
  });
}

export async function joinRoom(input: {
  code: string;
  playerId: string;
  name?: string;
}): Promise<RoomDocument> {
  const code = (input.code || '').trim().toUpperCase();
  if (!code) throw new AppError(400, 'Room code is required.');
  if (!input.playerId?.trim()) throw new AppError(400, 'playerId is required.');

  const room = await Room.findOne({ code });
  if (!room || room.status === 'closed') {
    throw new AppError(404, 'No room found with that code.');
  }
  if (room.status === 'finished') {
    throw new AppError(409, 'That room already finished.');
  }

  if (room.host.playerId === input.playerId) {
    return room;
  }
  if (room.guest?.playerId === input.playerId) {
    return room;
  }
  if (room.guest) {
    throw new AppError(409, 'That room is already full.');
  }

  room.guest = {
    playerId: input.playerId.trim(),
    name: displayName(input.name),
    squad: null,
    ready: false,
  };
  refreshStatus(room);
  await room.save();
  return room;
}

export async function getRoom(code: string): Promise<RoomDocument> {
  const room = await Room.findOne({ code: code.trim().toUpperCase() });
  if (!room || room.status === 'closed') {
    throw new AppError(404, 'No room found with that code.');
  }
  return room;
}

function seatFor(room: RoomDocument, playerId: string): IRoomPlayer {
  if (room.host.playerId === playerId) return room.host;
  if (room.guest?.playerId === playerId) return room.guest;
  throw new AppError(403, 'You are not in this room.');
}

export async function submitSquad(input: {
  code: string;
  playerId: string;
  squad: Record<string, unknown>;
}): Promise<RoomDocument> {
  const room = await getRoom(input.code);
  if (room.status === 'finished') {
    throw new AppError(409, 'That room already finished.');
  }
  if (!room.guest) {
    throw new AppError(409, 'Wait for an opponent before drafting.');
  }
  const seat = seatFor(room, input.playerId);
  if (!input.squad || typeof input.squad !== 'object') {
    throw new AppError(400, 'squad is required.');
  }
  seat.squad = input.squad;
  seat.ready = false;
  refreshStatus(room);
  await room.save();
  return room;
}

export async function setReady(input: {
  code: string;
  playerId: string;
  ready?: boolean;
}): Promise<RoomDocument> {
  const room = await getRoom(input.code);
  if (room.status === 'finished') {
    throw new AppError(409, 'That room already finished.');
  }
  const seat = seatFor(room, input.playerId);
  if (!seat.squad) {
    throw new AppError(409, 'Draft your XI before ready up.');
  }
  seat.ready = input.ready !== false;
  refreshStatus(room);
  await room.save();
  return room;
}

export async function submitMatchResult(input: {
  code: string;
  playerId: string;
  matchResult: Record<string, unknown>;
}): Promise<RoomDocument> {
  const room = await getRoom(input.code);
  if (room.host.playerId !== input.playerId) {
    throw new AppError(403, 'Only the host can publish the match.');
  }
  if (room.status !== 'ready' && room.status !== 'finished') {
    throw new AppError(409, 'Both players must be ready first.');
  }
  if (!room.host.squad || !room.guest?.squad) {
    throw new AppError(409, 'Both squads are required.');
  }
  if (!input.matchResult || typeof input.matchResult !== 'object') {
    throw new AppError(400, 'matchResult is required.');
  }
  room.matchResult = input.matchResult;
  room.status = 'finished';
  await room.save();
  return room;
}
