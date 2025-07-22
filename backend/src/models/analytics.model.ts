import { Schema, model, Document } from 'mongoose';

export interface IAnalyticsEvent extends Document {
  type: string;
  timestamp: Date;
  event?: string;
  data?: any;
  error?: string;
  stack?: string;
  review?: string;
  rating?: number;
  user?: any;
}

const AnalyticsSchema = new Schema<IAnalyticsEvent>({
  type: { type: String, required: true },
  timestamp: { type: Date, required: true },
  event: { type: String },
  data: { type: Schema.Types.Mixed },
  error: { type: String },
  stack: { type: String },
  review: { type: String },
  rating: { type: Number },
  user: { type: Schema.Types.Mixed },
});

export default model<IAnalyticsEvent>('Analytics', AnalyticsSchema); 