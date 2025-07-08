import { DataTypes, Model } from 'sequelize';
import { sequelize } from '../utils/db';
import { User } from './user.model';
import { Shop } from './shop.model';

class ManagerShops extends Model {
  public userId!: string;
  public shopId!: string;
}

ManagerShops.init(
  {
    userId: {
      type: DataTypes.STRING,
      allowNull: false,
      references: {
        model: User,
        key: 'id',
      },
      onDelete: 'CASCADE',
    },
    shopId: {
      type: DataTypes.STRING,
      allowNull: false,
      references: {
        model: Shop,
        key: 'id',
      },
      onDelete: 'CASCADE',
    },
  },
  {
    sequelize,
    modelName: 'ManagerShops',
    tableName: 'manager_shops',
    timestamps: false,
  }
);

export { ManagerShops }; 