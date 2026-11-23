import { Router } from 'express';
import * as roomController from '../controllers/room.controller';
import { optionalAuth } from '../middleware/auth';

const router = Router();

router.post('/', optionalAuth, roomController.create);
router.post('/join', optionalAuth, roomController.join);
router.get('/:code', optionalAuth, roomController.getByCode);
router.post('/:code/squad', optionalAuth, roomController.submitSquad);
router.post('/:code/ready', optionalAuth, roomController.setReady);
router.post('/:code/match', optionalAuth, roomController.submitMatch);

export default router;
