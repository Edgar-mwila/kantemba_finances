import type { Request, Response } from 'express';
import { Sale } from '../models/sale.model';

export const getSales = async (req: Request, res: Response) => {
  console.log('[GET] /sales', req.query);
  try {
    const { businessId } = req.query;
    if (!businessId) return res.status(400).json({ message: 'businessId required' });
    const sales = await Sale.findAll({ where: { businessId: businessId as string } });
    console.log('Sales found:', sales.map(s => s.toJSON()));
    res.json(sales);
  } catch (err) {
    console.error('Server error:', err);
    res.status(500).json({ message: 'Server error', error: err });
  }
};

export const getSaleById = async (req: Request, res: Response) => {
  console.log('[GET] /sales/:id', req.params);
  try {
    const { id } = req.params;
    const sale = await Sale.findByPk(id);
    if (!sale) {
      console.log('Sale not found');
      return res.status(404).json({ message: 'Sale not found' });
    }
    console.log('Sale found:', sale.toJSON());
    res.json(sale);
  } catch (err) {
    console.error('Server error:', err);
    res.status(500).json({ message: 'Server error', error: err });
  }
};

export const createSale = async (req: Request, res: Response) => {
  console.log('[POST] /sales', req.body);
  try {
    const { items, ...saleData } = req.body;
    const sale = await Sale.create(saleData);
    if (items && Array.isArray(items)) {
      for (const item of items) {
        // SaleItem logic will be handled in the new sale_item.controller.ts
      }
    }
    const saleWithItems = await Sale.findByPk(sale.id);
    console.log('Sale created:', saleWithItems?.toJSON());
    res.status(201).json(saleWithItems);
  } catch (err) {
    console.error('Error creating sale:', err);
    res.status(400).json({ message: 'Error creating sale', error: err });
  }
};

export const updateSale = async (req: Request, res: Response) => {
  console.log('[PUT] /sales/:id', req.params, req.body);
  try {
    const { id } = req.params;
    const [updated] = await Sale.update(req.body, { where: { id } });
    if (!updated) {
      console.log('Sale not found');
      return res.status(404).json({ message: 'Sale not found' });
    }
    const sale = await Sale.findByPk(id);
    console.log('Sale updated:', sale?.toJSON());
    res.json(sale);
  } catch (err) {
    console.error('Error updating sale:', err);
    res.status(400).json({ message: 'Error updating sale', error: err });
  }
};

export const deleteSale = async (req: Request, res: Response) => {
  console.log('[DELETE] /sales/:id', req.params);
  try {
    const { id } = req.params;
    const deleted = await Sale.destroy({ where: { id } });
    if (!deleted) {
      console.log('Sale not found');
      return res.status(404).json({ message: 'Sale not found' });
    }
    console.log('Sale deleted:', id);
    res.json({ message: 'Sale deleted' });
  } catch (err) {
    console.error('Error deleting sale:', err);
    res.status(500).json({ message: 'Error deleting sale', error: err });
  }
};

