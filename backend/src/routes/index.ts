import { Router } from 'express';
import * as healthController from '../controllers/health.controller';
import authRoutes from './auth.routes';
import playerRoutes from './player.routes';
import gameRoutes from './game.routes';
import roomRoutes from './room.routes';
import catalogRoutes from './catalog.routes';
import adminRoutes from './admin.routes';

const router = Router();

router.get('/health', healthController.get);
router.use('/api/auth', authRoutes);
router.use('/api/players', playerRoutes);
router.use('/api/games', gameRoutes);
router.use('/api/rooms', roomRoutes);
router.use('/api/catalog', catalogRoutes);
router.use('/api/admin', adminRoutes);

export default router;
