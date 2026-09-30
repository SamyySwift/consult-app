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
import { ChevronRight, Map as MapIcon, MapPin, Maximize2, Phone, Truck } from 'lucide-react';
import { useAppContext } from '../context/AppContext';
import { vehicleName } from '../lib/format';
import { MAP_LOOK, STALE_LOOK } from '../lib/status';
import { Avatar, EmptyState, Eyebrow, SurfaceCard } from '../components/ui';

const API_KEY = import.meta.env.VITE_GOOGLE_MAPS_API_KEY;
// Advanced markers need a map ID; Google's demo ID works until one is created
const MAP_ID = import.meta.env.VITE_GOOGLE_MAP_ID || 'DEMO_MAP_ID';
const ABUJA = { lat: 9.0765, lng: 7.3986 };
// Same as the client app: after this long a position is no longer live
const STALE_AFTER_MS = 2 * 60 * 1000;

// Statuses where the driver has the job and reports their position, most urgent first
const URGENCY = ['inTransit', 'pickedUp', 'confirmed'];

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
        <EmptyState
          icon={MapIcon}
          title="Map unavailable"
          className="max-w-md"
          subtitle={
            API_KEY
              ? 'Google rejected the map key. Enable the Maps JavaScript API in Google Cloud and allow it on this key, then reload.'
              : 'Add VITE_GOOGLE_MAPS_API_KEY to admin_dashboard/.env and restart the dashboard. The key needs the Maps JavaScript API enabled.'
          }
        />
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
    <div className="absolute inset-0 flex gap-4 px-8 pb-8">
      <aside className="w-[340px] shrink-0 flex flex-col min-h-0">
        <div className="pb-4 px-1 shrink-0">
          <h2 className="text-[18px] font-bold text-white">Vehicles on the move</h2>
          <p className="text-[13px] text-white/55 mt-1">
            {vehicleCount} {vehicleCount === 1 ? 'vehicle' : 'vehicles'} · {counts.live} live
            {counts.stale > 0 && ` · ${counts.stale} not updated recently`}
            {waitingCount > 0 && ` · ${waitingCount} no location`}
          </p>
        </div>

        <div className="flex-1 min-h-0 overflow-y-auto scrollbar-thin flex flex-col gap-2.5 pr-1">
          {groups.length === 0 && (
            <SurfaceCard radius="rounded-[22px]" className="p-5 text-[13px] text-white/55">
              No vehicles are being moved right now.
            </SurfaceCard>
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
            <div className="px-1 pt-3 pb-1">
              <Eyebrow>Waiting for location</Eyebrow>
              <p className="text-[12px] text-white/45 mt-1.5">
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
        </div>
      </aside>

      <div className="flex-1 relative min-w-0 rounded-card overflow-hidden border border-line">
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
            <PickupMarker position={selectedJob.pickup} title={`Pickup: ${selectedJob.pickup.address}`} />
          )}
          {selectedJob && hasPoint(selectedJob.dropoff) && (
            <DropoffMarker position={selectedJob.dropoff} title={`Drop-off: ${selectedJob.dropoff.address}`} />
          )}
        </GoogleMap>

        {/* Glass floats over the map, where there is imagery to blur */}
        <div className="glass absolute left-4 bottom-4 flex flex-wrap items-center gap-x-4 gap-y-1.5 max-w-[calc(100%-2rem)] px-4 py-2.5 rounded-[22px]">
          {URGENCY.map((s) => (
            <Legend key={s} color={MAP_LOOK[s].dot} label={MAP_LOOK[s].label} />
          ))}
          <Legend color={STALE_LOOK.dot} label="Over 2 min old" />
        </div>

        {located.length > 0 && (
          <button
            type="button"
            onClick={fitAll}
            className="glass absolute top-4 right-4 flex items-center gap-2 h-10 px-4 rounded-full text-[13px] font-semibold text-white cursor-pointer transition-colors hover:bg-white/8"
          >
            <Maximize2 size={15} strokeWidth={2.2} /> Fit all
          </button>
        )}
      </div>
    </div>
  );
}

function Legend({ color, label }) {
  return (
    <span className="flex items-center gap-1.5 text-[12px] font-medium text-white/85">
      <span className="size-2.5 rounded-full" style={{ background: color }} />
      {label}
    </span>
  );
}

function Freshness({ fresh }) {
  return (
    <span className={`flex items-center gap-1.5 text-[12px] font-medium ${fresh.live ? 'text-accent-light' : 'text-warning'}`}>
      <span
        className={`size-1.5 rounded-full ${fresh.live ? 'bg-accent animate-pulse-dot shadow-[0_0_6px_rgb(0_200_83/0.7)]' : 'bg-warning'}`}
      />
      {fresh.label}
    </span>
  );
}

