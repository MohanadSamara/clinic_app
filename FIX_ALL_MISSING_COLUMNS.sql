-- Comprehensive Fix: Add All Missing Columns to Supabase Tables
-- Run this SQL in Supabase SQL Editor to fix all schema cache errors
-- PostgREST error PGRST204 means the column doesn't exist in the schema cache

-- ============================================
-- USERS TABLE - Add missing columns
-- ============================================
ALTER TABLE users ADD COLUMN IF NOT EXISTS profile_image TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS provider TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS provider_id TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS linked_doctor_id UUID REFERENCES users(id);
ALTER TABLE users ADD COLUMN IF NOT EXISTS linked_driver_id UUID REFERENCES users(id);
ALTER TABLE users ADD COLUMN IF NOT EXISTS availability_status TEXT DEFAULT 'offline';
ALTER TABLE users ADD COLUMN IF NOT EXISTS password TEXT;

-- ============================================
-- VANS TABLE - Add missing columns
-- ============================================
ALTER TABLE vans ADD COLUMN IF NOT EXISTS area TEXT;
ALTER TABLE vans ADD COLUMN IF NOT EXISTS model TEXT;
ALTER TABLE vans ADD COLUMN IF NOT EXISTS description TEXT;

-- ============================================
-- PETS TABLE - Add missing columns
-- ============================================
ALTER TABLE pets ADD COLUMN IF NOT EXISTS serial_number TEXT UNIQUE;
ALTER TABLE pets ADD COLUMN IF NOT EXISTS medical_history_summary TEXT;
ALTER TABLE pets ADD COLUMN IF NOT EXISTS vaccination_status JSONB;
ALTER TABLE pets ADD COLUMN IF NOT EXISTS photo_path TEXT;

-- ============================================
-- SERVICES TABLE - Add missing columns (if any)
-- ============================================
-- Services table typically has: id, name, description, category, price, promotional_price, is_active, created_at, updated_at

-- ============================================
-- DOCTORS TABLE - Add missing columns
-- ============================================
ALTER TABLE doctors ADD COLUMN IF NOT EXISTS assigned_service_id UUID REFERENCES services(id);
ALTER TABLE doctors ADD COLUMN IF NOT EXISTS license_number TEXT;
ALTER TABLE doctors ADD COLUMN IF NOT EXISTS specialization TEXT;
ALTER TABLE doctors ADD COLUMN IF NOT EXISTS experience_years INTEGER;
ALTER TABLE doctors ADD COLUMN IF NOT EXISTS is_available BOOLEAN DEFAULT TRUE;

-- ============================================
-- MEDICAL RECORDS TABLE - Add missing columns
-- ============================================
ALTER TABLE medical_records ADD COLUMN IF NOT EXISTS attachments TEXT;

-- ============================================
-- DOCUMENTS TABLE - Add missing columns
-- ============================================
ALTER TABLE documents ADD COLUMN IF NOT EXISTS access_level TEXT DEFAULT 'private';
ALTER TABLE documents ADD COLUMN IF NOT EXISTS file_size INTEGER DEFAULT 0;
ALTER TABLE documents ADD COLUMN IF NOT EXISTS mime_type TEXT;
ALTER TABLE documents ADD COLUMN IF NOT EXISTS version INTEGER DEFAULT 1;
ALTER TABLE documents ADD COLUMN IF NOT EXISTS uploaded_by UUID REFERENCES users(id);

-- ============================================
-- APPOINTMENTS TABLE - Add missing columns
-- ============================================
ALTER TABLE appointments ADD COLUMN IF NOT EXISTS location_lat DECIMAL(10,8);
ALTER TABLE appointments ADD COLUMN IF NOT EXISTS location_lng DECIMAL(11,8);
ALTER TABLE appointments ADD COLUMN IF NOT EXISTS calendar_event_id TEXT;
ALTER TABLE appointments ADD COLUMN IF NOT EXISTS payment_method TEXT;
ALTER TABLE appointments ADD COLUMN IF NOT EXISTS service_request_id UUID REFERENCES service_requests(id);
ALTER TABLE appointments ADD COLUMN IF NOT EXISTS urgency_level TEXT DEFAULT 'routine';

-- ============================================
-- SCHEDULES TABLE - Add missing columns
-- ============================================
ALTER TABLE schedules ADD COLUMN IF NOT EXISTS is_holiday BOOLEAN DEFAULT FALSE;
ALTER TABLE schedules ADD COLUMN IF NOT EXISTS is_free_day BOOLEAN DEFAULT FALSE;

