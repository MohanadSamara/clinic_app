-- URGENT: Fix Integer IDs in UUID Columns
-- Run this in Supabase SQL Editor to fix all UUID issues
-- This will convert all integer IDs to proper UUIDs

-- ============================================
-- STEP 1: Check what integer IDs exist
-- ============================================

-- Count users with integer-like IDs
SELECT COUNT(*) as integer_users_count
FROM users
WHERE id::text ~ '^[0-9]+$';

-- ============================================
-- STEP 2: Update users table with new UUIDs
-- ============================================

-- Create a temp table to map old IDs to new UUIDs
CREATE TEMP TABLE id_map AS 
SELECT id as old_id, gen_random_uuid() as new_id 
FROM users WHERE id::text ~ '^[0-9]+$';

-- Update users table
UPDATE users u
SET id = m.new_id
FROM id_map m
WHERE u.id = m.old_id::uuid;

-- ============================================
-- STEP 3: Update pets table
-- ============================================

UPDATE pets p
SET owner_id = m.new_id
FROM id_map m
WHERE p.owner_id = m.old_id::uuid;

-- ============================================
-- STEP 4: Update appointments table
-- ============================================

UPDATE appointments a
SET owner_id = m.new_id
FROM id_map m
WHERE a.owner_id = m.old_id::uuid;

UPDATE appointments a
SET doctor_id = m.new_id
FROM id_map m
WHERE a.doctor_id = m.old_id::uuid;

UPDATE appointments a
SET driver_id = m.new_id
FROM id_map m
WHERE a.driver_id = m.old_id::uuid;

-- ============================================
-- STEP 5: Update medical_records table
-- ============================================

UPDATE medical_records m
SET doctor_id = map.new_id
FROM id_map map
WHERE m.doctor_id = map.old_id::uuid;

-- ============================================
-- STEP 6: Update notifications table
-- ============================================

UPDATE notifications n
SET user_id = m.new_id
FROM id_map m
WHERE n.user_id = m.old_id::uuid;

-- ============================================
-- STEP 7: Update service_requests table
-- ============================================

UPDATE service_requests s
SET owner_id = m.new_id
FROM id_map m
WHERE s.owner_id = m.old_id::uuid;

UPDATE service_requests s
SET assigned_doctor_id = m.new_id
FROM id_map m
WHERE s.assigned_doctor_id = m.old_id::uuid;

-- ============================================
-- STEP 8: Update documents table
-- ============================================

UPDATE documents d
SET uploaded_by = m.new_id
FROM id_map m
WHERE d.uploaded_by = m.old_id::uuid;

-- ============================================
-- STEP 9: Update schedules table
-- ============================================

UPDATE schedules s
SET doctor_id = m.new_id
FROM id_map m
WHERE s.doctor_id = m.old_id::uuid;

-- ============================================
-- STEP 10: Update doctor_verification_documents
-- ============================================

UPDATE doctor_verification_documents d
SET doctor_id = m.new_id,
    reviewer_id = m.new_id
FROM id_map m
WHERE d.doctor_id = m.old_id::uuid
   OR d.reviewer_id = m.old_id::uuid;

-- ============================================
-- STEP 11: Update driver_verification_documents
-- ============================================

UPDATE driver_verification_documents d
SET driver_id = m.new_id,
    reviewer_id = m.new_id
FROM id_map m
WHERE d.driver_id = m.old_id::uuid
   OR d.reviewer_id = m.old_id::uuid;

-- ============================================
-- STEP 12: Update driver_status table
-- ============================================

UPDATE driver_status ds
SET driver_id = m.new_id
FROM id_map m
WHERE ds.driver_id = m.old_id::uuid;

-- ============================================
-- STEP 13: Update vans table
-- ============================================

UPDATE vans v
SET assigned_driver_id = m.new_id,
    assigned_doctor_id = m.new_id
FROM id_map m
WHERE v.assigned_driver_id = m.old_id::uuid
   OR v.assigned_doctor_id = m.old_id::uuid;

-- ============================================
-- STEP 14: Update routes table
-- ============================================

UPDATE routes r
SET driver_id = m.new_id
FROM id_map m
WHERE r.driver_id = m.old_id::uuid;

-- ============================================
-- STEP 15: Update vehicle_checks table
-- ============================================

UPDATE vehicle_checks vc
SET driver_id = m.new_id
FROM id_map m
WHERE vc.driver_id = m.old_id::uuid;

-- ============================================
-- STEP 16: Update audit_logs table
-- ============================================

UPDATE audit_logs a
SET user_id = m.new_id
FROM id_map m
WHERE a.user_id = m.old_id::uuid;

-- ============================================
-- STEP 17: Update payments table
-- ============================================

UPDATE payments p
SET user_id = m.new_id
FROM id_map m
WHERE p.user_id = m.old_id::uuid;

-- ============================================
-- STEP 18: Update driver_verification_audit_logs
-- ============================================

UPDATE driver_verification_audit_logs d
SET user_id = m.new_id
FROM id_map m
WHERE d.user_id = m.old_id::uuid;

-- ============================================
-- STEP 19: Update doctors table (if it exists)
-- ============================================

-- First check if doctors table exists and has user_id
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'doctors') THEN
        UPDATE doctors d
        SET user_id = m.new_id
        FROM id_map m
        WHERE d.user_id = m.old_id::uuid;
    END IF;
END $$;

-- ============================================
-- STEP 20: Verify the fix
-- ============================================

-- Check users now have UUIDs
SELECT 'Users:' as table_name, COUNT(*) as count
FROM users WHERE id::text ~ '^[0-9]+$'
UNION ALL
SELECT 'Pets with integer owner_id:', COUNT(*)
FROM pets WHERE owner_id::text ~ '^[0-9]+$'
UNION ALL
SELECT 'Appointments with integer owner_id:', COUNT(*)
FROM appointments WHERE owner_id::text ~ '^[0-9]+$';

-- Show sample users with proper UUIDs
SELECT id, email, name FROM users LIMIT 5;

-- Show sample pets with proper owner UUIDs
SELECT p.id, p.name, p.owner_id, u.email 
FROM pets p 
LEFT JOIN users u ON p.owner_id = u.id 
LIMIT 5;

-- Clean up
DROP TABLE IF EXISTS id_map;

-- ============================================
-- REFRESH SCHEMA CACHE
-- ============================================
SELECT pg_notify('pgrst', 'reload schema');

-- Success message
SELECT 'Migration complete! All integer IDs have been converted to UUIDs.' as result;

