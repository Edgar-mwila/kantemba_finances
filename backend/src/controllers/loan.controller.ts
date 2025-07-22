import type { Request, Response } from 'express';
import Loan from '../models/loan.model';

export const createLoan = async (req: Request, res: Response) => {
    try {
        const loan = new Loan(req.body);
        await loan.save();
        res.status(201).send(loan);
    } catch (error) {
        res.status(400).send(error);
    }
};

export const getLoans = async (req: Request, res: Response) => {
    try {
        const loans = await Loan.find(req.query);
        res.status(200).send(loans);
    } catch (error) {
        res.status(500).send(error);
    }
};

export const getLoanById = async (req: Request, res: Response) => {
    try {
        const loan = await Loan.findById(req.params.id);
        if (!loan) {
            return res.status(404).send();
        }
        res.status(200).send(loan);
    } catch (error) {
        res.status(500).send(error);
    }
};

export const updateLoan = async (req: Request, res: Response) => {
    try {
        const loan = await Loan.findByIdAndUpdate(req.params.id, req.body, { new: true, runValidators: true });
        if (!loan) {
            return res.status(404).send();
        }
        res.status(200).send(loan);
    } catch (error) {
        res.status(400).send(error);
    }
};

export const deleteLoan = async (req: Request, res: Response) => {
    try {
        const loan = await Loan.findByIdAndDelete(req.params.id);
        if (!loan) {
            return res.status(404).send();
        }
        res.status(200).send(loan);
    } catch (error) {
        res.status(500).send(error);
    }
}; 