-- Complete Database Fix
-- Run this in Supabase SQL Editor
-- Fixes: UUID migration, missing columns, and schema cache

-- ============================================
-- STEP 1: Add missing columns to pets table
-- ============================================

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'pets' AND column_name = 'medical_history_summary') THEN
        ALTER TABLE pets ADD COLUMN medical_history_summary TEXT;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'pets' AND column_name = 'serial_number') THEN
        ALTER TABLE pets ADD COLUMN serial_number TEXT UNIQUE;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'pets' AND column_name = 'vaccination_status') THEN
        ALTER TABLE pets ADD COLUMN vaccination_status JSONB;
    END IF;
END $$;

-- ============================================
-- STEP 2: Add missing columns to users table
-- ============================================

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'email_key') THEN
        ALTER TABLE users ADD COLUMN email_key TEXT UNIQUE;
        UPDATE users SET email_key = LOWER(REPLACE(email, '.', '_')) WHERE email_key IS NULL;
    END IF;
END $$;

-- ============================================
-- STEP 3: Refresh schema cache
-- ============================================
SELECT pg_notify('pgrst', 'reload schema');

-- ============================================
-- STEP 4: Create ID mapping for UUID migration
-- ============================================
CREATE TEMP TABLE id_map AS 
SELECT id as old_id, gen_random_uuid() as new_id 
FROM users WHERE id::text ~ '^[0-9]+$';

-- ============================================
-- STEP 5: Update users table
-- ============================================
UPDATE users u SET id = m.new_id FROM id_map m WHERE u.id = m.old_id::uuid;

-- ============================================
-- STEP 6: Update pets table
-- ============================================
UPDATE pets p SET owner_id = m.new_id FROM id_map m WHERE p.owner_id = m.old_id::uuid;

-- ============================================
-- STEP 7: Update appointments table
-- ============================================
UPDATE appointments SET owner_id = map.new_id FROM id_map map WHERE owner_id = map.old_id::uuid;
UPDATE appointments SET doctor_id = map.new_id FROM id_map map WHERE doctor_id = map.old_id::uuid;
UPDATE appointments SET driver_id = map.new_id FROM id_map map WHERE driver_id = map.old_id::uuid;

-- ============================================
-- STEP 8: Update medical_records table
-- ============================================
UPDATE medical_records SET doctor_id = map.new_id FROM id_map map WHERE doctor_id = map.old_id::uuid;

-- ============================================
-- STEP 9: Update notifications table
-- ============================================
UPDATE notifications SET user_id = map.new_id FROM id_map map WHERE user_id = map.old_id::uuid;

-- ============================================
-- STEP 10: Update service_requests table
-- ============================================
UPDATE service_requests SET owner_id = map.new_id FROM id_map map WHERE owner_id = map.old_id::uuid;
UPDATE service_requests SET assigned_doctor_id = map.new_id FROM id_map map WHERE assigned_doctor_id = map.old_id::uuid;

-- ============================================
-- STEP 11: Update schedules table
-- ============================================
UPDATE schedules SET doctor_id = map.new_id FROM id_map map WHERE doctor_id = map.old_id::uuid;

-- ============================================
-- STEP 12: Update driver_status table
-- ============================================
UPDATE driver_status SET driver_id = map.new_id FROM id_map map WHERE driver_id = map.old_id::uuid;

-- ============================================
-- STEP 13: Update routes table
-- ============================================
UPDATE routes SET driver_id = map.new_id FROM id_map map WHERE driver_id = map.old_id::uuid;

-- ============================================
-- STEP 14: Update payments table
-- ============================================
UPDATE payments SET user_id = map.new_id FROM id_map map WHERE user_id = map.old_id::uuid;

-- ============================================
-- STEP 15: Update vans table (if columns exist)
-- ============================================
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'vans' AND column_name = 'assigned_driver_id') THEN
        UPDATE vans SET assigned_driver_id = map.new_id FROM id_map map WHERE assigned_driver_id = map.old_id::uuid;
    END IF;
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'vans' AND column_name = 'assigned_doctor_id') THEN
        UPDATE vans SET assigned_doctor_id = map.new_id FROM id_map map WHERE assigned_doctor_id = map.old_id::uuid;
    END IF;
END $$;

-- ============================================
-- STEP 16: Update doctor_verification_documents
-- ============================================
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'doctor_verification_documents' AND column_name = 'doctor_id') THEN
        UPDATE doctor_verification_documents SET doctor_id = map.new_id FROM id_map map WHERE doctor_id = map.old_id::uuid;
    END IF;
END $$;

-- ============================================
-- STEP 17: Update driver_verification_documents
-- ============================================
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'driver_verification_documents' AND column_name = 'driver_id') THEN
        UPDATE driver_verification_documents SET driver_id = map.new_id FROM id_map map WHERE driver_id = map.old_id::uuid;
    END IF;
END $$;

-- ============================================
-- STEP 18: Refresh schema cache again
-- ============================================
SELECT pg_notify('pgrst', 'reload schema');

-- ============================================
-- VERIFICATION
-- ============================================

-- Check columns exist
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'pets' AND column_name IN ('medical_history_summary', 'serial_number', 'vaccination_status');

-- Check remaining integer IDs
SELECT 'Users with integer IDs:' as check_name, COUNT(*) as count
FROM users WHERE id::text ~ '^[0-9]+$';

-- Show sample UUIDs
SELECT id, email, name FROM users LIMIT 3;

-- Clean up
DROP TABLE id_map;

SELECT 'All fixes applied successfully!' as result;
