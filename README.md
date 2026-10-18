# Royal Rewards — Backend API Server

This is the independent backend API server for Royal Rewards.

## 🚀 Running Locally

```bash
cd backend
npm run dev
```
The API server will run at: `http://localhost:5050`
Health check: `http://localhost:5050/api/health`

## ⚙️ Environment Configuration (`.env`)

```env
PORT=5050
DATABASE_URL="file:./dev.db"
JWT_SECRET="your-secure-jwt-secret"
ADMIN_SECRET="your-secure-admin-secret"
NODE_ENV="development"
CORS_ORIGIN="http://localhost:5173"
```

## 🌐 Setting Up a Separate Domain in Production

1. Deploy this folder (`/backend`) to your server or platform (e.g. Render, Railway, DigitalOcean, VPS).
2. Point your API domain (e.g. `api.yourdomain.com`) to this server.
3. In your production `.env`, set:
   ```env
   CORS_ORIGIN="https://app.yourdomain.com"
   ```
   (Replace `https://app.yourdomain.com` with your frontend's actual domain).
