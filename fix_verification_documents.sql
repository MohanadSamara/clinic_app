-- FIX: Add all missing columns to verification documents tables
-- Run this in Supabase SQL Editor

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
-- REFRESH SCHEMA CACHE
-- ============================================
NOTIFY pgrst, 'reload schema';

-- ============================================
-- VERIFY COLUMNS - DOCTOR
-- ============================================
SELECT 'doctor_verification_documents' as table_name, column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'doctor_verification_documents';

-- ============================================
-- VERIFY COLUMNS - DRIVER
-- ============================================
SELECT 'driver_verification_documents' as table_name, column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'driver_verification_documents';
