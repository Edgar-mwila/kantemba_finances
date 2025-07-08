import type { Request, Response } from 'express';
import { User } from '../models/user.model';
import bcrypt from 'bcryptjs';
import { signToken } from '../utils/jwt';

export const getUsers = async (req: Request, res: Response) => {
  console.log('[GET] /users', req.query);
  try {
    const { businessId } = req.query;
    if (!businessId) return res.status(400).json({ message: 'businessId required' });
    const users = await User.findAll({ where: { businessId: businessId as string } });
    console.log('Users found:', users.map(u => u.toJSON()));
    res.json(users);
  } catch (err) {
    console.error('Server error:', err);
    res.status(500).json({ message: 'Server error', error: err });
  }
};

export const getUserById = async (req: Request, res: Response) => {
  console.log('[GET] /users/:id', req.params);
  try {
    const { id } = req.params;
    const user = await User.findByPk(id);
    if (!user) {
      console.log('User not found');
      return res.status(404).json({ message: 'User not found' });
    }
    console.log('User found:', user.toJSON());
    res.json(user);
  } catch (err) {
    console.error('Server error:', err);
    res.status(500).json({ message: 'Server error', error: err });
  }
};

export const createUser = async (req: Request, res: Response) => {
  console.log('[POST] /users', req.body);
  try {
    const { password, ...rest } = req.body;
    const hash = await bcrypt.hash(password, 10);
    const user = await User.create({ ...rest, password: hash });
    console.log('User created:', user.toJSON());
    res.status(201).json(user);
  } catch (err) {
    console.error('Error creating user:', err);
    res.status(400).json({ message: 'Error creating user', error: err });
  }
};

export const updateUser = async (req: Request, res: Response) => {
  console.log('[PUT] /users/:id', req.params, req.body);
  try {
    const { id } = req.params;
    const { password, ...rest } = req.body;
    let updateData = rest;
    if (password) {
      updateData = { ...rest, password: await bcrypt.hash(password, 10) };
    }
    const [updated] = await User.update(updateData, { where: { id } });
    if (!updated) {
      console.log('User not found');
      return res.status(404).json({ message: 'User not found' });
    }
    const user = await User.findByPk(id);
    console.log('User updated:', user?.toJSON());
    res.json(user);
  } catch (err) {
    console.error('Error updating user:', err);
    res.status(400).json({ message: 'Error updating user', error: err });
  }
};

export const deleteUser = async (req: Request, res: Response) => {
  console.log('[DELETE] /users/:id', req.params);
  try {
    const { id } = req.params;
    const deleted = await User.destroy({ where: { id } });
    if (!deleted) {
      console.log('User not found');
      return res.status(404).json({ message: 'User not found' });
    }
    console.log('User deleted:', id);
    res.json({ message: 'User deleted' });
  } catch (err) {
    console.error('Error deleting user:', err);
    res.status(500).json({ message: 'Error deleting user', error: err });
  }
};

export const loginUser = async (req: Request, res: Response) => {
  console.log('[POST] /users/login', req.body);
  try {
    const { contact, password, businessId } = req.body;
    const user = await User.findOne({ where: { contact, businessId } });
    if (!user) {
      console.log('User not found');
      return res.status(404).json({ message: 'User not found' });
    }
    
    const valid = await bcrypt.compare(password, user.toJSON().password);
    if (!valid) {
      console.log('Invalid password');
      return res.status(401).json({ message: 'Invalid password' });
    }
    const token = signToken({ id: user.id, businessId: user.businessId, role: user.role, permissions: user.permissions, contact: user.contact });
    console.log('User login success:', user.toJSON());
    res.json({ user, token });
  } catch (err) {
    console.error('Login error:', err);
    res.status(500).json({ message: 'Login error', error: err });
  }
};

export const validateToken = async (req: Request, res: Response): Promise<void> => {
  console.log('[GET] /users/validate');
  try {
    const user = (req as any).user;
    if (!user) {
      console.log('No user found in request');
      res.status(401).json({ message: 'Invalid token' });
      return;
    }
    
    // Get the current user data from database
    console.log('Validating user:', user);
    const currentUser = await User.findByPk(user.id);
    if (!currentUser) {
      console.log('User not found in database');
      res.status(401).json({ message: 'User not found' });
      return;
    }
    
    console.log('Token validation success:', currentUser.toJSON());
    res.json({ valid: true, user: currentUser });
  } catch (err) {
    console.error('Token validation error:', err);
    res.status(500).json({ message: 'Token validation error', error: err });
  }
};
