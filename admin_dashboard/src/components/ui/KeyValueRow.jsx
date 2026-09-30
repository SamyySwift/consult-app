/** Summary row: icon, label, and the value right-aligned (client review screen rows). */
export function KeyValueRow({ icon: Icon, label, className = '', children }) {
  return (
    <div className="flex items-start gap-3 py-2.5 text-[13px] border-b border-white/6 last:border-0">
      {Icon && <Icon size={16} strokeWidth={2} className="mt-px shrink-0 text-subtle" />}
      <span className="w-24 shrink-0 text-muted">{label}</span>
      <span className={`flex-1 min-w-0 text-right font-semibold break-words ${className || 'text-white'}`}>{children}</span>
    </div>
  );
}
