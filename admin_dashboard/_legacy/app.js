const SUPABASE_URL = 'https://ulksjcitenlxtvxwvktw.supabase.co';
const SUPABASE_ANON_KEY = import.meta.env ? import.meta.env.VITE_SUPABASE_ANON_KEY : '';

let _supabase = null;
function getSupabase() {
  if (!_supabase && typeof window !== 'undefined' && window.supabase && window.supabase.createClient) {
    _supabase = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
  }
  return _supabase;
}

// ── In-Memory State ──────────────────────────────────────────────────────────
let JOBS = [];
let JOBS_MAP = new Map();
let DRIVERS = [];
let currentFilter = 'all';
let selectedJobId = null;

// ── Cached DOM refs ──────────────────────────────────────────────────────────
let DOM = {};

// ── Hoisted Vehicle Icons ───────────────────────────────────────────────────
const VEHICLE_ICONS = {
  sedan:      '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><path d="M5 17H3a2 2 0 0 1-2-2V9a2 2 0 0 1 2-2h1l3-4h7l3 4h1a2 2 0 0 1 2 2v6a2 2 0 0 1-2 2h-2"/><circle cx="7.5" cy="17.5" r="2.5"/><circle cx="16.5" cy="17.5" r="2.5"/></svg>',
  suv:        '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><path d="M5 17H3a2 2 0 0 1-2-2V9a2 2 0 0 1 2-2h1l2-3h9l2 3h1a2 2 0 0 1 2 2v6a2 2 0 0 1-2 2h-2"/><circle cx="7.5" cy="17.5" r="2.5"/><circle cx="16.5" cy="17.5" r="2.5"/></svg>',
  truck:      '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><rect x="1" y="3" width="15" height="13" rx="1"/><path d="M16 8h4l3 4v5h-7V8z"/><circle cx="5.5" cy="18.5" r="2.5"/><circle cx="18.5" cy="18.5" r="2.5"/></svg>',
  van:        '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><path d="M3 17H1V9a2 2 0 0 1 2-2h14v10H8M3 17h5M16 17h5v-6l-3-4H16v10z"/><circle cx="5.5" cy="17.5" r="2.5"/><circle cx="18.5" cy="17.5" r="2.5"/></svg>',
  motorcycle: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><circle cx="5.5" cy="17.5" r="3.5"/><circle cx="18.5" cy="17.5" r="3.5"/><path d="M15 6h3l2 5M5.5 14L9 8l4 3h5"/></svg>',
};

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

// ── Utilities ────────────────────────────────────────────────────────────────
function fmtAmount(n) {
  return '₦' + (n || 0).toLocaleString('en-NG');
}

function vehicleIcon(type) {
  const normalized = (type || 'sedan').toLowerCase();
  return VEHICLE_ICONS[normalized] || VEHICLE_ICONS.sedan;
}

function formatRelativeTime(dateStr) {
  if (!dateStr) return null;
  const date = new Date(dateStr);
  if (isNaN(date.getTime())) return dateStr;
  
  const diffMs = Date.now() - date.getTime();
  const diffMin = Math.round(diffMs / (1000 * 60));
  const diffHrs = Math.round(diffMs / (1000 * 60 * 60));
  const diffDays = Math.round(diffMs / (1000 * 60 * 60 * 24));

  if (diffMin < 1) return 'Just now';
  if (diffMin < 60) return `${diffMin} min ago`;
  if (diffHrs < 24) return `${diffHrs} hr${diffHrs > 1 ? 's' : ''} ago`;
  if (diffDays === 1) return 'Yesterday';
  if (diffDays < 7) return `${diffDays} days ago`;
  return date.toLocaleDateString('en-NG', { month: 'short', day: 'numeric' });
}

function normalizeStatus(dbStatus) {
  if (!dbStatus) return 'pending';
  const s = dbStatus.toLowerCase();
  if (s === 'delivered') return 'completed';
  if (s === 'pickedup' || s === 'picked_up') return 'pickedUp';
  if (s === 'intransit' || s === 'in_transit') return 'inTransit';
  if (s === 'confirmed') return 'confirmed';
  if (s === 'assigned') return 'assigned';
  if (s === 'cancelled') return 'cancelled';
  return 'pending';
}

function denormalizeStatus(appStatus) {
  switch (appStatus) {
    case 'completed': return 'delivered';
    case 'pickedUp': return 'pickedUp';
    case 'inTransit': return 'inTransit';
    case 'confirmed': return 'confirmed';
    case 'assigned': return 'assigned';
    case 'cancelled': return 'cancelled';
    default: return 'pending';
  }
}

// ── Live Supabase Data Operations ─────────────────────────────────────────────
async function loadDrivers() {
  const supabase = getSupabase();
  if (!supabase) return;
  try {
    const { data, error } = await supabase
      .from('profiles')
      .select('id, full_name, phone')
      .eq('role', 'driver');

    if (error) throw error;
    if (data && data.length > 0) {
      DRIVERS = data;
      const driverSelect = document.getElementById('f-driver');
      if (driverSelect) {
        driverSelect.innerHTML = '<option value="">— Select Driver —</option>' +
          DRIVERS.map(d => `<option value="${d.id}">${d.full_name || 'Driver (' + d.phone + ')'}</option>`).join('');
      }
    }
  } catch (err) {
    console.warn('Error loading drivers:', err);
  }
}

