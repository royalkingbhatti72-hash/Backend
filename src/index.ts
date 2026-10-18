import { createApp } from './app';
import { config } from './config';

const app = createApp();

app.listen(config.port, () => {
  console.log(`👑 Royal Rewards API Server running on http://localhost:${config.port}`);
  console.log(`⚙️  Environment: ${config.nodeEnv}`);
  console.log(`🌐 CORS Origin: ${config.corsOrigin}`);
});
