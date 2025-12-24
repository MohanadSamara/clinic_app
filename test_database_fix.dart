// test_database_fix.dart
import 'lib/db/db_helper.dart';

void main() async {
  print('Testing database schema fix...');

  try {
    // Initialize database
    final dbHelper = DBHelper.instance;
    final db = await dbHelper.database;

    // Check if service_request_id column exists in appointments table
    final result = await db.rawQuery("PRAGMA table_info(appointments)");
    final columns = result.map((row) => row['name'] as String).toList();

    print('Current columns in appointments table:');
    for (final column in columns) {
      print('  - $column');
    }

    if (columns.contains('service_request_id')) {
      print(
        '✅ SUCCESS: service_request_id column exists in appointments table',
      );
    } else {
      print(
        '❌ ERROR: service_request_id column is missing from appointments table',
      );
    }

    // Test inserting an appointment with service_request_id
    try {
      final testAppointment = {
        'owner_id': 1,
        'pet_id': 1,
        'service_type': 'Test Service',
        'description': 'Test appointment for schema validation',
        'scheduled_at': DateTime.now().toIso8601String(),
        'status': 'pending',
        'address': 'Test Address',
        'price': 30.0,
        'doctor_id': 2,
        'urgency_level': 'routine',
        'payment_method': 'cash',
        'service_request_id': null, // This should work now
      };

      final id = await db.insert('appointments', testAppointment);
      print('✅ SUCCESS: Appointment inserted with ID: $id');

      // Clean up test data
      await db.delete('appointments', where: 'id=?', whereArgs: [id]);
      print('✅ SUCCESS: Test data cleaned up');
    } catch (e) {
      print('❌ ERROR: Failed to insert appointment: $e');
    }
  } catch (e) {
    print('❌ ERROR: Database test failed: $e');
  }

  print('Database schema test completed.');
}