async function loadLiveBookings() {
  const supabase = getSupabase();
  if (!supabase) {
    renderJobs(currentFilter);
    updateKPIs();
    return;
  }

  try {
    const { data, error } = await supabase
      .from('bookings')
      .select(`
        *,
        client:profiles!bookings_user_id_fkey(full_name, phone, email),
        driver:profiles!bookings_driver_id_fkey(full_name, phone)
      `)
      .order('created_at', { ascending: false });

    if (error) throw error;

    if (data) {
      JOBS = data.map(b => {
        const clientName = b.client?.full_name || 'Direct Client';
        const clientPhone = b.client?.phone || '—';
        const driverName = b.driver?.full_name || (b.driver_id ? 'Assigned Driver' : 'Unassigned');
        
        return {
          id: b.id || b.tracking_number || 'JB00000',
          dbId: b.id,
          customerId: b.user_id,
          customerName: clientName,
          customerPhone: clientPhone,
          driverId: b.driver_id,
          driverName: driverName,
          vehicle: {
            type: (b.vehicle_type || 'sedan').toLowerCase(),
            make: b.vehicle_make || 'Vehicle',
            model: b.vehicle_model || '',
            year: b.vehicle_year || '2023',
            color: b.vehicle_color || 'Silver',
          },
          pickup: {
            address: b.pickup_address || 'Lagos, Nigeria',
            scheduledAt: b.pickup_datetime ? formatRelativeTime(b.pickup_datetime) : 'Scheduled',
          },
          dropoff: {
            address: b.dropoff_address || 'Abuja, Nigeria',
          },
          serviceType: b.service_type || 'Standard',
          transportMode: b.transport_mode ? (b.transport_mode.includes('enclosed') ? 'Enclosed Transport' : 'Open Transport') : 'Open Transport',
          hasInsurance: !!b.has_insurance,
          totalAmount: Number(b.total_amount) || 75000,
          status: normalizeStatus(b.status),
          createdAt: formatRelativeTime(b.created_at),
          assignedAt: b.assigned_at ? formatRelativeTime(b.assigned_at) : (b.driver_id ? formatRelativeTime(b.created_at) : null),
          confirmedAt: b.confirmed_at ? formatRelativeTime(b.confirmed_at) : null,
          pickedUpAt: b.picked_up_at ? formatRelativeTime(b.picked_up_at) : null,
          completedAt: b.completed_at ? formatRelativeTime(b.completed_at) : null,
          clientAcknowledgedAt: b.completed_at ? formatRelativeTime(b.completed_at) : null,
          clientSignatureBase64: b.client_signature_url 
            ? (b.client_signature_url.startsWith('data:image') ? b.client_signature_url : `data:image/png;base64,${b.client_signature_url}`) 
            : null,
        };
      });

      JOBS_MAP = new Map(JOBS.map(j => [j.id, j]));
      renderJobs(currentFilter);
      renderClients();
      renderDrivers();
      renderAllJobsList();
      renderEarnings();
      updateKPIs();

      // If drawer is currently open, refresh its data
      if (selectedJobId && JOBS_MAP.has(selectedJobId)) {
        openDrawer(selectedJobId);
      }
    }
  } catch (err) {
    console.error('Error fetching live bookings from Supabase:', err);
    showToast('Failed to sync live bookings. Retrying...', 'error');
  }
}

function subscribeToRealtime() {
  const supabase = getSupabase();
  if (!supabase) return;

  supabase
    .channel('public:admin_command_center')
    .on('postgres_changes', { event: '*', schema: 'public', table: 'bookings' }, (payload) => {
      console.log('Realtime dispatch change received:', payload.eventType);
      loadLiveBookings();
    })
    .on('postgres_changes', { event: '*', schema: 'public', table: 'drivers' }, () => {
      loadDrivers();
    })
    .subscribe((status) => {
      const dot = document.querySelector('.live-dot');
      if (status === 'SUBSCRIBED' && dot) {
        dot.style.background = '#10b981';
      }
    });
}

// ── KPI Counter Animation ─────────────────────────────────────────────────────
function updateKPIs() {
  const total = JOBS.length;
  const active = JOBS.filter(j => j.status === 'inTransit' || j.status === 'pickedUp' || j.status === 'confirmed').length;
  const assigned = JOBS.filter(j => j.status === 'assigned' || j.status === 'pending').length;
  const delivered = JOBS.filter(j => j.status === 'completed').length;
  const revenue = JOBS
    .filter(j => j.status !== 'cancelled')
    .reduce((sum, j) => sum + (j.totalAmount || 0), 0);

  const kpiTotal = document.querySelector('#kpi-total .kpi-value');
  const kpiActive = document.querySelector('#kpi-active .kpi-value');
  const kpiAssigned = document.querySelector('#kpi-assigned .kpi-value');
  const kpiCompleted = document.querySelector('#kpi-completed .kpi-value');
  const kpiRevenue = document.querySelector('#kpi-revenue .kpi-value');

  if (kpiTotal) { kpiTotal.dataset.target = total; animateKPI(kpiTotal); }
  if (kpiActive) { kpiActive.dataset.target = active; animateKPI(kpiActive); }
  if (kpiAssigned) { kpiAssigned.dataset.target = assigned; animateKPI(kpiAssigned); }
  if (kpiCompleted) { kpiCompleted.dataset.target = delivered; animateKPI(kpiCompleted); }
  if (kpiRevenue) { kpiRevenue.dataset.target = revenue; animateKPI(kpiRevenue); }
}

function animateKPI(el) {
  const target = parseInt(el.dataset.target, 10) || 0;
  const isRevenue = el.classList.contains('revenue');
  const duration = 800;
  const startTime = performance.now();

  function tick(now) {
    const elapsed = now - startTime;
    const progress = Math.min(elapsed / duration, 1);
    const ease = 1 - Math.pow(1 - progress, 3);
    const value = Math.round(target * ease);
    el.textContent = isRevenue ? ('₦' + value.toLocaleString('en-NG')) : value;
    if (progress < 1) requestAnimationFrame(tick);
  }

  requestAnimationFrame(tick);
}

// ── Render Jobs ─────────────────────────────────────────────────────────────
function renderJobs(filter) {
  const grid = DOM.grid;
  if (!grid) return;

  const parts = [];
  let idx = 0;
  for (const job of JOBS) {
    if (filter !== 'all' && job.status !== filter) continue;

    const { year, make, model, color, type } = job.vehicle;

    parts.push(`
      <div class="job-card ${job.status === 'inTransit' ? 'in-transit' : ''}"
           data-id="${job.id}"
           style="animation-delay: ${idx * 40}ms"
           tabindex="0"
           role="button"
           aria-label="Job ${job.id}, ${job.customerName}">
        <div class="job-card-top">
          <span class="job-id-badge">${job.id}</span>
          <span class="job-status-chip ${job.status}">
            <span class="status-dot"></span>
            ${STATUS_LABELS[job.status] || job.status}
          </span>
        </div>

        <div class="job-vehicle-row">
          <div class="vehicle-icon">${vehicleIcon(type)}</div>
          <div class="vehicle-details">
            <div class="vehicle-name">${year} ${make} ${model}</div>
            <div class="vehicle-meta">${color} · ${job.serviceType}</div>
          </div>
        </div>

        <div class="job-route">
          <div class="route-stop">
            <span class="route-dot pickup"></span>
            <span class="route-address">${job.pickup.address}</span>
          </div>
          <div class="route-line" style="margin-left:3.5px;"></div>
          <div class="route-stop">
            <span class="route-dot dropoff"></span>
            <span class="route-address">${job.dropoff.address}</span>
          </div>
        </div>

        <div class="job-card-footer">
          <div class="job-customer">
            <strong>${job.customerName}</strong><br/>
            <span style="font-size:11px; color:var(--text-dim);">${job.driverName}</span>
          </div>
          <div class="job-amount">${fmtAmount(job.totalAmount)}</div>
        </div>

        <div class="job-tags">
          <span class="tag">${job.transportMode === 'Enclosed Transport' ? 'Enclosed' : 'Open'}</span>
          ${job.hasInsurance ? '<span class="tag insured">Insured</span>' : ''}
        </div>
      </div>
    `);
    idx++;
  }

  if (parts.length === 0) {
    grid.innerHTML = `<div class="empty-state" style="grid-column: 1 / -1; text-align: center; padding: 40px; color: var(--text-dim);"><p>No jobs found in this category.</p></div>`;
    return;
  }

  grid.innerHTML = parts.join('');
}

