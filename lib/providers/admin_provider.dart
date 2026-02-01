// lib/providers/admin_provider.dart
// Migrated to Supabase database (PostgreSQL) - 2026-01-31
// All data synced globally across devices via Supabase

import 'package:flutter/material.dart';
import '../services/supabase_complete_service.dart';
import '../models/user.dart';

/// AdminProvider - Supabase Database Integration
///
/// Database: Supabase (PostgreSQL)
/// Tables used: users, system_settings, audit_logs
///
/// All database operations now use Supabase client exclusively.
/// Firestore has been completely removed.
class AdminProvider with ChangeNotifier {
  bool _isLoading = false;
  String? _error;
  List<User> _users = [];
  Map<String, dynamic> _systemSettings = {};
  List<Map<String, dynamic>> _auditLogs = [];

  // Supabase service instance for database operations (singleton)
  final SupabaseCompleteService _supabaseService =
      SupabaseCompleteService.instance;

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<User> get users => _users;
  Map<String, dynamic> get systemSettings => _systemSettings;
  List<Map<String, dynamic>> get auditLogs => _auditLogs;

  // Helper to convert any ID to int
  int _toIntId(dynamic id) {
    if (id == null) return 0;
    if (id is int) return id;
    if (id is String) {
      return int.tryParse(id) ?? id.hashCode;
    }
    return id.hashCode;
  }

  // ========== LOAD USERS ==========

