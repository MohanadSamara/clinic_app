-- Fix for vans table 'area' column missing error
-- Run this SQL in Supabase SQL Editor to fix the issue

-- Add the missing 'area' column to vans table
ALTER TABLE vans ADD COLUMN IF NOT EXISTS area TEXT;

-- Verify the column was added
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'vans' 
ORDER BY ordinal_position;

-- Refresh the schema cache (optional but recommended)
-- This ensures Supabase recognizes the new column
NOTIFY pgrst, 'reload schema';

-- If the above doesn't work, try dropping and recreating the table (WARNING: DATA LOSS)
-- Only run this if the column still doesn't appear after the ALTER TABLE command above

/*
-- First backup any existing data
SELECT * INTO vans_backup FROM vans;

-- Drop the existing table
DROP TABLE IF EXISTS vans CASCADE;

-- Recreate the table with all columns including 'area'
CREATE TABLE vans (
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

-- Restore the data from backup
INSERT INTO vans (id, name, license_plate, model, capacity, status, description, assigned_driver_id, assigned_doctor_id, created_at, updated_at)
SELECT id, name, license_plate, model, capacity, status, description, assigned_driver_id, assigned_doctor_id, created_at, updated_at FROM vans_backup;

-- Re-enable RLS
ALTER TABLE vans ENABLE ROW LEVEL SECURITY;

-- Recreate the trigger
CREATE TRIGGER update_vans_updated_at BEFORE UPDATE ON vans
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Drop the backup table
DROP TABLE vans_backup;
*/

