import type { Request, Response } from 'express';
import * as adminService from '../services/admin.service';
import * as catalogService from '../services/catalog.service';
import { asyncHandler } from '../middleware/asyncHandler';
import { AppError } from '../errors/AppError';

export const login = asyncHandler(async (req: Request, res: Response) => {
  const email = String(req.body?.email ?? '');
  const password = String(req.body?.password ?? '');
  if (!email || !password) {
    throw new AppError(400, 'Email and password are required.');
  }
  res.json(adminService.login(email, password));
});

export const overview = asyncHandler(async (_req: Request, res: Response) => {
  res.json({ overview: adminService.overview() });
});

export const getCatalog = asyncHandler(async (_req: Request, res: Response) => {
  res.json({ catalog: catalogService.getFullCatalog() });
});

export const replaceSportsFacePuzzles = asyncHandler(
  async (req: Request, res: Response) => {
    const puzzles = req.body?.puzzles;
    if (!Array.isArray(puzzles)) {
      throw new AppError(400, 'Body must include a puzzles array.');
    }
    const saved = await catalogService.replaceSportsFacePuzzles(puzzles);
    res.json({ puzzles: saved });
  },
);

export const replaceHubCategories = asyncHandler(
  async (req: Request, res: Response) => {
    const categories = req.body?.categories;
    if (!Array.isArray(categories)) {
      throw new AppError(400, 'Body must include a categories array.');
    }
    const saved = await catalogService.replaceHubCategories(categories);
    res.json({ categories: saved });
  },
);

export const replaceHuntLevels = asyncHandler(
  async (req: Request, res: Response) => {
    const levels = req.body?.levels;
    if (!Array.isArray(levels)) {
      throw new AppError(400, 'Body must include a levels array.');
    }
    const saved = await catalogService.replaceHuntLevels(levels);
    res.json({ levels: saved });
  },
);

export const replaceTrumpConfig = asyncHandler(
  async (req: Request, res: Response) => {
    const config = req.body?.config;
    if (!config || typeof config !== 'object') {
      throw new AppError(400, 'Body must include a config object.');
    }
    const saved = await catalogService.replaceTrumpConfig(config);
    res.json({ config: saved });
  },
);

export const replaceNationalTeams = asyncHandler(
  async (req: Request, res: Response) => {
    const teams = req.body?.teams;
    if (!Array.isArray(teams)) {
      throw new AppError(400, 'Body must include a teams array.');
    }
    const saved = await catalogService.replaceNationalTeams(teams);
    res.json({ teams: saved });
  },
);

export const replaceIplTeams = asyncHandler(
  async (req: Request, res: Response) => {
    const teams = req.body?.teams;
    if (!Array.isArray(teams)) {
      throw new AppError(400, 'Body must include a teams array.');
    }
    const saved = await catalogService.replaceIplTeams(teams);
    res.json({ teams: saved });
  },
);

export const replaceVenues = asyncHandler(
  async (req: Request, res: Response) => {
    const venues = req.body?.venues;
    if (!Array.isArray(venues)) {
      throw new AppError(400, 'Body must include a venues array.');
    }
    const saved = await catalogService.replaceVenues(venues);
    res.json({ venues: saved });
  },
);
