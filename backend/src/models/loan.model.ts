import { Schema, model, Document } from 'mongoose';

export interface ILoanPayment {
  amount: number;
  date: Date;
  method: string;
}

export interface ILoan extends Document {
  lenderName: string;
  lenderContact: string;
  lenderAddress?: string;
  principal: number;
  interestType: 'fixed' | 'percentage';
  interestValue: number;
  dueDate: Date;
  paymentPlan: string;
  paymentHistory: ILoanPayment[];
  status: 'active' | 'paid' | 'overdue';
  createdAt: Date;
  updatedAt: Date;
}

const LoanPaymentSchema = new Schema<ILoanPayment>({
  amount: { type: Number, required: true },
  date: { type: Date, required: true },
  method: { type: String, required: true },
});

const LoanSchema = new Schema<ILoan>({
  lenderName: { type: String, required: true },
  lenderContact: { type: String, required: true },
  lenderAddress: { type: String },
  principal: { type: Number, required: true },
  interestType: { type: String, enum: ['fixed', 'percentage'], required: true },
  interestValue: { type: Number, required: true },
  dueDate: { type: Date, required: true },
  paymentPlan: { type: String, required: true },
  paymentHistory: { type: [LoanPaymentSchema], default: [] },
  status: { type: String, enum: ['active', 'paid', 'overdue'], default: 'active' },
  createdAt: { type: Date, default: Date.now },
  updatedAt: { type: Date, default: Date.now },
});

export default model<ILoan>('Loan', LoanSchema); 