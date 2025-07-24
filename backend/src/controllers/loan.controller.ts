import type { Request, Response } from 'express';
import { Loan, LoanPayment } from '../models/loan.model';
import { Op } from 'sequelize';

export const createLoan = async (req: Request, res: Response) => {
    try {
        const loanData = {
            ...req.body
        };
        const loan = await Loan.create(loanData);
        res.status(201).json(loan);
    } catch (err) {
    console.error('Server error:', err);
    res.status(500).json({ message: 'Server error', error: err });
    }
};

export const getLoans = async (req: Request, res: Response) => {
    try {
        const where: any = {};
        
        // Build where clause from query parameters
        if (req.query.status) {
            where.status = req.query.status;
        }
        if (req.query.interestType) {
            where.interestType = req.query.interestType;
        }
        if (req.query.lenderName) {
            where.lenderName = {
                [Op.iLike]: `%${req.query.lenderName}%`
            };
        }
        
        const loans = await Loan.findAll({
            where,
            include: [{
                model: LoanPayment,
                as: 'LoanPayments'
            }],
            order: [['createdAt', 'DESC']]
        });
        
        res.status(200).json(loans);
    } catch (err) {
    console.error('Server error:', err);
    res.status(500).json({ message: 'Server error', error: err });
    }
};

export const getLoanById = async (req: Request, res: Response) => {
    try {
        const loan = await Loan.findByPk(req.params.id, {
            include: [{
                model: LoanPayment,
                as: 'LoanPayments',
                order: [['date', 'DESC']]
            }]
        });
        
        if (!loan) {
            return res.status(404).json({ error: 'Loan not found' });
        }
        
        res.status(200).json(loan);
    } catch (err) {
    console.error('Server error:', err);
    res.status(500).json({ message: 'Server error', error: err });
    }
};

export const updateLoan = async (req: Request, res: Response) => {
    try {
        const [updatedRowsCount] = await Loan.update(req.body, {
            where: { id: req.params.id },
            returning: true
        });
        
        if (updatedRowsCount === 0) {
            return res.status(404).json({ error: 'Loan not found' });
        }
        
        const updatedLoan = await Loan.findByPk(req.params.id, {
            include: [{
                model: LoanPayment,
                as: 'LoanPayments'
            }]
        });
        
        res.status(200).json(updatedLoan);
    } catch (err) {
    console.error('Server error:', err);
    res.status(500).json({ message: 'Server error', error: err });
    }
};

export const deleteLoan = async (req: Request, res: Response) => {
    try {
        const loan = await Loan.findByPk(req.params.id);
        
        if (!loan) {
            return res.status(404).json({ error: 'Loan not found' });
        }
        
        await loan.destroy();
        res.status(200).json({ message: 'Loan deleted successfully', loan });
    } catch (err) {
    console.error('Server error:', err);
    res.status(500).json({ message: 'Server error', error: err });
    }
};

// Additional controller for managing loan payments
export const addLoanPayment = async (req: Request, res: Response) => {
    try {
        const { id: loanId } = req.params;
        
        // Check if loan exists
        const loan = await Loan.findByPk(loanId);
        if (!loan) {
            return res.status(404).json({ error: 'Loan not found' });
        }
        
        const paymentData = {
            loanId,
            ...req.body
        };
        
        const payment = await LoanPayment.create(paymentData);
        res.status(201).json(payment);
    } catch (err) {
    console.error('Server error:', err);
    res.status(500).json({ message: 'Server error', error: err });
    }
};

export const getLoanPayments = async (req: Request, res: Response) => {
    try {
        const { id: loanId } = req.params;
        
        const payments = await LoanPayment.findAll({
            where: { loanId },
            order: [['date', 'DESC']]
        });
        
        res.status(200).json(payments);
    } catch (err) {
    console.error('Server error:', err);
    res.status(500).json({ message: 'Server error', error: err });
    }
};