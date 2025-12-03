// lib/db/db_helper.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

class DBHelper {
  static final DBHelper instance = DBHelper._init();
  static Database? _db;

  DBHelper._init() {
    if (kIsWeb) {
      // For web
      databaseFactory = databaseFactoryFfiWeb;
    } else {
      // For desktop platforms (Windows, Linux, macOS)
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    // Note: For mobile (Android/iOS), sqflite uses the default factory automatically
  }

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB('vet_clinic.db');
    return _db!;
  }

  Future<Database> _initDB(String filePath) async {
    String dbPath;
    if (kIsWeb) {
      // For web, use the default path (IndexedDB)
      dbPath = await getDatabasesPath();
    } else if (Platform.isAndroid || Platform.isIOS) {
      // For mobile, use the standard app data directory
      dbPath = await getDatabasesPath();
    } else {
      // For desktop (Windows, Linux, macOS), use a persistent directory in the user's documents
      final directory = await getApplicationDocumentsDirectory();
      dbPath = directory.path;
    }
    final path = join(dbPath, filePath);
    return await openDatabase(
      path,
      version: 25,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 3) {
      // Add new tables for version 3
      await _createNewTablesV3(db);
    }
    if (oldVersion < 4) {
      // Add doctor_id column to appointments table
      try {
        await db.execute(
          'ALTER TABLE appointments ADD COLUMN doctor_id INTEGER',
        );
      } catch (e) {
        debugPrint('Error adding doctor_id column: $e');
      }
    }
    if (oldVersion < 5) {
      // Add new tables for service assignments and sessions
      await _createNewTablesV5(db);
    }
    if (oldVersion < 7) {
      // Add promotional_price column to services table
      try {
        await db.execute(
          'ALTER TABLE services ADD COLUMN promotional_price REAL',
        );
      } catch (e) {
        debugPrint('Error adding promotional_price column: $e');
      }
    }
    if (oldVersion < 8) {
      // Add routes and vehicle_checks tables
      await db.execute('''
        CREATE TABLE IF NOT EXISTS routes (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          driver_id INTEGER,
          appointment_id INTEGER,
          start_lat REAL,
          start_lng REAL,
          end_lat REAL,
          end_lng REAL,
          waypoints TEXT,
          distance REAL,
          duration INTEGER,
          status TEXT,
          created_at TEXT,
          FOREIGN KEY (driver_id) REFERENCES users (id),
          FOREIGN KEY (appointment_id) REFERENCES appointments (id)
        );
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS vehicle_checks (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          driver_id INTEGER,
          check_date TEXT,
          fuel_level TEXT,
          tire_condition TEXT,
          lights_ok INTEGER,
          medical_equipment_ok INTEGER,
          notes TEXT,
          photos TEXT,
          created_at TEXT,
          FOREIGN KEY (driver_id) REFERENCES users (id)
        );
      ''');
    }
    if (oldVersion < 9) {
      // Add serial_number column to pets table
      try {
        await db.execute('ALTER TABLE pets ADD COLUMN serial_number TEXT');
        debugPrint('Added serial_number column to pets table');
      } catch (e) {
        debugPrint('Error adding serial_number column: $e');
      }
    }
    if (oldVersion < 10) {
      // Add provider and providerId columns to users table for social auth
      try {
        await db.execute('ALTER TABLE users ADD COLUMN provider TEXT');
        await db.execute('ALTER TABLE users ADD COLUMN providerId TEXT');
        debugPrint('Added provider and providerId columns to users table');
      } catch (e) {
        debugPrint('Error adding social auth columns: $e');
      }
    }
    if (oldVersion < 11) {
      // Ensure provider and providerId columns exist (fix for existing databases)
      try {
        // Check if columns exist and add them if they don't
        final result = await db.rawQuery("PRAGMA table_info(users)");
        final columns = result.map((row) => row['name'] as String).toList();

        if (!columns.contains('provider')) {
          await db.execute('ALTER TABLE users ADD COLUMN provider TEXT');
          debugPrint('Added provider column to users table');
        }
        if (!columns.contains('providerId')) {
          await db.execute('ALTER TABLE users ADD COLUMN providerId TEXT');
          debugPrint('Added providerId column to users table');
        }
      } catch (e) {
        debugPrint('Error ensuring social auth columns exist: $e');
      }
    }
    if (oldVersion < 12) {
      // Add new columns to documents table for enhanced file management
      try {
        await db.execute(
          'ALTER TABLE documents ADD COLUMN version INTEGER DEFAULT 1',
        );
        await db.execute(
          'ALTER TABLE documents ADD COLUMN uploaded_by INTEGER',
        );
        await db.execute(
          'ALTER TABLE documents ADD COLUMN access_level TEXT DEFAULT "private"',
        );
        await db.execute(
          'ALTER TABLE documents ADD COLUMN encryption_key TEXT',
        );
        await db.execute(
          'ALTER TABLE documents ADD COLUMN file_size INTEGER DEFAULT 0',
        );
        await db.execute('ALTER TABLE documents ADD COLUMN mime_type TEXT');
        await db.execute('ALTER TABLE documents ADD COLUMN checksum TEXT');
        await db.execute('ALTER TABLE documents ADD COLUMN audit_logs TEXT');
        debugPrint('Added enhanced columns to documents table');
      } catch (e) {
        debugPrint('Error adding enhanced columns to documents table: $e');
      }

      // Create audit_logs table
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS audit_logs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            document_id INTEGER,
            user_id INTEGER,
            action TEXT,
            timestamp TEXT,
            details TEXT,
            ip_address TEXT,
            FOREIGN KEY (document_id) REFERENCES documents (id),
            FOREIGN KEY (user_id) REFERENCES users (id)
          );
        ''');
        debugPrint('Created audit_logs table');
      } catch (e) {
        debugPrint('Error creating audit_logs table: $e');
      }
    }
    if (oldVersion < 13) {
      // Add profileImage column to users table
      try {
        await db.execute('ALTER TABLE users ADD COLUMN profileImage TEXT');
        debugPrint('Added profileImage column to users table');
      } catch (e) {
        debugPrint('Error adding profileImage column: $e');
      }
    }
    if (oldVersion < 14) {
      // Add linked_doctor_id and linked_driver_id columns to users table for direct doctor-driver linking
      try {
        await db.execute(
          'ALTER TABLE users ADD COLUMN linked_doctor_id INTEGER',
        );
        await db.execute(
          'ALTER TABLE users ADD COLUMN linked_driver_id INTEGER',
        );
        debugPrint(
          'Added linked_doctor_id and linked_driver_id columns to users table',
        );
      } catch (e) {
        debugPrint('Error adding linked columns to users table: $e');
      }
    }
    if (oldVersion < 15) {
      // Ensure linked_doctor_id and linked_driver_id columns exist (fix for databases where migration failed)
      try {
        final result = await db.rawQuery("PRAGMA table_info(users)");
        final columns = result.map((row) => row['name'] as String).toList();

        if (!columns.contains('linked_doctor_id')) {
          await db.execute(
            'ALTER TABLE users ADD COLUMN linked_doctor_id INTEGER',
          );
          debugPrint('Added linked_doctor_id column to users table');
        }
        if (!columns.contains('linked_driver_id')) {
          await db.execute(
            'ALTER TABLE users ADD COLUMN linked_driver_id INTEGER',
          );
          debugPrint('Added linked_driver_id column to users table');
        }
      } catch (e) {
        debugPrint('Error ensuring linked columns exist: $e');
      }
    }
    if (oldVersion < 16) {
      // Add medical_record_id column to documents table
      try {
        await db.execute(
          'ALTER TABLE documents ADD COLUMN medical_record_id INTEGER',
        );
        debugPrint('Added medical_record_id column to documents table');
      } catch (e) {
        debugPrint(
          'Error adding medical_record_id column to documents table: $e',
        );
      }
    }
    if (oldVersion < 17) {
      // Add calendar_event_id column to appointments table for Google Calendar integration
      try {
        await db.execute(
          'ALTER TABLE appointments ADD COLUMN calendar_event_id TEXT',
        );
        debugPrint('Added calendar_event_id column to appointments table');
      } catch (e) {
        debugPrint(
          'Error adding calendar_event_id column to appointments table: $e',
        );
      }
    }
    if (oldVersion < 18) {
      // Add availability_status and last_seen columns to users table for real-time availability tracking
      try {
        await db.execute(
          'ALTER TABLE users ADD COLUMN availability_status TEXT DEFAULT "offline"',
        );
        await db.execute('ALTER TABLE users ADD COLUMN last_seen TEXT');
        debugPrint(
          'Added availability_status and last_seen columns to users table',
        );
      } catch (e) {
        debugPrint('Error adding availability columns to users table: $e');
      }
    }
    if (oldVersion < 19) {
      // Update payments table to new structure with invoice details
      try {
        // Add new columns to payments table
        await db.execute('ALTER TABLE payments ADD COLUMN user_id INTEGER');
        await db.execute(
          'ALTER TABLE payments ADD COLUMN subtotal REAL DEFAULT 0.0',
        );
        await db.execute(
          'ALTER TABLE payments ADD COLUMN tax REAL DEFAULT 0.0',
        );
        await db.execute(
          'ALTER TABLE payments ADD COLUMN total REAL DEFAULT 0.0',
        );
        await db.execute(
          'ALTER TABLE payments ADD COLUMN currency TEXT DEFAULT "JOD"',
        );
        await db.execute(
          'ALTER TABLE payments ADD COLUMN payment_intent_id TEXT',
        );
        await db.execute('ALTER TABLE payments ADD COLUMN invoice_number TEXT');
        await db.execute(
          'ALTER TABLE payments ADD COLUMN service_description TEXT',
        );
        await db.execute('ALTER TABLE payments ADD COLUMN completed_at TEXT');

        // Update existing records to have user_id from appointments
        await db.execute('''
          UPDATE payments
          SET user_id = (SELECT owner_id FROM appointments WHERE appointments.id = payments.appointment_id),
              subtotal = amount / 1.16,
              tax = amount - (amount / 1.16),
              total = amount,
              service_description = 'Veterinary Service'
          WHERE user_id IS NULL
        ''');

        debugPrint('Updated payments table to new structure');
      } catch (e) {
        debugPrint('Error updating payments table: $e');
      }
    }
    if (oldVersion < 20) {
      // Ensure payments table has all required columns (fix for failed migrations)
      try {
        final result = await db.rawQuery("PRAGMA table_info(payments)");
        final columns = result.map((row) => row['name'] as String).toList();

        // Add missing columns if they don't exist
        if (!columns.contains('user_id')) {
          await db.execute('ALTER TABLE payments ADD COLUMN user_id INTEGER');
        }
        if (!columns.contains('subtotal')) {
          await db.execute(
            'ALTER TABLE payments ADD COLUMN subtotal REAL DEFAULT 0.0',
          );
        }
        if (!columns.contains('tax')) {
          await db.execute(
            'ALTER TABLE payments ADD COLUMN tax REAL DEFAULT 0.0',
          );
        }
        if (!columns.contains('total')) {
          await db.execute(
            'ALTER TABLE payments ADD COLUMN total REAL DEFAULT 0.0',
          );
        }
        if (!columns.contains('currency')) {
          await db.execute(
            'ALTER TABLE payments ADD COLUMN currency TEXT DEFAULT "JOD"',
          );
        }
        if (!columns.contains('payment_intent_id')) {
          await db.execute(
            'ALTER TABLE payments ADD COLUMN payment_intent_id TEXT',
          );
        }
        if (!columns.contains('invoice_number')) {
          await db.execute(
            'ALTER TABLE payments ADD COLUMN invoice_number TEXT',
          );
        }
        if (!columns.contains('service_description')) {
          await db.execute(
            'ALTER TABLE payments ADD COLUMN service_description TEXT',
          );
        }
        if (!columns.contains('completed_at')) {
          await db.execute('ALTER TABLE payments ADD COLUMN completed_at TEXT');
        }

        // Update any records that still have NULL values
        await db.execute('''
          UPDATE payments
          SET user_id = COALESCE(user_id, (SELECT owner_id FROM appointments WHERE appointments.id = payments.appointment_id)),
              subtotal = COALESCE(subtotal, amount / 1.16),
              tax = COALESCE(tax, amount - (amount / 1.16)),
              total = COALESCE(total, amount),
              currency = COALESCE(currency, 'JOD'),
              service_description = COALESCE(service_description, 'Veterinary Service')
          WHERE user_id IS NULL OR subtotal IS NULL OR tax IS NULL OR total IS NULL
        ''');

        debugPrint('Ensured payments table has all required columns');
      } catch (e) {
        debugPrint('Error ensuring payments table columns: $e');
      }
    }
    if (oldVersion < 21) {
      // Final fix for payments table - ensure all columns exist and are properly populated
      try {
        final result = await db.rawQuery("PRAGMA table_info(payments)");
        final columns = result.map((row) => row['name'] as String).toList();

        // Force add user_id column if it doesn't exist (this should fix the issue)
        if (!columns.contains('user_id')) {
          await db.execute('ALTER TABLE payments ADD COLUMN user_id INTEGER');
          debugPrint('Added user_id column to payments table');
        }

        // Ensure all other columns exist
        final requiredColumns = {
          'subtotal': 'REAL DEFAULT 0.0',
          'tax': 'REAL DEFAULT 0.0',
          'total': 'REAL DEFAULT 0.0',
          'currency': 'TEXT DEFAULT "JOD"',
          'payment_intent_id': 'TEXT',
          'invoice_number': 'TEXT',
          'service_description': 'TEXT',
          'completed_at': 'TEXT',
        };

        for (final entry in requiredColumns.entries) {
          if (!columns.contains(entry.key)) {
            await db.execute(
              'ALTER TABLE payments ADD COLUMN ${entry.key} ${entry.value}',
            );
            debugPrint('Added ${entry.key} column to payments table');
          }
        }

        // Populate user_id for existing records if missing
        await db.execute('''
          UPDATE payments
          SET user_id = (SELECT owner_id FROM appointments WHERE appointments.id = payments.appointment_id)
          WHERE user_id IS NULL
        ''');

        // Populate other fields for existing records
        await db.execute('''
          UPDATE payments
          SET subtotal = COALESCE(subtotal, ROUND(amount / 1.16, 2)),
              tax = COALESCE(tax, ROUND(amount - (amount / 1.16), 2)),
              total = COALESCE(total, amount),
              currency = COALESCE(currency, 'JOD'),
              service_description = COALESCE(service_description, 'Veterinary Service')
          WHERE subtotal IS NULL OR tax IS NULL OR total IS NULL
        ''');

        debugPrint('Completed payments table migration to version 21');
      } catch (e) {
        debugPrint('Error in version 21 migration: $e');
      }
    }
    if (oldVersion < 22) {
      // Force fix for payments table user_id column
      try {
        final result = await db.rawQuery("PRAGMA table_info(payments)");
        final columns = result.map((row) => row['name'] as String).toList();

        if (!columns.contains('user_id')) {
          await db.execute('ALTER TABLE payments ADD COLUMN user_id INTEGER');
          debugPrint('Added user_id column to payments table in version 22');

          // Populate user_id for existing records
          await db.execute('''
            UPDATE payments
            SET user_id = (SELECT owner_id FROM appointments WHERE appointments.id = payments.appointment_id)
            WHERE user_id IS NULL
          ''');
        }

        debugPrint('Completed payments table migration to version 22');
      } catch (e) {
        debugPrint('Error in version 22 migration: $e');
      }
    }
    if (oldVersion < 23) {
      // Final fix for payments table - ensure all columns exist and are properly populated
      try {
        final result = await db.rawQuery("PRAGMA table_info(payments)");
        final columns = result.map((row) => row['name'] as String).toList();

        // Ensure user_id column exists
        if (!columns.contains('user_id')) {
          await db.execute('ALTER TABLE payments ADD COLUMN user_id INTEGER');
          debugPrint('Added user_id column to payments table in version 23');
        }

        // Populate user_id for existing records if missing
        await db.execute('''
          UPDATE payments
          SET user_id = (SELECT owner_id FROM appointments WHERE appointments.id = payments.appointment_id)
          WHERE user_id IS NULL
        ''');

        debugPrint('Completed payments table migration to version 23');
      } catch (e) {
        debugPrint('Error in version 23 migration: $e');
      }
    }
    if (oldVersion < 24) {
      // Add area column to vans table
      try {
        await db.execute('ALTER TABLE vans ADD COLUMN area TEXT');
        debugPrint('Added area column to vans table in version 24');
      } catch (e) {
        debugPrint('Error adding area column to vans table: $e');
      }
    }
    if (oldVersion < 25) {
      // Add area column to users table
      try {
        await db.execute('ALTER TABLE users ADD COLUMN area TEXT');
        debugPrint('Added area column to users table in version 25');
      } catch (e) {
        debugPrint('Error adding area column to users table: $e');
      }
    }
    // Version 6 migration removed - simplified user table
  }

  Future _createDB(Database db, int version) async {
    // Only drop tables if version is 1 (fresh install)
    // For upgrades, preserve existing data
    // Note: Removed table dropping to preserve data on app restart

    // Users table
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        phone TEXT,
        role TEXT NOT NULL DEFAULT 'owner',
        provider TEXT,
        providerId TEXT,
        profileImage TEXT,
        area TEXT,
        linked_doctor_id INTEGER,
        linked_driver_id INTEGER,
        availability_status TEXT DEFAULT 'offline',
        last_seen TEXT
      );
    ''');

