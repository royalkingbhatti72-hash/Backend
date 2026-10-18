import { createApp } from '../src/app';

let appInstance: any;

export default function handler(req: any, res: any) {
  try {
    if (!appInstance) {
      appInstance = createApp();
    }
    return appInstance(req, res);
  } catch (err: any) {
    console.error('Fatal backend serverless error:', err);
    return res.status(500).json({
      error: 'Backend Serverless Error',
      message: err?.message || String(err),
    });
  }
}
