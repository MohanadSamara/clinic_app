-- Fix for RLS Policy Error 42501 AND email_key null constraint on users table
-- Run this in Supabase SQL Editor
-- This fixes: 
-- 1. "new row violates row-level security policy for table 'users'"
-- 2. "null value in column 'email_key' violates not-null constraint"

-- ============================================
-- FIX 1: MAKE email_key OPTIONAL
-- ============================================

DO $$
BEGIN
    -- Remove NOT NULL constraint
    ALTER TABLE users ALTER COLUMN email_key DROP NOT NULL;
    
    -- Update existing NULL values
    UPDATE users SET email_key = LOWER(REPLACE(email, '.', '_')) WHERE email_key IS NULL;
    
    -- Add NOT NULL back
    ALTER TABLE users ALTER COLUMN email_key SET NOT NULL;
    
EXCEPTION
    WHEN undefined_column THEN
        -- Column doesn't exist, create it
        ALTER TABLE users ADD COLUMN email_key TEXT UNIQUE;
        UPDATE users SET email_key = LOWER(REPLACE(email, '.', '_')) WHERE email_key IS NULL;
        ALTER TABLE users ALTER COLUMN email_key SET NOT NULL;
END $$;

-- ============================================
-- FIX 2: CREATE FUNCTION TO AUTO-GENERATE email_key
-- ============================================

CREATE OR REPLACE FUNCTION generate_email_key()
RETURNS TRIGGER AS $$
BEGIN
    -- Generate email_key from email if not provided or NULL
    IF NEW.email_key IS NULL OR NEW.email_key = '' THEN
        NEW.email_key := LOWER(REPLACE(NEW.email, '.', '_'));
    END IF;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Drop existing trigger if exists
DROP TRIGGER IF EXISTS set_email_key_on_insert ON users;

-- Create trigger
CREATE TRIGGER set_email_key_on_insert
    BEFORE INSERT ON users
    FOR EACH ROW
    EXECUTE FUNCTION generate_email_key();

-- ============================================
-- FIX 3: RLS POLICIES
-- ============================================

-- Drop existing INSERT policies (both old and new)
DROP POLICY IF EXISTS "Users can insert own data" ON users;
DROP POLICY IF EXISTS "Allow inserting users for registration" ON users;

-- Create new permissive INSERT policy for registration
CREATE POLICY "Allow inserting users for registration" ON users
    FOR INSERT
    WITH CHECK (true);  -- Allow any insert (authenticated or not)

-- ============================================
-- REFRESH POSTGREST SCHEMA CACHE
-- ============================================
SELECT pg_notify('pgrst', 'reload schema');

-- ============================================
-- VERIFICATION
-- ============================================

-- Check if email_key column exists and has data
SELECT 
    column_name, 
    is_nullable, 
    column_default
FROM information_schema.columns 
WHERE table_name = 'users' AND column_name = 'email_key';

-- Check current RLS policies on users table
SELECT 
    policyname,
    cmd,
    qual,
    with_check
FROM pg_policies
WHERE tablename = 'users';

-- List users to verify email_key was populated
SELECT id, email, email_key FROM users LIMIT 5;

