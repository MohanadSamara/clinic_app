-- Migration to fix RLS policies - COMPLETE FIX
-- Run this in Supabase SQL Editor
-- This fixes the RLS error 42501 for the vans table

-- ============================================
-- DISABLE RLS ON VANS TABLE (for development)
-- ============================================

-- First disable RLS
ALTER TABLE vans DISABLE ROW LEVEL SECURITY;

-- Drop ALL existing RLS policies on vans
DROP POLICY IF EXISTS "Enable insert for authenticated users" ON vans;
DROP POLICY IF EXISTS "Enable read access for authenticated users" ON vans;
DROP POLICY IF EXISTS "Enable update for authenticated users" ON vans;
DROP POLICY IF EXISTS "Enable delete for authenticated users" ON vans;
DROP POLICY IF EXISTS "Users can insert vans" ON vans;
DROP POLICY IF EXISTS "Allow authenticated users to insert vans" ON vans;
DROP POLICY IF EXISTS "Allow all authenticated inserts" ON vans;

-- ============================================
-- ADD MISSING COLUMNS TO VANS TABLE
-- ============================================

-- Add name column if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'vans' AND column_name = 'name'
    ) THEN
        ALTER TABLE vans ADD COLUMN name TEXT NOT NULL DEFAULT 'Van';
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
    END IF;
END $$;

-- ============================================
-- REFRESH POSTGREST SCHEMA CACHE
-- ============================================

SELECT pg_notify('pgrst', 'reload schema');

-- ============================================
-- VERIFY
-- ============================================

-- Check if RLS is disabled
SELECT tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public' AND tablename = 'vans';

-- List vans table columns
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'vans' 
ORDER BY ordinal_position;
