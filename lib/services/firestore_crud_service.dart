// lib/services/firestore_crud_service.dart
// Generic Firestore CRUD Service
// All data stored under users/{uid}/collections/{autoId}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Generic CRUD result
class CrudResult<T> {
  final T? data;
  final String? error;
  final bool success;

  CrudResult({this.data, this.error, this.success = true});

  factory CrudResult.success(T data) => CrudResult(data: data);
  factory CrudResult.error(String error) =>
      CrudResult(error: error, success: false);
}

/// Firestore CRUD Service
/// All data is stored at: users/{userId}/{collection}/{docId}
/// Document IDs are auto-generated (no hardcoding)
class FirestoreCrudService {
  // Singleton
  static final FirestoreCrudService instance = FirestoreCrudService._init();
  FirestoreCrudService._init();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get a reference to a subcollection
  // Path: users/{userId}/{collection}
  CollectionReference<Map<String, dynamic>> _getCollectionRef(
    String userId,
    String collection,
  ) {
    return _firestore.collection('users/$userId/$collection');
  }

  // ========== CREATE ==========

  /// Add a document to a user's collection
  /// Path: users/{userId}/{collection}
  /// Document ID is auto-generated
  Future<CrudResult<String>> create({
    required String userId,
    required String collection, // e.g., 'pets', 'appointments'
    required Map<String, dynamic> data,
  }) async {
    try {
      if (userId.isEmpty) {
        return CrudResult.error('User ID is required');
      }

      // Always link data to the user
      final docData = <String, dynamic>{
        'userId': userId,
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      };
      docData.addAll(data);

      final docRef = await _getCollectionRef(userId, collection).add(docData);

      debugPrint('Created document in $collection: ${docRef.id}');
      return CrudResult.success(docRef.id);
    } catch (e) {
      debugPrint('Error creating document: $e');
      return CrudResult.error('Failed to create: $e');
    }
  }

  // ========== READ ==========

  /// Get a single document by ID
  Future<CrudResult<Map<String, dynamic>>> read({
    required String userId,
    required String collection,
    required String docId,
  }) async {
    try {
      final doc = await _getCollectionRef(userId, collection).doc(docId).get();

      if (!doc.exists) {
        return CrudResult.error('Document not found');
      }

      return CrudResult.success(doc.data()!);
    } catch (e) {
      debugPrint('Error reading document: $e');
      return CrudResult.error('Failed to read: $e');
    }
  }

  /// Get all documents in a collection for a user
  Future<CrudResult<List<Map<String, dynamic>>>> readAll({
    required String userId,
    required String collection,
    String? orderBy,
    bool descending = false,
    int? limit,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _getCollectionRef(userId, collection);

      if (orderBy != null) {
        query = query.orderBy(orderBy, descending: descending);
      }

      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();
      final docs = <Map<String, dynamic>>[];
      for (final doc in snapshot.docs) {
        final docData = doc.data();
        docData['id'] = doc.id;
        docs.add(docData);
      }

      debugPrint('Read ${docs.length} documents from $collection');
      return CrudResult.success(docs);
    } catch (e) {
      debugPrint('Error reading documents: $e');
      return CrudResult.error('Failed to read: $e');
    }
  }

  /// Get real-time stream of all documents in a collection
  Stream<List<Map<String, dynamic>>> streamAll({
    required String userId,
    required String collection,
    String? orderBy,
    bool descending = false,
  }) {
    Query<Map<String, dynamic>> query = _getCollectionRef(userId, collection);

    if (orderBy != null) {
      query = query.orderBy(orderBy, descending: descending);
    }

    return query.snapshots().map((snapshot) {
      final docs = <Map<String, dynamic>>[];
      for (final doc in snapshot.docs) {
        final docData = doc.data();
        docData['id'] = doc.id;
        docs.add(docData);
      }
      return docs;
    });
  }

  /// Query documents with conditions
  Future<CrudResult<List<Map<String, dynamic>>>> query({
    required String userId,
    required String collection,
    required String field,
    required dynamic value,
    String? orderBy,
    bool descending = false,
    int? limit,
  }) async {
    try {
      Query<Map<String, dynamic>> queryRef = _getCollectionRef(
        userId,
        collection,
      ).where(field, isEqualTo: value);

      if (orderBy != null) {
        queryRef = queryRef.orderBy(orderBy, descending: descending);
      }

      if (limit != null) {
        queryRef = queryRef.limit(limit);
      }

      final snapshot = await queryRef.get();
      final docs = <Map<String, dynamic>>[];
      for (final doc in snapshot.docs) {
        final docData = doc.data();
        docData['id'] = doc.id;
        docs.add(docData);
      }

      return CrudResult.success(docs);
    } catch (e) {
      debugPrint('Error querying documents: $e');
      return CrudResult.error('Failed to query: $e');
    }
  }

  // ========== UPDATE ==========

