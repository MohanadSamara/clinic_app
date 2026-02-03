-- ============================================
-- QUICK FIX: Make appointments visible to all authenticated users
-- Run this in Supabase SQL Editor
-- ============================================

-- STEP 1: Drop the restrictive policy
DROP POLICY IF EXISTS permissive_all_access ON appointments;

-- STEP 2: Create a simple permissive policy
CREATE POLICY "allow_all_authenticated" ON appointments
    FOR SELECT
    USING (auth.role() = 'authenticated');

-- STEP 3: Also allow INSERT/UPDATE/DELETE for authenticated users
CREATE POLICY "allow_all_insert" ON appointments
    FOR INSERT
    WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "allow_all_update" ON appointments
    FOR UPDATE
    USING (auth.role() = 'authenticated');

CREATE POLICY "allow_all_delete" ON appointments
    FOR DELETE
    USING (auth.role() = 'authenticated');

-- STEP 4: Verify the fix
SELECT 
    'Policies created: ' || COUNT(*)::text as result
FROM pg_policies 
WHERE tablename = 'appointments';

-- STEP 5: Test visibility
SELECT 
    '✅ Appointments visible: ' || COUNT(*)::text as result
FROM appointments;

-- STEP 6: Refresh schema cache
SELECT pg_notify('pgrst', 'reload schema');

-- DONE! Now test in your app

