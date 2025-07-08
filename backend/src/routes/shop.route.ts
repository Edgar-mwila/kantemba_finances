import { Router, type RequestHandler } from 'express';
import { getShops, getShopById, createShop, updateShop, deleteShop } from '../controllers/shop.controller';
import { authenticateJWT } from '../middlewares/auth.middleware';

const router = Router();

// router.use(authenticateJWT as RequestHandler);
router.get('/', getShops as RequestHandler);
router.get('/:id', getShopById as RequestHandler);
router.post('/', createShop as RequestHandler);
router.put('/:id', updateShop as RequestHandler);
router.delete('/:id', deleteShop as RequestHandler);

export default router;
