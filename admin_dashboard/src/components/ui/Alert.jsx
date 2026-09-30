import { CircleAlert, CircleCheck } from 'lucide-react';

const TONES = {
  success: { icon: CircleCheck, className: 'bg-success-bg border-accent/25 text-accent-light' },
  error: { icon: CircleAlert, className: 'bg-error-bg border-error/25 text-error' },
};

export function Alert({ tone = 'success', action, className = '', children }) {
  const { icon: Icon, className: toneClass } = TONES[tone];
  return (
    <div
      role={tone === 'error' ? 'alert' : 'status'}
      className={`flex items-center gap-3 px-4 py-3 rounded-[18px] border text-[13px] font-medium shrink-0 ${toneClass} ${className}`}
    >
      <Icon size={18} strokeWidth={2.2} className="shrink-0" />
      <div className="flex-1 min-w-0">{children}</div>
      {action}
    </div>
  );
}
