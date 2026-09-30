import React, { useEffect, useMemo, useRef, useState } from 'react';
import {
  APIProvider,
  AdvancedMarker,
  ColorScheme,
  InfoWindow,
  Map as GoogleMap,
  useAdvancedMarkerRef,
  useMap,
} from '@vis.gl/react-google-maps';
import { Maximize2, Phone, Truck } from 'lucide-react';
import { useAppContext } from '../context/AppContext';

const API_KEY = import.meta.env.VITE_GOOGLE_MAPS_API_KEY;
// Advanced markers need a map ID; Google's demo ID works until one is created
const MAP_ID = import.meta.env.VITE_GOOGLE_MAP_ID || 'DEMO_MAP_ID';
const ABUJA = { lat: 9.0765, lng: 7.3986 };
// Same as the client app: after this long a position is no longer live
const STALE_AFTER_MS = 2 * 60 * 1000;

// Statuses where the driver has the job and reports their position, most urgent first
const STATUSES = {
  inTransit: { label: 'In transit', color: '#C9913A', ink: '#080E1C' },
  pickedUp: { label: 'Picked up', color: '#3B82F6', ink: '#FFFFFF' },
  confirmed: { label: 'Heading to pickup', color: '#F0F4FF', ink: '#080E1C' },
};
const URGENCY = Object.keys(STATUSES);
const STALE_LOOK = { color: '#3D5070', ink: '#B4C0D3' };

const timeOf = (at) => {
  const t = at ? new Date(at).getTime() : NaN;
  return Number.isFinite(t) ? t : null;
};

function formatAgo(ms) {
  const s = Math.max(1, Math.round(ms / 1000));
  if (s < 60) return `${s}s ago`;
  const m = Math.floor(s / 60);
  if (m < 60) return `${m} min ago`;
  const h = Math.floor(m / 60);
  if (h < 24) return `${h} h ago`;
  return `${Math.floor(h / 24)} d ago`;
}

function freshness(at, now) {
  const t = timeOf(at);
  if (t == null) return { live: false, label: 'Time unknown' };
  const age = now - t;
  return age < STALE_AFTER_MS
    ? { live: true, label: `Live · ${formatAgo(age)}` }
    : { live: false, label: `Last seen ${formatAgo(age)}` };
}

const vehicleName = (job) =>
  [job.vehicle.year, job.vehicle.make, job.vehicle.model].filter(Boolean).join(' ');

const byUrgency = (a, b) => URGENCY.indexOf(a.status) - URGENCY.indexOf(b.status);

const hasPoint = (p) => p && p.lat != null && p.lng != null;

/**
 * Active jobs grouped by driver, since a driver carrying several vehicles is
 * in one place. The group takes the driver's most recent reported position.
 */
function groupByDriver(jobs) {
  const groups = new Map();
  for (const job of jobs) {
    const key = job.driverId || job.id;
    const group = groups.get(key) ?? {
      key,
      driverName: job.driverName,
      driverPhone: job.driverPhone,
      jobs: [],
      location: null,
    };
    group.jobs.push(job);
    const loc = job.driverLocation;
    if (loc && (!group.location || (timeOf(loc.at) ?? 0) > (timeOf(group.location.at) ?? 0))) {
      group.location = loc;
    }
    groups.set(key, group);
  }
  return [...groups.values()]
    .map((g) => {
      const sorted = [...g.jobs].sort(byUrgency);
      return { ...g, jobs: sorted, status: sorted[0].status };
    })
    .sort((a, b) => byUrgency(a, b) || a.driverName.localeCompare(b.driverName));
}

/** Re-renders every [ms] so "ago" labels and stale colours stay current. */
function useNow(ms) {
  const [now, setNow] = useState(() => Date.now());
  useEffect(() => {
    const id = setInterval(() => setNow(Date.now()), ms);
    return () => clearInterval(id);
  }, [ms]);
  return now;
}

function fitTo(map, points) {
  if (!map || points.length === 0) return;
  if (points.length === 1) {
    map.panTo(points[0]);
    map.setZoom(14);
    return;
  }
  const lats = points.map((p) => p.lat);
  const lngs = points.map((p) => p.lng);
  map.fitBounds(
    { north: Math.max(...lats), south: Math.min(...lats), east: Math.max(...lngs), west: Math.min(...lngs) },
    80,
  );
}

