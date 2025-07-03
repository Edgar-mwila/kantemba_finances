import { DataTypes, Model } from 'sequelize';
import type { Optional } from 'sequelize';
import { sequelize } from '../utils/db';

interface BusinessAttributes {
  id: string;
  name: string;
  street: string;
  township: string;
  city: string;
  province: string;
  country: string;
  businessContact: string;
  ownerName: string;
  ownerContact: string;
  isPremium: boolean;
}

interface BusinessCreationAttributes extends Optional<BusinessAttributes, 'id' | 'isPremium'> {}

class Business extends Model<BusinessAttributes, BusinessCreationAttributes> implements BusinessAttributes {
  public id!: string;
  public name!: string;
  public street!: string;
  public township!: string;
  public city!: string;
  public province!: string;
  public country!: string;
  public businessContact!: string;
  public ownerName!: string;
  public ownerContact!: string;
  public isPremium!: boolean;
}

Business.init(
  {
    id: {
      type: DataTypes.STRING,
      primaryKey: true,
    },
    name: DataTypes.STRING,
    street: DataTypes.STRING,
    township: DataTypes.STRING,
    city: DataTypes.STRING,
    province: DataTypes.STRING,
    country: DataTypes.STRING,
    businessContact: DataTypes.STRING,
    ownerName: DataTypes.STRING,
    ownerContact: DataTypes.STRING,
    isPremium: {
      type: DataTypes.BOOLEAN,
      defaultValue: false,
    },
  },
  {
    sequelize,
    modelName: 'Business',
    tableName: 'businesses',
    timestamps: false,
  }
);

export { Business };
