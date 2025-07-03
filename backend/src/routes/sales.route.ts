import { Router, type RequestHandler } from 'express';
import { getSales, getSaleById, createSale, updateSale, deleteSale } from '../controllers/sales.controller';
import { authenticateJWT } from '../middlewares/auth.middleware';

const router = Router();

router.use(authenticateJWT as RequestHandler);
router.get('/', getSales as RequestHandler);
router.get('/:id', getSaleById as RequestHandler);
router.post('/', createSale as RequestHandler);
router.put('/:id', updateSale as RequestHandler);
router.delete('/:id', deleteSale as RequestHandler);

export default router;