    // Pets table with extended fields
    await db.execute('''
      CREATE TABLE pets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        owner_id INTEGER,
        name TEXT,
        species TEXT,
        breed TEXT,
        dob TEXT,
        notes TEXT,
        medical_history_summary TEXT,
        vaccination_status TEXT,
        photo_path TEXT,
        serial_number TEXT UNIQUE
      );
    ''');

    // Appointments table with driver and location fields
    await db.execute('''
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
        calendar_event_id TEXT
      );
    ''');

    // Create indexes for appointments performance
    await db.execute(
      'CREATE INDEX idx_appointments_owner_id ON appointments(owner_id)',
    );
    await db.execute(
      'CREATE INDEX idx_appointments_doctor_id ON appointments(doctor_id)',
    );
    await db.execute(
      'CREATE INDEX idx_appointments_driver_id ON appointments(driver_id)',
    );
    await db.execute(
      'CREATE INDEX idx_appointments_status ON appointments(status)',
    );
    await db.execute(
      'CREATE INDEX idx_appointments_scheduled_at ON appointments(scheduled_at)',
    );
    await db.execute(
      'CREATE INDEX idx_appointments_location ON appointments(location_lat, location_lng)',
    );
    await db.execute(
      'CREATE INDEX idx_appointments_owner_status ON appointments(owner_id, status)',
    );
    await db.execute(
      'CREATE INDEX idx_appointments_doctor_status ON appointments(doctor_id, status)',
    );

