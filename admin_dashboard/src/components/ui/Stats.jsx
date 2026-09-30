import { useId } from 'react';
import { SurfaceCard } from './SurfaceCard';
import { useElementSize } from './hooks';

/** One card of numbers in columns split by short dividers (client profile stats). */
export function StatsStrip({ items, className = '' }) {
  return (
    <SurfaceCard
      className={`grid py-[18px] shrink-0 ${className}`}
      style={{ gridTemplateColumns: `repeat(${items.length}, minmax(0, 1fr))` }}
    >
      {items.map((item, i) => (
        <div
          key={item.label}
          className={`relative flex flex-col items-center gap-1 px-4 text-center min-w-0 ${
            i > 0 ? 'before:absolute before:left-0 before:top-1/2 before:-translate-y-1/2 before:h-8 before:w-px before:bg-white/8' : ''
          }`}
        >
          <div className={`text-[24px] font-extrabold leading-tight tabular-nums truncate max-w-full ${item.tone ?? 'text-white'}`}>
            {item.value}
          </div>
          <div className="text-[12px] text-white/50 truncate max-w-full">{item.label}</div>
        </div>
      ))}
    </SurfaceCard>
  );
}

/**
 * The client's hero: a label, a large gradient number, and a bracket fanning
 * out to a row of glass pills. Each pill's rim fills with its share of the
 * whole. Pills: { icon, value, label, progress (0–1) }.
 */
export function HeroStats({ label, value, pills, className = '' }) {
  const [bracketRef, { width }] = useElementSize();

  return (
    <div className={`flex flex-col items-center text-center ${className}`}>
      <p className="text-[15px] font-semibold text-white/80">{label}</p>
      <div className="gradient-hero-text text-[80px] font-extrabold leading-[1.1] tracking-[-2px] tabular-nums">
        {value}
      </div>
      <div ref={bracketRef} className="w-full h-[30px] mt-1">
        <Bracket width={width} count={pills.length} />
      </div>
      <div
        className="w-full grid mt-1.5"
        style={{ gridTemplateColumns: `repeat(${pills.length}, minmax(0, 1fr))` }}
      >
        {pills.map((pill) => (
          <StatPill key={pill.label} {...pill} />
        ))}
      </div>
    </div>
  );
}

function StatPill({ icon: Icon, value, label, progress }) {
  const [ref, size] = useElementSize();
  return (
    <div className="flex flex-col items-center min-w-0 px-1">
      <div
        ref={ref}
        className="glass [--rim:none] relative inline-flex items-center gap-1.5 px-4 py-2.5 rounded-full"
      >
        <ProgressRim {...size} progress={progress} />
        <Icon size={18} strokeWidth={2.2} className="text-accent-light" />
        <span className="text-[20px] font-bold leading-none text-white tabular-nums">{value}</span>
      </div>
      <span className="mt-2.5 text-[13px] font-semibold text-white/90 truncate max-w-full">{label}</span>
    </div>
  );
}

/** Pill-shaped track with a green arc running clockwise from the top centre. */
function ProgressRim({ width: w, height: h, progress }) {
  const id = `rim${useId().replace(/[^a-zA-Z0-9]/g, '')}`;
  if (!w || !h) return null;

  const stroke = 2.5;
  const x0 = stroke / 2;
  const y0 = stroke / 2;
  const x1 = w - stroke / 2;
  const y1 = h - stroke / 2;
  const r = (y1 - y0) / 2;
  const d = `M ${w / 2} ${y0} H ${x1 - r} A ${r} ${r} 0 0 1 ${x1 - r} ${y1} H ${x0 + r} A ${r} ${r} 0 0 1 ${x0 + r} ${y0} Z`;
  const share = Math.min(1, Math.max(0, progress ?? 0));

  return (
    <>
      <svg aria-hidden width={w} height={h} className="absolute inset-0 pointer-events-none">
        <path d={d} fill="none" stroke="rgba(255,255,255,0.14)" strokeWidth={stroke} />
      </svg>
      {share > 0 && (
        <svg
          aria-hidden
          width={w}
          height={h}
          className="absolute inset-0 pointer-events-none overflow-visible drop-shadow-[0_0_4px_rgb(105_240_174/0.55)]"
        >
          <defs>
            <linearGradient id={id} x1="0" y1="0" x2="1" y2="1">
              <stop offset="0" stopColor="#69F0AE" />
              <stop offset="1" stopColor="#00C853" />
            </linearGradient>
          </defs>
          <path
            d={d}
            fill="none"
            stroke={`url(#${id})`}
            strokeWidth={stroke}
            strokeLinecap="round"
            pathLength={1}
            strokeDasharray={`${share} 1`}
            className="transition-[stroke-dasharray] duration-700 ease-out-cubic"
          />
        </svg>
      )}
    </>
  );
}

/** Curly bracket from the hero number down to the centre of each column. */
function Bracket({ width: w, count }) {
  if (!w || count < 2) return null;
  const h = 30;
  const mid = h / 2;
  const r = 14;
  const left = w / (2 * count);
  const right = w - left;
  const cx = w / 2;

  let d =
    `M ${left} ${h} Q ${left} ${mid} ${left + r} ${mid} L ${cx - r} ${mid} Q ${cx} ${mid} ${cx} 0 ` +
    `Q ${cx} ${mid} ${cx + r} ${mid} L ${right - r} ${mid} Q ${right} ${mid} ${right} ${h}`;
  for (let i = 1; i < count - 1; i++) {
    const x = (w * (2 * i + 1)) / (2 * count);
    d += ` M ${x} ${mid} L ${x} ${h}`;
  }

  return (
    <svg aria-hidden width={w} height={h} className="block overflow-visible">
      <path d={d} fill="none" stroke="rgba(255,255,255,0.3)" strokeWidth={1.5} strokeLinecap="round" />
    </svg>
  );
}

/** Row of rounded segments, the first `filled` of them lit. */
export function SegmentProgressBar({ total, filled, error = false }) {
  const lit = error
    ? 'bg-error shadow-[0_0_6px_rgb(255_82_82/0.35)]'
    : 'bg-accent shadow-[0_0_6px_rgb(0_200_83/0.35)]';
  return (
    <div className="flex gap-1.5" role="progressbar" aria-valuemin={0} aria-valuemax={total} aria-valuenow={filled}>
      {Array.from({ length: total }, (_, i) => (
        <span key={i} className={`h-[5px] flex-1 rounded-[3px] ${i < filled ? lit : 'bg-white/10'}`} />
      ))}
    </div>
  );
}
