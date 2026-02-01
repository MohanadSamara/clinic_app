# Supabase Setup Guide for Vet2U Clinic App

## Overview
This document provides step-by-step instructions to set up Supabase for your Flutter clinic application after migrating from Firebase Firestore and SQLite.

---

## Part 1: Create Supabase Account and Project

### Step 1: Create Supabase Account
1. Go to **https://supabase.com**
2. Click **"Start your project"** or **"Sign Up"**
3. Sign up using **GitHub**, **Google**, or **email**
4. Verify your email if required

### Step 2: Create New Project
1. In Supabase dashboard, click **"New Project"**
2. Select your organization or create a new one
3. **Project name**: `vet2u-clinic-app`
4. **Database Password**: Generate a strong password and **SAVE IT SECURELY**!
5. **Region**: Select closest region (e.g., `Asia Pacific - Singapore`)
6. Click **"Create new project"**
7. **Wait 2-3 minutes** for project to provision

### Step 3: Get API Credentials
1. Go to **Project Settings** → **API**
2. Copy and save these values:
   - **Project URL**: `https://[your-project-ref].supabase.co`
   - **anon public key**: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...`

### Step 4: Configure Flutter App
Open `lib/supabase_options.dart` and replace the placeholder values:

```dart
class SupabaseOptions {
  static const String projectUrl = 'https://your-project-ref.supabase.co';
  static const String anonKey = 'your-anon-public-key-here';
}
```

---

## Part 2: Create Database Tables

### Step 1: Open SQL Editor
In Supabase dashboard, go to **SQL Editor** and run the following SQL:

```sql
-- ============================================
-- USERS TABLE
-- ============================================
CREATE TABLE users (
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
    verification_status TEXT DEFAULT 'pending',
    linked_doctor_id UUID,
    linked_driver_id UUID,
    availability_status TEXT DEFAULT 'available',
    password TEXT,
    last_seen TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- PETS TABLE
-- ============================================
CREATE TABLE pets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_id UUID REFERENCES users(id) NOT NULL,
    name TEXT NOT NULL,
    species TEXT NOT NULL,
    breed TEXT,
    dob DATE,
    notes TEXT,
    photo_url TEXT,
    serial_number TEXT UNIQUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- APPOINTMENTS TABLE
-- ============================================
CREATE TABLE appointments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_id UUID REFERENCES users(id),
    doctor_id UUID REFERENCES users(id),
    driver_id UUID REFERENCES users(id),
    pet_id TEXT,
    service_type TEXT NOT NULL,
    scheduled_at TIMESTAMP WITH TIME ZONE NOT NULL,
    status TEXT DEFAULT 'pending',
    description TEXT,
    address TEXT,
    price DECIMAL(10,2),
    location_lat DECIMAL(10,8),
    location_lng DECIMAL(11,8),
    urgency_level TEXT DEFAULT 'routine',
    service_request_id TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- MEDICAL RECORDS TABLE
-- ============================================
CREATE TABLE medical_records (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    pet_id UUID REFERENCES pets(id),
    doctor_id UUID REFERENCES users(id),
    diagnosis TEXT NOT NULL,
    treatment TEXT,
    prescription TEXT,
    notes TEXT,
    date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- DOCUMENTS TABLE
-- ============================================
CREATE TABLE documents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    pet_id UUID REFERENCES pets(id),
    medical_record_id UUID REFERENCES medical_records(id),
    file_name TEXT NOT NULL,
    file_type TEXT,
    file_size INTEGER,
    file_url TEXT,
    description TEXT,
    upload_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- PAYMENTS TABLE
-- ============================================
CREATE TABLE payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    appointment_id UUID REFERENCES appointments(id),
    user_id UUID REFERENCES users(id),
    amount DECIMAL(10,2) NOT NULL,
    status TEXT DEFAULT 'pending',
    payment_method TEXT,
    transaction_id TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- NOTIFICATIONS TABLE
-- ============================================
CREATE TABLE notifications (
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
-- SERVICES TABLE
-- ============================================
CREATE TABLE services (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    description TEXT,
    category TEXT,
    price DECIMAL(10,2),
    duration_minutes INTEGER DEFAULT 30,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- SCHEDULES TABLE
-- ============================================
CREATE TABLE schedules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    doctor_id UUID REFERENCES users(id) NOT NULL,
    day_of_week INTEGER NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    is_available BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- VANS TABLE
-- ============================================
CREATE TABLE vans (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    plate_number TEXT UNIQUE,
    assigned_driver_id UUID REFERENCES users(id),
    assigned_doctor_id UUID REFERENCES users(id),
    status TEXT DEFAULT 'available',
    last_location_lat DECIMAL(10,8),
    last_location_lng DECIMAL(11,8),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- DOCTOR VERIFICATION DOCUMENTS TABLE
-- ============================================
CREATE TABLE doctor_verification_documents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    doctor_id UUID REFERENCES users(id) NOT NULL,
    document_type TEXT NOT NULL,
    file_name TEXT NOT NULL,
    file_url TEXT,
    status TEXT DEFAULT 'pending',
    upload_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    reviewer_id UUID REFERENCES users(id),
    review_date TIMESTAMP WITH TIME ZONE,
    review_notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- DRIVER VERIFICATION DOCUMENTS TABLE
-- ============================================
CREATE TABLE driver_verification_documents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    driver_id UUID REFERENCES users(id) NOT NULL,
    document_type TEXT NOT NULL,
    document_number TEXT,
    file_name TEXT NOT NULL,
    file_url TEXT,
    status TEXT DEFAULT 'pending',
    upload_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    reviewer_id UUID REFERENCES users(id),
    review_date TIMESTAMP WITH TIME ZONE,
    review_notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- AUDIT LOGS TABLE
-- ============================================
CREATE TABLE audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    action TEXT NOT NULL,
    details TEXT,
    document_id TEXT,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- SERVICE REQUESTS TABLE
-- ============================================
CREATE TABLE service_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_id UUID REFERENCES users(id) NOT NULL,
    assigned_doctor_id UUID REFERENCES users(id),
    pet_id UUID REFERENCES pets(id),
    service_type TEXT NOT NULL,
    request_type TEXT DEFAULT 'booking',
    status TEXT DEFAULT 'pending',
    request_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- PAGES TABLE (CMS)
-- ============================================
CREATE TABLE pages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    slug TEXT UNIQUE NOT NULL,
    content TEXT,
    is_published BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

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
ALTER TABLE doctor_verification_documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE driver_verification_documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE service_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE pages ENABLE ROW LEVEL SECURITY;

-- ============================================
-- BASIC RLS POLICIES (Simplified)
-- ============================================

-- Allow all authenticated users to read data
CREATE POLICY "Enable all read for authenticated users" ON users
    FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Enable all read for authenticated users" ON pets
    FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Enable all read for authenticated users" ON appointments
    FOR SELECT USING (auth.role() = 'authenticated');

-- Allow users to insert their own data
CREATE POLICY "Users can insert their own data" ON users
    FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can insert pets" ON pets
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- Allow users to update their own data
CREATE POLICY "Users can update own data" ON users
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can update own pets" ON pets
    FOR UPDATE USING (auth.role() = 'authenticated');
```

### Step 2: Run Additional Setup SQL
Run this SQL to seed some initial data:

```sql
-- Insert sample services
INSERT INTO services (name, description, category, price, duration_minutes) VALUES
('General Checkup', 'Basic health examination', 'checkup', 50.00, 30),
('Vaccination', 'Pet vaccination service', 'vaccination', 35.00, 15),
('Emergency Care', 'Emergency veterinary care', 'emergency', 150.00, 60),
('Dental Cleaning', 'Pet dental cleaning', 'dental', 100.00, 45),
('Surgery', 'Surgical procedure', 'surgery', 300.00, 120);

-- Insert sample pages
INSERT INTO pages (title, slug, content, is_published) VALUES
('About Us', 'about', 'Welcome to Vet2U - Your trusted mobile veterinary clinic', true),
('Services', 'services', 'We offer a wide range of veterinary services', true),
('Contact', 'contact', 'Contact us at info@vet2u.com', true);
```

---

## Part 3: Install Dependencies

Run in your project terminal:

```bash
flutter pub get
```

---

## Part 4: Test the Integration

1. Update `lib/supabase_options.dart` with your actual credentials
2. Run the app:
```bash
flutter run
```

---

## Part 5: Troubleshooting

### Error: Package not found
Make sure you ran `flutter pub get` after updating pubspec.yaml

### Error: Table not found
1. Check that you ran all SQL statements
2. Verify table names match exactly (case-sensitive)
3. Go to Supabase Dashboard → Table Editor to verify tables exist

### Error: Authentication failed
1. Check your Supabase URL and anon key in supabase_options.dart
2. Make sure RLS policies are correctly set up

### Error: Connection refused
1. Check your internet connection
2. Verify Supabase project is active in dashboard
3. Check if your IP is allowed (Supabase → Settings → API → IP Configuration)

---

## File Changes Summary

### Files Created:
- `lib/supabase_options.dart` - Supabase configuration
- `lib/services/supabase_service.dart` - Main Supabase client
- `lib/services/supabase_complete_service.dart` - Complete database service

### Files Deleted:
- `lib/services/firestore_service.dart`
- `lib/services/firestore_crud_service.dart`
- `lib/services/firestore_complete_service.dart`
- `lib/services/firestore_global_service.dart`
- `lib/services/sync_service.dart`
- `lib/db/db_helper.dart`
- `lib/providers/sync_provider.dart`
- `lib/models/sync_tracker.dart`

### Files Modified:
- `pubspec.yaml` - Added Supabase, removed Firebase/SQLite dependencies

### Files Kept (Unchanged):
- `lib/firebase_options.dart` - For Google Sign-In
- Firebase authentication for login functionality

---

## Next Steps

1. **Update providers** to use `SupabaseCompleteService` instead of Firestore
2. **Update screens** that directly use Firestore
3. **Test all CRUD operations** for each entity type
4. **Set up real-time subscriptions** for live updates (Supabase has built-in support)
5. **Configure Storage** for file uploads (Supabase Storage bucket)

For real-time updates, use Supabase's channel system:
```dart
supabase.channel('public:appointments')
    .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'appointments',
        callback: (payload) {
            // Handle real-time update
        },
    )
    .subscribe();
```

---

## Support

- Supabase Docs: https://supabase.com/docs
- Supabase Flutter: https://supabase.com/docs/reference/dart/start
- Community: https://github.com/supabase/supabase-flutter

