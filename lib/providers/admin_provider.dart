// lib/providers/admin_provider.dart
// Admin Provider using Firestore as the single source of truth
// All data synced globally across devices
// OTP Authentication remains UNCHANGED

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';

class AdminProvider with ChangeNotifier {
  bool _isLoading = false;
  String? _error;
  List<User> _users = [];
  Map<String, dynamic> _systemSettings = {};
  List<Map<String, dynamic>> _auditLogs = [];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
      final snapshot = await _firestore.collection('users').get();

      _users = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = _toIntId(doc.id);
        return User.fromMap(data);
      }).toList();
    } catch (e) {
      debugPrint('Error loading users from Firestore: $e');
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
      final snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: role)
          .get();

      _users = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = _toIntId(doc.id);
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
      // Update in Firestore
      await _firestore.collection('users').doc(user.id.toString()).update({
        'role': newRole,
        'updatedAt': DateTime.now().toIso8601String(),
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
      // Delete from Firestore
      await _firestore.collection('users').doc(user.id.toString()).delete();

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
      // Update doctor in Firestore
      await _firestore.collection('users').doc(doctor.id.toString()).update({
        'linkedDriverId': driver.id,
        'linked_driver_id': driver.id,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      // Update driver in Firestore
      await _firestore.collection('users').doc(driver.id.toString()).update({
        'linkedDoctorId': doctor.id,
        'linked_doctor_id': doctor.id,
        'updatedAt': DateTime.now().toIso8601String(),
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
      // Update doctor in Firestore
      await _firestore.collection('users').doc(doctor.id.toString()).update({
        'linkedDriverId': null,
        'linked_driver_id': null,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      // Update driver in Firestore
      await _firestore.collection('users').doc(driver.id.toString()).update({
        'linkedDoctorId': null,
        'linked_doctor_id': null,
        'updatedAt': DateTime.now().toIso8601String(),
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
      final snapshot = await _firestore.collection('system_settings').get();

      _systemSettings = {};
      for (var doc in snapshot.docs) {
        _systemSettings[doc.id] = doc.data()['value'];
      }
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
      await _firestore.collection('system_settings').doc(key).set({
        'value': value.toString(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

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
      final snapshot = await _firestore
          .collection('audit_logs')
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      _auditLogs = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
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
      // Get user counts by role
      final ownerSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'owner')
          .count()
          .get();
      final doctorSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'doctor')
          .count()
          .get();
      final driverSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'driver')
          .count()
          .get();
      final adminSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'admin')
          .count()
          .get();

      final appointmentSnapshot = await _firestore
          .collection('appointments')
          .count()
          .get();

      final paymentSnapshot = await _firestore
          .collection('payments')
          .count()
          .get();

      return {
        'owner_count': ownerSnapshot.count ?? 0,
        'doctor_count': doctorSnapshot.count ?? 0,
        'driver_count': driverSnapshot.count ?? 0,
        'admin_count': adminSnapshot.count ?? 0,
        'total_appointments': appointmentSnapshot.count ?? 0,
        'total_payments': paymentSnapshot.count ?? 0,
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
      await _firestore.collection('audit_logs').add({
        'action': action,
        'details': details,
        'userId': userId,
        'timestamp': FieldValue.serverTimestamp(),
        'documentId': null,
        'ipAddress': null,
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
