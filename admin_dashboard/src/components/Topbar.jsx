import React from 'react';
import { useAppContext } from '../context/AppContext';

export function Topbar({ title, breadcrumb }) {
  const { liveStatus } = useAppContext();

  return (
    <header className="flex items-center justify-between px-8 h-topbar-h bg-navy border-b border-navy-border sticky top-0 z-50 shrink-0">
      <div className="flex items-center gap-5">
        <div className="flex items-center gap-2 text-[13px]">
          <span className="text-text-mid">{breadcrumb}</span>
          <span className="text-text-dim">/</span>
          <span className="text-text-primary font-medium">{title}</span>
        </div>
        <div className="flex items-center gap-1.5 text-[11px] font-mono text-success bg-success-bg px-2.5 py-1 rounded-full border border-success/20">
          <span className={`w-1.5 h-1.5 rounded-full ${liveStatus === 'live' ? 'bg-success animate-pulse-dot' : 'bg-warning animate-pulse'}`}></span>
          <span>{liveStatus === 'live' ? 'Live' : 'Connecting'}</span>
        </div>
      </div>
      
      <div className="flex items-center gap-4">
        <button 
          id="btn-new-job"
          className="flex items-center gap-1.5 px-4 py-2 bg-accent-red text-white border-none rounded-lg text-[13px] font-semibold cursor-pointer font-sans transition-all hover:bg-accent-red-dark hover:-translate-y-[1px] hover:shadow-[0_4px_16px_rgba(239,58,71,0.35)] active:translate-y-0"
        >
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" className="w-[14px] h-[14px]"><path d="M12 5v14M5 12h14"/></svg>
          New Job
        </button>
        <div className="relative w-9 h-9 flex items-center justify-center text-text-mid cursor-pointer rounded-lg transition-colors hover:bg-navy-light hover:text-text-primary">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" className="w-[18px] h-[18px]"><path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9"/><path d="M13.73 21a2 2 0 0 1-3.46 0"/></svg>
          <span className="absolute top-1 right-1 w-4 h-4 bg-accent-red text-white text-[9px] font-bold rounded-full flex items-center justify-center">
            3
          </span>
        </div>
      </div>
    </header>
  );
}
