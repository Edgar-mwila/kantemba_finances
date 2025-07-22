import { DataTypes, Model } from 'sequelize';
import type { Optional } from 'sequelize';
import { sequelize } from '../utils/db';
import { User } from './user.model';
import { Shop } from './shop.model';

interface InventoryAttributes {
  id: string;
  name: string;
  price: number;
  quantity: number;
  lowStockThreshold: number;
  createdBy: string;
  shopId?: string | null;
  barcode?: string | null; // Add barcode field
  damagedRecords?: string | null;
}

interface InventoryCreationAttributes extends Optional<InventoryAttributes, 'id' | 'lowStockThreshold'> {}

class Inventory extends Model<InventoryAttributes, InventoryCreationAttributes> implements InventoryAttributes {
  public id!: string;
  public name!: string;
  public price!: number;
  public quantity!: number;
  public lowStockThreshold!: number;
  public createdBy!: string;
  public shopId?: string | null;
  public barcode?: string | null; // Add barcode field
  public damagedRecords?: string | null;
}

Inventory.init(
  {
    id: {
      type: DataTypes.STRING,
      primaryKey: true,
    },
    name: DataTypes.STRING,
    price: DataTypes.FLOAT,
    quantity: DataTypes.INTEGER,
    lowStockThreshold: {
      type: DataTypes.INTEGER,
      defaultValue: 5,
    },
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
        model: Shop,
        key: 'id',
      },
      onDelete: 'SET NULL',
    },
    barcode: {
      type: DataTypes.STRING,
      allowNull: true,
      unique: true, // Ensure unique barcodes
    },
    damagedRecords: {
      type: DataTypes.TEXT,
      allowNull: true,
      defaultValue: '[]',
    },
  },
  {
    sequelize,
    modelName: 'Inventory',
    tableName: 'inventories',
    timestamps: false,
  }
);

Inventory.belongsTo(Shop, { foreignKey: 'shopId' });
Shop.hasMany(Inventory, { foreignKey: 'shopId' });
Inventory.belongsTo(User, { foreignKey: 'createdBy' });
User.hasMany(Inventory, { foreignKey: 'createdBy' });

export { Inventory };