export function FleetMapView() {
  const [authFailed, setAuthFailed] = useState(false);

  useEffect(() => {
    // Google calls this when it rejects the key (e.g. the Maps JavaScript API isn't enabled)
    window.gm_authFailure = () => setAuthFailed(true);
    return () => {
      delete window.gm_authFailure;
    };
  }, []);

  if (!API_KEY || authFailed) {
    return (
      <div className="absolute inset-0 grid place-items-center p-8">
        <div className="max-w-md bg-navy-mid border border-navy-border rounded-xl p-6 text-center">
          <h2 className="font-syne text-[18px] font-bold text-text-primary mb-2">Map unavailable</h2>
          <p className="text-[13px] text-text-mid leading-relaxed">
            {API_KEY
              ? 'Google rejected the map key. Enable the Maps JavaScript API in Google Cloud and allow it on this key, then reload.'
              : 'Add VITE_GOOGLE_MAPS_API_KEY to admin_dashboard/.env and restart the dashboard. The key needs the Maps JavaScript API enabled.'}
          </p>
        </div>
      </div>
    );
  }

  return (
    <APIProvider apiKey={API_KEY}>
      <FleetMap />
    </APIProvider>
  );
}

function FleetMap() {
  const { jobs, setSelectedJobId } = useAppContext();
  const map = useMap();
  const now = useNow(5000);
  // The open driver marker and which of their vehicles has its stops shown
  const [selection, setSelection] = useState(null);
  const fitted = useRef(false);

  const groups = useMemo(
    () => groupByDriver(jobs.filter((j) => URGENCY.includes(j.status))),
    [jobs],
  );
  const located = groups.filter((g) => g.location);
  const waiting = groups.filter((g) => !g.location);

  const selectedGroup = selection ? located.find((g) => g.key === selection.key) : null;
  const selectedJob = selectedGroup?.jobs.find((j) => j.id === selection.jobId) ?? null;

  const counts = located.reduce(
    (acc, g) => {
      const live = freshness(g.location.at, now).live;
      acc[live ? 'live' : 'stale'] += g.jobs.length;
      return acc;
    },
    { live: 0, stale: 0 },
  );
  const vehicleCount = groups.reduce((n, g) => n + g.jobs.length, 0);
  const waitingCount = vehicleCount - counts.live - counts.stale;

  const fitAll = () => fitTo(map, located.map((g) => g.location));

  // Frame every vehicle once, when the first positions arrive; later refreshes leave the camera alone
  useEffect(() => {
    if (!map || fitted.current || located.length === 0) return;
    fitted.current = true;
    fitTo(map, located.map((g) => g.location));
  }, [map, located]);

  const focusJob = (group, job) => {
    setSelection({ key: group.key, jobId: job.id });
    if (!group.location) return;
    const stops = [job.status === 'confirmed' ? job.pickup : null, job.dropoff].filter(hasPoint);
    fitTo(map, [group.location, ...stops]);
  };

  return (
    <div className="absolute inset-0 flex">
      <aside className="w-[340px] shrink-0 bg-navy-mid border-r border-navy-border overflow-y-auto scrollbar-thin">
        <div className="p-5 border-b border-navy-border">
          <h2 className="font-syne text-[16px] font-bold text-text-primary">Vehicles on the move</h2>
          <p className="text-[12px] text-text-mid mt-1">
            {vehicleCount} {vehicleCount === 1 ? 'vehicle' : 'vehicles'} · {counts.live} live
            {counts.stale > 0 && ` · ${counts.stale} not updated recently`}
            {waitingCount > 0 && ` · ${waitingCount} no location`}
          </p>
          <div className="flex flex-wrap gap-x-3 gap-y-1.5 mt-3">
            {URGENCY.map((s) => (
              <Legend key={s} color={STATUSES[s].color} label={STATUSES[s].label} />
            ))}
            <Legend color={STALE_LOOK.color} label="Over 2 min old" />
          </div>
        </div>

        {groups.length === 0 && (
          <p className="p-5 text-[13px] text-text-dim">No vehicles are being moved right now.</p>
        )}

        {located.map((group) => (
          <DriverRow
            key={group.key}
            group={group}
            now={now}
            selectedJobId={selection?.key === group.key ? selection.jobId : null}
            onSelectJob={(job) => focusJob(group, job)}
          />
        ))}

        {waiting.length > 0 && (
          <div className="px-5 pt-5 pb-2">
            <h3 className="text-[11px] font-semibold uppercase tracking-wider text-text-dim">Waiting for location</h3>
            <p className="text-[11px] text-text-dim mt-1">
              The driver app hasn't sent a position yet. It may be closed or have location turned off.
            </p>
          </div>
        )}
        {waiting.map((group) => (
          <DriverRow
            key={group.key}
            group={group}
            now={now}
            selectedJobId={null}
            onSelectJob={(job) => setSelectedJobId(job.id)}
          />
        ))}
      </aside>

      <div className="flex-1 relative">
        <GoogleMap
          mapId={MAP_ID}
          colorScheme={ColorScheme.DARK}
          defaultCenter={ABUJA}
          defaultZoom={11}
          gestureHandling="greedy"
          clickableIcons={false}
          disableDefaultUI
          zoomControl
          onClick={() => setSelection(null)}
          style={{ width: '100%', height: '100%' }}
        >
          {located.map((group) => (
            <DriverMarker
              key={group.key}
              group={group}
              now={now}
              selected={selectedGroup?.key === group.key}
              selectedJobId={selectedGroup?.key === group.key ? selection.jobId : null}
              onSelect={() => setSelection({ key: group.key, jobId: group.jobs[0].id })}
              onSelectJob={(job) => focusJob(group, job)}
              onClose={() => setSelection(null)}
              onOpenJob={(job) => setSelectedJobId(job.id)}
            />
          ))}
          {selectedJob && hasPoint(selectedJob.pickup) && (
            <StopMarker position={selectedJob.pickup} letter="P" title={`Pickup: ${selectedJob.pickup.address}`} />
          )}
          {selectedJob && hasPoint(selectedJob.dropoff) && (
            <StopMarker position={selectedJob.dropoff} letter="D" title={`Drop-off: ${selectedJob.dropoff.address}`} />
          )}
        </GoogleMap>

        {located.length > 0 && (
          <button
            type="button"
            onClick={fitAll}
            className="absolute top-4 right-4 flex items-center gap-2 px-3.5 py-2 rounded-[10px] bg-navy-mid/95 border border-navy-border text-[12px] font-medium text-text-primary hover:bg-navy-light transition-colors cursor-pointer"
          >
            <Maximize2 size={14} /> Fit all
          </button>
        )}
      </div>
    </div>
  );
}

