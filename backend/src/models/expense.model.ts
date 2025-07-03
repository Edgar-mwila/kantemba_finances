import { DataTypes, Model } from 'sequelize';
import type { Optional } from 'sequelize';
import { sequelize } from '../utils/db';
import { Business } from './business.model';
import { User } from './user.model';

interface ExpenseAttributes {
  id: string;
  description: string;
  amount: number;
  date: Date;
  category: string;
  createdBy: string;
  businessId: string;
}

interface ExpenseCreationAttributes extends Optional<ExpenseAttributes, 'id' | 'category'> {}

class Expense extends Model<ExpenseAttributes, ExpenseCreationAttributes> implements ExpenseAttributes {
  public id!: string;
  public description!: string;
  public amount!: number;
  public date!: Date;
  public category!: string;
  public createdBy!: string;
  public businessId!: string;
}

Expense.init(
  {
    id: {
      type: DataTypes.STRING,
      primaryKey: true,
    },
    description: DataTypes.STRING,
    amount: DataTypes.FLOAT,
    date: DataTypes.DATE,
    category: {
      type: DataTypes.STRING,
      defaultValue: 'Uncategorized',
    },
    createdBy: {
      type: DataTypes.STRING,
      allowNull: false,
      references: {
        model: User,
        key: 'id',
      },
    },
    businessId: {
      type: DataTypes.STRING,
      allowNull: false,
      references: {
        model: Business,
        key: 'id',
      },
      onDelete: 'CASCADE',
    },
  },
  {
    sequelize,
    modelName: 'Expense',
    tableName: 'expenses',
    timestamps: false,
  }
);

Expense.belongsTo(Business, { foreignKey: 'businessId' });
Business.hasMany(Expense, { foreignKey: 'businessId' });
Expense.belongsTo(User, { foreignKey: 'createdBy' });
User.hasMany(Expense, { foreignKey: 'createdBy' });

export { Expense };
