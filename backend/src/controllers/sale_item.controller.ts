import type { Request, Response } from 'express';
import { SaleItem } from '../models/sale.model';

export const getSaleItems = async (req: Request, res: Response) => {
  console.log('[GET] /sale_items', req.query);
  try {
    const { saleId } = req.query;
    let items;
    if (saleId) {
      items = await SaleItem.findAll({ where: { saleId: saleId as string } });
    } else {
      items = await SaleItem.findAll();
    }
    console.log('Sale items found:', items.map(i => i.toJSON()));
    res.json(items);
  } catch (err) {
    console.error('Server error:', err);
    res.status(500).json({ message: 'Server error', error: err });
  }
};

export const getSaleItemById = async (req: Request, res: Response) => {
  console.log('[GET] /sale_items/:id', req.params);
  try {
    const { id } = req.params;
    const item = await SaleItem.findByPk(id);
    if (!item) {
      console.log('Sale item not found');
      return res.status(404).json({ message: 'Sale item not found' });
    }
    console.log('Sale item found:', item.toJSON());
    res.json(item);
  } catch (err) {
    console.error('Server error:', err);
    res.status(500).json({ message: 'Server error', error: err });
  }
};

export const createSaleItem = async (req: Request, res: Response) => {
  console.log('[POST] /sale_items', req.body);
  try {
    const item = await SaleItem.create(req.body);
    console.log('Sale item created:', item.toJSON());
    res.status(201).json(item);
  } catch (err) {
    console.error('Error creating sale item:', err);
    res.status(400).json({ message: 'Error creating sale item', error: err });
  }
};

export const updateSaleItem = async (req: Request, res: Response) => {
  console.log('[PUT] /sale_items/:id', req.params, req.body);
  try {
    const { id } = req.params;
    const [updated] = await SaleItem.update(req.body, { where: { id } });
    if (!updated) {
      console.log('Sale item not found');
      return res.status(404).json({ message: 'Sale item not found' });
    }
    const item = await SaleItem.findByPk(id);
    console.log('Sale item updated:', item?.toJSON());
    res.json(item);
  } catch (err) {
    console.error('Error updating sale item:', err);
    res.status(400).json({ message: 'Error updating sale item', error: err });
  }
};

export const deleteSaleItem = async (req: Request, res: Response) => {
  console.log('[DELETE] /sale_items/:id', req.params);
  try {
    const { id } = req.params;
    const deleted = await SaleItem.destroy({ where: { id } });
    if (!deleted) {
      console.log('Sale item not found');
      return res.status(404).json({ message: 'Sale item not found' });
    }
    console.log('Sale item deleted:', id);
    res.json({ message: 'Sale item deleted' });
  } catch (err) {
    console.error('Error deleting sale item:', err);
    res.status(500).json({ message: 'Error deleting sale item', error: err });
  }
}; 