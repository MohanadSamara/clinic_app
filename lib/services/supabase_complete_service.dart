// lib/services/supabase_complete_service.dart
// Complete Supabase Service - Single Source of Truth
// Replaces ALL Firestore and SQLite operations
// All app data stored in Supabase - UUID-based IDs

import 'package:supabase_flutter/supabase_flutter.dart';
import '../supabase_options.dart';

/// Complete Supabase Service - Single Source of Truth
/// Replaces ALL Firestore (firestore_complete_service.dart) and SQLite (db_helper.dart) operations
class SupabaseCompleteService {
  // Singleton
  static final SupabaseCompleteService instance =
      SupabaseCompleteService._init();
  SupabaseCompleteService._init();

  // Supabase client
  final SupabaseClient _client = SupabaseClient(
    SupabaseOptions.projectUrl,
    SupabaseOptions.anonKey,
  );

  SupabaseClient get client => _client;

  // ========== AUTH HELPERS ==========

  String? get currentUserId => _client.auth.currentUser?.id;
  String? get currentUserEmail => _client.auth.currentUser?.email;
  User? get currentUser => _client.auth.currentUser;
  bool get isAuthenticated => _client.auth.currentUser != null;

  // ========== TABLE REFERENCES ==========

  SupabaseQueryBuilder get usersTable => _client.from('users');
  SupabaseQueryBuilder get petsTable => _client.from('pets');
  SupabaseQueryBuilder get appointmentsTable => _client.from('appointments');
  SupabaseQueryBuilder get servicesTable => _client.from('services');
  SupabaseQueryBuilder get medicalRecordsTable =>
      _client.from('medical_records');
  SupabaseQueryBuilder get inventoryTable => _client.from('inventory');
  SupabaseQueryBuilder get notificationsTable => _client.from('notifications');
  SupabaseQueryBuilder get paymentsTable => _client.from('payments');
  SupabaseQueryBuilder get vansTable => _client.from('vans');
  SupabaseQueryBuilder get driverStatusTable => _client.from('driver_status');
  SupabaseQueryBuilder get routesTable => _client.from('routes');
  SupabaseQueryBuilder get vehicleChecksTable => _client.from('vehicle_checks');
  SupabaseQueryBuilder get schedulesTable => _client.from('schedules');
  SupabaseQueryBuilder get doctorVerificationDocumentsTable =>
      _client.from('doctor_verification_documents');
  SupabaseQueryBuilder get driverVerificationDocumentsTable =>
      _client.from('driver_verification_documents');
  SupabaseQueryBuilder get driverVerificationAuditLogsTable =>
      _client.from('driver_verification_audit_logs');
  SupabaseQueryBuilder get documentsTable => _client.from('documents');
  SupabaseQueryBuilder get auditLogsTable => _client.from('audit_logs');
  SupabaseQueryBuilder get vaccinationRecordsTable =>
      _client.from('vaccination_records');
  SupabaseQueryBuilder get serviceRequestsTable =>
      _client.from('service_requests');
  SupabaseQueryBuilder get complianceLogsTable =>
      _client.from('compliance_logs');
  SupabaseQueryBuilder get systemSettingsTable =>
      _client.from('system_settings');
  SupabaseQueryBuilder get pagesTable => _client.from('pages');
  SupabaseQueryBuilder get doctorsTable => _client.from('doctors');

  // ========== HELPER METHODS ==========

  static String getEmailKey(String email) {
    return email.toLowerCase().replaceAll('.', '_');
  }

  static String formatTimestamp(DateTime dateTime) {
    return dateTime.toIso8601String();
  }

  /// Parse UUID from various formats (int, String, UUID)
  static String parseId(dynamic id) {
    if (id == null) return '';
    if (id is String) return id;
    if (id is int) return id.toString();
    return id.toString();
  }

