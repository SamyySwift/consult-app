import React from 'react';
import { ShieldCheck, UserRound } from 'lucide-react';
import { useAppContext } from '../context/AppContext';
import { formatNaira, shortRef, vehicleName } from '../lib/format';
import { ACTIVE, STAGE_COUNT, statusOf } from '../lib/status';
import { FlatChip, IconTile, Route, SegmentProgressBar, StatusBadge, SurfaceCard, vehicleIcon } from './ui';

/** Dispatch board card, laid out like the client's booking tile. */
export function JobCard({ job, index }) {
  const { setSelectedJobId } = useAppContext();
  const { stage } = statusOf(job.status);
  const unassigned = !job.driverId;

  return (
    <SurfaceCard
      radius="rounded-[26px]"
      className="p-[18px] flex flex-col gap-4 animate-enter"
      style={{ animationDelay: `${Math.min(index, 12) * 50}ms` }}
      onClick={() => setSelectedJobId(job.id)}
    >
      <div className="flex items-start gap-3">
        <IconTile icon={vehicleIcon(job.vehicle.type)} accent={ACTIVE.includes(job.status)} />
        <div className="flex-1 min-w-0">
          <div className="text-[16px] font-bold text-white truncate">{vehicleName(job)}</div>
          <div className="mt-0.5 text-[12px] text-white/55 truncate">
            <span className="tabular-nums">#{shortRef(job.id)}</span> · {job.customerName}
          </div>
        </div>
        <StatusBadge status={job.status} compact />
      </div>

      <Route pickup={job.pickup.address} dropoff={job.dropoff.address} />

      <div className="flex flex-col gap-2.5">
        <div className="flex items-center justify-between gap-3">
          <span className="text-[12px] text-white/55">
            Journey <span className="font-semibold text-white">{stage} of {STAGE_COUNT}</span>
          </span>
          <FlatChip>{job.serviceType}</FlatChip>
        </div>
        <SegmentProgressBar total={STAGE_COUNT} filled={stage} error={job.status === 'cancelled'} />
      </div>

      <div className="flex items-end justify-between gap-3">
        <div className="min-w-0">
          <div className="text-[19px] font-extrabold leading-none text-white tabular-nums">
            {formatNaira(job.totalAmount)}
          </div>
          <div className={`mt-2 flex items-center gap-1.5 text-[12px] truncate ${unassigned ? 'text-white/40' : 'text-white/60'}`}>
            <UserRound size={13} strokeWidth={2.2} className="shrink-0" />
            {job.driverName}
          </div>
        </div>
        <div className="flex gap-1.5 shrink-0">
          <FlatChip>{job.transportMode === 'Enclosed Transport' ? 'Enclosed' : 'Open'}</FlatChip>
          {job.hasInsurance && (
            <FlatChip icon={ShieldCheck} accent>
              Insured
            </FlatChip>
          )}
        </div>
      </div>
    </SurfaceCard>
  );
}
