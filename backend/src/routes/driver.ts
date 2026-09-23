import { Router, Request, Response } from 'express';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { pool } from '../db';

export const driverRouter = Router();
const JWT_SECRET = process.env.JWT_SECRET || 'carpital_consult_super_secret_jwt_key_2026';

function extractDriverId(req: Request): string | null {
  const authHeader = req.headers.authorization;
  if (authHeader && authHeader.startsWith('Bearer ')) {
    try {
      const decoded = jwt.verify(authHeader.split(' ')[1], JWT_SECRET) as { id: string };
      return decoded.id;
    } catch (_) {}
  }
  return (req.body.driverId || req.query.driverId) as string | null;
}

// -------------------------------------------------------------
// POST /api/driver/login - Driver Login
// -------------------------------------------------------------
driverRouter.post('/login', async (req: Request, res: Response): Promise<void> => {
  const { email, password } = req.body;

  if (!email || !password) {
    res.status(400).json({ error: 'Email and password are required' });
    return;
  }

  const cleanEmail = email.trim().toLowerCase();

  try {
    const result = await pool.query(
      `SELECT * FROM public.users WHERE email = $1 AND role = 'driver'`,
      [cleanEmail]
    );

    if (result.rows.length === 0) {
      res.status(401).json({ error: 'Invalid driver credentials' });
      return;
    }

    const driver = result.rows[0];
    const isMatch = await bcrypt.compare(password, driver.password_hash);
    if (!isMatch) {
      res.status(401).json({ error: 'Invalid driver credentials' });
      return;
    }

    const token = jwt.sign(
      { id: driver.id, email: driver.email, role: 'driver' },
      JWT_SECRET,
      { expiresIn: '30d' }
    );

    res.json({
      success: true,
      token,
      driver: {
        id: driver.id,
        firstName: driver.first_name,
        lastName: driver.last_name,
        email: driver.email,
        phone: driver.phone,
        licenseNumber: driver.license_number,
        vehicleType: driver.vehicle_type,
        vehiclePlate: driver.vehicle_plate,
        isOnline: driver.is_online,
        isVerified: driver.is_verified,
        rating: parseFloat(driver.rating || '5.0'),
        totalJobs: driver.total_trips || 0,
      },
    });
  } catch (err: any) {
    console.error('Driver login error:', err);
    res.status(500).json({ error: 'Server error during driver login' });
  }
});

// -------------------------------------------------------------
// POST /api/driver/register - Driver Registration
// -------------------------------------------------------------
driverRouter.post('/register', async (req: Request, res: Response): Promise<void> => {
  const { firstName, lastName, email, phone, password, licenseNumber, vehicleType, vehiclePlate } = req.body;

  if (!email || !password || !firstName) {
    res.status(400).json({ error: 'Name, email, and password are required' });
    return;
  }

  const cleanEmail = email.trim().toLowerCase();

  try {
    const existing = await pool.query('SELECT id FROM public.users WHERE email = $1', [cleanEmail]);
    if (existing.rows.length > 0) {
      res.status(409).json({ error: 'An account with this email already exists' });
      return;
    }

    const salt = await bcrypt.genSalt(10);
    const passwordHash = await bcrypt.hash(password, salt);

    const result = await pool.query(
      `INSERT INTO public.users (
        first_name, last_name, email, phone, password_hash, role, is_verified,
        license_number, vehicle_type, vehicle_plate, is_online
      ) VALUES ($1, $2, $3, $4, $5, 'driver', TRUE, $6, $7, $8, TRUE)
      RETURNING *`,
      [firstName, lastName || '', cleanEmail, phone || '', passwordHash, licenseNumber || '', vehicleType || 'Tow Truck', vehiclePlate || '']
    );

    const driver = result.rows[0];
    const token = jwt.sign(
      { id: driver.id, email: driver.email, role: 'driver' },
      JWT_SECRET,
      { expiresIn: '30d' }
    );

    res.status(201).json({
      success: true,
      token,
      driver: {
        id: driver.id,
        firstName: driver.first_name,
        lastName: driver.last_name,
        email: driver.email,
        phone: driver.phone,
        licenseNumber: driver.license_number,
        vehicleType: driver.vehicle_type,
        vehiclePlate: driver.vehicle_plate,
        isOnline: driver.is_online,
        isVerified: true,
        rating: 5.0,
        totalJobs: 0,
      },
    });
  } catch (err: any) {
    console.error('Driver register error:', err);
    res.status(500).json({ error: 'Server error during driver registration' });
  }
});

