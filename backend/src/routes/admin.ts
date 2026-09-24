import { Router, Request, Response } from 'express';
import { pool } from '../db';
import { getInsurancePercentage, setInsurancePercentage } from '../settings';

export const adminRouter = Router();

// -------------------------------------------------------------
// GET /api/admin/bookings - List all bookings for admin command center
// -------------------------------------------------------------
adminRouter.get('/bookings', async (_req: Request, res: Response): Promise<void> => {
  try {
    const result = await pool.query(`
      SELECT 
        b.*,
        u.first_name as client_first_name,
        u.last_name as client_last_name,
        u.email as client_email,
        u.phone as client_phone,
        d.first_name as driver_first_name,
        d.last_name as driver_last_name,
        d.phone as driver_phone,
        d.vehicle_type as driver_assigned_vehicle_type,
        d.vehicle_plate as driver_assigned_vehicle_plate,
        d.rating as driver_rating
      FROM public.bookings b
      LEFT JOIN public.users u ON b.user_id = u.id
      LEFT JOIN public.users d ON b.driver_id = d.id
      ORDER BY b.created_at DESC
    `);

    // Format response to provide both direct joined columns and nested client/driver objects
    const formatted = result.rows.map(row => {
      const clientFullName = [row.client_first_name, row.client_last_name].filter(Boolean).join(' ') || 'Direct Client';
      const driverFullName = [row.driver_first_name, row.driver_last_name].filter(Boolean).join(' ') || (row.driver_id ? 'Assigned Driver' : 'Unassigned');

      return {
        ...row,
        client: {
          full_name: clientFullName,
          email: row.client_email || '',
          phone: row.client_phone || '',
        },
        driver: row.driver_id ? {
          id: row.driver_id,
          full_name: driverFullName,
          phone: row.driver_phone || '',
          vehicle_plate: row.driver_assigned_vehicle_plate || '',
        } : null,
      };
    });

    res.json(formatted);
  } catch (err: any) {
    console.error('Error fetching admin bookings:', err);
    res.status(500).json({ error: 'Failed to fetch bookings: ' + err.message });
  }
});

// -------------------------------------------------------------
// GET /api/admin/drivers - List all registered drivers
// -------------------------------------------------------------
adminRouter.get('/drivers', async (_req: Request, res: Response): Promise<void> => {
  try {
    const result = await pool.query(`
      SELECT 
        id, 
        first_name, 
        last_name, 
        email, 
        phone, 
        license_number, 
        vehicle_type, 
        vehicle_plate, 
        is_online, 
        rating, 
        total_trips,
        current_lat,
        current_lng,
        created_at
      FROM public.users
      WHERE role = 'driver'
      ORDER BY created_at DESC
    `);

    const formatted = result.rows.map(d => ({
      ...d,
      full_name: `${d.first_name || ''} ${d.last_name || ''}`.trim() || 'Driver',
      rating: parseFloat(d.rating || '5.0'),
    }));

    res.json(formatted);
  } catch (err: any) {
    console.error('Error fetching drivers:', err);
    res.status(500).json({ error: 'Failed to fetch drivers: ' + err.message });
  }
});

// -------------------------------------------------------------
// POST /api/admin/assign-driver - Assign or Reassign Driver to Booking
// -------------------------------------------------------------
adminRouter.post('/assign-driver', async (req: Request, res: Response): Promise<void> => {
  const { bookingId, driverId } = req.body;

  if (!bookingId || !driverId) {
    res.status(400).json({ error: 'bookingId and driverId are required' });
    return;
  }

  try {
    const result = await pool.query(
      `UPDATE public.bookings 
       SET driver_id = $1, 
           status = 'assigned', 
           assigned_at = NOW(), 
           updated_at = NOW() 
       WHERE id::text = $2 OR booking_reference = $2
       RETURNING *`,
      [driverId, bookingId]
    );

    if (result.rows.length === 0) {
      res.status(404).json({ error: 'Booking not found' });
      return;
    }

    res.json({ success: true, booking: result.rows[0] });
  } catch (err: any) {
    console.error('Error assigning driver:', err);
    res.status(500).json({ error: 'Failed to assign driver: ' + err.message });
  }
});

// -------------------------------------------------------------
// POST /api/admin/bookings/:id/status - Update booking status from admin
// -------------------------------------------------------------
adminRouter.post('/bookings/:id/status', async (req: Request, res: Response): Promise<void> => {
  const { id } = req.params;
  const { status } = req.body;

  if (!status) {
    res.status(400).json({ error: 'Status is required' });
    return;
  }

  try {
    let updateFields = `status = $1, updated_at = NOW()`;
    if (status === 'pickedUp' || status === 'picked_up') {
      updateFields += `, picked_up_at = NOW()`;
    }
    if (status === 'completed' || status === 'delivered') {
      updateFields += `, completed_at = NOW()`;
    }

    const result = await pool.query(
      `UPDATE public.bookings SET ${updateFields} WHERE id::text = $2 OR booking_reference = $2 RETURNING *`,
      [status, id]
    );

    if (result.rows.length === 0) {
      res.status(404).json({ error: 'Booking not found' });
      return;
    }

    res.json({ success: true, booking: result.rows[0] });
  } catch (err: any) {
    console.error('Error updating booking status:', err);
    res.status(500).json({ error: 'Failed to update booking status: ' + err.message });
  }
});

