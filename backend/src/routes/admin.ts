import { Router, Request, Response } from 'express';
import { pool } from '../db';
import { notifyBookingStatus } from '../services/bookingNotifications';
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
        created_at,
        partner_id,
        (SELECT name FROM public.partners p WHERE p.id = users.partner_id) AS partner_name
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
// Partners - companies drivers work for. Deactivated rather than deleted,
// so drivers linked to a partner keep their company.
// -------------------------------------------------------------
const PARTNER_TEXT_FIELDS = [
  'name',
  'contact_name',
  'contact_phone',
  'contact_email',
  'address',
  'registration_number',
  'notes',
] as const;

function readPartnerFields(body: any): Record<string, string> {
  const fields: Record<string, string> = {};
  for (const key of PARTNER_TEXT_FIELDS) {
    if (typeof body[key] === 'string') fields[key] = body[key].trim();
  }
  return fields;
}

// GET /api/admin/partners - All partners with their driver counts
adminRouter.get('/partners', async (_req: Request, res: Response): Promise<void> => {
  try {
    const result = await pool.query(`
      SELECT p.*, COUNT(u.id)::int AS driver_count
      FROM public.partners p
      LEFT JOIN public.users u ON u.partner_id = p.id AND u.role = 'driver'
      GROUP BY p.id
      ORDER BY p.is_active DESC, p.name ASC
    `);
    res.json(result.rows);
  } catch (err: any) {
    console.error('Error fetching partners:', err);
    res.status(500).json({ error: 'Failed to fetch partners: ' + err.message });
  }
});

// POST /api/admin/partners - Add a partner
adminRouter.post('/partners', async (req: Request, res: Response): Promise<void> => {
  const fields = readPartnerFields(req.body);
  if (!fields.name) {
    res.status(400).json({ error: 'Company name is required' });
    return;
  }

  try {
    const result = await pool.query(
      `INSERT INTO public.partners
        (name, contact_name, contact_phone, contact_email, address, registration_number, notes, is_active)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
       RETURNING *, 0 AS driver_count`,
      [
        fields.name,
        fields.contact_name ?? '',
        fields.contact_phone ?? '',
        fields.contact_email ?? '',
        fields.address ?? '',
        fields.registration_number ?? '',
        fields.notes ?? '',
        req.body.is_active !== false,
      ]
    );
    res.status(201).json(result.rows[0]);
  } catch (err: any) {
    console.error('Error creating partner:', err);
    res.status(500).json({ error: 'Failed to create partner: ' + err.message });
  }
});

// PUT /api/admin/partners/:id - Edit a partner's details or active status
adminRouter.put('/partners/:id', async (req: Request, res: Response): Promise<void> => {
  const fields = readPartnerFields(req.body);
  if ('name' in fields && !fields.name) {
    res.status(400).json({ error: 'Company name cannot be empty' });
    return;
  }

  const sets: string[] = [];
  const values: any[] = [];
  for (const [key, value] of Object.entries(fields)) {
    values.push(value);
    sets.push(`${key} = $${values.length}`);
  }
  if (typeof req.body.is_active === 'boolean') {
    values.push(req.body.is_active);
    sets.push(`is_active = $${values.length}`);
  }
  if (sets.length === 0) {
    res.status(400).json({ error: 'Nothing to update' });
    return;
  }

  values.push(req.params.id);
  try {
    const result = await pool.query(
      `UPDATE public.partners SET ${sets.join(', ')}, updated_at = NOW()
       WHERE id::text = $${values.length}
       RETURNING *, (SELECT COUNT(*)::int FROM public.users u
                     WHERE u.partner_id = partners.id AND u.role = 'driver') AS driver_count`,
      values
    );
    if (result.rows.length === 0) {
      res.status(404).json({ error: 'Partner not found' });
      return;
    }
    res.json(result.rows[0]);
  } catch (err: any) {
    console.error('Error updating partner:', err);
    res.status(500).json({ error: 'Failed to update partner: ' + err.message });
  }
});

// GET /api/admin/partners/:id/drivers - Drivers working for a partner
adminRouter.get('/partners/:id/drivers', async (req: Request, res: Response): Promise<void> => {
  try {
    const result = await pool.query(
      `SELECT id, first_name, last_name, email, phone, vehicle_type, vehicle_plate,
              is_online, is_verified, total_trips, created_at
       FROM public.users
       WHERE role = 'driver' AND partner_id::text = $1
       ORDER BY first_name ASC`,
      [req.params.id]
    );
    res.json(
      result.rows.map((d) => ({
        ...d,
        full_name: `${d.first_name || ''} ${d.last_name || ''}`.trim() || 'Driver',
      }))
    );
  } catch (err: any) {
    console.error('Error fetching partner drivers:', err);
    res.status(500).json({ error: 'Failed to fetch partner drivers: ' + err.message });
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

    void notifyBookingStatus(result.rows[0].id, result.rows[0].status);

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

    void notifyBookingStatus(result.rows[0].id, result.rows[0].status);

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
