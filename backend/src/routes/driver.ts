import { Router, Request, Response } from 'express';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { pool } from '../db';
import { notifyBookingStatus } from '../services/bookingNotifications';
import { sendOtpEmail } from '../services/email';
import { uploadBufferOrBase64 } from './upload';
import { broadcastDriverLocation } from '../realtime';

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

function generate6DigitOtp(): string {
  return Math.floor(100000 + Math.random() * 900000).toString();
}

function formatDriverResponse(driver: any) {
  return {
    id: driver.id,
    firstName: driver.first_name,
    lastName: driver.last_name,
    fullName: `${driver.first_name || ''} ${driver.last_name || ''}`.trim(),
    email: driver.email,
    phone: driver.phone || '',
    avatarUrl: driver.avatar_url || null,
    dateOfBirth: driver.date_of_birth || null,
    residentialAddress: driver.residential_address || null,
    stateLga: driver.state_lga || null,
    emergencyContactName: driver.emergency_contact_name || null,
    emergencyContactPhone: driver.emergency_contact_phone || null,
    emergencyContactRelationship: driver.emergency_contact_relationship || null,
    ninNumber: driver.nin_number || null,
    driverLicenseImage: driver.driver_license_image || null,
    licenseNumber: driver.license_number || null,
    vehicleType: driver.vehicle_type || 'Tow Truck',
    vehiclePlate: driver.vehicle_plate || null,
    isOnline: driver.is_online || false,
    isVerified: driver.is_verified || false,
    isProfileCompleted: driver.is_profile_completed || false,
    rating: parseFloat(driver.rating || '5.0'),
    totalJobs: driver.total_trips || 0,
  };
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

    if (!driver.is_verified) {
      const otp = generate6DigitOtp();
      const expiresAt = new Date(Date.now() + 10 * 60 * 1000);
      await pool.query('DELETE FROM public.email_verifications WHERE email = $1', [cleanEmail]);
      await pool.query(
        'INSERT INTO public.email_verifications (email, otp_code, expires_at) VALUES ($1, $2, $3)',
        [cleanEmail, otp, expiresAt]
      );
      await sendOtpEmail(cleanEmail, otp);

      res.status(403).json({
        error: 'Account not verified. A verification code has been sent to your email.',
        requiresOtp: true,
        email: cleanEmail,
      });
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
      driver: formatDriverResponse(driver),
    });
  } catch (err: any) {
    console.error('Driver login error:', err);
    res.status(500).json({ error: 'Server error during driver login' });
  }
});

// -------------------------------------------------------------
// POST /api/driver/register - Driver Registration (Sends OTP)
// -------------------------------------------------------------
driverRouter.post('/register', async (req: Request, res: Response): Promise<void> => {
  const { firstName, lastName, email, phone, password, licenseNumber, vehicleType, vehiclePlate } = req.body;

  if (!email || !password || !firstName) {
    res.status(400).json({ error: 'Name, email, and password are required' });
    return;
  }

  const cleanEmail = email.trim().toLowerCase();

  try {
    const existing = await pool.query('SELECT id, is_verified FROM public.users WHERE email = $1', [cleanEmail]);
    if (existing.rows.length > 0 && existing.rows[0].is_verified) {
      res.status(409).json({ error: 'An account with this email already exists' });
      return;
    }

    const salt = await bcrypt.genSalt(10);
    const passwordHash = await bcrypt.hash(password, salt);

    let driverId: string;
    if (existing.rows.length > 0) {
      const updated = await pool.query(
        `UPDATE public.users SET
          first_name = $1, last_name = $2, phone = $3, password_hash = $4,
          role = 'driver', license_number = $5, vehicle_type = $6, vehicle_plate = $7,
          updated_at = NOW()
        WHERE email = $8 RETURNING id`,
        [firstName, lastName || '', phone || '', passwordHash, licenseNumber || '', vehicleType || 'Tow Truck', vehiclePlate || '', cleanEmail]
      );
      driverId = updated.rows[0].id;
    } else {
      const result = await pool.query(
        `INSERT INTO public.users (
          first_name, last_name, email, phone, password_hash, role, is_verified,
          license_number, vehicle_type, vehicle_plate, is_online
        ) VALUES ($1, $2, $3, $4, $5, 'driver', FALSE, $6, $7, $8, TRUE)
        RETURNING id`,
        [firstName, lastName || '', cleanEmail, phone || '', passwordHash, licenseNumber || '', vehicleType || 'Tow Truck', vehiclePlate || '']
      );
      driverId = result.rows[0].id;
    }

    // Generate 6-digit OTP
    const otp = generate6DigitOtp();
    const expiresAt = new Date(Date.now() + 10 * 60 * 1000); // 10 minutes

    // Invalidate old OTPs for this email
    await pool.query('DELETE FROM public.email_verifications WHERE email = $1', [cleanEmail]);

    // Store new OTP
    await pool.query(
      'INSERT INTO public.email_verifications (email, otp_code, expires_at) VALUES ($1, $2, $3)',
      [cleanEmail, otp, expiresAt]
    );

    // Send via Resend
    await sendOtpEmail(cleanEmail, otp);

    res.status(201).json({
      success: true,
      requiresOtp: true,
      message: 'Verification code sent to your email',
      email: cleanEmail,
      driverId,
    });
  } catch (err: any) {
    console.error('Driver register error:', err);
    res.status(500).json({ error: 'Server error during driver registration' });
  }
});

