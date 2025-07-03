import type { Request, Response } from 'express';
import { Expense } from '../models/expense.model';

export const getExpenses = async (req: Request, res: Response) => {
  console.log('[GET] /expenses', req.query);
  try {
    const { businessId } = req.query;
    if (!businessId) return res.status(400).json({ message: 'businessId required' });
    const expenses = await Expense.findAll({ where: { businessId: businessId as string } });
    console.log('Expenses found:', expenses.map(e => e.toJSON()));
    res.json(expenses);
  } catch (err) {
    console.error('Server error:', err);
    res.status(500).json({ message: 'Server error', error: err });
  }
};

export const getExpenseById = async (req: Request, res: Response) => {
  console.log('[GET] /expenses/:id', req.params);
  try {
    const { id } = req.params;
    const expense = await Expense.findByPk(id);
    if (!expense) {
      console.log('Expense not found');
      return res.status(404).json({ message: 'Expense not found' });
    }
    console.log('Expense found:', expense.toJSON());
    res.json(expense);
  } catch (err) {
    console.error('Server error:', err);
    res.status(500).json({ message: 'Server error', error: err });
  }
};

export const createExpense = async (req: Request, res: Response) => {
  console.log('[POST] /expenses', req.body);
  try {
    const expense = await Expense.create(req.body);
    console.log('Expense created:', expense.toJSON());
    res.status(201).json(expense);
  } catch (err) {
    console.error('Error creating expense:', err);
    res.status(400).json({ message: 'Error creating expense', error: err });
  }
};

export const updateExpense = async (req: Request, res: Response) => {
  console.log('[PUT] /expenses/:id', req.params, req.body);
  try {
    const { id } = req.params;
    const [updated] = await Expense.update(req.body, { where: { id } });
    if (!updated) {
      console.log('Expense not found');
      return res.status(404).json({ message: 'Expense not found' });
    }
    const expense = await Expense.findByPk(id);
    console.log('Expense updated:', expense?.toJSON());
    res.json(expense);
  } catch (err) {
    console.error('Error updating expense:', err);
    res.status(400).json({ message: 'Error updating expense', error: err });
  }
};

export const deleteExpense = async (req: Request, res: Response) => {
  console.log('[DELETE] /expenses/:id', req.params);
  try {
    const { id } = req.params;
    const deleted = await Expense.destroy({ where: { id } });
    if (!deleted) {
      console.log('Expense not found');
      return res.status(404).json({ message: 'Expense not found' });
    }
    console.log('Expense deleted:', id);
    res.json({ message: 'Expense deleted' });
  } catch (err) {
    console.error('Error deleting expense:', err);
    res.status(500).json({ message: 'Error deleting expense', error: err });
  }
};
