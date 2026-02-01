# Database Schema & RLS Audit Report

## Executive Summary

This audit identifies the root causes of three critical errors in your Supabase application:

1. **PGRST204**: Could not find column in schema cache
2. **42501**: new row violates row-level security policy for table
3. **23502**: null value violates not-null constraint

---

## Part 1: Database Schema Audit

### 1.1 Schema Analysis

Based on your provided schema, here are the key observations:

#### Tables with Issues

| Table | Issue | Severity |
|-------|-------|----------|
| `users` | `email_key` NOT NULL but no default - causes insert failures | 🔴 High |
| `vans` | Multiple columns missing defaults (name, license_plate, etc.) | 🟡 Medium |
| `appointments` | Foreign keys (owner_id, doctor_id, driver_id) allow NULL - may cause orphaned records | 🟡 Medium |
| `pets` | `serial_number` UNIQUE but not NOT NULL - may cause duplicates | 🟡 Medium |

### 1.2 NOT NULL Columns Without Defaults

These columns will cause insert failures if not provided:

```sql
-- users table
email_key TEXT NOT NULL UNIQUE  -- ❌ CRITICAL: No default, causes insert failures

-- appointments table  
service_type TEXT NOT NULL      -- ✅ Has default? No explicit default
scheduled_at TIMESTAMPTZ NOT NULL

-- services table
name TEXT NOT NULL

-- pets table
owner_id UUID NOT NULL
name TEXT NOT NULL
species TEXT NOT NULL

-- vans table
name TEXT NOT NULL              -- ❌ Missing in some migrations
plate_number TEXT UNIQUE        -- ❌ Missing in some migrations
```

### 1.3 Foreign Key Analysis

```sql
-- These foreign keys allow NULL, which can cause orphaned records
appointments.owner_id UUID REFERENCES users(id)           -- Allows NULL
appointments.doctor_id UUID REFERENCES users(id)          -- Allows NULL
appointments.driver_id UUID REFERENCES users(id)          -- Allows NULL
```

**Recommendation**: Consider whether NULL should be allowed for these fields based on your business logic.

---

## Part 2: Row Level Security (RLS) Audit

### 2.1 Current RLS Status

To check which tables have RLS enabled:

```sql
SELECT tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public';
```

### 2.2 Common RLS Policy Issues

#### Issue 1: No Policies for INSERT Operations

**Error**: `new row violates row-level security policy for table`

**Cause**: RLS policies must explicitly allow INSERT operations. Many tables only have SELECT policies.

**Affected Tables**:
- `vans` - No INSERT policy for non-admin users
- `users` - Registration INSERT needs special handling
- `notifications` - Users need to INSERT their own notifications

#### Issue 2: Policy Conditions Using auth.uid() in INSERT

**Error**: `new row violates row-level security policy for table`

**Cause**: For INSERT operations, the `USING` clause is ignored. You must use `WITH CHECK` to define what values are acceptable.

**Wrong**:
```sql
CREATE POLICY "Insert policy" ON vans
    FOR INSERT 
    USING (auth.uid() = owner_id);  -- ❌ USING is ignored for INSERT
```

**Correct**:
```sql
CREATE POLICY "Insert policy" ON vans
    FOR INSERT 
    WITH CHECK (auth.uid() = owner_id);  -- ✅ Use WITH CHECK for INSERT
```

#### Issue 3: Missing Policies for UPDATE/DELETE

Many tables lack UPDATE/DELETE policies, causing 42501 errors on these operations.

---

## Part 3: Client Query Analysis

### 3.1 Flutter Client Issues

Based on `lib/services/supabase_complete_service.dart`:

#### Issue 1: No Error Handling for Schema Cache

**Problem**: PGRST204 errors occur when the PostgREST schema cache is stale.

**Solution**: Always refresh schema cache after migrations:
```sql
SELECT pg_notify('pgrst', 'reload schema');
```

#### Issue 2: Nullable Foreign Key Queries

**Problem** (Line 154-160 in supabase_complete_service.dart):
```dart
Future<List<Map<String, dynamic>>> getPetsByOwner(String ownerId) async {
  final response = await petsTable
      .select()
      .eq('owner_id', ownerId)  // ✅ Correct - filters by owner
      .order('name');
  return List<Map<String, dynamic>>.from(response);
}
```

This is correct - it filters by `owner_id` which matches the RLS policy.

#### Issue 3: Unauthenticated Inserts

**Problem** (Line 94-97):
```dart
Future<String> insertUser(Map<String, dynamic> data) async {
  final response = await usersTable.insert(data).select().single();
  return response['id'] as String;
}
```

This is called during user registration BEFORE authentication is complete. The RLS policy must allow unauthenticated INSERT.

### 3.2 Query Patterns That Cause Errors

```dart
// ❌ WRONG: Not providing required fields
await supabase.from('vans').insert({
  'status': 'available'  // Missing: name (NOT NULL)
});

// ✅ CORRECT: Providing all required fields
await supabase.from('vans').insert({
  'name': 'Van 1',
  'plate_number': 'ABC-123',
  'status': 'available'
});
```