// -------------------------------------------------------------
// POST /api/driver/verify-otp - Verify Driver OTP
// -------------------------------------------------------------
driverRouter.post('/verify-otp', async (req: Request, res: Response): Promise<void> => {
  const { email, otp } = req.body;
  if (!email || !otp) {
    res.status(400).json({ error: 'Email and OTP code are required' });
    return;
  }

  const cleanEmail = email.trim().toLowerCase();
  const cleanOtp = otp.toString().trim();

  try {
    const result = await pool.query(
      `SELECT id, expires_at, verified 
       FROM public.email_verifications 
       WHERE email = $1 AND otp_code = $2 
       ORDER BY created_at DESC LIMIT 1`,
      [cleanEmail, cleanOtp]
    );

    if (result.rows.length === 0) {
      res.status(400).json({ error: 'Invalid verification code' });
      return;
    }

    const verification = result.rows[0];
    if (new Date(verification.expires_at) < new Date()) {
      res.status(400).json({ error: 'Verification code has expired. Please request a new one.' });
      return;
    }

    // Mark verified
    await pool.query('UPDATE public.email_verifications SET verified = TRUE WHERE id = $1', [verification.id]);

    const userUpdate = await pool.query(
      `UPDATE public.users 
       SET is_verified = TRUE, updated_at = NOW() 
       WHERE email = $1 
       RETURNING *`,
      [cleanEmail]
    );

    if (userUpdate.rows.length === 0) {
      res.status(404).json({ error: 'Driver not found' });
      return;
    }

    const driver = userUpdate.rows[0];
    const token = jwt.sign(
      { id: driver.id, email: driver.email, role: 'driver' },
      JWT_SECRET,
      { expiresIn: '30d' }
    );

    res.json({
      success: true,
      token,
      driver: formatDriverResponse(driver),
    });
  } catch (err: any) {
    console.error('Driver OTP verify error:', err);
    res.status(500).json({ error: 'Server error verifying OTP' });
  }
});

// -------------------------------------------------------------
// POST /api/driver/resend-otp - Resend Driver OTP
// -------------------------------------------------------------
driverRouter.post('/resend-otp', async (req: Request, res: Response): Promise<void> => {
  const { email } = req.body;
  if (!email) {
    res.status(400).json({ error: 'Email is required' });
    return;
  }

  const cleanEmail = email.trim().toLowerCase();

  try {
    const user = await pool.query('SELECT id, is_verified FROM public.users WHERE email = $1', [cleanEmail]);
    if (user.rows.length === 0) {
      res.status(404).json({ error: 'No driver account found with this email' });
      return;
    }

    if (user.rows[0].is_verified) {
      res.status(400).json({ error: 'This driver account is already verified. Please sign in.' });
      return;
    }

    const otp = generate6DigitOtp();
    const expiresAt = new Date(Date.now() + 10 * 60 * 1000);

    await pool.query('DELETE FROM public.email_verifications WHERE email = $1', [cleanEmail]);
    await pool.query(
      'INSERT INTO public.email_verifications (email, otp_code, expires_at) VALUES ($1, $2, $3)',
      [cleanEmail, otp, expiresAt]
    );

    await sendOtpEmail(cleanEmail, otp);

    res.json({
      success: true,
      message: 'New verification code sent to your email',
    });
  } catch (err: any) {
    console.error('Driver resend OTP error:', err);
    res.status(500).json({ error: 'Failed to resend code' });
  }
});

// -------------------------------------------------------------
// GET /api/driver/profile - Fetch Current Driver Profile
// -------------------------------------------------------------
driverRouter.get('/profile', async (req: Request, res: Response): Promise<void> => {
  const driverId = extractDriverId(req) || (req.query.driverId as string);

  if (!driverId) {
    res.status(401).json({ error: 'Unauthorized. Driver ID required.' });
    return;
  }

  try {
    const result = await pool.query('SELECT * FROM public.users WHERE id = $1', [driverId]);
    if (result.rows.length === 0) {
      res.status(404).json({ error: 'Driver not found' });
      return;
    }

    res.json({
      success: true,
      driver: formatDriverResponse(result.rows[0]),
    });
  } catch (err: any) {
    console.error('Fetch driver profile error:', err);
    res.status(500).json({ error: 'Failed to fetch driver profile' });
  }
});

