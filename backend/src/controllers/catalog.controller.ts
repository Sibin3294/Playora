import * as catalogService from '../services/catalog.service';
import { asyncHandler } from '../middleware/asyncHandler';

export const getAll = asyncHandler(async (_req, res) => {
  res.json({ catalog: catalogService.getFullCatalog() });
});

export const getHuntLevels = asyncHandler(async (_req, res) => {
  res.json({ levels: catalogService.getHuntLevels() });
});

export const getNationalTeams = asyncHandler(async (_req, res) => {
  res.json({ teams: catalogService.getNationalTeams() });
});

export const getIpl = asyncHandler(async (_req, res) => {
  res.json(catalogService.getIplCatalog());
});

export const getVenues = asyncHandler(async (_req, res) => {
  res.json({ venues: catalogService.getVenues() });
});

export const getSportsFacePuzzles = asyncHandler(async (_req, res) => {
  res.json({ puzzles: catalogService.getSportsFacePuzzles() });
});

export const getHubCategories = asyncHandler(async (_req, res) => {
  res.json({ categories: catalogService.getHubCategories() });
});

export const getTrumpConfig = asyncHandler(async (_req, res) => {
  res.json({ config: catalogService.getTrumpConfig() });
});
