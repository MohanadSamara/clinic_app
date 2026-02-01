// lib/services/supabase_service.dart
// Main Supabase Client and Service
// Replaces Firestore Service

import 'package:supabase_flutter/supabase_flutter.dart';
import '../supabase_options.dart';

/// Supabase Service - Single Source of Truth
/// Replaces all Firestore and SQLite operations
class SupabaseService {
  // Singleton
  static final SupabaseService instance = SupabaseService._init();
  SupabaseService._init();

  // Supabase client
  final SupabaseClient _client = SupabaseClient(
    SupabaseOptions.projectUrl,
    SupabaseOptions.anonKey,
  );

  // Get client instance
  SupabaseClient get client => _client;

  // ========== AUTH HELPERS ==========

  /// Get current user ID
  String? get currentUserId => _client.auth.currentUser?.id;

  /// Get current user email
  String? get currentUserEmail => _client.auth.currentUser?.email;

  /// Get current user
  User? get currentUser => _client.auth.currentUser;

  /// Check if user is authenticated
  bool get isAuthenticated => _client.auth.currentUser != null;

  /// Get current session
  Session? get currentSession => _client.auth.currentSession;

  // ========== TABLE REFERENCES ==========

  /// Users table
  SupabaseQueryBuilder get usersTable => _client.from('users');

  /// Appointments table
  SupabaseQueryBuilder get appointmentsTable => _client.from('appointments');

  /// Pets table
  SupabaseQueryBuilder get petsTable => _client.from('pets');

  /// Medical records table
  SupabaseQueryBuilder get medicalRecordsTable =>
      _client.from('medical_records');

  /// Documents table
  SupabaseQueryBuilder get documentsTable => _client.from('documents');

  /// Payments table
  SupabaseQueryBuilder get paymentsTable => _client.from('payments');

  /// Notifications table
  SupabaseQueryBuilder get notificationsTable => _client.from('notifications');

  /// Services table
  SupabaseQueryBuilder get servicesTable => _client.from('services');

  /// Schedules table
  SupabaseQueryBuilder get schedulesTable => _client.from('schedules');

  /// Vans table
  SupabaseQueryBuilder get vansTable => _client.from('vans');

  /// Doctor verification documents table
  SupabaseQueryBuilder get doctorVerificationDocumentsTable =>
      _client.from('doctor_verification_documents');

  /// Driver verification documents table
  SupabaseQueryBuilder get driverVerificationDocumentsTable =>
      _client.from('driver_verification_documents');

  /// Audit logs table
  SupabaseQueryBuilder get auditLogsTable => _client.from('audit_logs');

  /// Service requests table
  SupabaseQueryBuilder get serviceRequestsTable =>
      _client.from('service_requests');

  /// Pages table
  SupabaseQueryBuilder get pagesTable => _client.from('pages');

  // ========== HELPERS ==========

  /// Generate email key (replace . with _)
  static String getEmailKey(String email) {
    return email.toLowerCase().replaceAll('.', '_');
  }

  /// Format timestamp for Supabase
  static String formatTimestamp(DateTime dateTime) {
    return dateTime.toIso8601String();
  }

  /// Dispose - close connections
  void dispose() {
    // Supabase handles connection pooling automatically
  }
}

/// Extension for common operations
extension SupabaseExtensions on SupabaseService {
  /// Get a single document by ID
  Future<Map<String, dynamic>?> getById({
    required String table,
    required String id,
  }) async {
    final response = await SupabaseService.instance.usersTable
        .select()
        .eq('id', id)
        .maybeSingle();
    return response;
  }

  /// Get all records from a table
  Future<List<Map<String, dynamic>>> getAll({
    required String table,
    String? orderBy,
    bool ascending = false,
    int? limit,
    String? filterField,
    dynamic filterValue,
  }) async {
    dynamic query = _client.from(table).select();

    if (filterField != null && filterValue != null) {
      query = query.eq(filterField, filterValue);
    }

    if (orderBy != null) {
      query = query.order(orderBy, ascending: ascending);
    }

    if (limit != null) {
      query = query.limit(limit);
    }

    final response = await query;
    return List<Map<String, dynamic>>.from(response as List);
  }

  /// Insert a record
  Future<String> insert({
    required String table,
    required Map<String, dynamic> data,
  }) async {
    final response = await _client.from(table).insert(data).select().single();
    return response['id'] as String;
  }

  /// Update a record
  Future<void> update({
    required String table,
    required String id,
    required Map<String, dynamic> data,
  }) async {
    await _client.from(table).update(data).eq('id', id);
  }

  /// Delete a record
  Future<void> delete({required String table, required String id}) async {
    await _client.from(table).delete().eq('id', id);
  }

  /// Query with conditions
  Future<List<Map<String, dynamic>>> query({
    required String table,
    required String field,
    required dynamic value,
    String? orderBy,
    bool ascending = false,
    int? limit,
  }) async {
    dynamic query = _client.from(table).select().eq(field, value);

    if (orderBy != null) {
      query = query.order(orderBy, ascending: ascending);
    }

    if (limit != null) {
      query = query.limit(limit);
    }

    final response = await query;
    return List<Map<String, dynamic>>.from(response as List);
  }
}
