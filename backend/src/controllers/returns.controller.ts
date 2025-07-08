import type { Request, Response } from 'express';
import { Return } from '../models/return.model';
import { Sale } from '../models/sale.model';
import { Inventory } from '../models/inventory.model';

export const createReturn = async (req: Request, res: Response) => {
  try {
    const {
      originalSaleId,
      items,
      totalReturnAmount,
      grandReturnAmount,
      vat,
      turnoverTax,
      levy,
      shopId,
      businessId,
      createdBy,
      reason,
    } = req.body;

    // Validate required fields
    if (!originalSaleId || !items || !shopId || !businessId || !createdBy || !reason) {
      return res.status(400).json({ message: 'Missing required fields' });
    }

    // Verify the original sale exists
    const originalSale = await Sale.findOne({ where: { id: originalSaleId } });
    if (!originalSale) {
      return res.status(404).json({ message: 'Original sale not found' });
    }

    // Generate unique return ID
    const returnId = `RET_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;

    // Create the return
    const newReturn = new Return({
      id: returnId,
      originalSaleId,
      totalReturnAmount,
      grandReturnAmount,
      vat,
      turnoverTax,
      levy,
      shopId,
      businessId,
      createdBy,
      reason,
      status: 'pending',
      date: new Date(), // Add the required date property
    });

    await newReturn.save();

    // Update inventory (restock items)
    for (const item of items) {
      const InventoryItem = await Inventory.findOne({ where: { id: item.productId } });
      if (InventoryItem) {
        InventoryItem.quantity += item.quantity;
        await InventoryItem.save();
      }
    }

    res.status(201).json({
      message: 'Return created successfully',
      return: newReturn,
    });
  } catch (error) {
    console.error('Error creating return:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
};

export const getReturns = async (req: Request, res: Response) => {
  try {
    const { businessId, shopId } = req.query;

    if (!businessId) {
      return res.status(400).json({ message: 'Business ID is required' });
    }

    let query: any = { businessId };

    if (shopId) {
      query.shopId = shopId;
    }

    const returns = await Return.findAll({
      where: query,
      order: [['date', 'DESC']],
    });

    res.status(200).json({
      returns,
    });
  } catch (error) {
    console.error('Error fetching returns:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
};

export const getReturnById = async (req: Request, res: Response) => {
  try {
    const { id } = req.params;

    const returnItem = await Return.findOne({ where: { id } });
    if (!returnItem) {
      return res.status(404).json({ message: 'Return not found' });
    }

    res.status(200).json({
      return: returnItem,
    });
  } catch (error) {
    console.error('Error fetching return:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
};

export const getReturnsBySale = async (req: Request, res: Response) => {
  try {
    const { saleId } = req.params;

    const returns = await Return.findAll({
      where: { originalSaleId: saleId },
      order: [['date', 'DESC']],
    });

    res.status(200).json({
      returns,
    });
  } catch (error) {
    console.error('Error fetching returns by sale:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
};

export const approveReturn = async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const { approvedBy } = req.body;

    if (!approvedBy) {
      return res.status(400).json({ message: 'Approved by is required' });
    }

    const returnItem = await Return.findOne({ where: { id } });
    if (!returnItem) {
      return res.status(404).json({ message: 'Return not found' });
    }

    if (returnItem.status !== 'pending') {
      return res.status(400).json({ message: 'Return is not in pending status' });
    }

    returnItem.status = 'approved';
    returnItem.approvedBy = approvedBy;
    returnItem.approvedAt = new Date();

    await returnItem.save();

    res.status(200).json({
      message: 'Return approved successfully',
      return: returnItem,
    });
  } catch (error) {
    console.error('Error approving return:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
};

export const rejectReturn = async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const { rejectedBy, rejectionReason } = req.body;

    if (!rejectedBy || !rejectionReason) {
      return res.status(400).json({ message: 'Rejected by and rejection reason are required' });
    }

    const returnItem = await Return.findOne({ where: { id } });
    if (!returnItem) {
      return res.status(404).json({ message: 'Return not found' });
    }

    if (returnItem.status !== 'pending') {
      return res.status(400).json({ message: 'Return is not in pending status' });
    }

    returnItem.status = 'rejected';
    returnItem.rejectedBy = rejectedBy;
    returnItem.rejectionReason = rejectionReason;
    returnItem.rejectedAt = new Date();

    // Ensure returnItem.items exists and is an array
    const items = (returnItem as any).items || [];
    for (const item of items) {
      const InventoryItem = await Inventory.findOne({ where: { id: item.productId } });
      if (InventoryItem) {
        InventoryItem.quantity = Math.max(0, InventoryItem.quantity - item.quantity);
        await InventoryItem.save();
      }
    }

    await returnItem.save();

    res.status(200).json({
      message: 'Return rejected successfully',
      return: returnItem,
    });
  } catch (error) {
    console.error('Error rejecting return:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
};

export const completeReturn = async (req: Request, res: Response) => {
  try {
    const { id } = req.params;

    const returnItem = await Return.findOne({ where: { id } });
    if (!returnItem) {
      return res.status(404).json({ message: 'Return not found' });
    }

    if (returnItem.status !== 'approved') {
      return res.status(400).json({ message: 'Return must be approved before completion' });
    }

    returnItem.status = 'completed';

    await returnItem.save();

    res.status(200).json({
      message: 'Return completed successfully',
      return: returnItem,
    });
  } catch (error) {
    console.error('Error completing return:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
};

export const deleteReturn = async (req: Request, res: Response) => {
  try {
    const { id } = req.params;

    const returnItem = await Return.findOne({ where: { id } });
    if (!returnItem) {
      return res.status(404).json({ message: 'Return not found' });
    }

    // Only allow deletion of pending returns
    if (returnItem.status !== 'pending') {
      return res.status(400).json({ message: 'Only pending returns can be deleted' });
    }

    // Reverse inventory changes
    const items = (returnItem as any).items || [];
    for (const item of items) {
      const InventoryItem = await Inventory.findOne({ where: { id: item.productId } });
      if (InventoryItem) {
        InventoryItem.quantity = Math.max(0, InventoryItem.quantity - item.quantity);
        await InventoryItem.save();
      }
    }

    await Return.destroy({ where: { id } });

    res.status(200).json({
      message: 'Return deleted successfully',
    });
  } catch (error) {
    console.error('Error deleting return:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
}; 