    // Services table
    await db.execute('''
      CREATE TABLE services (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        description TEXT,
        price REAL,
        category TEXT,
        is_active INTEGER,
        promotional_price REAL
      );
    ''');

    // Medical records table
    await db.execute('''
      CREATE TABLE medical_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        pet_id INTEGER,
        doctor_id INTEGER,
        diagnosis TEXT,
        treatment TEXT,
        prescription TEXT,
        notes TEXT,
        date TEXT,
        attachments TEXT
      );
    ''');

    // Inventory table
    await db.execute('''
      CREATE TABLE inventory (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        description TEXT,
        quantity INTEGER,
        min_threshold INTEGER,
        unit TEXT,
        cost REAL,
        category TEXT
      );
    ''');

    // Notifications table
    await db.execute('''
      CREATE TABLE notifications (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        title TEXT,
        message TEXT,
        type TEXT,
        is_read INTEGER,
        created_at TEXT,
        data TEXT
      );
    ''');

    // Payments table
    await db.execute('''
      CREATE TABLE payments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        appointment_id INTEGER,
        user_id INTEGER,
        amount REAL,
        subtotal REAL DEFAULT 0.0,
        tax REAL DEFAULT 0.0,
        total REAL DEFAULT 0.0,
        currency TEXT DEFAULT "JOD",
        method TEXT,
        status TEXT,
        transaction_id TEXT,
        payment_intent_id TEXT,
        invoice_number TEXT,
        service_description TEXT,
        completed_at TEXT,
        created_at TEXT
      );
    ''');

