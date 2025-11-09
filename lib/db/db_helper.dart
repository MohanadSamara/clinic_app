// lib/db/db_helper.dart
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:sqflite/sqflite.dart';

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
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(
      path,
      version: 6,
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
        role TEXT NOT NULL DEFAULT 'owner'
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
        photo_path TEXT
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
        urgency_level TEXT,
        location_lat REAL,
        location_lng REAL
      );
    ''');

    // Services table
    await db.execute('''
      CREATE TABLE services (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        description TEXT,
        price REAL,
        category TEXT,
        is_active INTEGER
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
        amount REAL,
        method TEXT,
        status TEXT,
        transaction_id TEXT,
        created_at TEXT
      );
    ''');

    // Create new tables for version 3
    await _createNewTablesV3(db);

    // Create new tables for version 5
    await _createNewTablesV5(db);

    // Insert default services after creating tables
    await _insertDefaultServices(db);
  }

  Future _createNewTablesV3(Database db) async {
    // Documents table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS documents (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        pet_id INTEGER,
        file_name TEXT,
        file_type TEXT,
        file_path TEXT,
        description TEXT,
        upload_date TEXT
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

    // Insert sample users and appointments for testing
    await _insertSampleData(db);
  }

  Future _insertSampleData(Database db) async {
    try {
      // Insert sample users
      final users = [
        {
          'name': 'Dr. Ahmed Hassan',
          'email': 'doctor@example.com',
          'password': '123456',
          'phone': '+96212345678',
          'role': 'doctor',
        },
        {
          'name': 'John Smith',
          'email': 'owner@example.com',
          'password': '123456',
          'phone': '+96287654321',
          'role': 'owner',
        },
      ];

      for (final user in users) {
        await db.insert(
          'users',
          user,
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }

      // Get user IDs
      final doctorResult = await db.query(
        'users',
        where: 'email=?',
        whereArgs: ['doctor@example.com'],
      );
      final ownerResult = await db.query(
        'users',
        where: 'email=?',
        whereArgs: ['owner@example.com'],
      );

      if (doctorResult.isNotEmpty && ownerResult.isNotEmpty) {
        final doctorId = doctorResult.first['id'];
        final ownerId = ownerResult.first['id'];

        // Insert sample pet
        final petId = await db.insert('pets', {
          'owner_id': ownerId,
          'name': 'Max',
          'species': 'Dog',
          'breed': 'Golden Retriever',
          'dob': '2020-05-15',
          'notes': 'Friendly and energetic',
        });

        // Insert sample appointments assigned to doctor
        final appointments = [
          {
            'owner_id': ownerId,
            'pet_id': petId,
            'doctor_id': doctorId,
            'service_type': 'Checkup',
            'description': 'Regular health checkup',
            'scheduled_at': DateTime.now()
                .add(const Duration(days: 1))
                .toIso8601String(),
            'status': 'confirmed',
            'address': '123 Main St, Amman',
            'price': 30.0,
            'urgency_level': 'routine',
          },
          {
            'owner_id': ownerId,
            'pet_id': petId,
            'doctor_id': doctorId,
            'service_type': 'Vaccination',
            'description': 'Annual vaccination',
            'scheduled_at': DateTime.now()
                .add(const Duration(days: 2))
                .toIso8601String(),
            'status': 'pending',
            'address': '123 Main St, Amman',
            'price': 50.0,
            'urgency_level': 'routine',
          },
          {
            'owner_id': ownerId,
            'pet_id': petId,
            'doctor_id': doctorId,
            'service_type': 'Dental Care',
            'description': 'Teeth cleaning',
            'scheduled_at': DateTime.now()
                .subtract(const Duration(days: 1))
                .toIso8601String(),
            'status': 'completed',
            'address': '123 Main St, Amman',
            'price': 80.0,
            'urgency_level': 'routine',
          },
        ];

        for (final appointment in appointments) {
          await db.insert(
            'appointments',
            appointment,
            conflictAlgorithm: ConflictAlgorithm.ignore,
          );
        }

        // Insert sample doctor record for all services
        final services = await db.query('services');
        for (final service in services) {
          final serviceId = service['id'];
          await db.insert('doctors', {
            'user_id': doctorId,
            'assigned_service_id': serviceId,
            'license_number': 'DOC123456',
            'specialization': 'General Veterinary',
            'experience_years': 5,
            'is_available': 1,
            'created_at': DateTime.now().toIso8601String(),
          }, conflictAlgorithm: ConflictAlgorithm.ignore);
        }
      }
    } catch (e) {
      debugPrint('Error inserting sample data: $e');
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

  // ---------- APPOINTMENTS ----------
  Future<int> insertAppointment(Map<String, dynamic> data) async {
    final db = await instance.database;
    return await db.insert('appointments', data);
  }

  Future<List<Map<String, dynamic>>> getAppointments({
    int? ownerId,
    int? doctorId,
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

    // Join with users table to get driver information
    final query =
        '''
      SELECT
        appointments.*,
        doctor.name as doctor_name,
        doctor.email as doctor_email,
        doctor.phone as doctor_phone,
        owner.name as owner_name,
        owner.email as owner_email,
        owner.phone as owner_phone
      FROM appointments
      LEFT JOIN users doctor ON appointments.doctor_id = doctor.id
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

  Future<int> deleteDocument(int id) async {
    final db = await instance.database;
    return await db.delete('documents', where: 'id=?', whereArgs: [id]);
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
}
