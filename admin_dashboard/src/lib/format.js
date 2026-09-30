// Same formats as the client app (consult_client/lib/core/utils/formatters.dart)

const thousands = new Intl.NumberFormat('en-US', { maximumFractionDigits: 0 });

/** Whole-naira amount with thousands separators, e.g. `₦1,500,000`. */
export const formatNaira = (amount) => `₦${thousands.format(Math.round(Number(amount) || 0))}`;

/**
 * Short, readable booking reference: the first block of a UUID, uppercased
 * (`ac20d396-0831-…` → `AC20D396`). Non-UUID ids are returned uppercased.
 */
export const shortRef = (id) => String(id ?? '').split('-')[0].toUpperCase();

export const vehicleName = (job) =>
  [job.vehicle.year, job.vehicle.make, job.vehicle.model].filter(Boolean).join(' ');

/** Up to two initials, e.g. `Ops Admin` → `OA`. */
export const initials = (name) =>
  String(name ?? '')
    .split(/\s+/)
    .filter(Boolean)
    .slice(0, 2)
    .map((w) => w[0].toUpperCase())
    .join('') || '?';
