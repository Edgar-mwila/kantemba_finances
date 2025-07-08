import { DataTypes, Model } from 'sequelize';
import type { Optional } from 'sequelize';
import { sequelize } from '../utils/db';

interface BusinessAttributes {
  id: string;
  name: string;
  // street: string;
  // township: string;
  // city: string;
  // province: string;
  country: string;
  businessContact: string;
  adminName: string;
  adminContact: string;
  isPremium: boolean;
  subscriptionType?: 'monthly' | 'yearly';
  subscriptionStartDate?: Date;
  subscriptionExpiryDate?: Date;
  trialUsed?: boolean;
  lastPaymentTxRef?: string;
}

interface BusinessCreationAttributes extends Optional<BusinessAttributes, 'id' | 'isPremium' | 'subscriptionType' | 'subscriptionStartDate' | 'subscriptionExpiryDate' | 'trialUsed' | 'lastPaymentTxRef'> {}

class Business extends Model<BusinessAttributes, BusinessCreationAttributes> implements BusinessAttributes {
  public id!: string;
  public name!: string;
  // public street!: string;
  // public township!: string;
  // public city!: string;
  // public province!: string;
  public country!: string;
  public businessContact!: string;
  public adminName!: string;
  public adminContact!: string;
  public isPremium!: boolean;
  public subscriptionType?: 'monthly' | 'yearly';
  public subscriptionStartDate?: Date;
  public subscriptionExpiryDate?: Date;
  public trialUsed?: boolean;
  public lastPaymentTxRef?: string;
}

Business.init(
  {
    id: {
      type: DataTypes.STRING,
      primaryKey: true,
    },
    name: DataTypes.STRING,
    // street: DataTypes.STRING,
    // township: DataTypes.STRING,
    // city: DataTypes.STRING,
    // province: DataTypes.STRING,
    country: DataTypes.STRING,
    businessContact: DataTypes.STRING,
    adminName: DataTypes.STRING,
    adminContact: DataTypes.STRING,
    isPremium: {
      type: DataTypes.BOOLEAN,
      defaultValue: false,
    },
    subscriptionType: DataTypes.STRING,
    subscriptionStartDate: DataTypes.DATE,
    subscriptionExpiryDate: DataTypes.DATE,
    trialUsed: DataTypes.BOOLEAN,
    lastPaymentTxRef: DataTypes.STRING,
  },
  {
    sequelize,
    modelName: 'Business',
    tableName: 'businesses',
    timestamps: false,
  }
);

export { Business };
