import { existsSync, readFileSync, writeFileSync } from 'fs';
import { join } from 'path';
import mongoose from 'mongoose';
import { CatalogDocument } from '../models/catalog.model';

function resolveDataDir(): string {
  const candidates = [
    join(__dirname, '../catalog/data'),
    join(process.cwd(), 'src/catalog/data'),
    join(process.cwd(), 'dist/catalog/data'),
  ];
  for (const candidate of candidates) {
    if (existsSync(candidate)) return candidate;
  }
  throw new Error('Catalog data directory not found.');
}

function loadJson<T>(fileName: string): T {
  const raw = readFileSync(join(resolveDataDir(), fileName), 'utf8');
  return JSON.parse(raw) as T;
}

function saveJsonBestEffort(fileName: string, value: unknown): void {
  try {
    const path = join(resolveDataDir(), fileName);
    writeFileSync(path, `${JSON.stringify(value, null, 2)}\n`, 'utf8');
  } catch (error) {
    // Ephemeral hosts (e.g. Render without a disk) can't persist files.
    console.warn(`Catalog file write skipped for ${fileName}:`, error);
  }
}

type CatalogCache = {
  huntLevels: unknown;
  nationalTeams: unknown;
  iplTeams: unknown;
  iplCompetition: unknown;
  venues: unknown;
  sportsFacePuzzles: unknown;
  hubCategories: unknown;
  trumpConfig: unknown;
};

const FILE_BY_KEY: Record<keyof CatalogCache, string> = {
  huntLevels: 'hunt_levels.json',
  nationalTeams: 'national_teams.json',
  iplTeams: 'ipl_teams.json',
  iplCompetition: 'ipl_competition.json',
  venues: 'venues.json',
  sportsFacePuzzles: 'sports_face_puzzles.json',
  hubCategories: 'hub_categories.json',
  trumpConfig: 'trump_config.json',
};

let cache: CatalogCache | null = null;

function mongoReady(): boolean {
  return mongoose.connection.readyState === 1;
}

function ensureCache(): CatalogCache {
  if (cache) return cache;
  cache = {
    huntLevels: loadJson('hunt_levels.json'),
    nationalTeams: loadJson('national_teams.json'),
    iplTeams: loadJson('ipl_teams.json'),
    iplCompetition: loadJson('ipl_competition.json'),
    venues: loadJson('venues.json'),
    sportsFacePuzzles: loadJson('sports_face_puzzles.json'),
    hubCategories: loadJson('hub_categories.json'),
    trumpConfig: loadJson('trump_config.json'),
  };
  return cache;
}

async function persistKey(key: keyof CatalogCache, value: unknown): Promise<void> {
  ensureCache()[key] = value;
  saveJsonBestEffort(FILE_BY_KEY[key], value);
  if (!mongoReady()) return;
  await CatalogDocument.findOneAndUpdate(
    { key },
    { key, data: value },
    { upsert: true, new: true, setDefaultsOnInsert: true },
  );
}

/** Overlay Mongo-published catalog docs onto the JSON seed cache. */
export async function hydrateCatalogFromMongo(): Promise<void> {
  if (!mongoReady()) return;
  const docs = await CatalogDocument.find({}).lean();
  if (!docs.length) return;
  const c = ensureCache();
  for (const doc of docs) {
    const key = doc.key as keyof CatalogCache;
    if (key in FILE_BY_KEY) {
      c[key] = doc.data;
    }
  }
}

export function reloadCatalogCache(): void {
  cache = null;
  ensureCache();
}

export function getHuntLevels() {
  return ensureCache().huntLevels;
}

export function getNationalTeams() {
  return ensureCache().nationalTeams;
}

export function getIplCatalog() {
  const c = ensureCache();
  return {
    competition: c.iplCompetition,
    teams: c.iplTeams,
  };
}

export function getVenues() {
  return ensureCache().venues;
}

export function getSportsFacePuzzles() {
  return ensureCache().sportsFacePuzzles;
}

export function getHubCategories() {
  return ensureCache().hubCategories;
}

export function getTrumpConfig() {
  return ensureCache().trumpConfig;
}

export function getFullCatalog() {
  const c = ensureCache();
  return {
    huntLevels: c.huntLevels,
    nationalTeams: c.nationalTeams,
    ipl: {
      competition: c.iplCompetition,
      teams: c.iplTeams,
    },
    venues: c.venues,
    sportsFacePuzzles: c.sportsFacePuzzles,
    hubCategories: c.hubCategories,
    trumpConfig: c.trumpConfig,
  };
}

export async function replaceSportsFacePuzzles(puzzles: unknown) {
  await persistKey('sportsFacePuzzles', puzzles);
  return puzzles;
}

export async function replaceHubCategories(categories: unknown) {
  await persistKey('hubCategories', categories);
  return categories;
}

export async function replaceHuntLevels(levels: unknown) {
  await persistKey('huntLevels', levels);
  return levels;
}

export async function replaceTrumpConfig(config: unknown) {
  await persistKey('trumpConfig', config);
  return config;
}

export async function replaceNationalTeams(teams: unknown) {
  await persistKey('nationalTeams', teams);
  return teams;
}

export async function replaceIplTeams(teams: unknown) {
  await persistKey('iplTeams', teams);
  return teams;
}

export async function replaceIplCompetition(competition: unknown) {
  await persistKey('iplCompetition', competition);
  return competition;
}

export async function replaceVenues(venues: unknown) {
  await persistKey('venues', venues);
  return venues;
}
