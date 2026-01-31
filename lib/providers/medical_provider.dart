// lib/providers/medical_provider.dart
// Medical Provider using Firestore as the single source of truth
// All data synced globally across devices
// OTP Authentication remains UNCHANGED

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/medical_record.dart';

class MedicalProvider extends ChangeNotifier {
  List<MedicalRecord> _medicalRecords = [];
  bool _isLoading = false;
  String? _error;

  List<MedicalRecord> get medicalRecords => _medicalRecords;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Firestore instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ========== LOAD DATA ==========

  Future<void> loadMedicalRecords({int? doctorId}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      Query<Map<String, dynamic>> query = _firestore.collection(
        'medical_records',
      );

      if (doctorId != null) {
        query = query.where('doctorId', isEqualTo: doctorId.toString());
      }

      final snapshot = await query.orderBy('date', descending: true).get();

      _medicalRecords = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = int.tryParse(doc.id) ?? doc.id.hashCode;
        return MedicalRecord.fromMap(data);
      }).toList();
    } catch (e) {
      debugPrint('Error loading medical records: $e');
      _error = 'Error loading medical records: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMedicalRecordsByPet(int petId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final snapshot = await _firestore
          .collection('medical_records')
          .where('petId', isEqualTo: petId.toString())
          .orderBy('date', descending: true)
          .get();

      final seenIds = <int>{};
      _medicalRecords = snapshot.docs
          .map((doc) {
            final data = doc.data();
            final id = int.tryParse(doc.id) ?? doc.id.hashCode;
            data['id'] = id;
            final record = MedicalRecord.fromMap(data);
            if (!seenIds.contains(record.id)) {
              seenIds.add(record.id!);
              return record;
            }
            return record;
          })
          .where((record) => record.id != null)
          .toList();
    } catch (e) {
      debugPrint('Error loading medical records by pet: $e');
      _error = 'Error loading medical records: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ========== ADD RECORD ==========

  Future<bool> addMedicalRecord(MedicalRecord record) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Add to Firestore
      final docRef = await _firestore.collection('medical_records').add({
        'petId': record.petId.toString(),
        'doctorId': record.doctorId.toString(),
        'diagnosis': record.diagnosis,
        'treatment': record.treatment,
        'prescription': record.prescription,
        'notes': record.notes,
        'date': record.date,
        'attachments': record.attachments,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Update with document ID
      await docRef.update({'id': docRef.id});

      // Create local record object
      final newRecord = record.copyWith(
        id: int.tryParse(docRef.id) ?? docRef.id.hashCode,
      );

      _medicalRecords.add(newRecord);
      notifyListeners();

      return true;
    } catch (e) {
      debugPrint('Error adding medical record: $e');
      _error = 'Error adding medical record: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ========== UPDATE RECORD ==========

  Future<bool> updateMedicalRecord(MedicalRecord record) async {
    if (record.id == null) return false;

    try {
      // Find and update in Firestore
      final snapshot = await _firestore.collection('medical_records').get();

      String? docId;
      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (int.tryParse(doc.id) == record.id || doc.id.hashCode == record.id) {
          docId = doc.id;
          break;
        }
      }

      if (docId != null) {
        await _firestore.collection('medical_records').doc(docId).update({
          'diagnosis': record.diagnosis,
          'treatment': record.treatment,
          'prescription': record.prescription,
          'notes': record.notes,
          'date': record.date,
          'attachments': record.attachments,
        });
      }

      final index = _medicalRecords.indexWhere((r) => r.id == record.id);
      if (index != -1) {
        _medicalRecords[index] = record;
        notifyListeners();
      }

      return true;
    } catch (e) {
      debugPrint('Error updating medical record: $e');
      return false;
    }
  }

  // ========== DELETE RECORD ==========

  Future<bool> deleteMedicalRecord(int id) async {
    try {
      // Find and delete from Firestore
      final snapshot = await _firestore.collection('medical_records').get();

      String? docId;
      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (int.tryParse(doc.id) == id || doc.id.hashCode == id) {
          docId = doc.id;
          break;
        }
      }

      if (docId != null) {
        await _firestore.collection('medical_records').doc(docId).delete();
      }

      _medicalRecords.removeWhere((record) => record.id == id);
      notifyListeners();

      return true;
    } catch (e) {
      debugPrint('Error deleting medical record: $e');
      return false;
    }
  }

  // ========== HELPERS ==========

  List<MedicalRecord> getMedicalRecordsByPet(int petId) {
    return _medicalRecords
        .where((record) => record.petId.toString() == petId.toString())
        .toList();
  }

  MedicalRecord? getMedicalRecordById(int id) {
    try {
      return _medicalRecords.firstWhere((r) => r.id == id);
    } catch (e) {
      return null;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
