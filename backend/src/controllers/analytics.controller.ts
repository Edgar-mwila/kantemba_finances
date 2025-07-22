import type { Request, Response } from 'express';
import Analytics from '../models/analytics.model';

export const logAnalytics = async (req: Request, res: Response) => {
  try {
    const event = new Analytics(req.body);
    await event.save();
    res.status(201).json({ message: 'Analytics event logged.' });
  } catch (error) {
    res.status(500).json({ message: 'Failed to log analytics event.' });
  }
};

export const getRecentEvents = async (req: Request, res: Response) => {
  const limit = parseInt(req.query.limit as string) || 100;
  const events = await Analytics.find().sort({ timestamp: -1 }).limit(limit);
  res.json(events);
};

export const getFeatureUsage = async (req: Request, res: Response) => {
  // Aggregate event counts by event type
  const usage = await Analytics.aggregate([
    { $match: { type: 'event' } },
    { $group: { _id: '$event', count: { $sum: 1 } } },
    { $sort: { count: -1 } },
  ]);
  res.json(usage);
};

export const getErrors = async (req: Request, res: Response) => {
  const limit = parseInt(req.query.limit as string) || 100;
  const errors = await Analytics.find({ type: 'error' }).sort({ timestamp: -1 }).limit(limit);
  res.json(errors);
};

export const getReviews = async (req: Request, res: Response) => {
  const limit = parseInt(req.query.limit as string) || 100;
  const reviews = await Analytics.find({ type: 'review' }).sort({ timestamp: -1 }).limit(limit);
  res.json(reviews);
}; 