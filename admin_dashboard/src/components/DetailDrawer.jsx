import React, { useState } from 'react';
import {
  BadgeCheck,
  Banknote,
  CalendarClock,
  Car,
  CircleCheck,
  CircleDot,
  ClipboardList,
  FileText,
  Flag,
  MapPin,
  Package,
  Palette,
  Phone,
  Printer,
  ShieldCheck,
  Tag,
  Truck,
  UserCheck,
  UserPlus,
  UserRound,
  X,
} from 'lucide-react';
import { useAppContext } from '../context/AppContext';
import { assignDriver, updateBookingStatus } from '../lib/api';
import { formatNaira, shortRef, vehicleName } from '../lib/format';
import { ACTIVE } from '../lib/status';
import {
  Alert,
  Badge,
  Button,
  Dialog,
  Eyebrow,
  GlassIconButton,
  IconTile,
  KeyValueRow,
  Select,
  StatusBadge,
  SurfaceCard,
  vehicleIcon,
} from './ui';

function Section({ title, aside, children }) {
  return (
    <section className="flex flex-col gap-2.5">
      <div className="flex items-center justify-between gap-3 px-1">
        <Eyebrow>{title}</Eyebrow>
        {aside}
      </div>
      {children}
    </section>
  );
}

function Rows({ children }) {
  return (
    <SurfaceCard radius="rounded-[20px]" className="px-4 py-1">
      {children}
    </SurfaceCard>
  );
}

/** Vertical version of the client's tracking timeline. */
function Timeline({ job }) {
  const steps = [
    { label: 'Job Created', time: job.createdAt, done: true, icon: ClipboardList },
    { label: 'Driver Assigned', time: job.assignedAt, done: !!job.assignedAt, icon: UserCheck },
    { label: 'Driver Confirmed', time: job.confirmedAt, done: !!job.confirmedAt, icon: BadgeCheck },
    { label: 'Vehicle Picked Up', time: job.pickedUpAt, done: !!job.pickedUpAt, icon: Package },
    { label: 'Delivered', time: job.completedAt, done: !!job.completedAt, icon: Flag },
  ];
  const lastDone = steps.reduce((acc, s, i) => (s.done ? i : acc), -1);
  const finished = job.status === 'completed' || job.status === 'cancelled';

  return (
    <ol className="flex flex-col px-1">
      {steps.map((step, i) => {
        const state = !step.done ? 'upcoming' : i === lastDone && !finished ? 'current' : 'done';
        const Icon = step.icon;
        const next = steps[i + 1];
        return (
          <li key={step.label} className="flex gap-3.5">
            <div className="flex flex-col items-center">
              <span
                className={`grid place-items-center w-10 rounded-full border shrink-0 ${
                  state === 'current'
                    ? 'h-14 gradient-accent border-transparent text-black shadow-glow-lg'
                    : state === 'done'
                      ? 'h-10 bg-accent/16 border-accent/45 text-accent-light'
                      : 'h-10 bg-white/5 border-white/10 text-white/40'
                }`}
              >
                <Icon size={17} strokeWidth={2.2} />
              </span>
              {next && (
                <span
                  className={`flex-1 min-h-4 my-1 border-l-2 ${
                    next.done ? 'border-dashed border-accent/70' : 'border-white/12'
                  }`}
                />
              )}
            </div>
            <div className={`min-w-0 pb-5 ${state === 'current' ? 'pt-3' : 'pt-1.5'}`}>
              <div className={`text-[14px] font-bold ${state === 'upcoming' ? 'text-white/45' : 'text-white'}`}>
                {step.label}
              </div>
              <div className={`mt-0.5 text-[12px] ${state === 'current' ? 'font-semibold text-accent' : 'text-white/55'}`}>
                {state === 'current' ? `Happening now · ${step.time}` : step.time || 'Pending'}
              </div>
            </div>
          </li>
        );
      })}
    </ol>
  );
}

