import { statusOf, TONES } from '../../lib/status';

/** Pill with a dot and a label, coloured by tone (see TONES). */
export function Badge({ tone = 'neutral', compact = false, pulse = false, children }) {
  return (
    <span
      className={`inline-flex items-center gap-1.5 w-fit rounded-full font-semibold whitespace-nowrap ${
        compact ? 'px-2 py-1 text-[11px]' : 'px-3 py-1.5 text-[12px]'
      } ${TONES[tone]}`}
    >
      <span className={`size-1.5 rounded-full bg-current ${pulse ? 'animate-pulse-dot' : ''}`} />
      {children}
    </span>
  );
}

/** A booking's status, as the client app shows it. */
export function StatusBadge({ status, compact = false }) {
  const { label, tone } = statusOf(status);
  return (
    <Badge tone={tone} compact={compact} pulse={status === 'inTransit'}>
      {label}
    </Badge>
  );
}
