import express from 'express';
import cors from 'cors';
import businessRoutes from './routes/business.route';
import userRoutes from './routes/user.route';
import inventoryRoutes from './routes/inventory.route';
import expensesRoutes from './routes/expenses.route';
import salesRoutes from './routes/sales.route';
import shopRoutes from './routes/shop.route';
import syncRoutes from './routes/sync.route';
import saleItemRoutes from './routes/sale_item.route';
import returnsRoutes from './routes/returns.route';
import aiRoutes from './routes/ai.route';

const app = express();

app.use(cors());
app.use(express.json());

app.use('/api/business', businessRoutes);
app.use('/api/users', userRoutes);
app.use('/api/inventory', inventoryRoutes);
app.use('/api/expenses', expensesRoutes);
app.use('/api/sales', salesRoutes);
app.use('/api/shops', shopRoutes);
app.use('/api/sync', syncRoutes);
app.use('/api/sale_items', saleItemRoutes);
app.use('/api/returns', returnsRoutes);
app.use('/api/ai', aiRoutes);
app.get('/api/health', (req, res) => {
    res.status(200).json({ status: 'ok' });
});

export { app };