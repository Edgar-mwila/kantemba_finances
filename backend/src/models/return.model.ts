import { DataTypes, Model } from 'sequelize';
import { sequelize } from '../utils/db';

export interface ReturnItemAttributes {
  id?: number;
  returnId?: string;
  productId: string;
  productName: string;
  quantity: number;
  originalPrice: number;
  reason: string;
}

export interface ReturnAttributes {
  id: string;
  originalSaleId: string;
  totalReturnAmount: number;
  grandReturnAmount: number;
  vat: number;
  turnoverTax: number;
  levy: number;
  date: Date;
  shopId: string;
  createdBy: string;
  reason: string;
  status: 'pending' | 'approved' | 'rejected' | 'completed';
}

export type ReturnCreationAttributes = ReturnAttributes;

export class Return extends Model<ReturnAttributes, ReturnCreationAttributes> implements ReturnAttributes {
  public id!: string;
  public originalSaleId!: string;
  public totalReturnAmount!: number;
  public grandReturnAmount!: number;
  public vat!: number;
  public turnoverTax!: number;
  public levy!: number;
  public date!: Date;
  public shopId!: string;
  public createdBy!: string;
  public reason!: string;
  public status!: 'pending' | 'approved' | 'rejected' | 'completed';

  // timestamps!
  public readonly createdAt!: Date;
  public readonly updatedAt!: Date;
}

export class ReturnItem extends Model<ReturnItemAttributes> implements ReturnItemAttributes {
  public id!: number;
  public returnId!: string;
  public productId!: string;
  public productName!: string;
  public quantity!: number;
  public originalPrice!: number;
  public reason!: string;
}

  Return.init(
    {
      id: { type: DataTypes.STRING, primaryKey: true },
      originalSaleId: { type: DataTypes.STRING, allowNull: false },
      totalReturnAmount: { type: DataTypes.FLOAT, allowNull: false, defaultValue: 0 },
      grandReturnAmount: { type: DataTypes.FLOAT, allowNull: false, defaultValue: 0 },
      vat: { type: DataTypes.FLOAT, allowNull: false, defaultValue: 0 },
      turnoverTax: { type: DataTypes.FLOAT, allowNull: false, defaultValue: 0 },
      levy: { type: DataTypes.FLOAT, allowNull: false, defaultValue: 0 },
      date: { type: DataTypes.DATE, allowNull: false, defaultValue: DataTypes.NOW },
      shopId: { type: DataTypes.STRING, allowNull: false },
      createdBy: { type: DataTypes.STRING, allowNull: false },
      reason: { type: DataTypes.STRING, allowNull: false },
      status: { 
        type: DataTypes.ENUM('pending', 'approved', 'rejected', 'completed'), 
        allowNull: false, 
        defaultValue: 'pending' 
      },
    },
    {
      sequelize,
      tableName: 'returns',
      indexes: [
        { fields: ['shopId'] },
        { fields: ['originalSaleId'] },
        { fields: ['status'] },
        { fields: ['date'] },
      ],
      timestamps: true,
    }
  );

  ReturnItem.init(
    {
      id: { type: DataTypes.INTEGER.UNSIGNED, autoIncrement: true, primaryKey: true },
      returnId: { type: DataTypes.STRING, allowNull: false },
      productId: { type: DataTypes.STRING, allowNull: false },
      productName: { type: DataTypes.STRING, allowNull: false },
      quantity: { type: DataTypes.INTEGER, allowNull: false, defaultValue: 1 },
      originalPrice: { type: DataTypes.FLOAT, allowNull: false, defaultValue: 0 },
      reason: { type: DataTypes.STRING, allowNull: false },
    },
    {
      sequelize,
      tableName: 'return_items',
      timestamps: false,
    }
  );

  Return.hasMany(ReturnItem, { foreignKey: 'returnId', as: 'items', onDelete: 'CASCADE' });
  ReturnItem.belongsTo(Return, { foreignKey: 'returnId', as: 'return' });