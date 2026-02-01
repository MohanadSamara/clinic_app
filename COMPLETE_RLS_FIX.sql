-- ============================================
-- COMPLETE RLS FIX FOR SUPABASE
-- Run this in Supabase SQL Editor to fix all RLS issues
-- ============================================

-- ============================================
-- STEP 1: DISABLE RLS ON ALL TABLES
-- ============================================

DO $$
DECLARE
    t text;
BEGIN
    FOR t IN SELECT tablename FROM pg_tables WHERE schemaname = 'public' LOOP
        EXECUTE format('ALTER TABLE %I DISABLE ROW LEVEL SECURITY', t);
    END LOOP;
END $$;

-- ============================================
-- STEP 2: DROP ALL EXISTING POLICIES
-- ============================================

DO $$
DECLARE
    pol RECORD;
BEGIN
    FOR pol IN 
        SELECT policyname, tablename FROM pg_policies WHERE schemaname = 'public'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON public.%I', pol.policyname, pol.tablename);
    END LOOP;
END $$;

-- ============================================
-- STEP 3: FIX USERS TABLE
-- ============================================

DROP TRIGGER IF EXISTS set_email_key_on_insert ON users;
DROP FUNCTION IF EXISTS generate_email_key();

ALTER TABLE users ALTER COLUMN email_key DROP NOT NULL;
UPDATE users SET email_key = LOWER(REPLACE(email, '.', '_')) WHERE email_key IS NULL OR email_key = '';

CREATE OR REPLACE FUNCTION generate_email_key()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.email_key IS NULL OR NEW.email_key = '' THEN
        NEW.email_key := LOWER(REPLACE(NEW.email, '.', '_'));
    END IF;
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER set_email_key_on_insert
    BEFORE INSERT ON users
    FOR EACH ROW
    EXECUTE FUNCTION generate_email_key();

ALTER TABLE users ENABLE ROW LEVEL SECURITY;
CREATE POLICY "users_pub_select" ON users FOR SELECT USING (true);
CREATE POLICY "users_pub_insert" ON users FOR INSERT WITH CHECK (true);
CREATE POLICY "users_own_update" ON users FOR UPDATE USING (auth.uid() = id);

-- ============================================
-- STEP 4: PETS TABLE
-- ============================================

ALTER TABLE pets ENABLE ROW LEVEL SECURITY;
CREATE POLICY "pets_owner_select" ON pets FOR SELECT USING (owner_id = auth.uid());
CREATE POLICY "pets_owner_insert" ON pets FOR INSERT WITH CHECK (owner_id = auth.uid());
CREATE POLICY "pets_owner_update" ON pets FOR UPDATE USING (owner_id = auth.uid());
CREATE POLICY "pets_owner_delete" ON pets FOR DELETE USING (owner_id = auth.uid());
CREATE POLICY "pets_doc_select" ON pets FOR SELECT USING (
    EXISTS (SELECT 1 FROM users WHERE users.id = auth.uid() AND users.role IN ('doctor', 'admin'))
);

-- ============================================
-- STEP 5: APPOINTMENTS TABLE
-- ============================================

ALTER TABLE appointments ENABLE ROW LEVEL SECURITY;
CREATE POLICY "appt_owner_select" ON appointments FOR SELECT USING (owner_id = auth.uid());
CREATE POLICY "appt_owner_insert" ON appointments FOR INSERT WITH CHECK (owner_id = auth.uid());
CREATE POLICY "appt_owner_update" ON appointments FOR UPDATE USING (owner_id = auth.uid());
CREATE POLICY "appt_doc_select" ON appointments FOR SELECT USING (
    doctor_id = auth.uid() OR
    EXISTS (SELECT 1 FROM users WHERE users.id = auth.uid() AND users.role IN ('doctor', 'admin'))
);
CREATE POLICY "appt_doc_update" ON appointments FOR UPDATE USING (
    doctor_id = auth.uid() OR
    EXISTS (SELECT 1 FROM users WHERE users.id = auth.uid() AND users.role = 'admin')
);
CREATE POLICY "appt_drv_select" ON appointments FOR SELECT USING (
    driver_id = auth.uid() OR
    EXISTS (SELECT 1 FROM users WHERE users.id = auth.uid() AND users.role IN ('driver', 'admin'))
);

-- ============================================
-- STEP 6: VANS TABLE (Critical Fix)
-- ============================================

ALTER TABLE vans ENABLE ROW LEVEL SECURITY;
CREATE POLICY "vans_auth_insert" ON vans FOR INSERT WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "vans_auth_select" ON vans FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "vans_auth_update" ON vans FOR UPDATE USING (auth.role() = 'authenticated');
CREATE POLICY "vans_auth_delete" ON vans FOR DELETE USING (auth.role() = 'authenticated');

