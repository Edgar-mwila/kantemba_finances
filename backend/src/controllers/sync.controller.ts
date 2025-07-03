import type { Request, Response } from 'express';

export const syncData = async (req: Request, res: Response) => {
  res.status(501).json({ message: 'Sync not implemented yet' });
};
