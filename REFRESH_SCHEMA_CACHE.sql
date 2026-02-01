-- REFRESH SCHEMA CACHE ONLY
-- Run this in Supabase SQL Editor to fix PGRST204 errors

-- Refresh the PostgREST schema cache
NOTIFY pgrst, 'reload schema';

-- Verify the vans table has the 'area' column
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'vans' 
ORDER BY ordinal_position;

-- Verify the users table has the 'provider_id' column
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'users' AND column_name = 'provider_id'
ORDER BY ordinal_position;

-- Verify all users columns
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'users' 
ORDER BY ordinal_position;

-- List all tables to confirm schema is loaded
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
ORDER BY table_name;

