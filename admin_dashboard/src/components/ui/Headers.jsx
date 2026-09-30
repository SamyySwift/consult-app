import { IconTile } from './SurfaceCard';

/** Small uppercase group label, e.g. above a card of settings. */
export function Eyebrow({ className = '', children }) {
  return (
    <div className={`text-[11px] font-bold uppercase tracking-[1.2px] text-white/45 ${className}`}>{children}</div>
  );
}

export function SectionHeader({ title, subtitle, action, className = '' }) {
  return (
    <div className={`flex flex-wrap items-center justify-between gap-4 ${className}`}>
      <div className="min-w-0">
        <h2 className="text-[18px] font-bold text-white">{title}</h2>
        {subtitle && <p className="text-[13px] text-white/55 mt-1">{subtitle}</p>}
      </div>
      {action}
    </div>
  );
}

/** Heading for a card: green icon tile, title and subtitle (client wizard sections). */
export function CardHeader({ icon, title, subtitle, action, className = '' }) {
  return (
    <div className={`flex flex-wrap items-center gap-4 ${className}`}>
      <IconTile icon={icon} radius={12} iconSize={22} accent />
      <div className="flex-1 min-w-[200px]">
        <h3 className="text-[17px] font-bold text-white">{title}</h3>
        {subtitle && <p className="text-[13px] text-muted mt-0.5">{subtitle}</p>}
      </div>
      {action}
    </div>
  );
}

/** Row above a list: a short summary on the left, search and actions on the right. */
export function Toolbar({ summary, children }) {
  return (
    <div className="flex flex-wrap items-center justify-between gap-3 shrink-0">
      <p className="text-[13px] text-white/55">{summary}</p>
      <div className="flex flex-wrap items-center gap-3">{children}</div>
    </div>
  );
}
