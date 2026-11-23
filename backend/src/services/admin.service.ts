import jwt from 'jsonwebtoken';
import {
  ADMIN_EMAIL,
  ADMIN_JWT_EXPIRES_IN,
  ADMIN_JWT_SECRET,
  ADMIN_PASSWORD,
} from '../config/admin';
import { AppError } from '../errors/AppError';
import * as catalogService from './catalog.service';

export function login(email: string, password: string) {
  const normalized = email.trim().toLowerCase();
  if (normalized !== ADMIN_EMAIL || password !== ADMIN_PASSWORD) {
    throw new AppError(401, 'Invalid admin email or password.');
  }
  const token = jwt.sign(
    { role: 'admin', email: ADMIN_EMAIL },
    ADMIN_JWT_SECRET,
    { expiresIn: ADMIN_JWT_EXPIRES_IN } as jwt.SignOptions,
  );
  return {
    token,
    admin: {
      email: ADMIN_EMAIL,
      role: 'admin' as const,
    },
  };
}

export function overview() {
  const catalog = catalogService.getFullCatalog() as {
    huntLevels: unknown[];
    nationalTeams: unknown[];
    ipl: { teams: unknown[] };
    venues: unknown[];
    sportsFacePuzzles: unknown[];
    hubCategories: Array<{ games?: unknown[] }>;
    trumpConfig: unknown;
  };

  const gameCount = catalog.hubCategories.reduce(
    (sum, category) => sum + (category.games?.length ?? 0),
    0,
  );

  return {
    counts: {
      categories: catalog.hubCategories.length,
      games: gameCount,
      facePuzzles: catalog.sportsFacePuzzles.length,
      huntLevels: catalog.huntLevels.length,
      nationalTeams: catalog.nationalTeams.length,
      iplTeams: catalog.ipl.teams.length,
      venues: catalog.venues.length,
    },
    adminEmail: ADMIN_EMAIL,
  };
}
