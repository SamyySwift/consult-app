import React, { useState, useMemo } from 'react';
import { useAppContext } from '../context/AppContext';

export function ClientsView() {
  const { jobs, setSelectedJobId } = useAppContext();
  const [search, setSearch] = useState('');
  const [expandedClient, setExpandedClient] = useState(null);

  // Build unique clients from jobs data
  const clients = useMemo(() => {
    const clientMap = new Map();

    jobs.forEach(job => {
      const key = job.customerId || job.customerName;
      if (!key) return;

      if (!clientMap.has(key)) {
        clientMap.set(key, {
          id: key,
          name: job.customerName || '—',
          phone: job.customerPhone || '—',
          totalBookings: 0,
          totalSpent: 0,
          lastBookingDate: null,
          lastBookingDateRaw: null,
          jobs: [],
          hasActiveJob: false,
        });
      }

      const client = clientMap.get(key);
      client.totalBookings += 1;
      if (job.status !== 'cancelled') {
        client.totalSpent += job.totalAmount || 0;
      }
      if (!client.lastBookingDateRaw || new Date(job.createdAtRaw) > new Date(client.lastBookingDateRaw)) {
        client.lastBookingDate = job.createdAt;
        client.lastBookingDateRaw = job.createdAtRaw;
      }
      if (['assigned', 'confirmed', 'inTransit', 'pickedUp'].includes(job.status)) {
        client.hasActiveJob = true;
      }
      client.jobs.push(job);
    });

    return Array.from(clientMap.values()).sort((a, b) => b.totalSpent - a.totalSpent);
  }, [jobs]);

  const filtered = useMemo(() => {
    const q = search.toLowerCase();
    return clients.filter(c =>
      !q || c.name.toLowerCase().includes(q) || c.phone.toLowerCase().includes(q)
    );
  }, [clients, search]);

  const totalRevenue = clients.reduce((s, c) => s + c.totalSpent, 0);
  const activeClients = clients.filter(c => c.hasActiveJob).length;

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
  const STATUS_LABELS = {
    pending: 'Pending', assigned: 'Assigned', confirmed: 'Confirmed',
    pickedUp: 'Picked Up', inTransit: 'In Transit', completed: 'Delivered',
    delivered: 'Delivered', cancelled: 'Cancelled',
  };

  return (
    <div className="flex flex-col flex-1 p-8 gap-6 overflow-hidden">
      {/* Header */}
      <div className="flex items-center justify-between shrink-0">
        <div>
          <h2 className="font-syne text-[18px] font-bold text-text-primary tracking-tight">
            Client Management
          </h2>
          <p className="text-[12px] text-text-dim mt-0.5">{clients.length} unique clients</p>
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

      {/* KPIs */}
      <div className="grid grid-cols-3 gap-3 shrink-0">
        {[
          { label: 'Total Clients', value: clients.length, display: clients.length, color: 'text-text-primary', sub: 'unique customers' },
          { label: 'Active Now', value: activeClients, display: activeClients, color: 'text-amber', sub: 'with ongoing bookings' },
          { label: 'Total Revenue', value: totalRevenue, display: `₦${totalRevenue.toLocaleString('en-NG')}`, color: 'text-success', sub: 'from all clients' },
        ].map(kpi => (
          <div key={kpi.label} className="bg-navy-mid border border-navy-border rounded-xl p-5 flex flex-col gap-1">
            <div className="text-[11px] text-text-mid uppercase tracking-[0.06em] font-medium">{kpi.label}</div>
            <div className={`font-syne font-extrabold text-[32px] leading-none tracking-tight ${kpi.color}`}>{kpi.display}</div>
            <div className="text-[11px] text-text-dim font-mono">{kpi.sub}</div>
          </div>
        ))}
      </div>

      {/* Client Table */}
      <div className="flex-1 overflow-auto rounded-xl border border-navy-border bg-navy-mid min-h-0">
        <table className="w-full text-left border-collapse">
          <thead className="sticky top-0 z-10 bg-navy-light border-b border-navy-border">
            <tr className="text-[11px] uppercase tracking-[0.05em] text-text-mid">
              <th className="px-4 py-3 font-medium">Client</th>
              <th className="px-4 py-3 font-medium">Phone</th>
              <th className="px-4 py-3 font-medium">Bookings</th>
              <th className="px-4 py-3 font-medium">Total Spent</th>
              <th className="px-4 py-3 font-medium">Last Booking</th>
              <th className="px-4 py-3 font-medium">Status</th>
              <th className="px-4 py-3 font-medium w-10"></th>
            </tr>
          </thead>
          <tbody>
            {filtered.length === 0 ? (
              <tr>
                <td colSpan={7} className="text-center py-16 text-text-dim text-[13px]">
                  {search ? 'No clients match your search.' : 'No clients found.'}
                </td>
              </tr>
            ) : (
              filtered.map(client => (
                <React.Fragment key={client.id}>
                  <tr
                    className="border-b border-navy-border hover:bg-navy/60 transition-colors cursor-pointer"
                    onClick={() => setExpandedClient(expandedClient === client.id ? null : client.id)}
                  >
                    <td className="px-4 py-3.5">
                      <div className="flex items-center gap-3">
                        <div className="w-8 h-8 rounded-full bg-navy-light border border-navy-border flex items-center justify-center text-[13px] font-bold text-text-mid shrink-0">
                          {client.name.charAt(0).toUpperCase()}
                        </div>
                        <span className="text-[13px] font-medium text-text-primary">{client.name}</span>
                      </div>
                    </td>
                    <td className="px-4 py-3.5 font-mono text-[12px] text-text-mid">{client.phone}</td>
                    <td className="px-4 py-3.5">
                      <span className="font-syne font-bold text-[20px] text-text-primary">{client.totalBookings}</span>
                    </td>
                    <td className="px-4 py-3.5 font-mono text-[13px] text-amber font-medium">
                      ₦{client.totalSpent.toLocaleString('en-NG')}
                    </td>
                    <td className="px-4 py-3.5 text-[12px] text-text-dim">{client.lastBookingDate || '—'}</td>
                    <td className="px-4 py-3.5">
                      {client.hasActiveJob ? (
                        <span className="text-[11px] font-semibold px-2.5 py-1 rounded-full uppercase tracking-[0.05em] bg-amber-glow text-amber flex items-center gap-1.5 w-fit">
                          <span className="w-1.5 h-1.5 rounded-full bg-current animate-pulse"></span>
                          Active
                        </span>
                      ) : (
                        <span className="text-[11px] font-semibold px-2.5 py-1 rounded-full uppercase tracking-[0.05em] bg-navy-light text-text-dim w-fit">
                          Inactive
                        </span>
                      )}
                    </td>
                    <td className="px-4 py-3.5">
                      <svg
                        viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"
                        className={`w-4 h-4 text-text-dim transition-transform duration-200 ${expandedClient === client.id ? 'rotate-90' : ''}`}
                      >
                        <path d="m9 18 6-6-6-6"/>
                      </svg>
                    </td>
                  </tr>

                  {/* Expanded job history */}
                  {expandedClient === client.id && (
                    <tr className="border-b border-navy-border bg-navy/40">
                      <td colSpan={7} className="px-4 py-3">
                        <div className="text-[11px] text-text-mid uppercase tracking-[0.05em] font-medium mb-2">
                          Booking History ({client.jobs.length})
                        </div>
                        <div className="flex flex-col gap-1.5">
                          {client.jobs.map(job => (
                            <div
                              key={job.id}
                              className="flex items-center gap-4 bg-navy-mid border border-navy-border rounded-lg px-3 py-2.5 cursor-pointer hover:border-navy-light transition-colors"
                              onClick={(e) => { e.stopPropagation(); setSelectedJobId(job.id); }}
                            >
                              <span className="font-mono text-[11px] text-text-dim">{job.id}</span>
                              <span className="text-[12px] text-text-mid flex-1 truncate">{job.pickup?.address} → {job.dropoff?.address}</span>
                              <span className={`text-[10px] font-semibold px-2 py-0.5 rounded-full uppercase ${STATUS_COLORS[job.status] || 'bg-navy-light text-text-dim'}`}>
                                {STATUS_LABELS[job.status] || job.status}
                              </span>
                              <span className="font-mono text-[12px] text-amber">₦{(job.totalAmount || 0).toLocaleString('en-NG')}</span>
                              <span className="text-[11px] text-text-dim shrink-0">{job.createdAt}</span>
                            </div>
                          ))}
                        </div>
                      </td>
                    </tr>
                  )}
                </React.Fragment>
              ))
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}
