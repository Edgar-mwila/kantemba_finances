import { DataTypes, Model } from 'sequelize';
import type { Optional } from 'sequelize';
import { sequelize } from '../utils/db';
import { Business } from './business.model';
import { User } from './user.model';
import { Inventory } from './inventory.model';
import { Shop } from './shop.model';

interface SaleAttributes {
  id: string;
  totalAmount: number;
  grandTotal: number;
  vat: number;
  turnoverTax: number;
  levy: number;
  date: Date;
  createdBy: string;
  shopId?: string | null;
}

interface SaleCreationAttributes extends Optional<SaleAttributes, 'id'> {}

class Sale extends Model<SaleAttributes, SaleCreationAttributes> implements SaleAttributes {
  public id!: string;
  public totalAmount!: number;
  public grandTotal!: number;
  public vat!: number;
  public turnoverTax!: number;
  public levy!: number;
  public date!: Date;
  public createdBy!: string;
  public shopId?: string | null;
}

Sale.init(
  {
    id: {
      type: DataTypes.STRING,
      primaryKey: true,
    },
    totalAmount: DataTypes.FLOAT,
    grandTotal: DataTypes.FLOAT,
    vat: DataTypes.FLOAT,
    turnoverTax: DataTypes.FLOAT,
    levy: DataTypes.FLOAT,
    date: DataTypes.DATE,
    createdBy: {
      type: DataTypes.STRING,
      allowNull: false,
      references: {
        model: User,
        key: 'id',
      },
    },
    shopId: {
      type: DataTypes.STRING,
      allowNull: true,
      references: {
        model: 'shops',
        key: 'id',
      },
      onDelete: 'SET NULL',
    },
  },
  {
    sequelize,
    modelName: 'Sale',
    tableName: 'sales',
    timestamps: false,
  }
);

interface SaleItemAttributes {
  id?: number;
  saleId: string;
  productId: string;
  productName: string;
  price: number;
  quantity: number;
}

class SaleItem extends Model<SaleItemAttributes> implements SaleItemAttributes {
  public id!: number;
  public saleId!: string;
  public productId!: string;
  public productName!: string;
  public price!: number;
  public quantity!: number;
}

SaleItem.init(
  {
    id: {
      type: DataTypes.INTEGER,
      autoIncrement: true,
      primaryKey: true,
    },
    saleId: {
      type: DataTypes.STRING,
      allowNull: false,
      references: {
        model: Sale,
        key: 'id',
      },
      onDelete: 'CASCADE',
    },
    productId: {
      type: DataTypes.STRING,
      allowNull: false,
      references: {
        model: Inventory,
        key: 'id',
      },
    },
    productName: DataTypes.STRING,
    price: DataTypes.FLOAT,
    quantity: DataTypes.INTEGER,
  },
  {
    sequelize,
    modelName: 'SaleItem',
    tableName: 'sale_items',
    timestamps: false,
  }
);

Sale.belongsTo(Shop, { foreignKey: 'shopId' });
Shop.hasMany(Sale, { foreignKey: 'shopId' });
Sale.belongsTo(User, { foreignKey: 'createdBy' });
User.hasMany(Sale, { foreignKey: 'createdBy' });
Sale.hasMany(SaleItem, { foreignKey: 'saleId' });
SaleItem.belongsTo(Sale, { foreignKey: 'saleId' });
Inventory.hasMany(SaleItem, { foreignKey: 'productId' });
SaleItem.belongsTo(Inventory, { foreignKey: 'productId' });

export { Sale, SaleItem };
