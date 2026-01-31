// lib/services/firestore_service.dart
// Firestore Service for User Data Synchronization
// This enables real-time data sharing across all devices
// Enhanced with offline support and error handling

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import '../models/user.dart';

/// Result class for Firestore operations
class FirestoreResult<T> {
  final T? data;
  final String? error;
  final bool success;

  FirestoreResult({this.data, this.error, this.success = true});

  factory FirestoreResult.success(T data) => FirestoreResult(data: data);
  factory FirestoreResult.error(String error) =>
      FirestoreResult(error: error, success: false);
}

/// Connection state enum for Firestore
enum FirestoreConnectionState {
  connected,
  disconnected,
  connecting,
  unavailable,
}

class FirestoreService {
  static final FirestoreService instance = FirestoreService._init();
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Connection state stream
  final _connectionStateController =
      StreamController<FirestoreConnectionState>.broadcast();
  Stream<FirestoreConnectionState> get connectionState =>
      _connectionStateController.stream;

  // Retry configuration
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 2);

  FirestoreService._init() {
    _setupConnectionListener();
  }

  /// Setup connection state listener
  void _setupConnectionListener() {
    if (kIsWeb) {
      // Web doesn't support persistence settings in the same way
      return;
    }

    try {
      // Enable persistence using the settings constructor
      _firestore.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: 104857600, // 100MB cache
      );
    } catch (e) {
      debugPrint('Error setting Firestore persistence: $e');
    }

    // Monitor connection state
    _firestore
        .collection('users')
        .snapshots()
        .listen(
          (snapshot) {
            if (snapshot.metadata.isFromCache) {
              _connectionStateController.add(
                FirestoreConnectionState.disconnected,
              );
            } else {
              _connectionStateController.add(
                FirestoreConnectionState.connected,
              );
            }
          },
          onError: (error) {
            debugPrint('Connection error: $error');
            _connectionStateController.add(
              FirestoreConnectionState.disconnected,
            );
          },
        );
  }

  /// Get current connection state
  Future<FirestoreConnectionState> getConnectionState() async {
    try {
      // Try to read a document to check connection
      final doc = await _firestore.collection('users').limit(1).get();
      return doc.metadata.isFromCache
          ? FirestoreConnectionState.disconnected
          : FirestoreConnectionState.connected;
    } catch (e) {
      debugPrint('Error checking connection state: $e');
      return FirestoreConnectionState.unavailable;
    }
  }

  /// Check if Firestore is available
  Future<bool> isAvailable() async {
    try {
      await _firestore.collection('users').limit(1).get();
      return true;
    } catch (e) {
      debugPrint('Firestore unavailable: $e');
      return false;
    }
  }

  /// Retry helper with exponential backoff
  Future<T> _withRetry<T>(Future<T> Function() operation) async {
    int attempts = 0;
    while (true) {
      try {
        return await operation();
      } catch (e) {
        attempts++;
        if (attempts >= _maxRetries) {
          debugPrint('Firestore operation failed after $attempts attempts: $e');
          rethrow;
        }
        debugPrint(
          'Firestore operation failed, retrying ($attempts/$_maxRetries): $e',
        );
        await Future.delayed(_retryDelay * attempts);
      }
    }
  }

  // Collection references
  CollectionReference get usersCollection => _firestore.collection('users');
  CollectionReference get appointmentsCollection =>
      _firestore.collection('appointments');
  CollectionReference get petsCollection => _firestore.collection('pets');
  CollectionReference get medicalRecordsCollection =>
      _firestore.collection('medical_records');
  CollectionReference get paymentsCollection =>
      _firestore.collection('payments');
  CollectionReference get notificationsCollection =>
      _firestore.collection('notifications');
  CollectionReference get serviceRequestsCollection =>
      _firestore.collection('service_requests');
  CollectionReference get auditLogsCollection =>
      _firestore.collection('audit_logs');

  // ========== USER OPERATIONS ==========

  /// Create or update user in Firestore with retry logic
  Future<FirestoreResult<void>> createOrUpdateUser(User user) async {
    return await _withRetry(() async {
      try {
        // Use email as document ID for easy lookup
        final emailKey = user.email.toLowerCase().replaceAll('.', '_');

        await usersCollection.doc(emailKey).set({
          'id': user.id,
          'email': user.email.toLowerCase(),
          'emailKey': emailKey,
          'name': user.name,
          'phone': user.phone,
          'role': user.role,
          'area': user.area,
          'provider': user.provider,
          'providerId': user.providerId,
          'profileImage': user.profileImage,
          'verificationStatus': user.verificationStatus,
          'linkedDoctorId': user.linkedDoctorId,
          'linkedDriverId': user.linkedDriverId,
          'availabilityStatus': user.availabilityStatus,
          'lastSeen': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        debugPrint('✅ User synced to Firestore: ${user.email}');
        return FirestoreResult<void>.success(null);
      } catch (e) {
        debugPrint('❌ Error syncing user to Firestore: $e');
        return FirestoreResult<void>.error(e.toString());
      }
    });
  }

  /// Get user by email from Firestore
  Future<FirestoreResult<User?>> getUserByEmail(String email) async {
    return await _withRetry(() async {
      try {
        final emailKey = email.toLowerCase().replaceAll('.', '_');
        final doc = await usersCollection.doc(emailKey).get();

        if (doc.exists) {
          return FirestoreResult<User?>.success(
            User.fromMap(doc.data() as Map<String, dynamic>),
          );
        }
        return FirestoreResult<User?>.success(null);
      } catch (e) {
        debugPrint('❌ Error getting user from Firestore: $e');
        return FirestoreResult<User?>.error(e.toString());
      }
    });
  }

  /// Get all users from Firestore
  Future<FirestoreResult<List<User>>> getAllUsers() async {
    return await _withRetry(() async {
      try {
        final snapshot = await usersCollection.get();
        final users = snapshot.docs
            .map((doc) => User.fromMap(doc.data() as Map<String, dynamic>))
            .toList();
        return FirestoreResult<List<User>>.success(users);
      } catch (e) {
        debugPrint('❌ Error getting all users from Firestore: $e');
        return FirestoreResult<List<User>>.error(e.toString());
      }
    });
  }

  /// Get users by role
  Future<FirestoreResult<List<User>>> getUsersByRole(String role) async {
    return await _withRetry(() async {
      try {
        final snapshot = await usersCollection
            .where('role', isEqualTo: role)
            .get();
        final users = snapshot.docs
            .map((doc) => User.fromMap(doc.data() as Map<String, dynamic>))
            .toList();
        return FirestoreResult<List<User>>.success(users);
      } catch (e) {
        debugPrint('❌ Error getting users by role from Firestore: $e');
        return FirestoreResult<List<User>>.error(e.toString());
      }
    });
  }

  /// Update user in Firestore
  Future<FirestoreResult<void>> updateUser(
    String email,
    Map<String, dynamic> data,
  ) async {
    return await _withRetry(() async {
      try {
        final emailKey = email.toLowerCase().replaceAll('.', '_');
        data['updatedAt'] = FieldValue.serverTimestamp();
        await usersCollection.doc(emailKey).update(data);
        debugPrint('✅ User updated in Firestore: $email');
        return FirestoreResult<void>.success(null);
      } catch (e) {
        debugPrint('❌ Error updating user in Firestore: $e');
        return FirestoreResult<void>.error(e.toString());
      }
    });
  }

  /// Delete user from Firestore
  Future<FirestoreResult<void>> deleteUser(String email) async {
    return await _withRetry(() async {
      try {
        final emailKey = email.toLowerCase().replaceAll('.', '_');
        await usersCollection.doc(emailKey).delete();
        debugPrint('✅ User deleted from Firestore: $email');
        return FirestoreResult<void>.success(null);
      } catch (e) {
        debugPrint('❌ Error deleting user from Firestore: $e');
        return FirestoreResult<void>.error(e.toString());
      }
    });
  }

  /// Real-time user stream
  Stream<List<User>> getUsersStream() {
    return usersCollection.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => User.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    });
  }

  /// Real-time users by role stream
  Stream<List<User>> getUsersByRoleStream(String role) {
    return usersCollection.where('role', isEqualTo: role).snapshots().map((
      snapshot,
    ) {
      return snapshot.docs
          .map((doc) => User.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    });
  }

  /// Update user availability status
  Future<FirestoreResult<void>> updateUserStatus(
    String email,
    String status,
  ) async {
    return await _withRetry(() async {
      try {
        final emailKey = email.toLowerCase().replaceAll('.', '_');
        await usersCollection.doc(emailKey).update({
          'availabilityStatus': status,
          'lastSeen': FieldValue.serverTimestamp(),
        });
        return FirestoreResult<void>.success(null);
      } catch (e) {
        debugPrint('❌ Error updating user status: $e');
        return FirestoreResult<void>.error(e.toString());
      }
    });
  }

  // ========== APPOINTMENT OPERATIONS ==========

  Future<FirestoreResult<void>> createAppointment(
    Map<String, dynamic> data,
  ) async {
    return await _withRetry(() async {
      try {
        final docRef = await appointmentsCollection.add(data);
        await docRef.update({'id': docRef.id});
        debugPrint('✅ Appointment created in Firestore');
        return FirestoreResult<void>.success(null);
      } catch (e) {
        debugPrint('❌ Error creating appointment in Firestore: $e');
        return FirestoreResult<void>.error(e.toString());
      }
    });
  }

  Future<FirestoreResult<void>> updateAppointment(
    String id,
    Map<String, dynamic> data,
  ) async {
    return await _withRetry(() async {
      try {
        data['updatedAt'] = FieldValue.serverTimestamp();
        await appointmentsCollection.doc(id).update(data);
        debugPrint('✅ Appointment updated in Firestore');
        return FirestoreResult<void>.success(null);
      } catch (e) {
        debugPrint('❌ Error updating appointment in Firestore: $e');
        return FirestoreResult<void>.error(e.toString());
      }
    });
  }

  Stream<List<Map<String, dynamic>>> getAppointmentsStream() {
    return appointmentsCollection
        .orderBy('scheduledAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(
                (doc) => {...doc.data() as Map<String, dynamic>, 'id': doc.id},
              )
              .toList();
        });
  }

  // ========== NOTIFICATION OPERATIONS ==========

  Future<FirestoreResult<void>> createNotification(
    Map<String, dynamic> data,
  ) async {
    return await _withRetry(() async {
      try {
        final docRef = await notificationsCollection.add(data);
        await docRef.update({'id': docRef.id});
        return FirestoreResult<void>.success(null);
      } catch (e) {
        debugPrint('❌ Error creating notification in Firestore: $e');
        return FirestoreResult<void>.error(e.toString());
      }
    });
  }

  Stream<List<Map<String, dynamic>>> getNotificationsStream(String userId) {
    return notificationsCollection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(
                (doc) => {...doc.data() as Map<String, dynamic>, 'id': doc.id},
              )
              .toList();
        });
  }

  // ========== AUDIT LOG OPERATIONS ==========

  Future<FirestoreResult<void>> logAuditAction(
    String action,
    String details, {
    String? userId,
  }) async {
    return await _withRetry(() async {
      try {
        await auditLogsCollection.add({
          'action': action,
          'details': details,
          'userId': userId,
          'timestamp': FieldValue.serverTimestamp(),
        });
        return FirestoreResult<void>.success(null);
      } catch (e) {
        debugPrint('❌ Error logging audit action: $e');
        return FirestoreResult<void>.error(e.toString());
      }
    });
  }

  Stream<List<Map<String, dynamic>>> getAuditLogsStream({int limit = 100}) {
    return auditLogsCollection
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(
                (doc) => {...doc.data() as Map<String, dynamic>, 'id': doc.id},
              )
              .toList();
        });
  }

  // ========== SYNC FROM LOCAL TO CLOUD ==========

  /// Sync all local users to Firestore (useful for migration)
  Future<Map<String, dynamic>> syncAllUsersToCloud(List<User> users) async {
    int successCount = 0;
    int failCount = 0;
    final errors = <String>[];

    for (final user in users) {
      try {
        final result = await createOrUpdateUser(user);
        if (result.success) {
          successCount++;
        } else {
          failCount++;
          errors.add('${user.email}: ${result.error}');
        }
      } catch (e) {
        failCount++;
        errors.add('${user.email}: $e');
      }
    }

    debugPrint('✅ Synced $successCount/${users.length} users to Firestore');
    if (errors.isNotEmpty) {
      debugPrint('❌ Errors: ${errors.length} - ${errors.join(', ')}');
    }

    return {'success': successCount, 'failed': failCount, 'errors': errors};
  }

  // ========== SYNC FROM CLOUD TO LOCAL ==========

  /// Get all users from cloud for local storage
  Future<FirestoreResult<List<User>>> fetchAllUsersFromCloud() async {
    return await getAllUsers();
  }

  // ========== DATA STATISTICS ==========

  Future<FirestoreResult<Map<String, int>>> getUserStats() async {
    return await _withRetry(() async {
      try {
        final totalSnapshot = await usersCollection.count().get();
        final ownerSnapshot = await usersCollection
            .where('role', isEqualTo: 'owner')
            .count()
            .get();
        final doctorSnapshot = await usersCollection
            .where('role', isEqualTo: 'doctor')
            .count()
            .get();
        final driverSnapshot = await usersCollection
            .where('role', isEqualTo: 'driver')
            .count()
            .get();
        final adminSnapshot = await usersCollection
            .where('role', isEqualTo: 'admin')
            .count()
            .get();

        final stats = {
          'total': totalSnapshot.count ?? 0,
          'owners': ownerSnapshot.count ?? 0,
          'doctors': doctorSnapshot.count ?? 0,
          'drivers': driverSnapshot.count ?? 0,
          'admins': adminSnapshot.count ?? 0,
        };

        return FirestoreResult<Map<String, int>>.success(stats);
      } catch (e) {
        debugPrint('❌ Error getting user stats: $e');
        return FirestoreResult<Map<String, int>>.error(e.toString());
      }
    });
  }

  // ========== COLLECTION MANAGEMENT ==========

  /// Check if a collection exists
  Future<bool> collectionExists(String collectionPath) async {
    try {
      final snapshot = await _firestore
          .collection(collectionPath)
          .limit(1)
          .get();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get document count for a collection
  Future<int> getCollectionCount(String collectionPath) async {
    try {
      final snapshot = await _firestore
          .collection(collectionPath)
          .count()
          .get();
      return snapshot.count ?? 0;
    } catch (e) {
      debugPrint('Error getting collection count: $e');
      return 0;
    }
  }

  /// Cleanup - close streams
  void dispose() {
    _connectionStateController.close();
  }
}