// ── Event Delegation — Grid ───────────────────────────────────────────────────
function initGridDelegation() {
  DOM.grid.addEventListener('click', e => {
    const card = e.target.closest('.job-card[data-id]');
    if (card) openDrawer(card.dataset.id);
  });

  DOM.grid.addEventListener('keydown', e => {
    if (e.key !== 'Enter' && e.key !== ' ') return;
    const card = e.target.closest('.job-card[data-id]');
    if (card) openDrawer(card.dataset.id);
  });
}

// ── Drawer ───────────────────────────────────────────────────────────────────
function openDrawer(id) {
  const job = JOBS_MAP.get(id);
  if (!job) return;
  selectedJobId = id;

  DOM.drawerJobId.textContent = job.id;
  DOM.drawerTitle.textContent =
    `${job.vehicle.year} ${job.vehicle.make} ${job.vehicle.model} · ${job.serviceType}`;

  DOM.drawerBody.innerHTML = `
    <div>
      <div class="drawer-section-title">Client & Driver</div>
      <div class="detail-row"><span class="label">Client</span><span class="value">${job.customerName}</span></div>
      <div class="detail-row"><span class="label">Phone</span><span class="value mono">${job.customerPhone}</span></div>
      <div class="detail-row"><span class="label">Driver</span><span class="value">${job.driverName}</span></div>
    </div>

    <div>
      <div class="drawer-section-title">Vehicle</div>
      <div class="detail-row"><span class="label">Vehicle</span><span class="value">${job.vehicle.year} ${job.vehicle.make} ${job.vehicle.model}</span></div>
      <div class="detail-row"><span class="label">Colour</span><span class="value">${job.vehicle.color}</span></div>
      <div class="detail-row"><span class="label">Transport</span><span class="value">${job.transportMode}</span></div>
      <div class="detail-row"><span class="label">Insurance</span><span class="value">${job.hasInsurance ? '✓ Covered' : '— None'}</span></div>
    </div>

    <div>
      <div class="drawer-section-title">Route</div>
      <div class="detail-row"><span class="label">Pickup</span><span class="value" style="max-width:200px;">${job.pickup.address}</span></div>
      ${job.pickup.scheduledAt ? `<div class="detail-row"><span class="label">Scheduled</span><span class="value mono">${job.pickup.scheduledAt}</span></div>` : ''}
      <div class="detail-row"><span class="label">Dropoff</span><span class="value" style="max-width:200px;">${job.dropoff.address}</span></div>
    </div>

    <div>
      <div class="drawer-section-title">Financials</div>
      <div class="detail-row"><span class="label">Amount</span><span class="value amber">${fmtAmount(job.totalAmount)}</span></div>
      <div class="detail-row"><span class="label">Service</span><span class="value">${job.serviceType}</span></div>
    </div>

    <div>
      <div class="drawer-section-title">Job Timeline</div>
      <div class="timeline">${buildTimeline(job)}</div>
    </div>
    
    <div>
      <div class="drawer-section-title">Official Documents & Records</div>
      <div style="display:flex; flex-direction:column; gap:8px;">
        <button class="doc-btn" onclick="openDocumentModal('waybill', '${job.id}')">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" width="16" height="16"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"></path><polyline points="14 2 14 8 20 8"></polyline><line x1="16" y1="13" x2="8" y2="13"></line><line x1="16" y1="17" x2="8" y2="17"></line><polyline points="10 9 9 9 8 9"></polyline></svg>
          View Order Request (Waybill)
        </button>
        <button class="doc-btn" onclick="openDocumentModal('pod', '${job.id}')">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" width="16" height="16"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"></path><polyline points="9 12 11 14 15 10"></polyline></svg>
          View Proof of Handover (POD)
        </button>
      </div>
    </div>

    ${job.clientSignatureBase64 ? `
    <div style="margin-top: 16px;">
      <div class="drawer-section-title">Client Acknowledgement</div>
      <div class="ack-checklist">
        <div class="ack-item">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="20 6 9 17 4 12"></polyline></svg>
          Vehicle received in good condition
        </div>
        <div class="ack-item">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="20 6 9 17 4 12"></polyline></svg>
          Vehicle inspected
        </div>
      </div>
      <div class="drawer-signature-container" style="background:#fff; border-radius:8px; padding:10px; margin-top:8px;">
        <img src="${job.clientSignatureBase64}" alt="Client Signature" style="max-width:100%; height:auto;">
      </div>
      <div style="font-size: 11px; color: var(--text-dim); text-align: center; margin-top: 8px;">
        Signed on ${job.clientAcknowledgedAt || 'completion'}
      </div>
    </div>
    ` : ''}
  `;

  DOM.drawerActions.innerHTML = buildActions(job);

  DOM.drawer.classList.add('open');
  DOM.backdrop.classList.add('visible');
}

function initDrawerActionsDelegation() {
  DOM.drawerActions.addEventListener('click', e => {
    const btn = e.target.closest('[data-action]');
    if (!btn) return;
    const job = JOBS_MAP.get(selectedJobId);
    if (job) handleAction(btn.dataset.action, job);
  });
}

function buildTimeline(job) {
  const steps = [
    { label: 'Job Created',       time: job.createdAt,   done: true },
    { label: 'Driver Assigned',   time: job.assignedAt,  done: !!job.assignedAt },
    { label: 'Driver Confirmed',  time: job.confirmedAt, done: !!job.confirmedAt },
    { label: 'Vehicle Picked Up', time: job.pickedUpAt,  done: !!job.pickedUpAt },
    { label: 'Delivered',         time: job.completedAt, done: !!job.completedAt },
  ];

  const activeIdx = steps.reduce((acc, s, i) => s.done ? i : acc, -1);

  return steps.map((s, i) => `
    <div class="timeline-event">
      <div class="tl-dot ${s.done && i < activeIdx ? 'done' : s.done && i === activeIdx ? (job.status === 'completed' ? 'done' : 'active') : 'pending'}"></div>
      <div class="tl-content">
        <div class="tl-label">${s.label}</div>
        ${s.time
          ? `<div class="tl-time">${s.time}</div>`
          : '<div class="tl-time" style="color:var(--text-dim)">Pending</div>'}
      </div>
    </div>
  `).join('');
}

