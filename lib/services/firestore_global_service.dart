// lib/services/firestore_global_service.dart
// Comprehensive Firestore Global Service
// ALL app data stored in Firestore - single source of truth
// Compatible with Flutter Web and Mobile
// OTP Authentication flow remains UNCHANGED

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show debugPrint;

import '../models/user_model.dart';
import '../models/pet.dart';
import '../models/appointment.dart';
import '../models/medical_record.dart';

/// Firestore Global Service - Single Source of Truth
/// All data stored in Firestore, synced across all devices
/// OTP Authentication is SEPARATE and completely untouched
class FirestoreGlobalService {
  // Singleton
  static final FirestoreGlobalService instance = FirestoreGlobalService._init();
  FirestoreGlobalService._init();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ========== COLLECTION REFERENCES ==========

  // Root collections (not user-scoped)
  CollectionReference<Map<String, dynamic>> get usersCollection =>
      _firestore.collection('users');
  CollectionReference<Map<String, dynamic>> get petsCollection =>
      _firestore.collection('pets');
  CollectionReference<Map<String, dynamic>> get appointmentsCollection =>
      _firestore.collection('appointments');
  CollectionReference<Map<String, dynamic>> get medicalRecordsCollection =>
      _firestore.collection('medical_records');
  CollectionReference<Map<String, dynamic>> get paymentsCollection =>
      _firestore.collection('payments');
  CollectionReference<Map<String, dynamic>> get notificationsCollection =>
      _firestore.collection('notifications');
  CollectionReference<Map<String, dynamic>> get serviceRequestsCollection =>
      _firestore.collection('service_requests');
  CollectionReference<Map<String, dynamic>> get auditLogsCollection =>
      _firestore.collection('audit_logs');
  CollectionReference<Map<String, dynamic>> get vansCollection =>
      _firestore.collection('vans');
  CollectionReference<Map<String, dynamic>> get schedulesCollection =>
      _firestore.collection('schedules');
  CollectionReference<Map<String, dynamic>> get documentsCollection =>
      _firestore.collection('documents');
  CollectionReference<Map<String, dynamic>> get driverStatusCollection =>
      _firestore.collection('driver_status');

  // ========== AUTH HELPERS ==========

  /// Get current authenticated user ID
  /// Returns null if not logged in
  String? get currentUserId => _auth.currentUser?.uid;

  /// Get current user role from Firestore
  Future<UserRole?> getCurrentUserRole() async {
    final uid = currentUserId;
    if (uid == null) return null;

    try {
      final doc = await usersCollection.doc(uid).get();
      if (doc.exists) {
        final roleStr = doc.data()?['role'] as String?;
        return _parseRole(roleStr);
      }
    } catch (e) {
      debugPrint('Error getting user role: $e');
    }
    return null;
  }

  /// Check if user is admin
  Future<bool> isAdmin() async {
    final role = await getCurrentUserRole();
    return role == UserRole.admin;
  }

  // ========== USER OPERATIONS ==========

