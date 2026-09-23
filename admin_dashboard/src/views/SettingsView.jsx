import React, { useState, useEffect } from 'react';
import { supabase } from '../lib/supabase';

function formatAmount(value) {
  if (value === null || value === undefined) return '0';
  const raw = String(value).replace(/\D/g, '');
  if (!raw) return '';
  return parseInt(raw, 10).toLocaleString('en-US');
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

  useEffect(() => {
    fetchPricing();
  }, []);

  const fetchPricing = async () => {
    setLoading(true);
    try {
      const { data, error } = await supabase
        .from('pricing_config')
        .select('*')
        .order('id', { ascending: true });
        
      if (error) throw error;
      
      const formatted = (data || []).map(p => ({
        ...p,
        base_price_str: formatAmount(p.base_price),
        enclosed_addon_str: formatAmount(p.enclosed_addon),
        insurance_rate_str: formatAmount(p.insurance_rate),
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
    setSaving(true);
    setMessage(null);
    try {
      for (const p of pricingData) {
        const { error } = await supabase
          .from('pricing_config')
          .update({
            base_price: parseAmount(p.base_price_str),
            enclosed_addon: parseAmount(p.enclosed_addon_str),
            insurance_rate: parseAmount(p.insurance_rate_str)
          })
          .eq('id', p.id);
        
        if (error) throw error;
      }
      setMessage({ type: 'success', text: 'Pricing configuration saved successfully.' });
      setTimeout(() => setMessage(null), 3000);
    } catch (err) {
      console.error('Error saving pricing:', err);
      setMessage({ type: 'error', text: 'Failed to save changes.' });
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

      <div className="bg-navy-mid border border-navy-border rounded-xl overflow-hidden">
        <table className="w-full text-left border-collapse">
          <thead>
            <tr className="bg-navy-light border-b border-navy-border text-[11px] uppercase tracking-[0.05em] text-text-mid">
              <th className="p-4 font-medium w-1/4">Service Tier</th>
              <th className="p-4 font-medium">Base Price (₦)</th>
              <th className="p-4 font-medium">Enclosed Add-on (₦)</th>
              <th className="p-4 font-medium">Insurance Rate (₦)</th>
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
                <td className="p-4">
                  <input
                    type="text"
                    value={p.insurance_rate_str}
                    onChange={(e) => handleChange(i, 'insurance_rate_str', e.target.value)}
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
