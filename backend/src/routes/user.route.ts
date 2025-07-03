import { Router, type RequestHandler } from 'express';
import { getUsers, getUserById, createUser, updateUser, deleteUser, loginUser } from '../controllers/user.controller';

const router = Router();

router.get('/', getUsers as RequestHandler);
router.get('/:id', getUserById as RequestHandler);
router.post('/', createUser as RequestHandler);
router.put('/:id', updateUser as RequestHandler);
router.delete('/:id', deleteUser as RequestHandler);
router.post('/login', loginUser as RequestHandler);

export default router;
