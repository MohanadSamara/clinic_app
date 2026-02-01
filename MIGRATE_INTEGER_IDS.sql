-- Migration script to fix old integer IDs stored in UUID columns
-- Run this in Supabase SQL Editor

-- ============================================
-- STEP 1: Check current data with integer IDs
-- ============================================

-- Look for users with integer-like IDs (hashCodes)
SELECT id, email, name, LEFT(id::text, 1) as id_start
FROM users
WHERE id::text ~ '^[0-9]+$'
LIMIT 10;

-- ============================================
-- STEP 2: Create a mapping table for old IDs to new UUIDs
-- ============================================

-- Create a temporary mapping table
CREATE TEMP TABLE user_id_mapping (
    old_id TEXT PRIMARY KEY,
    new_id UUID DEFAULT gen_random_uuid()
);

-- Populate with users that have integer-like IDs
INSERT INTO user_id_mapping (old_id)
SELECT id::text FROM users WHERE id::text ~ '^[0-9]+$';

-- ============================================
-- STEP 3: Update pets table
-- ============================================

-- First, update pets that reference old integer IDs
UPDATE pets p
SET owner_id = m.new_id
FROM user_id_mapping m
WHERE p.owner_id::text = m.old_id;

-- ============================================
-- STEP 4: Update appointments table
-- ============================================

UPDATE appointments a
SET owner_id = m.new_id
FROM user_id_mapping m
WHERE a.owner_id::text = m.old_id;

UPDATE appointments a
SET doctor_id = m.new_id
FROM user_id_mapping m
WHERE a.doctor_id::text = m.old_id;

UPDATE appointments a
SET driver_id = m.new_id
FROM user_id_mapping m
WHERE a.driver_id::text = m.old_id;

-- ============================================
-- STEP 5: Update medical_records table
-- ============================================

UPDATE medical_records m
SET doctor_id = map.new_id
FROM user_id_mapping map
WHERE m.doctor_id::text = map.old_id;

-- ============================================
-- STEP 6: Update notifications table
-- ============================================

UPDATE notifications n
SET user_id = m.new_id
FROM user_id_mapping m
WHERE n.user_id::text = m.old_id;

-- ============================================
-- STEP 7: Update service_requests table
-- ============================================

UPDATE service_requests s
SET owner_id = m.new_id
FROM user_id_mapping m
WHERE s.owner_id::text = m.old_id;

UPDATE service_requests s
SET assigned_doctor_id = m.new_id
FROM user_id_mapping m
WHERE s.assigned_doctor_id::text = m.old_id;

-- ============================================
-- STEP 8: Update the users table itself
-- ============================================

UPDATE users u
SET id = m.new_id
FROM user_id_mapping m
WHERE u.id::text = m.old_id;

-- ============================================
-- STEP 9: Verify the migration
-- ============================================

-- Check that users now have proper UUIDs
SELECT id, email, name FROM users LIMIT 5;

-- Check that pets have proper owner UUIDs
SELECT p.id, p.name, p.owner_id, u.email as owner_email
FROM pets p
LEFT JOIN users u ON p.owner_id = u.id
LIMIT 5;

-- ============================================
-- STEP 10: Show the mapping for reference
-- ============================================

SELECT * FROM user_id_mapping;

-- Clean up
DROP TABLE user_id_mapping;

-- ============================================
-- REFRESH POSTGREST SCHEMA CACHE
-- ============================================
SELECT pg_notify('pgrst', 'reload schema');

