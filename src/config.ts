import dotenv from 'dotenv';
dotenv.config();

export const config = {
  port: parseInt(process.env.PORT || '5000', 10),
  jwtSecret: process.env.JWT_SECRET || 'royal-rewards-super-secret-jwt-key-2026',
  adminSecret: process.env.ADMIN_SECRET || 'royal-rewards-admin-secret-key-2026',
  nodeEnv: process.env.NODE_ENV || 'development',
  corsOrigin: process.env.CORS_ORIGIN || '*',
};
