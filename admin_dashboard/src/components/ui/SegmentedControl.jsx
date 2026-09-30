import { useSlidingIndicator } from './hooks';

/**
 * Glass pill of options with a capsule that slides under the selected one
 * (client GlassSegmentedControl). Options: { value, label, count? }.
 */
export function SegmentedControl({ options, value, onChange, className = '' }) {
  const { register, box } = useSlidingIndicator(value);

  return (
    <div className={`glass relative rounded-full p-1 max-w-full min-w-0 ${className}`}>
      <div role="tablist" className="relative flex overflow-x-auto scrollbar-none rounded-full">
        {box && (
          <span
            aria-hidden
            className="absolute top-0 rounded-full bg-white/14 transition-[left,width] duration-300 ease-out-cubic"
            style={{ left: box.left, width: box.width, height: box.height }}
          />
        )}
        {options.map((option) => {
          const selected = option.value === value;
          return (
            <button
              key={option.value}
              ref={register(option.value)}
              type="button"
              role="tab"
              aria-selected={selected}
              onClick={() => onChange(option.value)}
              className={`relative shrink-0 h-[38px] px-4 rounded-full text-[13px] whitespace-nowrap cursor-pointer transition-colors ${
                selected ? 'font-bold text-white' : 'font-medium text-white/55 hover:text-white/80'
              }`}
            >
              {option.label}
              {option.count != null && <span className="tabular-nums"> ({option.count})</span>}
            </button>
          );
        })}
      </div>
    </div>
  );
}