  Future<void> loadUsers({bool forceRefresh = false}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final users = await _supabaseService.getAllUsers();

      _users = users.map((data) {
        data['id'] = _toIntId(data['id']);
        return User.fromMap(data);
      }).toList();
    } catch (e) {
      debugPrint('Error loading users from Supabase: $e');
      _error = 'Failed to load users: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ========== LOAD USERS BY ROLE ==========

  Future<void> loadUsersByRole(String role) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final users = await _supabaseService.getAllUsers(role: role);

      _users = users.map((data) {
        data['id'] = _toIntId(data['id']);
        return User.fromMap(data);
      }).toList();
    } catch (e) {
      debugPrint('Error loading users by role: $e');
      _error = 'Failed to load users: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ========== UPDATE USER ROLE ==========

  Future<bool> updateUserRole(User user, String newRole) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Update in Supabase
      await _supabaseService.updateUser(user.id.toString(), {
        'role': newRole,
        'updated_at': DateTime.now().toIso8601String(),
      });

      // Update local state
      final index = _users.indexWhere((u) => u.id == user.id);
      if (index != -1) {
        _users[index] = user.copyWith(role: newRole);
      }

      // Log audit action
      await logAuditAction(
        'update_user_role',
        'Updated ${user.name} role to $newRole',
        userId: user.id.toString(),
      );

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error updating user role: $e');
      _error = 'Failed to update user role: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ========== DELETE USER ==========

  Future<bool> deleteUser(User user) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Delete from Supabase
      await _supabaseService.deleteUser(user.id.toString());

      // Remove from local state
      _users.removeWhere((u) => u.id == user.id);

      // Log audit action
      await logAuditAction(
        'delete_user',
        'Deleted user ${user.name}',
        userId: user.id.toString(),
      );

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error deleting user: $e');
      _error = 'Failed to delete user: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ========== LINK DOCTOR TO DRIVER ==========

  Future<bool> linkDoctorToDriver(User doctor, User driver) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Update doctor in Supabase
      await _supabaseService.updateUser(doctor.id.toString(), {
        'linked_driver_id': driver.id,
        'updated_at': DateTime.now().toIso8601String(),
      });

      // Update driver in Supabase
      await _supabaseService.updateUser(driver.id.toString(), {
        'linked_doctor_id': doctor.id,
        'updated_at': DateTime.now().toIso8601String(),
      });

      // Update local state
      final doctorIndex = _users.indexWhere((u) => u.id == doctor.id);
      final driverIndex = _users.indexWhere((u) => u.id == driver.id);

      if (doctorIndex != -1) {
        _users[doctorIndex] = doctor.copyWith(linkedDriverId: driver.id);
      }
      if (driverIndex != -1) {
        _users[driverIndex] = driver.copyWith(linkedDoctorId: doctor.id);
      }

      // Log audit action
      await logAuditAction(
        'link_users',
        'Linked Dr. ${doctor.name} to driver ${driver.name}',
        userId: doctor.id.toString(),
      );

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error linking users: $e');
      _error = 'Failed to link users: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ========== UNLINK DOCTOR FROM DRIVER ==========

  Future<bool> unlinkDoctorFromDriver(User doctor, User driver) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Update doctor in Supabase
      await _supabaseService.updateUser(doctor.id.toString(), {
        'linked_driver_id': null,
        'updated_at': DateTime.now().toIso8601String(),
      });

      // Update driver in Supabase
      await _supabaseService.updateUser(driver.id.toString(), {
        'linked_doctor_id': null,
        'updated_at': DateTime.now().toIso8601String(),
      });

      // Update local state
      final doctorIndex = _users.indexWhere((u) => u.id == doctor.id);
      final driverIndex = _users.indexWhere((u) => u.id == driver.id);

      if (doctorIndex != -1) {
        _users[doctorIndex] = doctor.copyWith(linkedDriverId: null);
      }
      if (driverIndex != -1) {
        _users[driverIndex] = driver.copyWith(linkedDoctorId: null);
      }

      // Log audit action
      await logAuditAction(
        'unlink_users',
        'Unlinked Dr. ${doctor.name} from driver ${driver.name}',
        userId: doctor.id.toString(),
      );

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error unlinking users: $e');
      _error = 'Failed to unlink users: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ========== SYSTEM SETTINGS ==========

  Future<void> loadSystemSettings() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _systemSettings = await _supabaseService.getSystemSettings();
    } catch (e) {
      debugPrint('Error loading system settings: $e');
      _error = 'Failed to load system settings: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateSystemSetting(String key, dynamic value) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _supabaseService.updateSystemSetting(key, value);

      _systemSettings[key] = value;

      await logAuditAction(
        'update_setting',
        'Updated system setting $key to $value',
      );

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error updating system setting: $e');
      _error = 'Failed to update system setting: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ========== AUDIT LOGS ==========

  Future<void> loadAuditLogs({int limit = 100}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final logs = await _supabaseService.getAuditLogs(limit: limit);
      _auditLogs = logs;
    } catch (e) {
      debugPrint('Error loading audit logs: $e');
      _error = 'Failed to load audit logs: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ========== DASHBOARD STATS ==========

  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      // Get all users
      final allUsers = await _supabaseService.getAllUsers();

      final ownerCount = allUsers.where((u) => u['role'] == 'owner').length;
      final doctorCount = allUsers.where((u) => u['role'] == 'doctor').length;
      final driverCount = allUsers.where((u) => u['role'] == 'driver').length;
      final adminCount = allUsers.where((u) => u['role'] == 'admin').length;

      return {
        'owner_count': ownerCount,
        'doctor_count': doctorCount,
        'driver_count': driverCount,
        'admin_count': adminCount,
        'total_users': allUsers.length,
      };
    } catch (e) {
      debugPrint('Error getting dashboard stats: $e');
      _error = 'Failed to load dashboard stats: $e';
      return {};
    }
  }

  // ========== AUDIT LOGGING ==========

  Future<void> logAuditAction(
    String action,
    String details, {
    String? userId,
  }) async {
    try {
      await _supabaseService.insertAuditLog({
        'action': action,
        'details': details,
        'user_id': userId,
        'document_id': null,
        'ip_address': null,
      });
    } catch (e) {
      debugPrint('Failed to log audit action: $e');
    }
  }

  // ========== HELPERS ==========

  void clearError() {
    _error = null;
    notifyListeners();
  }

  User? getUserById(dynamic id) {
    final idInt = _toIntId(id);
    try {
      return _users.firstWhere((u) => u.id == idInt);
    } catch (e) {
      return null;
    }
  }

  List<User> getUsersByRole(String role) {
    return _users.where((u) => u.role == role).toList();
  }
}
