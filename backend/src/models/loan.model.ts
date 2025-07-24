import { DataTypes, Model } from 'sequelize';
import type { Optional } from 'sequelize';
import { sequelize } from '../utils/db';

interface LoanPaymentAttributes {
  id?: number;
  loanId: string;
  amount: number;
  date: Date;
  method: string;
}

interface LoanAttributes {
  id: string;
  lenderName: string;
  lenderContact: string;
  lenderAddress?: string | null;
  principal: number;
  interestType: 'fixed' | 'percentage';
  interestValue: number;
  dueDate: Date;
  paymentPlan: string;
  status: 'active' | 'paid' | 'overdue';
  createdAt: Date;
  updatedAt: Date;
}

interface LoanCreationAttributes extends Optional<LoanAttributes, 'id' | 'createdAt' | 'updatedAt'> {}

class Loan extends Model<LoanAttributes, LoanCreationAttributes> implements LoanAttributes {
  public id!: string;
  public lenderName!: string;
  public lenderContact!: string;
  public lenderAddress?: string | null;
  public principal!: number;
  public interestType!: 'fixed' | 'percentage';
  public interestValue!: number;
  public dueDate!: Date;
  public paymentPlan!: string;
  public status!: 'active' | 'paid' | 'overdue';
  public createdAt!: Date;
  public updatedAt!: Date;
}

class LoanPayment extends Model<LoanPaymentAttributes> implements LoanPaymentAttributes {
  public id!: number;
  public loanId!: string;
  public amount!: number;
  public date!: Date;
  public method!: string;
}

Loan.init(
  {
    id: {
      type: DataTypes.STRING,
      primaryKey: true,
    },
    lenderName: {
      type: DataTypes.STRING,
      allowNull: false,
    },
    lenderContact: {
      type: DataTypes.STRING,
      allowNull: false,
    },
    lenderAddress: {
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
    modelName: 'Loan',
    tableName: 'loans',
    timestamps: true,
  }
);

LoanPayment.init(
  {
    id: {
      type: DataTypes.INTEGER,
      autoIncrement: true,
      primaryKey: true,
    },
    loanId: {
      type: DataTypes.STRING,
      allowNull: false,
      references: {
        model: Loan,
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
    modelName: 'LoanPayment',
    tableName: 'loan_payments',
    timestamps: false,
  }
);

Loan.hasMany(LoanPayment, { foreignKey: 'loanId' });
LoanPayment.belongsTo(Loan, { foreignKey: 'loanId' });

export { Loan, LoanPayment };