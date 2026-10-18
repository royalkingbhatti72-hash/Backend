import express from 'express';
import cors from 'cors';
import morgan from 'morgan';

import authRoutes from './routes/authRoutes';
import userRoutes from './routes/userRoutes';
import taskRoutes from './routes/taskRoutes';
import walletRoutes from './routes/walletRoutes';
import depositRoutes from './routes/depositRoutes';
import withdrawalRoutes from './routes/withdrawalRoutes';
import spinRoutes from './routes/spinRoutes';
import referralRoutes from './routes/referralRoutes';
import notificationRoutes from './routes/notificationRoutes';
import settingsRoutes from './routes/settingsRoutes';
import adminRoutes from './routes/adminRoutes';
import { errorHandler } from './middleware/errorHandler';
import { config } from './config';
import { getAdminSpaHtml } from './views/adminHtml';

export function createApp() {
  const app = express();

  // CORS - allow requests from any frontend origin with credentials support
  app.use(cors({
    origin: (origin, callback) => {
      callback(null, true);
    },
    credentials: true,
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With'],
  }));

  app.use(express.json());
  app.use(express.urlencoded({ extended: true }));

  if (process.env.NODE_ENV !== 'test') {
    app.use(morgan('dev'));
  }

  // Normalize Vercel rewritten URL from x-matched-path if present
  app.use((req, res, next) => {
    const matchedPath = req.headers['x-matched-path'] as string | undefined;
    if (matchedPath && matchedPath !== '/api/index') {
      req.url = matchedPath;
    }
    next();
  });

  // API Routes
  app.use('/api/auth', authRoutes);
  app.use('/api/user', userRoutes);
  app.use('/api/tasks', taskRoutes);
  app.use('/api/wallet', walletRoutes);
  app.use('/api/deposits', depositRoutes);
  app.use('/api/withdrawals', withdrawalRoutes);
  app.use('/api/spin', spinRoutes);
  app.use('/api/referrals', referralRoutes);
  app.use('/api/notifications', notificationRoutes);
  app.use('/api/settings', settingsRoutes);
  app.use('/api/admin', adminRoutes);

  // Root & Health check endpoints
  app.get(['/api', '/api/index'], (req, res) => {
    res.json({
      name: 'Earn Sheet API Server',
      status: 'online',
      message: 'Backend API server is running.',
      endpoints: {
        health: '/api/health',
        publicSettings: '/api/settings/public',
      },
    });
  });

  app.get('/api/health', (req, res) => {
    res.json({ status: 'ok', name: 'Earn Sheet API', timestamp: new Date() });
  });

  // Serve the complete Royal Administration Portal SPA on any non-API GET route
  app.use((req, res, next) => {
    if (req.method === 'GET' && !req.path.startsWith('/api')) {
      res.setHeader('Content-Type', 'text/html; charset=utf-8');
      return res.send(getAdminSpaHtml());
    }
    next();
  });

  // Chrome DevTools probe & favicon handlers to prevent 404 warnings
  app.get(['/favicon.ico', '/apple-touch-icon.png', '/apple-touch-icon-precomposed.png'], (req, res) => {
    res.status(204).end();
  });

  app.get('/.well-known/appspecific/com.chrome.devtools.json', (req, res) => {
    res.status(204).end();
  });

  // Global error handler
  app.use(errorHandler);

  return app;
}
