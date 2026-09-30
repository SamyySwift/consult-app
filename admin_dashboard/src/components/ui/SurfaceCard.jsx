// Flat content layer, as in consult_client/lib/core/widgets/surface.dart

/**
 * Flat card: solid surface with a hairline border. Glass belongs to floating
 * controls; cards and rows that scroll with content use this instead.
 * Pass `radius` as a rounded-* class to change the corner.
 */
export function SurfaceCard({ radius = 'rounded-card', onClick, className = '', children, ...rest }) {
  const clickable = onClick
    ? {
        onClick,
        role: 'button',
        tabIndex: 0,
        onKeyDown: (e) => {
          if (e.key === 'Enter' || e.key === ' ') {
            e.preventDefault();
            onClick(e);
          }
        },
      }
    : {};

  return (
    <div
      className={`bg-surface border border-line ${radius} ${
        onClick ? 'cursor-pointer transition-colors duration-200 hover:border-white/20 hover:bg-[#191919]' : ''
      } ${className}`}
      {...clickable}
      {...rest}
    >
      {children}
    </div>
  );
}

/**
 * Rounded square holding an icon, for the leading slot of a card or row.
 * `accent` tints it green; keep that for tiles that carry status.
 */
export function IconTile({ icon: Icon, size = 44, iconSize = 20, radius = 14, accent = false, className = '' }) {
  return (
    <span
      className={`grid place-items-center shrink-0 ${
        accent ? 'bg-accent/12 text-accent-light' : 'bg-surface-variant text-white/85'
      } ${className}`}
      style={{ width: size, height: size, borderRadius: radius }}
    >
      <Icon size={iconSize} strokeWidth={2} />
    </span>
  );
}

/** Small flat label chip, e.g. a service name or "Insured". */
export function FlatChip({ icon: Icon, accent = false, className = '', children }) {
  return (
    <span
      className={`inline-flex items-center gap-[5px] px-2.5 py-[5px] rounded-full text-[11px] font-semibold whitespace-nowrap ${
        accent ? 'bg-accent/12 text-accent-light' : 'bg-surface-variant text-white/80'
      } ${className}`}
    >
      {Icon && <Icon size={12} strokeWidth={2.4} />}
      {children}
    </span>
  );
}