function DriverRow({ group, now, selectedJobId, onSelectJob }) {
  const fresh = group.location ? freshness(group.location.at, now) : null;
  return (
    <SurfaceCard radius="rounded-[22px]" className="p-3.5 shrink-0">
      <div className="flex items-center gap-3 px-1">
        <Avatar name={group.driverName} size={36} />
        <div className="min-w-0 flex-1">
          <div className="text-[14px] font-semibold text-white truncate">{group.driverName}</div>
          {fresh && <Freshness fresh={fresh} />}
        </div>
      </div>
      <div className="mt-2.5 flex flex-col gap-1">
        {group.jobs.map((job) => (
          <button
            key={job.id}
            type="button"
            onClick={() => onSelectJob(job)}
            className={`w-full text-left rounded-[14px] px-3 py-2 cursor-pointer transition-colors ${
              job.id === selectedJobId ? 'bg-white/10' : 'hover:bg-white/5'
            }`}
          >
            <div className="flex items-center gap-2">
              <span className="size-2 rounded-full shrink-0" style={{ background: MAP_LOOK[job.status].dot }} />
              <span className="text-[13px] font-semibold text-white truncate">{vehicleName(job)}</span>
            </div>
            <div className="text-[12px] text-white/55 mt-0.5 truncate pl-4">
              {MAP_LOOK[job.status].label} · {job.customerName}
            </div>
          </button>
        ))}
      </div>
    </SurfaceCard>
  );
}

function DriverMarker({ group, now, selected, selectedJobId, onSelect, onSelectJob, onClose, onOpenJob }) {
  const [markerRef, marker] = useAdvancedMarkerRef();
  const fresh = freshness(group.location.at, now);
  const look = fresh.live ? MAP_LOOK[group.status] : STALE_LOOK;
  const count = group.jobs.length;
  const glow = fresh.live && group.status === 'inTransit' ? ', 0 0 20px rgb(0 200 83 / 0.45)' : '';

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
          className="relative size-11 rounded-full grid place-items-center border-2 border-black"
          style={{
            background: look.fill,
            color: look.ink,
            boxShadow: selected
              ? `0 0 0 5px ${look.dot}55, 0 4px 14px rgb(0 0 0 / 0.5)${glow}`
              : `0 4px 14px rgb(0 0 0 / 0.5)${glow}`,
          }}
        >
          <Truck size={20} strokeWidth={2.2} />
          {count > 1 && (
            <span className="absolute -top-1.5 -right-1.5 min-w-5 h-5 px-1 rounded-full bg-error text-white text-[11px] font-bold grid place-items-center border-2 border-black">
              {count}
            </span>
          )}
        </div>
      </AdvancedMarker>

      {selected && marker && (
        <InfoWindow
          anchor={marker}
          onClose={onClose}
          headerContent={<span className="text-[15px] font-bold text-white">{group.driverName}</span>}
        >
          <div className="min-w-[240px] max-w-[300px] text-white">
            <div className="flex items-center gap-2">
              <Freshness fresh={fresh} />
              {group.driverPhone && (
                <a href={`tel:${group.driverPhone}`} className="ml-auto flex items-center gap-1 text-[12px] font-medium text-white/85">
                  <Phone size={12} /> {group.driverPhone}
                </a>
              )}
            </div>
            {group.jobs.map((job) => (
              <div
                key={job.id}
                className={`mt-2.5 pt-2.5 border-t border-white/8 ${job.id === selectedJobId ? '' : 'opacity-70'}`}
              >
                <button type="button" onClick={() => onSelectJob(job)} className="text-left w-full cursor-pointer">
                  <div className="text-[13px] font-bold">{vehicleName(job)}</div>
                  <div className="text-[12px] text-white/55">
                    {MAP_LOOK[job.status].label} · {job.customerName}
                  </div>
                  <div className="text-[11px] text-white/45 mt-0.5">
                    {job.pickup.address} → {job.dropoff.address}
                  </div>
                </button>
                <button
                  type="button"
                  onClick={() => onOpenJob(job)}
                  className="mt-1.5 flex items-center gap-0.5 text-[12px] font-semibold text-accent-light cursor-pointer"
                >
                  Open job <ChevronRight size={14} strokeWidth={2.4} />
                </button>
              </div>
            ))}
          </div>
        </InfoWindow>
      )}
    </>
  );
}

/** Pickup: a glowing green dot, as on the client's tracking map. */
function PickupMarker({ position, title }) {
  return (
    <AdvancedMarker position={{ lat: position.lat, lng: position.lng }} title={title} anchorLeft="-50%" anchorTop="-50%" zIndex={50}>
      <div className="size-4 rounded-full bg-accent border-[3px] border-black shadow-[0_0_0_4px_rgb(0_200_83/0.3),0_4px_12px_rgb(0_0_0/0.5)]" />
    </AdvancedMarker>
  );
}

function DropoffMarker({ position, title }) {
  return (
    <AdvancedMarker position={{ lat: position.lat, lng: position.lng }} title={title} anchorLeft="-50%" anchorTop="-50%" zIndex={50}>
      <div className="size-8 rounded-full grid place-items-center bg-[#1A1C1B] border-2 border-white text-white shadow-[0_4px_12px_rgb(0_0_0/0.5)]">
        <MapPin size={15} strokeWidth={2.4} />
      </div>
    </AdvancedMarker>
  );
}
