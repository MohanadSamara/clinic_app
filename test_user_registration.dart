// Test user registration
import 'lib/db/db_helper.dart';

void main() async {
  print('Testing user registration...');

  try {
    final dbHelper = DBHelper.instance;
    final db = await dbHelper.database;

    // Test inserting a user
    final testUser = {
      'name': 'Test User',
      'email': 'test@example.com',
      'password': 'testpassword123',
      'phone': '+1234567890',
      'role': 'owner',
      'verification_status': 'verified',
    };

    print('Inserting user with data: $testUser');

    final id = await db.insert('users', testUser);
    print('✅ SUCCESS: User inserted with ID: $id');

    // Verify the user was inserted correctly
    final result = await db.query('users', where: 'id=?', whereArgs: [id]);
    if (result.isNotEmpty) {
      final user = result.first;
      print('Retrieved user: $user');
      if (user['password'] == 'testpassword123') {
        print('✅ SUCCESS: Password saved correctly');
      } else {
        print(
          '❌ ERROR: Password not saved correctly. Stored: ${user['password']}',
        );
      }
    } else {
      print('❌ ERROR: User not found after insertion');
    }

    // Clean up
    await db.delete('users', where: 'id=?', whereArgs: [id]);
    print('✅ SUCCESS: Test data cleaned up');
  } catch (e) {
    print('❌ ERROR: $e');
  }

  print('User registration test completed.');
}
