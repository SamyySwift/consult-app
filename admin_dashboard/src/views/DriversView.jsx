import React, { useState, useMemo } from 'react';
import { useAppContext } from '../context/AppContext';

export function DriversView() {
  const { jobs, drivers } = useAppContext();
  const [search, setSearch] = useState('');

  // Build enriched driver data by cross-referencing jobs
  const enrichedDrivers = useMemo(() => {
    // Collect all unique drivers — from the drivers list + anyone assigned in jobs
    const driverMap = new Map();

    drivers.forEach(d => {
      driverMap.set(d.id, {
        id: d.id,
        name: d.full_name || '—',
        phone: d.phone || '—',
        activeJobs: 0,
        completedJobs: 0,
        totalEarnings: 0,
        status: 'available',
      });
    });

    // Cross-reference with jobs
    jobs.forEach(job => {
      if (!job.driverId) return;
      if (!driverMap.has(job.driverId)) {
        driverMap.set(job.driverId, {
          id: job.driverId,
          name: job.driverName || 'Unknown Driver',
          phone: '—',
          activeJobs: 0,
          completedJobs: 0,
          totalEarnings: 0,
          status: 'available',
        });
      }
      const d = driverMap.get(job.driverId);
      if (['inTransit', 'pickedUp', 'confirmed', 'assigned'].includes(job.status)) {
        d.activeJobs += 1;
        d.status = 'active';
      }
      if (job.status === 'completed') {
        d.completedJobs += 1;
        d.totalEarnings += job.totalAmount || 0;
      }
    });

    return Array.from(driverMap.values());
  }, [jobs, drivers]);

  const filtered = useMemo(() => {
    const q = search.toLowerCase();
    return enrichedDrivers.filter(d =>
      !q || d.name.toLowerCase().includes(q) || d.phone.toLowerCase().includes(q)
    );
  }, [enrichedDrivers, search]);

  const totalActive = enrichedDrivers.filter(d => d.status === 'active').length;
  const totalAvailable = enrichedDrivers.filter(d => d.status === 'available').length;
  const totalEarnings = enrichedDrivers.reduce((s, d) => s + d.totalEarnings, 0);
  const totalCompleted = enrichedDrivers.reduce((s, d) => s + d.completedJobs, 0);

  return (
    <div className="flex flex-col flex-1 p-8 gap-6 overflow-hidden">
      {/* Header */}
      <div className="flex items-center justify-between shrink-0">
        <div>
          <h2 className="font-syne text-[18px] font-bold text-text-primary tracking-tight">
            Driver Management
          </h2>
          <p className="text-[12px] text-text-dim mt-0.5">{enrichedDrivers.length} registered drivers</p>
        </div>
        <div className="relative">
          <svg className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-text-dim" fill="none" stroke="currentColor" strokeWidth="2" viewBox="0 0 24 24">
            <circle cx="11" cy="11" r="8"/><path d="m21 21-4.35-4.35"/>
          </svg>
          <input
            type="text"
            placeholder="Search by name or phone…"
            value={search}
            onChange={e => setSearch(e.target.value)}
            className="w-64 pl-9 pr-4 py-2 bg-navy-mid border border-navy-border rounded-lg text-[13px] text-text-primary placeholder:text-text-dim focus:outline-none focus:border-info transition-colors"
          />
        </div>
      </div>

      {/* Summary KPI row */}
      <div className="grid grid-cols-4 gap-3 shrink-0">
        {[
          { label: 'Total Drivers', value: enrichedDrivers.length, color: 'text-text-primary', sub: 'in roster' },
          { label: 'Currently Active', value: totalActive, color: 'text-amber', sub: 'on a job now' },
          { label: 'Available', value: totalAvailable, color: 'text-success', sub: 'ready to dispatch' },
          { label: 'Jobs Completed', value: totalCompleted, color: 'text-info', sub: `₦${totalEarnings.toLocaleString('en-NG')} earned` },
        ].map(kpi => (
          <div key={kpi.label} className="bg-navy-mid border border-navy-border rounded-xl p-5 flex flex-col gap-1">
            <div className="text-[11px] text-text-mid uppercase tracking-[0.06em] font-medium">{kpi.label}</div>
            <div className={`font-syne font-extrabold text-[32px] leading-none tracking-tight ${kpi.color}`}>{kpi.value}</div>
            <div className="text-[11px] text-text-dim font-mono">{kpi.sub}</div>
          </div>
        ))}
      </div>

      {/* Driver Table */}
      <div className="flex-1 overflow-auto rounded-xl border border-navy-border bg-navy-mid min-h-0">
        <table className="w-full text-left border-collapse">
          <thead className="sticky top-0 z-10 bg-navy-light border-b border-navy-border">
            <tr className="text-[11px] uppercase tracking-[0.05em] text-text-mid">
              <th className="px-4 py-3 font-medium">Driver</th>
              <th className="px-4 py-3 font-medium">Phone</th>
              <th className="px-4 py-3 font-medium">Status</th>
              <th className="px-4 py-3 font-medium">Active Jobs</th>
              <th className="px-4 py-3 font-medium">Completed</th>
              <th className="px-4 py-3 font-medium">Total Earned</th>
            </tr>
          </thead>
          <tbody>
            {filtered.length === 0 ? (
              <tr>
                <td colSpan={6} className="text-center py-16 text-text-dim text-[13px]">
                  {search ? 'No drivers match your search.' : 'No drivers found.'}
                </td>
              </tr>
            ) : (
              filtered.map(driver => (
                <tr key={driver.id} className="border-b border-navy-border last:border-0 hover:bg-navy/60 transition-colors">
                  <td className="px-4 py-3.5">
                    <div className="flex items-center gap-3">
                      <div className="w-8 h-8 rounded-full bg-navy-light border border-navy-border flex items-center justify-center text-[13px] font-bold text-text-mid shrink-0">
                        {driver.name.charAt(0).toUpperCase()}
                      </div>
                      <span className="text-[13px] font-medium text-text-primary">{driver.name}</span>
                    </div>
                  </td>
                  <td className="px-4 py-3.5 font-mono text-[12px] text-text-mid">{driver.phone}</td>
                  <td className="px-4 py-3.5">
                    <span className={`text-[11px] font-semibold px-2.5 py-1 rounded-full uppercase tracking-[0.05em] flex items-center gap-1.5 w-fit ${
                      driver.status === 'active' ? 'bg-amber-glow text-amber' : 'bg-success-bg text-success'
                    }`}>
                      <span className={`w-1.5 h-1.5 rounded-full bg-current ${driver.status === 'active' ? 'animate-pulse' : ''}`}></span>
                      {driver.status === 'active' ? 'On Job' : 'Available'}
                    </span>
                  </td>
                  <td className="px-4 py-3.5">
                    <span className={`font-syne font-bold text-[20px] ${driver.activeJobs > 0 ? 'text-amber' : 'text-text-dim'}`}>
                      {driver.activeJobs}
                    </span>
                  </td>
                  <td className="px-4 py-3.5">
                    <span className="font-syne font-bold text-[20px] text-text-primary">{driver.completedJobs}</span>
                  </td>
                  <td className="px-4 py-3.5 font-mono text-[13px] text-amber font-medium">
                    ₦{driver.totalEarnings.toLocaleString('en-NG')}
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}
