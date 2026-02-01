-- Supabase Migration Script for Vet2U Clinic App
-- Run this in Supabase SQL Editor to create all tables

-- ============================================
-- Drop existing tables (if needed for fresh start)
-- WARNING: This will delete all data!
-- ============================================
-- DROP TABLE IF EXISTS audit_logs CASCADE;
-- DROP TABLE IF EXISTS compliance_logs CASCADE;
-- DROP TABLE IF EXISTS vehicle_checks CASCADE;
-- DROP TABLE IF EXISTS routes CASCADE;
-- DROP TABLE IF EXISTS driver_verification_audit_logs CASCADE;
-- DROP TABLE IF EXISTS driver_verification_documents CASCADE;
-- DROP TABLE IF EXISTS doctor_verification_documents CASCADE;
-- DROP TABLE IF EXISTS vaccination_records CASCADE;
-- DROP TABLE IF EXISTS documents CASCADE;
-- DROP TABLE IF EXISTS service_requests CASCADE;
-- DROP TABLE IF EXISTS pages CASCADE;
-- DROP TABLE IF EXISTS driver_status CASCADE;
-- DROP TABLE IF EXISTS payments CASCADE;
-- DROP TABLE IF EXISTS inventory CASCADE;
-- DROP TABLE IF EXISTS medical_records CASCADE;
-- DROP TABLE IF EXISTS schedules CASCADE;
-- DROP TABLE IF EXISTS appointments CASCADE;
-- DROP TABLE IF EXISTS services CASCADE;
-- DROP TABLE IF EXISTS pets CASCADE;
-- DROP TABLE IF EXISTS vans CASCADE;
-- DROP TABLE IF EXISTS doctors CASCADE;
-- DROP TABLE IF EXISTS users CASCADE;

-- ============================================
-- USERS TABLE
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
    linked_doctor_id UUID,
    linked_driver_id UUID,
    availability_status TEXT DEFAULT 'offline',
    password TEXT,
    last_seen TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- PETS TABLE
-- ============================================
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

-- ============================================
-- SERVICES TABLE
-- ============================================
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

-- ============================================
-- DOCTORS TABLE
-- ============================================
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

-- ============================================
-- APPOINTMENTS TABLE
-- ============================================
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

-- ============================================
-- MEDICAL RECORDS TABLE
-- ============================================
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

-- ============================================
-- DOCUMENTS TABLE
-- ============================================
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

-- ============================================
-- VACCINATION RECORDS TABLE
-- ============================================
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

-- ============================================
-- SERVICE REQUESTS TABLE
-- ============================================
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

-- ============================================
-- NOTIFICATIONS TABLE
-- ============================================
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

-- ============================================
-- PAYMENTS TABLE
-- ============================================
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

-- ============================================
-- INVENTORY TABLE
-- ============================================
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

-- ============================================
-- SCHEDULES TABLE
-- ============================================
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

-- ============================================
-- VANS TABLE
-- ============================================
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

-- ============================================
-- DRIVER STATUS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS driver_status (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    driver_id UUID REFERENCES users(id) NOT NULL,
    latitude DECIMAL(10,8),
    longitude DECIMAL(11,8),
    status TEXT DEFAULT 'available',
    current_appointment_id UUID REFERENCES appointments(id),
    last_updated TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- ROUTES TABLE
-- ============================================
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

-- ============================================
-- VEHICLE CHECKS TABLE
-- ============================================
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

-- ============================================
-- DOCTOR VERIFICATION DOCUMENTS TABLE
-- ============================================
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

-- ============================================
-- DRIVER VERIFICATION DOCUMENTS TABLE
-- ============================================
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

-- ============================================
-- DRIVER VERIFICATION AUDIT LOGS TABLE
-- ============================================
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

-- ============================================
-- AUDIT LOGS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    document_id UUID REFERENCES documents(id),
    user_id UUID REFERENCES users(id),
    action TEXT NOT NULL,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    details TEXT,
    ip_address TEXT
);

-- ============================================
-- COMPLIANCE LOGS TABLE
-- ============================================
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

-- ============================================
-- PAGES TABLE (CMS)
-- ============================================
CREATE TABLE IF NOT EXISTS pages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    slug TEXT UNIQUE NOT NULL,
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    is_published BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- SYSTEM SETTINGS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS system_settings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    key TEXT UNIQUE NOT NULL,
    value TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- INDEXES FOR PERFORMANCE
