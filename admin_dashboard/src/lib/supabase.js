import { createClient } from '@supabase/supabase-js';

const SUPABASE_URL = 'https://ulksjcitenlxtvxwvktw.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVsa3NqY2l0ZW5seHR2eHd2a3R3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODU2MDE0OTgsImV4cCI6MjEwMTE3NzQ5OH0.cKWA1RdL99z9IAYHkIeu6W0WxY6Sfk5PiRpJVTmvmtM';

export const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
