import React from 'react';
import { useAppContext } from '../context/AppContext';

const STATUS_LABELS = {
  pending:   'Pending',
  assigned:  'Assigned',
  confirmed: 'Confirmed',
  pickedUp:  'Picked Up',
  inTransit: 'In Transit',
  completed: 'Delivered',
  delivered: 'Delivered',
  cancelled: 'Cancelled',
};

const VehicleIcon = ({ type }) => {
  const normalized = (type || 'sedan').toLowerCase();
  
  if (normalized === 'suv') {
    return <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" className="w-[18px] h-[18px]"><path d="M5 17H3a2 2 0 0 1-2-2V9a2 2 0 0 1 2-2h1l2-3h9l2 3h1a2 2 0 0 1 2 2v6a2 2 0 0 1-2 2h-2"/><circle cx="7.5" cy="17.5" r="2.5"/><circle cx="16.5" cy="17.5" r="2.5"/></svg>;
  }
  if (normalized === 'truck') {
    return <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" className="w-[18px] h-[18px]"><rect x="1" y="3" width="15" height="13" rx="1"/><path d="M16 8h4l3 4v5h-7V8z"/><circle cx="5.5" cy="18.5" r="2.5"/><circle cx="18.5" cy="18.5" r="2.5"/></svg>;
  }
  if (normalized === 'van') {
    return <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" className="w-[18px] h-[18px]"><path d="M3 17H1V9a2 2 0 0 1 2-2h14v10H8M3 17h5M16 17h5v-6l-3-4H16v10z"/><circle cx="5.5" cy="17.5" r="2.5"/><circle cx="18.5" cy="17.5" r="2.5"/></svg>;
  }
  if (normalized === 'motorcycle') {
    return <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" className="w-[18px] h-[18px]"><circle cx="5.5" cy="17.5" r="3.5"/><circle cx="18.5" cy="17.5" r="3.5"/><path d="M15 6h3l2 5M5.5 14L9 8l4 3h5"/></svg>;
  }
  return <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" className="w-[18px] h-[18px]"><path d="M5 17H3a2 2 0 0 1-2-2V9a2 2 0 0 1 2-2h1l3-4h7l3 4h1a2 2 0 0 1 2 2v6a2 2 0 0 1-2 2h-2"/><circle cx="7.5" cy="17.5" r="2.5"/><circle cx="16.5" cy="17.5" r="2.5"/></svg>;
};

export function JobCard({ job, index }) {
  const { setSelectedJobId } = useAppContext();
  
  const statusColors = {
    assigned:  'bg-warning-bg text-warning',
    confirmed: 'bg-info-bg text-info',
    pickedUp:  'bg-info-bg text-info',
    inTransit: 'bg-amber-glow text-amber',
    completed: 'bg-success-bg text-success',
    cancelled: 'bg-error-bg text-accent-red',
    pending:   'bg-navy-light text-text-mid'
  };

  const statusColorClass = statusColors[job.status] || statusColors.pending;

  return (
    <div 
      className={`bg-navy-mid border border-navy-border rounded-xl p-5 cursor-pointer relative overflow-hidden transition-all duration-200 animate-card-enter hover:-translate-y-[3px] hover:shadow-[0_12px_40px_rgba(0,0,0,0.4)] hover:border-navy-light ${job.status === 'inTransit' ? 'in-transit-before' : ''}`}
      style={{ animationDelay: `${index * 40}ms` }}
      onClick={() => setSelectedJobId(job.id)}
      role="button"
      tabIndex="0"
      onKeyDown={(e) => {
        if (e.key === 'Enter' || e.key === ' ') {
          e.preventDefault();
          setSelectedJobId(job.id);
        }
      }}
    >
      <div className="flex items-start justify-between mb-4">
        <span className="font-mono text-xs font-medium text-text-mid bg-navy-light px-2 py-1 rounded tracking-[0.04em]">
          {job.id}
        </span>
        <span className={`flex items-center gap-1.5 text-[11px] font-semibold px-2.5 py-1 rounded-full uppercase tracking-[0.05em] ${statusColorClass}`}>
          <span className={`w-1.5 h-1.5 rounded-full bg-current ${job.status === 'inTransit' ? 'animate-pulse-dot-fast' : ''}`}></span>
          {STATUS_LABELS[job.status] || job.status}
        </span>
      </div>

      <div className="flex items-center gap-2.5 mb-3.5">
        <div className="w-9 h-9 bg-navy-light rounded-lg flex items-center justify-center text-text-mid shrink-0">
          <VehicleIcon type={job.vehicle.type} />
        </div>
        <div>
          <div className="text-[14px] font-semibold text-text-primary leading-[1.2]">
            {job.vehicle.year} {job.vehicle.make} {job.vehicle.model}
          </div>
          <div className="text-[11px] text-text-mid font-mono mt-0.5">
            {job.vehicle.color} · {job.serviceType}
          </div>
        </div>
      </div>

      <div className="flex flex-col gap-1.5 p-3 bg-navy rounded-lg mb-3.5">
        <div className="flex items-center gap-2 text-xs">
          <span className="w-2 h-2 rounded-full shrink-0 bg-success"></span>
          <span className="text-text-mid leading-[1.3] truncate" title={job.pickup.address}>{job.pickup.address}</span>
        </div>
        <div className="w-[1px] h-[10px] bg-navy-border ml-[3.5px]"></div>
        <div className="flex items-center gap-2 text-xs">
          <span className="w-2 h-2 rounded-full shrink-0 bg-accent-red"></span>
          <span className="text-text-mid leading-[1.3] truncate" title={job.dropoff.address}>{job.dropoff.address}</span>
        </div>
      </div>

      <div className="flex items-center justify-between">
        <div className="text-xs text-text-mid">
          <strong className="text-text-primary font-medium">{job.customerName}</strong><br/>
          <span className="text-[11px] text-text-dim">{job.driverName}</span>
        </div>
        <div className="font-mono text-[13px] font-medium text-amber">
          ₦{(job.totalAmount || 0).toLocaleString('en-NG')}
        </div>
      </div>

      <div className="flex gap-1 mt-2.5">
        <span className="text-[10px] px-1.5 py-0.5 rounded-[3px] bg-navy text-text-dim border border-navy-border font-mono">
          {job.transportMode === 'Enclosed Transport' ? 'Enclosed' : 'Open'}
        </span>
        {job.hasInsurance && (
          <span className="text-[10px] px-1.5 py-0.5 rounded-[3px] bg-success-bg text-success border border-success/20 font-mono">
            Insured
          </span>
        )}
      </div>
    </div>
  );
}
