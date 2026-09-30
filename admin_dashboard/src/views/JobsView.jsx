import React, { useState, useMemo } from 'react';
import { useAppContext } from '../context/AppContext';
import { formatNaira, shortRef } from '../lib/format';
import { EmptyRow, Route, SearchField, SegmentedControl, StatusBadge, TableCard, Td, Th, Toolbar, Tr } from '../components/ui';

const FILTERS = [
  { id: 'all',       label: 'All' },
  { id: 'pending',   label: 'Pending' },
  { id: 'assigned',  label: 'Assigned' },
  { id: 'confirmed', label: 'Confirmed' },
  { id: 'inTransit', label: 'In Transit' },
  { id: 'completed', label: 'Delivered' },
  { id: 'cancelled', label: 'Cancelled' },
];

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

  const sortable = (key) => ({
    onSort: () => handleSort(key),
    sorted: sort.key === key ? sort.dir : null,
  });

  return (
    <div className="flex flex-col flex-1 min-h-0 px-8 pb-8 gap-5 overflow-hidden">
      <Toolbar summary={`${filtered.length} of ${jobs.length} bookings`}>
        <SearchField
          value={search}
          onChange={setSearch}
          placeholder="Search jobs, customers, drivers…"
          className="w-80"
        />
      </Toolbar>

      <SegmentedControl
        className="self-start shrink-0"
        value={statusFilter}
        onChange={setStatusFilter}
        options={FILTERS.map(f => ({ value: f.id, label: f.label, count: counts[f.id] }))}
      />

      <TableCard minWidth={960}>
        <thead>
          <tr>
            <Th {...sortable('id')}>Job</Th>
            <Th {...sortable('vehicle')}>Vehicle</Th>
            <Th {...sortable('customerName')}>Customer</Th>
            <Th {...sortable('driverName')}>Driver</Th>
            <Th>Route</Th>
            <Th {...sortable('totalAmount')}>Amount</Th>
            <Th {...sortable('status')}>Status</Th>
            <Th {...sortable('createdAtRaw')}>Created</Th>
          </tr>
        </thead>
        <tbody>
          {filtered.length === 0 ? (
            <EmptyRow colSpan={8}>No jobs match your search or filters.</EmptyRow>
          ) : (
            filtered.map(job => (
              <Tr key={job.id} onClick={() => setSelectedJobId(job.id)}>
                <Td className="text-[12px] font-semibold text-white/70 tabular-nums whitespace-nowrap">
                  #{shortRef(job.id)}
                </Td>
                <Td>
                  <div className="font-semibold text-white leading-snug">
                    {job.vehicle.year} {job.vehicle.make} {job.vehicle.model}
                  </div>
                  <div className="text-[12px] text-white/45">{job.vehicle.color}</div>
                </Td>
                <Td>
                  <div className="font-medium text-white">{job.customerName}</div>
                  <div className="text-[12px] text-white/45 tabular-nums">{job.customerPhone}</div>
                </Td>
                <Td className={job.driverId ? 'text-white/85' : 'text-white/40'}>{job.driverName}</Td>
                <Td className="max-w-[240px]">
                  <Route pickup={job.pickup?.address} dropoff={job.dropoff?.address} compact />
                </Td>
                <Td className="font-bold text-white tabular-nums whitespace-nowrap">
                  {formatNaira(job.totalAmount)}
                </Td>
                <Td>
                  <StatusBadge status={job.status} compact />
                </Td>
                <Td className="text-[12px] text-white/55 whitespace-nowrap">{job.createdAt}</Td>
              </Tr>
            ))
          )}
        </tbody>
      </TableCard>
    </div>
  );
}