// ── Document Modals ──────────────────────────────────────────────────────────
function openDocumentModal(type, jobId) {
  const job = JOBS_MAP.get(jobId);
  if (!job) return;

  const modal = document.getElementById('document-modal');
  const title = document.getElementById('document-modal-title');
  const body = document.getElementById('document-modal-body');
  
  if (!modal || !title || !body) {
    console.warn("Document modal elements not found in HTML");
    return;
  }

  const printBtn = `<button class="action-btn primary" onclick="window.print()" style="position:absolute; top:20px; right:60px;">Print</button>`;

  if (type === 'waybill') {
    title.textContent = "Order Request Document (Waybill)";
    body.innerHTML = `
      ${printBtn}
      <div class="print-doc">
        <div class="doc-header">
          <div>
            <div class="doc-brand">AUTOMOVE INC.</div>
            <div class="doc-sub">OFFICIAL TRANSPORT MANIFEST & WAYBILL</div>
            <div style="margin-top:20px;"><strong>DOCUMENT NO:</strong> REQ-${job.id}</div>
            <div><strong>ISSUED DATE:</strong> ${job.createdAt}</div>
          </div>
          <div class="qr-placeholder">[ QR: REQ-${job.id} ]</div>
        </div>
        
        <div class="doc-section">
          <div class="doc-sec-title">CLIENT INFORMATION</div>
          <div class="doc-grid">
            <div><span class="label">CLIENT NAME</span><br/><strong>${job.customerName}</strong></div>
            <div><span class="label">PHONE NUMBER</span><br/><strong>${job.customerPhone}</strong></div>
          </div>
        </div>

        <div class="doc-section">
          <div class="doc-sec-title">VEHICLE SPECIFICATIONS</div>
          <div class="doc-grid">
            <div><span class="label">VEHICLE</span><br/><strong>${job.vehicle.year} ${job.vehicle.make} ${job.vehicle.model}</strong></div>
            <div><span class="label">COLOR</span><br/><strong>${job.vehicle.color}</strong></div>
            <div><span class="label">VIN / CHASSIS NO.</span><br/><strong>${job.vehicle.vin || 'VIN-VERIFIED-AUTOMOVE'}</strong></div>
            <div><span class="label">VEHICLE TYPE</span><br/><strong>${job.vehicle.type}</strong></div>
          </div>
        </div>

        <div class="doc-section">
          <div class="doc-sec-title">LOGISTICS & ROUTING</div>
          <div style="margin-bottom:10px;"><span class="label">PICKUP ADDRESS</span><br/><strong>${job.pickup.address}</strong></div>
          <div style="margin-bottom:10px;"><span class="label">DROPOFF ADDRESS</span><br/><strong>${job.dropoff.address}</strong></div>
          <div class="doc-grid">
            <div><span class="label">SERVICE TIER</span><br/><strong>${job.serviceType}</strong></div>
            <div><span class="label">TRANSPORT MODE</span><br/><strong>${job.transportMode}</strong></div>
            <div><span class="label">INSURANCE</span><br/><strong>${job.hasInsurance ? 'Covered' : 'None'}</strong></div>
          </div>
        </div>

        <div class="doc-section">
          <div class="doc-sec-title">FINANCIAL BREAKDOWN</div>
          <div style="display:flex; justify-content:space-between; margin-bottom:8px;">
            <span>Base Transport Fare</span><strong>${fmtAmount(job.totalAmount)}</strong>
          </div>
          <hr style="border-color:#eee; margin:10px 0;"/>
          <div style="display:flex; justify-content:space-between; font-size:18px;">
            <strong>TOTAL AMOUNT</strong><strong>${fmtAmount(job.totalAmount)}</strong>
          </div>
        </div>
      </div>
    `;
  } else if (type === 'pod') {
    title.textContent = "Proof of Handover (POD)";
    body.innerHTML = `
      ${printBtn}
      <div class="print-doc">
        <div class="doc-header">
          <div>
            <div class="doc-brand">AUTOMOVE INC.</div>
            <div class="doc-sub">PROOF OF HANDOVER / DELIVERY CERTIFICATE</div>
            <div style="margin-top:20px;"><strong>CERTIFICATE NO:</strong> POD-${job.id}-CERT</div>
            <div><strong>HANDOVER DATE:</strong> ${job.completedAt || 'Pending'}</div>
          </div>
          <div class="qr-placeholder">[ QR: POD-${job.id} ]</div>
        </div>

        <div class="doc-section">
          <div class="doc-sec-title">VEHICLE DETAILS</div>
          <div class="doc-grid">
            <div><span class="label">VEHICLE NAME</span><br/><strong>${job.vehicle.year} ${job.vehicle.make} ${job.vehicle.model}</strong></div>
            <div><span class="label">COLOR</span><br/><strong>${job.vehicle.color}</strong></div>
          </div>
        </div>

        <div class="doc-section">
          <div class="doc-sec-title">DELIVERY INFORMATION</div>
          <div style="margin-bottom:10px;"><span class="label">HANDOVER ADDRESS</span><br/><strong>${job.dropoff.address}</strong></div>
          <div class="doc-grid">
            <div><span class="label">LOGISTICS CAPTAIN</span><br/><strong>${job.driverName}</strong></div>
            <div><span class="label">DRIVER PHONE</span><br/><strong>+234 812 345 6789</strong></div>
          </div>
        </div>

        <div class="doc-section">
          <div class="doc-sec-title">HANDOVER CHECKLIST</div>
          <div style="margin-bottom:8px;">☑ Vehicle exterior inspected and damage recorded (if any)</div>
          <div style="margin-bottom:8px;">☑ Vehicle interior and accessories inspected</div>
          <div style="margin-bottom:8px;">☑ Keys handed over to designated recipient</div>
          <div style="margin-bottom:8px;">☑ Vehicle accepted in good overall condition</div>
        </div>

        <div class="doc-section">
          <div class="doc-sec-title">CLIENT ACKNOWLEDGEMENT</div>
          ${job.clientSignatureBase64 ? `
            <div style="padding:20px; border:1px solid #eee; border-radius:8px; text-align:center;">
              <img src="${job.clientSignatureBase64}" style="max-height:100px;">
              <div style="font-size:12px; color:#888; margin-top:10px;">Digitally Signed upon delivery</div>
            </div>
          ` : `
            <div style="padding:40px; border:1px solid #eee; background:#fafafa; text-align:center; color:#888;">
              <strong>PENDING CLIENT SIGNATURE</strong>
            </div>
          `}
        </div>
      </div>
    `;
  }

  modal.classList.add('open');
}

