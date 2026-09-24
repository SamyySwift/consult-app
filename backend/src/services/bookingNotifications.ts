import { pool } from '../db';
import { sendBookingStatusEmail } from './email';

// Statuses the client is emailed about. Keys are the DB status values; several
// routes write different spellings for the same state.
const STATUS_MESSAGES: Record<string, { subject: string; heading: string; body: string }> = {
  assigned: {
    subject: 'A driver has been assigned',
    heading: 'Driver assigned',
    body: 'A driver has been assigned to your booking and will contact you before pickup.',
  },
  pickedUp: {
    subject: 'Your vehicle has been picked up',
    heading: 'Vehicle picked up',
    body: 'Your driver has collected your vehicle.',
  },
  inTransit: {
    subject: 'Your vehicle is on its way',
    heading: 'In transit',
    body: 'Your vehicle is on its way to the delivery address.',
  },
  outForDelivery: {
    subject: 'Your vehicle is almost there',
    heading: 'Out for delivery',
    body: 'Your vehicle is nearly at the delivery address.',
  },
  completed: {
    subject: 'Your vehicle has been delivered',
    heading: 'Delivered',
    body: 'Your vehicle has been delivered. Thank you for choosing Carpital Consult.',
  },
};

const STATUS_ALIASES: Record<string, string> = {
  picked_up: 'pickedUp',
  in_transit: 'inTransit',
  out_for_delivery: 'outForDelivery',
  delivered: 'completed',
};

/**
 * Emails the booking's client about a status change. Safe to call after every
 * status update: it only sends once per status, and never throws, so callers
 * can fire and forget without affecting the HTTP response.
 */
export async function notifyBookingStatus(bookingId: string, rawStatus: string): Promise<void> {
  const status = STATUS_ALIASES[rawStatus] ?? rawStatus;
  const message = STATUS_MESSAGES[status];
  if (!message) return;

  try {
    // Claim the notification atomically so concurrent or repeated updates send once.
    const claimed = await pool.query(
      `UPDATE public.bookings b
       SET last_notified_status = $2
       FROM public.users u
       WHERE b.id = $1 AND u.id = b.user_id
         AND b.last_notified_status IS DISTINCT FROM $2
       RETURNING b.booking_reference, b.vehicle_year, b.vehicle_make, b.vehicle_model,
                 b.dropoff_address, u.email, u.first_name`,
      [bookingId, status]
    );

    const row = claimed.rows[0];
    if (!row?.email) return;

    const vehicle = [row.vehicle_year, row.vehicle_make, row.vehicle_model].filter(Boolean).join(' ');
    await sendBookingStatusEmail({
      toEmail: row.email,
      firstName: row.first_name,
      subject: `${message.subject} (${row.booking_reference || 'your booking'})`,
      heading: message.heading,
      body: message.body,
      reference: row.booking_reference,
      vehicle,
      dropoffAddress: row.dropoff_address,
    });
  } catch (err) {
    console.error(`Failed to send status email for booking ${bookingId}:`, err);
  }
}
