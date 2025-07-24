import { Router, type RequestHandler } from 'express';
import { 
    createLoan, 
    getLoans, 
    getLoanById, 
    updateLoan, 
    deleteLoan,
    addLoanPayment,
    getLoanPayments
} from '../controllers/loan.controller';
import { authenticateJWT } from '../middlewares/auth.middleware';

const router = Router();

// Apply authentication middleware to all routes
router.use(authenticateJWT as RequestHandler);

// Main loan routes
router.post('/', createLoan as RequestHandler);
router.get('/', getLoans as RequestHandler);
router.get('/:id', getLoanById as RequestHandler);
router.patch('/:id', updateLoan as RequestHandler);
router.delete('/:id', deleteLoan as RequestHandler);

// Payment management routes
router.post('/:id/payments', addLoanPayment as RequestHandler);
router.get('/:id/payments', getLoanPayments as RequestHandler);

export default router;