-- ============================================
CREATE INDEX idx_appointments_owner_id ON appointments(owner_id);
CREATE INDEX idx_appointments_doctor_id ON appointments(doctor_id);
CREATE INDEX idx_appointments_driver_id ON appointments(driver_id);
CREATE INDEX idx_appointments_status ON appointments(status);
CREATE INDEX idx_appointments_scheduled_at ON appointments(scheduled_at);
CREATE INDEX idx_pets_owner_id ON pets(owner_id);
CREATE INDEX idx_notifications_user_id ON notifications(user_id);
CREATE INDEX idx_payments_appointment_id ON payments(appointment_id);
CREATE INDEX idx_payments_user_id ON payments(user_id);
CREATE INDEX idx_service_requests_owner_id ON service_requests(owner_id);
CREATE INDEX idx_service_requests_assigned_doctor_id ON service_requests(assigned_doctor_id);
CREATE INDEX idx_schedules_doctor_id ON schedules(doctor_id);
CREATE INDEX idx_driver_status_driver_id ON driver_status(driver_id);

-- ============================================
-- ENABLE ROW LEVEL SECURITY (RLS)
-- ============================================
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE pets ENABLE ROW LEVEL SECURITY;
ALTER TABLE appointments ENABLE ROW LEVEL SECURITY;
ALTER TABLE medical_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE services ENABLE ROW LEVEL SECURITY;
ALTER TABLE schedules ENABLE ROW LEVEL SECURITY;
ALTER TABLE vans ENABLE ROW LEVEL SECURITY;
ALTER TABLE driver_status ENABLE ROW LEVEL SECURITY;
ALTER TABLE routes ENABLE ROW LEVEL SECURITY;
ALTER TABLE vehicle_checks ENABLE ROW LEVEL SECURITY;
ALTER TABLE doctor_verification_documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE driver_verification_documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE driver_verification_audit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE compliance_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE service_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE pages ENABLE ROW LEVEL SECURITY;
ALTER TABLE system_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE inventory ENABLE ROW LEVEL SECURITY;
ALTER TABLE vaccination_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE doctors ENABLE ROW LEVEL SECURITY;

-- ============================================
-- BASIC RLS POLICIES
-- ============================================

-- Allow authenticated users to read all data
CREATE POLICY "Enable read access for authenticated users" ON users
    FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Enable read access for authenticated users" ON pets
    FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Enable read access for authenticated users" ON appointments
    FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Enable read access for authenticated users" ON medical_records
    FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Enable read access for authenticated users" ON documents
    FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Enable read access for authenticated users" ON notifications
    FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Enable read access for authenticated users" ON services
    FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Enable read access for authenticated users" ON schedules
    FOR SELECT USING (auth.role() = 'authenticated');

-- Allow users to insert their own data
CREATE POLICY "Users can insert own data" ON users
    FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can insert pets for owners" ON pets
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- Allow users to update their own data
CREATE POLICY "Users can update own data" ON users
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can update own pets" ON pets
    FOR UPDATE USING (auth.role() = 'authenticated');

-- ============================================
-- SEED DEFAULT DATA
-- ============================================

-- Insert default services
INSERT INTO services (name, description, category, price, duration_minutes) VALUES
('General Checkup', 'Basic health examination', 'checkup', 50.00, 30),
('Vaccination', 'Pet vaccination service', 'vaccination', 35.00, 15),
('Emergency Care', 'Emergency veterinary care', 'emergency', 150.00, 60),
('Dental Cleaning', 'Pet dental cleaning', 'dental', 100.00, 45),
('Surgery', 'Surgical procedure', 'surgery', 300.00, 120),
('Grooming', 'Pet grooming service', 'grooming', 40.00, 45);

-- Insert default pages
INSERT INTO pages (title, slug, content, is_published) VALUES
('About Us', 'about', 'Welcome to Vet2U - Your trusted mobile veterinary clinic', true),
('Services', 'services', 'We offer a wide range of veterinary services', true),
('Contact', 'contact', 'Contact us at info@vet2u.com', true);

-- ============================================
-- FUNCTIONS
-- ============================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Triggers for updated_at
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_pets_updated_at BEFORE UPDATE ON pets
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_services_updated_at BEFORE UPDATE ON services
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_appointments_updated_at BEFORE UPDATE ON appointments
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_medical_records_updated_at BEFORE UPDATE ON medical_records
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_documents_updated_at BEFORE UPDATE ON documents
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_notifications_updated_at BEFORE UPDATE ON notifications
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_payments_updated_at BEFORE UPDATE ON payments
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_inventory_updated_at BEFORE UPDATE ON inventory
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_schedules_updated_at BEFORE UPDATE ON schedules
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_vans_updated_at BEFORE UPDATE ON vans
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_service_requests_updated_at BEFORE UPDATE ON service_requests
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_vaccination_records_updated_at BEFORE UPDATE ON vaccination_records
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_doctors_updated_at BEFORE UPDATE ON doctors
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_driver_verification_documents_updated_at BEFORE UPDATE ON driver_verification_documents
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_doctor_verification_documents_updated_at BEFORE UPDATE ON doctor_verification_documents
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_pages_updated_at BEFORE UPDATE ON pages
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_system_settings_updated_at BEFORE UPDATE ON system_settings
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