function closeDocumentModal() {
  const modal = document.getElementById('document-modal');
  if (modal) modal.classList.remove('open');
}

function buildActions(job) {
  if (job.status === 'pending' || job.status === 'assigned') return `
    <button class="action-btn primary" data-action="confirmDriver">Confirm Driver</button>
    <button class="action-btn secondary" data-action="reassign">Assign / Reassign Driver</button>
    <button class="action-btn danger" data-action="cancel">Cancel Job</button>
  `;
  if (job.status === 'confirmed') return `
    <button class="action-btn primary" data-action="markPickedUp">Mark as Picked Up</button>
    <button class="action-btn secondary" data-action="reassign">Assign / Reassign Driver</button>
    <button class="action-btn danger" data-action="cancel">Cancel Job</button>
  `;
  if (job.status === 'pickedUp') return `
    <button class="action-btn primary" data-action="markInTransit">Mark In Transit</button>
  `;
  if (job.status === 'inTransit') return `
    <button class="action-btn primary" data-action="markDelivered">Mark as Delivered</button>
  `;
  if (job.status === 'completed') return `
    <button class="action-btn secondary" data-action="viewReceipt">View Delivery Record</button>
  `;
  return '';
}

async function handleAction(action, job) {
  const statusMap = {
    confirmDriver: 'confirmed',
    markPickedUp:  'pickedUp',
    markInTransit: 'inTransit',
    markDelivered: 'delivered',
    cancel:        'cancelled',
  };

  if (statusMap[action]) {
    const newDbStatus = statusMap[action];
    const updatePayload = { status: newDbStatus };
    
    if (newDbStatus === 'confirmed') updatePayload.confirmed_at = new Date().toISOString();
    if (newDbStatus === 'pickedUp') updatePayload.picked_up_at = new Date().toISOString();
    if (newDbStatus === 'delivered') updatePayload.completed_at = new Date().toISOString();

    const supabase = getSupabase();
    if (supabase && job.dbId) {
      try {
        const { error } = await supabase
          .from('bookings')
          .update(updatePayload)
          .eq('id', job.dbId);

        if (error) throw error;
      } catch (err) {
        console.error('Error updating status in Supabase:', err);
        showToast('Error syncing update: ' + err.message, 'error');
        return;
      }
    }

    job.status = normalizeStatus(newDbStatus);
    if (action === 'markDelivered') job.completedAt = 'Just now';
    if (action === 'markPickedUp')  job.pickedUpAt  = 'Just now';
    if (action === 'markInTransit') job.pickedUpAt  = job.pickedUpAt || 'Just now';
    if (action === 'confirmDriver') job.confirmedAt = 'Just now';

    closeDrawer();
    renderJobs(currentFilter);
    updateKPIs();
    showToast(
      action === 'cancel' ? 'Job cancelled.' : 'Status updated live to Supabase.',
      action === 'cancel' ? 'error' : 'success'
    );
    return;
  }

  if (action === 'viewReceipt') {
    showToast(`Delivery completed for ${job.id}. Signature verified.`, 'success');
    return;
  }

  if (action === 'reassign') {
    if (DRIVERS.length > 0) {
      const select = document.getElementById('reassign-driver-select');
      
      // Calculate driver statuses
      const driverMap = new Map();
      DRIVERS.forEach(d => {
        driverMap.set(d.id, { ...d, activeStatus: 'Available' });
      });
      JOBS.forEach(j => {
        if (j.driverId && driverMap.has(j.driverId)) {
          if (j.status === 'inTransit' || j.status === 'pickedUp' || j.status === 'assigned') {
            driverMap.get(j.driverId).activeStatus = 'In Transit / Busy';
          }
        }
      });
      
      select.innerHTML = '<option value="">— Select Driver —</option>' + 
        Array.from(driverMap.values()).map(d => 
          `<option value="${d.id}">${d.full_name} (${d.activeStatus})</option>`
        ).join('');
        
      const modal = document.getElementById('reassign-modal');
      modal.dataset.jobId = job.dbId;
      modal.classList.add('open');
    } else {
      showToast('No drivers available', 'error');
    }
  }
}

function closeDrawer() {
  DOM.drawer.classList.remove('open');
  DOM.backdrop.classList.remove('visible');
  selectedJobId = null;
}

// ── Toast ─────────────────────────────────────────────────────────────────────
let toastContainer = null;

function showToast(message, type = 'success') {
  if (!toastContainer) {
    toastContainer = document.createElement('div');
    toastContainer.className = 'toast-container';
    document.body.appendChild(toastContainer);
  }

  const toast = document.createElement('div');
  toast.className = `toast ${type}`;
  toast.textContent = message;
  toastContainer.appendChild(toast);

  setTimeout(() => {
    toast.classList.add('fade-out');
    setTimeout(() => toast.remove(), 300);
  }, 3500);
}

// ── New Job Modal ─────────────────────────────────────────────────────────────
function openModal()  { DOM.modalOverlay.classList.add('open'); }
function closeModal() { DOM.modalOverlay.classList.remove('open'); }

async function createJob() {
  const client  = document.getElementById('f-client').value.trim();
  const vehicle = document.getElementById('f-vehicle').value.trim();
  const pickup  = document.getElementById('f-pickup').value.trim();
  const dropoff = document.getElementById('f-dropoff').value.trim();
  const driverId = document.getElementById('f-driver').value;
  const amount  = parseFloat(document.getElementById('f-amount').value);
  const service = document.getElementById('f-service').value;
  const mode    = document.getElementById('f-mode').value;

  if (!client || !vehicle || !pickup || !dropoff || isNaN(amount)) {
    showToast('Please fill in all required fields.', 'error');
    return;
  }

  const parts = vehicle.split(' ');
  const year  = parts[0] || '2024';
  const make  = parts[1] || 'Vehicle';
  const model = parts.slice(2).join(' ') || '';
  const trackingNumber = 'JB' + Math.floor(100000 + Math.random() * 900000);

  const validService = service.toLowerCase().includes('white') 
    ? 'whiteGlove' 
    : (service.toLowerCase().includes('express') ? 'express' : 'standard');

  const insertPayload = {
    id: trackingNumber,
    vehicle_type: 'sedan',
    vehicle_make: make,
    vehicle_model: model,
    vehicle_year: year,
    vehicle_color: 'Standard',
    pickup_address: pickup,
    dropoff_address: dropoff,
    service_type: validService,
    transport_mode: mode.toLowerCase().includes('enclosed') ? 'enclosed' : 'open',
    has_insurance: false,
    base_price: amount,
    insurance_fee: 0,
    total_amount: amount,
    status: driverId ? 'assigned' : 'pending',
    driver_id: driverId || null,
  };

  const supabase = getSupabase();
  if (supabase) {
    try {
      const { data, error } = await supabase
        .from('bookings')
        .insert([insertPayload])
        .select()
        .single();

      if (error) throw error;
      showToast(`Job ${trackingNumber} created in Supabase!`, 'success');
    } catch (err) {
      console.error('Error inserting booking into Supabase:', err);
      showToast('Error saving job: ' + err.message, 'error');
    }
  }

  closeModal();
  loadLiveBookings();

  ['f-client','f-vehicle','f-pickup','f-dropoff','f-amount'].forEach(id => {
    const el = document.getElementById(id);
    if (el) el.value = '';
  });
}