    // Vans table
    await db.execute('''
      CREATE TABLE vans (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        license_plate TEXT UNIQUE NOT NULL,
        model TEXT,
        capacity INTEGER DEFAULT 1,
        status TEXT DEFAULT 'available',
        description TEXT,
        area TEXT,
        assigned_driver_id INTEGER,
        assigned_doctor_id INTEGER,
        created_at TEXT,
        FOREIGN KEY (assigned_driver_id) REFERENCES users (id),
        FOREIGN KEY (assigned_doctor_id) REFERENCES users (id)
      );
    ''');

    // Driver status table
    await db.execute('''
      CREATE TABLE driver_status (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        driver_id INTEGER,
        latitude REAL,
        longitude REAL,
        status TEXT,
        current_appointment_id INTEGER,
        last_updated TEXT
      );
    ''');

    // Routes table
    await db.execute('''
      CREATE TABLE routes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        driver_id INTEGER,
        appointment_id INTEGER,
        start_lat REAL,
        start_lng REAL,
        end_lat REAL,
        end_lng REAL,
        waypoints TEXT,
        distance REAL,
        duration INTEGER,
        status TEXT,
        created_at TEXT,
        FOREIGN KEY (driver_id) REFERENCES users (id),
        FOREIGN KEY (appointment_id) REFERENCES appointments (id)
      );
    ''');

    // Vehicle checks table
    await db.execute('''
      CREATE TABLE vehicle_checks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        driver_id INTEGER,
        check_date TEXT,
        fuel_level TEXT,
        tire_condition TEXT,
        lights_ok INTEGER,
        medical_equipment_ok INTEGER,
        notes TEXT,
        photos TEXT,
        created_at TEXT,
        FOREIGN KEY (driver_id) REFERENCES users (id)
      );
    ''');

    // Create new tables for version 3
    await _createNewTablesV3(db);

    // Create new tables for version 5
    await _createNewTablesV5(db);

