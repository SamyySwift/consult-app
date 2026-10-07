import { createContext, useContext, useState, useEffect, useRef } from 'react';
import { fetchAdminBookings, fetchAdminDrivers } from '../lib/api';

const AppContext = createContext();

export function AppProvider({ children }) {
  const [jobs, setJobs] = useState([]);
  const [drivers, setDrivers] = useState([]);
  const [currentFilter, setCurrentFilter] = useState('all');
  const [selectedJobId, setSelectedJobId] = useState(null);
  const [loading, setLoading] = useState(true);
  const [liveStatus, setLiveStatus] = useState('live');

  // Format date utility
  const formatRelativeTime = (dateStr) => {
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
  };

  const normalizeStatus = (dbStatus) => {
    if (!dbStatus) return 'pending';
    const s = dbStatus.toLowerCase();
    if (s === 'delivered' || s === 'completed') return 'completed';
    if (s === 'pickedup' || s === 'picked_up') return 'pickedUp';
    if (s === 'intransit' || s === 'in_transit') return 'inTransit';
    if (s === 'confirmed') return 'confirmed';
    if (s === 'assigned') return 'assigned';
    if (s === 'cancelled') return 'cancelled';
    return 'pending';
  };

  const toNumber = (v) => {
    const n = v == null || v === '' ? NaN : Number(v);
    return Number.isFinite(n) ? n : null;
  };

  const fetchDrivers = async () => {
    try {
      const data = await fetchAdminDrivers();
      setDrivers(data || []);
    } catch (err) {
      console.warn('Error loading drivers:', err);
    }
  };

  const formatBooking = (b) => {
    const clientName = b.client?.full_name || [b.client_first_name, b.client_last_name].filter(Boolean).join(' ') || 'Direct Client';
    const clientPhone = b.client?.phone || b.client_phone || '—';
    const driverName = b.driver?.full_name || [b.driver_first_name, b.driver_last_name].filter(Boolean).join(' ') || (b.driver_id ? 'Assigned Driver' : 'Unassigned');
    
    return {
      id: b.id || b.booking_reference || 'JB00000',
      dbId: b.id,
      bookingReference: b.booking_reference,
      customerId: b.user_id,
      customerName: clientName,
      customerPhone: clientPhone,
      driverId: b.driver_id,
      driverName: driverName,
      driverPhone: b.driver_phone || null,
      // Last position the driver app reported for this job
      driverLocation: toNumber(b.driver_lat) != null && toNumber(b.driver_lng) != null
        ? { lat: toNumber(b.driver_lat), lng: toNumber(b.driver_lng), at: b.driver_location_at || null }
        : null,
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
        lat: toNumber(b.pickup_lat),
        lng: toNumber(b.pickup_lng),
      },
      dropoff: {
        address: b.dropoff_address || 'Abuja, Nigeria',
        lat: toNumber(b.dropoff_lat),
        lng: toNumber(b.dropoff_lng),
      },
      serviceType: b.service_type || 'Standard',
      transportMode: b.transport_mode ? (b.transport_mode.includes('enclosed') ? 'Enclosed Transport' : 'Open Transport') : 'Open Transport',
      hasInsurance: !!b.has_insurance,
      vehicleValue: Number(b.vehicle_value) || 0,
      insuranceFee: Number(b.insurance_fee) || Number(b.insurance_amount) || 0,
      totalAmount: Number(b.total_amount) || 75000,
      status: normalizeStatus(b.status),
      createdAt: formatRelativeTime(b.created_at),
      createdAtRaw: b.created_at,
      assignedAt: b.assigned_at ? formatRelativeTime(b.assigned_at) : (b.driver_id ? formatRelativeTime(b.created_at) : null),
      confirmedAt: b.confirmed_at ? formatRelativeTime(b.confirmed_at) : null,
      pickedUpAt: b.picked_up_at ? formatRelativeTime(b.picked_up_at) : null,
      completedAt: b.completed_at ? formatRelativeTime(b.completed_at) : null,
      clientAcknowledgedAt: b.client_acknowledged_at ? formatRelativeTime(b.client_acknowledged_at) : null,
      // Photos, voice note and signature load when the booking is opened
      pickupConditionDesc: b.pickup_condition_desc,
    };
  };

  const isOpenStatus = (status) => status !== 'completed' && status !== 'cancelled';

  // Polls fetch only open bookings; the full list, history included, loads at
  // start, when a booking leaves the open set, and at least this often
  const FULL_REFRESH_MS = 60_000;
  const lastFullFetchAt = useRef(0);
  // The interval below would otherwise only ever see the first render's jobs
  const jobsRef = useRef([]);

  const fetchBookings = async ({ poll = false } = {}) => {
    try {
      let full = !poll || Date.now() - lastFullFetchAt.current >= FULL_REFRESH_MS;
      let formattedJobs = (await fetchAdminBookings({ openOnly: !full }))?.map(formatBooking);

      if (formattedJobs && !full) {
        const openIds = new Set(formattedJobs.map(j => j.id));
        // A booking that dropped out of the open set was completed or
        // cancelled; only the full list says which
        if (jobsRef.current.some(j => isOpenStatus(j.status) && !openIds.has(j.id))) {
          full = true;
          formattedJobs = (await fetchAdminBookings())?.map(formatBooking);
        } else {
          formattedJobs = [...formattedJobs, ...jobsRef.current.filter(j => !isOpenStatus(j.status))]
            .sort((a, b) => new Date(b.createdAtRaw) - new Date(a.createdAtRaw));
        }
      }

      if (formattedJobs) {
        if (full) lastFullFetchAt.current = Date.now();
        jobsRef.current = formattedJobs;
        setJobs(formattedJobs);
        setLiveStatus('live');
      }
    } catch (err) {
      console.error('Error fetching live bookings:', err);
      setLiveStatus('connecting');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchDrivers();
    fetchBookings();

    // Auto-refresh poll every 4 seconds for live command center updates. A
    // hidden tab skips it and catches up as soon as it's shown again.
    const poll = () => {
      if (document.hidden) return;
      fetchDrivers();
      fetchBookings({ poll: true });
    };
    const interval = setInterval(poll, 4000);
    document.addEventListener('visibilitychange', poll);

    return () => {
      clearInterval(interval);
      document.removeEventListener('visibilitychange', poll);
    };
  }, []);

  const value = {
    jobs,
    drivers,
    currentFilter,
    setCurrentFilter,
    selectedJobId,
    setSelectedJobId,
    loading,
    liveStatus,
    fetchBookings,
    fetchDrivers
  };

  return <AppContext.Provider value={value}>{children}</AppContext.Provider>;
}

export const useAppContext = () => useContext(AppContext);
