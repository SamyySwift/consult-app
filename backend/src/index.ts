import express from 'express';
import http from 'http';
import cors from 'cors';
import dotenv from 'dotenv';
import { initDatabase, pool } from './db';
import { attachRealtime } from './realtime';
import { authRouter } from './routes/auth';
import { bookingsRouter } from './routes/bookings';
import { driverRouter } from './routes/driver';
import { adminRouter } from './routes/admin';
import { uploadRouter } from './routes/upload';
import { filesRouter } from './routes/files';
import { mapsRouter } from './routes/maps';

dotenv.config();

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json({ limit: '20mb' }));
app.use(express.urlencoded({ extended: true, limit: '20mb' }));

// Health Check
app.get('/health', async (_req, res) => {
  let dbStatus = 'disconnected';
  try {
    const dbRes = await pool.query('SELECT 1');
    if (dbRes.rows.length > 0) dbStatus = 'connected';
  } catch (err: any) {
    dbStatus = `error: ${err.message}`;
  }

  res.json({
    status: 'ok',
    service: 'Carpital Consult Logistics API',
    timestamp: new Date().toISOString(),
    database: dbStatus,
  });
});

// Mount API Routes
app.use('/api/auth', authRouter);
app.use('/api/bookings', bookingsRouter);
app.use('/api/driver', driverRouter);
app.use('/api/admin', adminRouter);
app.use('/api/upload', uploadRouter);
app.use('/api/files', filesRouter);
app.use('/api/maps', mapsRouter);

async function startServer() {
  try {
    if (process.env.DATABASE_URL) {
      await initDatabase();
    } else {
      console.warn('⚠️ No DATABASE_URL set. Running in deferred DB mode.');
    }

    const server = http.createServer(app);
    attachRealtime(server);

    server.listen(PORT, () => {
      console.log(`🚀 Carpital Consult API server running on port ${PORT}`);
    });
  } catch (err) {
    console.error('❌ Failed to start server:', err);
    process.exit(1);
  }
}

startServer();
