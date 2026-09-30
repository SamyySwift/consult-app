import React, { useState, useEffect } from 'react';
import { Percent, Save, Tag } from 'lucide-react';
import {
  fetchPricing as apiFetchPricing,
  savePricing as apiSavePricing,
  fetchInsuranceSettings,
  saveInsuranceSettings,
} from '../lib/api';
import { Alert, Button, CardHeader, Input, Loading, SurfaceCard, Td, Th, Toolbar, Tr } from '../components/ui';

function formatAmount(value) {
  if (value === null || value === undefined) return '0';
  const raw = String(value).replace(/\D/g, '');
  if (!raw) return '';
  return parseInt(raw, 10).toLocaleString('en-US');
}

// NUMERIC columns come back from Postgres as strings like "75000.00".
// Round to a whole number first so the decimals aren't read as extra digits.
function formatDbAmount(value) {
  return formatAmount(Math.round(Number(value) || 0));
}

function parseAmount(value) {
  if (!value) return 0;
  return parseInt(String(value).replace(/\D/g, ''), 10) || 0;
}

function NairaInput({ value, onChange, label }) {
  return (
    <div className="relative max-w-[180px]">
      <span className="absolute left-4 top-1/2 -translate-y-1/2 text-[14px] font-semibold text-white/45 pointer-events-none">₦</span>
      <Input value={value} onChange={onChange} aria-label={label} inputMode="numeric" className="pl-9 tabular-nums" />
    </div>
  );
}

export function SettingsView() {
  const [pricingData, setPricingData] = useState([]);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [message, setMessage] = useState(null);
  const [insurancePct, setInsurancePct] = useState('');

  useEffect(() => {
    fetchPricing();
    fetchInsuranceSettings()
      .then((data) => setInsurancePct(String(data.insurance_percentage ?? '')))
      .catch((err) => console.error('Error fetching insurance settings:', err));
  }, []);

  const handleInsurancePctChange = (value) => {
    // Allow digits with at most one decimal point and two decimal places
    if (/^\d{0,3}(\.\d{0,2})?$/.test(value)) setInsurancePct(value);
  };

  const fetchPricing = async () => {
    setLoading(true);
    try {
      const data = await apiFetchPricing();

      const formatted = (data || []).map(p => ({
        ...p,
        base_price_str: formatDbAmount(p.base_price),
        enclosed_addon_str: formatDbAmount(p.enclosed_addon),
      }));
      setPricingData(formatted);
    } catch (err) {
      console.error('Error fetching pricing:', err);
    } finally {
      setLoading(false);
    }
  };

  const handleChange = (index, field, value) => {
    const newData = [...pricingData];
    newData[index] = { ...newData[index], [field]: formatAmount(value) };
    setPricingData(newData);
  };

  const handleSave = async () => {
    const pct = parseFloat(insurancePct);
    if (!Number.isFinite(pct) || pct < 0 || pct > 100) {
      setMessage({ type: 'error', text: 'Insurance percentage must be between 0 and 100.' });
      return;
    }

    setSaving(true);
    setMessage(null);
    try {
      const payload = pricingData.map(p => ({
        id: p.id,
        base_price: parseAmount(p.base_price_str),
        enclosed_addon: parseAmount(p.enclosed_addon_str),
      }));

      await Promise.all([apiSavePricing(payload), saveInsuranceSettings(pct)]);
      setMessage({ type: 'success', text: 'Pricing configuration saved successfully.' });
      setTimeout(() => setMessage(null), 3000);
    } catch (err) {
      console.error('Error saving pricing:', err);
      setMessage({ type: 'error', text: `Failed to save changes: ${err.message}` });
    } finally {
      setSaving(false);
    }
  };

  if (loading) {
    return <Loading label="Loading configuration…" />;
  }

  return (
    <div className="flex flex-col gap-5 px-8 pb-10 max-w-[1000px]">
      <Toolbar summary={`${pricingData.length} service tiers`}>
        <Button icon={Save} onClick={handleSave} loading={saving}>
          {saving ? 'Saving…' : 'Save Changes'}
        </Button>
      </Toolbar>

      {message && <Alert tone={message.type}>{message.text}</Alert>}

      <SurfaceCard className="p-5">
        <CardHeader
          icon={Percent}
          title="Insurance Percentage"
          subtitle="Insurance fee charged as a percentage of the client's estimated vehicle worth."
          action={
            <div className="flex items-center gap-2">
              <div className="w-[110px]">
                <Input
                  inputMode="decimal"
                  aria-label="Insurance percentage"
                  value={insurancePct}
                  onChange={(e) => handleInsurancePctChange(e.target.value)}
                  className="text-right tabular-nums"
                />
              </div>
              <span className="text-[15px] font-semibold text-white/55">%</span>
            </div>
          }
        />
        {parseFloat(insurancePct) > 0 && (
          <p className="mt-4 pl-[60px] text-[12px] text-white/55">
            e.g. a ₦10,000,000 vehicle will pay ₦{Math.round(100000 * parseFloat(insurancePct)).toLocaleString('en-US')} for insurance.
          </p>
        )}
      </SurfaceCard>

      <SurfaceCard className="overflow-hidden">
        <CardHeader
          icon={Tag}
          title="Service Tiers"
          subtitle="Base price and enclosed add-on for each tier, in naira."
          className="p-5"
        />
        <table className="w-full text-left border-collapse">
          <thead>
            <tr>
              <Th className="w-1/3 border-t">Service Tier</Th>
              <Th className="border-t">Base Price</Th>
              <Th className="border-t">Enclosed Add-on</Th>
            </tr>
          </thead>
          <tbody>
            {pricingData.map((p, i) => (
              <Tr key={p.id}>
                <Td>
                  <div className="font-semibold text-white">{p.name}</div>
                  <div className="text-[12px] text-white/50 mt-0.5">{p.description}</div>
                </Td>
                <Td>
                  <NairaInput
                    label={`${p.name} base price`}
                    value={p.base_price_str}
                    onChange={(e) => handleChange(i, 'base_price_str', e.target.value)}
                  />
                </Td>
                <Td>
                  <NairaInput
                    label={`${p.name} enclosed add-on`}
                    value={p.enclosed_addon_str}
                    onChange={(e) => handleChange(i, 'enclosed_addon_str', e.target.value)}
                  />
                </Td>
              </Tr>
            ))}
          </tbody>
        </table>
      </SurfaceCard>
    </div>
  );
}
