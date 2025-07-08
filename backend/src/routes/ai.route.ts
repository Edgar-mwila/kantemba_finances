import { Router, type RequestHandler } from 'express';
import { analyzeReport } from '../controllers/ai.controller';

const router: ReturnType<typeof Router> = Router();

router.post('/analysis', analyzeReport as RequestHandler);

export default router; 