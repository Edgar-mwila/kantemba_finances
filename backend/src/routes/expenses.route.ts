import { Router, type RequestHandler } from 'express';
import { getExpenses, getExpenseById, createExpense, updateExpense, deleteExpense } from '../controllers/expenses.controller';
import { authenticateJWT } from '../middlewares/auth.middleware';

const router = Router();

router.use(authenticateJWT as RequestHandler);
router.get('/', getExpenses as RequestHandler);
router.get('/:id', getExpenseById as RequestHandler);
router.post('/', createExpense as RequestHandler);
router.put('/:id', updateExpense as RequestHandler);
router.delete('/:id', deleteExpense as RequestHandler);

export default router;