// -------------------------------------------------------------
// POST /api/driver/complete-profile - Complete KYC Profile
// -------------------------------------------------------------
driverRouter.post('/complete-profile', async (req: Request, res: Response): Promise<void> => {
  const driverId = extractDriverId(req) || req.body.driverId;
  const {
    fullName,
    firstName,
    lastName,
    avatarUrl,
    dateOfBirth,
    phone,
    email,
    residentialAddress,
    stateLga,
    emergencyContactName,
    emergencyContactPhone,
    emergencyContactRelationship,
    ninNumber,
    driverLicenseImage,
    licenseNumber,
  } = req.body;

  if (!driverId && !email) {
    res.status(400).json({ error: 'Driver identification required' });
    return;
  }

  // Parse name if full name provided
  let fName = firstName;
  let lName = lastName;
  if (fullName && (!fName || !lName)) {
    const parts = fullName.trim().split(' ');
    fName = parts[0] || '';
    lName = parts.slice(1).join(' ') || '';
  }

  try {
    let finalAvatarUrl = avatarUrl;
    if (avatarUrl && typeof avatarUrl === 'string' && avatarUrl.startsWith('data:image')) {
      try {
        finalAvatarUrl = await uploadBufferOrBase64(
          avatarUrl,
          'avatars',
          `driver_${driverId || 'avatar'}`
        );
      } catch (uploadErr) {
        console.error('Failed to upload avatar to bucket:', uploadErr);
      }
    }

    let finalLicenseImage = driverLicenseImage;
    if (driverLicenseImage && typeof driverLicenseImage === 'string' && driverLicenseImage.startsWith('data:image')) {
      try {
        finalLicenseImage = await uploadBufferOrBase64(
          driverLicenseImage,
          'licenses',
          `license_${driverId || 'doc'}`
        );
      } catch (uploadErr) {
        console.error('Failed to upload license image to bucket:', uploadErr);
      }
    }

    const updates: string[] = ['is_profile_completed = TRUE', 'updated_at = NOW()'];
    const values: any[] = [];
    let pIdx = 1;

    if (fName) { updates.push(`first_name = $${pIdx++}`); values.push(fName); }
    if (lName !== undefined) { updates.push(`last_name = $${pIdx++}`); values.push(lName); }
    if (phone) { updates.push(`phone = $${pIdx++}`); values.push(phone); }
    if (finalAvatarUrl) { updates.push(`avatar_url = $${pIdx++}`); values.push(finalAvatarUrl); }
    if (dateOfBirth) { updates.push(`date_of_birth = $${pIdx++}`); values.push(dateOfBirth); }
    if (residentialAddress) { updates.push(`residential_address = $${pIdx++}`); values.push(residentialAddress); }
    if (stateLga) { updates.push(`state_lga = $${pIdx++}`); values.push(stateLga); }
    if (emergencyContactName) { updates.push(`emergency_contact_name = $${pIdx++}`); values.push(emergencyContactName); }
    if (emergencyContactPhone) { updates.push(`emergency_contact_phone = $${pIdx++}`); values.push(emergencyContactPhone); }
    if (emergencyContactRelationship) { updates.push(`emergency_contact_relationship = $${pIdx++}`); values.push(emergencyContactRelationship); }
    if (ninNumber) { updates.push(`nin_number = $${pIdx++}`); values.push(ninNumber); }
    if (finalLicenseImage) { updates.push(`driver_license_image = $${pIdx++}`); values.push(finalLicenseImage); }
    if (licenseNumber) { updates.push(`license_number = $${pIdx++}`); values.push(licenseNumber); }

    let query: string;
    if (driverId) {
      values.push(driverId);
      query = `UPDATE public.users SET ${updates.join(', ')} WHERE id = $${pIdx} RETURNING *`;
    } else {
      values.push(email.trim().toLowerCase());
      query = `UPDATE public.users SET ${updates.join(', ')} WHERE email = $${pIdx} RETURNING *`;
    }

    const result = await pool.query(query, values);
    if (result.rows.length === 0) {
      res.status(404).json({ error: 'Driver account not found' });
      return;
    }

    const driver = result.rows[0];
    res.json({
      success: true,
      message: 'Profile completed successfully',
      driver: formatDriverResponse(driver),
    });
  } catch (err: any) {
    console.error('Complete profile error:', err);
    res.status(500).json({ error: 'Failed to complete profile: ' + err.message });
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

    void notifyBookingStatus(result.rows[0].id, result.rows[0].status);

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
        `UPDATE public.bookings SET driver_lat = $1, driver_lng = $2, driver_location_at = NOW(), updated_at = NOW() WHERE id = $3`,
        [lat, lng, jobId]
      );
      broadcastDriverLocation(jobId, Number(lat), Number(lng));
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
