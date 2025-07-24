import type { Request, Response } from 'express';
import { Business } from '../models/business.model';
import { User } from '../models/user.model';
import { Shop } from '../models/shop.model';
import { Inventory } from '../models/inventory.model';
import { Expense } from '../models/expense.model';
import { Sale, SaleItem } from '../models/sale.model';
import { Return, ReturnItem } from '../models/return.model';
import { Loan, LoanPayment } from '../models/loan.model';
import { Payable, PayablePayment } from '../models/payable.model';
import { Receivable, ReceivablePayment } from '../models/receivable.model';

// Utility: Clean foreign keys and remove unknown attributes
function cleanRecord(record: any, allowedFields: string[], fkFields: string[] = []) {
  const cleaned: any = {};
  for (const key of allowedFields) {
    let value = record[key];
    // Convert empty string foreign keys to null
    if (fkFields.includes(key) && (value === '' || value === undefined)) {
      value = null;
    }
    cleaned[key] = value;
  }
  return cleaned;
}

export const syncData = async (req: Request, res: Response) => {
  const startTime = Date.now();
  const requestId = `sync_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  
  // Log incoming request
  console.log(`[${requestId}] ==================== SYNC REQUEST START ====================`);
  console.log(`[${requestId}] Method: ${req.method}`);
  console.log(`[${requestId}] URL: ${req.url}`);
  console.log(`[${requestId}] Headers:`, JSON.stringify(req.headers, null, 2));
  console.log(`[${requestId}] User-Agent: ${req.get('User-Agent')}`);
  console.log(`[${requestId}] IP: ${req.ip}`);
  console.log(`[${requestId}] Timestamp: ${new Date().toISOString()}`);
  
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
      receivables = [],
      payables = [],
      loans = [],
      receivable_payments = [],
      loan_payments = [],
      payable_payments = [],
    } = req.body;

    // Log request data summary
    console.log(`[${requestId}] REQUEST DATA SUMMARY:`);
    console.log(`[${requestId}] - Business: ${business ? 'Present' : 'Not provided'}`);
    console.log(`[${requestId}] - Users: ${users.length} items`);
    console.log(`[${requestId}] - Shops: ${shops.length} items`);
    console.log(`[${requestId}] - Inventories: ${inventories.length} items`);
    console.log(`[${requestId}] - Expenses: ${expenses.length} items`);
    console.log(`[${requestId}] - Sales: ${sales.length} items`);
    console.log(`[${requestId}] - Sale Items: ${sale_items.length} items`);
    console.log(`[${requestId}] - Returns: ${returns.length} items`);
    console.log(`[${requestId}] - Return Items: ${return_items.length} items`);
    console.log(`[${requestId}] - Receivables: ${receivables.length} items`);
    console.log(`[${requestId}] - Payables: ${payables.length} items`);
    console.log(`[${requestId}] - Loans: ${loans.length} items`);
    console.log(`[${requestId}] - Receivables: ${receivable_payments.length} items`);
    console.log(`[${requestId}] - Payables: ${payable_payments.length} items`);
    console.log(`[${requestId}] - Loans: ${loan_payments.length} items`);
    
    // Log detailed request data (be careful with sensitive data)
    console.log(`[${requestId}] DETAILED REQUEST DATA:`);
    if (business) {
      console.log(`[${requestId}] Business Data:`, JSON.stringify(business, null, 2));
    }
    console.log(`[${requestId}] Users Data:`, JSON.stringify(users, null, 2));
    console.log(`[${requestId}] Shops Data:`, JSON.stringify(shops, null, 2));
    console.log(`[${requestId}] Inventories Data:`, JSON.stringify(inventories, null, 2));
    console.log(`[${requestId}] Expenses Data:`, JSON.stringify(expenses, null, 2));
    console.log(`[${requestId}] Sales Data:`, JSON.stringify(sales, null, 2));
    console.log(`[${requestId}] Sale Items Data:`, JSON.stringify(sale_items, null, 2));
    console.log(`[${requestId}] Returns Data:`, JSON.stringify(returns, null, 2));
    console.log(`[${requestId}] Return Items Data:`, JSON.stringify(return_items, null, 2));
    console.log(`[${requestId}] Receivables Data:`, JSON.stringify(receivables, null, 2));
    console.log(`[${requestId}] Payables Data:`, JSON.stringify(payables, null, 2));
    console.log(`[${requestId}] Loans Data:`, JSON.stringify(loans, null, 2));
    console.log(`[${requestId}] Receivable Payments Data:`, JSON.stringify(receivable_payments, null, 2));
    console.log(`[${requestId}] Payable Payments Data:`, JSON.stringify(payable_payments, null, 2));
    console.log(`[${requestId}] Loan Payments Data:`, JSON.stringify(loan_payments, null, 2));

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
      receivables: { success: 0, error: 0 },
      payables: { success: 0, error: 0 },
      loans: { success: 0, error: 0 },
      receivable_payments: { success: 0, error: 0 },
      payable_payments: { success: 0, error: 0 },
      loan_payments: { success: 0, error: 0 },
    };

    // Upsert business
    if (business && business.id) {
      console.log(`[${requestId}] Processing business: ${business.id}`);
      const [biz, created] = await Business.findOrCreate({ where: { id: business.id }, defaults: business });
      if (!created) {
        await biz.update(business);
      }
      results.business = { id: biz.id, created, updated: !created };
      console.log(`[${requestId}] Business processed: ${created ? 'Created' : 'Updated'}`);
    } else {
      console.warn(`[${requestId}] WARNING: No business object provided in sync payload. This may cause foreign key errors.`);
    }

    // Upsert users
    console.log(`[${requestId}] Processing ${users.length} users...`);
    for (const user of users) {
      try {
        // Clean user record
        const allowedFields = ['id','name','contact','password','role','permissions','businessId','shopId'];
        const fkFields = ['businessId','shopId'];
        const cleanedUser = cleanRecord(user, allowedFields, fkFields);
        // Skip if required FKs are missing
        if (!cleanedUser.businessId) {
          console.error(`[${requestId}] Skipping user ${user.id}: missing businessId`);
          results.users.error++;
          continue;
        }
        const [u, created] = await User.findOrCreate({ where: { id: cleanedUser.id }, defaults: cleanedUser });
        if (!created) await u.update(cleanedUser);
        results.users.success++;
        console.log(`[${requestId}] User ${user.id}: ${created ? 'Created' : 'Updated'}`);
      } catch (e) { 
        results.users.error++;
        console.error(`[${requestId}] Error processing user ${user.id}:`, e);
      }
    }

    // Upsert shops
    console.log(`[${requestId}] Processing ${shops.length} shops...`);
    for (const shop of shops) {
      try {
        const allowedFields = ['id','name','businessId'];
        const fkFields = ['businessId'];
        const cleanedShop = cleanRecord(shop, allowedFields, fkFields);
        if (!cleanedShop.businessId) {
          console.error(`[${requestId}] Skipping shop ${shop.id}: missing businessId`);
          results.shops.error++;
          continue;
        }
        const [s, created] = await Shop.findOrCreate({ where: { id: cleanedShop.id }, defaults: cleanedShop });
        if (!created) await s.update(cleanedShop);
        results.shops.success++;
        console.log(`[${requestId}] Shop ${shop.id}: ${created ? 'Created' : 'Updated'}`);
      } catch (e) { 
        results.shops.error++;
        console.error(`[${requestId}] Error processing shop ${shop.id}:`, e);
      }
    }

    // Upsert inventories
    console.log(`[${requestId}] Processing ${inventories.length} inventories...`);
    for (const item of inventories) {
      try {
        const allowedFields = ['id','name','price','quantity','lowStockThreshold','createdBy','shopId','damagedRecords'];
        const fkFields = ['createdBy','shopId'];
        const cleanedItem = cleanRecord(item, allowedFields, fkFields);
        if (!cleanedItem.createdBy || !cleanedItem.shopId) {
          console.error(`[${requestId}] Skipping inventory ${item.id}: missing createdBy or shopId`);
          results.inventories.error++;
          continue;
        }
        const [inv, created] = await Inventory.findOrCreate({ where: { id: cleanedItem.id }, defaults: cleanedItem });
        if (!created) await inv.update(cleanedItem);
        results.inventories.success++;
        console.log(`[${requestId}] Inventory ${item.id}: ${created ? 'Created' : 'Updated'}`);
      } catch (e) { 
        results.inventories.error++;
        console.error(`[${requestId}] Error processing inventory ${item.id}:`, e);
      }
    }

    // Upsert expenses
    console.log(`[${requestId}] Processing ${expenses.length} expenses...`);
    for (const expense of expenses) {
      try {
        const allowedFields = ['id','description','amount','date','category','createdBy','shopId'];
        const fkFields = ['createdBy','shopId'];
        const cleanedExpense = cleanRecord(expense, allowedFields, fkFields);
        if (!cleanedExpense.createdBy || !cleanedExpense.shopId) {
          console.error(`[${requestId}] Skipping expense ${expense.id}: missing createdBy or shopId`);
          results.expenses.error++;
          continue;
        }
        const [exp, created] = await Expense.findOrCreate({ where: { id: cleanedExpense.id }, defaults: cleanedExpense });
        if (!created) await exp.update(cleanedExpense);
        results.expenses.success++;
        console.log(`[${requestId}] Expense ${expense.id}: ${created ? 'Created' : 'Updated'}`);
      } catch (e) { 
        results.expenses.error++;
        console.error(`[${requestId}] Error processing expense ${expense.id}:`, e);
      }
    }

    // Upsert sales
    console.log(`[${requestId}] Processing ${sales.length} sales...`);
    for (const sale of sales) {
      try {
        const allowedFields = ['id','totalAmount','grandTotal','vat','turnoverTax','levy','date','createdBy','shopId','customerName','customerPhone','discount'];
        const fkFields = ['createdBy','shopId'];
        const cleanedSale = cleanRecord(sale, allowedFields, fkFields);
        if (!cleanedSale.createdBy || !cleanedSale.shopId) {
          console.error(`[${requestId}] Skipping sale ${sale.id}: missing createdBy or shopId`);
          results.sales.error++;
          continue;
        }
        const [s, created] = await Sale.findOrCreate({ where: { id: cleanedSale.id }, defaults: cleanedSale });
        if (!created) await s.update(cleanedSale);
        results.sales.success++;
        console.log(`[${requestId}] Sale ${sale.id}: ${created ? 'Created' : 'Updated'}`);
      } catch (e) { 
        results.sales.error++;
        console.error(`[${requestId}] Error processing sale ${sale.id}:`, e);
      }
    }

    // Upsert sale_items
    console.log(`[${requestId}] Processing ${sale_items.length} sale items...`);
    for (const item of sale_items) {
      try {
        const allowedFields = ['id','saleId','productId','productName','price','quantity'];
        const fkFields = ['saleId'];
        const cleanedItem = cleanRecord(item, allowedFields, fkFields);
        if (!cleanedItem.saleId) {
          console.error(`[${requestId}] Skipping sale item ${item.id}: missing saleId`);
          results.sale_items.error++;
          continue;
        }
        const [si, created] = await SaleItem.findOrCreate({ where: { id: cleanedItem.id }, defaults: cleanedItem });
        if (!created) await si.update(cleanedItem);
        results.sale_items.success++;
        console.log(`[${requestId}] Sale item ${item.id}: ${created ? 'Created' : 'Updated'}`);
      } catch (e) { 
        results.sale_items.error++;
        console.error(`[${requestId}] Error processing sale item ${item.id}:`, e);
      }
    }

    // Upsert returns
    console.log(`[${requestId}] Processing ${returns.length} returns...`);
    for (const ret of returns) {
      try {
        const allowedFields = ['id','originalSaleId','totalReturnAmount','grandReturnAmount','vat','turnoverTax','levy','date','shopId','createdBy','reason','status'];
        const fkFields = ['originalSaleId','shopId','createdBy'];
        const cleanedReturn = cleanRecord(ret, allowedFields, fkFields);
        if (!cleanedReturn.originalSaleId || !cleanedReturn.shopId) {
          console.error(`[${requestId}] Skipping return ${ret.id}: missing originalSaleId or shopId`);
          results.returns.error++;
          continue;
        }
        const [r, created] = await Return.findOrCreate({ where: { id: cleanedReturn.id }, defaults: cleanedReturn });
        if (!created) await r.update(cleanedReturn);
        results.returns.success++;
        console.log(`[${requestId}] Return ${ret.id}: ${created ? 'Created' : 'Updated'}`);
      } catch (e) { 
        results.returns.error++;
        console.error(`[${requestId}] Error processing return ${ret.id}:`, e);
      }
    }

    // Upsert return_items
    console.log(`[${requestId}] Processing ${return_items.length} return items...`);
    for (const item of return_items) {
      try {
        const allowedFields = ['id','returnId','productId','productName','quantity','originalPrice','reason','shopId'];
        const fkFields = ['returnId','shopId'];
        const cleanedItem = cleanRecord(item, allowedFields, fkFields);
        if (!cleanedItem.returnId || !cleanedItem.shopId) {
          console.error(`[${requestId}] Skipping return item ${item.id}: missing returnId or shopId`);
          results.return_items.error++;
          continue;
        }
        const [ri, created] = await ReturnItem.findOrCreate({ where: { id: cleanedItem.id }, defaults: cleanedItem });
        if (!created) await ri.update(cleanedItem);
        results.return_items.success++;
        console.log(`[${requestId}] Return item ${item.id}: ${created ? 'Created' : 'Updated'}`);
      } catch (e) { 
        results.return_items.error++;
        console.error(`[${requestId}] Error processing return item ${item.id}:`, e);
      }
    }

    // Sync Receivables, Payables, Loans
    const syncOperations = [];
    if (receivables && receivables.length > 0) {
        syncOperations.push(...receivables.map((r: any) => Receivable.findOrCreate({ where: { id: r._id }, defaults: r})));
    }
    if (receivable_payments && receivable_payments.length > 0) {
        syncOperations.push(...receivable_payments.map((r: any) => ReceivablePayment.findOrCreate({ where: { id: r._id }, defaults: r})));
    }
    if (payables && payables.length > 0) {
        syncOperations.push(...payables.map((p: any) => Payable.findOrCreate({ where: { id: p._id }, defaults: p})));
    }
    if (payable_payments && payable_payments.length > 0) {
        syncOperations.push(...payable_payments.map((p: any) => PayablePayment.findOrCreate({ where: { id: p._id }, defaults: p})));
    }
    if (loans && loans.length > 0) {
        syncOperations.push(...loans.map((l: any) => Loan.findOrCreate({ where: { id: l._id }, defaults: l})));
    }
    if (loan_payments && loan_payments.length > 0) {
        syncOperations.push(...loan_payments.map((l: any) => LoanPayment.findOrCreate({ where: { id: l._id }, defaults: l})));
    }

    try {
        await Promise.all(syncOperations);
        res.status(200).send({ message: 'Sync successful' });
    } catch (error) {
        console.error('Sync error:', error);
        res.status(500).send({ message: 'Sync failed', error });
    }
  } catch (err) {
    const endTime = Date.now();
    const duration = endTime - startTime;
    
    console.error(`[${requestId}] ==================== SYNC ERROR ====================`);
    console.error(`[${requestId}] Status Code: 500`);
    console.error(`[${requestId}] Processing Duration: ${duration}ms`);
    console.error(`[${requestId}] Error:`, err);
    console.error(`[${requestId}] Error Stack:`, (err as Error).stack);
    
    const errorResponse = { message: 'Sync error', error: err };
    console.error(`[${requestId}] Error Response:`, JSON.stringify(errorResponse, null, 2));
    console.error(`[${requestId}] ==================== SYNC ERROR END ====================`);
    
    res.status(500).json(errorResponse);
  }
};