  /// Create or update user profile in Firestore
  /// Called AFTER successful OTP verification
  Future<void> saveUserProfile(UserModel user) async {
    try {
      await usersCollection.doc(user.id).set({
        'id': user.id,
        'email': user.email.toLowerCase(),
        'name': user.name,
        'phone': user.phone,
        'role': user.role.toString().split('.').last,
        'area': user.area,
        'profileImage': user.profileImage,
        'verificationStatus': user.verificationStatus,
        'linkedDoctorId': user.linkedDoctorId,
        'linkedDriverId': user.linkedDriverId,
        'availabilityStatus': user.availabilityStatus ?? 'offline',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      debugPrint('User profile saved to Firestore: ${user.id}');
    } catch (e) {
      debugPrint('Error saving user profile: $e');
      rethrow;
    }
  }

  /// Get user profile by ID
  Future<UserModel?> getUserProfile(String uid) async {
    try {
      final doc = await usersCollection.doc(uid).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting user profile: $e');
      return null;
    }
  }

  /// Stream user profile changes
  Stream<UserModel?> streamUserProfile(String uid) {
    return usersCollection.doc(uid).snapshots().map((doc) {
      if (doc.exists) {
        return UserModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    });
  }

  /// Get all doctors
  Future<List<UserModel>> getDoctors() async {
    try {
      final snapshot = await usersCollection
          .where('role', isEqualTo: 'doctor')
          .where('verificationStatus', isEqualTo: 'verified')
          .get();
      return snapshot.docs
          .map((doc) => UserModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      debugPrint('Error getting doctors: $e');
      return [];
    }
  }

  /// Get all drivers
  Future<List<UserModel>> getDrivers() async {
    try {
      final snapshot = await usersCollection
          .where('role', isEqualTo: 'driver')
          .where('verificationStatus', isEqualTo: 'verified')
          .get();
      return snapshot.docs
          .map((doc) => UserModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      debugPrint('Error getting drivers: $e');
      return [];
    }
  }

  // ========== PET OPERATIONS ==========

  /// Add a new pet
  Future<String> addPet(Pet pet, String ownerId) async {
    try {
      final docRef = await petsCollection.add({
        'ownerId': ownerId,
        'name': pet.name,
        'species': pet.species,
        'breed': pet.breed,
        'dob': pet.dob,
        'notes': pet.notes,
        'medicalHistorySummary': pet.medicalHistorySummary,
        'vaccinationStatus': pet.vaccinationStatus,
        'photoPath': pet.photoPath,
        'serialNumber': pet.serialNumber,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await docRef.update({'id': docRef.id});
      debugPrint('Pet added: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('Error adding pet: $e');
      rethrow;
    }
  }

  /// Get pet by ID
  Future<Pet?> getPet(String petId) async {
    try {
      final doc = await petsCollection.doc(petId).get();
      if (doc.exists) {
        return _parsePetFromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting pet: $e');
      return null;
    }
  }

  /// Stream owner's pets
  Stream<List<Pet>> streamPetsByOwner(String ownerId) {
    return petsCollection
        .where('ownerId', isEqualTo: ownerId)
        .orderBy('name')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => _parsePetFromMap(doc.data()!))
              .toList();
        });
  }

  /// Update pet
  Future<void> updatePet(String petId, Map<String, dynamic> data) async {
    try {
      data['updatedAt'] = FieldValue.serverTimestamp();
      await petsCollection.doc(petId).update(data);
      debugPrint('Pet updated: $petId');
    } catch (e) {
      debugPrint('Error updating pet: $e');
      rethrow;
    }
  }

  /// Delete pet
  Future<void> deletePet(String petId) async {
    try {
      await petsCollection.doc(petId).delete();
      debugPrint('Pet deleted: $petId');
    } catch (e) {
      debugPrint('Error deleting pet: $e');
      rethrow;
    }
  }

  // ========== APPOINTMENT OPERATIONS ==========

  /// Add a new appointment
  Future<String> addAppointment(Appointment appointment) async {
    try {
      final docRef = await appointmentsCollection.add({
        'ownerId': appointment.ownerId.toString(),
        'petId': appointment.petId.toString(),
        'serviceType': appointment.serviceType,
        'description': appointment.description,
        'scheduledAt': appointment.scheduledAt,
        'status': appointment.status,
        'address': appointment.address,
        'price': appointment.price,
        'doctorId': appointment.doctorId?.toString(),
        'driverId': appointment.driverId?.toString(),
        'urgencyLevel': appointment.urgencyLevel,
        'locationLat': appointment.locationLat,
        'locationLng': appointment.locationLng,
        'calendarEventId': appointment.calendarEventId,
        'paymentMethod': appointment.paymentMethod,
        'serviceRequestId': appointment.serviceRequestId?.toString(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await docRef.update({'id': docRef.id});
      debugPrint('Appointment added: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('Error adding appointment: $e');
      rethrow;
    }
  }

  /// Get appointment by ID
  Future<Appointment?> getAppointment(String appointmentId) async {
    try {
      final doc = await appointmentsCollection.doc(appointmentId).get();
      if (doc.exists) {
        return _parseAppointmentFromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting appointment: $e');
      return null;
    }
  }

  /// Stream owner's appointments
  Stream<List<Appointment>> streamAppointmentsByOwner(String ownerId) {
    return appointmentsCollection
        .where('ownerId', isEqualTo: ownerId)
        .orderBy('scheduledAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => _parseAppointmentFromMap(doc.data()!))
              .toList();
        });
  }

  /// Update appointment
  Future<void> updateAppointment(
    String appointmentId,
    Map<String, dynamic> data,
  ) async {
    try {
      data['updatedAt'] = FieldValue.serverTimestamp();
      await appointmentsCollection.doc(appointmentId).update(data);
      debugPrint('Appointment updated: $appointmentId');
    } catch (e) {
      debugPrint('Error updating appointment: $e');
      rethrow;
    }
  }

  /// Update appointment status
  Future<void> updateAppointmentStatus(
    String appointmentId,
    String status,
  ) async {
    await updateAppointment(appointmentId, {'status': status});
  }

  /// Delete appointment
  Future<void> deleteAppointment(String appointmentId) async {
    try {
      await appointmentsCollection.doc(appointmentId).delete();
      debugPrint('Appointment deleted: $appointmentId');
    } catch (e) {
      debugPrint('Error deleting appointment: $e');
      rethrow;
    }
  }

  // ========== MEDICAL RECORD OPERATIONS ==========

  /// Add medical record
  Future<String> addMedicalRecord(MedicalRecord record) async {
    try {
      final docRef = await medicalRecordsCollection.add({
        'petId': record.petId.toString(),
        'doctorId': record.doctorId.toString(),
        'diagnosis': record.diagnosis,
        'treatment': record.treatment,
        'prescription': record.prescription,
        'notes': record.notes,
        'date': record.date,
        'attachments': record.attachments,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await docRef.update({'id': docRef.id});
      debugPrint('Medical record added: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('Error adding medical record: $e');
      rethrow;
    }
  }

  /// Stream medical records by pet
  Stream<List<MedicalRecord>> streamMedicalRecordsByPet(String petId) {
    return medicalRecordsCollection
        .where('petId', isEqualTo: petId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => _parseMedicalRecordFromMap(doc.data()!))
              .toList();
        });
  }

  // ========== NOTIFICATION OPERATIONS ==========

  /// Add notification
  Future<String> addNotification(Map<String, dynamic> data) async {
    try {
      final docRef = await notificationsCollection.add({
        ...data,
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
      });
      await docRef.update({'id': docRef.id});
      return docRef.id;
    } catch (e) {
      debugPrint('Error adding notification: $e');
      rethrow;
    }
  }

  /// Stream user notifications
  Stream<List<Map<String, dynamic>>> streamNotifications(String userId) {
    return notificationsCollection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          }).toList();
        });
  }

  /// Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    await notificationsCollection.doc(notificationId).update({'isRead': true});
  }

  // ========== AUDIT LOG OPERATIONS ==========

  /// Log audit action
  Future<void> logAuditAction({
    required String action,
    required String details,
    String? userId,
    String? ipAddress,
  }) async {
    try {
      await auditLogsCollection.add({
        'action': action,
        'details': details,
        'userId': userId,
        'ipAddress': ipAddress,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error logging audit action: $e');
    }
  }

  // ========== PARSING HELPERS ==========

  /// Convert dynamic value to int
  int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  Pet _parsePetFromMap(Map<String, dynamic> data) {
    return Pet(
      id: null,
      ownerId: _parseInt(data['ownerId']),
      name: data['name'] ?? '',
      species: data['species'] ?? '',
      breed: data['breed'],
      dob: data['dob'],
      notes: data['notes'],
      medicalHistorySummary: data['medicalHistorySummary'],
      vaccinationStatus: data['vaccinationStatus'],
      photoPath: data['photoPath'],
      serialNumber: data['serialNumber'] ?? '',
    );
  }

  Appointment _parseAppointmentFromMap(Map<String, dynamic> data) {
    return Appointment(
      id: null,
      ownerId: _parseInt(data['ownerId']),
      petId: _parseInt(data['petId']),
      serviceType: data['serviceType'] ?? '',
      description: data['description'],
      scheduledAt: data['scheduledAt'] ?? '',
      status: data['status'] ?? 'pending',
      address: data['address'],
      price: data['price']?.toDouble(),
      doctorId: data['doctorId'] != null ? _parseInt(data['doctorId']) : null,
      driverId: data['driverId'] != null ? _parseInt(data['driverId']) : null,
      urgencyLevel: data['urgencyLevel'] ?? 'routine',
      locationLat: data['locationLat']?.toDouble(),
      locationLng: data['locationLng']?.toDouble(),
      calendarEventId: data['calendarEventId'],
      paymentMethod: data['paymentMethod'],
      serviceRequestId: data['serviceRequestId'] != null
          ? _parseInt(data['serviceRequestId'])
          : null,
    );
  }

  MedicalRecord _parseMedicalRecordFromMap(Map<String, dynamic> data) {
    return MedicalRecord(
      id: null,
      petId: _parseInt(data['petId']),
      doctorId: _parseInt(data['doctorId']),
      diagnosis: data['diagnosis'] ?? '',
      treatment: data['treatment'] ?? '',
      prescription: data['prescription'],
      notes: data['notes'],
      date: data['date'] ?? '',
      attachments: data['attachments'] != null
          ? List<String>.from(data['attachments'])
          : null,
    );
  }

  UserRole _parseRole(String? roleStr) {
    switch (roleStr?.toLowerCase()) {
      case 'doctor':
        return UserRole.doctor;
      case 'driver':
        return UserRole.driver;
      case 'admin':
        return UserRole.admin;
      case 'owner':
      default:
        return UserRole.owner;
    }
  }

  // ========== DISPOSE ==========

  void dispose() {
    // Close any streams if needed
  }
}
