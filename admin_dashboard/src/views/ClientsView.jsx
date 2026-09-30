import React, { useState, useMemo } from 'react';
import { ChevronRight } from 'lucide-react';
import { useAppContext } from '../context/AppContext';
import { formatNaira, shortRef } from '../lib/format';
import { Avatar, Badge, EmptyRow, Eyebrow, SearchField, StatsStrip, StatusBadge, TableCard, Td, Th, Toolbar, Tr } from '../components/ui';

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

  return (
    <div className="flex flex-col flex-1 min-h-0 px-8 pb-8 gap-5 overflow-hidden">
      <Toolbar summary={`${clients.length} unique clients`}>
        <SearchField
          value={search}
          onChange={setSearch}
          placeholder="Search by name or phone…"
          className="w-80"
        />
      </Toolbar>

      <StatsStrip
        items={[
          { label: 'Total clients', value: clients.length },
          { label: 'Active now', value: activeClients, tone: 'text-accent' },
          { label: 'Total revenue', value: formatNaira(totalRevenue) },
        ]}
      />

      <TableCard>
        <thead>
          <tr>
            <Th>Client</Th>
            <Th>Phone</Th>
            <Th>Bookings</Th>
            <Th>Total Spent</Th>
            <Th>Last Booking</Th>
            <Th>Status</Th>
            <Th className="w-10" />
          </tr>
        </thead>
        <tbody>
          {filtered.length === 0 ? (
            <EmptyRow colSpan={7}>{search ? 'No clients match your search.' : 'No clients found.'}</EmptyRow>
          ) : (
            filtered.map(client => {
              const expanded = expandedClient === client.id;
              return (
                <React.Fragment key={client.id}>
                  <Tr
                    onClick={() => setExpandedClient(expanded ? null : client.id)}
                    className={expanded ? 'bg-white/3' : ''}
                  >
                    <Td>
                      <div className="flex items-center gap-3">
                        <Avatar name={client.name} size={34} />
                        <span className="font-semibold text-white">{client.name}</span>
                      </div>
                    </Td>
                    <Td className="text-white/70 tabular-nums">{client.phone}</Td>
                    <Td className="text-[15px] font-bold text-white tabular-nums">{client.totalBookings}</Td>
                    <Td className="font-bold text-white tabular-nums whitespace-nowrap">{formatNaira(client.totalSpent)}</Td>
                    <Td className="text-[12px] text-white/55">{client.lastBookingDate || '—'}</Td>
                    <Td>
                      {client.hasActiveJob ? (
                        <Badge tone="live" compact pulse>Active</Badge>
                      ) : (
                        <Badge compact>Inactive</Badge>
                      )}
                    </Td>
                    <Td>
                      <ChevronRight
                        size={17}
                        className={`text-white/40 transition-transform duration-200 ${expanded ? 'rotate-90' : ''}`}
                      />
                    </Td>
                  </Tr>

                  {/* Expanded job history */}
                  {expanded && (
                    <tr className="border-b border-white/6 bg-white/3">
                      <td colSpan={7} className="px-4 pt-1 pb-4">
                        <Eyebrow className="mb-2.5">Booking History ({client.jobs.length})</Eyebrow>
                        <div className="flex flex-col gap-1.5">
                          {client.jobs.map(job => (
                            <button
                              key={job.id}
                              type="button"
                              className="flex items-center gap-4 w-full text-left rounded-[16px] border border-white/6 bg-surface-variant/60 px-3.5 py-2.5 cursor-pointer transition-colors hover:border-white/15"
                              onClick={(e) => { e.stopPropagation(); setSelectedJobId(job.id); }}
                            >
                              <span className="text-[12px] font-semibold text-white/60 tabular-nums">#{shortRef(job.id)}</span>
                              <span className="flex-1 truncate text-[13px] text-white/85">
                                {job.pickup?.address} → {job.dropoff?.address}
                              </span>
                              <StatusBadge status={job.status} compact />
                              <span className="text-[13px] font-bold text-white tabular-nums">{formatNaira(job.totalAmount)}</span>
                              <span className="shrink-0 text-[12px] text-white/45">{job.createdAt}</span>
                            </button>
                          ))}
                        </div>
                      </td>
                    </tr>
                  )}
                </React.Fragment>
              );
            })
          )}
        </tbody>
      </TableCard>
    </div>
  );
}
