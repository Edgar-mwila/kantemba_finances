import type { Request, Response } from 'express';
import { Receivable, ReceivablePayment } from '../models/receivable.model';
import { Op } from 'sequelize';

export const createReceivable = async (req: Request, res: Response) => {
    try {
        const receivableData = {
            ...req.body
        };
        const receivable = await Receivable.create(receivableData);
        res.status(201).json(receivable);
    } catch (err) {
    console.error('Server error:', err);
    res.status(500).json({ message: 'Server error', error: err });
    }
};

export const getReceivables = async (req: Request, res: Response) => {
    try {
        const where: any = {};
        
        // Build where clause from query parameters
        if (req.query.status) {
            where.status = req.query.status;
        }
        if (req.query.interestType) {
            where.interestType = req.query.interestType;
        }
        if (req.query.name) {
            where.name = {
                [Op.iLike]: `%${req.query.name}%`
            };
        }
        
        const receivables = await Receivable.findAll({
            where,
            include: [{
                model: ReceivablePayment,
                as: 'ReceivablePayments'
            }],
            order: [['createdAt', 'DESC']]
        });
        
        res.status(200).json(receivables);
    } catch (err) {
    console.error('Server error:', err);
    res.status(500).json({ message: 'Server error', error: err });
    }
};

export const getReceivableById = async (req: Request, res: Response) => {
    try {
        const receivable = await Receivable.findByPk(req.params.id, {
            include: [{
                model: ReceivablePayment,
                as: 'ReceivablePayments',
                order: [['date', 'DESC']]
            }]
        });
        
        if (!receivable) {
            return res.status(404).json({ error: 'Receivable not found' });
        }
        
        res.status(200).json(receivable);
    } catch (err) {
    console.error('Server error:', err);
    res.status(500).json({ message: 'Server error', error: err });
    }
};

export const updateReceivable = async (req: Request, res: Response) => {
    try {
        const [updatedRowsCount] = await Receivable.update(req.body, {
            where: { id: req.params.id },
            returning: true
        });
        
        if (updatedRowsCount === 0) {
            return res.status(404).json({ error: 'Receivable not found' });
        }
        
        const updatedReceivable = await Receivable.findByPk(req.params.id, {
            include: [{
                model: ReceivablePayment,
                as: 'ReceivablePayments'
            }]
        });
        
        res.status(200).json(updatedReceivable);
    } catch (err) {
    console.error('Server error:', err);
    res.status(500).json({ message: 'Server error', error: err });
    }
};

export const deleteReceivable = async (req: Request, res: Response) => {
    try {
        const receivable = await Receivable.findByPk(req.params.id);
        
        if (!receivable) {
            return res.status(404).json({ error: 'Receivable not found' });
        }
        
        await receivable.destroy();
        res.status(200).json({ message: 'Receivable deleted successfully', receivable });
    } catch (err) {
    console.error('Server error:', err);
    res.status(500).json({ message: 'Server error', error: err });
    }
};

// Additional controller for managing receivable payments
export const addReceivablePayment = async (req: Request, res: Response) => {
    try {
        const { id: receivableId } = req.params;
        
        // Check if receivable exists
        const receivable = await Receivable.findByPk(receivableId);
        if (!receivable) {
            return res.status(404).json({ error: 'Receivable not found' });
        }
        
        const paymentData = {
            receivableId,
            ...req.body
        };
        
        const payment = await ReceivablePayment.create(paymentData);
        res.status(201).json(payment);
    } catch (err) {
    console.error('Server error:', err);
    res.status(500).json({ message: 'Server error', error: err });
    }
};

export const getReceivablePayments = async (req: Request, res: Response) => {
    try {
        const { id: receivableId } = req.params;
        
        const payments = await ReceivablePayment.findAll({
            where: { receivableId },
            order: [['date', 'DESC']]
        });
        
        res.status(200).json(payments);
    } catch (err) {
    console.error('Server error:', err);
    res.status(500).json({ message: 'Server error', error: err });
    }
};