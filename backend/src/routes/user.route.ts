import { Router, type RequestHandler } from 'express';
import { getUsers, getUserById, createUser, updateUser, deleteUser, loginUser, validateToken, createToken } from '../controllers/user.controller';
import { authenticateJWT } from '../middlewares/auth.middleware';

const router = Router();

router.get('/', getUsers as RequestHandler);
router.get('/validate', validateToken);
router.get('/:id', getUserById as RequestHandler);
router.post('/', createUser as RequestHandler);
router.put('/:id', updateUser as RequestHandler);
router.delete('/:id', deleteUser as RequestHandler);
router.post('/login', loginUser as RequestHandler);
router.post('/token', createToken as RequestHandler);

export default router;