// -------------------------------------------------------------
// GET /api/driver/jobs - Get Driver's Jobs
// -------------------------------------------------------------
driverRouter.get('/jobs', async (req: Request, res: Response): Promise<void> => {
  const driverId = extractDriverId(req);

  try {
    let query = `
      SELECT b.*, 
             u.first_name as client_first_name, 
             u.last_name as client_last_name, 
             u.phone as client_phone,
             u.email as client_email
      FROM public.bookings b
      LEFT JOIN public.users u ON b.user_id = u.id
    `;
    const params: any[] = [];

    if (driverId) {
      query += ` WHERE b.driver_id = $1`;
      params.push(driverId);
    } else {
      // If no driver specified, show active bookings
      query += ` WHERE b.status IN ('pending', 'assigned', 'confirmed', 'pickedUp', 'picked_up', 'inTransit', 'in_transit')`;
    }

    query += ` ORDER BY b.created_at DESC`;

    const result = await pool.query(query, params);
    
    // Add client profiles structure for Flutter compatibility
    const jobs = result.rows.map(row => {
      const clientFullName = [row.client_first_name, row.client_last_name].filter(Boolean).join(' ') || 'Client';
      return {
        ...row,
        client_name: clientFullName,
        profiles: {
          full_name: clientFullName,
          phone: row.client_phone || '',
          email: row.client_email || '',
        },
      };
    });

    res.json(jobs);
  } catch (err: any) {
    console.error('Error fetching driver jobs:', err);
    res.status(500).json({ error: 'Failed to fetch jobs' });
  }
});

// -------------------------------------------------------------
// POST /api/driver/jobs/:id/accept - Driver Confirms/Accepts Job
// -------------------------------------------------------------
driverRouter.post('/jobs/:id/accept', async (req: Request, res: Response): Promise<void> => {
  const { id } = req.params;
  const driverId = extractDriverId(req);

  try {
    const result = await pool.query(
      `UPDATE public.bookings 
       SET status = 'confirmed', confirmed_at = NOW(), updated_at = NOW() 
       WHERE id = $1 AND (driver_id = $2 OR driver_id IS NULL)
       RETURNING *`,
      [id, driverId]
    );

    if (result.rows.length === 0) {
      res.status(404).json({ error: 'Job not found or not assigned to you' });
      return;
    }

    res.json({ success: true, job: result.rows[0] });
  } catch (err: any) {
    console.error('Error accepting job:', err);
    res.status(500).json({ error: 'Failed to accept job' });
  }
});

