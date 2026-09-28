import React, { useState, useEffect, useMemo } from 'react';
import {
  fetchPartners,
  createPartner,
  updatePartner,
  fetchPartnerDrivers,
} from '../lib/api';

const EMPTY_FORM = {
  name: '',
  registration_number: '',
  contact_name: '',
  contact_phone: '',
  contact_email: '',
  address: '',
  notes: '',
  is_active: true,
};

export function PartnersView() {
  const [partners, setPartners] = useState([]);
  const [loading, setLoading] = useState(true);
  const [loadError, setLoadError] = useState(null);
  const [search, setSearch] = useState('');
  const [editing, setEditing] = useState(null); // null = closed, {} = new, partner = edit
  const [expandedId, setExpandedId] = useState(null);
  const [message, setMessage] = useState(null);

  const loadPartners = async () => {
    setLoadError(null);
    try {
      setPartners(await fetchPartners());
    } catch (err) {
      console.error('Error fetching partners:', err);
      setLoadError(err.message);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadPartners();
  }, []);

  const showMessage = (type, text) => {
    setMessage({ type, text });
    setTimeout(() => setMessage(null), 3000);
  };

  const handleSaved = (saved, isNew) => {
    setPartners(prev =>
      isNew ? [...prev, saved] : prev.map(p => (p.id === saved.id ? saved : p))
    );
    setEditing(null);
    showMessage('success', isNew ? `${saved.name} added as a partner.` : `${saved.name} updated.`);
  };

  const toggleActive = async partner => {
    try {
      const saved = await updatePartner(partner.id, { is_active: !partner.is_active });
      setPartners(prev => prev.map(p => (p.id === saved.id ? saved : p)));
      showMessage(
        'success',
        saved.is_active
          ? `${saved.name} is active and shows in driver sign-up.`
          : `${saved.name} is inactive and hidden from driver sign-up.`
      );
    } catch (err) {
      showMessage('error', `Failed to update partner: ${err.message}`);
    }
  };

  const filtered = useMemo(() => {
    const q = search.trim().toLowerCase();
    const list = [...partners].sort(
      (a, b) => Number(b.is_active) - Number(a.is_active) || a.name.localeCompare(b.name)
    );
    if (!q) return list;
    return list.filter(p =>
      [p.name, p.contact_name, p.contact_phone, p.contact_email, p.registration_number]
        .filter(Boolean)
        .some(v => v.toLowerCase().includes(q))
    );
  }, [partners, search]);

  const activeCount = partners.filter(p => p.is_active).length;
  const linkedDrivers = partners.reduce((sum, p) => sum + (p.driver_count || 0), 0);

  if (loading) {
    return (
      <div className="flex-1 p-8 flex items-center justify-center text-text-mid">
        Loading partners...
      </div>
    );
  }

  return (
    <div className="flex flex-col flex-1 p-8 gap-6 overflow-hidden">
      {/* Header */}
      <div className="flex items-center justify-between shrink-0 gap-4">
        <div>
          <h2 className="font-syne text-[18px] font-bold text-text-primary tracking-tight">
            Partners &amp; Affiliations
          </h2>
          <p className="text-[12px] text-text-dim mt-0.5">
            Companies drivers work for. Active partners appear in the driver sign-up form.
          </p>
        </div>
        <div className="flex items-center gap-3">
          <div className="relative">
            <svg className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-text-dim" fill="none" stroke="currentColor" strokeWidth="2" viewBox="0 0 24 24">
              <circle cx="11" cy="11" r="8"/><path d="m21 21-4.35-4.35"/>
            </svg>
            <input
              type="text"
              placeholder="Search partners…"
              value={search}
              onChange={e => setSearch(e.target.value)}
              className="w-64 pl-9 pr-4 py-2 bg-navy-mid border border-navy-border rounded-lg text-[13px] text-text-primary placeholder:text-text-dim focus:outline-none focus:border-info transition-colors"
            />
          </div>
          <button
            onClick={() => setEditing({})}
            className="px-4 py-2 rounded-lg text-[13px] font-semibold text-white bg-info hover:bg-info/90 transition-colors whitespace-nowrap"
          >
            + Add Partner
          </button>
        </div>
      </div>

      {message && (
        <div className={`shrink-0 p-4 rounded-lg text-[13px] font-medium ${message.type === 'success' ? 'bg-success-bg text-success border border-success/20' : 'bg-error-bg text-accent-red border border-accent-red/20'}`}>
          {message.text}
        </div>
      )}

      {loadError && (
        <div className="shrink-0 p-4 rounded-lg text-[13px] font-medium bg-error-bg text-accent-red border border-accent-red/20 flex items-center justify-between">
          <span>Couldn't load partners: {loadError}</span>
          <button onClick={loadPartners} className="underline">Retry</button>
        </div>
      )}

      {/* Summary */}
      <div className="grid grid-cols-3 gap-3 shrink-0">
        {[
          { label: 'Partners', value: partners.length, color: 'text-text-primary', sub: 'registered companies' },
          { label: 'Active', value: activeCount, color: 'text-success', sub: 'shown in driver sign-up' },
          { label: 'Linked Drivers', value: linkedDrivers, color: 'text-info', sub: 'driving for a partner' },
        ].map(kpi => (
          <div key={kpi.label} className="bg-navy-mid border border-navy-border rounded-xl p-5 flex flex-col gap-1">
            <div className="text-[11px] text-text-mid uppercase tracking-[0.06em] font-medium">{kpi.label}</div>
            <div className={`font-syne font-extrabold text-[32px] leading-none tracking-tight ${kpi.color}`}>{kpi.value}</div>
            <div className="text-[11px] text-text-dim font-mono">{kpi.sub}</div>
          </div>
        ))}
      </div>

      {/* Partner table */}
      <div className="flex-1 overflow-auto rounded-xl border border-navy-border bg-navy-mid min-h-0">
        <table className="w-full text-left border-collapse">
          <thead className="sticky top-0 z-10 bg-navy-light border-b border-navy-border">
            <tr className="text-[11px] uppercase tracking-[0.05em] text-text-mid">
              <th className="px-4 py-3 font-medium">Company</th>
              <th className="px-4 py-3 font-medium">Contact</th>
              <th className="px-4 py-3 font-medium">Address</th>
              <th className="px-4 py-3 font-medium">Drivers</th>
              <th className="px-4 py-3 font-medium">Status</th>
              <th className="px-4 py-3 font-medium text-right">Actions</th>
            </tr>
          </thead>
          <tbody>
            {filtered.length === 0 ? (
              <tr>
                <td colSpan={6} className="text-center py-16 text-text-dim text-[13px]">
                  {search
                    ? 'No partners match your search.'
                    : 'No partners yet. Add one so drivers can select it when they sign up.'}
                </td>
              </tr>
            ) : (
              filtered.map(partner => (
                <React.Fragment key={partner.id}>
                  <tr className={`border-b border-navy-border hover:bg-navy/60 transition-colors ${partner.is_active ? '' : 'opacity-60'}`}>
                    <td className="px-4 py-3.5">
                      <div className="text-[13px] font-semibold text-text-primary">{partner.name}</div>
                      {partner.registration_number && (
                        <div className="text-[11px] text-text-dim font-mono mt-0.5">RC {partner.registration_number}</div>
                      )}
                    </td>
                    <td className="px-4 py-3.5">
                      <div className="text-[13px] text-text-primary">{partner.contact_name || '—'}</div>
                      <div className="text-[11px] text-text-mid font-mono mt-0.5">
                        {[partner.contact_phone, partner.contact_email].filter(Boolean).join(' · ') || '—'}
                      </div>
                    </td>
                    <td className="px-4 py-3.5 text-[12px] text-text-mid max-w-[220px]">
                      <div className="line-clamp-2">{partner.address || '—'}</div>
                    </td>
                    <td className="px-4 py-3.5">
                      <button
                        onClick={() => setExpandedId(expandedId === partner.id ? null : partner.id)}
                        disabled={!partner.driver_count}
                        className="flex items-center gap-1.5 text-[13px] text-info disabled:text-text-dim disabled:cursor-default"
                        title={partner.driver_count ? 'Show drivers' : 'No drivers yet'}
                      >
                        <span className="font-syne font-bold text-[20px]">{partner.driver_count || 0}</span>
                        {partner.driver_count > 0 && (
                          <span className="text-[11px]">{expandedId === partner.id ? 'Hide' : 'View'}</span>
                        )}
                      </button>
                    </td>
                    <td className="px-4 py-3.5">
                      <span className={`text-[11px] font-semibold px-2.5 py-1 rounded-full uppercase tracking-[0.05em] flex items-center gap-1.5 w-fit ${
                        partner.is_active ? 'bg-success-bg text-success' : 'bg-navy-light text-text-dim'
                      }`}>
                        <span className="w-1.5 h-1.5 rounded-full bg-current"></span>
                        {partner.is_active ? 'Active' : 'Inactive'}
                      </span>
                    </td>
                    <td className="px-4 py-3.5">
                      <div className="flex items-center justify-end gap-2">
                        <button
                          onClick={() => setEditing(partner)}
                          className="px-3 py-1.5 rounded-md text-[12px] font-medium text-text-primary border border-navy-border hover:bg-navy-light transition-colors"
                        >
                          Edit
                        </button>
                        <button
                          onClick={() => toggleActive(partner)}
                          className={`px-3 py-1.5 rounded-md text-[12px] font-medium border transition-colors ${
                            partner.is_active
                              ? 'text-accent-red border-accent-red/30 hover:bg-error-bg'
                              : 'text-success border-success/30 hover:bg-success-bg'
                          }`}
                        >
                          {partner.is_active ? 'Deactivate' : 'Activate'}
                        </button>
                      </div>
                    </td>
                  </tr>
                  {expandedId === partner.id && (
                    <tr className="border-b border-navy-border bg-navy/40">
                      <td colSpan={6} className="px-4 py-4">
                        <PartnerDrivers partnerId={partner.id} />
                      </td>
                    </tr>
                  )}
                </React.Fragment>
              ))
            )}
          </tbody>
        </table>
      </div>

      {editing && (
        <PartnerForm
          partner={editing.id ? editing : null}
          onCancel={() => setEditing(null)}
          onSaved={handleSaved}
        />
      )}
    </div>
  );
}

