import React, { useState, useMemo } from 'react';
import { useAppContext } from '../context/AppContext';
import { formatNaira } from '../lib/format';
import { Avatar, Badge, EmptyRow, SearchField, StatsStrip, TableCard, Td, Th, Toolbar, Tr } from '../components/ui';

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
        company: d.partner_name || null,
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
          company: null,
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
      !q ||
      d.name.toLowerCase().includes(q) ||
      d.phone.toLowerCase().includes(q) ||
      (d.company || '').toLowerCase().includes(q)
    );
  }, [enrichedDrivers, search]);

  const totalActive = enrichedDrivers.filter(d => d.status === 'active').length;
  const totalAvailable = enrichedDrivers.filter(d => d.status === 'available').length;
  const totalEarnings = enrichedDrivers.reduce((s, d) => s + d.totalEarnings, 0);
  const totalCompleted = enrichedDrivers.reduce((s, d) => s + d.completedJobs, 0);

  return (
    <div className="flex flex-col flex-1 min-h-0 px-8 pb-8 gap-5 overflow-hidden">
      <Toolbar summary={`${enrichedDrivers.length} registered drivers`}>
        <SearchField
          value={search}
          onChange={setSearch}
          placeholder="Search by name, phone or company…"
          className="w-80"
        />
      </Toolbar>

      <StatsStrip
        items={[
          { label: 'Total drivers', value: enrichedDrivers.length },
          { label: 'Currently active', value: totalActive, tone: 'text-accent' },
          { label: 'Available', value: totalAvailable },
          { label: 'Jobs completed', value: totalCompleted },
          { label: 'Earned', value: formatNaira(totalEarnings) },
        ]}
      />

      <TableCard>
        <thead>
          <tr>
            <Th>Driver</Th>
            <Th>Phone</Th>
            <Th>Company</Th>
            <Th>Status</Th>
            <Th>Active Jobs</Th>
            <Th>Completed</Th>
            <Th>Total Earned</Th>
          </tr>
        </thead>
        <tbody>
          {filtered.length === 0 ? (
            <EmptyRow colSpan={7}>{search ? 'No drivers match your search.' : 'No drivers found.'}</EmptyRow>
          ) : (
            filtered.map(driver => (
              <Tr key={driver.id}>
                <Td>
                  <div className="flex items-center gap-3">
                    <Avatar name={driver.name} size={34} />
                    <span className="font-semibold text-white">{driver.name}</span>
                  </div>
                </Td>
                <Td className="text-white/70 tabular-nums">{driver.phone}</Td>
                <Td className="text-white/85">
                  {driver.company || <span className="text-white/40">Not set</span>}
                </Td>
                <Td>
                  {driver.status === 'active' ? (
                    <Badge tone="live" compact pulse>On Job</Badge>
                  ) : (
                    <Badge compact>Available</Badge>
                  )}
                </Td>
                <Td className={`text-[15px] font-bold tabular-nums ${driver.activeJobs > 0 ? 'text-accent' : 'text-white/35'}`}>
                  {driver.activeJobs}
                </Td>
                <Td className="text-[15px] font-bold text-white tabular-nums">{driver.completedJobs}</Td>
                <Td className="font-bold text-white tabular-nums whitespace-nowrap">
                  {formatNaira(driver.totalEarnings)}
                </Td>
              </Tr>
            ))
          )}
        </tbody>
      </TableCard>
    </div>
  );
}
