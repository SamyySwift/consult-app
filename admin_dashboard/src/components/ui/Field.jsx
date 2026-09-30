import { ChevronDown, Search } from 'lucide-react';

// Filled, borderless at rest, accent border on focus (client InputDecorationTheme)
const CONTROL =
  'w-full bg-surface-variant border-[1.5px] border-transparent px-4 text-[14px] font-medium text-white placeholder:text-subtle placeholder:font-normal outline-none transition-colors focus:border-accent';

/** A label above its control, with an optional hint underneath. */
export function Field({ label, hint, className = '', children }) {
  return (
    <label className={`flex flex-col gap-2 ${className}`}>
      <span className="text-[13px] font-medium text-white">{label}</span>
      {children}
      {hint && <span className="text-[12px] text-white/50">{hint}</span>}
    </label>
  );
}

export function Input({ className = '', ...props }) {
  return <input {...props} className={`${CONTROL} h-12 rounded-tile ${className}`} />;
}

export function Textarea({ className = '', ...props }) {
  return <textarea {...props} className={`${CONTROL} py-3 rounded-tile resize-none ${className}`} />;
}

export function Select({ className = '', children, ...props }) {
  return (
    <div className="relative">
      <select {...props} className={`${CONTROL} h-12 pr-11 rounded-tile appearance-none cursor-pointer ${className}`}>
        {children}
      </select>
      <ChevronDown size={18} className="absolute right-4 top-1/2 -translate-y-1/2 text-white/55 pointer-events-none" />
    </div>
  );
}

/** Pill search box whose icon turns green while focused. */
export function SearchField({ value, onChange, placeholder, className = '' }) {
  return (
    <div className={`group relative ${className}`}>
      <Search
        size={17}
        className="absolute left-4 top-1/2 -translate-y-1/2 text-subtle pointer-events-none transition-colors group-focus-within:text-accent"
      />
      <input
        type="text"
        value={value}
        onChange={(e) => onChange(e.target.value)}
        placeholder={placeholder}
        aria-label={placeholder}
        className={`${CONTROL} h-11 pl-11 rounded-full`}
      />
    </div>
  );
}
