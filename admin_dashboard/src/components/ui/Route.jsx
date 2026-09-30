import { MapPin } from 'lucide-react';

/** Pickup on a glowing green dot, drop-off on a pin (client booking tile). */
export function Route({ pickup, dropoff, compact = false }) {
  return (
    <div className={`flex flex-col min-w-0 ${compact ? 'gap-1 text-[12px]' : 'gap-2 text-[13px]'}`}>
      <div className="flex items-center gap-2.5 min-w-0">
        <span className="grid place-items-center w-4 shrink-0">
          <span className="size-[7px] rounded-full bg-accent shadow-[0_0_6px_rgb(0_200_83/0.6)]" />
        </span>
        <span className="truncate text-white/85" title={pickup}>{pickup}</span>
      </div>
      <div className="flex items-center gap-2.5 min-w-0">
        <MapPin size={compact ? 14 : 15} strokeWidth={2.2} className="w-4 shrink-0 text-white/55" />
        <span className="truncate text-white/55" title={dropoff}>{dropoff}</span>
      </div>
    </div>
  );
}
