import { Router } from 'express';
import { createPayable, getPayables, getPayableById, updatePayable, deletePayable } from '../controllers/payable.controller';
import { authMiddleware } from '../middlewares/auth.middleware';

const router = Router();

router.post('/', authMiddleware, createPayable);
router.get('/', authMiddleware, getPayables);
router.get('/:id', authMiddleware, getPayableById);
router.patch('/:id', authMiddleware, updatePayable);
router.delete('/:id', authMiddleware, deletePayable);

export default router; 