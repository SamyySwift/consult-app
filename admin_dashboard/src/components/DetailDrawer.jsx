import React, { useState } from 'react';
import { useAppContext } from '../context/AppContext';
import { supabase } from '../lib/supabase';

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

  const buildTimeline = (j) => {
    const steps = [
      { label: 'Job Created',       time: j.createdAt,   done: true },
      { label: 'Driver Assigned',   time: j.assignedAt,  done: !!j.assignedAt },
      { label: 'Driver Confirmed',  time: j.confirmedAt, done: !!j.confirmedAt },
      { label: 'Vehicle Picked Up', time: j.pickedUpAt,  done: !!j.pickedUpAt },
      { label: 'Delivered',         time: j.completedAt, done: !!j.completedAt },
    ];
  
    const activeIdx = steps.reduce((acc, s, i) => s.done ? i : acc, -1);
  
    return steps.map((s, i) => {
      let dotClass = 'border-navy-border';
      if (s.done && i < activeIdx) dotClass = 'bg-success border-success';
      else if (s.done && i === activeIdx) dotClass = j.status === 'completed' ? 'bg-success border-success' : 'bg-amber border-amber shadow-[0_0_0_4px_rgba(201,145,58,0.15)] animate-pulse-dot';
      else dotClass = 'border-navy-border';

      return (
        <div key={i} className="relative pl-6 pb-5 last:pb-0 before:content-[''] before:absolute before:left-[3px] before:top-2 before:bottom-[-8px] before:w-px before:bg-navy-border last:before:hidden">
          <div className={`absolute left-0 top-1 w-2 h-2 rounded-full border-2 bg-navy ${dotClass}`}></div>
          <div>
            <div className={`text-[13px] font-medium leading-none mb-1 ${s.done ? 'text-text-primary' : 'text-text-mid'}`}>{s.label}</div>
            <div className={`text-[11px] font-mono ${s.time ? 'text-text-mid' : 'text-text-dim'}`}>
              {s.time || 'Pending'}
            </div>
          </div>
        </div>
      );
    });
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
      const { error } = await supabase
        .from('bookings')
        .update({
          driver_id: selectedDriverId,
          status: 'assigned',
          assigned_at: new Date().toISOString(),
        })
        .eq('id', job.dbId);

      if (error) throw error;

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
        await supabase
          .from('bookings')
          .update({ status: 'cancelled' })
          .eq('id', job.dbId);
        await fetchBookings();
      } catch (err) {
        console.error('Cancel failed:', err);
      }
      closeDrawer();
      return;
    }

    // Status-update actions
    const statusMap = {
      markPickedUp:   { status: 'pickedUp',   field: 'picked_up_at' },
      markInTransit:  { status: 'inTransit',  field: null },
      markDelivered:  { status: 'completed',  field: 'completed_at' },
    };
    const mapping = statusMap[action];
    if (!mapping) return;

    try {
      const update = { status: mapping.status };
      if (mapping.field) update[mapping.field] = new Date().toISOString();
      await supabase.from('bookings').update(update).eq('id', job.dbId);
      await fetchBookings();
    } catch (err) {
      console.error('Action failed:', err);
    }
  };

  return (
    <>
      <div 
        className={`fixed inset-0 bg-black/50 z-[199] transition-opacity duration-[220ms] ${isOpen ? 'opacity-100 pointer-events-auto' : 'opacity-0 pointer-events-none'}`}
        onClick={closeDrawer}
      ></div>

      <aside className={`fixed top-0 right-0 w-[400px] h-screen bg-navy-mid border-l border-navy-border z-[200] flex flex-col transition-transform duration-300 ease-[cubic-bezier(0.4,0,0.2,1)] ${isOpen ? 'translate-x-0' : 'translate-x-full'}`}>
        {job && (
          <>
            <div className="flex items-start justify-between p-6 border-b border-navy-border shrink-0">
              <div>
                <div className="font-mono text-xs text-accent-red mb-1">{job.id}</div>
                <div className="font-syne text-[18px] font-bold text-text-primary">
                  {job.vehicle.year} {job.vehicle.make} {job.vehicle.model} · {job.serviceType}
                </div>
              </div>
              <button 
                onClick={closeDrawer}
                className="w-8 h-8 bg-navy-light border-none rounded-md flex items-center justify-center cursor-pointer text-text-mid hover:bg-navy hover:text-text-primary transition-colors"
              >
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" className="w-[18px] h-[18px]"><path d="M18 6L6 18M6 6l12 12"/></svg>
              </button>
            </div>

            <div className="flex-1 overflow-y-auto p-6 flex flex-col gap-8 scrollbar-thin">
              <div>
                <div className="text-[11px] font-medium text-text-mid uppercase tracking-[0.06em] mb-3 pb-2 border-b border-navy-border">Client & Driver</div>
                <div className="flex justify-between text-[13px] py-1.5"><span className="text-text-mid">Client</span><span className="text-text-primary font-medium">{job.customerName}</span></div>
                <div className="flex justify-between text-[13px] py-1.5"><span className="text-text-mid">Phone</span><span className="text-text-primary font-medium font-mono">{job.customerPhone}</span></div>
                <div className="flex justify-between text-[13px] py-1.5">
                  <span className="text-text-mid">Driver</span>
                  <span className={`font-medium text-[13px] ${job.driverName === 'Unassigned' ? 'text-text-dim italic' : 'text-text-primary'}`}>
                    {job.driverName}
                  </span>
                </div>
              </div>

              <div>
                <div className="text-[11px] font-medium text-text-mid uppercase tracking-[0.06em] mb-3 pb-2 border-b border-navy-border">Vehicle</div>
                <div className="flex justify-between text-[13px] py-1.5"><span className="text-text-mid">Vehicle</span><span className="text-text-primary font-medium">{job.vehicle.year} {job.vehicle.make} {job.vehicle.model}</span></div>
                <div className="flex justify-between text-[13px] py-1.5"><span className="text-text-mid">Colour</span><span className="text-text-primary font-medium">{job.vehicle.color}</span></div>
                <div className="flex justify-between text-[13px] py-1.5"><span className="text-text-mid">Transport</span><span className="text-text-primary font-medium">{job.transportMode}</span></div>
                <div className="flex justify-between text-[13px] py-1.5"><span className="text-text-mid">Insurance</span><span className="text-text-primary font-medium">{job.hasInsurance ? '✓ Covered' : '— None'}</span></div>
              </div>

              <div>
                <div className="text-[11px] font-medium text-text-mid uppercase tracking-[0.06em] mb-3 pb-2 border-b border-navy-border">Route</div>
                <div className="flex justify-between text-[13px] py-1.5"><span className="text-text-mid">Pickup</span><span className="text-text-primary font-medium max-w-[200px] text-right">{job.pickup.address}</span></div>
                {job.pickup.scheduledAt && <div className="flex justify-between text-[13px] py-1.5"><span className="text-text-mid">Scheduled</span><span className="text-text-primary font-medium font-mono">{job.pickup.scheduledAt}</span></div>}
                <div className="flex justify-between text-[13px] py-1.5"><span className="text-text-mid">Dropoff</span><span className="text-text-primary font-medium max-w-[200px] text-right">{job.dropoff.address}</span></div>
              </div>

              <div>
                <div className="text-[11px] font-medium text-text-mid uppercase tracking-[0.06em] mb-3 pb-2 border-b border-navy-border">Financials</div>
                <div className="flex justify-between text-[13px] py-1.5"><span className="text-text-mid">Amount</span><span className="text-amber font-mono font-medium tracking-[0.02em]">₦{(job.totalAmount || 0).toLocaleString('en-NG')}</span></div>
                <div className="flex justify-between text-[13px] py-1.5"><span className="text-text-mid">Service</span><span className="text-text-primary font-medium">{job.serviceType}</span></div>
              </div>

              {(job.pickupConditionDesc || (job.pickupConditionImages && job.pickupConditionImages.length > 0) || job.pickupConditionAudio) && (
                <div>
                  <div className="text-[11px] font-medium text-text-mid uppercase tracking-[0.06em] mb-3 pb-2 border-b border-navy-border">Pickup Condition</div>
                  {job.pickupConditionDesc && (
                    <div className="mb-3">
                      <div className="text-[12px] text-text-mid mb-1">Description</div>
                      <div className="text-[13px] text-text-primary bg-navy-light p-3 rounded-lg border border-navy-border">{job.pickupConditionDesc}</div>
                    </div>
                  )}
                  {job.pickupConditionImages && job.pickupConditionImages.length > 0 && (
                    <div className="mb-3">
                      <div className="text-[12px] text-text-mid mb-1">Photos</div>
                      <div className="flex gap-2 overflow-x-auto pb-2 scrollbar-thin">
                        {job.pickupConditionImages.map((img, idx) => (
                          <a key={idx} href={img} target="_blank" rel="noreferrer" className="shrink-0">
                            <img src={img} alt={`Condition ${idx+1}`} className="w-16 h-16 object-cover rounded-lg border border-navy-border hover:opacity-80 transition-opacity" />
                          </a>
                        ))}
                      </div>
                    </div>
                  )}
                  {job.pickupConditionAudio && (
                    <div className="mb-3">
                      <div className="text-[12px] text-text-mid mb-1">Voice Note</div>
                      <audio controls src={job.pickupConditionAudio} className="w-full h-8" />
                    </div>
                  )}
                </div>
              )}

              {/* ── Delivery Record Section ──────────────────────────── */}
              {(job.status === 'completed' || job.completedAt || job.clientSignatureBase64) && (
                <div>
                  <div className="text-[11px] font-medium text-text-mid uppercase tracking-[0.06em] mb-3 pb-2 border-b border-navy-border flex justify-between items-center">
                    <span>Delivery Record</span>
                    <span className="text-[10px] text-success bg-success/15 px-2 py-0.5 rounded font-mono uppercase font-bold">✓ Delivered</span>
                  </div>
                  
                  <div className="flex justify-between text-[13px] py-1.5">
                    <span className="text-text-mid">Delivered At</span>
                    <span className="text-text-primary font-medium font-mono">{job.completedAt || 'Completed'}</span>
                  </div>
                  
                  {job.clientAcknowledgedAt && (
                    <div className="flex justify-between text-[13px] py-1.5">
                      <span className="text-text-mid">Client Acknowledged</span>
                      <span className="text-text-primary font-medium font-mono">{job.clientAcknowledgedAt}</span>
                    </div>
                  )}

                  {job.clientSignatureBase64 ? (
                    <div className="mt-3">
                      <div className="text-[12px] text-text-mid mb-1.5 flex items-center justify-between">
                        <span>Client Digital Signature</span>
                        <span className="text-[11px] text-success font-medium">✓ Verified</span>
                      </div>
                      <div className="bg-white p-3 rounded-lg border border-navy-border flex items-center justify-center min-h-[90px]">
                        <img 
                          src={job.clientSignatureBase64} 
                          alt="Client Signature" 
                          className="max-h-20 object-contain"
                        />
                      </div>
                    </div>
                  ) : (
                    <div className="mt-2 text-[12px] text-text-dim italic bg-navy-light p-2.5 rounded border border-navy-border">
                      No digital signature attached
                    </div>
                  )}

                  <button
                    onClick={() => setShowDeliveryModal(true)}
                    className="w-full mt-3 px-3 py-2 bg-navy-light text-info text-[12px] font-semibold rounded-lg border border-navy-border hover:bg-navy-border transition-colors flex items-center justify-center gap-1.5"
                  >
                    <svg className="w-4 h-4" fill="none" stroke="currentColor" strokeWidth="2" viewBox="0 0 24 24">
                      <path d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/>
                    </svg>
                    View Official Delivery Receipt
                  </button>
                </div>
              )}

              <div>
                <div className="text-[11px] font-medium text-text-mid uppercase tracking-[0.06em] mb-3 pb-2 border-b border-navy-border">Job Timeline</div>
                <div>{buildTimeline(job)}</div>
              </div>
            </div>

            {/* ── Action Footer ──────────────────────────────────────── */}
            <div className="p-6 border-t border-navy-border bg-navy shrink-0 flex flex-col gap-2.5">

              {/* Assign Driver Panel */}
              {assignMode ? (
                <div className="flex flex-col gap-3 bg-navy-mid border border-navy-border rounded-xl p-4">
                  <div className="text-[12px] font-semibold text-text-mid uppercase tracking-[0.06em]">
                    {job.driverId ? 'Reassign Driver' : 'Assign Driver'}
                  </div>

                  <select
                    value={selectedDriverId}
                    onChange={e => { setSelectedDriverId(e.target.value); setAssignError(''); }}
                    className="w-full px-3 py-2 bg-navy border border-navy-border rounded-lg text-[13px] text-text-primary focus:outline-none focus:border-info transition-colors appearance-none cursor-pointer"
                  >
                    <option value="" disabled>— Select a driver —</option>
                    {drivers.length === 0 && (
                      <option value="" disabled>No drivers available</option>
                    )}
                    {drivers.map(d => (
                      <option key={d.id} value={d.id}>
                        {d.full_name}{d.phone ? ` · ${d.phone}` : ''}
                      </option>
                    ))}
                  </select>

                  {assignError && (
                    <p className="text-[12px] text-accent-red">{assignError}</p>
                  )}

                  <div className="flex gap-2">
                    <button
                      onClick={handleAssignDriver}
                      disabled={assigning || !selectedDriverId}
                      className="flex-1 px-4 py-2 bg-info text-white text-[13px] font-semibold rounded-lg hover:bg-info/90 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
                    >
                      {assigning ? 'Assigning…' : 'Confirm Assignment'}
                    </button>
                    <button
                      onClick={() => { setAssignMode(false); setAssignError(''); }}
                      className="px-4 py-2 bg-navy-light text-text-primary text-[13px] font-semibold rounded-lg border border-navy-border hover:bg-navy-border transition-colors"
                    >
                      Cancel
                    </button>
                  </div>
                </div>
              ) : (
                <>
                  {(job.status === 'pending' || job.status === 'assigned') && (
                    <>
                      <button
                        className="px-4 py-2 bg-navy-light text-text-primary text-[13px] font-semibold rounded-lg border border-navy-border hover:bg-navy-border transition-colors"
                        onClick={() => handleAction('assign')}
                      >
                        {job.driverId ? 'Reassign Driver' : 'Assign Driver'}
                      </button>
                      <button
                        className="px-4 py-2 bg-transparent text-accent-red text-[13px] font-semibold rounded-lg hover:bg-error-bg transition-colors"
                        onClick={() => handleAction('cancel')}
                      >
                        Cancel Job
                      </button>
                    </>
                  )}
                  {job.status === 'confirmed' && (
                    <>
                      <button disabled className="px-4 py-2 bg-navy-light text-text-mid text-[13px] font-semibold rounded-lg border border-navy-border cursor-not-allowed">Awaiting Driver Condition Report</button>
                      <button className="px-4 py-2 bg-navy-light text-text-primary text-[13px] font-semibold rounded-lg border border-navy-border hover:bg-navy-border transition-colors" onClick={() => handleAction('assign')}>Reassign Driver</button>
                      <button className="px-4 py-2 bg-transparent text-accent-red text-[13px] font-semibold rounded-lg hover:bg-error-bg transition-colors" onClick={() => handleAction('cancel')}>Cancel Job</button>
                    </>
                  )}
                  {job.status === 'pickedUp' && (
                    <button className="px-4 py-2 bg-amber text-navy-mid text-[13px] font-semibold rounded-lg hover:bg-amber/90 transition-colors" onClick={() => handleAction('markInTransit')}>Mark In Transit</button>
                  )}
                  {job.status === 'inTransit' && (
                    <button className="px-4 py-2 bg-success text-white text-[13px] font-semibold rounded-lg hover:bg-success/90 transition-colors" onClick={() => handleAction('markDelivered')}>Mark as Delivered</button>
                  )}
                  {job.status === 'completed' && (
                    <button className="px-4 py-2 bg-info text-white text-[13px] font-semibold rounded-lg hover:bg-info/90 transition-colors flex items-center justify-center gap-2" onClick={() => handleAction('viewReceipt')}>
                      <svg className="w-4 h-4" fill="none" stroke="currentColor" strokeWidth="2" viewBox="0 0 24 24"><path d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/></svg>
                      View Delivery Record
                    </button>
                  )}
                </>
              )}
            </div>
          </>
        )}
      </aside>

      {/* ── Official Delivery Receipt Modal ────────────────────────────── */}
      {showDeliveryModal && job && (
        <div className="fixed inset-0 bg-black/75 z-[300] flex items-center justify-center p-4 backdrop-blur-sm animate-fade-in">
          <div className="bg-navy-mid border border-navy-border rounded-2xl max-w-lg w-full max-h-[90vh] overflow-y-auto shadow-2xl p-6 relative flex flex-col gap-6 text-text-primary scrollbar-thin">
            
            {/* Modal Header */}
            <div className="flex items-center justify-between border-b border-navy-border pb-4">
              <div>
                <div className="text-[10px] font-mono tracking-widest text-success uppercase font-bold mb-0.5">
                  Official Proof of Delivery
                </div>
                <h3 className="font-syne text-[20px] font-bold text-text-primary">
                  Delivery Record #{job.id}
                </h3>
              </div>
              <button 
                onClick={() => setShowDeliveryModal(false)}
                className="w-8 h-8 bg-navy-light border border-navy-border rounded-lg flex items-center justify-center text-text-mid hover:text-text-primary hover:bg-navy transition-colors"
              >
                <svg className="w-4 h-4" fill="none" stroke="currentColor" strokeWidth="2" viewBox="0 0 24 24"><path d="M18 6L6 18M6 6l12 12"/></svg>
              </button>
            </div>

            {/* Delivery Banner */}
            <div className="bg-success/15 border border-success/30 rounded-xl p-4 flex items-center gap-3">
              <div className="w-10 h-10 rounded-full bg-success/20 flex items-center justify-center text-success shrink-0 font-bold">
                ✓
              </div>
              <div>
                <div className="text-[13px] font-bold text-success">Delivery Completed & Verified</div>
                <div className="text-[12px] text-text-mid font-mono mt-0.5">
                  Completed: {job.completedAt || 'Date Recorded'}
                </div>
              </div>
            </div>

            {/* Logistics Overview Grid */}
            <div className="grid grid-cols-2 gap-4 bg-navy-light p-4 rounded-xl border border-navy-border text-[12px]">
              <div>
                <span className="text-text-dim block mb-0.5">Vehicle</span>
                <span className="font-semibold text-text-primary">{job.vehicle.year} {job.vehicle.make} {job.vehicle.model}</span>
              </div>
              <div>
                <span className="text-text-dim block mb-0.5">Service Type</span>
                <span className="font-semibold text-text-primary">{job.serviceType} ({job.transportMode})</span>
              </div>
              <div>
                <span className="text-text-dim block mb-0.5">Client</span>
                <span className="font-semibold text-text-primary">{job.customerName} ({job.customerPhone})</span>
              </div>
              <div>
                <span className="text-text-dim block mb-0.5">Assigned Driver</span>
                <span className="font-semibold text-text-primary">{job.driverName}</span>
              </div>
            </div>

            {/* Route Details */}
            <div className="flex flex-col gap-2 bg-navy-light p-4 rounded-xl border border-navy-border text-[12px]">
              <div>
                <span className="text-text-dim text-[11px] block uppercase tracking-wider mb-1 font-mono">Pickup Origin</span>
                <span className="text-text-primary font-medium">{job.pickup.address}</span>
              </div>
              <div className="border-t border-navy-border pt-2 mt-1">
                <span className="text-text-dim text-[11px] block uppercase tracking-wider mb-1 font-mono">Dropoff Destination</span>
                <span className="text-text-primary font-medium">{job.dropoff.address}</span>
              </div>
            </div>

            {/* Digital Signature */}
            <div className="flex flex-col gap-2">
              <div className="text-[11px] font-mono uppercase tracking-wider text-text-mid font-semibold">
                Client Digital Signature Verification
              </div>
              {job.clientSignatureBase64 ? (
                <div className="bg-white p-4 rounded-xl border border-navy-border flex flex-col items-center justify-center gap-2">
                  <img 
                    src={job.clientSignatureBase64} 
                    alt="Client Signature" 
                    className="max-h-24 object-contain"
                  />
                  <div className="text-[10px] text-gray-500 font-mono border-t border-gray-200 pt-1 w-full text-center">
                    Digitally signed by recipient on delivery • Verified by Consult Logistics
                  </div>
                </div>
              ) : (
                <div className="bg-navy-light p-4 rounded-xl border border-navy-border text-center text-[12px] text-text-dim italic">
                  No digital signature image recorded for this booking.
                </div>
              )}
            </div>

            {/* Action Buttons */}
            <div className="flex gap-3 border-t border-navy-border pt-4">
              <button
                onClick={() => window.print()}
                className="flex-1 px-4 py-2.5 bg-navy-light text-text-primary text-[13px] font-semibold rounded-xl border border-navy-border hover:bg-navy-border transition-colors flex items-center justify-center gap-2"
              >
                <svg className="w-4 h-4" fill="none" stroke="currentColor" strokeWidth="2" viewBox="0 0 24 24"><path d="M17 17h2a2 2 0 002-2v-4a2 2 0 00-2-2H5a2 2 0 00-2 2v4a2 2 0 002 2h2m2 4h6a2 2 0 002-2v-4a2 2 0 00-2-2H9a2 2 0 00-2 2v4a2 2 0 002 2zm8-12V5a2 2 0 00-2-2H9a2 2 0 00-2 2v4h10z"/></svg>
                Print Receipt
              </button>
              <button
                onClick={() => setShowDeliveryModal(false)}
                className="px-6 py-2.5 bg-info text-white text-[13px] font-semibold rounded-xl hover:bg-info/90 transition-colors"
              >
                Close
              </button>
            </div>

          </div>
        </div>
      )}
    </>
  );
}
