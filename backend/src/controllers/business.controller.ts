import type { Request, Response } from 'express';
import { Business } from '../models/business.model';

export const getBusiness = async (req: Request, res: Response) => {
  console.log('[GET] /business/:id', req.params);
  try {
    const { id } = req.params;
    const business = await Business.findByPk(id);
    if (!business) {
      console.log('Business not found');
      return res.status(404).json({ message: 'Business not found' });
    }
    console.log('Business found:', business.toJSON());
    res.json(business);
  } catch (err) {
    console.error('Server error:', err);
    res.status(500).json({ message: 'Server error', error: err });
  }
};

export const createBusiness = async (req: Request, res: Response) => {
  console.log('[POST] /business', req.body);
  try {
    const business = await Business.create(req.body);
    console.log('Business created:', business.toJSON());
    res.status(201).json(business);
  } catch (err) {
    console.error('Error creating business:', err);
    res.status(400).json({ message: 'Error creating business', error: err });
  }
};

export const updateBusiness = async (req: Request, res: Response) => {
  console.log('[PUT] /business/:id', req.params, req.body);
  try {
    const { id } = req.params;
    const [updated] = await Business.update(req.body, { where: { id } });
    if (!updated) {
      console.log('Business not found');
      return res.status(404).json({ message: 'Business not found' });
    }
    const business = await Business.findByPk(id);
    console.log('Business updated:', business?.toJSON());
    res.json(business);
  } catch (err) {
    console.error('Error updating business:', err);
    res.status(400).json({ message: 'Error updating business', error: err });
  }
};

export const deleteBusiness = async (req: Request, res: Response) => {
  console.log('[DELETE] /business/:id', req.params);
  try {
    const { id } = req.params;
    const deleted = await Business.destroy({ where: { id } });
    if (!deleted) {
      console.log('Business not found');
      return res.status(404).json({ message: 'Business not found' });
    }
    console.log('Business deleted:', id);
    res.json({ message: 'Business deleted' });
  } catch (err) {
    console.error('Error deleting business:', err);
    res.status(500).json({ message: 'Error deleting business', error: err });
  }
};

export const flutterwaveWebhook = async (req: Request, res: Response): Promise<void> => {
  try {
    // Flutterwave sends event data in req.body
    const { businessId, txRef, planType, paymentStatus } = req.body;
    if (!businessId || !txRef || !planType || !paymentStatus) {
      res.status(400).json({ message: 'Missing required fields' });
      return;
    }
    if (paymentStatus !== 'successful') {
      res.status(200).json({ message: 'Payment not successful, no update.' });
      return;
    }
    // Calculate subscription dates
    const now = new Date();
    let expiry: Date;
    if (planType === 'yearly') {
      expiry = new Date(now);
      expiry.setFullYear(expiry.getFullYear() + 1);
    } else {
      expiry = new Date(now);
      expiry.setMonth(expiry.getMonth() + 1);
    }
    // Update business
    const [updated] = await Business.update({
      isPremium: true,
      subscriptionType: planType,
      subscriptionStartDate: now,
      subscriptionExpiryDate: expiry,
      trialUsed: true,
      lastPaymentTxRef: txRef,
    }, { where: { id: businessId } });
    if (!updated) {
      res.status(404).json({ message: 'Business not found' });
      return;
    }
    res.status(200).json({ message: 'Business upgraded to premium' });
  } catch (err) {
    console.error('Error in Flutterwave webhook:', err);
    res.status(500).json({ message: 'Server error', error: err });
  }
};
