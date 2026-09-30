import { ChevronDown, ChevronUp, ChevronsUpDown } from 'lucide-react';
import { SurfaceCard } from './SurfaceCard';

/** A table inside a card that scrolls under its sticky header. */
export function TableCard({ minWidth, className = '', children }) {
  return (
    <SurfaceCard className={`flex-1 min-h-[240px] overflow-auto scrollbar-thin ${className}`}>
      <table className="w-full text-left border-collapse" style={minWidth ? { minWidth } : undefined}>
        {children}
      </table>
    </SurfaceCard>
  );
}

/** Header cell. With `onSort` it is clickable and shows `sorted` ('asc' | 'desc' | null). */
export function Th({ onSort, sorted, className = '', children }) {
  const SortIcon = sorted === 'asc' ? ChevronUp : sorted === 'desc' ? ChevronDown : ChevronsUpDown;
  return (
    <th
      aria-sort={sorted === 'asc' ? 'ascending' : sorted === 'desc' ? 'descending' : undefined}
      className={`sticky top-0 z-10 bg-surface px-4 py-3.5 border-b border-white/6 text-[11px] font-bold uppercase tracking-[1.2px] text-white/45 whitespace-nowrap ${className}`}
    >
      {onSort ? (
        <button
          type="button"
          onClick={onSort}
          className={`inline-flex items-center gap-1 uppercase tracking-[1.2px] cursor-pointer transition-colors hover:text-white ${
            sorted ? 'text-white/80' : ''
          }`}
        >
          {children}
          <SortIcon size={13} strokeWidth={2.4} className={sorted ? '' : 'opacity-50'} />
        </button>
      ) : (
        children
      )}
    </th>
  );
}

export function Tr({ onClick, className = '', children }) {
  return (
    <tr
      onClick={onClick}
      className={`border-b border-white/6 last:border-0 transition-colors hover:bg-white/3 ${
        onClick ? 'cursor-pointer' : ''
      } ${className}`}
    >
      {children}
    </tr>
  );
}

export function Td({ className = '', children, ...props }) {
  return (
    <td {...props} className={`px-4 py-3.5 text-[13px] align-middle ${className}`}>
      {children}
    </td>
  );
}

export function EmptyRow({ colSpan, children }) {
  return (
    <tr>
      <td colSpan={colSpan} className="px-4 py-16 text-center text-[14px] text-white/55">
        {children}
      </td>
    </tr>
  );
}
