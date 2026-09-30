import { LoaderCircle } from 'lucide-react';

const VARIANTS = {
  // Green gradient pill with black text: the one call to action on a screen
  primary: 'gradient-accent text-black shadow-glow hover:brightness-110',
  glass: 'glass text-white hover:bg-white/8',
  outline: 'border border-line text-white hover:bg-white/5',
  danger: 'bg-error text-white shadow-glow-error hover:brightness-110',
  ghost: 'text-white/70 hover:text-white hover:bg-white/5',
  dangerGhost: 'text-error hover:bg-error-bg',
};

const SIZES = {
  sm: 'h-9 px-4 text-[13px] gap-1.5',
  md: 'h-11 px-5 text-[14px] gap-2',
};

export function Button({ variant = 'primary', size = 'md', icon: Icon, loading = false, className = '', children, ...props }) {
  const iconSize = size === 'sm' ? 15 : 17;
  return (
    <button
      type="button"
      {...props}
      disabled={loading || props.disabled}
      className={`relative inline-flex items-center justify-center rounded-full font-semibold whitespace-nowrap cursor-pointer transition-[filter,background-color,color,transform] duration-200 active:scale-[0.98] disabled:opacity-50 disabled:cursor-not-allowed disabled:shadow-none disabled:active:scale-100 ${VARIANTS[variant]} ${SIZES[size]} ${className}`}
    >
      {loading ? (
        <LoaderCircle size={iconSize} strokeWidth={2.4} className="animate-spin" />
      ) : (
        Icon && <Icon size={iconSize} strokeWidth={2.2} />
      )}
      {children}
    </button>
  );
}

/** Glass circle holding an icon, with an optional count badge. */
export function GlassIconButton({ icon: Icon, label, badge, size = 44, className = '', ...props }) {
  return (
    <button
      type="button"
      aria-label={label}
      title={label}
      {...props}
      className={`glass relative grid place-items-center shrink-0 rounded-full text-white cursor-pointer transition-colors hover:bg-white/8 ${className}`}
      style={{ width: size, height: size }}
    >
      <Icon size={Math.round(size * 0.46)} strokeWidth={2} />
      {badge > 0 && (
        <span className="absolute -top-0.5 -right-0.5 min-w-[18px] h-[18px] px-1 grid place-items-center rounded-full bg-error text-white text-[11px] font-bold">
          {badge}
        </span>
      )}
    </button>
  );
}
