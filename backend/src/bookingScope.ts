// Bookings still in progress. Apps poll just these with ?scope=open and load
// the full history less often, so polls stay small however much history builds up.
export const OPEN_BOOKING_STATUSES = [
  'pending',
  'assigned',
  'confirmed',
  'pickedUp',
  'picked_up',
  'inTransit',
  'in_transit',
  'outForDelivery',
];
