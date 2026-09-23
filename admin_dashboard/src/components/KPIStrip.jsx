import React, { useEffect, useState, useRef } from 'react';
import { useAppContext } from '../context/AppContext';

function AnimatedNumber({ value, isRevenue = false }) {
  const [displayValue, setDisplayValue] = useState(0);
  const prevValue = useRef(0);

  useEffect(() => {
    const startValue = prevValue.current;
    const endValue = value;
    const duration = 800;
    const startTime = performance.now();

    let animationFrameId;

    const tick = (now) => {
      const elapsed = now - startTime;
      const progress = Math.min(elapsed / duration, 1);
      const ease = 1 - Math.pow(1 - progress, 3);
      const current = Math.round(startValue + (endValue - startValue) * ease);
      
      setDisplayValue(current);

      if (progress < 1) {
        animationFrameId = requestAnimationFrame(tick);
      } else {
        prevValue.current = endValue;
      }
    };

    animationFrameId = requestAnimationFrame(tick);

    return () => {
      if (animationFrameId) cancelAnimationFrame(animationFrameId);
    };
  }, [value]);

  if (isRevenue) {
    return <>₦{displayValue.toLocaleString('en-NG')}</>;
  }
  return <>{displayValue}</>;
}

export function KPIStrip() {
  const { jobs } = useAppContext();

  const total = jobs.length;
  const active = jobs.filter(j => ['inTransit', 'pickedUp', 'confirmed'].includes(j.status)).length;
  const assigned = jobs.filter(j => ['assigned', 'pending'].includes(j.status)).length;
  const delivered = jobs.filter(j => j.status === 'completed').length;
  const revenue = jobs
    .filter(j => j.status !== 'cancelled')
    .reduce((sum, j) => sum + (j.totalAmount || 0), 0);

  return (
    <section className="grid grid-cols-5 gap-[1px] bg-navy-border border-b border-navy-border shrink-0">
      <div className="bg-navy p-6 flex flex-col gap-1.5 cursor-pointer transition-colors duration-200 hover:bg-navy-mid animate-kpi-enter">
        <div className="text-[11px] font-medium text-text-mid uppercase tracking-[0.06em]">Total Jobs</div>
        <div className="font-syne font-extrabold text-[36px] leading-none text-text-primary tracking-tight">
          <AnimatedNumber value={total} />
        </div>
        <div className="text-[11px] font-mono text-success">+12% this week</div>
      </div>
      
      <div className="bg-navy-mid p-6 flex flex-col gap-1.5 cursor-pointer transition-colors duration-200 relative overflow-hidden animate-kpi-enter shimmer-line-before">
        <div className="text-[11px] font-medium text-text-mid uppercase tracking-[0.06em]">Active</div>
        <div className="font-syne font-extrabold text-[36px] leading-none text-amber tracking-tight">
          <AnimatedNumber value={active} />
        </div>
        <div className="text-[11px] font-mono text-text-dim">In transit now</div>
      </div>

      <div className="bg-navy p-6 flex flex-col gap-1.5 cursor-pointer transition-colors duration-200 hover:bg-navy-mid animate-kpi-enter">
        <div className="text-[11px] font-medium text-text-mid uppercase tracking-[0.06em]">Awaiting Confirmation</div>
        <div className="font-syne font-extrabold text-[36px] leading-none text-text-primary tracking-tight">
          <AnimatedNumber value={assigned} />
        </div>
        <div className="text-[11px] font-mono text-warning">Needs attention</div>
      </div>

      <div className="bg-navy p-6 flex flex-col gap-1.5 cursor-pointer transition-colors duration-200 hover:bg-navy-mid animate-kpi-enter">
        <div className="text-[11px] font-medium text-text-mid uppercase tracking-[0.06em]">Delivered Today</div>
        <div className="font-syne font-extrabold text-[36px] leading-none text-text-primary tracking-tight">
          <AnimatedNumber value={delivered} />
        </div>
        <div className="text-[11px] font-mono text-success">+3 from yesterday</div>
      </div>

      <div className="bg-navy p-6 flex flex-col gap-1.5 cursor-pointer transition-colors duration-200 hover:bg-navy-mid animate-kpi-enter">
        <div className="text-[11px] font-medium text-text-mid uppercase tracking-[0.06em]">Revenue (Month)</div>
        <div className="font-syne font-extrabold text-[28px] leading-none text-text-primary tracking-tight">
          <AnimatedNumber value={revenue} isRevenue />
        </div>
        <div className="text-[11px] font-mono text-success">+18% vs last month</div>
      </div>
    </section>
  );
}
