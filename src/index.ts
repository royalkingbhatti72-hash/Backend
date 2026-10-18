import { createApp } from './app';
import { config } from './config';

const app = createApp();

if (process.env.NODE_ENV !== 'production' && !process.env.VERCEL) {
  app.listen(config.port, '0.0.0.0', () => {
    console.log(`👑 Earn Sheet API Server running on http://0.0.0.0:${config.port}`);
    console.log(`⚙️  Environment: ${config.nodeEnv}`);
    console.log(`🌐 CORS Origin: ${config.corsOrigin}`);
  });
}

export default app;
