import type { Request, Response } from 'express';
import { Shop } from '../models/shop.model';

export const getShops = async (req: Request, res: Response) => {
  console.log('[GET] /shops', req.query);
  try {
    const { businessId } = req.query;
    if (!businessId) return res.status(400).json({ message: 'businessId required' });
    const shops = await Shop.findAll({ where: { businessId: businessId as string } });
    console.log('Shops found:', shops.map(s => s.toJSON()));
    res.json(shops);
  } catch (err) {
    console.error('Server error:', err);
    res.status(500).json({ message: 'Server error', error: err });
  }
};

export const getShopById = async (req: Request, res: Response) => {
  console.log('[GET] /shops/:id', req.params);
  try {
    const { id } = req.params;
    const shop = await Shop.findByPk(id);
    if (!shop) {
      console.log('Shop not found');
      return res.status(404).json({ message: 'Shop not found' });
    }
    console.log('Shop found:', shop.toJSON());
    res.json(shop);
  } catch (err) {
    console.error('Server error:', err);
    res.status(500).json({ message: 'Server error', error: err });
  }
};

export const createShop = async (req: Request, res: Response) => {
  console.log('[POST] /shops', req.body);
  try {
    const shop = await Shop.create(req.body);
    console.log('Shop created:', shop.toJSON());
    res.status(201).json(shop);
  } catch (err) {
    console.error('Error creating shop:', err);
    res.status(400).json({ message: 'Error creating shop', error: err });
  }
};

export const updateShop = async (req: Request, res: Response) => {
  console.log('[PUT] /shops/:id', req.params, req.body);
  try {
    const { id } = req.params;
    const [updated] = await Shop.update(req.body, { where: { id } });
    if (!updated) {
      console.log('Shop not found');
      return res.status(404).json({ message: 'Shop not found' });
    }
    const shop = await Shop.findByPk(id);
    console.log('Shop updated:', shop?.toJSON());
    res.status(200).json(shop);
  } catch (err) {
    console.error('Error updating shop:', err);
    res.status(400).json({ message: 'Error updating shop', error: err });
  }
};

export const deleteShop = async (req: Request, res: Response) => {
  console.log('[DELETE] /shops/:id', req.params);
  try {
    const { id } = req.params;
    const deleted = await Shop.destroy({ where: { id } });
    if (!deleted) {
      console.log('Shop not found');
      return res.status(404).json({ message: 'Shop not found' });
    }
    console.log('Shop deleted:', id);
    res.status(204).json({ message: 'Shop deleted' });
  } catch (err) {
    console.error('Error deleting shop:', err);
    res.status(500).json({ message: 'Error deleting shop', error: err });
  }
};
