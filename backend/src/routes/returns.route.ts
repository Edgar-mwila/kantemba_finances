import { Router, type RequestHandler } from 'express';
import {
  createReturn,
  getReturns,
  getReturnById,
  getReturnsBySale,
  approveReturn,
  rejectReturn,
  completeReturn,
  deleteReturn,
} from '../controllers/returns.controller';
import { authenticateJWT } from '../middlewares/auth.middleware';

const router = Router();

router.use(authenticateJWT as RequestHandler);

// Create a new return
router.post('/', createReturn as RequestHandler);

// Get all returns (with optional filtering by business and shop)
router.get('/', getReturns as RequestHandler);

// Get a specific return by ID
router.get('/:id', getReturnById as RequestHandler);

// Get all returns for a specific sale
router.get('/sale/:saleId', getReturnsBySale as RequestHandler);

// Approve a return
router.put('/:id/approve', approveReturn as RequestHandler);

// Reject a return
router.put('/:id/reject', rejectReturn as RequestHandler);

// Complete a return
router.put('/:id/complete', completeReturn as RequestHandler);

// Delete a return (only pending returns)
router.delete('/:id', deleteReturn as RequestHandler);

export default router;