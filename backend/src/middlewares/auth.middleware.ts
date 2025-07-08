import type { Request, Response, NextFunction } from 'express';
import { verifyToken } from '../utils/jwt';

export function authenticateJWT(req: Request, res: Response, next: NextFunction) {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ message: 'No token provided' });
  }
  const token = authHeader.split(' ')[1];
  if (!token || typeof token !== 'string') {
    return res.status(401).json({ message: 'No token provided' });
  }
  const payload = verifyToken(token);
  if (!payload) {
    return res.status(401).json({ message: 'Invalid or expired token' });
  }
  // @ts-ignore
  req.user = payload;
  next();
}

/**
 * Middleware to authorize based on user role and shop context.
 * Usage: authorizeRolesAndShops(['admin', 'manager'], true) // true = allow all shops for admin/manager
 * Usage: authorizeRolesAndShops(['employee']) // only allow employee for their own shop
 */
export function authorizeRolesAndShops(allowedRoles: string[], allowAllShopsForRoles: boolean = false) {
  return (req: Request, res: Response, next: NextFunction) => {
    // @ts-ignore
    const user = req.user;
    if (!user) {
      return res.status(401).json({ message: 'Unauthorized' });
    }
    if (!allowedRoles.includes(user.role)) {
      return res.status(403).json({ message: 'Forbidden: insufficient role' });
    }
    // If shopId is in params or body, check shop context
    const shopId = req.params.shopId || req.body.shopId || req.query.shopId;
    if (user.role === 'admin' || user.role === 'manager') {
      if (allowAllShopsForRoles) {
        // Admin/manager can access all shops
        return next();
      } else if (user.shopId && shopId && user.shopId !== shopId) {
        // If manager is assigned to a specific shop, restrict
        return res.status(403).json({ message: 'Forbidden: not assigned to this shop' });
      }
    } else if (user.role === 'employee') {
      if (!user.shopId || !shopId || user.shopId !== shopId) {
        return res.status(403).json({ message: 'Forbidden: not assigned to this shop' });
      }
    }
    next();
  };
}
