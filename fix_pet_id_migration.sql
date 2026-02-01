-- Fix pet_id fields that contain serial_number instead of UUID
-- This migration corrects records where pet_id was incorrectly set to a serial number instead of the pet's UUID

-- Step 1: First, let's see what invalid pet_ids exist (cast UUID to text for regex matching)
SELECT 'service_requests' as table_name, COUNT(*) as count, ARRAY_AGG(DISTINCT pet_id) as invalid_pet_ids
FROM public.service_requests 
WHERE pet_id IS NOT NULL 
  AND pet_id::text !~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$';

SELECT 'appointments' as table_name, COUNT(*) as count, ARRAY_AGG(DISTINCT pet_id) as invalid_pet_ids
FROM public.appointments 
WHERE pet_id IS NOT NULL 
  AND pet_id::text !~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$';

-- Step 2: Fix service_requests: Update pet_id to correct UUID based on serial_number
UPDATE public.service_requests sr
SET pet_id = p.id
FROM public.pets p
WHERE sr.pet_id::text = p.serial_number
  AND sr.pet_id IS NOT NULL
  AND sr.pet_id::text !~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$';

-- Step 3: Fix appointments: Update pet_id to correct UUID based on serial_number
UPDATE public.appointments a
SET pet_id = p.id
FROM public.pets p
WHERE a.pet_id::text = p.serial_number
  AND a.pet_id IS NOT NULL
  AND a.pet_id::text !~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$';

-- Step 4: Also fix medical_records if they have the same issue
UPDATE public.medical_records mr
SET pet_id = p.id
FROM public.pets p
WHERE mr.pet_id::text = p.serial_number
  AND mr.pet_id IS NOT NULL
  AND mr.pet_id::text !~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$';

-- Step 5: Fix documents if they have the same issue
UPDATE public.documents d
SET pet_id = p.id
FROM public.pets p
WHERE d.pet_id::text = p.serial_number
  AND d.pet_id IS NOT NULL
  AND d.pet_id::text !~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$';

-- Step 6: Fix vaccination_records if they have the same issue
UPDATE public.vaccination_records vr
SET pet_id = p.id
FROM public.pets p
WHERE vr.pet_id::text = p.serial_number
  AND vr.pet_id IS NOT NULL
  AND vr.pet_id::text !~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$';

-- Step 7: Verify the fix - there should be 0 invalid records now
SELECT 'service_requests' as table_name, COUNT(*) as invalid_count 
FROM public.service_requests 
WHERE pet_id IS NOT NULL 
  AND pet_id::text !~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
UNION ALL
SELECT 'appointments' as table_name, COUNT(*) as invalid_count 
FROM public.appointments 
WHERE pet_id IS NOT NULL 
  AND pet_id::text !~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$';

-- Step 8: Show what serial_number 437454712 corresponds to (if exists)
SELECT id, serial_number, name FROM public.pets WHERE serial_number = '437454712';
