import type { Request, Response } from 'express';
import { AnalyticsEvent } from '../models/analytics.model'; // or console if no logger setup
import { sequelize } from '../utils/db';
import { logger } from '../utils/logger';

export const logAnalytics = async (req: Request, res: Response) => {
  try {
    await AnalyticsEvent.create(req.body);
    res.status(201).json({ message: 'Analytics event logged.' });
  } catch (error) {
    logger.error('Failed to log analytics event:', {
      error: error instanceof Error ? error.message : error,
      stack: error instanceof Error ? error.stack : undefined,
      requestBody: req.body,
      timestamp: new Date().toISOString()
    });
    res.status(500).json({ message: 'Failed to log analytics event.' });
  }
};

export const getRecentEvents = async (req: Request, res: Response) => {
  try {
    const limit = parseInt(req.query.limit as string) || 100;
    const events = await AnalyticsEvent.findAll({
      order: [['timestamp', 'DESC']],
      limit: limit
    });
    res.json(events);
  } catch (error) {
    logger.error('Failed to fetch recent events:', {
      error: error instanceof Error ? error.message : error,
      stack: error instanceof Error ? error.stack : undefined,
      limit: req.query.limit,
      timestamp: new Date().toISOString()
    });
    res.status(500).json({ message: 'Failed to fetch recent events.' });
  }
};

export const getFeatureUsage = async (req: Request, res: Response) => {
  try {
    // Using raw SQL query for aggregation (similar to MongoDB's aggregate)
    const usage = await sequelize.query(`
      SELECT event as "_id", COUNT(*) as "count"
      FROM analytics_events 
      WHERE type = 'event'
      GROUP BY event
      ORDER BY count DESC
    `);
    
    res.json(usage);
  } catch (error) {
    res.status(500).json({ message: 'Failed to fetch feature usage.' });
  }
};

export const getErrors = async (req: Request, res: Response) => {
  try {
    const limit = parseInt(req.query.limit as string) || 100;
    const errors = await AnalyticsEvent.findAll({
      where: {
        type: 'error'
      },
      order: [['timestamp', 'DESC']],
      limit: limit
    });
    res.json(errors);
  } catch (error) {
    res.status(500).json({ message: 'Failed to fetch errors.' });
  }
};

export const getReviews = async (req: Request, res: Response) => {
  try {
    const limit = parseInt(req.query.limit as string) || 100;
    const reviews = await AnalyticsEvent.findAll({
      where: {
        type: 'review'
      },
      order: [['timestamp', 'DESC']],
      limit: limit
    });
    res.json(reviews);
  } catch (error) {
    res.status(500).json({ message: 'Failed to fetch reviews.' });
  }
};

// Alternative implementation for getFeatureUsage using Sequelize methods
export const getFeatureUsageSequelize = async (req: Request, res: Response) => {
  try {
    const usage = await AnalyticsEvent.findAll({
      attributes: [
        'event',
        [sequelize.fn('COUNT', sequelize.col('event')), 'count']
      ],
      where: {
        type: 'event'
      },
      group: ['event'],
      order: [[sequelize.literal('count'), 'DESC']]
    });
    
    // Transform to match MongoDB aggregate format
    const formattedUsage = usage.map((item: any) => ({
      _id: item.event,
      count: parseInt(item.dataValues.count)
    }));
    
    res.json(formattedUsage);
  } catch (error) {
    res.status(500).json({ message: 'Failed to fetch feature usage.' });
  }
};