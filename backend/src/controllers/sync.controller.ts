import type { Request, Response } from 'express';
import { Business } from '../models/business.model';
import { User } from '../models/user.model';
import { Shop } from '../models/shop.model';
import { Inventory } from '../models/inventory.model';
import { Expense } from '../models/expense.model';
import { Sale, SaleItem } from '../models/sale.model';
import { Return, ReturnItem } from '../models/return.model';

export const syncData = async (req: Request, res: Response) => {
  try {
    const {
      business,
      users = [],
      shops = [],
      inventories = [],
      expenses = [],
      sales = [],
      sale_items = [],
      returns = [],
      return_items = [],
    } = req.body;

    const results: any = {
      business: null,
      users: { success: 0, error: 0 },
      shops: { success: 0, error: 0 },
      inventories: { success: 0, error: 0 },
      expenses: { success: 0, error: 0 },
      sales: { success: 0, error: 0 },
      sale_items: { success: 0, error: 0 },
      returns: { success: 0, error: 0 },
      return_items: { success: 0, error: 0 },
    };

    // Upsert business
    if (business && business.id) {
      const [biz, created] = await Business.findOrCreate({ where: { id: business.id }, defaults: business });
      if (!created) {
        await biz.update(business);
      }
      results.business = { id: biz.id, created, updated: !created };
    }

    // Upsert users
    for (const user of users) {
      try {
        const [u, created] = await User.findOrCreate({ where: { id: user.id }, defaults: user });
        if (!created) await u.update(user);
        results.users.success++;
      } catch (e) { results.users.error++; }
    }

    // Upsert shops
    for (const shop of shops) {
      try {
        const [s, created] = await Shop.findOrCreate({ where: { id: shop.id }, defaults: shop });
        if (!created) await s.update(shop);
        results.shops.success++;
      } catch (e) { results.shops.error++; }
    }

    // Upsert inventories
    for (const item of inventories) {
      try {
        const [inv, created] = await Inventory.findOrCreate({ where: { id: item.id }, defaults: item });
        if (!created) await inv.update(item);
        results.inventories.success++;
      } catch (e) { results.inventories.error++; }
    }

    // Upsert expenses
    for (const expense of expenses) {
      try {
        const [exp, created] = await Expense.findOrCreate({ where: { id: expense.id }, defaults: expense });
        if (!created) await exp.update(expense);
        results.expenses.success++;
      } catch (e) { results.expenses.error++; }
    }

    // Upsert sales
    for (const sale of sales) {
      try {
        const [s, created] = await Sale.findOrCreate({ where: { id: sale.id }, defaults: sale });
        if (!created) await s.update(sale);
        results.sales.success++;
      } catch (e) { results.sales.error++; }
    }

    // Upsert sale_items
    for (const item of sale_items) {
      try {
        const [si, created] = await SaleItem.findOrCreate({ where: { id: item.id }, defaults: item });
        if (!created) await si.update(item);
        results.sale_items.success++;
      } catch (e) { results.sale_items.error++; }
    }

    // Upsert returns
    for (const ret of returns) {
      try {
        const [r, created] = await Return.findOrCreate({ where: { id: ret.id }, defaults: ret });
        if (!created) await r.update(ret);
        results.returns.success++;
      } catch (e) { results.returns.error++; }
    }

    // Upsert return_items
    for (const item of return_items) {
      try {
        const [ri, created] = await ReturnItem.findOrCreate({ where: { id: item.id }, defaults: item });
        if (!created) await ri.update(item);
        results.return_items.success++;
      } catch (e) { results.return_items.error++; }
    }

    res.json({ message: 'Sync complete', results });
  } catch (err) {
    console.error('Sync error:', err);
    res.status(500).json({ message: 'Sync error', error: err });
  }
};
