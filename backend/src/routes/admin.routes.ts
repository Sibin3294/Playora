import { Router } from 'express';
import * as adminController from '../controllers/admin.controller';
import { requireAdmin } from '../middleware/adminAuth';

const router = Router();

router.post('/login', adminController.login);

router.use(requireAdmin);
router.get('/overview', adminController.overview);
router.get('/catalog', adminController.getCatalog);
router.put('/catalog/sports-face-puzzles', adminController.replaceSportsFacePuzzles);
router.put('/catalog/hub-categories', adminController.replaceHubCategories);
router.put('/catalog/hunt-levels', adminController.replaceHuntLevels);
router.put('/catalog/trump-config', adminController.replaceTrumpConfig);
router.put('/catalog/national-teams', adminController.replaceNationalTeams);
router.put('/catalog/ipl-teams', adminController.replaceIplTeams);
router.put('/catalog/venues', adminController.replaceVenues);

export default router;
