import React from 'react';
import { Building2, ClipboardList, LayoutDashboard, Map as MapIcon, Settings, UserRound, Users, Wallet } from 'lucide-react';
import { Avatar, useSlidingIndicator } from './ui';

const NAV_ITEMS = [
  { id: 'dispatch', label: 'Dispatch', icon: LayoutDashboard },
  { id: 'map', label: 'Live Map', icon: MapIcon },
  { id: 'jobs', label: 'Jobs', icon: ClipboardList },
  { id: 'drivers', label: 'Drivers', icon: UserRound },
  { id: 'partners', label: 'Partners', icon: Building2 },
  { id: 'clients', label: 'Clients', icon: Users },
  { id: 'earnings', label: 'Earnings', icon: Wallet },
];

const FOOTER_ITEM = { id: 'settings', label: 'Settings', icon: Settings };

/**
 * Floating glass rail, the desktop take on the client's floating tab bar:
 * icon over label, with a capsule that slides to the current page.
 */
export function Sidebar({ currentView, setCurrentView }) {
  const { register, box } = useSlidingIndicator(currentView);

  const renderItem = ({ id, label, icon: Icon }) => {
    const active = currentView === id;
    return (
      <a
        key={id}
        ref={register(id)}
        href={`#${id}`}
        onClick={(e) => {
          e.preventDefault();
          setCurrentView(id);
        }}
        aria-current={active ? 'page' : undefined}
        className={`relative flex flex-col items-center gap-[3px] py-2.5 rounded-[30px] no-underline transition-colors duration-200 ${
          active ? 'text-white' : 'text-white/60 hover:text-white/90'
        }`}
      >
        <Icon size={22} strokeWidth={2} className={`transition-colors duration-200 ${active ? 'text-accent' : ''}`} />
        <span className="text-[11px] font-semibold leading-tight">{label}</span>
      </a>
    );
  };

  return (
    <aside className="glass fixed left-3 top-3 bottom-3 z-[100] w-rail flex flex-col items-center py-5 rounded-[36px]">
      <img src="/logo_white.png" alt="Carpital" className="w-[60px] mb-5 select-none" draggable={false} />

      <nav className="relative flex-1 min-h-0 w-full px-1.5 flex flex-col gap-1 overflow-y-auto scrollbar-none">
        {box && (
          <span
            aria-hidden
            className="absolute rounded-[30px] bg-white/12 transition-[top,height] duration-300 ease-out-cubic"
            style={{ top: box.top, left: box.left, width: box.width, height: box.height }}
          />
        )}
        {NAV_ITEMS.map(renderItem)}
        <div className="flex-1 min-h-3" />
        {renderItem(FOOTER_ITEM)}
      </nav>

      <Avatar name="Ops Admin" size={42} glass className="mt-3" title="Ops Admin · Fleet Manager" />
    </aside>
  );
}
