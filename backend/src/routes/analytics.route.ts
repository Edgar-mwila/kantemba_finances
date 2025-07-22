import { Router } from 'express';
import { logAnalytics, getRecentEvents, getFeatureUsage, getErrors, getReviews } from '../controllers/analytics.controller';

const router = Router();

router.post('/', logAnalytics);
router.get('/events', getRecentEvents);
router.get('/usage', getFeatureUsage);
router.get('/errors', getErrors);
router.get('/reviews', getReviews);

export default router; 