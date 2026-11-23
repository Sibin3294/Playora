import type { Request } from 'express';
import jwt from 'jsonwebtoken';
import { ADMIN_JWT_SECRET } from '../config/admin';
import { AppError } from '../errors/AppError';
import { asyncHandler } from './asyncHandler';

export type AdminRequest = Request & {
  adminEmail?: string;
};

function readBearer(req: Request): string | null {
  const header = req.headers.authorization;
  if (!header) return null;
  const [type, token] = header.split(' ');
  if (type !== 'Bearer' || !token) return null;
  return token;
}

export const requireAdmin = asyncHandler(async (req: AdminRequest, _res, next) => {
  const token = readBearer(req);
  if (!token) throw new AppError(401, 'Admin login required.');
  try {
    const payload = jwt.verify(token, ADMIN_JWT_SECRET) as {
      role?: string;
      email?: string;
    };
    if (payload.role !== 'admin' || !payload.email) {
      throw new AppError(401, 'Invalid admin token.');
    }
    req.adminEmail = payload.email;
    next();
  } catch (error) {
    if (error instanceof AppError) throw error;
    throw new AppError(401, 'Invalid or expired admin token.');
  }
});