function PartnerDrivers({ partnerId }) {
  const [drivers, setDrivers] = useState(null);
  const [error, setError] = useState(null);

  useEffect(() => {
    fetchPartnerDrivers(partnerId)
      .then(setDrivers)
      .catch(err => setError(err.message));
  }, [partnerId]);

  if (error) return <div className="text-[12px] text-accent-red">Couldn't load drivers: {error}</div>;
  if (!drivers) return <div className="text-[12px] text-text-mid">Loading drivers…</div>;

  return (
    <div className="grid grid-cols-2 xl:grid-cols-3 gap-2">
      {drivers.map(d => (
        <div key={d.id} className="flex items-center gap-3 bg-navy-mid border border-navy-border rounded-lg px-3 py-2.5">
          <div className="w-8 h-8 rounded-full bg-navy-light border border-navy-border flex items-center justify-center text-[13px] font-bold text-text-mid shrink-0">
            {d.full_name.charAt(0).toUpperCase()}
          </div>
          <div className="min-w-0">
            <div className="text-[13px] font-medium text-text-primary truncate">{d.full_name}</div>
            <div className="text-[11px] text-text-mid font-mono truncate">
              {[d.phone, d.vehicle_plate].filter(Boolean).join(' · ') || d.email}
            </div>
          </div>
          <span className={`ml-auto text-[10px] font-semibold px-2 py-0.5 rounded-full uppercase ${
            d.is_verified ? 'bg-success-bg text-success' : 'bg-amber-glow text-amber'
          }`}>
            {d.is_verified ? 'Verified' : 'Pending'}
          </span>
        </div>
      ))}
    </div>
  );
}