  /// Convert int to UUID (for legacy data migration)
  static String intToUuid(int id) {
    // Generate a deterministic UUID from int
    final hex = id.toRadixString(16).padLeft(32, '0');
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20, 32)}';
  }

  // ========== USERS ==========

  Future<String> insertUser(Map<String, dynamic> data) async {
    final response = await usersTable.insert(data).select().single();
    return response['id'] as String;
  }

  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    final response = await usersTable
        .select()
        .eq('email', email.toLowerCase())
        .maybeSingle();
    return response;
  }

  Future<Map<String, dynamic>?> getUserByEmailAndPassword(
    String email,
    String password,
  ) async {
    final response = await usersTable
        .select()
        .eq('email', email.toLowerCase())
        .eq('password', password)
        .maybeSingle();
    return response;
  }

  Future<List<Map<String, dynamic>>> getAllUsers({String? role}) async {
    dynamic query = usersTable.select();
    if (role != null) {
      query = query.eq('role', role);
    }
    query = query.order('name');
    final response = await query;
    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>?> getUserById(String id) async {
    final response = await usersTable.select().eq('id', id).maybeSingle();
    return response;
  }

  Future<void> updateUser(String id, Map<String, dynamic> data) async {
    await usersTable.update(data).eq('id', id);
  }

  Future<void> deleteUser(String id) async {
    await usersTable.delete().eq('id', id);
  }

  Future<String> getUserNameById(String id) async {
    final user = await getUserById(id);
    return user?['name'] as String? ?? 'Unknown User';
  }

  // ========== PETS ==========

  Future<String> insertPet(Map<String, dynamic> data) async {
    final response = await petsTable.insert(data).select().single();
    return response['id'] as String;
  }

  Future<List<Map<String, dynamic>>> getPetsByOwner(String ownerId) async {
    final response = await petsTable
        .select()
        .eq('owner_id', ownerId)
        .order('name');
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getPetsByDoctor(String doctorId) async {
    final recordsResponse = await medicalRecordsTable.select().eq(
      'doctor_id',
      doctorId,
    );
    final petIds = (recordsResponse as List)
        .map((doc) => doc['pet_id'])
        .toSet()
        .toList();

    if (petIds.isEmpty) return [];

    final response = await petsTable.select();
    final allPets = List<Map<String, dynamic>>.from(response);

    return allPets.where((pet) => petIds.contains(pet['id'])).toList()
      ..sort((a, b) => (a['name'] ?? '').compareTo(b['name'] ?? ''));
  }

  Future<List<Map<String, dynamic>>> getPetsByLinkedDoctor(
    String doctorId,
  ) async {
    final usersResponse = await usersTable.select().eq(
      'linked_doctor_id',
      doctorId,
    );
    final ownerIds = (usersResponse as List).map((doc) => doc['id']).toList();

    if (ownerIds.isEmpty) return [];

    final response = await petsTable.select();
    final allPets = List<Map<String, dynamic>>.from(response);

    return allPets.where((pet) => ownerIds.contains(pet['owner_id'])).toList()
      ..sort((a, b) => (a['name'] ?? '').compareTo(b['name'] ?? ''));
  }

  Future<Map<String, dynamic>?> getPetById(String id) async {
    final response = await petsTable.select().eq('id', id).maybeSingle();
    return response;
  }

  Future<void> updatePet(String id, Map<String, dynamic> data) async {
    await petsTable.update(data).eq('id', id);
  }

  Future<void> deletePet(String id) async {
    await petsTable.delete().eq('id', id);
  }

  Future<Map<String, dynamic>?> getPetBySerialNumber(
    String serialNumber,
  ) async {
    final response = await petsTable
        .select()
        .eq('serial_number', serialNumber)
        .maybeSingle();
    return response;
  }

  // ========== APPOINTMENTS ==========

  Future<String> insertAppointment(Map<String, dynamic> data) async {
    final response = await appointmentsTable.insert(data).select().single();
    return response['id'] as String;
  }

  Future<List<Map<String, dynamic>>> getAppointments({
    String? ownerId,
    String? doctorId,
    String? driverId,
    String? status,
    DateTime? date,
    bool? hasLocation,
  }) async {
    dynamic query = appointmentsTable.select();

    if (ownerId != null) {
      query = query.eq('owner_id', ownerId);
    } else if (doctorId != null) {
      query = query.eq('doctor_id', doctorId);
    } else if (driverId != null) {
      query = query.eq('driver_id', driverId);
    } else if (status != null) {
      query = query.eq('status', status);
    }

    query = query.order('scheduled_at', ascending: false);
    final response = await query;
    List<Map<String, dynamic>> results = List<Map<String, dynamic>>.from(
      response,
    );

    // Filter by date if needed
    if (date != null) {
      final dateStr = date.toIso8601String().split('T')[0];
      results = results
          .where(
            (a) => (a['scheduled_at'] as String?)?.startsWith(dateStr) ?? false,
          )
          .toList();
    }

    // Filter by location if needed
    if (hasLocation == true) {
      results = results
          .where((a) => a['location_lat'] != null && a['location_lng'] != null)
          .toList();
    }

    // Fetch services and associate with appointments
    final servicesResponse = await servicesTable.select();
    final services = List<Map<String, dynamic>>.from(servicesResponse);
    final serviceMap = {
      for (final service in services) service['name']: service,
    };

    // Add service data to each appointment
    for (final appointment in results) {
      final serviceType = appointment['service_type'] as String?;
      if (serviceType != null && serviceMap.containsKey(serviceType)) {
        appointment['service'] = serviceMap[serviceType];
      }
    }

    return results;
  }

  Future<Map<String, dynamic>?> getAppointmentById(String id) async {
    final response = await appointmentsTable
        .select()
        .eq('id', id)
        .maybeSingle();
    return response;
  }

  Future<void> updateAppointmentStatus(String id, String status) async {
    await appointmentsTable
        .update({
          'status': status,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', id);
  }

  Future<void> updateAppointment(String id, Map<String, dynamic> data) async {
    await appointmentsTable.update(data).eq('id', id);
  }

  // ========== SERVICES ==========

  Future<String> insertService(Map<String, dynamic> data) async {
    final response = await servicesTable.insert(data).select().single();
    return response['id'] as String;
  }

  Future<List<Map<String, dynamic>>> getServices({
    String? category,
    bool? activeOnly,
  }) async {
    dynamic query = servicesTable.select();

    if (category != null) {
      query = query.eq('category', category);
    }

    query = query.order('name');
    final response = await query;
    List<Map<String, dynamic>> results = List<Map<String, dynamic>>.from(
      response,
    );

    if (activeOnly == true) {
      results = results.where((s) => s['is_active'] == true).toList();
    }

    return results;
  }

  Future<void> updateService(String id, Map<String, dynamic> data) async {
    await servicesTable.update(data).eq('id', id);
  }

  Future<void> deleteService(String id) async {
    await servicesTable.delete().eq('id', id);
  }

  // ========== MEDICAL RECORDS ==========

  Future<String> insertMedicalRecord(Map<String, dynamic> data) async {
    final response = await medicalRecordsTable.insert(data).select().single();
    return response['id'] as String;
  }

  Future<List<Map<String, dynamic>>> getMedicalRecords({
    String? petId,
    String? doctorId,
  }) async {
    dynamic query = medicalRecordsTable.select();

    if (petId != null && doctorId != null) {
      query = query.eq('pet_id', petId).eq('doctor_id', doctorId);
    } else if (petId != null) {
      query = query.eq('pet_id', petId);
    } else if (doctorId != null) {
      query = query.eq('doctor_id', doctorId);
    }

    query = query.order('date', ascending: false);
    final response = await query;
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> updateMedicalRecord(String id, Map<String, dynamic> data) async {
    await medicalRecordsTable.update(data).eq('id', id);
  }

  Future<void> deleteMedicalRecord(String id) async {
    await medicalRecordsTable.delete().eq('id', id);
  }

  // ========== INVENTORY ==========

  Future<String> insertInventoryItem(Map<String, dynamic> data) async {
    final response = await inventoryTable.insert(data).select().single();
    return response['id'] as String;
  }

  Future<List<Map<String, dynamic>>> getLowStockItems() async {
    final response = await inventoryTable.select();
    final items = List<Map<String, dynamic>>.from(response);
    return items
        .where(
          (item) => (item['quantity'] ?? 0) <= (item['min_threshold'] ?? 0),
        )
        .toList();
  }

  Future<void> updateInventoryQuantity(String id, int newQuantity) async {
    await inventoryTable.update({'quantity': newQuantity}).eq('id', id);
  }

  Future<List<Map<String, dynamic>>> getAllInventoryItems() async {
    final response = await inventoryTable.select().order('name');
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> updateInventoryItem(String id, Map<String, dynamic> data) async {
    await inventoryTable.update(data).eq('id', id);
  }

  Future<void> deleteInventoryItem(String id) async {
    await inventoryTable.delete().eq('id', id);
  }

  // ========== NOTIFICATIONS ==========

  Future<String> insertNotification(Map<String, dynamic> data) async {
    final response = await notificationsTable.insert(data).select().single();
    return response['id'] as String;
  }

  Future<List<Map<String, dynamic>>> getNotificationsByUser(
    String userId, {
    bool? unreadOnly,
  }) async {
    dynamic query = notificationsTable.select().eq('user_id', userId);

    if (unreadOnly == true) {
      query = query.eq('is_read', false);
    }

    query = query.order('created_at', ascending: false);
    final response = await query;
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> markNotificationAsRead(String id) async {
    await notificationsTable.update({'is_read': true}).eq('id', id);
  }

  Future<int> getUnreadNotificationCount(String userId) async {
    final response = await notificationsTable
        .select('id')
        .eq('user_id', userId)
        .eq('is_read', false);
    return (response as List).length;
  }

  // ========== PAYMENTS ==========

  Future<String> insertPayment(Map<String, dynamic> data) async {
    final response = await paymentsTable.insert(data).select().single();
    return response['id'] as String;
  }

  Future<List<Map<String, dynamic>>> getPaymentsByAppointment(
    String appointmentId,
  ) async {
    final response = await paymentsTable
        .select()
        .eq('appointment_id', appointmentId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getPaymentsByUser(String userId) async {
    final response = await paymentsTable
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>?> getPaymentById(String paymentId) async {
    final response = await paymentsTable
        .select()
        .eq('id', paymentId)
        .maybeSingle();
    return response;
  }

  Future<List<Map<String, dynamic>>> getAllPayments() async {
    final response = await paymentsTable.select().order(
      'created_at',
      ascending: false,
    );
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> updatePayment(String id, Map<String, dynamic> data) async {
    await paymentsTable.update(data).eq('id', id);
  }

  // ========== DOCUMENTS ==========

  Future<String> insertDocument(Map<String, dynamic> data) async {
    final response = await documentsTable.insert(data).select().single();
    return response['id'] as String;
  }

  Future<List<Map<String, dynamic>>> getDocumentsByPet(String petId) async {
    final response = await documentsTable
        .select()
        .eq('pet_id', petId)
        .order('upload_date', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getDocumentsByMedicalRecord(
    String medicalRecordId,
  ) async {
    final response = await documentsTable
        .select()
        .eq('medical_record_id', medicalRecordId)
        .order('upload_date', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getDocumentsByOwner(String ownerId) async {
    final pets = await getPetsByOwner(ownerId);
    final petIds = pets.map((p) => p['id']).toList();

    if (petIds.isEmpty) return [];

    final response = await documentsTable.select();
    final allDocs = List<Map<String, dynamic>>.from(response);

    return allDocs.where((doc) => petIds.contains(doc['pet_id'])).toList()
      ..sort(
        (a, b) => (b['upload_date'] ?? '').compareTo(a['upload_date'] ?? ''),
      );
  }

  Future<void> deleteDocument(String id) async {
    await documentsTable.delete().eq('id', id);
  }

  Future<void> updateDocument(String id, Map<String, dynamic> data) async {
    await documentsTable.update(data).eq('id', id);
  }

  // ========== AUDIT LOGS ==========

  Future<String> insertAuditLog(Map<String, dynamic> data) async {
    final response = await auditLogsTable.insert(data).select().single();
    return response['id'] as String;
  }

  Future<List<Map<String, dynamic>>> getAuditLogsByDocument(
    String documentId,
  ) async {
    final response = await auditLogsTable
        .select()
        .eq('document_id', documentId)
        .order('timestamp', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getAuditLogsByUser(String userId) async {
    final response = await auditLogsTable
        .select()
        .eq('user_id', userId)
        .order('timestamp', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getAuditLogs({int limit = 100}) async {
    final response = await auditLogsTable
        .select()
        .order('timestamp', ascending: false)
        .limit(limit);
    return List<Map<String, dynamic>>.from(response);
  }

  // ========== VACCINATION RECORDS ==========

  Future<String> insertVaccinationRecord(Map<String, dynamic> data) async {
    final response = await vaccinationRecordsTable
        .insert(data)
        .select()
        .single();
    return response['id'] as String;
  }

  Future<List<Map<String, dynamic>>> getVaccinationRecordsByPet(
    String petId,
  ) async {
    final response = await vaccinationRecordsTable
        .select()
        .eq('pet_id', petId)
        .order('vaccination_date', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> updateVaccinationRecord(
    String id,
    Map<String, dynamic> data,
  ) async {
    await vaccinationRecordsTable.update(data).eq('id', id);
  }

  Future<void> deleteVaccinationRecord(String id) async {
    await vaccinationRecordsTable.delete().eq('id', id);
  }

  // ========== SERVICE REQUESTS ==========

  Future<String> insertServiceRequest(Map<String, dynamic> data) async {
    final response = await serviceRequestsTable.insert(data).select().single();
    return response['id'] as String;
  }

  Future<List<Map<String, dynamic>>> getServiceRequests({
    String? ownerId,
    String? assignedDoctorId,
    String? status,
    String? requestType,
  }) async {
    dynamic query = serviceRequestsTable.select();

    if (ownerId != null) {
      query = query.eq('owner_id', ownerId);
    } else if (assignedDoctorId != null) {
      query = query.eq('assigned_doctor_id', assignedDoctorId);
    } else if (status != null) {
      query = query.eq('status', status);
    }

    query = query.order('request_date', ascending: false);
    final response = await query;
    List<Map<String, dynamic>> results = List<Map<String, dynamic>>.from(
      response,
    );

    if (requestType != null) {
      results = results.where((r) => r['request_type'] == requestType).toList();
    }

    return results;
  }

  Future<void> updateServiceRequest(
    String id,
    Map<String, dynamic> data,
  ) async {
    await serviceRequestsTable.update(data).eq('id', id);
  }

  // ========== VANS ==========

  Future<String> insertVan(Map<String, dynamic> data) async {
    final response = await vansTable.insert(data).select().single();
    return response['id'] as String;
  }

  Future<List<Map<String, dynamic>>> getAllVans() async {
    final response = await vansTable.select().order('name');
    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>?> getVanById(String id) async {
    final response = await vansTable.select().eq('id', id).maybeSingle();
    return response;
  }

  Future<Map<String, dynamic>?> getVanByDriverId(String driverId) async {
    final response = await vansTable
        .select()
        .eq('assigned_driver_id', driverId)
        .maybeSingle();
    return response;
  }

  Future<Map<String, dynamic>?> getVanByDoctorId(String doctorId) async {
    final response = await vansTable
        .select()
        .eq('assigned_doctor_id', doctorId)
        .maybeSingle();
    return response;
  }

  Future<void> updateVan(String id, Map<String, dynamic> data) async {
    await vansTable.update(data).eq('id', id);
  }

  Future<void> deleteVan(String id) async {
    await vansTable.delete().eq('id', id);
  }

  // ========== DRIVER STATUS ==========

  Future<String> insertDriverStatus(Map<String, dynamic> data) async {
    final response = await driverStatusTable.insert(data).select().single();
    return response['id'] as String;
  }

  Future<Map<String, dynamic>?> getDriverStatus(String driverId) async {
    final response = await driverStatusTable
        .select()
        .eq('driver_id', driverId)
        .order('last_updated', ascending: false)
        .limit(1)
        .maybeSingle();
    return response;
  }

  Future<List<Map<String, dynamic>>> getAllDriverStatuses() async {
    final response = await driverStatusTable.select().order(
      'last_updated',
      ascending: false,
    );
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getLinkedDriverStatuses() async {
    final usersResponse = await usersTable.select().not(
      'linked_doctor_id',
      'is',
      null,
    );
    final driverIds = (usersResponse as List).map((doc) => doc['id']).toList();

    if (driverIds.isEmpty) return [];

    final response = await driverStatusTable.select();
    final allStatuses = List<Map<String, dynamic>>.from(response);

    return allStatuses
        .where((status) => driverIds.contains(status['driver_id']))
        .toList()
      ..sort(
        (a, b) => (b['last_updated'] ?? '').compareTo(a['last_updated'] ?? ''),
      );
  }

  // ========== COMPLIANCE LOGS ==========

  Future<String> insertComplianceLog(Map<String, dynamic> data) async {
    final response = await complianceLogsTable.insert(data).select().single();
    return response['id'] as String;
  }

  Future<List<Map<String, dynamic>>> getAllComplianceLogs() async {
    final response = await complianceLogsTable.select().order(
      'inspection_date',
      ascending: false,
    );
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> updateComplianceLog(String id, Map<String, dynamic> data) async {
    await complianceLogsTable.update(data).eq('id', id);
  }

  Future<void> deleteComplianceLog(String id) async {
    await complianceLogsTable.delete().eq('id', id);
  }

  // ========== SCHEDULES ==========

  Future<String> insertSchedule(Map<String, dynamic> data) async {
    final response = await schedulesTable.insert(data).select().single();
    return response['id'] as String;
  }

  Future<List<Map<String, dynamic>>> getSchedulesByDoctor(
    String doctorId,
  ) async {
    final response = await schedulesTable
        .select()
        .eq('doctor_id', doctorId)
        .order('day_of_week');
    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>?> getScheduleById(String id) async {
    final response = await schedulesTable.select().eq('id', id).maybeSingle();
    return response;
  }

  Future<void> updateSchedule(String id, Map<String, dynamic> data) async {
    await schedulesTable.update(data).eq('id', id);
  }

  Future<void> deleteSchedule(String id) async {
    await schedulesTable.delete().eq('id', id);
  }

  Future<void> deleteSchedulesByDoctor(String doctorId) async {
    await schedulesTable.delete().eq('doctor_id', doctorId);
  }

  // ========== SYSTEM SETTINGS ==========

  Future<Map<String, dynamic>> getSystemSettings() async {
    final response = await systemSettingsTable.select();
    final result = <String, dynamic>{};
    for (final doc in response as List) {
      result[doc['key'] as String] = doc['value'];
    }
    return result;
  }

  Future<void> updateSystemSetting(String key, dynamic value) async {
    await systemSettingsTable.upsert({
      'key': key,
      'value': value.toString(),
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  // ========== PAGES ==========

  Future<String> insertPage(Map<String, dynamic> data) async {
    final response = await pagesTable.insert(data).select().single();
    return response['id'] as String;
  }

  Future<List<Map<String, dynamic>>> getAllPages() async {
    final response = await pagesTable.select().order('title');
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getPublishedPages() async {
    final response = await pagesTable
        .select()
        .eq('is_published', true)
        .order('title');
    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>?> getPageBySlug(String slug) async {
    final response = await pagesTable.select().eq('slug', slug).maybeSingle();
    return response;
  }

  Future<Map<String, dynamic>?> getPageById(String id) async {
    final response = await pagesTable.select().eq('id', id).maybeSingle();
    return response;
  }

  Future<void> updatePage(String id, Map<String, dynamic> data) async {
    await pagesTable.update(data).eq('id', id);
  }

  Future<void> deletePage(String id) async {
    await pagesTable.delete().eq('id', id);
  }

  // ========== DOCTOR VERIFICATION DOCUMENTS ==========

  Future<String> insertDoctorVerificationDocument(
    Map<String, dynamic> data,
  ) async {
    final response = await doctorVerificationDocumentsTable
        .insert(data)
        .select()
        .single();
    return response['id'] as String;
  }

  Future<List<Map<String, dynamic>>> getDoctorVerificationDocuments(
    String doctorId,
  ) async {
    final response = await doctorVerificationDocumentsTable
        .select()
        .eq('doctor_id', doctorId)
        .order('upload_date', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> updateDoctorVerificationDocument(
    String id,
    Map<String, dynamic> data,
  ) async {
    await doctorVerificationDocumentsTable.update(data).eq('id', id);
  }

  Future<void> deleteDoctorVerificationDocument(String id) async {
    await doctorVerificationDocumentsTable.delete().eq('id', id);
  }

  Future<List<Map<String, dynamic>>> getPendingVerificationDocuments() async {
    final response = await doctorVerificationDocumentsTable
        .select()
        .eq('status', 'pending')
        .order('upload_date');
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> updateDoctorDocumentsStatus(
    String doctorId,
    String status,
  ) async {
    await doctorVerificationDocumentsTable
        .update({'status': status})
        .eq('doctor_id', doctorId);
  }

  // ========== DRIVER VERIFICATION DOCUMENTS ==========

  Future<String> insertDriverVerificationDocument(
    Map<String, dynamic> data,
  ) async {
    final response = await driverVerificationDocumentsTable
        .insert(data)
        .select()
        .single();
    return response['id'] as String;
  }

  Future<List<Map<String, dynamic>>> getDriverVerificationDocuments(
    String driverId,
  ) async {
    final response = await driverVerificationDocumentsTable
        .select()
        .eq('driver_id', driverId)
        .order('upload_date', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>?> getDriverVerificationDocumentById(
    String id,
  ) async {
    final response = await driverVerificationDocumentsTable
        .select()
        .eq('id', id)
        .maybeSingle();
    return response;
  }

  Future<void> updateDriverVerificationDocument(
    String id,
    Map<String, dynamic> data,
  ) async {
    await driverVerificationDocumentsTable.update(data).eq('id', id);
  }

  Future<void> deleteDriverVerificationDocument(String id) async {
    await driverVerificationDocumentsTable.delete().eq('id', id);
  }

  Future<List<Map<String, dynamic>>>
  getPendingDriverVerificationDocuments() async {
    final response = await driverVerificationDocumentsTable
        .select()
        .eq('status', 'pending')
        .order('upload_date');
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getDriverVerificationDocumentsByStatus(
    String status,
  ) async {
    final response = await driverVerificationDocumentsTable
        .select()
        .eq('status', status)
        .order('upload_date', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>?> getDriverVerificationDocumentByNumber(
    String documentNumber,
  ) async {
    final response = await driverVerificationDocumentsTable
        .select()
        .eq('document_number', documentNumber)
        .maybeSingle();
    return response;
  }

  Future<List<Map<String, dynamic>>> getDriverVerificationDocumentsByEmail(
    String email,
  ) async {
    final user = await getUserByEmail(email);
    if (user == null) return [];
    return getDriverVerificationDocuments(user['id']);
  }

  Future<List<Map<String, dynamic>>> getDriversWithPendingVerification() async {
    final response = await driverVerificationDocumentsTable.select().eq(
      'status',
      'pending',
    );

    final driverIds = (response as List)
        .map((doc) => doc['driver_id'] as String)
        .toSet()
        .toList();

    if (driverIds.isEmpty) return [];

    final users = <Map<String, dynamic>>[];
    for (final driverId in driverIds) {
      final user = await getUserById(driverId);
      if (user != null) {
        users.add(user);
      }
    }

    return users;
  }

  // ========== DRIVER VERIFICATION AUDIT LOGS ==========

  Future<String> insertDriverVerificationAuditLog(
    Map<String, dynamic> data,
  ) async {
    final response = await driverVerificationAuditLogsTable
        .insert(data)
        .select()
        .single();
    return response['id'] as String;
  }

  Future<List<Map<String, dynamic>>> getDriverVerificationAuditLogsByDocument(
    String documentId,
  ) async {
    final response = await driverVerificationAuditLogsTable
        .select()
        .eq('document_id', documentId)
        .order('timestamp', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getDriverVerificationAuditLogsByUser(
    String userId,
  ) async {
    final response = await driverVerificationAuditLogsTable
        .select()
        .eq('user_id', userId)
        .order('timestamp', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getAllDriverVerificationAuditLogs({
    int limit = 100,
  }) async {
    final response = await driverVerificationAuditLogsTable
        .select()
        .order('timestamp', ascending: false)
        .limit(limit);
    return List<Map<String, dynamic>>.from(response);
  }

  // ========== DRIVER VERIFICATION STATUS HELPERS ==========

  Future<String> getDriverVerificationStatus(String driverId) async {
    final documents = await getDriverVerificationDocuments(driverId);

    if (documents.isEmpty) {
      return 'not_started';
    }

    final pendingCount = documents
        .where((d) => d['status'] == 'pending')
        .length;
    final rejectedCount = documents
        .where((d) => d['status'] == 'rejected')
        .length;
    final approvedCount = documents
        .where((d) => d['status'] == 'approved')
        .length;

    if (pendingCount > 0) {
      return 'pending';
    }
    if (rejectedCount > 0) {
      return 'rejected';
    }
    if (approvedCount == documents.length) {
      return 'approved';
    }

    return 'pending';
  }

  Future<void> approveDriverVerificationDocument(
    String documentId,
    String reviewerId,
    String? notes,
  ) async {
    await driverVerificationDocumentsTable
        .update({
          'status': 'approved',
          'reviewer_id': reviewerId,
          'review_date': DateTime.now().toIso8601String(),
          'review_notes': notes,
        })
        .eq('id', documentId);

    await insertDriverVerificationAuditLog({
      'document_id': documentId,
      'user_id': reviewerId,
      'action': 'approved',
      'details': notes ?? 'Document approved',
    });
  }

  Future<void> rejectDriverVerificationDocument(
    String documentId,
    String reviewerId,
    String reason,
  ) async {
    await driverVerificationDocumentsTable
        .update({
          'status': 'rejected',
          'reviewer_id': reviewerId,
          'review_date': DateTime.now().toIso8601String(),
          'review_notes': reason,
        })
        .eq('id', documentId);

    await insertDriverVerificationAuditLog({
      'document_id': documentId,
      'user_id': reviewerId,
      'action': 'rejected',
      'details': 'Reason: $reason',
    });
  }

  Future<void> updateDriverDocumentsStatus(
    String driverId,
    String status,
  ) async {
    await driverVerificationDocumentsTable
        .update({'status': status})
        .eq('driver_id', driverId);
  }

  // ========== DOCTORS ==========

  Future<String> insertDoctor(Map<String, dynamic> data) async {
    final response = await doctorsTable.insert(data).select().single();
    return response['id'] as String;
  }

  Future<List<Map<String, dynamic>>> getDoctors() async {
    final response = await doctorsTable.select();
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getDoctorsByService(
    String serviceId,
  ) async {
    final response = await doctorsTable
        .select()
        .eq('assigned_service_id', serviceId)
        .eq('is_available', true);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>?> getDoctorByUserId(String userId) async {
    final response = await doctorsTable
        .select()
        .eq('user_id', userId)
        .maybeSingle();
    return response;
  }

  Future<void> updateDoctor(String id, Map<String, dynamic> data) async {
    await doctorsTable.update(data).eq('id', id);
  }

  Future<void> deleteDoctor(String id) async {
    await doctorsTable.delete().eq('id', id);
  }

  // ========== REPORTING / KPIs ==========

  Future<Map<String, int>> getAppointmentKpis({
    required DateTime start,
    required DateTime end,
  }) async {
    final startIso = start.toIso8601String();
    final endIso = end.toIso8601String();

    // Total
    final totalResponse = await appointmentsTable
        .select('id')
        .gte('scheduled_at', startIso)
        .lte('scheduled_at', endIso)
        .limit(10000);
    final total = (totalResponse as List).length;

    // Completed
    final completedResponse = await appointmentsTable
        .select('id')
        .eq('status', 'completed')
        .gte('scheduled_at', startIso)
        .lte('scheduled_at', endIso)
        .limit(10000);
    final completed = (completedResponse as List).length;

    // Canceled
    final canceledResponse = await appointmentsTable
        .select('id')
        .eq('status', 'canceled')
        .gte('scheduled_at', startIso)
        .lte('scheduled_at', endIso)
        .limit(10000);
    final canceled = (canceledResponse as List).length;

    // Emergency
    final emergencyResponse = await appointmentsTable
        .select('id')
        .eq('urgency_level', 'emergency')
        .gte('scheduled_at', startIso)
        .lte('scheduled_at', endIso)
        .limit(10000);
    final emergency = (emergencyResponse as List).length;

    // Routine
    final routineResponse = await appointmentsTable
        .select('id')
        .eq('urgency_level', 'routine')
        .gte('scheduled_at', startIso)
        .lte('scheduled_at', endIso)
        .limit(10000);
    final routine = (routineResponse as List).length;

    return {
      'total': total,
      'completed': completed,
      'canceled': canceled,
      'emergency': emergency,
      'routine': routine,
    };
  }

  Future<double> getRevenueByDateRange(DateTime start, DateTime end) async {
    final startIso = start.toIso8601String();
    final endIso = end.toIso8601String();

    final response = await paymentsTable
        .select('amount')
        .gte('created_at', startIso)
        .lte('created_at', endIso)
        .eq('status', 'completed');

    // Get refunded payments separately
    final refundedResponse = await paymentsTable
        .select('amount')
        .gte('created_at', startIso)
        .lte('created_at', endIso)
        .eq('status', 'refunded');

    double total = 0.0;
    for (final payment in response as List) {
      final amount = payment['amount'];
      if (amount != null) {
        total += (amount as num).toDouble();
      }
    }
    for (final payment in refundedResponse as List) {
      final amount = payment['amount'];
      if (amount != null) {
        total -= (amount as num).toDouble();
      }
    }
    return total;
  }

  Future<List<Map<String, dynamic>>> getDailyAppointmentCounts({
    required DateTime start,
    required DateTime end,
  }) async {
    final startIso = start.toIso8601String();
    final endIso = end.toIso8601String();

    final response = await appointmentsTable
        .select('scheduled_at')
        .gte('scheduled_at', startIso)
        .lte('scheduled_at', endIso);

    final appointments = List<Map<String, dynamic>>.from(response);
    final dailyMap = <String, int>{};

    for (final appointment in appointments) {
      final scheduledAt = appointment['scheduled_at'] as String?;
      if (scheduledAt != null) {
        final date = scheduledAt.split('T')[0];
        dailyMap[date] = (dailyMap[date] ?? 0) + 1;
      }
    }

    return dailyMap.entries
        .map((e) => {'day': e.key, 'count': e.value})
        .toList()
      ..sort((a, b) => (a['day'] as String).compareTo(b['day'] as String));
  }

  // ========== DISPOSE ==========

  void dispose() {}
}
