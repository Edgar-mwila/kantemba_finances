import { Router } from 'express';
import { createReceivable, getReceivables, getReceivableById, updateReceivable, deleteReceivable } from '../controllers/receivable.controller';
import { authMiddleware } from '../middlewares/auth.middleware';

const router = Router();

router.post('/', authMiddleware, createReceivable);
router.get('/', authMiddleware, getReceivables);
router.get('/:id', authMiddleware, getReceivableById);
router.patch('/:id', authMiddleware, updateReceivable);
router.delete('/:id', authMiddleware, deleteReceivable);

export default router; 