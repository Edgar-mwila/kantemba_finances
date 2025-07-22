import type { Request, Response } from 'express';
import Receivable from '../models/receivable.model';

export const createReceivable = async (req: Request, res: Response) => {
    try {
        const receivable = new Receivable(req.body);
        await receivable.save();
        res.status(201).send(receivable);
    } catch (error) {
        res.status(400).send(error);
    }
};

export const getReceivables = async (req: Request, res: Response) => {
    try {
        const receivables = await Receivable.find(req.query);
        res.status(200).send(receivables);
    } catch (error) {
        res.status(500).send(error);
    }
};

export const getReceivableById = async (req: Request, res: Response) => {
    try {
        const receivable = await Receivable.findById(req.params.id);
        if (!receivable) {
            return res.status(404).send();
        }
        res.status(200).send(receivable);
    } catch (error) {
        res.status(500).send(error);
    }
};

export const updateReceivable = async (req: Request, res: Response) => {
    try {
        const receivable = await Receivable.findByIdAndUpdate(req.params.id, req.body, { new: true, runValidators: true });
        if (!receivable) {
            return res.status(404).send();
        }
        res.status(200).send(receivable);
    } catch (error) {
        res.status(400).send(error);
    }
};

export const deleteReceivable = async (req: Request, res: Response) => {
    try {
        const receivable = await Receivable.findByIdAndDelete(req.params.id);
        if (!receivable) {
            return res.status(404).send();
        }
        res.status(200).send(receivable);
    } catch (error) {
        res.status(500).send(error);
    }
}; 