function PartnerForm({ partner, onCancel, onSaved }) {
  const isNew = !partner;
  const [form, setForm] = useState(() =>
    isNew ? EMPTY_FORM : Object.fromEntries(Object.keys(EMPTY_FORM).map(k => [k, partner[k] ?? EMPTY_FORM[k]]))
  );
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState(null);

  const set = (field, value) => setForm(f => ({ ...f, [field]: value }));

  const handleSubmit = async e => {
    e.preventDefault();
    if (!form.name.trim()) {
      setError('Company name is required.');
      return;
    }
    if (form.contact_email && !/^\S+@\S+\.\S+$/.test(form.contact_email.trim())) {
      setError('Contact email looks invalid.');
      return;
    }

    setSaving(true);
    setError(null);
    try {
      const saved = isNew ? await createPartner(form) : await updatePartner(partner.id, form);
      onSaved(saved, isNew);
    } catch (err) {
      setError(err.message);
      setSaving(false);
    }
  };

  const inputClass =
    'w-full bg-navy border border-navy-border rounded-md px-3 py-2 text-[13px] text-text-primary placeholder:text-text-dim focus:outline-none focus:border-info';
  const labelClass = 'block text-[11px] uppercase tracking-[0.05em] text-text-mid font-medium mb-1.5';

  return (
    <div
      className="fixed inset-0 z-[200] bg-black/60 flex items-center justify-center p-6"
      onClick={onCancel}
    >
      <form
        onSubmit={handleSubmit}
        onClick={e => e.stopPropagation()}
        className="w-full max-w-[560px] max-h-full overflow-y-auto bg-navy-mid border border-navy-border rounded-xl p-6 flex flex-col gap-4"
      >
        <div className="flex items-center justify-between">
          <h3 className="font-syne text-[16px] font-bold text-text-primary">
            {isNew ? 'Add Partner' : `Edit ${partner.name}`}
          </h3>
          <button type="button" onClick={onCancel} className="text-text-mid hover:text-text-primary text-[20px] leading-none" aria-label="Close">
            ×
          </button>
        </div>

        {error && (
          <div className="p-3 rounded-lg text-[12px] font-medium bg-error-bg text-accent-red border border-accent-red/20">
            {error}
          </div>
        )}

        <div className="grid grid-cols-2 gap-4">
          <div className="col-span-2">
            <label className={labelClass}>Company name *</label>
            <input className={inputClass} value={form.name} onChange={e => set('name', e.target.value)} placeholder="e.g. Swift Haulage Ltd" autoFocus />
          </div>
          <div className="col-span-2">
            <label className={labelClass}>Registration number (CAC / RC)</label>
            <input className={inputClass} value={form.registration_number} onChange={e => set('registration_number', e.target.value)} placeholder="e.g. RC 1234567" />
          </div>
          <div className="col-span-2">
            <label className={labelClass}>Contact person</label>
            <input className={inputClass} value={form.contact_name} onChange={e => set('contact_name', e.target.value)} placeholder="Full name" />
          </div>
          <div>
            <label className={labelClass}>Contact phone</label>
            <input className={inputClass} value={form.contact_phone} onChange={e => set('contact_phone', e.target.value)} placeholder="080..." />
          </div>
          <div>
            <label className={labelClass}>Contact email</label>
            <input className={inputClass} type="email" value={form.contact_email} onChange={e => set('contact_email', e.target.value)} placeholder="name@company.com" />
          </div>
          <div className="col-span-2">
            <label className={labelClass}>Address</label>
            <textarea className={`${inputClass} resize-none`} rows={2} value={form.address} onChange={e => set('address', e.target.value)} placeholder="Office address" />
          </div>
          <div className="col-span-2">
            <label className={labelClass}>Notes / agreement terms</label>
            <textarea className={`${inputClass} resize-none`} rows={3} value={form.notes} onChange={e => set('notes', e.target.value)} placeholder="Commission, contract terms, anything the team should know" />
          </div>
          <label className="col-span-2 flex items-center gap-2 text-[13px] text-text-primary cursor-pointer">
            <input type="checkbox" checked={form.is_active} onChange={e => set('is_active', e.target.checked)} className="accent-info w-4 h-4" />
            Active: show this company in the driver sign-up form
          </label>
        </div>

        <div className="flex justify-end gap-2 pt-2">
          <button type="button" onClick={onCancel} className="px-4 py-2 rounded-lg text-[13px] font-medium text-text-primary border border-navy-border hover:bg-navy-light transition-colors">
            Cancel
          </button>
          <button
            type="submit"
            disabled={saving}
            className={`px-4 py-2 rounded-lg text-[13px] font-semibold text-white transition-colors ${saving ? 'bg-navy-border cursor-not-allowed' : 'bg-info hover:bg-info/90'}`}
          >
            {saving ? 'Saving...' : isNew ? 'Add Partner' : 'Save Changes'}
          </button>
        </div>
      </form>
    </div>
  );
}
