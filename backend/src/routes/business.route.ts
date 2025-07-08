import { Router, type RequestHandler } from 'express';
import { getBusiness, createBusiness, updateBusiness, deleteBusiness, flutterwaveWebhook } from '../controllers/business.controller';

const router: ReturnType<typeof Router> = Router();

router.get('/:id', getBusiness as RequestHandler);
router.post('/', createBusiness as RequestHandler);
router.put('/:id', updateBusiness as RequestHandler);
router.delete('/:id', deleteBusiness as RequestHandler);

// Flutterwave webhook for payment notifications
router.post('/webhook/flutterwave', flutterwaveWebhook as RequestHandler);

export default router;
