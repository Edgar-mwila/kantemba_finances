import { Sequelize } from 'sequelize'

export const sequelize = new Sequelize(
  process.env.MYSQL_DATABASE || 'kantemba',
  process.env.MYSQL_USER || 'root',
  process.env.MYSQL_PASSWORD || '',
  {
    host: process.env.MYSQL_HOST || 'localhost',
    port: Number(process.env.MYSQL_PORT) || 3306,
    dialect: 'mysql',
    logging: false,
  }
);

export const connectDB = async () => {
  try {
    await sequelize.authenticate();
    await sequelize.sync(); // auto-create tables if not exist
    console.log('MySQL connected');
  } catch (err) {
    console.error('MySQL connection error:', err);
    process.exit(1);
  }
};