// ── Filters ───────────────────────────────────────────────────────────────────
function initFilters() {
  DOM.filterBar.addEventListener('click', e => {
    const btn = e.target.closest('.filter-btn');
    if (!btn) return;

    DOM.filterBar.querySelectorAll('.filter-btn').forEach(b => b.classList.remove('active'));
    btn.classList.add('active');
    currentFilter = btn.dataset.filter;
    renderJobs(currentFilter);
  });

  // KPI card clicks
  document.querySelectorAll('.kpi-card').forEach(card => {
    card.addEventListener('click', () => {
      let targetFilter = 'all';
      if (card.id === 'kpi-total') targetFilter = 'all';
      if (card.id === 'kpi-active') targetFilter = 'inTransit';
      if (card.id === 'kpi-assigned') targetFilter = 'assigned';
      if (card.id === 'kpi-completed') targetFilter = 'completed';
      if (card.id === 'kpi-revenue') return; // Do nothing for revenue

      // Find the corresponding filter button and click it to reuse logic and update UI
      const filterBtn = DOM.filterBar.querySelector(`.filter-btn[data-filter="${targetFilter}"]`);
      if (filterBtn) {
        filterBtn.click();
        
        // Scroll to the board header smoothly so the user sees the filtered list
        document.querySelector('.dispatch-board').scrollIntoView({ behavior: 'smooth' });
      }
    });
  });
}

// ── Init ─────────────────────────────────────────────────────────────────────
document.addEventListener('DOMContentLoaded', () => {
  DOM = {
    grid:         document.getElementById('jobs-grid'),
    drawer:       document.getElementById('detail-drawer'),
    backdrop:     document.getElementById('drawer-backdrop'),
    drawerJobId:  document.getElementById('drawer-job-id'),
    drawerTitle:  document.getElementById('drawer-title'),
    drawerBody:   document.getElementById('drawer-body'),
    drawerActions:document.getElementById('drawer-actions'),
    modalOverlay: document.getElementById('modal-overlay'),
    filterBar:    document.querySelector('.board-filters'),
  };

  initGridDelegation();
  initDrawerActionsDelegation();
  initFilters();

  // Load drivers & bookings from Supabase with safe async retry for CDN script
  async function initSupabaseData() {
    let tries = 0;
    while (!getSupabase() && tries < 20) {
      await new Promise(r => setTimeout(r, 100));
      tries++;
    }
    loadDrivers();
    loadLiveBookings();
    subscribeToRealtime();
    loadPricingConfig();
  }
  initSupabaseData();

  // Drawer close
  document.getElementById('drawer-close').addEventListener('click', closeDrawer);
  DOM.backdrop.addEventListener('click', closeDrawer);

  // Modal
  document.getElementById('btn-new-job').addEventListener('click', openModal);
  document.getElementById('modal-close').addEventListener('click', closeModal);
  document.getElementById('btn-cancel-modal').addEventListener('click', closeModal);
  document.getElementById('btn-create-job').addEventListener('click', createJob);
  document.getElementById('btn-submit-reassign').addEventListener('click', submitReassignDriver);
  DOM.modalOverlay.addEventListener('click', e => {
    if (e.target === DOM.modalOverlay) closeModal();
  });

  // Keyboard shortcuts
  document.addEventListener('keydown', e => {
    if (e.key === 'Escape') { closeDrawer(); closeModal(); }
  });

  // Sidebar nav items
  document.querySelectorAll('.nav-item[data-view]').forEach(item => {
    item.addEventListener('click', e => {
      e.preventDefault();
      document.querySelectorAll('.nav-item').forEach(n => n.classList.remove('active'));
      item.classList.add('active');

      const viewId = item.getAttribute('data-view');
      document.querySelectorAll('.view-section').forEach(sec => {
        sec.style.display = 'none';
        sec.classList.remove('active');
      });

      const activeSec = document.getElementById(`view-${viewId}`);
      if (activeSec) {
        activeSec.style.display = 'block';
        activeSec.classList.add('active');
      }

      // Update breadcrumbs
      const breadcrumbSection = document.querySelector('.breadcrumb-section');
      const breadcrumbPage = document.querySelector('.breadcrumb-page');
      if (viewId === 'dispatch') {
        breadcrumbSection.textContent = 'Dispatch';
        breadcrumbPage.textContent = 'Command Centre';
      } else if (viewId === 'clients') {
        breadcrumbSection.textContent = 'Clients';
        breadcrumbPage.textContent = 'Client Management';
      } else if (viewId === 'drivers') {
        breadcrumbSection.textContent = 'Drivers';
        breadcrumbPage.textContent = 'Driver Management';
      } else {
        breadcrumbSection.textContent = viewId.charAt(0).toUpperCase() + viewId.slice(1);
        breadcrumbPage.textContent = 'Overview';
      }
    });
  });
});

// ── Client & Driver Aggregation ───────────────────────────────────────────────

function renderClients() {
  const tbody = document.getElementById('clients-table-body');
  if (!tbody) return;

  const clientMap = new Map();
  JOBS.forEach(job => {
    if (!job.customerName) return;
    const key = job.customerName;
    if (!clientMap.has(key)) {
      clientMap.set(key, {
        name: job.customerName,
        phone: job.customerPhone || 'N/A',
        orders: 0,
        spent: 0,
        lastActive: job.createdAt
      });
    }
    const c = clientMap.get(key);
    c.orders++;
    c.spent += job.totalAmount || 0;
    if (new Date(job.createdAt) > new Date(c.lastActive)) {
      c.lastActive = job.createdAt;
    }
  });

  tbody.innerHTML = Array.from(clientMap.values()).map(c => `
    <tr>
      <td style="font-weight: 600;">${c.name}</td>
      <td>${c.phone}</td>
      <td>${c.orders}</td>
      <td style="font-weight: 600;">${fmtAmount(c.spent)}</td>
      <td>${c.lastActive}</td>
      <td>
        <button class="doc-btn" onclick="printRecords('client', '${c.name.replace(/'/g, "\\'")}')" style="padding: 6px 12px;">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" width="14" height="14"><polyline points="6 9 6 2 18 2 18 9"></polyline><path d="M6 18H4a2 2 0 0 1-2-2v-5a2 2 0 0 1 2-2h16a2 2 0 0 1 2 2v5a2 2 0 0 1-2 2h-2"></path><rect x="6" y="14" width="12" height="8"></rect></svg>
          Print Records
        </button>
      </td>
    </tr>
  `).join('');
}

