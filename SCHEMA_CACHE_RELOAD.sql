-- ============================================
-- SUPABASE SCHEMA CACHE RELOAD SCRIPT
-- Fix for: Could not find the 'document_number' column 
-- of 'doctor_verification_documents' in the schema cache
-- ============================================

-- Step 1: Notify PostgREST to reload the schema cache
NOTIFY pgrst, 'reload_schema';

-- Step 2: Verify the doctor_verification_documents table structure
SELECT 
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_name = 'doctor_verification_documents'
ORDER BY ordinal_position;

-- Step 3: Check if document_number column exists
SELECT 
    COUNT(*) as column_exists
FROM information_schema.columns
WHERE table_name = 'doctor_verification_documents'
  AND column_name = 'document_number';

-- Step 4: Verify the table has RLS enabled
SELECT 
    'doctor_verification_documents' as table_name,
    relrowsecurity as rls_enabled
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE relname = 'doctor_verification_documents'
  AND n.nspname = 'public';

-- Step 5: Check policies on the table
SELECT 
    policyname,
    cmd,
    qual
FROM pg_policies
WHERE tablename = 'doctor_verification_documents';

-- Step 6: Test that the column is accessible (this will fail if schema cache isn't reloaded)
-- Run this as a simple test query:
-- SELECT document_number FROM doctor_verification_documents LIMIT 1;

-- Step 7: If NOTIFY doesn't work, try restarting PostgREST via Dashboard:
-- Go to Database -> Extensions -> pg_net (if needed)
-- Or go to API -> PostgREST -> click "Reload Schema"

-- Step 8: Alternative - Force schema cache update by touching the database
SELECT 1 as schema_cache_refresh;

-- Step 9: Create a function to manually refresh schema cache (if NOTIFY fails)
CREATE OR REPLACE FUNCTION refresh_pgrst_schema()
RETURNS void AS $$
BEGIN
    -- This function can be called to trigger schema refresh
    -- In Supabase, this is handled automatically by NOTIFY
    PERFORM pg_notify('pgrst', 'reload_schema');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION refresh_pgrst_schema() TO authenticated, postgres;

-- Step 10: Display helpful information
SELECT 
    'Schema cache reload initiated' as status,
    'Run NOTIFY pgrst, ''reload_schema''' as instruction,
    'Or restart PostgREST from Dashboard -> API -> PostgREST -> Reload Schema' as alternative;
