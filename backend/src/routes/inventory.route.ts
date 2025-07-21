import { Router, type RequestHandler } from 'express';
import { getInventory, getInventoryByBarcode, getInventoryItemById, createInventoryItem, updateInventoryItem, deleteInventoryItem } from '../controllers/inventory.controller';
import { authenticateJWT } from '../middlewares/auth.middleware';

const router = Router();

router.use(authenticateJWT as RequestHandler);
router.get('/', getInventory as RequestHandler);
router.get('/barcode/:barcode', getInventoryByBarcode as RequestHandler);
router.get('/:id', getInventoryItemById as RequestHandler);
router.post('/', createInventoryItem as RequestHandler);
router.put('/:id', updateInventoryItem as RequestHandler);
router.delete('/:id', deleteInventoryItem as RequestHandler);

export default router;
