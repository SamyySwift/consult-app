import React, { useState, useMemo } from 'react';
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

const STATUS_COLORS = {
  pending:   'bg-navy-light text-text-mid',
  assigned:  'bg-warning-bg text-warning',
  confirmed: 'bg-info-bg text-info',
  pickedUp:  'bg-info-bg text-info',
  inTransit: 'bg-amber-glow text-amber',
  completed: 'bg-success-bg text-success',
  delivered: 'bg-success-bg text-success',
  cancelled: 'bg-error-bg text-accent-red',
};

const FILTERS = [
  { id: 'all',       label: 'All' },
  { id: 'pending',   label: 'Pending' },
  { id: 'assigned',  label: 'Assigned' },
  { id: 'confirmed', label: 'Confirmed' },
  { id: 'inTransit', label: 'In Transit' },
  { id: 'completed', label: 'Delivered' },
  { id: 'cancelled', label: 'Cancelled' },
];

const SortIcon = ({ direction }) => (
  <svg viewBox="0 0 16 16" className="w-3 h-3 inline ml-1 opacity-60" fill="currentColor">
    {direction === 'asc'
      ? <path d="M8 3l4 6H4l4-6z" />
      : direction === 'desc'
      ? <path d="M8 13l-4-6h8l-4 6z" />
      : <><path d="M8 2l3 5H5L8 2z" opacity="0.4"/><path d="M8 14l-3-5h6l-3 5z" opacity="0.4"/></>
    }
  </svg>
);

