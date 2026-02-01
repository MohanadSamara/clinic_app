-- ============================================
-- VANS TABLE RLS FIX
-- Run this in Supabase SQL Editor to fix the vans table insert error
-- ============================================

-- Step 1: Disable RLS on vans table temporarily
ALTER TABLE vans DISABLE ROW LEVEL SECURITY;

-- Step 2: Drop existing policies on vans table
DROP POLICY IF EXISTS vans_select ON vans;
DROP POLICY IF EXISTS vans_insert ON vans;
DROP POLICY IF EXISTS vans_update ON vans;
DROP POLICY IF EXISTS vans_delete ON vans;

-- Step 3: Create new policies that allow authenticated users to work with vans
-- SELECT - Any authenticated user can view vans
CREATE POLICY "vans_select_all" ON vans
FOR SELECT
USING (auth.role() = 'authenticated');

-- INSERT - Any authenticated user can insert vans
CREATE POLICY "vans_insert_all" ON vans
FOR INSERT
WITH CHECK (auth.role() = 'authenticated');

-- UPDATE - Any authenticated user can update vans
CREATE POLICY "vans_update_all" ON vans
FOR UPDATE
USING (auth.role() = 'authenticated');

-- DELETE - Any authenticated user can delete vans
CREATE POLICY "vans_delete_all" ON vans
FOR DELETE
USING (auth.role() = 'authenticated');

-- Step 4: Re-enable RLS on vans table
ALTER TABLE vans ENABLE ROW LEVEL SECURITY;

-- Step 5: Verify the fix
SELECT 
    'vans' as table_name,
    rowsecurity as rls_enabled,
    (SELECT COUNT(*) FROM pg_policies WHERE tablename = 'vans') as policy_count
FROM pg_tables 
WHERE tablename = 'vans' AND schemaname = 'public';

-- Step 6: Test insert (optional - this will be done by the app)
-- INSERT INTO vans (name, license_plate, capacity, status) 
-- VALUES ('Test Van', 'ABC-123', 1, 'available');

