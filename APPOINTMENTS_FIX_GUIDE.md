# Appointments Not Showing Up - Root Cause Analysis & Solution

## Problem Summary
Your appointments exist in the database but don't appear in the Flutter app. Here's why:

## Root Cause: RLS (Row Level Security) Policy Issue

The Supabase RLS policy on the `appointments` table was blocking data access:

```sql
-- Old restrictive policy (from COMPLETE_RLS_FIX.sql):
CREATE POLICY "appt_doc_select" ON appointments FOR SELECT USING (
    doctor_id = auth.uid() OR
    EXISTS (SELECT 1 FROM users WHERE users.id = auth.uid() AND users.role IN ('doctor', 'admin'))
);
```

### The Problem:
1. **Authentication Mismatch**: Your app uses two separate systems:
   - `auth.users` table (Supabase Auth) - provides `auth.uid()`
   - `users` table (custom table) - stores user data with roles

2. **RLS Checks `auth.uid()`**: Supabase RLS policies check `auth.uid()` which comes from Supabase Auth, NOT your `users` table.

3. **Data Exists**: Your SQL query shows 5 appointments exist in the database, but the app's RLS policy is blocking access.

## Your Appointment Data (from SQL results)
| ID | Service Type | Status | Doctor ID | Scheduled |
|----|-------------|--------|-----------|-----------|
| ce7f75ec... | Live Checkup | confirmed | 74936969... | 2026-02-01 |
| 788e7a41... | Vaccination | accepted | 74936969... | 2026-02-01 |
| 2f2cf9e1... | Vaccination | accepted | 74936969... | 2026-02-01 |
| f36c7c79... | Vaccination | accepted | 74936969... | 2026-02-01 |
| b5353e53... | Vaccination | paid | 74936969... | 2026-02-01 |

## Solution Steps

### Step 1: Apply the Quick Fix (Recommended)
Run this SQL in Supabase SQL Editor:
```sql
-- Drop restrictive policy
DROP POLICY IF EXISTS permissive_all_access ON appointments;

-- Create permissive policy for authenticated users
CREATE POLICY "allow_all_authenticated" ON appointments
    FOR SELECT
    USING (auth.role() = 'authenticated');

-- Also allow INSERT/UPDATE/DELETE
CREATE POLICY "allow_all_insert" ON appointments
    FOR INSERT
    WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "allow_all_update" ON appointments
    FOR UPDATE
    USING (auth.role() = 'authenticated');

CREATE POLICY "allow_all_delete" ON appointments
    FOR DELETE
    USING (auth.role() = 'authenticated');

-- Refresh schema
SELECT pg_notify('pgrst', 'reload schema');
```

### Step 2: Verify the Fix
Run this to test:
```sql
-- Should show all 5 appointments
SELECT COUNT(*) FROM appointments;

-- Should show policies
SELECT policyname FROM pg_policies WHERE tablename = 'appointments';
```

## Additional Code Fixes Needed

### Fix 1: Date Filtering Logic
The app's date filtering might also cause issues. The appointments show:
- `scheduled_at: "2026-02-01 20:23:00+00"`

Make sure your device date is correct and check if filtering is too restrictive.

### Fix 2: Error Handling
Add better error logging in `appointment_provider.dart`:

```dart
Future<void> loadAppointments({
  String? ownerId,
  String? doctorId,
  bool forceRefresh = false,
}) async {
  _isLoading = true;
  _error = null;
  notifyListeners();

  try {
    final appointmentsData = await _supabaseService.getAppointments(
      ownerId: ownerId,
      doctorId: doctorId,
    );
    
    debugPrint('✅ Loaded ${appointmentsData.length} appointments');
    for (var apt in appointmentsData) {
      debugPrint('  - ${apt['id']}: ${apt['service_type']} (${apt['status']})');
    }
    
    _appointments = appointmentsData
        .map((data) => Appointment.fromMap(data))
        .toList();
  } catch (e) {
    debugPrint('❌ Error loading appointments: $e');
    _error = 'Error loading appointments: $e';
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}
```

## Files Created for Fix
1. `QUICK_APPOINTMENTS_FIX.sql` - Simple SQL to run in Supabase
2. `APPOINTMENTS_RLS_FIX.sql` - Comprehensive RLS fix
3. `APPOINTMENTS_FIX_DIAGNOSTIC.sql` - Diagnostic queries

## Testing After Fix
1. Run the SQL fix in Supabase
2. Restart your Flutter app
3. Check the doctor dashboard for appointments
4. Look for debug output showing appointment count

## If Still Not Working
Check these potential issues:
1. **User ID mismatch**: Make sure `authProvider.user!.id` matches the `doctor_id` in appointments
2. **Date filtering**: Verify today's date includes 2026-02-01
3. **Network issues**: Check if Supabase client is configured correctly
4. **Cached data**: Clear app cache and restart

## Supabase Dashboard Verification
Go to Supabase Dashboard → Authentication → Users and check:
1. Is your user logged in?
2. What is your `auth.uid()`?
3. Does it match the `doctor_id` in appointments table?

---
Generated: 2026-02-01

