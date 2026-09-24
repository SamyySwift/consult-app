import React, { useState, useEffect } from 'react';
import {
  fetchPricing as apiFetchPricing,
  savePricing as apiSavePricing,
  fetchInsuranceSettings,
  saveInsuranceSettings,
} from '../lib/api';

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
    return (
      <div className="flex-1 p-8 flex items-center justify-center text-text-mid">
        Loading configuration...
      </div>
    );
  }

  return (
    <div className="flex flex-col flex-1 overflow-hidden p-8">
      <div className="flex items-center justify-between mb-6">
        <h2 className="font-syne text-[18px] font-bold text-text-primary tracking-tight">
          Pricing Configuration
        </h2>
        <button
          onClick={handleSave}
          disabled={saving}
          className={`px-4 py-2 rounded-lg text-[13px] font-semibold text-white transition-colors ${
            saving ? 'bg-navy-border cursor-not-allowed' : 'bg-info hover:bg-info/90'
          }`}
        >
          {saving ? 'Saving...' : 'Save Changes'}
        </button>
      </div>

      {message && (
        <div className={`mb-6 p-4 rounded-lg text-[13px] font-medium ${message.type === 'success' ? 'bg-success-bg text-success border border-success/20' : 'bg-error-bg text-accent-red border border-accent-red/20'}`}>
          {message.text}
        </div>
      )}

      <div className="bg-navy-mid border border-navy-border rounded-xl p-5 mb-6">
        <div className="flex flex-wrap items-center justify-between gap-4">
          <div>
            <div className="font-semibold text-text-primary text-[13px]">Insurance Percentage</div>
            <div className="text-[11px] text-text-mid mt-0.5">
              Insurance fee charged as a percentage of the client's estimated vehicle worth.
            </div>
          </div>
          <div className="flex items-center gap-2">
            <input
              type="text"
              inputMode="decimal"
              value={insurancePct}
              onChange={(e) => handleInsurancePctChange(e.target.value)}
              className="w-[100px] bg-navy border border-navy-border rounded-md px-3 py-2 text-[13px] text-text-primary focus:outline-none focus:border-info font-mono text-right"
            />
            <span className="text-text-mid text-[13px]">%</span>
          </div>
        </div>
        {parseFloat(insurancePct) > 0 && (
          <div className="text-[11px] text-text-mid mt-3">
            e.g. a ₦10,000,000 vehicle will pay ₦{Math.round(100000 * parseFloat(insurancePct)).toLocaleString('en-US')} for insurance.
          </div>
        )}
      </div>

      <div className="bg-navy-mid border border-navy-border rounded-xl overflow-hidden">
        <table className="w-full text-left border-collapse">
          <thead>
            <tr className="bg-navy-light border-b border-navy-border text-[11px] uppercase tracking-[0.05em] text-text-mid">
              <th className="p-4 font-medium w-1/4">Service Tier</th>
              <th className="p-4 font-medium">Base Price (₦)</th>
              <th className="p-4 font-medium">Enclosed Add-on (₦)</th>
            </tr>
          </thead>
          <tbody>
            {pricingData.map((p, i) => (
              <tr key={p.id} className="border-b border-navy-border last:border-0 hover:bg-navy/30 transition-colors">
                <td className="p-4">
                  <div className="font-semibold text-text-primary text-[13px]">{p.name}</div>
                  <div className="text-[11px] text-text-mid mt-0.5">{p.description}</div>
                </td>
                <td className="p-4">
                  <input
                    type="text"
                    value={p.base_price_str}
                    onChange={(e) => handleChange(i, 'base_price_str', e.target.value)}
                    className="w-full max-w-[150px] bg-navy border border-navy-border rounded-md px-3 py-2 text-[13px] text-text-primary focus:outline-none focus:border-info font-mono"
                  />
                </td>
                <td className="p-4">
                  <input
                    type="text"
                    value={p.enclosed_addon_str}
                    onChange={(e) => handleChange(i, 'enclosed_addon_str', e.target.value)}
                    className="w-full max-w-[150px] bg-navy border border-navy-border rounded-md px-3 py-2 text-[13px] text-text-primary focus:outline-none focus:border-info font-mono"
                  />
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
