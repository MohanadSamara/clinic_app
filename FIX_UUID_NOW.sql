-- URGENT FIX: Convert all UUID columns to TEXT to accept numeric IDs
-- Run this first in Supabase SQL Editor

-- Drop foreign key constraints
ALTER TABLE users DROP CONSTRAINT IF EXISTS users_linked_doctor_id_fkey;
ALTER TABLE users DROP CONSTRAINT IF EXISTS users_linked_driver_id_fkey;
ALTER TABLE vans DROP CONSTRAINT IF EXISTS vans_assigned_doctor_id_fkey;
ALTER TABLE vans DROP CONSTRAINT IF EXISTS vans_assigned_driver_id_fkey;

-- Change users table columns from UUID to TEXT
ALTER TABLE users ALTER COLUMN linked_doctor_id TYPE TEXT;
ALTER TABLE users ALTER COLUMN linked_driver_id TYPE TEXT;

-- Change vans table columns from UUID to TEXT
ALTER TABLE vans ALTER COLUMN assigned_doctor_id TYPE TEXT;
ALTER TABLE vans ALTER COLUMN assigned_driver_id TYPE TEXT;

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';

-- Confirm changes
SELECT column_name, data_type FROM information_schema.columns 
WHERE table_name IN ('users', 'vans') 
AND column_name IN ('linked_doctor_id', 'linked_driver_id', 'assigned_doctor_id', 'assigned_driver_id')
ORDER BY table_name, column_name;