export function DetailDrawer() {
  const { jobs, drivers, selectedJobId, setSelectedJobId, fetchBookings } = useAppContext();
  const job = jobs.find(j => j.id === selectedJobId);

  const isOpen = !!job;

  // Driver assignment state
  const [assignMode, setAssignMode] = useState(false);
  const [selectedDriverId, setSelectedDriverId] = useState('');
  const [assigning, setAssigning] = useState(false);
  const [assignError, setAssignError] = useState('');
  const [showDeliveryModal, setShowDeliveryModal] = useState(false);

  const closeDrawer = () => {
    setSelectedJobId(null);
    setAssignMode(false);
    setSelectedDriverId('');
    setAssignError('');
    setShowDeliveryModal(false);
  };

  // ── Manual driver assignment ──────────────────────────────────────────────
  const handleAssignDriver = async () => {
    if (!selectedDriverId) {
      setAssignError('Please select a driver first.');
      return;
    }
    setAssigning(true);
    setAssignError('');
    try {
      await assignDriver(job.dbId, selectedDriverId);
      await fetchBookings();
      setAssignMode(false);
      setSelectedDriverId('');
    } catch (err) {
      setAssignError(err.message || 'Failed to assign driver. Please try again.');
    } finally {
      setAssigning(false);
    }
  };

  const handleAction = async (action) => {
    if (action === 'viewReceipt') {
      setShowDeliveryModal(true);
      return;
    }
    if (action === 'assign') {
      setAssignMode(true);
      // Pre-select current driver if one is already assigned
      setSelectedDriverId(job.driverId || '');
      setAssignError('');
      return;
    }
    if (action === 'cancel') {
      try {
        await updateBookingStatus(job.dbId, 'cancelled');
        await fetchBookings();
      } catch (err) {
        console.error('Cancel failed:', err);
      }
      closeDrawer();
      return;
    }

    // Status-update actions
    const statusMap = {
      markPickedUp:   'pickedUp',
      markInTransit:  'inTransit',
      markDelivered:  'completed',
    };
    const newStatus = statusMap[action];
    if (!newStatus) return;

    try {
      await updateBookingStatus(job.dbId, newStatus);
      await fetchBookings();
    } catch (err) {
      console.error('Action failed:', err);
    }
  };

  const hasCondition =
    job && (job.pickupConditionDesc || job.pickupConditionImages?.length > 0 || job.pickupConditionAudio);
  const hasDelivery = job && (job.status === 'completed' || job.completedAt || job.clientSignatureBase64);

  return (
    <>
      <div
        className={`fixed inset-0 z-[199] bg-black/50 transition-opacity duration-300 ${isOpen ? 'opacity-100' : 'opacity-0 pointer-events-none'}`}
        onClick={closeDrawer}
      ></div>

      <aside
        aria-hidden={!isOpen}
        className={`fixed top-3 right-3 bottom-3 z-[200] w-drawer max-w-[calc(100vw-24px)] flex flex-col rounded-sheet border border-white/10 bg-[rgb(16_16_16/0.9)] backdrop-blur-[20px] shadow-float transition-transform duration-300 ease-out-cubic ${
          isOpen ? 'translate-x-0' : 'translate-x-[calc(100%+24px)]'
        }`}
      >
        {job && (
          <>
            <div className="flex items-start gap-3.5 px-6 pt-6 pb-5 border-b border-white/8 shrink-0">
              <IconTile icon={vehicleIcon(job.vehicle.type)} accent={ACTIVE.includes(job.status)} />
              <div className="flex-1 min-w-0">
                <div className="text-[12px] text-white/55 truncate">
                  <span className="tabular-nums">#{shortRef(job.id)}</span> · {job.serviceType}
                </div>
                <h2 className="mt-0.5 text-[20px] font-extrabold leading-tight tracking-[-0.3px] text-white">
                  {vehicleName(job)}
                </h2>
                <div className="mt-2.5">
                  <StatusBadge status={job.status} />
                </div>
              </div>
              <GlassIconButton icon={X} label="Close" size={40} onClick={closeDrawer} />
            </div>

            <div className="flex-1 overflow-y-auto px-5 py-6 flex flex-col gap-7 scrollbar-thin">
              <Section title="Client & Driver">
                <Rows>
                  <KeyValueRow icon={UserRound} label="Client">{job.customerName}</KeyValueRow>
                  <KeyValueRow icon={Phone} label="Phone" className="text-white tabular-nums">{job.customerPhone}</KeyValueRow>
                  <KeyValueRow
                    icon={Truck}
                    label="Driver"
                    className={job.driverName === 'Unassigned' ? 'text-white/45 italic' : 'text-white'}
                  >
                    {job.driverName}
                  </KeyValueRow>
                </Rows>
              </Section>

              <Section title="Vehicle">
                <Rows>
                  <KeyValueRow icon={Car} label="Vehicle">{vehicleName(job)}</KeyValueRow>
                  <KeyValueRow icon={Palette} label="Colour">{job.vehicle.color}</KeyValueRow>
                  {job.vehicleValue > 0 && (
                    <KeyValueRow icon={Banknote} label="Worth" className="text-white tabular-nums">
                      {formatNaira(job.vehicleValue)}
                    </KeyValueRow>
                  )}
                  <KeyValueRow icon={Package} label="Transport">{job.transportMode}</KeyValueRow>
                  <KeyValueRow
                    icon={ShieldCheck}
                    label="Insurance"
                    className={job.hasInsurance ? 'text-accent-light' : 'text-white/45'}
                  >
                    {job.hasInsurance ? 'Covered' : 'None'}
                  </KeyValueRow>
                </Rows>
              </Section>

              <Section title="Route">
                <Rows>
                  <KeyValueRow icon={CircleDot} label="Pickup">{job.pickup.address}</KeyValueRow>
                  {job.pickup.scheduledAt && (
                    <KeyValueRow icon={CalendarClock} label="Scheduled">{job.pickup.scheduledAt}</KeyValueRow>
                  )}
                  <KeyValueRow icon={MapPin} label="Drop-off">{job.dropoff.address}</KeyValueRow>
                </Rows>
              </Section>

              <Section title="Payment">
                <Rows>
                  <KeyValueRow icon={Banknote} label="Total" className="text-[16px] font-extrabold text-accent tabular-nums">
                    {formatNaira(job.totalAmount)}
                  </KeyValueRow>
                  {job.hasInsurance && job.insuranceFee > 0 && (
                    <KeyValueRow icon={ShieldCheck} label="Insurance fee" className="text-white tabular-nums">
                      {formatNaira(job.insuranceFee)}
                    </KeyValueRow>
                  )}
                  <KeyValueRow icon={Tag} label="Service">{job.serviceType}</KeyValueRow>
                </Rows>
              </Section>

              {hasCondition && (
                <Section title="Pickup Condition">
                  <SurfaceCard radius="rounded-[20px]" className="p-4 flex flex-col gap-4">
                    {job.pickupConditionDesc && (
                      <p className="text-[13px] leading-relaxed text-white/85">{job.pickupConditionDesc}</p>
                    )}
                    {job.pickupConditionImages?.length > 0 && (
                      <div className="flex gap-2 overflow-x-auto pb-1 scrollbar-thin">
                        {job.pickupConditionImages.map((img, idx) => (
                          <a key={idx} href={img} target="_blank" rel="noreferrer" className="shrink-0">
                            <img
                              src={img}
                              alt={`Condition ${idx + 1}`}
                              className="size-16 object-cover rounded-[14px] border border-line hover:opacity-80 transition-opacity"
                            />
                          </a>
                        ))}
                      </div>
                    )}
                    {job.pickupConditionAudio && (
                      <audio controls src={job.pickupConditionAudio} className="w-full h-9" />
                    )}
                  </SurfaceCard>
                </Section>
              )}

              {hasDelivery && (
                <Section title="Delivery Record" aside={<Badge tone="success" compact>Delivered</Badge>}>
                  <Rows>
                    <KeyValueRow icon={CircleCheck} label="Delivered">{job.completedAt || 'Completed'}</KeyValueRow>
                    {job.clientAcknowledgedAt && (
                      <KeyValueRow icon={BadgeCheck} label="Signed off">{job.clientAcknowledgedAt}</KeyValueRow>
                    )}
                  </Rows>
                  {job.clientSignatureBase64 ? (
                    <div className="flex items-center justify-center min-h-[96px] p-3 rounded-[20px] bg-white">
                      <img src={job.clientSignatureBase64} alt="Client signature" className="max-h-20 object-contain" />
                    </div>
                  ) : (
                    <p className="px-1 text-[12px] italic text-white/45">No digital signature attached</p>
                  )}
                  <Button variant="glass" icon={FileText} className="w-full" onClick={() => setShowDeliveryModal(true)}>
                    View delivery receipt
                  </Button>
                </Section>
              )}

              <Section title="Job Timeline">
                <Timeline job={job} />
              </Section>
            </div>

            {/* ── Actions ─────────────────────────────────────────────── */}
            <div className="px-5 py-5 border-t border-white/8 shrink-0 flex flex-col gap-2.5">
              {assignMode ? (
                <SurfaceCard radius="rounded-[20px]" className="p-4 flex flex-col gap-3">
                  <Eyebrow>{job.driverId ? 'Reassign Driver' : 'Assign Driver'}</Eyebrow>
                  <Select
                    value={selectedDriverId}
                    onChange={e => { setSelectedDriverId(e.target.value); setAssignError(''); }}
                    aria-label="Driver"
                  >
                    <option value="" disabled>Select a driver</option>
                    {drivers.length === 0 && (
                      <option value="" disabled>No drivers available</option>
                    )}
                    {drivers.map(d => (
                      <option key={d.id} value={d.id}>
                        {d.full_name}{d.phone ? ` · ${d.phone}` : ''}
                      </option>
                    ))}
                  </Select>

                  {assignError && <p className="text-[12px] text-error">{assignError}</p>}

                  <div className="flex gap-2">
                    <Button
                      className="flex-1"
                      onClick={handleAssignDriver}
                      disabled={!selectedDriverId}
                      loading={assigning}
                    >
                      {assigning ? 'Assigning…' : 'Confirm assignment'}
                    </Button>
                    <Button variant="glass" onClick={() => { setAssignMode(false); setAssignError(''); }}>
                      Cancel
                    </Button>
                  </div>
                </SurfaceCard>
              ) : (
                <>
                  {(job.status === 'pending' || job.status === 'assigned') && (
                    <>
                      <Button variant="glass" icon={UserPlus} onClick={() => handleAction('assign')}>
                        {job.driverId ? 'Reassign driver' : 'Assign driver'}
                      </Button>
                      <Button variant="dangerGhost" onClick={() => handleAction('cancel')}>
                        Cancel job
                      </Button>
                    </>
                  )}
                  {job.status === 'confirmed' && (
                    <>
                      <Button variant="glass" disabled>
                        Awaiting driver condition report
                      </Button>
                      <Button variant="glass" icon={UserPlus} onClick={() => handleAction('assign')}>
                        Reassign driver
                      </Button>
                      <Button variant="dangerGhost" onClick={() => handleAction('cancel')}>
                        Cancel job
                      </Button>
                    </>
                  )}
                  {job.status === 'pickedUp' && (
                    <Button icon={Truck} onClick={() => handleAction('markInTransit')}>
                      Mark in transit
                    </Button>
                  )}
                  {job.status === 'inTransit' && (
                    <Button icon={CircleCheck} onClick={() => handleAction('markDelivered')}>
                      Mark as delivered
                    </Button>
                  )}
                  {job.status === 'completed' && (
                    <Button variant="glass" icon={FileText} onClick={() => handleAction('viewReceipt')}>
                      View delivery record
                    </Button>
                  )}
                </>
              )}
            </div>
          </>
        )}
      </aside>

      {/* ── Official Delivery Receipt ──────────────────────────────────── */}
      {showDeliveryModal && job && (
        <Dialog
          eyebrow="Official proof of delivery"
          title={`Delivery Record #${shortRef(job.id)}`}
          width="max-w-lg"
          onClose={() => setShowDeliveryModal(false)}
          footer={
            <>
              <Button variant="glass" icon={Printer} onClick={() => window.print()}>
                Print receipt
              </Button>
              <Button onClick={() => setShowDeliveryModal(false)}>Close</Button>
            </>
          }
        >
          <Alert tone="success">
            <div className="font-bold">Delivery completed & verified</div>
            <div className="mt-0.5 text-[12px] font-normal text-white/60">Completed: {job.completedAt || 'Date recorded'}</div>
          </Alert>

          <SurfaceCard radius="rounded-[20px]" className="grid grid-cols-2 gap-4 p-4 text-[13px]">
            <ReceiptField label="Vehicle">{vehicleName(job)}</ReceiptField>
            <ReceiptField label="Service type">{job.serviceType} ({job.transportMode})</ReceiptField>
            <ReceiptField label="Client">{job.customerName} ({job.customerPhone})</ReceiptField>
            <ReceiptField label="Assigned driver">{job.driverName}</ReceiptField>
          </SurfaceCard>

          <SurfaceCard radius="rounded-[20px]" className="flex flex-col gap-3 p-4 text-[13px]">
            <ReceiptField label="Pickup origin">{job.pickup.address}</ReceiptField>
            <div className="border-t border-white/6" />
            <ReceiptField label="Drop-off destination">{job.dropoff.address}</ReceiptField>
          </SurfaceCard>

          <div className="flex flex-col gap-2.5">
            <Eyebrow className="px-1">Client digital signature</Eyebrow>
            {job.clientSignatureBase64 ? (
              <div className="flex flex-col items-center gap-2 p-4 rounded-[20px] bg-white">
                <img src={job.clientSignatureBase64} alt="Client signature" className="max-h-24 object-contain" />
                <div className="w-full pt-1 border-t border-gray-200 text-center text-[10px] text-gray-500">
                  Digitally signed by recipient on delivery • Verified by Consult Logistics
                </div>
              </div>
            ) : (
              <SurfaceCard radius="rounded-[20px]" className="p-4 text-center text-[12px] italic text-white/45">
                No digital signature image recorded for this booking.
              </SurfaceCard>
            )}
          </div>
        </Dialog>
      )}
    </>
  );
}

function ReceiptField({ label, children }) {
  return (
    <div className="min-w-0">
      <div className="mb-0.5 text-[12px] text-white/50">{label}</div>
      <div className="font-semibold text-white break-words">{children}</div>
    </div>
  );
}
