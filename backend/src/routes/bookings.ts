import { Router, Request, Response } from 'express';
import jwt from 'jsonwebtoken';
import { pool } from '../db';
import { getInsurancePercentage } from '../settings';

export const bookingsRouter = Router();
const JWT_SECRET = process.env.JWT_SECRET || 'carpital_consult_super_secret_jwt_key_2026';

function extractUserId(req: Request): string | null {
  const authHeader = req.headers.authorization;
  if (authHeader && authHeader.startsWith('Bearer ')) {
    try {
      const decoded = jwt.verify(authHeader.split(' ')[1], JWT_SECRET) as { id: string };
      return decoded.id;
    } catch (_) {}
  }
  return (req.body.userId || req.query.userId) as string | null;
}

// -------------------------------------------------------------
// GET /api/bookings/settings - Public pricing settings for clients
// -------------------------------------------------------------
bookingsRouter.get('/settings', async (_req: Request, res: Response): Promise<void> => {
  try {
    res.json({ insurance_percentage: await getInsurancePercentage() });
  } catch (err: any) {
    console.error('Error fetching booking settings:', err);
    res.status(500).json({ error: 'Failed to fetch settings: ' + err.message });
  }
});

// -------------------------------------------------------------
// POST /api/bookings - Create new booking
// -------------------------------------------------------------
bookingsRouter.post('/', async (req: Request, res: Response): Promise<void> => {
  const userId = extractUserId(req) || req.body.user_id || req.body.userId;
  const b = req.body;

  const pickupAddress = b.pickup_address || b.pickupAddress;
  const dropoffAddress = b.dropoff_address || b.dropoffAddress;
  const pickupLat = b.pickup_lat ?? b.pickupLat;
  const pickupLng = b.pickup_lng ?? b.pickupLng;
  const dropoffLat = b.dropoff_lat ?? b.dropoffLat;
  const dropoffLng = b.dropoff_lng ?? b.dropoffLng;
  const serviceType = b.service_type || b.serviceType || 'standard';
  const transportTier = b.transport_tier || b.transportTier || 'standard';
  const transportMode = b.transport_mode || b.transportMode || 'standard';
  let totalAmount = b.total_amount ?? b.totalAmount;
  const basePrice = b.base_price ?? b.basePrice ?? totalAmount;
  let insuranceFee = b.insurance_fee ?? b.insuranceFee ?? b.insuranceAmount ?? 0;
  const hasInsurance = !!(b.has_insurance ?? b.hasInsurance);
  const pickupDateTime = b.pickup_datetime || b.pickupDateTime;
  const documentPaths = b.document_paths || b.documentPaths || [];

  // Vehicle information (support both separate fields and vehicleDetails object)
  const vehicleDetails = b.vehicle_details || b.vehicleDetails || {};
  const vehicleType = b.vehicle_type || b.vehicleType || vehicleDetails.type || 'sedan';
  const vehicleMake = b.vehicle_make || b.vehicleMake || vehicleDetails.make || 'Vehicle';
  const vehicleModel = b.vehicle_model || b.vehicleModel || vehicleDetails.model || '';
  const vehicleYear = b.vehicle_year || b.vehicleYear || vehicleDetails.year || '2023';
  const vehicleColor = b.vehicle_color || b.vehicleColor || vehicleDetails.color || 'Silver';
  const vehicleVin = b.vehicle_vin || b.vehicleVin || vehicleDetails.vin || '';
  const vehicleValue = b.vehicle_value ?? b.vehicleValue ?? vehicleDetails.value ?? 0;

  if (!pickupAddress || !dropoffAddress || !totalAmount) {
    res.status(400).json({ error: 'Pickup, dropoff, and total amount are required' });
    return;
  }

  // Recompute insurance with the admin-configured percentage of vehicle worth
  if (hasInsurance && Number(vehicleValue) > 0) {
    try {
      const pct = await getInsurancePercentage();
      const serverFee = Math.round(Number(vehicleValue) * (pct / 100));
      totalAmount = Number(totalAmount) - Number(insuranceFee) + serverFee;
      insuranceFee = serverFee;
    } catch (err) {
      console.error('Error loading insurance percentage, using client fee:', err);
    }
  }

  // Generate unique booking reference: e.g. AM-847291
  const refNum = Math.floor(100000 + Math.random() * 900000);
  const bookingReference = `AM-${refNum}`;

  try {
    const result = await pool.query(
      `INSERT INTO public.bookings (
        user_id,
        booking_reference,
        pickup_address,
        dropoff_address,
        pickup_lat,
        pickup_lng,
        dropoff_lat,
        dropoff_lng,
        service_type,
        transport_tier,
        transport_mode,
        total_amount,
        base_price,
        insurance_fee,
        status,
        vehicle_type,
        vehicle_make,
        vehicle_model,
        vehicle_year,
        vehicle_color,
        vehicle_vin,
        vehicle_details,
        document_paths,
        has_insurance,
        insurance_amount,
        pickup_datetime,
        vehicle_value
      ) VALUES (
        $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, 'pending',
        $15, $16, $17, $18, $19, $20, $21, $22, $23, $24, $25, $26
      )
      RETURNING *`,
      [
        userId || null,
        bookingReference,
        pickupAddress,
        dropoffAddress,
        pickupLat || null,
        pickupLng || null,
        dropoffLat || null,
        dropoffLng || null,
        serviceType,
        transportTier,
        transportMode,
        totalAmount,
        basePrice,
        insuranceFee,
        vehicleType,
        vehicleMake,
        vehicleModel,
        vehicleYear,
        vehicleColor,
        vehicleVin,
        JSON.stringify(vehicleDetails),
        JSON.stringify(documentPaths),
        hasInsurance,
        insuranceFee,
        pickupDateTime || null,
        vehicleValue,
      ]
    );

    res.status(201).json({
      success: true,
      booking: result.rows[0],
    });
  } catch (err: any) {
    console.error('Error creating booking:', err);
    res.status(500).json({ error: 'Failed to create booking: ' + err.message });
  }
});

