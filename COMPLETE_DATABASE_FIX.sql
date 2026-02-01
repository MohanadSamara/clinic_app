-- COMPLETE DATABASE FIX: Create All Tables AND Add Missing Columns
-- Run this in Supabase SQL Editor
-- This will fix all PGRST204 schema cache errors

-- ============================================
-- FIRST: Create All Tables (if not exist)
-- ============================================

CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email TEXT UNIQUE NOT NULL,
    email_key TEXT UNIQUE NOT NULL,
    name TEXT NOT NULL,
    phone TEXT,
    role TEXT NOT NULL DEFAULT 'owner',
    area TEXT,
    provider TEXT,
    provider_id TEXT,
    profile_image TEXT,
    verification_status TEXT DEFAULT 'verified',
    linked_doctor_id UUID REFERENCES users(id),
    linked_driver_id UUID REFERENCES users(id),
    availability_status TEXT DEFAULT 'offline',
    password TEXT,
    last_seen TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS pets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_id UUID REFERENCES users(id) NOT NULL,
    name TEXT NOT NULL,
    species TEXT NOT NULL,
    breed TEXT,
    dob DATE,
    notes TEXT,
    medical_history_summary TEXT,
    vaccination_status JSONB,
    photo_path TEXT,
    serial_number TEXT UNIQUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS services (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    description TEXT,
    category TEXT,
    price DECIMAL(10,2),
    promotional_price DECIMAL(10,2),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS doctors (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) UNIQUE NOT NULL,
    assigned_service_id UUID REFERENCES services(id),
    license_number TEXT,
    specialization TEXT,
    experience_years INTEGER,
    is_available BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS appointments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_id UUID REFERENCES users(id),
    pet_id UUID REFERENCES pets(id),
    service_type TEXT NOT NULL,
    description TEXT,
    scheduled_at TIMESTAMP WITH TIME ZONE NOT NULL,
    status TEXT DEFAULT 'pending',
    address TEXT,
    price DECIMAL(10,2),
    doctor_id UUID REFERENCES users(id),
    driver_id UUID REFERENCES users(id),
    urgency_level TEXT DEFAULT 'routine',
    location_lat DECIMAL(10,8),
    location_lng DECIMAL(11,8),
    calendar_event_id TEXT,
    payment_method TEXT,
    service_request_id UUID,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS medical_records (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    pet_id UUID REFERENCES pets(id),
    doctor_id UUID REFERENCES users(id),
    diagnosis TEXT NOT NULL,
    treatment TEXT,
    prescription TEXT,
    notes TEXT,
    attachments TEXT,
    date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS documents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    pet_id UUID REFERENCES pets(id),
    medical_record_id UUID REFERENCES medical_records(id),
    file_name TEXT NOT NULL,
    file_type TEXT,
    file_path TEXT,
    description TEXT,
    upload_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    version INTEGER DEFAULT 1,
    uploaded_by UUID REFERENCES users(id),
    access_level TEXT DEFAULT 'private',
    file_size INTEGER DEFAULT 0,
    mime_type TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS vaccination_records (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    pet_id UUID REFERENCES pets(id) NOT NULL,
    vaccine_name TEXT NOT NULL,
    vaccination_date DATE,
    next_due_date DATE,
    batch_number TEXT,
    veterinarian_name TEXT,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS service_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_id UUID REFERENCES users(id) NOT NULL,
    pet_id UUID REFERENCES pets(id),
    assigned_doctor_id UUID REFERENCES users(id),
    service_type TEXT NOT NULL,
    request_type TEXT DEFAULT 'booking',
    status TEXT DEFAULT 'pending',
    description TEXT,
    latitude DECIMAL(10,8),
    longitude DECIMAL(11,8),
    address TEXT,
    request_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    scheduled_date TIMESTAMP WITH TIME ZONE,
    rejection_reason TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) NOT NULL,
    title TEXT NOT NULL,
    body TEXT,
    type TEXT,
    is_read BOOLEAN DEFAULT FALSE,
    data JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    appointment_id UUID REFERENCES appointments(id),
    user_id UUID REFERENCES users(id),
    amount DECIMAL(10,2) NOT NULL,
    subtotal DECIMAL(10,2) DEFAULT 0.0,
    tax DECIMAL(10,2) DEFAULT 0.0,
    total DECIMAL(10,2) DEFAULT 0.0,
    currency TEXT DEFAULT 'JOD',
    method TEXT,
    status TEXT DEFAULT 'pending',
    transaction_id TEXT,
    payment_intent_id TEXT,
    invoice_number TEXT,
    service_description TEXT,
    completed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS inventory (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    description TEXT,
    quantity INTEGER DEFAULT 0,
    min_threshold INTEGER DEFAULT 0,
    unit TEXT,
    cost DECIMAL(10,2),
    category TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS schedules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    doctor_id UUID REFERENCES users(id) NOT NULL,
    day_of_week INTEGER NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    is_available BOOLEAN DEFAULT TRUE,
    is_holiday BOOLEAN DEFAULT FALSE,
    is_free_day BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS vans (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    license_plate TEXT UNIQUE NOT NULL,
    model TEXT,
    capacity INTEGER DEFAULT 1,
    status TEXT DEFAULT 'available',
    description TEXT,
    area TEXT,
    assigned_driver_id UUID REFERENCES users(id),
    assigned_doctor_id UUID REFERENCES users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS driver_status (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    driver_id UUID REFERENCES users(id) NOT NULL,
    latitude DECIMAL(10,8),
    longitude DECIMAL(11,8),
    status TEXT DEFAULT 'available',
    current_appointment_id UUID REFERENCES appointments(id),
    last_updated TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS routes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    driver_id UUID REFERENCES users(id),
    appointment_id UUID REFERENCES appointments(id),
    start_lat DECIMAL(10,8),
    start_lng DECIMAL(11,8),
    end_lat DECIMAL(10,8),
    end_lng DECIMAL(11,8),
    waypoints JSONB,
    distance DECIMAL(10,2),
    duration INTEGER,
    status TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS vehicle_checks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    driver_id UUID REFERENCES users(id),
    check_date DATE,
    fuel_level TEXT,
    tire_condition TEXT,
    lights_ok BOOLEAN,
    medical_equipment_ok BOOLEAN,
    notes TEXT,
    photos TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS doctor_verification_documents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    doctor_id UUID REFERENCES users(id) NOT NULL,
    document_type TEXT NOT NULL,
    file_name TEXT NOT NULL,
    file_path TEXT,
    upload_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    status TEXT DEFAULT 'pending',
    review_date TIMESTAMP WITH TIME ZONE,
    reviewer_id UUID REFERENCES users(id),
    review_notes TEXT,
    document_number TEXT,
    expiry_date DATE,
    issuing_authority TEXT,
    verification_code TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS driver_verification_documents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    driver_id UUID REFERENCES users(id) NOT NULL,
    document_type TEXT NOT NULL,
    document_number TEXT,
    file_name TEXT NOT NULL,
    file_path TEXT,
    upload_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expiry_date DATE,
    issue_date DATE,
    issuing_authority TEXT,
    status TEXT DEFAULT 'pending',
    review_date TIMESTAMP WITH TIME ZONE,
    reviewer_id UUID REFERENCES users(id),
    review_notes TEXT,
    verification_code TEXT,
    vehicle_class TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS driver_verification_audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    document_id UUID REFERENCES driver_verification_documents(id),
    user_id UUID REFERENCES users(id),
    action TEXT NOT NULL,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    details TEXT,
    ip_address TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    document_id UUID REFERENCES documents(id),
    user_id UUID REFERENCES users(id),
    action TEXT NOT NULL,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    details TEXT,
    ip_address TEXT
);

CREATE TABLE IF NOT EXISTS compliance_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    inspection_type TEXT,
    inspector_name TEXT,
    inspection_date DATE,
    status TEXT,
    findings TEXT,
    corrective_actions TEXT,
    next_inspection_date DATE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS pages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    slug TEXT UNIQUE NOT NULL,
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    is_published BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS system_settings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    key TEXT UNIQUE NOT NULL,
    value TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- SECOND: Create Indexes
-- ============================================
CREATE INDEX IF NOT EXISTS idx_appointments_owner_id ON appointments(owner_id);
CREATE INDEX IF NOT EXISTS idx_appointments_doctor_id ON appointments(doctor_id);
CREATE INDEX IF NOT EXISTS idx_appointments_driver_id ON appointments(driver_id);
CREATE INDEX IF NOT EXISTS idx_appointments_status ON appointments(status);
CREATE INDEX IF NOT EXISTS idx_appointments_scheduled_at ON appointments(scheduled_at);
CREATE INDEX IF NOT EXISTS idx_pets_owner_id ON pets(owner_id);
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_payments_appointment_id ON payments(appointment_id);
CREATE INDEX IF NOT EXISTS idx_payments_user_id ON payments(user_id);
CREATE INDEX IF NOT EXISTS idx_service_requests_owner_id ON service_requests(owner_id);
CREATE INDEX IF NOT EXISTS idx_service_requests_assigned_doctor_id ON service_requests(assigned_doctor_id);
CREATE INDEX IF NOT EXISTS idx_schedules_doctor_id ON schedules(doctor_id);
CREATE INDEX IF NOT EXISTS idx_driver_status_driver_id ON driver_status(driver_id);

-- ============================================
-- THIRD: Create Updated At Trigger Function
-- ============================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- ============================================
-- FOURTH: Enable RLS on all tables
-- ============================================
ALTER TABLE IF EXISTS users ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS pets ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS appointments ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS medical_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS services ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS schedules ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS vans ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS driver_status ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS routes ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS vehicle_checks ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS doctor_verification_documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS driver_verification_documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS driver_verification_audit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS audit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS compliance_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS service_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS pages ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS system_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS inventory ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS vaccination_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS doctors ENABLE ROW LEVEL SECURITY;

-- ============================================
-- FIFTH: Create RLS Policies (using DO to avoid errors)
-- ============================================

DO $$
DECLARE
    policy_count INTEGER;
BEGIN
    -- Users table policies
    SELECT COUNT(*) INTO policy_count FROM pg_policies WHERE tablename = 'users' AND policyname = 'users_read_authenticated';
    IF policy_count = 0 THEN
        CREATE POLICY "users_read_authenticated" ON users FOR SELECT USING (auth.role() = 'authenticated');
    END IF;
    
    SELECT COUNT(*) INTO policy_count FROM pg_policies WHERE tablename = 'users' AND policyname = 'users_insert_own';
    IF policy_count = 0 THEN
        CREATE POLICY "users_insert_own" ON users FOR INSERT WITH CHECK (auth.uid() = id);
    END IF;
    
    SELECT COUNT(*) INTO policy_count FROM pg_policies WHERE tablename = 'users' AND policyname = 'users_update_own';
    IF policy_count = 0 THEN
        CREATE POLICY "users_update_own" ON users FOR UPDATE USING (auth.uid() = id);
    END IF;

    -- Pets table policies
    SELECT COUNT(*) INTO policy_count FROM pg_policies WHERE tablename = 'pets' AND policyname = 'pets_read_authenticated';
    IF policy_count = 0 THEN
        CREATE POLICY "pets_read_authenticated" ON pets FOR SELECT USING (auth.role() = 'authenticated');
    END IF;
    
    SELECT COUNT(*) INTO policy_count FROM pg_policies WHERE tablename = 'pets' AND policyname = 'pets_insert_authenticated';
    IF policy_count = 0 THEN
        CREATE POLICY "pets_insert_authenticated" ON pets FOR INSERT WITH CHECK (auth.role() = 'authenticated');
    END IF;
    
    SELECT COUNT(*) INTO policy_count FROM pg_policies WHERE tablename = 'pets' AND policyname = 'pets_update_authenticated';
    IF policy_count = 0 THEN
        CREATE POLICY "pets_update_authenticated" ON pets FOR UPDATE USING (auth.role() = 'authenticated');
    END IF;

    -- Appointments table policies
    SELECT COUNT(*) INTO policy_count FROM pg_policies WHERE tablename = 'appointments' AND policyname = 'appointments_read_authenticated';
    IF policy_count = 0 THEN
        CREATE POLICY "appointments_read_authenticated" ON appointments FOR SELECT USING (auth.role() = 'authenticated');
    END IF;

    -- Medical records table policies
    SELECT COUNT(*) INTO policy_count FROM pg_policies WHERE tablename = 'medical_records' AND policyname = 'medical_records_read_authenticated';
    IF policy_count = 0 THEN
        CREATE POLICY "medical_records_read_authenticated" ON medical_records FOR SELECT USING (auth.role() = 'authenticated');
    END IF;

    -- Documents table policies
    SELECT COUNT(*) INTO policy_count FROM pg_policies WHERE tablename = 'documents' AND policyname = 'documents_read_authenticated';
    IF policy_count = 0 THEN
        CREATE POLICY "documents_read_authenticated" ON documents FOR SELECT USING (auth.role() = 'authenticated');
    END IF;

    -- Notifications table policies
    SELECT COUNT(*) INTO policy_count FROM pg_policies WHERE tablename = 'notifications' AND policyname = 'notifications_read_authenticated';
    IF policy_count = 0 THEN
        CREATE POLICY "notifications_read_authenticated" ON notifications FOR SELECT USING (auth.role() = 'authenticated');
    END IF;

    -- Services table policies
    SELECT COUNT(*) INTO policy_count FROM pg_policies WHERE tablename = 'services' AND policyname = 'services_read_authenticated';
    IF policy_count = 0 THEN
        CREATE POLICY "services_read_authenticated" ON services FOR SELECT USING (auth.role() = 'authenticated');
    END IF;

    -- Schedules table policies
    SELECT COUNT(*) INTO policy_count FROM pg_policies WHERE tablename = 'schedules' AND policyname = 'schedules_read_authenticated';
    IF policy_count = 0 THEN
        CREATE POLICY "schedules_read_authenticated" ON schedules FOR SELECT USING (auth.role() = 'authenticated');
    END IF;
END $$;

-- ============================================
-- SIXTH: Refresh Schema Cache
-- ============================================
NOTIFY pgrst, 'reload schema';

-- ============================================
-- VERIFY: List all tables
-- ============================================
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
ORDER BY table_name;

