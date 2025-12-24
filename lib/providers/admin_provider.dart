import 'package:flutter/material.dart';
import '../db/db_helper.dart';
import '../models/user.dart';

class AdminProvider with ChangeNotifier {
  bool _isLoading = false;
  String? _error;
  List<User> _users = [];
  Map<String, dynamic> _systemSettings = {};
  List<Map<String, dynamic>> _auditLogs = [];

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<User> get users => _users;
  Map<String, dynamic> get systemSettings => _systemSettings;
  List<Map<String, dynamic>> get auditLogs => _auditLogs;

  // Load all users
  Future<void> loadUsers() async {
    _setLoading(true);
    try {
      final userMaps = await DBHelper.instance.getAllUsers();
      _users = userMaps.map((map) => User.fromMap(map)).toList();
      _error = null;
    } catch (e) {
      _error = 'Failed to load users: $e';
    } finally {
      _setLoading(false);
    }
  }

  // Update user role
  Future<bool> updateUserRole(User user, String newRole) async {
    _setLoading(true);
    try {
      await DBHelper.instance.updateUser(user.id!, {'role': newRole});
      final index = _users.indexWhere((u) => u.id == user.id);
      if (index != -1) {
        _users[index] = user.copyWith(role: newRole);
      }
      await logAuditAction(
        'update_user_role',
        'Updated ${user.name} role to $newRole',
      );
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to update user role: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Delete user
  Future<bool> deleteUser(User user) async {
    _setLoading(true);
    try {
      await DBHelper.instance.deleteUser(user.id!);
      _users.removeWhere((u) => u.id == user.id);
      await logAuditAction('delete_user', 'Deleted user ${user.name}');
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to delete user: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Link doctor to driver
  Future<bool> linkDoctorToDriver(User doctor, User driver) async {
    _setLoading(true);
    try {
      await DBHelper.instance.updateUser(doctor.id!, {
        'linked_driver_id': driver.id,
      });
      await DBHelper.instance.updateUser(driver.id!, {
        'linked_doctor_id': doctor.id,
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

      await logAuditAction(
        'link_users',
        'Linked Dr. ${doctor.name} to driver ${driver.name}',
      );
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to link users: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Unlink doctor from driver
  Future<bool> unlinkDoctorFromDriver(User doctor, User driver) async {
    _setLoading(true);
    try {
      await DBHelper.instance.updateUser(doctor.id!, {
        'linked_driver_id': null,
      });
      await DBHelper.instance.updateUser(driver.id!, {
        'linked_doctor_id': null,
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

      await logAuditAction(
        'unlink_users',
        'Unlinked Dr. ${doctor.name} from driver ${driver.name}',
      );
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to unlink users: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Load system settings
  Future<void> loadSystemSettings() async {
    _setLoading(true);
    try {
      final settings = await DBHelper.instance.getSystemSettings();
      _systemSettings = settings;
      _error = null;
    } catch (e) {
      _error = 'Failed to load system settings: $e';
    } finally {
      _setLoading(false);
    }
  }

  // Update system setting
  Future<bool> updateSystemSetting(String key, dynamic value) async {
    _setLoading(true);
    try {
      await DBHelper.instance.updateSystemSetting(key, value);
      _systemSettings[key] = value;
      await logAuditAction(
        'update_setting',
        'Updated system setting $key to $value',
      );
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to update system setting: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Load audit logs
  Future<void> loadAuditLogs({int limit = 100}) async {
    _setLoading(true);
    try {
      final logs = await DBHelper.instance.getAuditLogs(limit: limit);
      _auditLogs = logs;
      _error = null;
    } catch (e) {
      _error = 'Failed to load audit logs: $e';
    } finally {
      _setLoading(false);
    }
  }

  // Get dashboard statistics
  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final stats = await DBHelper.instance.getDashboardStats();
      return stats;
    } catch (e) {
      _error = 'Failed to load dashboard stats: $e';
      return {};
    }
  }

  // Private methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  Future<void> logAuditAction(String action, String details) async {
    try {
      await DBHelper.instance.insertAuditLog({
        'action': action,
        'details': details,
        'timestamp': DateTime.now().toIso8601String(),
        'user_id': null, // TODO: Add current user ID when auth is available
        'document_id': null,
        'ip_address': null,
      });
    } catch (e) {
      debugPrint('Failed to log audit action: $e');
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}