  /// Update a document
  Future<CrudResult<void>> update({
    required String userId,
    required String collection,
    required String docId,
    required Map<String, dynamic> data,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updatedAt': DateTime.now().toIso8601String(),
      };
      updateData.addAll(data);

      await _getCollectionRef(userId, collection).doc(docId).update(updateData);

      debugPrint('Updated document in $collection: $docId');
      return CrudResult.success(null);
    } catch (e) {
      debugPrint('Error updating document: $e');
      return CrudResult.error('Failed to update: $e');
    }
  }

  // ========== DELETE ==========

  /// Delete a document
  Future<CrudResult<void>> delete({
    required String userId,
    required String collection,
    required String docId,
  }) async {
    try {
      await _getCollectionRef(userId, collection).doc(docId).delete();

      debugPrint('Deleted document from $collection: $docId');
      return CrudResult.success(null);
    } catch (e) {
      debugPrint('Error deleting document: $e');
      return CrudResult.error('Failed to delete: $e');
    }
  }

  // ========== COUNT ==========

  /// Count documents in a collection
  Future<CrudResult<int>> count({
    required String userId,
    required String collection,
  }) async {
    try {
      final snapshot = await _getCollectionRef(
        userId,
        collection,
      ).count().get();

      return CrudResult.success(snapshot.count ?? 0);
    } catch (e) {
      debugPrint('Error counting documents: $e');
      return CrudResult.error('Failed to count: $e');
    }
  }

  // ========== SPECIALIZED METHODS FOR PETS ==========

  /// Add a pet for a user
  Future<CrudResult<String>> addPet({
    required String userId,
    required String name,
    required String species,
    String? breed,
    DateTime? dob,
    String? notes,
    String? photoUrl,
  }) async {
    return create(
      userId: userId,
      collection: 'pets',
      data: {
        'name': name,
        'species': species,
        'breed': breed,
        'dob': dob?.toIso8601String(),
        'notes': notes,
        'photoUrl': photoUrl,
      },
    );
  }

  /// Get all pets for a user
  Future<CrudResult<List<Map<String, dynamic>>>> getPets({
    required String userId,
  }) async {
    return readAll(userId: userId, collection: 'pets', orderBy: 'name');
  }

  /// Stream all pets for a user
  Stream<List<Map<String, dynamic>>> streamPets(String userId) {
    return streamAll(userId: userId, collection: 'pets', orderBy: 'name');
  }

  // ========== SPECIALIZED METHODS FOR APPOINTMENTS ==========

  /// Add an appointment for a user
  Future<CrudResult<String>> addAppointment({
    required String userId,
    required String petId,
    required String serviceType,
    required DateTime scheduledAt,
    String? description,
    String? address,
    double? price,
    String? doctorId,
    String? driverId,
  }) async {
    return create(
      userId: userId,
      collection: 'appointments',
      data: {
        'petId': petId,
        'serviceType': serviceType,
        'scheduledAt': scheduledAt.toIso8601String(),
        'status': 'pending',
        'description': description,
        'address': address,
        'price': price,
        'doctorId': doctorId,
        'driverId': driverId,
      },
    );
  }

  /// Get all appointments for a user
  Future<CrudResult<List<Map<String, dynamic>>>> getAppointments({
    required String userId,
    String? status,
  }) async {
    if (status != null) {
      return query(
        userId: userId,
        collection: 'appointments',
        field: 'status',
        value: status,
        orderBy: 'scheduledAt',
      );
    }
    return readAll(
      userId: userId,
      collection: 'appointments',
      orderBy: 'scheduledAt',
      descending: true,
    );
  }

  /// Stream appointments for a user
  Stream<List<Map<String, dynamic>>> streamAppointments(String userId) {
    return streamAll(
      userId: userId,
      collection: 'appointments',
      orderBy: 'scheduledAt',
      descending: true,
    );
  }

  // ========== SPECIALIZED METHODS FOR MEDICAL RECORDS ==========

  /// Add a medical record for a user
  Future<CrudResult<String>> addMedicalRecord({
    required String userId,
    required String petId,
    required String diagnosis,
    String? treatment,
    String? prescription,
    String? notes,
    DateTime? date,
  }) async {
    return create(
      userId: userId,
      collection: 'medical_records',
      data: {
        'petId': petId,
        'diagnosis': diagnosis,
        'treatment': treatment,
        'prescription': prescription,
        'notes': notes,
        'date': (date ?? DateTime.now()).toIso8601String(),
      },
    );
  }

  /// Get all medical records for a user
  Future<CrudResult<List<Map<String, dynamic>>>> getMedicalRecords({
    required String userId,
    String? petId,
  }) async {
    if (petId != null) {
      return query(
        userId: userId,
        collection: 'medical_records',
        field: 'petId',
        value: petId,
        orderBy: 'date',
        descending: true,
      );
    }
    return readAll(
      userId: userId,
      collection: 'medical_records',
      orderBy: 'date',
      descending: true,
    );
  }

  /// Stream medical records for a user
  Stream<List<Map<String, dynamic>>> streamMedicalRecords(String userId) {
    return streamAll(
      userId: userId,
      collection: 'medical_records',
      orderBy: 'date',
      descending: true,
    );
  }
}