---

## Part 4: Root Cause Analysis

### Error 1: PGRST204 - Schema Cache

**Cause**: PostgREST maintains a cache of the database schema. After adding tables/columns, the cache must be refreshed.

**Layer**: PostgREST (API layer)

**Solution**:
```sql
SELECT pg_notify('pgrst', 'reload schema');
```

### Error 2: 42501 - RLS Policy Violation

**Cause**: RLS policies blocked the operation because:
- No matching policy for the operation type (SELECT/INSERT/UPDATE/DELETE)
- Policy conditions weren't satisfied
- Using `USING` instead of `WITH CHECK` for INSERT policies

**Layer**: PostgreSQL RLS (Database layer)

**Solution**: Create appropriate policies for each operation.

### Error 3: 23502 - NOT NULL Constraint Violation

**Cause**: INSERT statement didn't provide a value for a NOT NULL column without a default.

**Layer**: PostgreSQL (Database layer)

**Solution**: 
1. Provide the value in INSERT
2. Add a DEFAULT to the column
3. Create a trigger to auto-generate the value

---

## Part 5: Exact SQL Fixes

### 5.1 Complete RLS Fix Script

Run this in Supabase SQL Editor:

```sql
-- ============================================
-- COMPLETE RLS FIX - Run in Supabase SQL Editor
-- ============================================

-- Step 1: Disable RLS on all tables
DO $$
DECLARE
    t text;
BEGIN
    FOR t IN SELECT tablename FROM pg_tables WHERE schemaname = 'public' LOOP
        EXECUTE format('ALTER TABLE %I DISABLE ROW LEVEL SECURITY', t);
    END LOOP;
END $$;

-- Step 2: Drop all existing policies
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

-- Step 3: Fix email_key for users table
DROP TRIGGER IF EXISTS set_email_key_on_insert ON users;
DROP FUNCTION IF EXISTS generate_email_key();

ALTER TABLE users ALTER COLUMN email_key DROP NOT NULL;
UPDATE users SET email_key = LOWER(REPLACE(email, '.', '_')) WHERE email_key IS NULL;

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

-- Step 4: Re-enable RLS with proper policies

-- USERS TABLE
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
CREATE POLICY "users_select_all" ON users FOR SELECT USING (true);
CREATE POLICY "users_insert_any" ON users FOR INSERT WITH CHECK (true);
CREATE POLICY "users_update_own" ON users FOR UPDATE USING (auth.uid() = id);

-- PETS TABLE
ALTER TABLE pets ENABLE ROW LEVEL SECURITY;
CREATE POLICY "pets_select_owner" ON pets FOR SELECT USING (owner_id = auth.uid());
CREATE POLICY "pets_insert_owner" ON pets FOR INSERT WITH CHECK (owner_id = auth.uid());
CREATE POLICY "pets_update_owner" ON pets FOR UPDATE USING (owner_id = auth.uid());
CREATE POLICY "pets_delete_owner" ON pets FOR DELETE USING (owner_id = auth.uid());

-- APPOINTMENTS TABLE
ALTER TABLE appointments ENABLE ROW LEVEL "appt SECURITY;
CREATE POLICY_select_owner" ON appointments FOR SELECT USING (owner_id = auth.uid());
CREATE POLICY "appt_insert_owner" ON appointments FOR INSERT WITH CHECK (owner_id = auth.uid());
CREATE POLICY "appt_update_owner" ON appointments FOR UPDATE USING (owner_id = auth.uid());

-- VANS TABLE - Critical fix for your error
ALTER TABLE vans ENABLE ROW LEVEL SECURITY;
CREATE POLICY "vans_insert_auth" ON vans FOR INSERT WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "vans_select_auth" ON vans FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "vans_update_auth" ON vans FOR UPDATE USING (auth.role() = 'authenticated');
CREATE POLICY "vans_delete_auth" ON vans FOR DELETE USING (auth.role() = 'authenticated');

-- NOTIFICATIONS TABLE
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
CREATE POLICY "notif_select_user" ON notifications FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "notif_insert_user" ON notifications FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY "notif_update_user" ON notifications FOR UPDATE USING (user_id = auth.uid());
CREATE POLICY "notif_delete_user" ON notifications FOR DELETE USING (user_id = auth.uid());

-- Add more tables as needed...

-- Step 5: Refresh PostgREST schema cache
SELECT pg_notify('pgrst', 'reload schema');

-- Verification
SELECT 'Tables with RLS: ' || COUNT(*)::text 
FROM pg_tables 
WHERE schemaname = 'public' AND rowsecurity = true;

SELECT 'Total policies: ' || COUNT(*)::text FROM pg_policies WHERE schemaname = 'public';
```

### 5.2 Column Fix for Vans Table

If vans table is missing required columns:

