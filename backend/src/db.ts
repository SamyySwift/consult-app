import { Pool } from 'pg';
import dotenv from 'dotenv';

dotenv.config();

const connectionString = process.env.DATABASE_URL;

export const pool = new Pool({
  connectionString: connectionString || 'postgresql://postgres:postgres@localhost:5432/consult',
  ssl: process.env.NODE_ENV === 'production' && !connectionString?.includes('localhost')
    ? { rejectUnauthorized: false }
    : undefined,
});

export async function initDatabase() {
  console.log('🔄 Initializing and migrating database schema...');
  const client = await pool.connect();
  try {
    await client.query(`
      -- Users / Profiles Table
      CREATE TABLE IF NOT EXISTS public.users (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        first_name TEXT NOT NULL,
        last_name TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        password_hash TEXT NOT NULL,
        phone TEXT DEFAULT '',
        avatar_url TEXT,
        role TEXT DEFAULT 'client',
        is_verified BOOLEAN DEFAULT FALSE,
        license_number TEXT,
        vehicle_type TEXT,
        vehicle_plate TEXT,
        is_online BOOLEAN DEFAULT FALSE,
        rating NUMERIC(3, 2) DEFAULT 5.0,
        total_trips INT DEFAULT 0,
        current_lat DOUBLE PRECISION,
        current_lng DOUBLE PRECISION,
        created_at TIMESTAMPTZ DEFAULT NOW(),
        updated_at TIMESTAMPTZ DEFAULT NOW()
      );

      -- Ensure driver columns exist on users
      ALTER TABLE public.users ADD COLUMN IF NOT EXISTS license_number TEXT;
      ALTER TABLE public.users ADD COLUMN IF NOT EXISTS vehicle_type TEXT;
      ALTER TABLE public.users ADD COLUMN IF NOT EXISTS vehicle_plate TEXT;
      ALTER TABLE public.users ADD COLUMN IF NOT EXISTS is_online BOOLEAN DEFAULT FALSE;
      ALTER TABLE public.users ADD COLUMN IF NOT EXISTS rating NUMERIC(3, 2) DEFAULT 5.0;
      ALTER TABLE public.users ADD COLUMN IF NOT EXISTS total_trips INT DEFAULT 0;
      ALTER TABLE public.users ADD COLUMN IF NOT EXISTS current_lat DOUBLE PRECISION;
      ALTER TABLE public.users ADD COLUMN IF NOT EXISTS current_lng DOUBLE PRECISION;
      ALTER TABLE public.users ADD COLUMN IF NOT EXISTS is_profile_completed BOOLEAN DEFAULT FALSE;
      ALTER TABLE public.users ADD COLUMN IF NOT EXISTS date_of_birth TEXT;
      ALTER TABLE public.users ADD COLUMN IF NOT EXISTS residential_address TEXT;
      ALTER TABLE public.users ADD COLUMN IF NOT EXISTS state_lga TEXT;
      ALTER TABLE public.users ADD COLUMN IF NOT EXISTS emergency_contact_name TEXT;
      ALTER TABLE public.users ADD COLUMN IF NOT EXISTS emergency_contact_phone TEXT;
      ALTER TABLE public.users ADD COLUMN IF NOT EXISTS emergency_contact_relationship TEXT;
      ALTER TABLE public.users ADD COLUMN IF NOT EXISTS nin_number TEXT;
      ALTER TABLE public.users ADD COLUMN IF NOT EXISTS driver_license_image TEXT;

      -- Email Verifications (OTP) Table
      CREATE TABLE IF NOT EXISTS public.email_verifications (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        email TEXT NOT NULL,
        otp_code TEXT NOT NULL,
        expires_at TIMESTAMPTZ NOT NULL,
        verified BOOLEAN DEFAULT FALSE,
        created_at TIMESTAMPTZ DEFAULT NOW()
      );

      CREATE INDEX IF NOT EXISTS idx_email_verif_lookup 
      ON public.email_verifications(email, otp_code);

      -- Bookings Table
      CREATE TABLE IF NOT EXISTS public.bookings (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
        driver_id UUID REFERENCES public.users(id) ON DELETE SET NULL,
        booking_reference TEXT UNIQUE NOT NULL,
        pickup_address TEXT NOT NULL,
        dropoff_address TEXT NOT NULL,
        pickup_lat DOUBLE PRECISION,
        pickup_lng DOUBLE PRECISION,
        dropoff_lat DOUBLE PRECISION,
        dropoff_lng DOUBLE PRECISION,
        driver_lat DOUBLE PRECISION,
        driver_lng DOUBLE PRECISION,
        service_type TEXT NOT NULL,
        transport_tier TEXT NOT NULL DEFAULT 'standard',
        transport_mode TEXT DEFAULT 'standard',
        total_amount NUMERIC(12, 2) NOT NULL,
        status TEXT DEFAULT 'pending',
        vehicle_details JSONB,
        document_paths JSONB DEFAULT '[]'::jsonb,
        has_insurance BOOLEAN DEFAULT FALSE,
        insurance_amount NUMERIC(12, 2) DEFAULT 0,
        pickup_datetime TIMESTAMPTZ,
        assigned_at TIMESTAMPTZ,
        confirmed_at TIMESTAMPTZ,
        picked_up_at TIMESTAMPTZ,
        completed_at TIMESTAMPTZ,
        created_at TIMESTAMPTZ DEFAULT NOW(),
        updated_at TIMESTAMPTZ DEFAULT NOW()
      );

      -- Ensure all tracking & driver columns exist on bookings
      ALTER TABLE public.bookings ADD COLUMN IF NOT EXISTS driver_id UUID REFERENCES public.users(id) ON DELETE SET NULL;
      ALTER TABLE public.bookings ADD COLUMN IF NOT EXISTS transport_mode TEXT DEFAULT 'standard';
      ALTER TABLE public.bookings ADD COLUMN IF NOT EXISTS driver_lat DOUBLE PRECISION;
      ALTER TABLE public.bookings ADD COLUMN IF NOT EXISTS driver_lng DOUBLE PRECISION;
      ALTER TABLE public.bookings ADD COLUMN IF NOT EXISTS document_paths JSONB DEFAULT '[]'::jsonb;
      ALTER TABLE public.bookings ADD COLUMN IF NOT EXISTS has_insurance BOOLEAN DEFAULT FALSE;
      ALTER TABLE public.bookings ADD COLUMN IF NOT EXISTS base_price NUMERIC(12, 2) DEFAULT 0;
      ALTER TABLE public.bookings ADD COLUMN IF NOT EXISTS insurance_fee NUMERIC(12, 2) DEFAULT 0;
      ALTER TABLE public.bookings ADD COLUMN IF NOT EXISTS vehicle_value NUMERIC(14, 2) DEFAULT 0;
      ALTER TABLE public.bookings ADD COLUMN IF NOT EXISTS vehicle_type TEXT;
      ALTER TABLE public.bookings ADD COLUMN IF NOT EXISTS vehicle_make TEXT;
      ALTER TABLE public.bookings ADD COLUMN IF NOT EXISTS vehicle_model TEXT;
      ALTER TABLE public.bookings ADD COLUMN IF NOT EXISTS vehicle_year TEXT;
      ALTER TABLE public.bookings ADD COLUMN IF NOT EXISTS vehicle_color TEXT;
      ALTER TABLE public.bookings ADD COLUMN IF NOT EXISTS vehicle_vin TEXT;
      ALTER TABLE public.bookings ADD COLUMN IF NOT EXISTS pickup_datetime TIMESTAMPTZ;
      ALTER TABLE public.bookings ADD COLUMN IF NOT EXISTS assigned_at TIMESTAMPTZ;
      ALTER TABLE public.bookings ADD COLUMN IF NOT EXISTS confirmed_at TIMESTAMPTZ;
      ALTER TABLE public.bookings ADD COLUMN IF NOT EXISTS picked_up_at TIMESTAMPTZ;
      ALTER TABLE public.bookings ADD COLUMN IF NOT EXISTS completed_at TIMESTAMPTZ;
      ALTER TABLE public.bookings ADD COLUMN IF NOT EXISTS pickup_condition_desc TEXT;
      ALTER TABLE public.bookings ADD COLUMN IF NOT EXISTS pickup_condition_images JSONB DEFAULT '[]'::jsonb;
      ALTER TABLE public.bookings ADD COLUMN IF NOT EXISTS pickup_condition_audio TEXT;
      ALTER TABLE public.bookings ADD COLUMN IF NOT EXISTS client_signature_url TEXT;
      ALTER TABLE public.bookings ADD COLUMN IF NOT EXISTS client_acknowledged_at TIMESTAMPTZ;

      -- Pricing Configuration Table (Admin)
      CREATE TABLE IF NOT EXISTS public.pricing_config (
        id SERIAL PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT DEFAULT '',
        base_price NUMERIC(12, 2) DEFAULT 0,
        enclosed_addon NUMERIC(12, 2) DEFAULT 0,
        insurance_rate NUMERIC(12, 2) DEFAULT 0,
        updated_at TIMESTAMPTZ DEFAULT NOW()
      );

      -- Default Pricing Seeds if empty
      INSERT INTO public.pricing_config (name, description, base_price, enclosed_addon, insurance_rate)
      SELECT 'Sedan / Hatchback', 'Standard passenger vehicles', 75000, 25000, 5000
      WHERE NOT EXISTS (SELECT 1 FROM public.pricing_config WHERE name = 'Sedan / Hatchback');

      INSERT INTO public.pricing_config (name, description, base_price, enclosed_addon, insurance_rate)
      SELECT 'SUV / Crossover', 'Mid to full-size sport utility vehicles', 95000, 30000, 7500
      WHERE NOT EXISTS (SELECT 1 FROM public.pricing_config WHERE name = 'SUV / Crossover');

      INSERT INTO public.pricing_config (name, description, base_price, enclosed_addon, insurance_rate)
      SELECT 'Truck / Van', 'Pickup trucks, cargo vans, and commercial units', 120000, 40000, 10000
      WHERE NOT EXISTS (SELECT 1 FROM public.pricing_config WHERE name = 'Truck / Van');

      -- Global App Settings (Admin)
      CREATE TABLE IF NOT EXISTS public.app_settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL,
        updated_at TIMESTAMPTZ DEFAULT NOW()
      );

      -- Insurance fee = vehicle worth x this percentage
      INSERT INTO public.app_settings (key, value)
      VALUES ('insurance_percentage', '1.5')
      ON CONFLICT (key) DO NOTHING;

      CREATE INDEX IF NOT EXISTS idx_bookings_user_id ON public.bookings(user_id);
      CREATE INDEX IF NOT EXISTS idx_bookings_driver_id ON public.bookings(driver_id);
      CREATE INDEX IF NOT EXISTS idx_bookings_status ON public.bookings(status);
    `);
    console.log('✅ Database schema and migrations applied successfully');
  } catch (err) {
    console.error('❌ Error initializing database schema:', err);
    throw err;
  } finally {
    client.release();
  }
}
