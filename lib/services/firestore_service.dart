// lib/services/firestore_service.dart
// Firestore Service for User Data Synchronization
// This enables real-time data sharing across all devices

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../models/user.dart';

class FirestoreService {
  static final FirestoreService instance = FirestoreService._init();
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  FirestoreService._init();

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

  /// Create or update user in Firestore
  Future<void> createOrUpdateUser(User user) async {
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

      print('✅ User synced to Firestore: ${user.email}');
    } catch (e) {
      print('❌ Error syncing user to Firestore: $e');
      rethrow;
    }
  }

  /// Get user by email from Firestore
  Future<User?> getUserByEmail(String email) async {
    try {
      final emailKey = email.toLowerCase().replaceAll('.', '_');
      final doc = await usersCollection.doc(emailKey).get();

      if (doc.exists) {
        return User.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('❌ Error getting user from Firestore: $e');
      return null;
    }
  }

  /// Get all users from Firestore
  Future<List<User>> getAllUsers() async {
    try {
      final snapshot = await usersCollection.get();
      return snapshot.docs
          .map((doc) => User.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ Error getting all users from Firestore: $e');
      return [];
    }
  }

  /// Get users by role
  Future<List<User>> getUsersByRole(String role) async {
    try {
      final snapshot = await usersCollection
          .where('role', isEqualTo: role)
          .get();
      return snapshot.docs
          .map((doc) => User.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ Error getting users by role from Firestore: $e');
      return [];
    }
  }

  /// Update user in Firestore
  Future<void> updateUser(String email, Map<String, dynamic> data) async {
    try {
      final emailKey = email.toLowerCase().replaceAll('.', '_');
      data['updatedAt'] = FieldValue.serverTimestamp();
      await usersCollection.doc(emailKey).update(data);
      print('✅ User updated in Firestore: $email');
    } catch (e) {
      print('❌ Error updating user in Firestore: $e');
      rethrow;
    }
  }

  /// Delete user from Firestore
  Future<void> deleteUser(String email) async {
    try {
      final emailKey = email.toLowerCase().replaceAll('.', '_');
      await usersCollection.doc(emailKey).delete();
      print('✅ User deleted from Firestore: $email');
    } catch (e) {
      print('❌ Error deleting user from Firestore: $e');
      rethrow;
    }
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
  Future<void> updateUserStatus(String email, String status) async {
    try {
      final emailKey = email.toLowerCase().replaceAll('.', '_');
      await usersCollection.doc(emailKey).update({
        'availabilityStatus': status,
        'lastSeen': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('❌ Error updating user status: $e');
    }
  }

  // ========== APPOINTMENT OPERATIONS ==========

  Future<void> createAppointment(Map<String, dynamic> data) async {
    try {
      final docRef = await appointmentsCollection.add(data);
      await docRef.update({'id': docRef.id});
      print('✅ Appointment created in Firestore');
    } catch (e) {
      print('❌ Error creating appointment in Firestore: $e');
      rethrow;
    }
  }

  Future<void> updateAppointment(String id, Map<String, dynamic> data) async {
    try {
      data['updatedAt'] = FieldValue.serverTimestamp();
      await appointmentsCollection.doc(id).update(data);
      print('✅ Appointment updated in Firestore');
    } catch (e) {
      print('❌ Error updating appointment in Firestore: $e');
      rethrow;
    }
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

  Future<void> createNotification(Map<String, dynamic> data) async {
    try {
      final docRef = await notificationsCollection.add(data);
      await docRef.update({'id': docRef.id});
    } catch (e) {
      print('❌ Error creating notification in Firestore: $e');
      rethrow;
    }
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

  Future<void> logAuditAction(
    String action,
    String details, {
    String? userId,
  }) async {
    try {
      await auditLogsCollection.add({
        'action': action,
        'details': details,
        'userId': userId,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('❌ Error logging audit action: $e');
    }
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
  Future<void> syncAllUsersToCloud(List<User> users) async {
    int successCount = 0;
    for (final user in users) {
      try {
        await createOrUpdateUser(user);
        successCount++;
      } catch (e) {
        print('❌ Error syncing user ${user.email}: $e');
      }
    }
    print('✅ Synced $successCount/${users.length} users to Firestore');
  }

  // ========== SYNC FROM CLOUD TO LOCAL ==========

  /// Get all users from cloud for local storage
  Future<List<User>> fetchAllUsersFromCloud() async {
    return await getAllUsers();
  }

  // ========== DATA STATISTICS ==========

  Future<Map<String, int>> getUserStats() async {
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

      return {
        'total': totalSnapshot.count ?? 0,
        'owners': ownerSnapshot.count ?? 0,
        'doctors': doctorSnapshot.count ?? 0,
        'drivers': driverSnapshot.count ?? 0,
        'admins': adminSnapshot.count ?? 0,
      };
    } catch (e) {
      print('❌ Error getting user stats: $e');
      return {'total': 0, 'owners': 0, 'doctors': 0, 'drivers': 0, 'admins': 0};
    }
  }
}