```sql
-- Add missing columns to vans
ALTER TABLE vans ADD COLUMN IF NOT EXISTS name TEXT NOT NULL DEFAULT 'Van';
ALTER TABLE vans ADD COLUMN IF NOT EXISTS plate_number TEXT UNIQUE;
ALTER TABLE vans ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'available';

-- Refresh schema
SELECT pg_notify('pgrst', 'reload schema');
```

---

## Part 6: Best Practices Guide

### 6.1 Naming Conventions

| Object | Convention | Example |
|--------|------------|---------|
| Tables | snake_case, plural | `users`, `appointments` |
| Columns | snake_case | `owner_id`, `created_at` |
| Policies | Descriptive with operation | `users_select_own`, `appt_insert_owner` |
| Functions | verb_noun | `get_user_by_id`, `update_appointment_status` |
| Triggers | table_operation_trigger | `set_timestamp_on_update` |

### 6.2 Auth Triggers vs Client Inserts

#### Use Auth Triggers When:
- Auto-populating computed fields
- Enforcing business rules on all inserts
- Audit logging

#### Use Client Inserts When:
- User-provided data
- Data that varies per request
- Conditional logic in application layer

**Example Auth Trigger**:
```sql
CREATE OR REPLACE FUNCTION set_created_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.created_at = NOW();
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER set_timestamp
    BEFORE INSERT ON appointments
    FOR EACH ROW
    EXECUTE FUNCTION set_created_at();
```

### 6.3 Safe RLS Defaults for Production

```sql
-- ============================================
-- PRODUCTION-READY RLS POLICIES
-- ============================================

-- USERS: Registration + Self Management
CREATE POLICY "pub_read_users" ON users FOR SELECT USING (true);
CREATE POLICY "pub_insert_users" ON users FOR INSERT WITH CHECK (true);
CREATE POLICY "own_update_users" ON users FOR UPDATE USING (auth.uid() = id);

-- PETS: Owner-based access
CREATE POLICY "own_select_pets" ON pets FOR SELECT USING (
    owner_id = auth.uid() OR 
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin')
);
CREATE POLICY "own_insert_pets" ON pets FOR INSERT WITH CHECK (owner_id = auth.uid());
CREATE POLICY "own_update_pets" ON pets FOR UPDATE USING (owner_id = auth.uid());
CREATE POLICY "own_delete_pets" ON pets FOR DELETE USING (owner_id = auth.uid());

-- APPOINTMENTS: Role-based access
CREATE POLICY "own_select_appts" ON appointments FOR SELECT USING (
    owner_id = auth.uid() OR
    doctor_id = auth.uid() OR
    driver_id = auth.uid() OR
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin')
);
CREATE POLICY "own_insert_appts" ON appointments FOR INSERT WITH CHECK (owner_id = auth.uid());

-- ADMIN TABLES: Admin only
CREATE POLICY "admin_all" ON audit_logs FOR ALL USING (
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin')
);
```

### 6.4 Development vs Production Settings

#### Development (Relaxed):
```sql
-- Allow all authenticated operations
CREATE POLICY "dev_all" ON vans FOR ALL USING (auth.role() = 'authenticated');
```

#### Production (Restrictive):
```sql
-- Admin only for sensitive tables
CREATE POLICY "prod_admin_all" ON system_settings FOR ALL USING (
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin')
);
```

### 6.5 Testing RLS Policies

Always test your policies:

```sql
-- 1. Check if RLS is enabled
SELECT tablename, rowsecurity FROM pg_tables WHERE schemaname = 'public';

-- 2. List all policies
SELECT policyname, tablename, cmd, qual, with_check 
FROM pg_policies;

-- 3. Test as different users
SET ROLE authenticated;
SELECT * FROM vans;  -- Should work if policy allows

SET ROLE anon;
SELECT * FROM vans;  -- Should fail if no anon policy

RESET ROLE;
```

---

## Part 7: Quick Fix Commands

### Fix All RLS Issues at Once
```sql
-- Disable all RLS (quick fix for development)
DO $$
DECLARE t text;
BEGIN FOR t IN SELECT tablename FROM pg_tables WHERE schemaname = 'public' 
LOOP EXECUTE format('ALTER TABLE %I DISABLE ROW LEVEL SECURITY', t);
END LOOP; END $$;
SELECT pg_notify('pgrst', 'reload schema');
```

### Refresh Schema Cache
```sql
SELECT pg_notify('pgrst', 'reload schema');
```

### Check for Missing Columns
```sql
SELECT table_name, column_name, is_nullable, column_default
FROM information_schema.columns
WHERE table_schema = 'public'
AND is_nullable = 'NO'
AND column_default IS NULL;
```

---

## Summary of Actions

1. **Run the complete RLS fix script** in Supabase SQL Editor
2. **Ensure all NOT NULL columns have defaults** or are provided in inserts
3. **Refresh the schema cache** after any schema changes
4. **Test RLS policies** as different user roles
5. **Use the quick fix** if you need to disable RLS temporarily for development

If you continue to experience issues, check:
1. Are you authenticated when making the request?
2. Does your user role match the policy conditions?
3. Are all required fields provided in the INSERT?
4. Is the PostgREST schema cache refreshed?
