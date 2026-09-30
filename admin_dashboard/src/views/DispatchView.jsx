import React from 'react';
import { Banknote, CircleCheck, ClipboardList, Clock, Inbox, Truck } from 'lucide-react';
import { useAppContext } from '../context/AppContext';
import { JobCard } from '../components/JobCard';
import { formatNaira } from '../lib/format';
import { ACTIVE, AWAITING } from '../lib/status';
import { EmptyState, HeroStats, IconTile, SectionHeader, SegmentedControl, SurfaceCard } from '../components/ui';

const FILTERS = [
  { id: 'all', label: 'All' },
  { id: 'pending', label: 'Pending' },
  { id: 'assigned', label: 'Assigned' },
  { id: 'confirmed', label: 'Confirmed' },
  { id: 'inTransit', label: 'In Transit' },
  { id: 'completed', label: 'Delivered' },
];

export function DispatchView() {
  const { jobs, currentFilter, setCurrentFilter } = useAppContext();

  const count = (statuses) => jobs.filter((j) => statuses.includes(j.status)).length;
  const total = jobs.length;
  const share = (n) => (total ? n / total : 0);

  const awaiting = count(AWAITING);
  const onTheRoad = count(['pickedUp', 'inTransit']);
  const delivered = count(['completed']);
  const revenue = jobs
    .filter((j) => j.status !== 'cancelled')
    .reduce((sum, j) => sum + (j.totalAmount || 0), 0);

  const filteredJobs = jobs.filter((job) => currentFilter === 'all' || job.status === currentFilter);

  return (
    <div className="px-8 pb-10">
      <section className="grid gap-6 lg:grid-cols-[minmax(0,1fr)_300px] items-center">
        <HeroStats
          label="Active jobs"
          value={count(ACTIVE)}
          className="w-full max-w-[560px] mx-auto"
          pills={[
            { icon: Clock, value: awaiting, label: 'Awaiting', progress: share(awaiting) },
            { icon: Truck, value: onTheRoad, label: 'On the road', progress: share(onTheRoad) },
            { icon: CircleCheck, value: delivered, label: 'Delivered', progress: share(delivered) },
          ]}
        />
        <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-1">
          <SummaryTile icon={ClipboardList} label="Total jobs" value={total} />
          <SummaryTile icon={Banknote} label="Revenue" value={formatNaira(revenue)} />
        </div>
      </section>

      <SectionHeader
        title="Live Dispatch Board"
        className="mt-10 mb-5"
        action={
          <SegmentedControl
            value={currentFilter}
            onChange={setCurrentFilter}
            options={FILTERS.map((f) => ({
              value: f.id,
              label: f.label,
              count: f.id === 'all' ? total : count([f.id]),
            }))}
          />
        }
      />

      {filteredJobs.length > 0 ? (
        <div className="grid grid-cols-[repeat(auto-fill,minmax(340px,1fr))] gap-3">
          {filteredJobs.map((job, index) => (
            <JobCard key={job.id} job={job} index={index} />
          ))}
        </div>
      ) : (
        <EmptyState
          icon={Inbox}
          title="Nothing here"
          subtitle="No jobs in this category right now."
          className="max-w-md mx-auto mt-4"
        />
      )}
    </div>
  );
}

function SummaryTile({ icon, label, value }) {
  return (
    <SurfaceCard className="flex items-center gap-4 p-5">
      <IconTile icon={icon} />
      <div className="min-w-0">
        <div className="text-[12px] text-white/50">{label}</div>
        <div className="text-[24px] font-extrabold leading-tight text-white tabular-nums truncate">{value}</div>
      </div>
    </SurfaceCard>
  );
}