// -------------------------------------------------------------
// POST /api/driver/jobs/:id/status - Advance Job Status & Delivery Proof
// -------------------------------------------------------------
driverRouter.post('/jobs/:id/status', async (req: Request, res: Response): Promise<void> => {
  const { id } = req.params;
  const body = req.body;
  const status = body.status;

  if (!status) {
    res.status(400).json({ error: 'Status is required' });
    return;
  }

  // Normalize status
  let dbStatus = status;
  if (status === 'picked_up' || status === 'pickedUp') dbStatus = 'pickedUp';
  else if (status === 'in_transit' || status === 'inTransit') dbStatus = 'inTransit';
  else if (status === 'delivered' || status === 'completed') dbStatus = 'completed';
  else if (status === 'confirmed') dbStatus = 'confirmed';
  else if (status === 'assigned') dbStatus = 'assigned';
  else if (status === 'cancelled') dbStatus = 'cancelled';

  const pickupConditionDesc = body.pickupConditionDesc || body.pickup_condition_desc;
  const pickupConditionImages = body.pickupConditionImages || body.pickup_condition_images;
  const pickupConditionAudio = body.pickupConditionAudio || body.pickup_condition_audio;
  const clientSignatureUrl = body.clientSignatureBase64 || body.client_signature_url;

  try {
    const updates: string[] = ['status = $1', 'updated_at = NOW()'];
    const values: any[] = [dbStatus];
    let pIdx = 2;

    if (dbStatus === 'confirmed') {
      updates.push(`confirmed_at = NOW()`);
    } else if (dbStatus === 'pickedUp') {
      updates.push(`picked_up_at = NOW()`);
    } else if (dbStatus === 'completed') {
      updates.push(`completed_at = NOW()`);
      updates.push(`client_acknowledged_at = NOW()`);
    }

    if (pickupConditionDesc) {
      updates.push(`pickup_condition_desc = $${pIdx++}`);
      values.push(pickupConditionDesc);
    }
    if (pickupConditionImages) {
      updates.push(`pickup_condition_images = $${pIdx++}`);
      values.push(JSON.stringify(pickupConditionImages));
    }
    if (pickupConditionAudio) {
      updates.push(`pickup_condition_audio = $${pIdx++}`);
      values.push(pickupConditionAudio);
    }
    if (clientSignatureUrl) {
      updates.push(`client_signature_url = $${pIdx++}`);
      values.push(clientSignatureUrl);
    }

    values.push(id);
    const sql = `UPDATE public.bookings SET ${updates.join(', ')} WHERE id = $${pIdx} RETURNING *`;

    const result = await pool.query(sql, values);

    if (result.rows.length === 0) {
      res.status(404).json({ error: 'Job not found' });
      return;
    }

    // If delivered, increment driver's total_trips
    if (dbStatus === 'completed' && result.rows[0].driver_id) {
      await pool.query(
        `UPDATE public.users SET total_trips = COALESCE(total_trips, 0) + 1 WHERE id = $1`,
        [result.rows[0].driver_id]
      );
    }

    res.json({ success: true, job: result.rows[0] });
  } catch (err: any) {
    console.error('Error updating job status:', err);
    res.status(500).json({ error: 'Failed to update job status: ' + err.message });
  }
});

// -------------------------------------------------------------
// POST /api/driver/location - Update Driver GPS Location
// -------------------------------------------------------------
driverRouter.post('/location', async (req: Request, res: Response): Promise<void> => {
  const driverId = extractDriverId(req);
  const { lat, lng, jobId } = req.body;

  if (lat == null || lng == null) {
    res.status(400).json({ error: 'Latitude and longitude are required' });
    return;
  }

  try {
    if (driverId) {
      await pool.query(
        `UPDATE public.users SET current_lat = $1, current_lng = $2, updated_at = NOW() WHERE id = $3`,
        [lat, lng, driverId]
      );
    }

    if (jobId) {
      await pool.query(
        `UPDATE public.bookings SET driver_lat = $1, driver_lng = $2, updated_at = NOW() WHERE id = $3`,
        [lat, lng, jobId]
      );
    }

    res.json({ success: true });
  } catch (err: any) {
    console.error('Error updating location:', err);
    res.status(500).json({ error: 'Failed to update location' });
  }
});

// -------------------------------------------------------------
// POST /api/driver/status - Toggle Online / Offline
// -------------------------------------------------------------
driverRouter.post('/status', async (req: Request, res: Response): Promise<void> => {
  const driverId = extractDriverId(req);
  const { isOnline } = req.body;

  if (!driverId) {
    res.status(401).json({ error: 'Unauthorized driver' });
    return;
  }

  try {
    const result = await pool.query(
      `UPDATE public.users SET is_online = $1, updated_at = NOW() WHERE id = $2 RETURNING is_online`,
      [!!isOnline, driverId]
    );

    res.json({ success: true, isOnline: result.rows[0]?.is_online });
  } catch (err: any) {
    console.error('Error updating driver status:', err);
    res.status(500).json({ error: 'Failed to update driver status' });
  }
});
