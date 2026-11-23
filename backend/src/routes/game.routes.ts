import { Router } from 'express';
import * as gameController from '../controllers/game.controller';
import { optionalAuth } from '../middleware/auth';

const router = Router();

router.post('/', optionalAuth, gameController.create);
router.get('/:id', optionalAuth, gameController.getById);
router.post('/:id/guesses', optionalAuth, gameController.guess);

export default router;
