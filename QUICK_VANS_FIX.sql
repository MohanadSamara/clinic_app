-- QUICK FIX FOR VANS TABLE - FULLY PERMISSIVE
-- Run this in Supabase SQL Editor

-- Step 1: Disable RLS on vans
ALTER TABLE vans DISABLE ROW LEVEL SECURITY;

-- Step 2: Drop all existing van policies
DO $$
DECLARE
    pol text;
BEGIN
    FOR pol IN SELECT policyname FROM pg_policies WHERE tablename = 'vans' AND schemaname = 'public'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON vans', pol);
    END LOOP;
END $$;

-- Step 3: Re-enable RLS with permissive policies
ALTER TABLE vans ENABLE ROW LEVEL SECURITY;

-- Policy: Any authenticated user can insert vans
CREATE POLICY "vans_auth_insert" ON vans
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- Policy: Any authenticated user can select vans
CREATE POLICY "vans_auth_select" ON vans
    FOR SELECT USING (auth.role() = 'authenticated');

-- Policy: Any authenticated user can update vans
CREATE POLICY "vans_auth_update" ON vans
    FOR UPDATE USING (auth.role() = 'authenticated');

-- Policy: Any authenticated user can delete vans
CREATE POLICY "vans_auth_delete" ON vans
    FOR DELETE USING (auth.role() = 'authenticated');

-- Step 4: Refresh schema
SELECT pg_notify('pgrst', 'reload schema');

-- Verify
SELECT 'RLS enabled: ' || rowsecurity::text FROM pg_tables 
WHERE tablename = 'vans' AND schemaname = 'public';

SELECT policyname, cmd, qual FROM pg_policies WHERE tablename = 'vans';
