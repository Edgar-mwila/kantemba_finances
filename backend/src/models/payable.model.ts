import { DataTypes, Model } from 'sequelize';
import type { Optional } from 'sequelize';
import { sequelize } from '../utils/db';

interface PayablePaymentAttributes {
  id?: number;
  payableId: string;
  amount: number;
  date: Date;
  method: string;
}

interface PayableAttributes {
  id: string;
  name: string;
  contact: string;
  address?: string | null;
  principal: number;
  interestType: 'fixed' | 'percentage';
  interestValue: number;
  dueDate: Date;
  paymentPlan: string;
  status: 'active' | 'paid' | 'overdue';
  createdAt: Date;
  updatedAt: Date;
}

interface PayableCreationAttributes extends Optional<PayableAttributes, 'id' | 'createdAt' | 'updatedAt'> {}

class Payable extends Model<PayableAttributes, PayableCreationAttributes> implements PayableAttributes {
  public id!: string;
  public name!: string;
  public contact!: string;
  public address?: string | null;
  public principal!: number;
  public interestType!: 'fixed' | 'percentage';
  public interestValue!: number;
  public dueDate!: Date;
  public paymentPlan!: string;
  public status!: 'active' | 'paid' | 'overdue';
  public createdAt!: Date;
  public updatedAt!: Date;
}

class PayablePayment extends Model<PayablePaymentAttributes> implements PayablePaymentAttributes {
  public id!: number;
  public payableId!: string;
  public amount!: number;
  public date!: Date;
  public method!: string;
}

Payable.init(
  {
    id: {
      type: DataTypes.STRING,
      primaryKey: true,
    },
    name: {
      type: DataTypes.STRING,
      allowNull: false,
    },
    contact: {
      type: DataTypes.STRING,
      allowNull: false,
    },
    address: {
      type: DataTypes.STRING,
      allowNull: true,
    },
    principal: {
      type: DataTypes.FLOAT,
      allowNull: false,
    },
    interestType: {
      type: DataTypes.ENUM('fixed', 'percentage'),
      allowNull: false,
    },
    interestValue: {
      type: DataTypes.FLOAT,
      allowNull: false,
    },
    dueDate: {
      type: DataTypes.DATE,
      allowNull: false,
    },
    paymentPlan: {
      type: DataTypes.STRING,
      allowNull: false,
    },
    status: {
      type: DataTypes.ENUM('active', 'paid', 'overdue'),
      allowNull: false,
      defaultValue: 'active',
    },
    createdAt: {
      type: DataTypes.DATE,
      allowNull: false,
      defaultValue: DataTypes.NOW,
    },
    updatedAt: {
      type: DataTypes.DATE,
      allowNull: false,
      defaultValue: DataTypes.NOW,
    },
  },
  {
    sequelize,
    modelName: 'Payable',
    tableName: 'payables',
    timestamps: true,
  }
);

PayablePayment.init(
  {
    id: {
      type: DataTypes.INTEGER,
      autoIncrement: true,
      primaryKey: true,
    },
    payableId: {
      type: DataTypes.STRING,
      allowNull: false,
      references: {
        model: Payable,
        key: 'id',
      },
      onDelete: 'CASCADE',
    },
    amount: {
      type: DataTypes.FLOAT,
      allowNull: false,
    },
    date: {
      type: DataTypes.DATE,
      allowNull: false,
    },
    method: {
      type: DataTypes.STRING,
      allowNull: false,
    },
  },
  {
    sequelize,
    modelName: 'PayablePayment',
    tableName: 'payable_payments',
    timestamps: false,
  }
);

Payable.hasMany(PayablePayment, { foreignKey: 'payableId' });
PayablePayment.belongsTo(Payable, { foreignKey: 'payableId' });

export { Payable, PayablePayment };