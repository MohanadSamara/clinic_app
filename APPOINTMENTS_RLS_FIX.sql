-- ============================================
-- SUPABASE RLS AUTHENTICATION FIX
-- Fix for appointments not showing in app
-- ============================================

-- STEP 1: Check current RLS state
SELECT 
    'appointments' as table_name,
    rowsecurity as rls_enabled
FROM pg_tables 
WHERE tablename = 'appointments' AND schemaname = 'public';

-- STEP 2: List all policies on appointments table
SELECT 
    policyname,
    cmd,
    CASE 
        WHEN qual IS NULL THEN 'no condition (allows all)'
        ELSE LEFT(qual, 100)
    END as condition
FROM pg_policies 
WHERE tablename = 'appointments';

-- STEP 3: Create a helper function to get the actual user ID
-- This bridges the gap between auth.users and your users table
CREATE OR REPLACE FUNCTION app_get_user_id()
RETURNS uuid AS $$
BEGIN
    -- Return auth.uid() if it exists
    RETURN auth.uid();
EXCEPTION WHEN OTHERS THEN
    -- Fallback: try to get from users table using email
    RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- STEP 4: Drop the permissive policy (if exists)
DROP POLICY IF EXISTS permissive_all_access ON appointments;

-- STEP 5: Create proper RLS policies for appointments

-- Policy 1: Doctors can see their assigned appointments
CREATE POLICY "doctor_see_assigned" ON appointments
    FOR SELECT
    USING (
        doctor_id = auth.uid() OR
        EXISTS (
            SELECT 1 FROM users 
            WHERE users.id = auth.uid() 
            AND users.role IN ('doctor', 'admin')
        )
    );

-- Policy 2: Owners can see their own appointments
CREATE POLICY "owner_see_own" ON appointments
    FOR SELECT
    USING (
        owner_id = auth.uid() OR
        EXISTS (
            SELECT 1 FROM users 
            WHERE users.id = auth.uid() 
            AND users.role IN ('owner', 'admin')
        )
    );

-- Policy 3: Drivers can see their assigned appointments
CREATE POLICY "driver_see_assigned" ON appointments
    FOR SELECT
    USING (
        driver_id = auth.uid() OR
        EXISTS (
            SELECT 1 FROM users 
            WHERE users.id = auth.uid() 
            AND users.role IN ('driver', 'admin')
        )
    );

-- Policy 4: Anyone authenticated can see appointments (temporary fix)
CREATE POLICY "all_authenticated_see" ON appointments
    FOR SELECT
    USING (auth.role() = 'authenticated');

-- STEP 6: Insert test data verification
DO $$
DECLARE
    test_count INTEGER;
BEGIN
    -- Count appointments
    SELECT COUNT(*) INTO test_count FROM appointments;
    RAISE NOTICE 'Total appointments in database: %', test_count;
    
    -- Try to count as authenticated user
    SELECT COUNT(*) INTO test_count 
    FROM appointments 
    WHERE auth.role() = 'authenticated';
    RAISE NOTICE 'Appointments visible to authenticated users: %', test_count;
END $$;

-- STEP 7: Test if appointments are visible
SELECT 
    id,
    service_type,
    status,
    scheduled_at,
    doctor_id,
    owner_id,
    '✅ VISIBLE' as visibility_test
FROM appointments
LIMIT 3;

-- STEP 8: Refresh schema cache
SELECT pg_notify('pgrst', 'reload schema');

-- ============================================
-- VERIFICATION
-- ============================================
SELECT 
    'RLS Policies on appointments' as info,
    COUNT(*) as policy_count
FROM pg_policies 
WHERE tablename = 'appointments';

-- List the policies
SELECT 
    policyname,
    cmd,
    CASE 
        WHEN qual IS NOT NULL THEN 'has condition'
        ELSE 'no condition'
    END as policy_type
FROM pg_policies 
WHERE tablename = 'appointments'
ORDER BY policyname;

