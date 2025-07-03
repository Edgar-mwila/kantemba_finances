import { DataTypes, Model } from 'sequelize';
import type { Optional } from 'sequelize';
import { sequelize } from '../utils/db';
import { Business } from './business.model';
import { User } from './user.model';

interface InventoryAttributes {
  id: string;
  name: string;
  price: number;
  quantity: number;
  lowStockThreshold: number;
  createdBy: string;
  businessId: string;
}

interface InventoryCreationAttributes extends Optional<InventoryAttributes, 'id' | 'lowStockThreshold'> {}

class Inventory extends Model<InventoryAttributes, InventoryCreationAttributes> implements InventoryAttributes {
  public id!: string;
  public name!: string;
  public price!: number;
  public quantity!: number;
  public lowStockThreshold!: number;
  public createdBy!: string;
  public businessId!: string;
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
    modelName: 'Inventory',
    tableName: 'inventories',
    timestamps: false,
  }
);

Inventory.belongsTo(Business, { foreignKey: 'businessId' });
Business.hasMany(Inventory, { foreignKey: 'businessId' });
Inventory.belongsTo(User, { foreignKey: 'createdBy' });
User.hasMany(Inventory, { foreignKey: 'createdBy' });

export { Inventory };
