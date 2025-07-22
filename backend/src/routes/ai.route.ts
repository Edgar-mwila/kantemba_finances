import { Router, type RequestHandler } from 'express';
import { analyzeReport } from '../controllers/ai.controller';
import { authenticateJWT } from '../middlewares/auth.middleware';

const router = Router();

router.use(authenticateJWT as RequestHandler);
router.post('/analysis', analyzeReport as RequestHandler);

export default router; 