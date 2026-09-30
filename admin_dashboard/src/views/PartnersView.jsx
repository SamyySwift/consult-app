import React, { useState, useEffect, useMemo } from 'react';
import { Building2, ChevronDown, Pencil, Plus } from 'lucide-react';
import {
  fetchPartners,
  createPartner,
  updatePartner,
  fetchPartnerDrivers,
} from '../lib/api';
import {
  Alert,
  Avatar,
  Badge,
  Button,
  Dialog,
  EmptyRow,
  Field,
  IconTile,
  Input,
  Loading,
  SearchField,
  StatsStrip,
  TableCard,
  Td,
  Textarea,
  Th,
  Toolbar,
  Tr,
} from '../components/ui';

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
    return <Loading label="Loading partners…" />;
  }

  return (
    <div className="flex flex-col flex-1 min-h-0 px-8 pb-8 gap-5 overflow-hidden">
      <Toolbar summary="Companies drivers work for. Active partners appear in the driver sign-up form.">
        <SearchField value={search} onChange={setSearch} placeholder="Search partners…" className="w-64" />
        <Button icon={Plus} onClick={() => setEditing({})}>
          Add Partner
        </Button>
      </Toolbar>

      {message && <Alert tone={message.type}>{message.text}</Alert>}

      {loadError && (
        <Alert
          tone="error"
          action={
            <Button variant="ghost" size="sm" onClick={loadPartners}>
              Retry
            </Button>
          }
        >
          Couldn't load partners: {loadError}
        </Alert>
      )}

      <StatsStrip
        items={[
          { label: 'Partners', value: partners.length },
          { label: 'Active', value: activeCount, tone: 'text-accent' },
          { label: 'Linked drivers', value: linkedDrivers },
        ]}
      />

      <TableCard>
        <thead>
          <tr>
            <Th>Company</Th>
            <Th>Contact</Th>
            <Th>Address</Th>
            <Th>Drivers</Th>
            <Th>Status</Th>
            <Th className="text-right">Actions</Th>
          </tr>
        </thead>
        <tbody>
          {filtered.length === 0 ? (
            <EmptyRow colSpan={6}>
              {search
                ? 'No partners match your search.'
                : 'No partners yet. Add one so drivers can select it when they sign up.'}
            </EmptyRow>
          ) : (
            filtered.map(partner => {
              const expanded = expandedId === partner.id;
              return (
                <React.Fragment key={partner.id}>
                  <Tr className={partner.is_active ? '' : 'opacity-60'}>
                    <Td>
                      <div className="flex items-center gap-3">
                        <IconTile icon={Building2} size={36} iconSize={17} radius={12} />
                        <div className="min-w-0">
                          <div className="font-semibold text-white">{partner.name}</div>
                          {partner.registration_number && (
                            <div className="text-[12px] text-white/45 tabular-nums mt-0.5">RC {partner.registration_number}</div>
                          )}
                        </div>
                      </div>
                    </Td>
                    <Td>
                      <div className="text-white/85">{partner.contact_name || '—'}</div>
                      <div className="text-[12px] text-white/45 mt-0.5">
                        {[partner.contact_phone, partner.contact_email].filter(Boolean).join(' · ') || '—'}
                      </div>
                    </Td>
                    <Td className="max-w-[220px] text-[12px] text-white/60">
                      <div className="line-clamp-2">{partner.address || '—'}</div>
                    </Td>
                    <Td>
                      <button
                        type="button"
                        onClick={() => setExpandedId(expanded ? null : partner.id)}
                        disabled={!partner.driver_count}
                        className="flex items-center gap-1.5 text-white cursor-pointer disabled:cursor-default disabled:text-white/35"
                        title={partner.driver_count ? 'Show drivers' : 'No drivers yet'}
                      >
                        <span className="text-[15px] font-bold tabular-nums">{partner.driver_count || 0}</span>
                        {partner.driver_count > 0 && (
                          <span className="flex items-center text-[12px] font-semibold text-accent-light">
                            {expanded ? 'Hide' : 'View'}
                            <ChevronDown size={14} className={`transition-transform duration-200 ${expanded ? 'rotate-180' : ''}`} />
                          </span>
                        )}
                      </button>
                    </Td>
                    <Td>
                      {partner.is_active ? <Badge tone="success" compact>Active</Badge> : <Badge compact>Inactive</Badge>}
                    </Td>
                    <Td>
                      <div className="flex items-center justify-end gap-2">
                        <Button variant="outline" size="sm" icon={Pencil} onClick={() => setEditing(partner)}>
                          Edit
                        </Button>
                        <Button
                          variant={partner.is_active ? 'dangerGhost' : 'outline'}
                          size="sm"
                          onClick={() => toggleActive(partner)}
                        >
                          {partner.is_active ? 'Deactivate' : 'Activate'}
                        </Button>
                      </div>
                    </Td>
                  </Tr>
                  {expanded && (
                    <tr className="border-b border-white/6 bg-white/3">
                      <td colSpan={6} className="px-4 py-4">
                        <PartnerDrivers partnerId={partner.id} />
                      </td>
                    </tr>
                  )}
                </React.Fragment>
              );
            })
          )}
        </tbody>
      </TableCard>

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

  if (error) return <div className="text-[12px] text-error">Couldn't load drivers: {error}</div>;
  if (!drivers) return <div className="text-[12px] text-white/55">Loading drivers…</div>;

  return (
    <div className="grid grid-cols-2 xl:grid-cols-3 gap-2">
      {drivers.map(d => (
        <div
          key={d.id}
          className="flex items-center gap-3 rounded-[16px] border border-white/6 bg-surface-variant/60 px-3 py-2.5"
        >
          <Avatar name={d.full_name} size={34} />
          <div className="min-w-0">
            <div className="text-[13px] font-semibold text-white truncate">{d.full_name}</div>
            <div className="text-[12px] text-white/50 truncate">
              {[d.phone, d.vehicle_plate].filter(Boolean).join(' · ') || d.email}
            </div>
          </div>
          <span className="ml-auto">
            {d.is_verified ? <Badge tone="success" compact>Verified</Badge> : <Badge tone="warning" compact>Pending</Badge>}
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

  return (
    <Dialog
      as="form"
      onSubmit={handleSubmit}
      title={isNew ? 'Add Partner' : `Edit ${partner.name}`}
      onClose={onCancel}
      footer={
        <>
          <Button variant="glass" onClick={onCancel}>
            Cancel
          </Button>
          <Button type="submit" loading={saving}>
            {saving ? 'Saving…' : isNew ? 'Add Partner' : 'Save Changes'}
          </Button>
        </>
      }
    >
      {error && <Alert tone="error">{error}</Alert>}

      <div className="grid grid-cols-2 gap-4">
        <Field label="Company name *" className="col-span-2">
          <Input value={form.name} onChange={e => set('name', e.target.value)} placeholder="e.g. Swift Haulage Ltd" autoFocus />
        </Field>
        <Field label="Registration number (CAC / RC)" className="col-span-2">
          <Input value={form.registration_number} onChange={e => set('registration_number', e.target.value)} placeholder="e.g. RC 1234567" />
        </Field>
        <Field label="Contact person" className="col-span-2">
          <Input value={form.contact_name} onChange={e => set('contact_name', e.target.value)} placeholder="Full name" />
        </Field>
        <Field label="Contact phone">
          <Input value={form.contact_phone} onChange={e => set('contact_phone', e.target.value)} placeholder="080..." />
        </Field>
        <Field label="Contact email">
          <Input type="email" value={form.contact_email} onChange={e => set('contact_email', e.target.value)} placeholder="name@company.com" />
        </Field>
        <Field label="Address" className="col-span-2">
          <Textarea rows={2} value={form.address} onChange={e => set('address', e.target.value)} placeholder="Office address" />
        </Field>
        <Field label="Notes / agreement terms" className="col-span-2">
          <Textarea rows={3} value={form.notes} onChange={e => set('notes', e.target.value)} placeholder="Commission, contract terms, anything the team should know" />
        </Field>
        <label className="col-span-2 flex items-center gap-3 rounded-tile bg-surface-variant px-4 py-3.5 text-[13px] text-white cursor-pointer">
          <input
            type="checkbox"
            checked={form.is_active}
            onChange={e => set('is_active', e.target.checked)}
            className="size-4 accent-accent cursor-pointer"
          />
          Active: show this company in the driver sign-up form
        </label>
      </div>
    </Dialog>
  );
}