-- ============================================
-- SERVICE REQUESTS TABLE - Add missing columns
-- ============================================
ALTER TABLE service_requests ADD COLUMN IF NOT EXISTS request_type TEXT DEFAULT 'booking';
ALTER TABLE service_requests ADD COLUMN IF NOT EXISTS rejection_reason TEXT;
ALTER TABLE service_requests ADD COLUMN IF NOT EXISTS latitude DECIMAL(10,8);
ALTER TABLE service_requests ADD COLUMN IF NOT EXISTS longitude DECIMAL(11,8);

-- ============================================
-- NOTIFICATIONS TABLE - Add missing columns
-- ============================================
ALTER TABLE notifications ADD COLUMN IF NOT EXISTS type TEXT;
ALTER TABLE notifications ADD COLUMN IF NOT EXISTS data JSONB;

-- ============================================
-- PAYMENTS TABLE - Add missing columns
-- ============================================
ALTER TABLE payments ADD COLUMN IF NOT EXISTS subtotal DECIMAL(10,2) DEFAULT 0.0;
ALTER TABLE payments ADD COLUMN IF NOT EXISTS tax DECIMAL(10,2) DEFAULT 0.0;
ALTER TABLE payments ADD COLUMN IF NOT EXISTS currency TEXT DEFAULT 'JOD';
ALTER TABLE payments ADD COLUMN IF NOT EXISTS payment_intent_id TEXT;
ALTER TABLE payments ADD COLUMN IF NOT EXISTS invoice_number TEXT;
ALTER TABLE payments ADD COLUMN IF NOT EXISTS service_description TEXT;
ALTER TABLE payments ADD COLUMN IF NOT EXISTS completed_at TIMESTAMP WITH TIME ZONE;

-- ============================================
-- DRIVER STATUS TABLE - Add missing columns
-- ============================================
ALTER TABLE driver_status ADD COLUMN IF NOT EXISTS current_appointment_id UUID REFERENCES appointments(id);
ALTER TABLE driver_status ADD COLUMN IF NOT EXISTS last_updated TIMESTAMP WITH TIME ZONE;

-- ============================================
-- INVENTORY TABLE - Add missing columns
-- ============================================
ALTER TABLE inventory ADD COLUMN IF NOT EXISTS min_threshold INTEGER DEFAULT 0;
ALTER TABLE inventory ADD COLUMN IF NOT EXISTS unit TEXT;
ALTER TABLE inventory ADD COLUMN IF NOT EXISTS cost DECIMAL(10,2);
ALTER TABLE inventory ADD COLUMN IF NOT EXISTS category TEXT;

-- ============================================
-- VACCINATION RECORDS TABLE - Add missing columns
-- ============================================
ALTER TABLE vaccination_records ADD COLUMN IF NOT EXISTS batch_number TEXT;
ALTER TABLE vaccination_records ADD COLUMN IF NOT EXISTS veterinarian_name TEXT;

-- ============================================
-- VERIFICATION DOCUMENTS - Add missing columns
-- ============================================
ALTER TABLE doctor_verification_documents ADD COLUMN IF NOT EXISTS document_number TEXT;
ALTER TABLE doctor_verification_documents ADD COLUMN IF NOT EXISTS expiry_date DATE;
ALTER TABLE doctor_verification_documents ADD COLUMN IF NOT EXISTS issuing_authority TEXT;
ALTER TABLE doctor_verification_documents ADD COLUMN IF NOT EXISTS verification_code TEXT;

ALTER TABLE driver_verification_documents ADD COLUMN IF NOT EXISTS document_number TEXT;
ALTER TABLE driver_verification_documents ADD COLUMN IF NOT EXISTS expiry_date DATE;
ALTER TABLE driver_verification_documents ADD COLUMN IF NOT EXISTS issue_date DATE;
ALTER TABLE driver_verification_documents ADD COLUMN IF NOT EXISTS issuing_authority TEXT;
ALTER TABLE driver_verification_documents ADD COLUMN IF NOT EXISTS verification_code TEXT;
ALTER TABLE driver_verification_documents ADD COLUMN IF NOT EXISTS vehicle_class TEXT;

-- ============================================
-- Refresh Schema Cache (IMPORTANT!)
-- ============================================
-- This notifies PostgREST to reload the schema
NOTIFY pgrst, 'reload schema';

-- ============================================
-- Verify Columns Were Added
-- ============================================

-- Check vans table columns
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'vans' 
ORDER BY ordinal_position;

-- Check users table columns
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'users' 
ORDER BY ordinal_position;

-- List all tables to verify
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
ORDER BY table_name;

