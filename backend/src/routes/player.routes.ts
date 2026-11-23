import { Router } from 'express';
import * as playerController from '../controllers/player.controller';
import * as gameController from '../controllers/game.controller';
import { optionalAuth } from '../middleware/auth';

const router = Router();

router.post('/', playerController.create);
router.get('/:id/games', optionalAuth, gameController.listForPlayer);
router.get('/:id', optionalAuth, playerController.getById);
router.patch('/:id', optionalAuth, playerController.update);

export default router;
