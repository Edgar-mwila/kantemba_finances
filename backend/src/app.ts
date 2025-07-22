import express from 'express';
import cors from 'cors';
import path from 'path';
import { fileURLToPath } from 'url';
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
import loanRoutes from './routes/loan.route';
import payableRoutes from './routes/payable.route';
import receivableRoutes from './routes/receivable.route';
import analyticsRoutes from './routes/analytics.route';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

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
app.use('/api/loans', loanRoutes);
app.use('/api/payables', payableRoutes);
app.use('/api/receivables', receivableRoutes);
app.use('/api/analytics', analyticsRoutes);

app.get('/dashboard', (req, res) => {
  res.sendFile(path.join(__dirname, 'dashboard.html'));
});

app.get('/api/health', (req, res) => {
    res.status(200).json({ status: 'ok' });
});

const port = process.env.PORT || 3000;

app.listen(port, () => {
    console.log(`Server is running on port ${port}`);
});

export { app };