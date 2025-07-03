import { Router, type RequestHandler } from 'express';
import { getSaleItems, getSaleItemById, createSaleItem, updateSaleItem, deleteSaleItem } from '../controllers/sale_item.controller';

const router = Router();

router.get('/', getSaleItems as RequestHandler);
router.get('/:id', getSaleItemById as RequestHandler);
router.post('/', createSaleItem as RequestHandler);
router.put('/:id', updateSaleItem as RequestHandler);
router.delete('/:id', deleteSaleItem as RequestHandler);

export default router; 