-- ============================================
-- STEP 7: NOTIFICATIONS TABLE
-- ============================================

ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
CREATE POLICY "notif_user_select" ON notifications FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "notif_user_insert" ON notifications FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY "notif_user_update" ON notifications FOR UPDATE USING (user_id = auth.uid());
CREATE POLICY "notif_user_delete" ON notifications FOR DELETE USING (user_id = auth.uid());

-- ============================================
-- STEP 8: MEDICAL RECORDS TABLE
-- ============================================

ALTER TABLE medical_records ENABLE ROW LEVEL SECURITY;
CREATE POLICY "medrec_owner_select" ON medical_records FOR SELECT USING (
    EXISTS (SELECT 1 FROM pets WHERE pets.id = medical_records.pet_id AND pets.owner_id = auth.uid())
);
CREATE POLICY "medrec_doc_all" ON medical_records FOR ALL USING (
    EXISTS (SELECT 1 FROM users WHERE users.id = auth.uid() AND users.role IN ('doctor', 'admin'))
);

-- ============================================
-- STEP 9: DOCUMENTS TABLE
-- ============================================

ALTER TABLE documents ENABLE ROW LEVEL SECURITY;
CREATE POLICY "docs_owner_select" ON documents FOR SELECT USING (
    EXISTS (SELECT 1 FROM pets WHERE pets.id = documents.pet_id AND pets.owner_id = auth.uid())
);
CREATE POLICY "docs_owner_insert" ON documents FOR INSERT WITH CHECK (
    EXISTS (SELECT 1 FROM pets WHERE pets.id = documents.pet_id AND pets.owner_id = auth.uid())
);

-- ============================================
-- STEP 10: PAYMENTS TABLE
-- ============================================

ALTER TABLE payments ENABLE ROW LEVEL SECURITY;
CREATE POLICY "pay_user_select" ON payments FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "pay_user_insert" ON payments FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY "pay_admin_select" ON payments FOR SELECT USING (
    EXISTS (SELECT 1 FROM users WHERE users.id = auth.uid() AND users.role = 'admin')
);

-- ============================================
-- STEP 11: SERVICE REQUESTS TABLE
-- ============================================

ALTER TABLE service_requests ENABLE ROW LEVEL SECURITY;
CREATE POLICY "sreq_owner_select" ON service_requests FOR SELECT USING (owner_id = auth.uid());
CREATE POLICY "sreq_owner_insert" ON service_requests FOR INSERT WITH CHECK (owner_id = auth.uid());
CREATE POLICY "sreq_doc_select" ON service_requests FOR SELECT USING (
    assigned_doctor_id = auth.uid() OR
    EXISTS (SELECT 1 FROM users WHERE users.id = auth.uid() AND users.role IN ('doctor', 'admin'))
);

-- ============================================
-- STEP 12: VACCINATION RECORDS TABLE
-- ============================================

ALTER TABLE vaccination_records ENABLE ROW LEVEL SECURITY;
CREATE POLICY "vax_owner_select" ON vaccination_records FOR SELECT USING (
    EXISTS (SELECT 1 FROM pets WHERE pets.id = vaccination_records.pet_id AND pets.owner_id = auth.uid())
);
CREATE POLICY "vax_doc_insert" ON vaccination_records FOR INSERT WITH CHECK (
    EXISTS (SELECT 1 FROM users WHERE users.id = auth.uid() AND users.role IN ('doctor', 'admin'))
);

-- ============================================
-- STEP 13: DOCTORS TABLE
-- ============================================

ALTER TABLE doctors ENABLE ROW LEVEL SECURITY;
CREATE POLICY "doctors_pub_select" ON doctors FOR SELECT USING (true);
CREATE POLICY "doctors_own_update" ON doctors FOR UPDATE USING (
    user_id = auth.uid() OR
    EXISTS (SELECT 1 FROM users WHERE users.id = auth.uid() AND users.role = 'admin')
);

-- ============================================
-- STEP 14: SCHEDULES TABLE
-- ============================================

ALTER TABLE schedules ENABLE ROW LEVEL SECURITY;
CREATE POLICY "sched_doc_select" ON schedules FOR SELECT USING (doctor_id = auth.uid());
CREATE POLICY "sched_doc_all" ON schedules FOR ALL USING (
    doctor_id = auth.uid() OR
    EXISTS (SELECT 1 FROM users WHERE users.id = auth.uid() AND users.role = 'admin')
);

-- ============================================
-- STEP 15: DRIVER STATUS TABLE
-- ============================================

