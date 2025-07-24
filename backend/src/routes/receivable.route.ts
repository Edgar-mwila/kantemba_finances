import { Router, type RequestHandler } from 'express';
import { 
    createReceivable, 
    getReceivables, 
    getReceivableById, 
    updateReceivable, 
    deleteReceivable,
    addReceivablePayment,
    getReceivablePayments
} from '../controllers/receivable.controller';
import { authenticateJWT } from '../middlewares/auth.middleware';

const router = Router();

// Apply authentication middleware to all routes
router.use(authenticateJWT as RequestHandler);

// Main receivable routes
router.post('/', createReceivable as RequestHandler);
router.get('/', getReceivables as RequestHandler);
router.get('/:id', getReceivableById as RequestHandler);
router.patch('/:id', updateReceivable as RequestHandler);
router.delete('/:id', deleteReceivable as RequestHandler);

// Payment management routes
router.post('/:id/payments', addReceivablePayment as RequestHandler);
router.get('/:id/payments', getReceivablePayments as RequestHandler);

export default router;