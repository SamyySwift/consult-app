import { initials } from '../../lib/format';

/** Initials in a neutral circle. Green is kept for status, so avatars stay grey. */
export function Avatar({ name, size = 36, glass = false, className = '', ...props }) {
  return (
    <span
      {...props}
      className={`relative grid place-items-center shrink-0 rounded-full font-bold ${
        glass ? 'glass text-white' : 'bg-surface-variant text-white/85'
      } ${className}`}
      style={{ width: size, height: size, fontSize: Math.round(size * 0.36) }}
    >
      {initials(name)}
    </span>
  );
}