// -------------------------------------------------------------
// GET /api/admin/pricing - Get pricing configuration
// -------------------------------------------------------------
adminRouter.get('/pricing', async (_req: Request, res: Response): Promise<void> => {
  try {
    const result = await pool.query('SELECT * FROM public.pricing_config ORDER BY id ASC');
    res.json(result.rows);
  } catch (err: any) {
    console.error('Error fetching pricing config:', err);
    res.status(500).json({ error: 'Failed to fetch pricing config: ' + err.message });
  }
});

// -------------------------------------------------------------
// POST /api/admin/pricing - Save pricing configuration
// -------------------------------------------------------------
adminRouter.post('/pricing', async (req: Request, res: Response): Promise<void> => {
  const items = Array.isArray(req.body) ? req.body : [req.body];

  try {
    for (const item of items) {
      if (item.id) {
        await pool.query(
          `UPDATE public.pricing_config 
           SET base_price = $1, enclosed_addon = $2, insurance_rate = COALESCE($3, insurance_rate), updated_at = NOW()
           WHERE id = $4`,
          [item.base_price, item.enclosed_addon, item.insurance_rate ?? null, item.id]
        );
      }
    }

    const updated = await pool.query('SELECT * FROM public.pricing_config ORDER BY id ASC');
    res.json({ success: true, pricing: updated.rows });
  } catch (err: any) {
    console.error('Error saving pricing:', err);
    res.status(500).json({ error: 'Failed to save pricing: ' + err.message });
  }
});

// -------------------------------------------------------------
// GET /api/admin/settings/insurance - Get insurance percentage
// -------------------------------------------------------------
adminRouter.get('/settings/insurance', async (_req: Request, res: Response): Promise<void> => {
  try {
    res.json({ insurance_percentage: await getInsurancePercentage() });
  } catch (err: any) {
    console.error('Error fetching insurance settings:', err);
    res.status(500).json({ error: 'Failed to fetch insurance settings: ' + err.message });
  }
});

// -------------------------------------------------------------
// POST /api/admin/settings/insurance - Save insurance percentage
// -------------------------------------------------------------
adminRouter.post('/settings/insurance', async (req: Request, res: Response): Promise<void> => {
  const pct = Number(req.body.insurance_percentage);
  if (!Number.isFinite(pct) || pct < 0 || pct > 100) {
    res.status(400).json({ error: 'Insurance percentage must be a number between 0 and 100' });
    return;
  }

  try {
    await setInsurancePercentage(pct);
    res.json({ success: true, insurance_percentage: pct });
  } catch (err: any) {
    console.error('Error saving insurance settings:', err);
    res.status(500).json({ error: 'Failed to save insurance settings: ' + err.message });
  }
});

// -------------------------------------------------------------
// GET /api/admin/stats - Overview metrics
// -------------------------------------------------------------
adminRouter.get('/stats', async (_req: Request, res: Response): Promise<void> => {
  try {
    const totalRes = await pool.query('SELECT COUNT(*) FROM public.bookings');
    const pendingRes = await pool.query("SELECT COUNT(*) FROM public.bookings WHERE status = 'pending'");
    const activeRes = await pool.query("SELECT COUNT(*) FROM public.bookings WHERE status IN ('assigned', 'confirmed', 'pickedUp', 'picked_up', 'inTransit', 'in_transit')");
    const completedRes = await pool.query("SELECT COUNT(*) FROM public.bookings WHERE status IN ('completed', 'delivered')");
    const driversRes = await pool.query("SELECT COUNT(*) FROM public.users WHERE role = 'driver'");
    const revenueRes = await pool.query("SELECT COALESCE(SUM(total_amount), 0) as total FROM public.bookings WHERE status IN ('completed', 'delivered')");

    res.json({
      totalBookings: parseInt(totalRes.rows[0].count, 10),
      pendingBookings: parseInt(pendingRes.rows[0].count, 10),
      activeBookings: parseInt(activeRes.rows[0].count, 10),
      completedBookings: parseInt(completedRes.rows[0].count, 10),
      totalDrivers: parseInt(driversRes.rows[0].count, 10),
      totalRevenue: parseFloat(revenueRes.rows[0].total),
    });
  } catch (err: any) {
    console.error('Error fetching admin stats:', err);
    res.status(500).json({ error: 'Failed to fetch admin stats: ' + err.message });
  }
});
