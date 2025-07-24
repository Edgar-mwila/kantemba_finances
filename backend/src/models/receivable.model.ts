import { DataTypes, Model } from 'sequelize';
import type { Optional } from 'sequelize';
import { sequelize } from '../utils/db';

interface ReceivablePaymentAttributes {
  id?: number;
  receivableId: string;
  amount: number;
  date: Date;
  method: string;
}

interface ReceivableAttributes {
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

interface ReceivableCreationAttributes extends Optional<ReceivableAttributes, 'id' | 'createdAt' | 'updatedAt'> {}

class Receivable extends Model<ReceivableAttributes, ReceivableCreationAttributes> implements ReceivableAttributes {
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

class ReceivablePayment extends Model<ReceivablePaymentAttributes> implements ReceivablePaymentAttributes {
  public id!: number;
  public receivableId!: string;
  public amount!: number;
  public date!: Date;
  public method!: string;
}

Receivable.init(
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
    modelName: 'Receivable',
    tableName: 'receivables',
    timestamps: true,
  }
);

ReceivablePayment.init(
  {
    id: {
      type: DataTypes.INTEGER,
      autoIncrement: true,
      primaryKey: true,
    },
    receivableId: {
      type: DataTypes.STRING,
      allowNull: false,
      references: {
        model: Receivable,
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
    modelName: 'ReceivablePayment',
    tableName: 'receivable_payments',
    timestamps: false,
  }
);

Receivable.hasMany(ReceivablePayment, { foreignKey: 'receivableId' });
ReceivablePayment.belongsTo(Receivable, { foreignKey: 'receivableId' });

export { Receivable, ReceivablePayment };