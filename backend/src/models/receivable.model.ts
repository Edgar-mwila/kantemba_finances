import { Schema, model, Document } from 'mongoose';

export interface IReceivablePayment {
  amount: number;
  date: Date;
  method: string;
}

export interface IReceivable extends Document {
  name: string;
  contact: string;
  address?: string;
  principal: number;
  interestType: 'fixed' | 'percentage';
  interestValue: number;
  dueDate: Date;
  paymentPlan: string;
  paymentHistory: IReceivablePayment[];
  status: 'active' | 'paid' | 'overdue';
  createdAt: Date;
  updatedAt: Date;
}

const ReceivablePaymentSchema = new Schema<IReceivablePayment>({
  amount: { type: Number, required: true },
  date: { type: Date, required: true },
  method: { type: String, required: true },
});

const ReceivableSchema = new Schema<IReceivable>({
  name: { type: String, required: true },
  contact: { type: String, required: true },
  address: { type: String },
  principal: { type: Number, required: true },
  interestType: { type: String, enum: ['fixed', 'percentage'], required: true },
  interestValue: { type: Number, required: true },
  dueDate: { type: Date, required: true },
  paymentPlan: { type: String, required: true },
  paymentHistory: { type: [ReceivablePaymentSchema], default: [] },
  status: { type: String, enum: ['active', 'paid', 'overdue'], default: 'active' },
  createdAt: { type: Date, default: Date.now },
  updatedAt: { type: Date, default: Date.now },
});

export default model<IReceivable>('Receivable', ReceivableSchema); 