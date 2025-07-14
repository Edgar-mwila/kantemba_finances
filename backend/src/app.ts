import express from 'express';
import cors from 'cors';
import path from 'path';
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

// Content types for file serving
const contentTypes: { [key: string]: string } = {
    '.html': 'text/html',
    '.css': 'text/css',
    '.js': 'application/javascript',
    '.json': 'application/json',
    '.png': 'image/png',
    '.jpg': 'image/jpeg',
    '.ico': 'image/x-icon',
    '.svg': 'image/svg+xml',
    '.apk': 'application/vnd.android.package-archive',
    '.exe': 'application/vnd.microsoft.portable-executable',
};

app.use(cors());
app.use(express.json());

// Serve static files with proper content types
app.use(express.static(path.join(__dirname, '../'), {
    setHeaders: (res, filePath) => {
        const ext = path.extname(filePath).toLowerCase();
        if (contentTypes[ext]) {
            res.setHeader('Content-Type', contentTypes[ext]);
        }
    }
}));

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