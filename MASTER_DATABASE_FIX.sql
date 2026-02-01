-- MASTER DATABASE FIX: Add All Missing Columns and Fix RLS
-- Run this in Supabase SQL Editor to fix all PGRST204 errors

-- ============================================
-- APPOINTMENTS TABLE
-- ============================================
ALTER TABLE appointments ADD COLUMN IF NOT EXISTS calendar_event_id TEXT;
ALTER TABLE appointments ADD COLUMN IF NOT EXISTS payment_method TEXT;
ALTER TABLE appointments ADD COLUMN IF NOT EXISTS urgency_level TEXT DEFAULT 'routine';
ALTER TABLE appointments ADD COLUMN IF NOT EXISTS location_lat DECIMAL(10,8);
ALTER TABLE appointments ADD COLUMN IF NOT EXISTS location_lng DECIMAL(11,8);
ALTER TABLE appointments ADD COLUMN IF NOT EXISTS service_request_id UUID;

-- ============================================
-- DOCTOR VERIFICATION DOCUMENTS TABLE
-- ============================================
ALTER TABLE doctor_verification_documents ADD COLUMN IF NOT EXISTS document_number TEXT;
ALTER TABLE doctor_verification_documents ADD COLUMN IF NOT EXISTS expiry_date DATE;
ALTER TABLE doctor_verification_documents ADD COLUMN IF NOT EXISTS issuing_authority TEXT;
ALTER TABLE doctor_verification_documents ADD COLUMN IF NOT EXISTS verification_code TEXT;
ALTER TABLE doctor_verification_documents ADD COLUMN IF NOT EXISTS rejection_reason TEXT;
ALTER TABLE doctor_verification_documents ADD COLUMN IF NOT EXISTS verified_at TIMESTAMP WITH TIME ZONE;
ALTER TABLE doctor_verification_documents ADD COLUMN IF NOT EXISTS verification_status TEXT DEFAULT 'pending';
ALTER TABLE doctor_verification_documents ADD COLUMN IF NOT EXISTS file_size INTEGER;
ALTER TABLE doctor_verification_documents ADD COLUMN IF NOT EXISTS description TEXT;
ALTER TABLE doctor_verification_documents ADD COLUMN IF NOT EXISTS file_path TEXT;
ALTER TABLE doctor_verification_documents ADD COLUMN IF NOT EXISTS version INTEGER DEFAULT 1;
ALTER TABLE doctor_verification_documents ADD COLUMN IF NOT EXISTS file_type TEXT;
ALTER TABLE doctor_verification_documents ADD COLUMN IF NOT EXISTS mime_type TEXT;
ALTER TABLE doctor_verification_documents ADD COLUMN IF NOT EXISTS verified_by UUID;
ALTER TABLE doctor_verification_documents ADD COLUMN IF NOT EXISTS audit_logs JSONB;
ALTER TABLE doctor_verification_documents ADD COLUMN IF NOT EXISTS checksum TEXT;

-- ============================================
-- PAYMENTS TABLE
-- ============================================
ALTER TABLE payments ADD COLUMN IF NOT EXISTS currency TEXT DEFAULT 'JOD';
ALTER TABLE payments ADD COLUMN IF NOT EXISTS service_description TEXT;
ALTER TABLE payments ADD COLUMN IF NOT EXISTS tax DECIMAL(10,2) DEFAULT 0;
ALTER TABLE payments ADD COLUMN IF NOT EXISTS subtotal DECIMAL(10,2);
ALTER TABLE payments ADD COLUMN IF NOT EXISTS payment_intent_id TEXT;
ALTER TABLE payments ADD COLUMN IF NOT EXISTS invoice_number TEXT;
ALTER TABLE payments ADD COLUMN IF NOT EXISTS method TEXT;
ALTER TABLE payments ADD COLUMN IF NOT EXISTS total DECIMAL(10,2);
ALTER TABLE payments ADD COLUMN IF NOT EXISTS completed_at TIMESTAMP WITH TIME ZONE;

