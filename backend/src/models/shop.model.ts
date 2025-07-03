import { DataTypes, Model } from 'sequelize';
import type { Optional } from 'sequelize';
import { sequelize } from '../utils/db';
import { Business } from './business.model';

interface ShopAttributes {
  id: string;
  name: string;
  location: string;
  businessId: string;
}

interface ShopCreationAttributes extends Optional<ShopAttributes, 'id'> {}

class Shop extends Model<ShopAttributes, ShopCreationAttributes> implements ShopAttributes {
  public id!: string;
  public name!: string;
  public location!: string;
  public businessId!: string;
}

Shop.init(
  {
    id: {
      type: DataTypes.STRING,
      primaryKey: true,
    },
    name: DataTypes.STRING,
    location: DataTypes.STRING,
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
    modelName: 'Shop',
    tableName: 'shops',
    timestamps: false,
  }
);

Shop.belongsTo(Business, { foreignKey: 'businessId' });
Business.hasMany(Shop, { foreignKey: 'businessId' });

export { Shop };
