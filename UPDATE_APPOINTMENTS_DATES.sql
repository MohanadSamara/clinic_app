-- ============================================
-- UPDATE APPOINTMENTS TO TODAY (2025-02-01)
-- This will make appointments visible in your app
-- ============================================

-- STEP 1: Update all appointments to today's date
UPDATE appointments
SET 
    scheduled_at = NOW() + INTERVAL '2 hours',
    created_at = NOW(),
    updated_at = NOW()
WHERE scheduled_at > NOW() + INTERVAL '1 year';

-- STEP 2: Verify the update
SELECT 
    id,
    service_type,
    status,
    scheduled_at,
    -- Show the date part only
    TO_CHAR(scheduled_at, 'YYYY-MM-DD') as date_only,
    -- Show if today or future
    CASE 
        WHEN scheduled_at::date = NOW()::date THEN '📅 TODAY'
        WHEN scheduled_at::date > NOW()::date THEN '🔮 FUTURE'
        ELSE '⏰ PAST'
    END as visibility
FROM appointments
ORDER BY scheduled_at;

-- STEP 3: Count appointments
SELECT COUNT(*) as total_appointments FROM appointments;

-- ============================================
-- RLS FIX (run this FIRST if not already done)
-- ============================================

-- Drop all existing policies
DO $$
DECLARE
    pol text;
BEGIN
    FOR pol IN SELECT policyname FROM pg_policies WHERE tablename = 'appointments' LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON appointments', pol);
    END LOOP;
END $$;

-- Create permissive policy
CREATE POLICY "anyone_authenticated" ON appointments
    FOR ALL
    USING (auth.role() = 'authenticated')
    WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "public_read" ON appointments
    FOR SELECT
    USING (true);

-- Verify RLS
SELECT 
    'Policies: ' || COUNT(*) as count,
    rowsecurity as rls_enabled
FROM pg_tables t
LEFT JOIN pg_policies p ON t.tablename = p.tablename
WHERE t.tablename = 'appointments'
GROUP BY t.tablename, t.rowsecurity;

-- Refresh schema
NOTIFY pgrst, 'reload schema';

-- ============================================
-- TEST: Should show all appointments now
-- ============================================
SELECT '✅ Ready! Total appointments: ' || COUNT(*)::text as status
FROM appointments;