function Legend({ color, label }) {
  return (
    <span className="flex items-center gap-1.5 text-[11px] text-text-mid">
      <span className="w-2.5 h-2.5 rounded-full" style={{ background: color }} />
      {label}
    </span>
  );
}

function DriverRow({ group, now, selectedJobId, onSelectJob }) {
  const fresh = group.location ? freshness(group.location.at, now) : null;
  return (
    <div className="px-5 py-4 border-b border-navy-border">
      <div className="flex items-center gap-2">
        <span className="text-[13px] font-semibold text-text-primary truncate">{group.driverName}</span>
        {fresh && (
          <span className={`ml-auto shrink-0 text-[11px] ${fresh.live ? 'text-success' : 'text-warning'}`}>
            {fresh.label}
          </span>
        )}
      </div>
      <div className="mt-2 flex flex-col gap-1.5">
        {group.jobs.map((job) => (
          <button
            key={job.id}
            type="button"
            onClick={() => onSelectJob(job)}
            className={`text-left rounded-lg px-3 py-2 border transition-colors cursor-pointer ${
              job.id === selectedJobId
                ? 'bg-navy-light border-navy-border'
                : 'bg-transparent border-transparent hover:bg-navy-light/60'
            }`}
          >
            <div className="flex items-center gap-2">
              <span className="w-2 h-2 rounded-full shrink-0" style={{ background: STATUSES[job.status].color }} />
              <span className="text-[12px] font-medium text-text-primary truncate">{vehicleName(job)}</span>
            </div>
            <div className="text-[11px] text-text-mid mt-0.5 truncate">
              {STATUSES[job.status].label} · {job.customerName}
            </div>
          </button>
        ))}
      </div>
    </div>
  );
}