// -------------------------------------------------------------
// GET /api/bookings - List user bookings
// -------------------------------------------------------------
bookingsRouter.get('/', async (req: Request, res: Response): Promise<void> => {
  const userId = extractUserId(req);

  try {
    let query = `
      SELECT b.*, 
             d.first_name as driver_first_name, 
             d.last_name as driver_last_name, 
             d.phone as driver_phone,
             d.vehicle_type as driver_vehicle_type,
             d.vehicle_plate as driver_vehicle_plate
      FROM public.bookings b
      LEFT JOIN public.users d ON b.driver_id = d.id
    `;
    const params: any[] = [];

    if (userId) {
      query += ` WHERE b.user_id = $1`;
      params.push(userId);
    }

    query += ` ORDER BY b.created_at DESC`;

    const result = await pool.query(query, params);
    res.json(result.rows);
  } catch (err: any) {
    console.error('Error fetching bookings:', err);
    res.status(500).json({ error: 'Failed to fetch bookings' });
  }
});

// -------------------------------------------------------------
// GET /api/bookings/:id - Get booking detail
// -------------------------------------------------------------
bookingsRouter.get('/:id', async (req: Request, res: Response): Promise<void> => {
  const { id } = req.params;

  try {
    const result = await pool.query(
      `SELECT b.*, 
              d.first_name as driver_first_name, 
              d.last_name as driver_last_name, 
              d.phone as driver_phone,
              d.vehicle_type as driver_vehicle_type,
              d.vehicle_plate as driver_vehicle_plate,
              u.first_name as user_first_name,
              u.last_name as user_last_name,
              u.phone as user_phone
       FROM public.bookings b
       LEFT JOIN public.users d ON b.driver_id = d.id
       LEFT JOIN public.users u ON b.user_id = u.id
       WHERE b.id::text = $1 OR b.booking_reference = $1`,
      [id]
    );

    if (result.rows.length === 0) {
      res.status(404).json({ error: 'Booking not found' });
      return;
    }

    res.json(result.rows[0]);
  } catch (err: any) {
    console.error('Error fetching booking:', err);
    res.status(500).json({ error: 'Failed to fetch booking details' });
  }
});

// -------------------------------------------------------------
// POST /api/bookings/:id/cancel - Cancel booking
// -------------------------------------------------------------
bookingsRouter.post('/:id/cancel', async (req: Request, res: Response): Promise<void> => {
  const { id } = req.params;

  try {
    const result = await pool.query(
      `UPDATE public.bookings 
       SET status = 'cancelled', updated_at = NOW() 
       WHERE (id::text = $1 OR booking_reference = $1) AND status = 'pending'
       RETURNING *`,
      [id]
    );

    if (result.rows.length === 0) {
      res.status(400).json({ error: 'Booking cannot be cancelled (must be in pending state)' });
      return;
    }

    res.json({ success: true, booking: result.rows[0] });
  } catch (err: any) {
    console.error('Error cancelling booking:', err);
    res.status(500).json({ error: 'Failed to cancel booking' });
  }
});
