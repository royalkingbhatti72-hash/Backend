import { createApp } from '../src/app';

let appInstance: any = null;

function getApp() {
  if (!appInstance) {
    appInstance = createApp();
  }
  return appInstance;
}

export default async function handler(req: any, res: any) {
  try {
    const app = getApp();
    return app(req, res);
  } catch (error: any) {
    console.error('[Vercel Serverless Crash]:', error);
    if (!res.headersSent) {
      return res.status(500).json({
        error: 'Serverless Function Execution Error',
        message: error?.message || 'An unexpected crash occurred during function initialization',
        stack: process.env.NODE_ENV === 'development' ? error?.stack : undefined,
      });
    }
  }
}
