import React from 'react';
import { Bell, Plus } from 'lucide-react';
import { useAppContext } from '../context/AppContext';
import { Button, GlassIconButton } from './ui';

/** Page header in the client's tab-page style: large title left, glass controls right. */
export function Topbar({ title, section }) {
  const { liveStatus } = useAppContext();
  const live = liveStatus === 'live';

  return (
    <header className="flex flex-wrap items-end justify-between gap-4 px-8 pt-7 pb-5 shrink-0">
      <div className="min-w-0">
        <p className="text-[13px] tracking-[0.2px] text-white/70">{section}</p>
        <h1 className="text-[30px] font-extrabold leading-tight tracking-[-0.6px] text-white">{title}</h1>
      </div>

      <div className="flex items-center gap-2.5">
        <span className="glass relative inline-flex items-center gap-2 h-11 px-4 rounded-full text-[13px] font-semibold text-white">
          <span
            className={`size-2 rounded-full animate-pulse-dot ${
              live ? 'bg-accent shadow-[0_0_8px_rgb(0_200_83/0.7)]' : 'bg-warning'
            }`}
          />
          {live ? 'Live' : 'Connecting'}
        </span>
        <GlassIconButton icon={Bell} label="Notifications" />
        <Button id="btn-new-job" icon={Plus}>
          New Job
        </Button>
      </div>
    </header>
  );
}
