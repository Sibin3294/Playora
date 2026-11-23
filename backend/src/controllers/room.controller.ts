import * as roomService from '../services/room.service';
import { asyncHandler } from '../middleware/asyncHandler';
import type { AuthedRequest } from '../middleware/auth';
import { AppError } from '../errors/AppError';

function playerIdFrom(req: AuthedRequest): string {
  const id = req.playerId || req.body.playerId || req.query.playerId;
  if (!id || typeof id !== 'string') {
    throw new AppError(400, 'playerId is required.');
  }
  return id;
}

export const create = asyncHandler(async (req: AuthedRequest, res) => {
  const playerId = playerIdFrom(req);
  const room = await roomService.createRoom({
    playerId,
    name: req.body.name,
  });
  res.status(201).json({ room: roomService.toPublicRoom(room, playerId) });
});

export const join = asyncHandler(async (req: AuthedRequest, res) => {
  const playerId = playerIdFrom(req);
  const room = await roomService.joinRoom({
    code: req.body.code,
    playerId,
    name: req.body.name,
  });
  res.json({ room: roomService.toPublicRoom(room, playerId) });
});

export const getByCode = asyncHandler(async (req: AuthedRequest, res) => {
  const playerId = playerIdFrom(req);
  const room = await roomService.getRoom(req.params.code);
  res.json({ room: roomService.toPublicRoom(room, playerId) });
});

export const submitSquad = asyncHandler(async (req: AuthedRequest, res) => {
  const playerId = playerIdFrom(req);
  const room = await roomService.submitSquad({
    code: req.params.code,
    playerId,
    squad: req.body.squad,
  });
  res.json({ room: roomService.toPublicRoom(room, playerId) });
});

export const setReady = asyncHandler(async (req: AuthedRequest, res) => {
  const playerId = playerIdFrom(req);
  const room = await roomService.setReady({
    code: req.params.code,
    playerId,
    ready: req.body.ready,
  });
  res.json({ room: roomService.toPublicRoom(room, playerId) });
});

export const submitMatch = asyncHandler(async (req: AuthedRequest, res) => {
  const playerId = playerIdFrom(req);
  const room = await roomService.submitMatchResult({
    code: req.params.code,
    playerId,
    matchResult: req.body.matchResult,
  });
  res.json({ room: roomService.toPublicRoom(room, playerId) });
});
