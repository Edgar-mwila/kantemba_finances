import { DataTypes, Model } from 'sequelize';
import type { Optional } from 'sequelize';
import { sequelize } from '../utils/db';
import { Business } from './business.model';

export enum UserRole {
  admin = 'admin',
  manager = 'manager',
  employee = 'employee',
}

interface UserAttributes {
  id: string;
  name: string;
  contact: string;
  password: string;
  role: UserRole;
  permissions: string[];
  businessId: string;
  shopId?: string | null;
}

interface UserCreationAttributes extends Optional<UserAttributes, 'id'> {}

class User extends Model<UserAttributes, UserCreationAttributes> implements UserAttributes {
  public id!: string;
  public name!: string;
  public contact!: string;
  public password!: string;
  public role!: UserRole;
  public permissions!: string[];
  public businessId!: string;
  public shopId?: string | null;
}

User.init(
  {
    id: {
      type: DataTypes.STRING,
      primaryKey: true,
    },
    name: DataTypes.STRING,
    password: DataTypes.STRING,
    contact: {
      type: DataTypes.STRING,
      allowNull: false,
      unique: true,
    },
    role: {
      type: DataTypes.ENUM('admin', 'manager', 'employee'),
      allowNull: false,
    },
    permissions: {
      type: DataTypes.JSON,
      allowNull: false,
      defaultValue: [],
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
    modelName: 'User',
    tableName: 'users',
    timestamps: false,
  }
);

User.belongsTo(Business, { foreignKey: 'businessId' });
Business.hasMany(User, { foreignKey: 'businessId' });

export { User };
