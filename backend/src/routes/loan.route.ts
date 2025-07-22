import { Router } from 'express';
import { createLoan, getLoans, getLoanById, updateLoan, deleteLoan } from '../controllers/loan.controller';
import { authMiddleware } from '../middlewares/auth.middleware';

const router = Router();

router.post('/', authMiddleware, createLoan);
router.get('/', authMiddleware, getLoans);
router.get('/:id', authMiddleware, getLoanById);
router.patch('/:id', authMiddleware, updateLoan);
router.delete('/:id', authMiddleware, deleteLoan);

export default router; 