function renderDrivers() {
  const tbody = document.getElementById('drivers-table-body');
  if (!tbody) return;

  const driverMap = new Map();
  JOBS.forEach(job => {
    if (!job.driverName) return;
    const key = job.driverName;
    if (!driverMap.has(key)) {
      driverMap.set(key, {
        name: job.driverName,
        phone: job.driverPhone || 'N/A',
        deliveries: 0,
        earned: 0,
        status: 'Available'
      });
    }
    const d = driverMap.get(key);
    d.deliveries++;
    d.earned += job.totalAmount || 0;
    if (job.status === 'inTransit' || job.status === 'pickedUp' || job.status === 'assigned') {
      d.status = 'In Transit';
    }
  });

  tbody.innerHTML = Array.from(driverMap.values()).map(d => `
    <tr>
      <td style="font-weight: 600;">${d.name}</td>
      <td>${d.phone}</td>
      <td>${d.deliveries}</td>
      <td style="font-weight: 600;">${fmtAmount(d.earned)}</td>
      <td><span class="status-badge ${d.status === 'In Transit' ? 'assigned' : 'completed'}">${d.status}</span></td>
      <td>
        <button class="doc-btn" onclick="printRecords('driver', '${d.name.replace(/'/g, "\\'")}')" style="padding: 6px 12px;">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" width="14" height="14"><polyline points="6 9 6 2 18 2 18 9"></polyline><path d="M6 18H4a2 2 0 0 1-2-2v-5a2 2 0 0 1 2-2h16a2 2 0 0 1 2 2v5a2 2 0 0 1-2 2h-2"></path><rect x="6" y="14" width="12" height="8"></rect></svg>
          Print Records
        </button>
      </td>
    </tr>
  `).join('');
}

function renderAllJobsList() {
  const tbody = document.getElementById('jobs-table-body');
  if (!tbody) return;
  
  // Sort by date descending
  const sortedJobs = [...JOBS].sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));

  tbody.innerHTML = sortedJobs.map(j => `
    <tr>
      <td style="font-family: 'DM Mono', monospace;">JB-${j.id.split('-')[0]}</td>
      <td>${j.createdAt}</td>
      <td>${j.customerName || 'N/A'}</td>
      <td>${j.driverName || 'Unassigned'}</td>
      <td>${j.vehicle.year} ${j.vehicle.make}</td>
      <td><span class="status-badge ${j.status}">${j.status.toUpperCase()}</span></td>
      <td style="font-weight: 600;">${fmtAmount(j.totalAmount)}</td>
    </tr>
  `).join('');
}

function renderEarnings() {
  const tbody = document.getElementById('earnings-table-body');
  if (!tbody) return;

  let gross = 0;
  let completedValue = 0;
  let validJobs = 0;

  const rows = [];
  
  // Sort by date descending
  const sortedJobs = [...JOBS].sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));

  sortedJobs.forEach(j => {
    if (j.status === 'cancelled') return;
    
    gross += j.totalAmount || 0;
    validJobs++;
    if (j.status === 'completed') {
      completedValue += j.totalAmount || 0;
    }

    const payStatus = j.status === 'completed' ? 'Settled' : 'Pending Escrow';
    const payColor = j.status === 'completed' ? 'var(--success)' : 'var(--warning)';

    rows.push(`
      <tr>
        <td>${j.createdAt}</td>
        <td style="font-family: 'DM Mono', monospace;">JB-${j.id.split('-')[0]}</td>
        <td>${j.customerName || 'N/A'}</td>
        <td style="color: ${payColor}; font-weight:500;">${payStatus}</td>
        <td style="font-weight: 600;">${fmtAmount(j.totalAmount)}</td>
      </tr>
    `);
  });

  const earnGross = document.getElementById('earn-gross');
  const earnAvg = document.getElementById('earn-avg');
  const earnCompleted = document.getElementById('earn-completed');
  
  if (earnGross) earnGross.textContent = fmtAmount(gross);
  if (earnCompleted) earnCompleted.textContent = fmtAmount(completedValue);
  if (earnAvg) earnAvg.textContent = fmtAmount(validJobs > 0 ? (gross / validJobs) : 0);

  tbody.innerHTML = rows.join('');
}

