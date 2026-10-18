# Earn Sheet / Royal Rewards — Backend API Server

This is the independent Express & Prisma backend API server for Earn Sheet / Royal Rewards, designed for both local development and zero-maintenance Vercel serverless deployment with Supabase PostgreSQL.

---

## 🚀 Running Locally

```bash
cd backend
npm install
npm run dev
```

* API server runs at: `http://localhost:5050`
* Health check: `http://localhost:5050/api/health`
* Root endpoint: `http://localhost:5050/api`

---

## 🗄️ Supabase PostgreSQL Setup

1. Open your [Supabase SQL Editor](https://supabase.com/dashboard).
2. Copy the full contents of [`prisma/supabase_full_setup.sql`](./prisma/supabase_full_setup.sql).
3. Paste into the SQL Editor and click **Run**.
4. This seeds all **10 Levels**, all **100 Tasks**, **8 Spin Wheel Prizes**, **20 Platform Settings**, and the **Super Admin account**:
   * **Admin Username**: `admin`
   * **Admin Password**: `Admin@Royal2026!`

---

## ☁️ Vercel Deployment Settings

1. Connect the repository `https://github.com/royalkingbhatti72-hash/Backend` to Vercel.
2. In **Project Settings** $\rightarrow$ **Deployment Protection**:
   * Set **Vercel Authentication** to **Disabled**.
3. In **Project Settings** $\rightarrow$ **Environment Variables**, add:
   * `DATABASE_URL`: `postgresql://postgres:[YOUR-PASSWORD]@db.ilrngvidbuenxfgsbpim.supabase.co:6543/postgres?pgbouncer=true&connection_limit=1`
   * `DIRECT_URL`: `postgresql://postgres:[YOUR-PASSWORD]@db.ilrngvidbuenxfgsbpim.supabase.co:5432/postgres`
   * `JWT_SECRET`: `royal-rewards-super-secret-jwt-key-2026`
   * `ADMIN_SECRET`: `royal-rewards-admin-secret-key-2026`
   * `SUPABASE_URL`: `https://ilrngvidbuenxfgsbpim.supabase.co`
   * `SUPABASE_ANON_KEY`: `sb_publishable_4EqCtWIiEIwm3ETQvxeOgA_fUcSKkiJ`