function DriverMarker({ group, now, selected, selectedJobId, onSelect, onSelectJob, onClose, onOpenJob }) {
  const [markerRef, marker] = useAdvancedMarkerRef();
  const fresh = freshness(group.location.at, now);
  const look = fresh.live ? STATUSES[group.status] : STALE_LOOK;
  const count = group.jobs.length;

  return (
    <>
      <AdvancedMarker
        ref={markerRef}
        position={{ lat: group.location.lat, lng: group.location.lng }}
        title={`${group.driverName} · ${count} ${count === 1 ? 'vehicle' : 'vehicles'}`}
        anchorLeft="-50%"
        anchorTop="-50%"
        zIndex={selected ? 1000 : fresh.live ? 100 : 1}
        onClick={onSelect}
      >
        <div
          className="relative w-10 h-10 rounded-full grid place-items-center border-2 border-navy"
          style={{
            background: look.color,
            color: look.ink,
            boxShadow: selected
              ? `0 0 0 5px ${look.color}55, 0 4px 14px rgba(0,0,0,.5)`
              : '0 4px 14px rgba(0,0,0,.5)',
          }}
        >
          <Truck size={18} strokeWidth={2.2} />
          {count > 1 && (
            <span className="absolute -top-1.5 -right-1.5 min-w-5 h-5 px-1 rounded-full bg-accent-red text-white text-[11px] font-bold grid place-items-center border-2 border-navy">
              {count}
            </span>
          )}
        </div>
      </AdvancedMarker>

      {selected && marker && (
        <InfoWindow
          anchor={marker}
          onClose={onClose}
          headerContent={<span className="text-[14px] font-semibold text-[#0D1829]">{group.driverName}</span>}
        >
          <div className="min-w-[240px] max-w-[300px] text-[#0D1829]">
            <div className="flex items-center gap-2 text-[12px] text-[#4B5B76]">
              <span className="w-2 h-2 rounded-full" style={{ background: fresh.live ? '#22C55E' : '#F59E0B' }} />
              {fresh.label}
              {group.driverPhone && (
                <a href={`tel:${group.driverPhone}`} className="ml-auto flex items-center gap-1 text-[#0D1829] font-medium">
                  <Phone size={12} /> {group.driverPhone}
                </a>
              )}
            </div>
            {group.jobs.map((job) => (
              <div
                key={job.id}
                className={`mt-2 pt-2 border-t border-[#E5E9F0] ${job.id === selectedJobId ? '' : 'opacity-80'}`}
              >
                <button type="button" onClick={() => onSelectJob(job)} className="text-left w-full cursor-pointer">
                  <div className="text-[13px] font-semibold">{vehicleName(job)}</div>
                  <div className="text-[12px] text-[#4B5B76]">
                    {STATUSES[job.status].label} · {job.customerName}
                  </div>
                  <div className="text-[11px] text-[#6B7A94] mt-0.5">
                    {job.pickup.address} → {job.dropoff.address}
                  </div>
                </button>
                <button
                  type="button"
                  onClick={() => onOpenJob(job)}
                  className="mt-1 text-[12px] font-semibold text-accent-red-dark cursor-pointer"
                >
                  Open job
                </button>
              </div>
            ))}
          </div>
        </InfoWindow>
      )}
    </>
  );
}

function StopMarker({ position, letter, title }) {
  return (
    <AdvancedMarker position={{ lat: position.lat, lng: position.lng }} title={title} anchorLeft="-50%" anchorTop="-50%" zIndex={50}>
      <div className="w-7 h-7 rounded-full grid place-items-center bg-navy border-2 border-text-primary text-text-primary text-[12px] font-bold shadow-[0_4px_12px_rgba(0,0,0,.5)]">
        {letter}
      </div>
    </AdvancedMarker>
  );
}
