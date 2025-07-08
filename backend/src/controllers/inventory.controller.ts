import type { Request, Response } from 'express';
import { Inventory } from '../models/inventory.model';

export const getInventory = async (req: Request, res: Response) => {
  console.log('[GET] /inventory', req.query);
  try {
    const { shopId } = req.query;
    if (!shopId) return res.status(400).json({ message: 'shopId required' });
    const items = await Inventory.findAll({ where: { shopId: shopId as string } });
    console.log('Inventory items found:', items.map(i => i.toJSON()));
    res.json(items);
  } catch (err) {
    console.error('Server error:', err);
    res.status(500).json({ message: 'Server error', error: err });
  }
};

export const getInventoryItemById = async (req: Request, res: Response) => {
  console.log('[GET] /inventory/:id', req.params);
  try {
    const { id } = req.params;
    const item = await Inventory.findByPk(id);
    if (!item) {
      console.log('Inventory item not found');
      return res.status(404).json({ message: 'Inventory item not found' });
    }
    console.log('Inventory item found:', item.toJSON());
    res.json(item);
  } catch (err) {
    console.error('Server error:', err);
    res.status(500).json({ message: 'Server error', error: err });
  }
};

export const createInventoryItem = async (req: Request, res: Response) => {
  console.log('[POST] /inventory', req.body);
  try {
    const item = await Inventory.create(req.body);
    console.log('Inventory item created:', item.toJSON());
    res.status(201).json(item);
  } catch (err) {
    console.error('Error creating inventory item:', err);
    res.status(400).json({ message: 'Error creating inventory item', error: err });
  }
};

export const updateInventoryItem = async (req: Request, res: Response) => {
  console.log('[PUT] /inventory/:id', req.params, req.body);
  try {
    const { id } = req.params;
    const [updated] = await Inventory.update(req.body, { where: { id } });
    if (!updated) {
      console.log('Inventory item not found');
      return res.status(404).json({ message: 'Inventory item not found' });
    }
    const item = await Inventory.findByPk(id);
    console.log('Inventory item updated:', item?.toJSON());
    res.json(item);
  } catch (err) {
    console.error('Error updating inventory item:', err);
    res.status(400).json({ message: 'Error updating inventory item', error: err });
  }
};

export const deleteInventoryItem = async (req: Request, res: Response) => {
  console.log('[DELETE] /inventory/:id', req.params);
  try {
    const { id } = req.params;
    const deleted = await Inventory.destroy({ where: { id } });
    if (!deleted) {
      console.log('Inventory item not found');
      return res.status(404).json({ message: 'Inventory item not found' });
    }
    console.log('Inventory item deleted:', id);
    res.json({ message: 'Inventory item deleted' });
  } catch (err) {
    console.error('Error deleting inventory item:', err);
    res.status(500).json({ message: 'Error deleting inventory item', error: err });
  }
};
