import { DataTypes, Model } from 'sequelize';
import type { Optional } from 'sequelize';
import { sequelize } from '../utils/db';

interface AnalyticsEventAttributes {
  id: number;
  type: string;
  timestamp: Date;
  event?: string | null;
  data?: any;
  error?: string | null;
  stack?: string | null;
  review?: string | null;
  rating?: number | null;
  user?: any;
}

interface AnalyticsEventCreationAttributes extends Optional<AnalyticsEventAttributes, 'id'> {}

class AnalyticsEvent extends Model<AnalyticsEventAttributes, AnalyticsEventCreationAttributes> implements AnalyticsEventAttributes {
  public id!: number;
  public type!: string;
  public timestamp!: Date;
  public event?: string | null;
  public data?: any;
  public error?: string | null;
  public stack?: string | null;
  public review?: string | null;
  public rating?: number | null;
  public user?: any;
}

AnalyticsEvent.init(
  {
    id: {
      type: DataTypes.INTEGER,
      autoIncrement: true,
      primaryKey: true
    },
    type: {
      type: DataTypes.STRING,
      allowNull: false,
    },
    timestamp: {
      type: DataTypes.DATE,
      allowNull: false,
    },
    event: {
      type: DataTypes.STRING,
      allowNull: true,
    },
    data: {
      type: DataTypes.JSON,
      allowNull: true,
    },
    error: {
      type: DataTypes.STRING,
      allowNull: true,
    },
    stack: {
      type: DataTypes.TEXT,
      allowNull: true,
    },
    review: {
      type: DataTypes.TEXT,
      allowNull: true,
    },
    rating: {
      type: DataTypes.INTEGER,
      allowNull: true,
    },
    user: {
      type: DataTypes.JSON,
      allowNull: true,
    },
  },
  {
    sequelize,
    modelName: 'AnalyticsEvent',
    tableName: 'analytics_events',
    timestamps: false,
  }
);

export { AnalyticsEvent };