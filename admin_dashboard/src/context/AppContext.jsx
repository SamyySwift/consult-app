import { createContext, useContext, useState, useEffect } from 'react';
import { supabase } from '../lib/supabase';

const AppContext = createContext();

export function AppProvider({ children }) {
  const [jobs, setJobs] = useState([]);
  const [drivers, setDrivers] = useState([]);
  const [currentFilter, setCurrentFilter] = useState('all');
  const [selectedJobId, setSelectedJobId] = useState(null);
  const [loading, setLoading] = useState(true);
  const [liveStatus, setLiveStatus] = useState('connecting');

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
    if (s === 'delivered') return 'completed';
    if (s === 'pickedup' || s === 'picked_up') return 'pickedUp';
    if (s === 'intransit' || s === 'in_transit') return 'inTransit';
    if (s === 'confirmed') return 'confirmed';
    if (s === 'assigned') return 'assigned';
    if (s === 'cancelled') return 'cancelled';
    return 'pending';
  };

  const fetchDrivers = async () => {
    try {
      const { data, error } = await supabase
        .from('profiles')
        .select('id, full_name, phone')
        .eq('role', 'driver');
      if (error) throw error;
      setDrivers(data || []);
    } catch (err) {
      console.warn('Error loading drivers:', err);
    }
  };

  const fetchBookings = async () => {
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
        const formattedJobs = data.map(b => {
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
            createdAtRaw: b.created_at,
            assignedAt: b.assigned_at ? formatRelativeTime(b.assigned_at) : (b.driver_id ? formatRelativeTime(b.created_at) : null),
            confirmedAt: b.confirmed_at ? formatRelativeTime(b.confirmed_at) : null,
            pickedUpAt: b.picked_up_at ? formatRelativeTime(b.picked_up_at) : null,
            completedAt: b.completed_at ? formatRelativeTime(b.completed_at) : null,
            clientAcknowledgedAt: b.completed_at ? formatRelativeTime(b.completed_at) : null,
            clientSignatureBase64: b.client_signature_url 
              ? (b.client_signature_url.startsWith('data:image') ? b.client_signature_url : `data:image/png;base64,${b.client_signature_url}`) 
              : null,
            pickupConditionDesc: b.pickup_condition_desc,
            pickupConditionImages: Array.isArray(b.pickup_condition_images) ? b.pickup_condition_images : null,
            pickupConditionAudio: b.pickup_condition_audio,
          };
        });
        setJobs(formattedJobs);
      }
    } catch (err) {
      console.error('Error fetching live bookings:', err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchDrivers();
    fetchBookings();

    const channel = supabase
      .channel('public:admin_command_center')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'bookings' }, () => {
        fetchBookings();
      })
      .on('postgres_changes', { event: '*', schema: 'public', table: 'drivers' }, () => {
        fetchDrivers();
      })
      .subscribe((status) => {
        if (status === 'SUBSCRIBED') {
          setLiveStatus('live');
        } else {
          setLiveStatus('connecting');
        }
      });

    return () => {
      supabase.removeChannel(channel);
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