-- ============================================
-- SERVICE REQUESTS TABLE
-- ============================================
ALTER TABLE service_requests ADD COLUMN IF NOT EXISTS rejection_reason TEXT;
ALTER TABLE service_requests ADD COLUMN IF NOT EXISTS address TEXT;
ALTER TABLE service_requests ADD COLUMN IF NOT EXISTS longitude DECIMAL(11,8);
ALTER TABLE service_requests ADD COLUMN IF NOT EXISTS description TEXT;
ALTER TABLE service_requests ADD COLUMN IF NOT EXISTS latitude DECIMAL(10,8);
ALTER TABLE service_requests ADD COLUMN IF NOT EXISTS scheduled_date TIMESTAMP WITH TIME ZONE;
ALTER TABLE service_requests ADD COLUMN IF NOT EXISTS request_type TEXT DEFAULT 'booking';

-- ============================================
-- MEDICAL RECORDS TABLE
-- ============================================
ALTER TABLE medical_records ADD COLUMN IF NOT EXISTS attachments TEXT;

-- ============================================
-- NOTIFICATIONS TABLE
-- ============================================
ALTER TABLE notifications ADD COLUMN IF NOT EXISTS message TEXT;
ALTER TABLE notifications ADD COLUMN IF NOT EXISTS type TEXT;
ALTER TABLE notifications ADD COLUMN IF NOT EXISTS data JSONB;
ALTER TABLE notifications ADD COLUMN IF NOT EXISTS body TEXT;

-- ============================================
-- DOCUMENTS TABLE
-- ============================================
ALTER TABLE documents ADD COLUMN IF NOT EXISTS encryption_key TEXT;
ALTER TABLE documents ADD COLUMN IF NOT EXISTS version INTEGER DEFAULT 1;
ALTER TABLE documents ADD COLUMN IF NOT EXISTS file_path TEXT;
ALTER TABLE documents ADD COLUMN IF NOT EXISTS uploaded_by UUID;
ALTER TABLE documents ADD COLUMN IF NOT EXISTS access_level TEXT DEFAULT 'private';
ALTER TABLE documents ADD COLUMN IF NOT EXISTS mime_type TEXT;
ALTER TABLE documents ADD COLUMN IF NOT EXISTS audit_logs JSONB;
ALTER TABLE documents ADD COLUMN IF NOT EXISTS checksum TEXT;
ALTER TABLE documents ADD COLUMN IF NOT EXISTS file_size INTEGER DEFAULT 0;

-- ============================================
-- SCHEDULES TABLE
-- ============================================
ALTER TABLE schedules ADD COLUMN IF NOT EXISTS is_holiday BOOLEAN DEFAULT FALSE;
ALTER TABLE schedules ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT TRUE;
ALTER TABLE schedules ADD COLUMN IF NOT EXISTS is_free_day BOOLEAN DEFAULT FALSE;

-- ============================================
-- SERVICES TABLE
-- ============================================
ALTER TABLE services ADD COLUMN IF NOT EXISTS promotional_price DECIMAL(10,2);
ALTER TABLE services ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT TRUE;

-- ============================================
-- USERS TABLE
-- ============================================
ALTER TABLE users DROP CONSTRAINT IF EXISTS users_linked_doctor_id_fkey;
ALTER TABLE users DROP CONSTRAINT IF EXISTS users_linked_driver_id_fkey;
ALTER TABLE users ALTER COLUMN linked_doctor_id TYPE TEXT;
ALTER TABLE users ALTER COLUMN linked_driver_id TYPE TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS profile_image TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS provider TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS provider_id TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS availability_status TEXT DEFAULT 'offline';
ALTER TABLE users ADD COLUMN IF NOT EXISTS area TEXT;

-- ============================================
-- VANS TABLE
-- ============================================
ALTER TABLE vans ADD COLUMN IF NOT EXISTS area TEXT;
ALTER TABLE vans ADD COLUMN IF NOT EXISTS model TEXT;
ALTER TABLE vans ADD COLUMN IF NOT EXISTS description TEXT;

-- ============================================
-- PETS TABLE
-- ============================================
ALTER TABLE pets ADD COLUMN IF NOT EXISTS serial_number TEXT UNIQUE;
ALTER TABLE pets ADD COLUMN IF NOT EXISTS medical_history_summary TEXT;
ALTER TABLE pets ADD COLUMN IF NOT EXISTS vaccination_status JSONB;
ALTER TABLE pets ADD COLUMN IF NOT EXISTS photo_path TEXT;

