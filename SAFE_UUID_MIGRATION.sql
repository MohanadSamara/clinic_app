-- Safe UUID Migration Script
-- Run this in Supabase SQL Editor
-- Only updates tables that actually exist with the correct columns

-- ============================================
-- STEP 1: Create ID mapping
-- ============================================
CREATE TEMP TABLE id_map AS 
SELECT id as old_id, gen_random_uuid() as new_id 
FROM users WHERE id::text ~ '^[0-9]+$';

-- ============================================
-- STEP 2: Update users table
-- ============================================
UPDATE users u SET id = m.new_id FROM id_map m WHERE u.id = m.old_id::uuid;

-- ============================================
-- STEP 3: Update pets table
-- ============================================
UPDATE pets p SET owner_id = m.new_id FROM id_map m WHERE p.owner_id = m.old_id::uuid;

-- ============================================
-- STEP 4: Update appointments table
-- ============================================
UPDATE appointments a SET owner_id = m.new_id FROM id_map m WHERE a.owner_id = m.old_id::uuid;
UPDATE appointments a SET doctor_id = m.new_id FROM id_map m WHERE a.doctor_id = m.old_id::uuid;
UPDATE appointments a SET driver_id = m.new_id FROM id_map m WHERE a.driver_id = m.old_id::uuid;

-- ============================================
-- STEP 5: Update medical_records table
-- ============================================
UPDATE medical_records SET doctor_id = map.new_id FROM id_map map WHERE doctor_id = map.old_id::uuid;

-- ============================================
-- STEP 6: Update notifications table
-- ============================================
UPDATE notifications SET user_id = m.new_id FROM id_map m WHERE user_id = m.old_id::uuid;

-- ============================================
-- STEP 7: Update service_requests table
-- ============================================
UPDATE service_requests SET owner_id = m.new_id FROM id_map m WHERE owner_id = m.old_id::uuid;
UPDATE service_requests SET assigned_doctor_id = m.new_id FROM id_map m WHERE assigned_doctor_id = m.old_id::uuid;

-- ============================================
-- STEP 8: Update schedules table
-- ============================================
UPDATE schedules SET doctor_id = m.new_id FROM id_map m WHERE doctor_id = m.old_id::uuid;

-- ============================================
-- STEP 9: Update driver_status table
-- ============================================
UPDATE driver_status SET driver_id = m.new_id FROM id_map m WHERE driver_id = m.old_id::uuid;

-- ============================================
-- STEP 10: Update routes table
-- ============================================
UPDATE routes SET driver_id = m.new_id FROM id_map m WHERE driver_id = m.old_id::uuid;

-- ============================================
-- STEP 11: Update payments table
-- ============================================
UPDATE payments SET user_id = m.new_id FROM id_map m WHERE user_id = m.old_id::uuid;

-- ============================================
-- STEP 12: Update vans table (if columns exist)
-- ============================================
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'vans' AND column_name = 'assigned_driver_id') THEN
        UPDATE vans SET assigned_driver_id = m.new_id FROM id_map m WHERE assigned_driver_id = m.old_id::uuid;
    END IF;
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'vans' AND column_name = 'assigned_doctor_id') THEN
        UPDATE vans SET assigned_doctor_id = m.new_id FROM id_map m WHERE assigned_doctor_id = m.old_id::uuid;
    END IF;
END $$;

-- ============================================
-- STEP 13: Update doctor_verification_documents
-- ============================================
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'doctor_verification_documents' AND column_name = 'doctor_id') THEN
        UPDATE doctor_verification_documents SET doctor_id = m.new_id FROM id_map m WHERE doctor_id = m.old_id::uuid;
    END IF;
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'doctor_verification_documents' AND column_name = 'reviewer_id') THEN
        UPDATE doctor_verification_documents SET reviewer_id = m.new_id FROM id_map m WHERE reviewer_id = m.old_id::uuid;
    END IF;
END $$;

-- ============================================
-- STEP 14: Update driver_verification_documents
-- ============================================
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'driver_verification_documents' AND column_name = 'driver_id') THEN
        UPDATE driver_verification_documents SET driver_id = m.new_id FROM id_map m WHERE driver_id = m.old_id::uuid;
    END IF;
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'driver_verification_documents' AND column_name = 'reviewer_id') THEN
        UPDATE driver_verification_documents SET reviewer_id = m.new_id FROM id_map m WHERE reviewer_id = m.old_id::uuid;
    END IF;
END $$;

-- ============================================
-- STEP 15: Update vehicle_checks
-- ============================================
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'vehicle_checks' AND column_name = 'driver_id') THEN
        UPDATE vehicle_checks SET driver_id = m.new_id FROM id_map m WHERE driver_id = m.old_id::uuid;
    END IF;
END $$;

-- ============================================
-- STEP 16: Update audit_logs
-- ============================================
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'audit_logs' AND column_name = 'user_id') THEN
        UPDATE audit_logs SET user_id = m.new_id FROM id_map m WHERE user_id = m.old_id::uuid;
    END IF;
END $$;

-- ============================================
-- STEP 17: Update driver_verification_audit_logs
-- ============================================
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'driver_verification_audit_logs' AND column_name = 'user_id') THEN
        UPDATE driver_verification_audit_logs SET user_id = m.new_id FROM id_map m WHERE user_id = m.old_id::uuid;
    END IF;
END $$;

-- ============================================
-- STEP 18: Update documents table (if exists)
-- ============================================
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'documents' AND column_name = 'uploaded_by') THEN
        UPDATE documents SET uploaded_by = m.new_id FROM id_map m WHERE uploaded_by = m.old_id::uuid;
    END IF;
END $$;

-- ============================================
-- STEP 19: Update doctors table (if exists)
-- ============================================
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'doctors' AND column_name = 'user_id') THEN
        UPDATE doctors SET user_id = m.new_id FROM id_map m WHERE user_id = m.old_id::uuid;
    END IF;
END $$;

-- ============================================
-- VERIFICATION
-- ============================================

-- Check remaining integer IDs
SELECT 'Users with integer IDs:' as check_name, COUNT(*) as count
FROM users WHERE id::text ~ '^[0-9]+$'
UNION ALL
SELECT 'Pets with integer owner_id:', COUNT(*)
FROM pets WHERE owner_id::text ~ '^[0-9]+$'
UNION ALL
SELECT 'Appointments with integer owner_id:', COUNT(*)
FROM appointments WHERE owner_id::text ~ '^[0-9]+$';

-- Show sample data
SELECT 'Sample users:' as info;
SELECT id, email, name FROM users LIMIT 3;

SELECT 'Sample pets:' as info;
SELECT p.id, p.name, p.owner_id FROM pets p LIMIT 3;

-- Clean up
DROP TABLE id_map;

-- ============================================
-- REFRESH SCHEMA CACHE
-- ============================================
SELECT pg_notify('pgrst', 'reload schema');

SELECT 'Migration complete!' as result;
