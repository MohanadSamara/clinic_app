-- ============================================
-- COMPLETE FIX: Drop ALL existing policies and create permissive ones
-- ============================================

-- STEP 1: Drop ALL existing policies on appointments
DO $$
DECLARE
    pol text;
BEGIN
    FOR pol IN SELECT policyname FROM pg_policies WHERE tablename = 'appointments' LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON appointments', pol);
    END LOOP;
END $$;

-- STEP 2: Create simple permissive policy (allows ALL authenticated access)
CREATE POLICY "anyone_authenticated" ON appointments
    FOR ALL
    USING (auth.role() = 'authenticated')
    WITH CHECK (auth.role() = 'authenticated');

-- STEP 3: Also create bypass policy for anonymous (if needed)
CREATE POLICY "public_read" ON appointments
    FOR SELECT
    USING (true);

-- STEP 4: Verify policies
SELECT policyname, cmd, 
       CASE WHEN qual IS NULL THEN 'no condition' ELSE 'has condition' END as condition
FROM pg_policies WHERE tablename = 'appointments';

-- STEP 5: Check if RLS is enabled
SELECT 
    'RLS Enabled: ' || rowsecurity::text as status
FROM pg_tables 
WHERE tablename = 'appointments';

-- STEP 6: Test visibility (should show all appointments)
SELECT 
    'Total appointments visible: ' || COUNT(*)::text as result
FROM appointments;

-- STEP 7: Refresh schema cache
NOTIFY pgrst, 'reload schema';

-- ============================================
-- VERIFY THE ACTUAL APPOINTMENT DATES
-- ============================================
SELECT 
    id,
    service_type,
    status,
    scheduled_at,
    -- Show if appointment is in the past or future
    CASE 
        WHEN scheduled_at > NOW() THEN '🔮 FUTURE'
        WHEN scheduled_at < NOW() THEN '📅 PAST'
        ELSE '⚡ TODAY'
    END as time_status
FROM appointments
ORDER BY scheduled_at;

-- ============================================
-- CHECK YOUR CURRENT DATE
-- ============================================
SELECT 
    NOW() as current_time,
    'Your device date should match this' as note;

