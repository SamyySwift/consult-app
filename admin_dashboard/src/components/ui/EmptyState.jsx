import { LoaderCircle } from 'lucide-react';
import { IconTile, SurfaceCard } from './SurfaceCard';

/** Card with a green icon, a title, a line of help and an optional action. */
export function EmptyState({ icon, title, subtitle, action, className = '' }) {
  return (
    <SurfaceCard radius="rounded-[30px]" className={`flex flex-col items-center px-6 pt-7 pb-6 text-center ${className}`}>
      <IconTile icon={icon} size={64} iconSize={30} radius={22} accent />
      <h3 className="mt-4 text-[18px] font-bold text-white">{title}</h3>
      {subtitle && <p className="mt-1.5 max-w-sm text-[14px] leading-[1.4] text-white/60">{subtitle}</p>}
      {action && <div className="mt-5">{action}</div>}
    </SurfaceCard>
  );
}

export function Loading({ label }) {
  return (
    <div role="status" className="flex-1 flex flex-col items-center justify-center gap-3 p-8">
      <LoaderCircle size={36} strokeWidth={2.4} className="text-accent animate-spin" />
      <span className="text-[14px] font-medium text-muted">{label}</span>
    </div>
  );
}