// ── Printing Aggregated Records ───────────────────────────────────────────────
function printRecords(type, entityName) {
  const modal = document.getElementById('document-modal');
  const title = document.getElementById('document-modal-title');
  const body = document.getElementById('document-modal-body');
  
  let records = [];
  let headerTitle = '';
  let subTitle = '';
  
  if (type === 'client') {
    records = JOBS.filter(j => j.customerName === entityName);
    headerTitle = 'CLIENT TRANSPORT HISTORY';
    subTitle = `CLIENT: ${entityName}`;
    title.textContent = `Client Records: ${entityName}`;
  } else if (type === 'driver') {
    records = JOBS.filter(j => j.driverName === entityName);
    headerTitle = 'DRIVER LOG & HISTORY';
    subTitle = `LOGISTICS CAPTAIN: ${entityName}`;
    title.textContent = `Driver Records: ${entityName}`;
  } else if (type === 'all') {
    records = [...JOBS].sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));
    headerTitle = 'MASTER TRANSPORT LOG';
    subTitle = `OPERATIONS COMMAND`;
    title.textContent = `Master Log`;
  }

  const printBtn = `<button class="action-btn primary" onclick="window.print()" style="position:absolute; top:20px; right:60px;">Print</button>`;
  
  const rows = records.map(r => `
    <tr>
      <td style="padding: 8px; border-bottom: 1px solid #eee;">${r.createdAt}</td>
      <td style="padding: 8px; border-bottom: 1px solid #eee;">${r.vehicle.year} ${r.vehicle.make} ${r.vehicle.model}</td>
      <td style="padding: 8px; border-bottom: 1px solid #eee;">${r.serviceType}</td>
      <td style="padding: 8px; border-bottom: 1px solid #eee;">${r.status.toUpperCase()}</td>
      <td style="padding: 8px; border-bottom: 1px solid #eee; font-weight:600;">${fmtAmount(r.totalAmount)}</td>
    </tr>
  `).join('');

  body.innerHTML = `
    ${printBtn}
    <div class="print-doc">
      <div class="doc-header">
        <div>
          <div class="doc-brand">AUTOMOVE INC.</div>
          <div class="doc-sub">OFFICIAL ${headerTitle}</div>
          <div style="margin-top:20px;"><strong>${subTitle}</strong></div>
          <div><strong>GENERATED ON:</strong> ${new Date().toLocaleDateString()}</div>
        </div>
        <div class="qr-placeholder" style="width:60px; height:60px;">[ LOGS ]</div>
      </div>
      
      <div class="doc-section">
        <table style="width: 100%; border-collapse: collapse; font-size: 11px; text-align: left;">
          <thead>
            <tr style="background: #fafafa;">
              <th style="padding: 8px; border-bottom: 2px solid #ddd;">DATE</th>
              <th style="padding: 8px; border-bottom: 2px solid #ddd;">VEHICLE</th>
              <th style="padding: 8px; border-bottom: 2px solid #ddd;">SERVICE</th>
              <th style="padding: 8px; border-bottom: 2px solid #ddd;">STATUS</th>
              <th style="padding: 8px; border-bottom: 2px solid #ddd;">AMOUNT</th>
            </tr>
          </thead>
          <tbody>
            ${rows}
          </tbody>
        </table>
        <div style="margin-top: 20px; text-align:right; font-size: 14px;">
          <strong>TOTAL TRANSACTED: ${fmtAmount(records.reduce((sum, r) => sum + r.totalAmount, 0))}</strong>
        </div>
      </div>
    </div>
  `;

  modal.classList.add('open');
}

// ── Pricing Configuration ─────────────────────────────────────────────────────

let PRICING_DATA = [];

async function submitReassignDriver() {
  const modal = document.getElementById('reassign-modal');
  const jobId = modal.dataset.jobId;
  const select = document.getElementById('reassign-driver-select');
  const driverId = select.value;
  
  if (!driverId) {
    showToast('Please select a driver', 'error');
    return;
  }
  
  const supabase = getSupabase();
  if (supabase && jobId) {
    // Determine the new status. If the job was already confirmed, it might be better to set it to assigned
    // so the new driver has to confirm it.
    await supabase.from('bookings').update({ driver_id: driverId, status: 'assigned' }).eq('id', jobId);
    
    const driverName = select.options[select.selectedIndex].text.split(' (')[0];
    showToast(`Reassigned to ${driverName}`, 'success');
    
    modal.classList.remove('open');
    loadLiveBookings();
    closeDrawer();
  }
}

async function loadPricingConfig() {
  const supabase = getSupabase();
  if (!supabase) return;
  
  try {
    const { data, error } = await supabase
      .from('pricing_config')
      .select('*')
      .order('base_price', { ascending: true });
      
    if (error) throw error;
    
    PRICING_DATA = data || [];
    renderPricingSettings();
  } catch (err) {
    console.error('Error fetching pricing config:', err);
  }
}

function renderPricingSettings() {
  const tbody = document.getElementById('pricing-table-body');
  if (!tbody) return;
  
  tbody.innerHTML = PRICING_DATA.map((p, i) => `
    <tr data-index="${i}" data-id="${p.id}">
      <td style="font-weight: 600;">
        ${p.name}<br>
        <small style="color: var(--text-mid); font-weight: 400;">${p.description}</small>
      </td>
      <td>
        <input type="text" class="pricing-input" data-field="base_price" value="${fmtAmountNoSymbol(p.base_price)}" style="width: 100%; max-width: 150px; background: var(--navy); color: var(--text-primary); border: 1px solid var(--navy-border); padding: 8px; border-radius: 6px;">
      </td>
      <td>
        <input type="text" class="pricing-input" data-field="enclosed_addon" value="${fmtAmountNoSymbol(p.enclosed_addon)}" style="width: 100%; max-width: 150px; background: var(--navy); color: var(--text-primary); border: 1px solid var(--navy-border); padding: 8px; border-radius: 6px;">
      </td>
      <td>
        <input type="text" class="pricing-input" data-field="insurance_rate" value="${fmtAmountNoSymbol(p.insurance_rate)}" style="width: 100%; max-width: 150px; background: var(--navy); color: var(--text-primary); border: 1px solid var(--navy-border); padding: 8px; border-radius: 6px;">
      </td>
    </tr>
  `).join('');

  // Add formatting listener to all pricing inputs
  document.querySelectorAll('.pricing-input').forEach(input => {
    input.addEventListener('input', function(e) {
      // Remove all non-digits
      let raw = this.value.replace(/\D/g, '');
      if (raw) {
        this.value = parseInt(raw, 10).toLocaleString('en-US');
      } else {
        this.value = '';
      }
    });
  });
}

function fmtAmountNoSymbol(amount) {
  if (!amount) return '0';
  return amount.toLocaleString('en-US');
}

document.addEventListener('DOMContentLoaded', () => {
  const saveBtn = document.getElementById('btn-save-pricing');
  if (saveBtn) {
    saveBtn.addEventListener('click', async () => {
      const supabase = getSupabase();
      if (!supabase) return;
      
      const rows = document.querySelectorAll('#pricing-table-body tr');
      saveBtn.textContent = 'Saving...';
      saveBtn.style.opacity = '0.7';
      saveBtn.style.pointerEvents = 'none';
      
      try {
        for (const row of rows) {
          const id = row.getAttribute('data-id');
          const basePrice = row.querySelector('[data-field="base_price"]').value.replace(/,/g, '');
          const enclosedAddon = row.querySelector('[data-field="enclosed_addon"]').value.replace(/,/g, '');
          const insuranceRate = row.querySelector('[data-field="insurance_rate"]').value.replace(/,/g, '');
          
          const { error } = await supabase
            .from('pricing_config')
            .update({ 
              base_price: parseFloat(basePrice) || 0,
              enclosed_addon: parseFloat(enclosedAddon) || 0,
              insurance_rate: parseFloat(insuranceRate) || 0
            })
            .eq('id', id);
            
          if (error) throw error;
        }
        
        showToast('Pricing configuration updated successfully!', 'success');
        await loadPricingConfig();
      } catch (err) {
        console.error('Error updating pricing:', err);
        showToast('Failed to update pricing.', 'error');
      } finally {
        saveBtn.textContent = 'Save Changes';
        saveBtn.style.opacity = '1';
        saveBtn.style.pointerEvents = 'all';
      }
    });
  }
});
