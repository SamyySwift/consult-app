// Pickup photos, the voice note and the client's signature are stored inline
// as base64, so they make up nearly all of a booking's size. Lists that apps
// poll every few seconds leave them out; they're fetched per booking instead.
export const BOOKING_MEDIA_COLUMNS = [
  'pickup_condition_images',
  'pickup_condition_audio',
  'client_signature_url',
] as const;

type MediaColumn = (typeof BOOKING_MEDIA_COLUMNS)[number];

export function withoutBookingMedia<T extends Record<string, unknown>>(
  row: T,
  keep: readonly MediaColumn[] = []
): T {
  const copy: Record<string, unknown> = { ...row };
  for (const column of BOOKING_MEDIA_COLUMNS) {
    if (!keep.includes(column)) delete copy[column];
  }
  return copy as T;
}
