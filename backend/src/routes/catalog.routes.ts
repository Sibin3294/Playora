import { Router } from 'express';
import * as catalogController from '../controllers/catalog.controller';

const router = Router();

router.get('/', catalogController.getAll);
router.get('/hunt-levels', catalogController.getHuntLevels);
router.get('/cricket/national-teams', catalogController.getNationalTeams);
router.get('/cricket/ipl', catalogController.getIpl);
router.get('/cricket/venues', catalogController.getVenues);
router.get('/puzzles/sports-faces', catalogController.getSportsFacePuzzles);
router.get('/hub-categories', catalogController.getHubCategories);
router.get('/trump/config', catalogController.getTrumpConfig);

export default router;
