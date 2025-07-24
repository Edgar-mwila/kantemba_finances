import type { Request, Response } from 'express';
import { Payable, PayablePayment } from '../models/payable.model';
import { Op } from 'sequelize';

export const createPayable = async (req: Request, res: Response) => {
    try {
        const payableData = {
            ...req.body
        };
        const payable = await Payable.create(payableData);
        res.status(201).json(payable);
    } catch (err) {
    console.error('Server error:', err);
    res.status(500).json({ message: 'Server error', error: err });
    }
};

export const getPayables = async (req: Request, res: Response) => {
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
        
        const payables = await Payable.findAll({
            where,
            include: [{
                model: PayablePayment,
                as: 'PayablePayments'
            }],
            order: [['createdAt', 'DESC']]
        });
        
        res.status(200).json(payables);
    } catch (err) {
    console.error('Server error:', err);
    res.status(500).json({ message: 'Server error', error: err });
    }
};

export const getPayableById = async (req: Request, res: Response) => {
    try {
        const payable = await Payable.findByPk(req.params.id, {
            include: [{
                model: PayablePayment,
                as: 'PayablePayments',
                order: [['date', 'DESC']]
            }]
        });
        
        if (!payable) {
            return res.status(404).json({ error: 'Payable not found' });
        }
        
        res.status(200).json(payable);
    } catch (err) {
    console.error('Server error:', err);
    res.status(500).json({ message: 'Server error', error: err });
    }
};

export const updatePayable = async (req: Request, res: Response) => {
    try {
        const [updatedRowsCount] = await Payable.update(req.body, {
            where: { id: req.params.id },
            returning: true
        });
        
        if (updatedRowsCount === 0) {
            return res.status(404).json({ error: 'Payable not found' });
        }
        
        const updatedPayable = await Payable.findByPk(req.params.id, {
            include: [{
                model: PayablePayment,
                as: 'PayablePayments'
            }]
        });
        
        res.status(200).json(updatedPayable);
    } catch (err) {
    console.error('Server error:', err);
    res.status(500).json({ message: 'Server error', error: err });
    }
};

export const deletePayable = async (req: Request, res: Response) => {
    try {
        const payable = await Payable.findByPk(req.params.id);
        
        if (!payable) {
            return res.status(404).json({ error: 'Payable not found' });
        }
        
        await payable.destroy();
        res.status(200).json({ message: 'Payable deleted successfully', payable });
    } catch (err) {
    console.error('Server error:', err);
    res.status(500).json({ message: 'Server error', error: err });
    }
};

// Additional controller for managing payable payments
export const addPayablePayment = async (req: Request, res: Response) => {
    try {
        const { id: payableId } = req.params;
        
        // Check if payable exists
        const payable = await Payable.findByPk(payableId);
        if (!payable) {
            return res.status(404).json({ error: 'Payable not found' });
        }
        
        const paymentData = {
            payableId,
            ...req.body
        };
        
        const payment = await PayablePayment.create(paymentData);
        res.status(201).json(payment);
    } catch (err) {
    console.error('Server error:', err);
    res.status(500).json({ message: 'Server error', error: err });
    }
};

export const getPayablePayments = async (req: Request, res: Response) => {
    try {
        const { id: payableId } = req.params;
        
        const payments = await PayablePayment.findAll({
            where: { payableId },
            order: [['date', 'DESC']]
        });
        
        res.status(200).json(payments);
    } catch (err) {
    console.error('Server error:', err);
    res.status(500).json({ message: 'Server error', error: err });
    }
};