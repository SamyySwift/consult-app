import { pool } from './db';

export const DEFAULT_INSURANCE_PERCENTAGE = 1.5;

export async function getInsurancePercentage(): Promise<number> {
  const result = await pool.query(
    "SELECT value FROM public.app_settings WHERE key = 'insurance_percentage'"
  );
  const pct = parseFloat(result.rows[0]?.value);
  return Number.isFinite(pct) && pct >= 0 ? pct : DEFAULT_INSURANCE_PERCENTAGE;
}

export async function setInsurancePercentage(pct: number): Promise<void> {
  await pool.query(
    `INSERT INTO public.app_settings (key, value, updated_at)
     VALUES ('insurance_percentage', $1, NOW())
     ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value, updated_at = NOW()`,
    [String(pct)]
  );
}
