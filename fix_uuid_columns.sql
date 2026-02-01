-- FIX: Change UUID columns to TEXT to accept numeric IDs
-- Run this in Supabase SQL Editor

-- ============================================
-- CHANGE LINKED ID COLUMNS FROM UUID TO TEXT
-- ============================================

-- Drop existing foreign key constraints first
ALTER TABLE users DROP CONSTRAINT IF EXISTS users_linked_doctor_id_fkey;
ALTER TABLE users DROP CONSTRAINT IF EXISTS users_linked_driver_id_fkey;

-- Change column types from UUID to TEXT
ALTER TABLE users ALTER COLUMN linked_doctor_id TYPE TEXT;
ALTER TABLE users ALTER COLUMN linked_driver_id TYPE TEXT;

-- ============================================
-- REFRESH SCHEMA CACHE
-- ============================================
NOTIFY pgrst, 'reload schema';

-- Verify the change
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'users' AND column_name IN ('linked_doctor_id', 'linked_driver_id');
