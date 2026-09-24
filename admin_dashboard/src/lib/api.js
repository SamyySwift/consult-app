// Carpital Consult Admin API Client
const API_BASE_URL = import.meta.env.VITE_API_URL || 'https://carpitalconsult.com';

export async function fetchAdminBookings() {
  const res = await fetch(`${API_BASE_URL}/api/admin/bookings`);
  if (!res.ok) {
    const err = await res.json().catch(() => ({}));
    throw new Error(err.error || `Failed to fetch bookings (${res.status})`);
  }
  return res.json();
}

export async function fetchAdminDrivers() {
  const res = await fetch(`${API_BASE_URL}/api/admin/drivers`);
  if (!res.ok) {
    const err = await res.json().catch(() => ({}));
    throw new Error(err.error || `Failed to fetch drivers (${res.status})`);
  }
  return res.json();
}

export async function assignDriver(bookingId, driverId) {
  const res = await fetch(`${API_BASE_URL}/api/admin/assign-driver`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ bookingId, driverId }),
  });
  if (!res.ok) {
    const err = await res.json().catch(() => ({}));
    throw new Error(err.error || `Failed to assign driver (${res.status})`);
  }
  return res.json();
}

export async function updateBookingStatus(bookingId, status, extra = {}) {
  const res = await fetch(`${API_BASE_URL}/api/admin/bookings/${bookingId}/status`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ status, ...extra }),
  });
  if (!res.ok) {
    const err = await res.json().catch(() => ({}));
    throw new Error(err.error || `Failed to update status (${res.status})`);
  }
  return res.json();
}

export async function fetchPricing() {
  const res = await fetch(`${API_BASE_URL}/api/admin/pricing`);
  if (!res.ok) {
    const err = await res.json().catch(() => ({}));
    throw new Error(err.error || `Failed to fetch pricing (${res.status})`);
  }
  return res.json();
}

export async function savePricing(pricingList) {
  const res = await fetch(`${API_BASE_URL}/api/admin/pricing`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(pricingList),
  });
  if (!res.ok) {
    const err = await res.json().catch(() => ({}));
    throw new Error(err.error || `Failed to save pricing (${res.status})`);
  }
  return res.json();
}

export async function fetchInsuranceSettings() {
  const res = await fetch(`${API_BASE_URL}/api/admin/settings/insurance`);
  if (!res.ok) {
    const err = await res.json().catch(() => ({}));
    throw new Error(err.error || `Failed to fetch insurance settings (${res.status})`);
  }
  return res.json();
}

export async function saveInsuranceSettings(insurancePercentage) {
  const res = await fetch(`${API_BASE_URL}/api/admin/settings/insurance`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ insurance_percentage: insurancePercentage }),
  });
  if (!res.ok) {
    const err = await res.json().catch(() => ({}));
    throw new Error(err.error || `Failed to save insurance settings (${res.status})`);
  }
  return res.json();
}

export async function fetchStats() {
  const res = await fetch(`${API_BASE_URL}/api/admin/stats`);
  if (!res.ok) {
    const err = await res.json().catch(() => ({}));
    throw new Error(err.error || `Failed to fetch stats (${res.status})`);
  }
  return res.json();
}
