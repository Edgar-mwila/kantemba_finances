import { Router, type RequestHandler } from 'express';
import { 
    createPayable, 
    getPayables, 
    getPayableById, 
    updatePayable, 
    deletePayable,
    addPayablePayment,
    getPayablePayments
} from '../controllers/payable.controller';
import { authenticateJWT } from '../middlewares/auth.middleware';

const router = Router();

// Apply authentication middleware to all routes
router.use(authenticateJWT as RequestHandler);

// Main payable routes
router.post('/', createPayable as RequestHandler);
router.get('/', getPayables as RequestHandler);
router.get('/:id', getPayableById as RequestHandler);
router.patch('/:id', updatePayable as RequestHandler);
router.delete('/:id', deletePayable as RequestHandler);

// Payment management routes
router.post('/:id/payments', addPayablePayment as RequestHandler);
router.get('/:id/payments', getPayablePayments as RequestHandler);

export default router;