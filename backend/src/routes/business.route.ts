import { Router, type RequestHandler } from 'express';
import { getBusiness, createBusiness, updateBusiness, deleteBusiness } from '../controllers/business.controller';

const router: ReturnType<typeof Router> = Router();

router.get('/:id', getBusiness as RequestHandler);
router.post('/', createBusiness as RequestHandler);
router.put('/:id', updateBusiness as RequestHandler);
router.delete('/:id', deleteBusiness as RequestHandler);

export default router;
