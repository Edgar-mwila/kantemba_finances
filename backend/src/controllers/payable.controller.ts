import type { Request, Response } from 'express';
import Payable from '../models/payable.model';

export const createPayable = async (req: Request, res: Response) => {
    try {
        const payable = new Payable(req.body);
        await payable.save();
        res.status(201).send(payable);
    } catch (error) {
        res.status(400).send(error);
    }
};

export const getPayables = async (req: Request, res: Response) => {
    try {
        const payables = await Payable.find(req.query);
        res.status(200).send(payables);
    } catch (error) {
        res.status(500).send(error);
    }
};

export const getPayableById = async (req: Request, res: Response) => {
    try {
        const payable = await Payable.findById(req.params.id);
        if (!payable) {
            return res.status(404).send();
        }
        res.status(200).send(payable);
    } catch (error) {
        res.status(500).send(error);
    }
};

export const updatePayable = async (req: Request, res: Response) => {
    try {
        const payable = await Payable.findByIdAndUpdate(req.params.id, req.body, { new: true, runValidators: true });
        if (!payable) {
            return res.status(404).send();
        }
        res.status(200).send(payable);
    } catch (error) {
        res.status(400).send(error);
    }
};

export const deletePayable = async (req: Request, res: Response) => {
    try {
        const payable = await Payable.findByIdAndDelete(req.params.id);
        if (!payable) {
            return res.status(404).send();
        }
        res.status(200).send(payable);
    } catch (error) {
        res.status(500).send(error);
    }
}; 