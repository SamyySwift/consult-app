import React from 'react';

export function Sidebar({ currentView, setCurrentView }) {
  const navItems = [
    {
      id: 'dispatch',
      label: 'Dispatch',
      icon: <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8"><rect x="2" y="3" width="20" height="14" rx="2"/><path d="M8 21h8M12 17v4"/></svg>
    },
    {
      id: 'jobs',
      label: 'Jobs',
      icon: <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8"><path d="M9 5H7a2 2 0 0 0-2 2v12a2 2 0 0 0 2 2h10a2 2 0 0 0 2-2V7a2 2 0 0 0-2-2h-2"/><rect x="9" y="3" width="6" height="4" rx="1"/><path d="M9 12h6M9 16h4"/></svg>
    },
    {
      id: 'drivers',
      label: 'Drivers',
      icon: <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8"><circle cx="12" cy="8" r="4"/><path d="M4 20c0-4 3.6-7 8-7s8 3 8 7"/></svg>
    },
    {
      id: 'clients',
      label: 'Clients',
      icon: <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 0 0-3-3.87M16 3.13a4 4 0 0 1 0 7.75"/></svg>
    },
    {
      id: 'earnings',
      label: 'Earnings',
      icon: <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8"><path d="M12 2v20M17 5H9.5a3.5 3.5 0 0 0 0 7h5a3.5 3.5 0 0 1 0 7H6"/></svg>
    }
  ];

  const footerItem = {
    id: 'settings',
    label: 'Settings',
    icon: <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8"><circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 0 1 0 2.83 2 2 0 0 1-2.83 0l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-4 0v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 0 1-2.83-2.83l.06-.06A1.65 1.65 0 0 0 4.68 15a1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1 0-4h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 0 1 2.83-2.83l.06.06A1.65 1.65 0 0 0 9 4.68a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 4 0v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 0 1 2.83 2.83l-.06.06A1.65 1.65 0 0 0 19.4 9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 0 4h-.09a1.65 1.65 0 0 0-1.51 1z"/></svg>
  };

  return (
    <aside className="fixed top-0 left-0 flex flex-col bg-navy-mid border-r border-navy-border w-sidebar-w h-screen overflow-hidden transition-[width] duration-300 z-[100] group hover:w-sidebar-expanded-w">
      <div className="flex items-center gap-3 px-[18px] py-5 h-topbar-h border-b border-navy-border overflow-hidden whitespace-nowrap">
        <span className="shrink-0 w-7 h-7 bg-accent-red text-white rounded-md flex items-center justify-center font-syne font-extrabold text-base tracking-tighter">
          C
        </span>
        <span className="font-syne font-bold text-lg tracking-tight text-text-primary opacity-0 -translate-x-2 transition-all duration-300 group-hover:opacity-100 group-hover:translate-x-0">
          Consult
        </span>
      </div>

      <nav className="flex-1 flex flex-col gap-0.5 px-2 py-3 overflow-hidden">
        {navItems.map(item => (
          <a
            key={item.id}
            href={`#${item.id}`}
            onClick={(e) => { e.preventDefault(); setCurrentView(item.id); }}
            className={`relative flex items-center gap-3 p-2.5 rounded-lg text-text-mid no-underline cursor-pointer whitespace-nowrap transition-all duration-300 hover:bg-navy-light hover:text-text-primary ${
              currentView === item.id ? 'bg-error-bg !text-accent-red' : ''
            }`}
            title={item.label}
          >
            {currentView === item.id && (
              <div className="absolute left-0 top-[20%] h-[60%] w-0.5 bg-accent-red rounded-r-sm"></div>
            )}
            <div className="shrink-0 w-5 h-5 transition-colors duration-300 [&>svg]:w-5 [&>svg]:h-5">
              {item.icon}
            </div>
            <span className="text-[13px] font-medium opacity-0 -translate-x-2 transition-all duration-300 group-hover:opacity-100 group-hover:translate-x-0">
              {item.label}
            </span>
          </a>
        ))}
      </nav>

      <div className="flex flex-col gap-1 px-2 py-3 border-t border-navy-border overflow-hidden">
        <a
          href={`#${footerItem.id}`}
          onClick={(e) => { e.preventDefault(); setCurrentView(footerItem.id); }}
          className={`relative flex items-center gap-3 p-2.5 rounded-lg text-text-mid no-underline cursor-pointer whitespace-nowrap transition-all duration-300 hover:bg-navy-light hover:text-text-primary ${
            currentView === footerItem.id ? 'bg-error-bg text-accent-red' : ''
          }`}
          title={footerItem.label}
        >
          {currentView === footerItem.id && (
            <div className="absolute left-0 top-[20%] h-[60%] w-0.5 bg-accent-red rounded-r-sm"></div>
          )}
          <div className="shrink-0 w-5 h-5 transition-colors duration-300 [&>svg]:w-5 [&>svg]:h-5">
            {footerItem.icon}
          </div>
          <span className="text-[13px] font-medium opacity-0 -translate-x-2 transition-all duration-300 group-hover:opacity-100 group-hover:translate-x-0">
            {footerItem.label}
          </span>
        </a>
        <div className="flex items-center gap-2.5 px-2.5 py-2 rounded-lg overflow-hidden">
          <div className="shrink-0 w-8 h-8 rounded-full bg-gradient-to-br from-navy-light to-amber flex items-center justify-center text-[11px] font-semibold font-mono text-text-primary">
            OA
          </div>
          <div className="flex flex-col opacity-0 -translate-x-2 transition-all duration-300 group-hover:opacity-100 group-hover:translate-x-0">
            <span className="text-xs font-semibold text-text-primary">Ops Admin</span>
            <span className="text-[11px] text-text-mid">Fleet Manager</span>
          </div>
        </div>
      </div>
    </aside>
  );
}
