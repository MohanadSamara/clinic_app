# Database Schema Fix for Appointment Booking Error

## Problem Summary
The application was experiencing a SQLite error when trying to book appointments:
```
table appointments has no column named service_request_id, SQL logic error (code 1)
```

## Root Cause
The `appointments` table in the SQLite database was missing the `service_request_id` column, but the application code (specifically the `Appointment` model) was trying to insert data into this column.

## Analysis
1. The `Appointment` model in `lib/models/appointment.dart` includes a `service_request_id` field
2. The `toMap()` method includes this field in INSERT statements
3. However, the initial database table creation in `lib/db/db_helper.dart` did not include this column
4. There was a migration for version 29 that should add this column, but it wasn't working properly for existing databases

## Solution Applied

### 1. Updated Initial Table Creation
Modified the initial `appointments` table creation in `_createDB()` method to include the `service_request_id` column:

```sql
CREATE TABLE appointments (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  owner_id INTEGER,
  pet_id INTEGER,
  service_type TEXT,
  description TEXT,
  scheduled_at TEXT,
  status TEXT,
  address TEXT,
  price REAL,
  doctor_id INTEGER,
  driver_id INTEGER,
  urgency_level TEXT,
  location_lat REAL,
  location_lng REAL,
  calendar_event_id TEXT,
  payment_method TEXT,
  service_request_id INTEGER  -- Added this column
);
```

### 2. Enhanced Database Migration
Added a robust version 30 migration that safely checks if the column exists before adding it:

```dart
if (oldVersion < 30) {
  try {
    final result = await db.rawQuery("PRAGMA table_info(appointments)");
    final columns = result.map((row) => row['name'] as String).toList();

    if (!columns.contains('service_request_id')) {
      await db.execute(
        'ALTER TABLE appointments ADD COLUMN service_request_id INTEGER',
      );
      debugPrint(
        'Added service_request_id column to appointments table in version 30',
      );
    }
  } catch (e) {
    debugPrint(
      'Error ensuring service_request_id column exists in appointments table: $e',
    );
  }
}
```

### 3. Updated Database Version
Changed the database version from 29 to 30 to ensure the migration runs for existing databases.

## Files Modified
- `lib/db/db_helper.dart`: Updated table creation, added robust migration, and incremented version

## Testing
Created `test_database_fix.dart` to verify:
1. The `service_request_id` column exists in the appointments table
2. INSERT operations with `service_request_id` work correctly

## Impact
- **For new installations**: The `appointments` table will be created with the `service_request_id` column from the start
- **For existing databases**: The version 30 migration will automatically add the missing column
- **No data loss**: The migration is safe and preserves all existing appointment data

## Resolution
This fix resolves the appointment booking error by ensuring database schema consistency between the application code and the actual database structure.