export function JobsView() {
  const { jobs, setSelectedJobId } = useAppContext();
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState('all');
  const [sort, setSort] = useState({ key: 'createdAtRaw', dir: 'desc' });

  const handleSort = (key) => {
    setSort(prev => prev.key === key
      ? { key, dir: prev.dir === 'asc' ? 'desc' : 'asc' }
      : { key, dir: 'asc' }
    );
  };

  const filtered = useMemo(() => {
    const q = search.toLowerCase();
    return jobs
      .filter(j => statusFilter === 'all' || j.status === statusFilter)
      .filter(j => !q || [
        j.id, j.customerName, j.driverName,
        j.pickup?.address, j.dropoff?.address,
        j.vehicle?.make, j.vehicle?.model,
      ].some(f => f?.toLowerCase().includes(q)))
      .slice()
      .sort((a, b) => {
        let av = a[sort.key] ?? '';
        let bv = b[sort.key] ?? '';
        if (sort.key === 'totalAmount') { av = Number(av); bv = Number(bv); }
        else if (sort.key === 'createdAtRaw') { av = new Date(av).getTime() || 0; bv = new Date(bv).getTime() || 0; }
        else { av = String(av).toLowerCase(); bv = String(bv).toLowerCase(); }
        if (av < bv) return sort.dir === 'asc' ? -1 : 1;
        if (av > bv) return sort.dir === 'asc' ? 1 : -1;
        return 0;
      });
  }, [jobs, search, statusFilter, sort]);

  const counts = useMemo(() => {
    const c = {};
    FILTERS.forEach(f => {
      c[f.id] = f.id === 'all' ? jobs.length : jobs.filter(j => j.status === f.id).length;
    });
    return c;
  }, [jobs]);

  const Th = ({ label, sortKey }) => (
    <th
      className={`px-4 py-3 text-left text-[11px] font-medium uppercase tracking-[0.05em] text-text-mid select-none whitespace-nowrap ${sortKey ? 'cursor-pointer hover:text-text-primary transition-colors' : ''}`}
      onClick={sortKey ? () => handleSort(sortKey) : undefined}
    >
      {label}
      {sortKey && <SortIcon direction={sort.key === sortKey ? sort.dir : null} />}
    </th>
  );

  return (
    <div className="flex flex-col flex-1 p-8 gap-6 overflow-hidden">
      {/* Header */}
      <div className="flex items-center justify-between shrink-0">
        <div>
          <h2 className="font-syne text-[18px] font-bold text-text-primary tracking-tight">
            Master Transport Log
          </h2>
          <p className="text-[12px] text-text-dim mt-0.5">{filtered.length} of {jobs.length} bookings</p>
        </div>
        {/* Search */}
        <div className="relative">
          <svg className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-text-dim" fill="none" stroke="currentColor" strokeWidth="2" viewBox="0 0 24 24">
            <circle cx="11" cy="11" r="8"/><path d="m21 21-4.35-4.35"/>
          </svg>
          <input
            type="text"
            placeholder="Search jobs, customers, drivers…"
            value={search}
            onChange={e => setSearch(e.target.value)}
            className="w-72 pl-9 pr-4 py-2 bg-navy-mid border border-navy-border rounded-lg text-[13px] text-text-primary placeholder:text-text-dim focus:outline-none focus:border-info transition-colors"
          />
        </div>
      </div>

      {/* Filter Pills */}
      <div className="flex gap-1.5 flex-wrap shrink-0">
        {FILTERS.map(f => (
          <button
            key={f.id}
            onClick={() => setStatusFilter(f.id)}
            className={`flex items-center gap-1.5 px-3 py-1.5 rounded-full text-[11px] font-semibold border transition-all duration-150 ${
              statusFilter === f.id
                ? 'bg-info text-white border-info'
                : 'bg-navy-mid text-text-mid border-navy-border hover:border-navy-light hover:text-text-primary'
            }`}
          >
            {f.label}
            <span className={`text-[10px] px-1.5 py-0.5 rounded-full font-mono ${statusFilter === f.id ? 'bg-white/20' : 'bg-navy-light'}`}>
              {counts[f.id]}
            </span>
          </button>
        ))}
      </div>

      {/* Table */}
      <div className="flex-1 overflow-auto rounded-xl border border-navy-border bg-navy-mid min-h-0">
        <table className="w-full text-left border-collapse min-w-[900px]">
          <thead className="sticky top-0 z-10 bg-navy-light border-b border-navy-border">
            <tr>
              <Th label="Job ID" sortKey="id" />
              <Th label="Vehicle" sortKey="vehicle" />
              <Th label="Customer" sortKey="customerName" />
              <Th label="Driver" sortKey="driverName" />
              <Th label="Route" />
              <Th label="Amount" sortKey="totalAmount" />
              <Th label="Status" sortKey="status" />
              <Th label="Created" sortKey="createdAtRaw" />
            </tr>
          </thead>
          <tbody>
            {filtered.length === 0 ? (
              <tr>
                <td colSpan={8} className="text-center py-16 text-text-dim text-[13px]">
                  No jobs match your search or filters.
                </td>
              </tr>
            ) : (
              filtered.map(job => (
                <tr
                  key={job.id}
                  className="border-b border-navy-border last:border-0 hover:bg-navy/60 transition-colors cursor-pointer group"
                  onClick={() => setSelectedJobId(job.id)}
                >
                  <td className="px-4 py-3">
                    <span className="font-mono text-[11px] text-text-mid bg-navy px-2 py-0.5 rounded tracking-wide">
                      {job.id}
                    </span>
                  </td>
                  <td className="px-4 py-3">
                    <div className="text-[13px] font-semibold text-text-primary leading-snug">
                      {job.vehicle.year} {job.vehicle.make} {job.vehicle.model}
                    </div>
                    <div className="text-[11px] text-text-dim font-mono">{job.vehicle.color}</div>
                  </td>
                  <td className="px-4 py-3">
                    <div className="text-[13px] text-text-primary font-medium">{job.customerName}</div>
                    <div className="text-[11px] text-text-dim font-mono">{job.customerPhone}</div>
                  </td>
                  <td className="px-4 py-3 text-[13px] text-text-mid">{job.driverName}</td>
                  <td className="px-4 py-3 max-w-[200px]">
                    <div className="text-[11px] text-text-mid truncate" title={job.pickup?.address}>
                      <span className="w-1.5 h-1.5 rounded-full bg-success inline-block mr-1.5 align-middle"></span>
                      {job.pickup?.address}
                    </div>
                    <div className="text-[11px] text-text-dim truncate mt-0.5" title={job.dropoff?.address}>
                      <span className="w-1.5 h-1.5 rounded-full bg-accent-red inline-block mr-1.5 align-middle"></span>
                      {job.dropoff?.address}
                    </div>
                  </td>
                  <td className="px-4 py-3 font-mono text-[13px] text-amber font-medium whitespace-nowrap">
                    ₦{(job.totalAmount || 0).toLocaleString('en-NG')}
                  </td>
                  <td className="px-4 py-3">
                    <span className={`text-[11px] font-semibold px-2.5 py-1 rounded-full uppercase tracking-[0.05em] ${STATUS_COLORS[job.status] || STATUS_COLORS.pending}`}>
                      {STATUS_LABELS[job.status] || job.status}
                    </span>
                  </td>
                  <td className="px-4 py-3 text-[12px] text-text-dim whitespace-nowrap">{job.createdAt}</td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}