    // Create compliance logs table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS compliance_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        inspection_type TEXT,
        inspector_name TEXT,
        inspection_date TEXT,
        status TEXT,
        findings TEXT,
        corrective_actions TEXT,
        next_inspection_date TEXT,
        created_at TEXT
      );
    ''');

    // Create audit_logs table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS audit_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        document_id INTEGER,
        user_id INTEGER,
        action TEXT,
        timestamp TEXT,
        details TEXT,
        ip_address TEXT,
        FOREIGN KEY (document_id) REFERENCES documents (id),
        FOREIGN KEY (user_id) REFERENCES users (id)
      );
    ''');

    // Insert default services after creating tables
    await _insertDefaultServices(db);
  }

  Future _createNewTablesV3(Database db) async {
    // Documents table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS documents (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        pet_id INTEGER,
        medical_record_id INTEGER,
        file_name TEXT,
        file_type TEXT,
        file_path TEXT,
        description TEXT,
        upload_date TEXT,
        version INTEGER DEFAULT 1,
        uploaded_by INTEGER,
        access_level TEXT DEFAULT 'private',
        encryption_key TEXT,
        file_size INTEGER DEFAULT 0,
        mime_type TEXT,
        checksum TEXT,
        audit_logs TEXT
      );
    ''');

    // Vaccination records table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS vaccination_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        pet_id INTEGER,
        vaccine_name TEXT,
        vaccination_date TEXT,
        next_due_date TEXT,
        batch_number TEXT,
        veterinarian_name TEXT,
        notes TEXT
      );
    ''');

    // Service requests table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS service_requests (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        owner_id INTEGER,
        pet_id INTEGER,
        request_type TEXT,
        description TEXT,
        status TEXT,
        latitude REAL,
        longitude REAL,
        address TEXT,
        request_date TEXT,
        scheduled_date TEXT,
        assigned_doctor_id INTEGER,
        rejection_reason TEXT
      );
    ''');
  }

  Future _insertDefaultServices(Database db) async {
    final defaultServices = [
      {
        'name': 'Vaccination',
        'description': 'Regular vaccination service',
        'price': 50.0,
        'category': 'preventive',
        'is_active': 1,
      },
      {
        'name': 'Checkup',
        'description': 'General health checkup',
        'price': 30.0,
        'category': 'preventive',
        'is_active': 1,
      },
      {
        'name': 'Dental Care',
        'description': 'Teeth cleaning and dental care',
        'price': 80.0,
        'category': 'dental',
        'is_active': 1,
      },
      {
        'name': 'Emergency',
        'description': 'Emergency veterinary care',
        'price': 100.0,
        'category': 'emergency',
        'is_active': 1,
      },
      {
        'name': 'Surgery',
        'description': 'Surgical procedures',
        'price': 200.0,
        'category': 'surgical',
        'is_active': 1,
      },
      {
        'name': 'Grooming',
        'description': 'Pet grooming service',
        'price': 40.0,
        'category': 'grooming',
        'is_active': 1,
      },
    ];

    for (final service in defaultServices) {
      await db.insert('services', service);
    }
  }

  // ---------- USERS ----------
  Future<int> insertUser(Map<String, dynamic> data) async {
    final db = await instance.database;
    return await db.insert(
      'users',
      data,
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    final db = await instance.database;
    final res = await db.query('users', where: 'email=?', whereArgs: [email]);
    if (res.isNotEmpty) return res.first;
    return null;
  }

  Future<Map<String, dynamic>?> getUserByEmailAndPassword(
    String email,
    String password,
  ) async {
    final db = await instance.database;
    final res = await db.query(
      'users',
      where: 'email=? AND password=?',
      whereArgs: [email, password],
    );
    if (res.isNotEmpty) return res.first;
    return null;
  }

  Future<List<Map<String, dynamic>>> getAllUsers({String? role}) async {
    final db = await instance.database;
    if (role != null) {
      return await db.query('users', where: 'role=?', whereArgs: [role]);
    }
    return await db.query('users');
  }

  Future<int> updateUser(int id, Map<String, dynamic> data) async {
    final db = await instance.database;
    return await db.update('users', data, where: 'id=?', whereArgs: [id]);
  }

  Future<int> deleteUser(int id) async {
    final db = await instance.database;
    return await db.delete('users', where: 'id=?', whereArgs: [id]);
  }

  // ---------- PETS ----------
  Future<int> insertPet(Map<String, dynamic> data) async {
    final db = await instance.database;
    return await db.insert('pets', data);
  }

  Future<List<Map<String, dynamic>>> getPetsByOwner(int ownerId) async {
    final db = await instance.database;
    return await db.query('pets', where: 'owner_id=?', whereArgs: [ownerId]);
  }

  Future<List<Map<String, dynamic>>> getPetsByDoctor(int doctorId) async {
    final db = await instance.database;
    return await db.rawQuery(
      '''
      SELECT DISTINCT p.* FROM pets p
      INNER JOIN medical_records mr ON p.id = mr.pet_id
      WHERE mr.doctor_id = ?
      ORDER BY p.name ASC
    ''',
      [doctorId],
    );
  }

  Future<List<Map<String, dynamic>>> getPetsByLinkedDoctor(int doctorId) async {
    final db = await instance.database;
    return await db.rawQuery(
      '''
      SELECT p.* FROM pets p
      INNER JOIN users u ON p.owner_id = u.id
      WHERE u.linked_doctor_id = ?
      ORDER BY p.name ASC
    ''',
      [doctorId],
    );
  }

  Future<Map<String, dynamic>?> getPetById(int id) async {
    final db = await instance.database;
    final res = await db.query('pets', where: 'id=?', whereArgs: [id]);
    if (res.isNotEmpty) return res.first;
    return null;
  }

  Future<int> updatePet(int id, Map<String, dynamic> data) async {
    final db = await instance.database;
    return await db.update('pets', data, where: 'id=?', whereArgs: [id]);
  }

  Future<int> deletePet(int id) async {
    final db = await instance.database;
    return await db.delete('pets', where: 'id=?', whereArgs: [id]);
  }

  Future<Map<String, dynamic>?> getPetBySerialNumber(
    String serialNumber,
  ) async {
    final db = await instance.database;
    final res = await db.query(
      'pets',
      where: 'serial_number=?',
      whereArgs: [serialNumber],
    );
    if (res.isNotEmpty) return res.first;
    return null;
  }

  // ---------- APPOINTMENTS ----------
  Future<int> insertAppointment(Map<String, dynamic> data) async {
    final db = await instance.database;
    return await db.insert('appointments', data);
  }

  Future<List<Map<String, dynamic>>> getAppointments({
    int? ownerId,
    int? doctorId,
    int? driverId,
    String? status,
    DateTime? date,
    bool? hasLocation,
  }) async {
    final db = await instance.database;
    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (ownerId != null) {
      whereClause += 'owner_id=?';
      whereArgs.add(ownerId);
    }

    if (doctorId != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'doctor_id=?';
      whereArgs.add(doctorId);
    }

    if (driverId != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'driver_id=?';
      whereArgs.add(driverId);
    }

    if (status != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'status=?';
      whereArgs.add(status);
    }

    if (date != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'DATE(scheduled_at)=?';
      whereArgs.add(date.toIso8601String().split('T')[0]);
    }

    if (hasLocation == true) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += '(location_lat IS NOT NULL AND location_lng IS NOT NULL)';
    }

    // Join with users table to get driver and doctor information
    final query =
        '''
      SELECT
        appointments.*,
        doctor.name as doctor_name,
        doctor.email as doctor_email,
        doctor.phone as doctor_phone,
        driver.name as driver_name,
        driver.email as driver_email,
        driver.phone as driver_phone,
        owner.name as owner_name,
        owner.email as owner_email,
        owner.phone as owner_phone
      FROM appointments
      LEFT JOIN users doctor ON appointments.doctor_id = doctor.id
      LEFT JOIN users driver ON appointments.driver_id = driver.id
      LEFT JOIN users owner ON appointments.owner_id = owner.id
      ${whereClause.isNotEmpty ? 'WHERE $whereClause' : ''}
      ORDER BY appointments.scheduled_at DESC
    ''';

    return await db.rawQuery(query, whereArgs);
  }

  Future<List<Map<String, dynamic>>> getAppointmentsByOwner(int ownerId) async {
    return await getAppointments(ownerId: ownerId);
  }

  Future<int> updateAppointmentStatus(int id, String status) async {
    final db = await instance.database;
    return await db.update(
      'appointments',
      {'status': status},
      where: 'id=?',
      whereArgs: [id],
    );
  }

  Future<int> updateAppointment(int id, Map<String, dynamic> data) async {
    final db = await instance.database;
    return await db.update(
      'appointments',
      data,
      where: 'id=?',
      whereArgs: [id],
    );
  }

  // ---------- SERVICES ----------
  Future<int> insertService(Map<String, dynamic> data) async {
    final db = await instance.database;
    return await db.insert('services', data);
  }

  Future<List<Map<String, dynamic>>> getServices({
    String? category,
    bool? activeOnly,
  }) async {
    final db = await instance.database;
    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (category != null) {
      whereClause += 'category=?';
      whereArgs.add(category);
    }

    if (activeOnly == true) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'is_active=1';
    }

    return await db.query(
      'services',
      where: whereClause.isNotEmpty ? whereClause : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
    );
  }

  Future<int> updateService(int id, Map<String, dynamic> data) async {
    final db = await instance.database;
    return await db.update('services', data, where: 'id=?', whereArgs: [id]);
  }

  Future<int> deleteService(int id) async {
    final db = await instance.database;
    return await db.delete('services', where: 'id=?', whereArgs: [id]);
  }

  // ---------- MEDICAL RECORDS ----------
  Future<int> insertMedicalRecord(Map<String, dynamic> data) async {
    final db = await instance.database;
    return await db.insert('medical_records', data);
  }

  Future<List<Map<String, dynamic>>> getMedicalRecords({
    int? petId,
    int? doctorId,
  }) async {
    final db = await instance.database;
    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (petId != null) {
      whereClause += 'pet_id=?';
      whereArgs.add(petId);
    }

    if (doctorId != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'doctor_id=?';
      whereArgs.add(doctorId);
    }

    return await db.query(
      'medical_records',
      where: whereClause.isNotEmpty ? whereClause : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'date DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getMedicalRecordsByPet(int petId) async {
    return await getMedicalRecords(petId: petId);
  }

  Future<int> updateMedicalRecord(int id, Map<String, dynamic> data) async {
    final db = await instance.database;
    return await db.update(
      'medical_records',
      data,
      where: 'id=?',
      whereArgs: [id],
    );
  }

  Future<int> deleteMedicalRecord(int id) async {
    final db = await instance.database;
    return await db.delete('medical_records', where: 'id=?', whereArgs: [id]);
  }

  // ---------- INVENTORY ----------
  Future<int> insertInventoryItem(Map<String, dynamic> data) async {
    final db = await instance.database;
    return await db.insert('inventory', data);
  }

  Future<List<Map<String, dynamic>>> getLowStockItems() async {
    final db = await instance.database;
    return await db.query('inventory', where: 'quantity <= min_threshold');
  }

  Future<int> updateInventoryQuantity(int id, int newQuantity) async {
    final db = await instance.database;
    return await db.update(
      'inventory',
      {'quantity': newQuantity},
      where: 'id=?',
      whereArgs: [id],
    );
  }

  Future<List<Map<String, dynamic>>> getAllInventoryItems() async {
    final db = await instance.database;
    return await db.query('inventory', orderBy: 'name ASC');
  }

  Future<int> updateInventoryItem(int id, Map<String, dynamic> data) async {
    final db = await instance.database;
    return await db.update('inventory', data, where: 'id=?', whereArgs: [id]);
  }

  Future<int> deleteInventoryItem(int id) async {
    final db = await instance.database;
    return await db.delete('inventory', where: 'id=?', whereArgs: [id]);
  }

  // ---------- NOTIFICATIONS ----------
  Future<int> insertNotification(Map<String, dynamic> data) async {
    final db = await instance.database;
    return await db.insert('notifications', data);
  }

  Future<List<Map<String, dynamic>>> getNotificationsByUser(
    int userId, {
    bool? unreadOnly,
  }) async {
    final db = await instance.database;
    String whereClause = 'user_id=?';
    List<dynamic> whereArgs = [userId];

    if (unreadOnly == true) {
      whereClause += ' AND is_read=0';
    }

    return await db.query(
      'notifications',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'created_at DESC',
    );
  }

  Future<int> markNotificationAsRead(int id) async {
    final db = await instance.database;
    return await db.update(
      'notifications',
      {'is_read': 1},
      where: 'id=?',
      whereArgs: [id],
    );
  }

  Future<int> getUnreadNotificationCount(int userId) async {
    final db = await instance.database;
    final count =
        Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM notifications WHERE user_id = ? AND is_read = 0',
            [userId],
          ),
        ) ??
        0;
    return count;
  }

  // ---------- PAYMENTS ----------
  Future<int> insertPayment(Map<String, dynamic> data) async {
    final db = await instance.database;
    return await db.insert('payments', data);
  }

  Future<List<Map<String, dynamic>>> getPaymentsByAppointment(
    int appointmentId,
  ) async {
    final db = await instance.database;
    return await db.query(
      'payments',
      where: 'appointment_id=?',
      whereArgs: [appointmentId],
      orderBy: 'created_at DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getPaymentsByUser(int userId) async {
    final db = await instance.database;
    return await db.query(
      'payments',
      where: 'user_id=?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );
  }

  Future<Map<String, dynamic>?> getPaymentById(int paymentId) async {
    final db = await instance.database;
    final res = await db.query(
      'payments',
      where: 'id=?',
      whereArgs: [paymentId],
    );
    if (res.isNotEmpty) return res.first;
    return null;
  }

  Future<List<Map<String, dynamic>>> getAllPayments() async {
    final db = await instance.database;
    return await db.query('payments', orderBy: 'created_at DESC');
  }

  Future<int> updatePayment(int id, Map<String, dynamic> data) async {
    final db = await instance.database;
    return await db.update('payments', data, where: 'id=?', whereArgs: [id]);
  }

  // ---------- DOCUMENTS ----------
  Future<int> insertDocument(Map<String, dynamic> data) async {
    final db = await instance.database;
    return await db.insert('documents', data);
  }

  Future<List<Map<String, dynamic>>> getDocumentsByPet(int petId) async {
    final db = await instance.database;
    return await db.query(
      'documents',
      where: 'pet_id=?',
      whereArgs: [petId],
      orderBy: 'upload_date DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getDocumentsByMedicalRecord(
    int medicalRecordId,
  ) async {
    final db = await instance.database;
    return await db.query(
      'documents',
      where: 'medical_record_id=?',
      whereArgs: [medicalRecordId],
      orderBy: 'upload_date DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getDocumentsByOwner(int ownerId) async {
    final db = await instance.database;
    return await db.rawQuery(
      '''
      SELECT d.* FROM documents d
      INNER JOIN pets p ON d.pet_id = p.id
      WHERE p.owner_id = ?
      ORDER BY d.upload_date DESC
      ''',
      [ownerId],
    );
  }

  Future<int> deleteDocument(int id) async {
    final db = await instance.database;
    return await db.delete('documents', where: 'id=?', whereArgs: [id]);
  }

  Future<int> updateDocument(int id, Map<String, dynamic> data) async {
    final db = await instance.database;
    return await db.update('documents', data, where: 'id=?', whereArgs: [id]);
  }

  // ---------- AUDIT LOGS ----------
  Future<int> insertAuditLog(Map<String, dynamic> data) async {
    final db = await instance.database;
    return await db.insert('audit_logs', data);
  }

  Future<List<Map<String, dynamic>>> getAuditLogsByDocument(
    int documentId,
  ) async {
    final db = await instance.database;
    return await db.query(
      'audit_logs',
      where: 'document_id=?',
      whereArgs: [documentId],
      orderBy: 'timestamp DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getAuditLogsByUser(int userId) async {
    final db = await instance.database;
    return await db.query(
      'audit_logs',
      where: 'user_id=?',
      whereArgs: [userId],
      orderBy: 'timestamp DESC',
    );
  }

  // ---------- VACCINATION RECORDS ----------
  Future<int> insertVaccinationRecord(Map<String, dynamic> data) async {
    final db = await instance.database;
    return await db.insert('vaccination_records', data);
  }

  Future<List<Map<String, dynamic>>> getVaccinationRecordsByPet(
    int petId,
  ) async {
    final db = await instance.database;
    return await db.query(
      'vaccination_records',
      where: 'pet_id=?',
      whereArgs: [petId],
      orderBy: 'vaccination_date DESC',
    );
  }

  Future<int> updateVaccinationRecord(int id, Map<String, dynamic> data) async {
    final db = await instance.database;
    return await db.update(
      'vaccination_records',
      data,
      where: 'id=?',
      whereArgs: [id],
    );
  }

  Future<int> deleteVaccinationRecord(int id) async {
    final db = await instance.database;
    return await db.delete(
      'vaccination_records',
      where: 'id=?',
      whereArgs: [id],
    );
  }

  Future<int> deleteAppointmentsWithoutLocation() async {
    final db = await instance.database;
    return await db.delete(
      'appointments',
      where: 'location_lat IS NULL OR location_lng IS NULL',
    );
  }

  // ---------- SERVICE REQUESTS ----------
  Future<int> insertServiceRequest(Map<String, dynamic> data) async {
    final db = await instance.database;
    return await db.insert('service_requests', data);
  }

  Future<List<Map<String, dynamic>>> getServiceRequests({
    int? ownerId,
    String? status,
    String? requestType,
  }) async {
    final db = await instance.database;
    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (ownerId != null) {
      whereClause += 'owner_id=?';
      whereArgs.add(ownerId);
    }

    if (status != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'status=?';
      whereArgs.add(status);
    }

    if (requestType != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'request_type=?';
      whereArgs.add(requestType);
    }

    return await db.query(
      'service_requests',
      where: whereClause.isNotEmpty ? whereClause : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'request_date DESC',
    );
  }

  Future<int> updateServiceRequest(int id, Map<String, dynamic> data) async {
    final db = await instance.database;
    return await db.update(
      'service_requests',
      data,
      where: 'id=?',
      whereArgs: [id],
    );
  }

  Future _createNewTablesV5(Database db) async {
    // Doctors table with service assignment
    await db.execute('''
      CREATE TABLE IF NOT EXISTS doctors (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER UNIQUE,
        assigned_service_id INTEGER,
        license_number TEXT,
        specialization TEXT,
        experience_years INTEGER,
        is_available INTEGER DEFAULT 1,
        created_at TEXT,
        FOREIGN KEY (user_id) REFERENCES users (id),
        FOREIGN KEY (assigned_service_id) REFERENCES services (id)
      );
    ''');
  }

  // ---------- REPORTING / KPIs ----------
  Future<Map<String, int>> getAppointmentKpis({
    required DateTime start,
    required DateTime end,
  }) async {
    final db = await instance.database;
    final startIso = start.toIso8601String();
    final endIso = end.toIso8601String();

    // Total
    final total =
        Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM appointments WHERE scheduled_at BETWEEN ? AND ?',
            [startIso, endIso],
          ),
        ) ??
        0;

    // Completed
    final completed =
        Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM appointments WHERE status = ? AND scheduled_at BETWEEN ? AND ?',
            ['completed', startIso, endIso],
          ),
        ) ??
        0;

    // Canceled
    final canceled =
        Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM appointments WHERE status = ? AND scheduled_at BETWEEN ? AND ?',
            ['canceled', startIso, endIso],
          ),
        ) ??
        0;

    // Emergency vs Routine
    final emergency =
        Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM appointments WHERE urgency_level = ? AND scheduled_at BETWEEN ? AND ?',
            ['emergency', startIso, endIso],
          ),
        ) ??
        0;

    final routine =
        Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM appointments WHERE urgency_level = ? AND scheduled_at BETWEEN ? AND ?',
            ['routine', startIso, endIso],
          ),
        ) ??
        0;

    return {
      'total': total,
      'completed': completed,
      'canceled': canceled,
      'emergency': emergency,
      'routine': routine,
    };
  }

  Future<double> getRevenueByDateRange(DateTime start, DateTime end) async {
    final db = await instance.database;
    final startIso = start.toIso8601String();
    final endIso = end.toIso8601String();

    final res = await db.rawQuery(
      "SELECT SUM(amount) as sum_amount "
      "FROM payments "
      "WHERE created_at BETWEEN ? AND ? "
      "AND status IN ('completed','refunded')",
      [startIso, endIso],
    );
    final sum = (res.isNotEmpty ? res.first['sum_amount'] : null);
    if (sum == null) return 0.0;
    if (sum is int) return sum.toDouble();
    if (sum is double) return sum;
    if (sum is num) return sum.toDouble();
    return 0.0;
  }

  Future<List<Map<String, dynamic>>> getDailyAppointmentCounts({
    required DateTime start,
    required DateTime end,
  }) async {
    final db = await instance.database;
    final startIso = start.toIso8601String();
    final endIso = end.toIso8601String();
    return await db.rawQuery(
      "SELECT date(scheduled_at) AS day, COUNT(*) AS count "
      "FROM appointments "
      "WHERE scheduled_at BETWEEN ? AND ? "
      "GROUP BY day "
      "ORDER BY day ASC",
      [startIso, endIso],
    );
  }

  // ---------- DOCTORS ----------
  Future<int> insertDoctor(Map<String, dynamic> data) async {
    final db = await instance.database;
    return await db.insert('doctors', data);
  }

  Future<List<Map<String, dynamic>>> getDoctors() async {
    final db = await instance.database;
    return await db.query('doctors');
  }

  Future<List<Map<String, dynamic>>> getDoctorsByService(int serviceId) async {
    final db = await instance.database;
    return await db.query(
      'doctors',
      where: 'assigned_service_id = ? AND is_available = 1',
      whereArgs: [serviceId],
    );
  }

  Future<Map<String, dynamic>?> getDoctorByUserId(int userId) async {
    final db = await instance.database;
    final res = await db.query(
      'doctors',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    if (res.isNotEmpty) return res.first;
    return null;
  }

  Future<int> updateDoctor(int id, Map<String, dynamic> data) async {
    final db = await instance.database;
    return await db.update('doctors', data, where: 'id=?', whereArgs: [id]);
  }

  Future<int> deleteDoctor(int id) async {
    final db = await instance.database;
    return await db.delete('doctors', where: 'id=?', whereArgs: [id]);
  }

  // ---------- USERS ----------
  Future<Map<String, dynamic>?> getUserById(int id) async {
    final db = await instance.database;
    final res = await db.query('users', where: 'id=?', whereArgs: [id]);
    if (res.isNotEmpty) return res.first;
    return null;
  }

  Future<String> getUserNameById(int id) async {
    final user = await getUserById(id);
    return user?['name'] as String? ?? 'Unknown User';
  }

  // ---------- DRIVER STATUS ----------
  Future<int> insertDriverStatus(Map<String, dynamic> data) async {
    final db = await instance.database;
    return await db.insert('driver_status', data);
  }

  Future<Map<String, dynamic>?> getDriverStatus(int driverId) async {
    final db = await instance.database;
    final res = await db.query(
      'driver_status',
      where: 'driver_id = ?',
      whereArgs: [driverId],
      orderBy: 'last_updated DESC',
      limit: 1,
    );
    if (res.isNotEmpty) return res.first;
    return null;
  }

  Future<List<Map<String, dynamic>>> getAllDriverStatuses() async {
    final db = await instance.database;
    return await db.query('driver_status', orderBy: 'last_updated DESC');
  }

  Future<List<Map<String, dynamic>>> getLinkedDriverStatuses() async {
    final db = await instance.database;
    // Get driver statuses for drivers that are linked to doctors
    return await db.rawQuery('''
      SELECT ds.* FROM driver_status ds
      INNER JOIN users u ON ds.driver_id = u.id
      WHERE u.linked_doctor_id IS NOT NULL
      ORDER BY ds.last_updated DESC
    ''');
  }

  // ---------- VANS ----------
  Future<int> insertVan(Map<String, dynamic> data) async {
    final db = await instance.database;
    return await db.insert('vans', data);
  }

  Future<List<Map<String, dynamic>>> getAllVans() async {
    final db = await instance.database;
    return await db.query('vans', orderBy: 'name ASC');
  }

  Future<Map<String, dynamic>?> getVanById(int id) async {
    final db = await instance.database;
    final res = await db.query('vans', where: 'id=?', whereArgs: [id]);
    if (res.isNotEmpty) return res.first;
    return null;
  }

  Future<Map<String, dynamic>?> getVanByDriverId(int driverId) async {
    final db = await instance.database;
    final res = await db.query(
      'vans',
      where: 'assigned_driver_id=?',
      whereArgs: [driverId],
    );
    if (res.isNotEmpty) return res.first;
    return null;
  }

  Future<Map<String, dynamic>?> getVanByDoctorId(int doctorId) async {
    final db = await instance.database;
    final res = await db.query(
      'vans',
      where: 'assigned_doctor_id=?',
      whereArgs: [doctorId],
    );
    if (res.isNotEmpty) return res.first;
    return null;
  }

  Future<int> updateVan(int id, Map<String, dynamic> data) async {
    final db = await instance.database;
    return await db.update('vans', data, where: 'id=?', whereArgs: [id]);
  }

  Future<int> deleteVan(int id) async {
    final db = await instance.database;
    return await db.delete('vans', where: 'id=?', whereArgs: [id]);
  }

  // ---------- COMPLIANCE LOGS ----------
  Future<int> insertComplianceLog(Map<String, dynamic> data) async {
    final db = await instance.database;
    return await db.insert('compliance_logs', data);
  }

  Future<List<Map<String, dynamic>>> getAllComplianceLogs() async {
    final db = await instance.database;
    return await db.query('compliance_logs', orderBy: 'inspection_date DESC');
  }

  Future<int> updateComplianceLog(int id, Map<String, dynamic> data) async {
    final db = await instance.database;
    return await db.update(
      'compliance_logs',
      data,
      where: 'id=?',
      whereArgs: [id],
    );
  }

  Future<int> deleteComplianceLog(int id) async {
    final db = await instance.database;
    return await db.delete('compliance_logs', where: 'id=?', whereArgs: [id]);
  }

  // ---------- DATA EXPORT/IMPORT ----------
  Future<Map<String, dynamic>> exportData() async {
    final db = await instance.database;
    final data = <String, dynamic>{};

    // Get all existing tables
    final tablesResult = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'",
    );
    final existingTables = tablesResult
        .map((row) => row['name'] as String)
        .toList();

    for (final table in existingTables) {
      try {
        final rows = await db.query(table);
        data[table] = rows;
      } catch (e) {
        debugPrint('Error exporting table $table: $e');
      }
    }

    return data;
  }

  Future<void> importData(Map<String, dynamic> data) async {
    final db = await instance.database;

    // Clear all tables in reverse order to handle foreign keys
    final tables = [
      'audit_logs',
      'compliance_logs',
      'vehicle_checks',
      'routes',
      'service_requests',
      'vaccination_records',
      'documents',
      'driver_status',
      'payments',
      'notifications',
      'inventory',
      'medical_records',
      'services',
      'appointments',
      'pets',
      'doctors',
      'users',
    ];

    for (final table in tables) {
      await db.delete(table);
    }

    // Import data in correct order
    final importOrder = [
      'users',
      'doctors',
      'pets',
      'appointments',
      'services',
      'medical_records',
      'inventory',
      'notifications',
      'payments',
      'driver_status',
      'documents',
      'audit_logs',
      'vaccination_records',
      'service_requests',
      'routes',
      'vehicle_checks',
      'compliance_logs',
    ];

    for (final table in importOrder) {
      if (data.containsKey(table)) {
        final rows = data[table] as List<dynamic>;
        for (final row in rows) {
          try {
            await db.insert(
              table,
              row as Map<String, dynamic>,
              conflictAlgorithm: ConflictAlgorithm.ignore,
            );
          } catch (e) {
            debugPrint('Error importing row into $table: $e');
          }
        }
      }
    }
  }
}