ALTER TABLE driver_status ENABLE ROW LEVEL SECURITY;
CREATE POLICY "drivstat_drv_all" ON driver_status FOR ALL USING (
    driver_id = auth.uid() OR
    EXISTS (SELECT 1 FROM users WHERE users.id = auth.uid() AND users.role IN ('driver', 'admin'))
);

-- ============================================
-- STEP 16: ROUTES TABLE
-- ============================================

ALTER TABLE routes ENABLE ROW LEVEL SECURITY;
CREATE POLICY "routes_drv_all" ON routes FOR ALL USING (
    driver_id = auth.uid() OR
    EXISTS (SELECT 1 FROM users WHERE users.id = auth.uid() AND users.role = 'admin')
);

-- ============================================
-- STEP 17: VEHICLE CHECKS TABLE
-- ============================================

ALTER TABLE vehicle_checks ENABLE ROW LEVEL SECURITY;
CREATE POLICY "vehcheck_drv_all" ON vehicle_checks FOR ALL USING (
    driver_id = auth.uid() OR
    EXISTS (SELECT 1 FROM users WHERE users.id = auth.uid() AND users.role = 'admin')
);

-- ============================================
-- STEP 18: ADMIN TABLES
-- ============================================

ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;
CREATE POLICY "audit_admin_select" ON audit_logs FOR SELECT USING (
    EXISTS (SELECT 1 FROM users WHERE users.id = auth.uid() AND users.role = 'admin')
);

ALTER TABLE compliance_logs ENABLE ROW LEVEL SECURITY;
CREATE POLICY "comp_admin_all" ON compliance_logs FOR ALL USING (
    EXISTS (SELECT 1 FROM users WHERE users.id = auth.uid() AND users.role = 'admin')
);

ALTER TABLE inventory ENABLE ROW LEVEL SECURITY;
CREATE POLICY "inv_admin_all" ON inventory FOR ALL USING (
    EXISTS (SELECT 1 FROM users WHERE users.id = auth.uid() AND users.role = 'admin')
);

ALTER TABLE system_settings ENABLE ROW LEVEL SECURITY;
CREATE POLICY "sett_admin_all" ON system_settings FOR ALL USING (
    EXISTS (SELECT 1 FROM users WHERE users.id = auth.uid() AND users.role = 'admin')
);

-- ============================================
-- STEP 19: PAGES AND SERVICES (Public Read)
-- ============================================

ALTER TABLE pages ENABLE ROW LEVEL SECURITY;
CREATE POLICY "pages_pub_select" ON pages FOR SELECT USING (is_published = true);
CREATE POLICY "pages_admin_all" ON pages FOR ALL USING (
    EXISTS (SELECT 1 FROM users WHERE users.id = auth.uid() AND users.role = 'admin')
);

ALTER TABLE services ENABLE ROW LEVEL SECURITY;
CREATE POLICY "serv_pub_select" ON services FOR SELECT USING (is_active = true);
CREATE POLICY "serv_admin_all" ON services FOR ALL USING (
    EXISTS (SELECT 1 FROM users WHERE users.id = auth.uid() AND users.role = 'admin')
);

-- ============================================
-- STEP 20: VERIFICATION DOCUMENTS
-- ============================================

ALTER TABLE doctor_verification_documents ENABLE ROW LEVEL SECURITY;
CREATE POLICY "docver_doc_all" ON doctor_verification_documents FOR ALL USING (
    doctor_id = auth.uid() OR
    EXISTS (SELECT 1 FROM users WHERE users.id = auth.uid() AND users.role = 'admin')
);

ALTER TABLE driver_verification_documents ENABLE ROW LEVEL SECURITY;
CREATE POLICY "drivver_drv_all" ON driver_verification_documents FOR ALL USING (
    driver_id = auth.uid() OR
    EXISTS (SELECT 1 FROM users WHERE users.id = auth.uid() AND users.role = 'admin')
);

-- ============================================
-- STEP 21: REFRESH SCHEMA CACHE
-- ============================================

SELECT pg_notify('pgrst', 'reload schema');

-- ============================================
-- VERIFICATION QUERIES
-- ============================================

-- Check RLS status
SELECT 'Tables with RLS: ' || COUNT(*)::text as result
FROM pg_tables WHERE schemaname = 'public' AND rowsecurity = true;

-- Count policies
SELECT 'Total policies: ' || COUNT(*)::text as result
FROM pg_policies WHERE schemaname = 'public';

-- List policies by table
SELECT tablename, COUNT(*) as policy_count
FROM pg_policies WHERE schemaname = 'public'
GROUP BY tablename ORDER BY policy_count DESC;
