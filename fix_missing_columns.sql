-- Migration to fix missing columns, RLS policies, and refresh schema cache
-- Run this in Supabase SQL Editor
-- This fixes PGRST204 and RLS errors

-- ============================================
-- DISABLE RLS ON VANS TABLE (for development)
-- ============================================

-- Disable RLS on vans table
ALTER TABLE vans DISABLE ROW LEVEL SECURITY;

-- Drop existing RLS policies on vans (if any)
DROP POLICY IF EXISTS "Enable insert for authenticated users" ON vans;
DROP POLICY IF EXISTS "Enable read access for authenticated users" ON vans;
DROP POLICY IF EXISTS "Enable update for authenticated users" ON vans;
DROP POLICY IF EXISTS "Enable delete for authenticated users" ON vans;

-- ============================================
-- ENABLE RLS WITH PROPER POLICIES FOR VANS
-- ============================================

-- Re-enable RLS on vans
ALTER TABLE vans ENABLE ROW LEVEL SECURITY;

-- Allow authenticated users to insert vans (admin/doctor/driver roles)
CREATE POLICY "Allow authenticated users to insert vans" ON vans
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- Allow authenticated users to read vans
CREATE POLICY "Allow authenticated users to read vans" ON vans
    FOR SELECT USING (auth.role() = 'authenticated');

-- Allow authenticated users to update vans
CREATE POLICY "Allow authenticated users to update vans" ON vans
    FOR UPDATE USING (auth.role() = 'authenticated');

-- Allow authenticated users to delete vans
CREATE POLICY "Allow authenticated users to delete vans" ON vans
    FOR DELETE USING (auth.role() = 'authenticated');

-- ============================================
-- DISABLE RLS ON USERS TABLE (for development)
-- ============================================

-- Disable RLS on users table
ALTER TABLE users DISABLE ROW LEVEL SECURITY;

-- Drop existing RLS policies on users (if any)
DROP POLICY IF EXISTS "Enable read access for authenticated users" ON users;
DROP POLICY IF EXISTS "Users can insert own data" ON users;
DROP POLICY IF EXISTS "Users can update own data" ON users;

-- ============================================
-- ENABLE RLS WITH PROPER POLICIES FOR USERS
-- ============================================

-- Re-enable RLS on users
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- Allow anyone to read users (needed for doctor/driver lookups)
CREATE POLICY "Allow public read access to users" ON users
    FOR SELECT USING (true);

-- Allow users to insert their own data
CREATE POLICY "Users can insert own data" ON users
    FOR INSERT WITH CHECK (auth.uid() = id);

-- Allow users to update their own data
CREATE POLICY "Users can update own data" ON users
    FOR UPDATE USING (auth.uid() = id);

-- ============================================
-- ADD ALL MISSING COLUMNS TO VANS TABLE
-- ============================================

-- Add name column if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'vans' AND column_name = 'name'
    ) THEN
        ALTER TABLE vans ADD COLUMN name TEXT NOT NULL DEFAULT 'Van';
        RAISE NOTICE 'Added name column to vans table';
    END IF;
END $$;

-- Add license_plate column if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'vans' AND column_name = 'license_plate'
    ) THEN
        ALTER TABLE vans ADD COLUMN license_plate TEXT UNIQUE;
        RAISE NOTICE 'Added license_plate column to vans table';
    END IF;
END $$;

-- Add model column if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'vans' AND column_name = 'model'
    ) THEN
        ALTER TABLE vans ADD COLUMN model TEXT;
        RAISE NOTICE 'Added model column to vans table';
    END IF;
END $$;

-- Add capacity column if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'vans' AND column_name = 'capacity'
    ) THEN
        ALTER TABLE vans ADD COLUMN capacity INTEGER DEFAULT 1;
        RAISE NOTICE 'Added capacity column to vans table';
    END IF;
END $$;

-- Add status column if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'vans' AND column_name = 'status'
    ) THEN
        ALTER TABLE vans ADD COLUMN status TEXT DEFAULT 'available';
        RAISE NOTICE 'Added status column to vans table';
    END IF;
END $$;

-- Add description column if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'vans' AND column_name = 'description'
    ) THEN
        ALTER TABLE vans ADD COLUMN description TEXT;
        RAISE NOTICE 'Added description column to vans table';
    END IF;
END $$;

-- Add area column if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'vans' AND column_name = 'area'
    ) THEN
        ALTER TABLE vans ADD COLUMN area TEXT;
        RAISE NOTICE 'Added area column to vans table';
    END IF;
END $$;

-- ============================================
-- ADD MISSING COLUMNS TO USERS TABLE
-- ============================================

-- Add profile_image column if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'users' AND column_name = 'profile_image'
    ) THEN
        ALTER TABLE users ADD COLUMN profile_image TEXT;
        RAISE NOTICE 'Added profile_image column to users table';
    END IF;
END $$;

-- ============================================
-- REFRESH POSTGREST SCHEMA CACHE
-- ============================================

-- Notify PostgREST to reload schema
SELECT pg_notify('pgrst', 'reload schema');

-- ============================================
-- VERIFY COLUMNS EXIST
-- ============================================

-- Verify vans table columns
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'vans'
ORDER BY ordinal_position;

-- Verify RLS policies on vans
SELECT policyname, cmd, qual
FROM pg_policies
WHERE tablename = 'vans';

-- ============================================
-- CONFIRMATION
-- ============================================

DO $$
BEGIN
    RAISE NOTICE 'RLS policies fixed for vans and users tables';
    RAISE NOTICE 'Missing columns added';
    RAISE NOTICE 'PostgREST schema cache refresh triggered';
END $$;