-- ============================================
-- DOCTORS TABLE
-- ============================================
ALTER TABLE doctors ADD COLUMN IF NOT EXISTS license_number TEXT;
ALTER TABLE doctors ADD COLUMN IF NOT EXISTS specialization TEXT;
ALTER TABLE doctors ADD COLUMN IF NOT EXISTS experience_years INTEGER;
ALTER TABLE doctors ADD COLUMN IF NOT EXISTS is_available BOOLEAN DEFAULT TRUE;

-- ============================================
-- INVENTORY TABLE
-- ============================================
ALTER TABLE inventory ADD COLUMN IF NOT EXISTS min_threshold INTEGER DEFAULT 0;
ALTER TABLE inventory ADD COLUMN IF NOT EXISTS unit TEXT;
ALTER TABLE inventory ADD COLUMN IF NOT EXISTS cost DECIMAL(10,2);
ALTER TABLE inventory ADD COLUMN IF NOT EXISTS category TEXT;

-- ============================================
-- VACCINATION RECORDS TABLE
-- ============================================
ALTER TABLE vaccination_records ADD COLUMN IF NOT EXISTS batch_number TEXT;
ALTER TABLE vaccination_records ADD COLUMN IF NOT EXISTS veterinarian_name TEXT;

-- ============================================
-- DRIVER VERIFICATION DOCUMENTS TABLE
-- ============================================
ALTER TABLE driver_verification_documents ADD COLUMN IF NOT EXISTS document_number TEXT;
ALTER TABLE driver_verification_documents ADD COLUMN IF NOT EXISTS file_path TEXT;
ALTER TABLE driver_verification_documents ADD COLUMN IF NOT EXISTS expiry_date DATE;
ALTER TABLE driver_verification_documents ADD COLUMN IF NOT EXISTS issue_date DATE;
ALTER TABLE driver_verification_documents ADD COLUMN IF NOT EXISTS issuing_authority TEXT;
ALTER TABLE driver_verification_documents ADD COLUMN IF NOT EXISTS verification_code TEXT;
ALTER TABLE driver_verification_documents ADD COLUMN IF NOT EXISTS vehicle_class TEXT;

-- ============================================
-- DRIVER STATUS TABLE
-- ============================================
ALTER TABLE driver_status ADD COLUMN IF NOT EXISTS current_appointment_id UUID;
ALTER TABLE driver_status ADD COLUMN IF NOT EXISTS last_updated TIMESTAMP WITH TIME ZONE;

-- ============================================
-- DISABLE RLS ON ALL TABLES
-- ============================================
DO $$
DECLARE
    t TEXT;
BEGIN
    FOR t IN SELECT tablename FROM pg_tables WHERE schemaname = 'public' LOOP
        EXECUTE format('ALTER TABLE IF EXISTS public.%I DISABLE ROW LEVEL SECURITY', t);
    END LOOP;
END $$;

-- ============================================
-- DROP ALL EXISTING POLICIES
-- ============================================
DO $$
DECLARE
    pol RECORD;
BEGIN
    FOR pol IN 
        SELECT policyname, tablename FROM pg_policies WHERE schemaname = 'public'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON public.%I', pol.policyname, pol.tablename);
    END LOOP;
END $$;

-- ============================================
-- ENABLE RLS AND CREATE PERMISSIVE POLICIES
-- ============================================
DO $$
DECLARE
    t TEXT;
BEGIN
    FOR t IN SELECT tablename FROM pg_tables WHERE schemaname = 'public' LOOP
        EXECUTE format('ALTER TABLE IF EXISTS public.%I ENABLE ROW LEVEL SECURITY', t);
        EXECUTE format('CREATE POLICY "permissive_all_access" ON public.%I FOR ALL USING (true) WITH CHECK (true)', t);
    END LOOP;
END $$;

-- ============================================
-- REFRESH SCHEMA CACHE
-- ============================================
NOTIFY pgrst, 'reload schema';
