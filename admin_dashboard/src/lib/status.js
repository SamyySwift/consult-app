/**
 * Booking statuses as AppContext normalises them, styled like the client
 * app's StatusBadge (consult_client/lib/core/widgets/status_badge.dart).
 * `stage` is how many of the journey's five steps are done, as in the client.
 */
export const STATUS = {
  pending:   { label: 'Pending',    tone: 'warning', stage: 0 },
  assigned:  { label: 'Assigned',   tone: 'neutral', stage: 0 },
  confirmed: { label: 'Confirmed',  tone: 'info',    stage: 1 },
  pickedUp:  { label: 'Picked Up',  tone: 'info',    stage: 2 },
  inTransit: { label: 'In Transit', tone: 'live',    stage: 3 },
  completed: { label: 'Delivered',  tone: 'success', stage: 5 },
  cancelled: { label: 'Cancelled',  tone: 'error',   stage: 0 },
};

export const STAGE_COUNT = 5;

export const statusOf = (status) => STATUS[status] ?? STATUS.pending;

/** Badge colours per tone. `live` is the accent, for things happening now. */
export const TONES = {
  neutral: 'bg-surface-variant text-white/80',
  warning: 'bg-warning-bg text-warning',
  info:    'bg-info-bg text-info',
  live:    'bg-accent/12 text-accent',
  success: 'bg-success-bg text-success',
  error:   'bg-error-bg text-error',
};

/** A driver has accepted the job and is heading to, or carrying, the vehicle. */
export const ACTIVE = ['confirmed', 'pickedUp', 'inTransit'];

/** Waiting for a driver to be assigned or to accept. */
export const AWAITING = ['pending', 'assigned'];

/** Driver markers on the live map, keyed by the job's status. */
export const MAP_LOOK = {
  inTransit: { label: 'In transit',        fill: 'linear-gradient(135deg, #00C853, #69F0AE)', dot: '#00C853', ink: '#000000' },
  pickedUp:  { label: 'Picked up',         fill: '#448AFF', dot: '#448AFF', ink: '#FFFFFF' },
  confirmed: { label: 'Heading to pickup', fill: '#FFFFFF', dot: '#FFFFFF', ink: '#000000' },
};

/** A marker whose position is too old to trust. */
export const STALE_LOOK = { fill: '#2A2A2A', dot: '#5C5C5C', ink: '#8A8A8A' };
