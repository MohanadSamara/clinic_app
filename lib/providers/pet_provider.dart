// lib/providers/pet_provider.dart
// Pet Provider using Firestore as the single source of truth
// Maintains backward compatibility with int parameters
// All data synced globally across devices

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/pet.dart';
import '../models/medical_record.dart';

class PetProvider extends ChangeNotifier {
  List<Pet> _pets = [];
  List<MedicalRecord> _medicalRecords = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Pet> get pets => _pets;
  List<MedicalRecord> get medicalRecords => _medicalRecords;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Firestore instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ========== LOAD DATA ==========

  Future<void> loadPets({int? ownerId}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      Query<Map<String, dynamic>> query = _firestore
          .collection('pets')
          .orderBy('name');

      if (ownerId != null) {
        query = query.where('ownerId', isEqualTo: ownerId.toString());
      }

      final snapshot = await query.get();

      _pets = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = int.tryParse(doc.id) ?? doc.id.hashCode;
        return Pet.fromMap(data);
      }).toList();
    } catch (e) {
      _error = 'Error loading pets: $e';
      debugPrint('Error loading pets: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadPetsByDoctor(int doctorId) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Get all pets - in production you might want a more specific query
      final snapshot = await _firestore.collection('pets').get();

      _pets = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = int.tryParse(doc.id) ?? doc.id.hashCode;
        return Pet.fromMap(data);
      }).toList();
    } catch (e) {
      debugPrint('Error loading pets by doctor: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadPetsByLinkedDoctor(int doctorId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final snapshot = await _firestore.collection('pets').get();

      _pets = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = int.tryParse(doc.id) ?? doc.id.hashCode;
        return Pet.fromMap(data);
      }).toList();
    } catch (e) {
      debugPrint('Error loading pets by linked doctor: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMedicalRecords(int petId) async {
    try {
      final snapshot = await _firestore
          .collection('medical_records')
          .where('petId', isEqualTo: petId.toString())
          .orderBy('date', descending: true)
          .get();

      _medicalRecords = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = int.tryParse(doc.id) ?? doc.id.hashCode;
        return MedicalRecord.fromMap(data);
      }).toList();
    } catch (e) {
      debugPrint('Error loading medical records: $e');
    }
    notifyListeners();
  }

  // ========== ADD PET ==========

  Future<bool> addPet(Pet pet, {int? doctorId}) async {
    try {
      // Add to Firestore
      final docRef = await _firestore.collection('pets').add({
        'ownerId': pet.ownerId.toString(),
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

      // Get the generated ID and create a local Pet object
      final newPet = pet.copyWith(
        id: int.tryParse(docRef.id.hashCode.toString()) ?? docRef.id.hashCode,
      );

      _pets.add(newPet);
      notifyListeners();

      // Create initial medical record if doctor is linked
      if (doctorId != null) {
        final initialRecord = MedicalRecord(
          petId: newPet.id!,
          doctorId: doctorId,
          diagnosis: 'Initial checkup',
          treatment: 'Pet registered in system',
          date: DateTime.now().toIso8601String().split('T')[0],
          notes: 'Initial medical record created upon pet registration',
        );
        await _firestore.collection('medical_records').add({
          'petId': newPet.id.toString(),
          'doctorId': doctorId.toString(),
          'diagnosis': initialRecord.diagnosis,
          'treatment': initialRecord.treatment,
          'prescription': initialRecord.prescription,
          'notes': initialRecord.notes,
          'date': initialRecord.date,
          'attachments': initialRecord.attachments,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      return true;
    } catch (e) {
      debugPrint('Error adding pet: $e');
      return false;
    }
  }

  // ========== UPDATE PET ==========

  Future<bool> updatePet(Pet pet) async {
    if (pet.id == null) return false;

    try {
      // Find the Firestore document by matching the id
      final snapshot = await _firestore
          .collection('pets')
          .where('ownerId', isEqualTo: pet.ownerId.toString())
          .get();

      String? docId;
      for (var doc in snapshot.docs) {
        final data = doc.data();
        // Match by serial number or other unique identifier
        if (data['serialNumber'] == pet.serialNumber ||
            data['name'] == pet.name) {
          docId = doc.id;
          break;
        }
      }

      if (docId != null) {
        await _firestore.collection('pets').doc(docId).update({
          'name': pet.name,
          'species': pet.species,
          'breed': pet.breed,
          'dob': pet.dob,
          'notes': pet.notes,
          'medicalHistorySummary': pet.medicalHistorySummary,
          'vaccinationStatus': pet.vaccinationStatus,
          'photoPath': pet.photoPath,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      final index = _pets.indexWhere((p) => p.id == pet.id);
      if (index != -1) {
        _pets[index] = pet;
        notifyListeners();
      }
      return true;
    } catch (e) {
      debugPrint('Error updating pet: $e');
      return false;
    }
  }

  // ========== DELETE PET ==========

  Future<bool> deletePet(int id) async {
    try {
      // Find the document in Firestore
      final snapshot = await _firestore.collection('pets').get();

      String? docId;
      for (var doc in snapshot.docs) {
        final data = doc.data();
        // Match by numeric id
        if (int.tryParse(doc.id) == id ||
            doc.id.hashCode == id ||
            data['serialNumber'] != null) {
          docId = doc.id;
          break;
        }
      }

      if (docId != null) {
        await _firestore.collection('pets').doc(docId).delete();
      }

      _pets.removeWhere((pet) => pet.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error deleting pet: $e');
      return false;
    }
  }

  // ========== MEDICAL RECORDS ==========

  Future<bool> addMedicalRecord(MedicalRecord record) async {
    try {
      await _firestore.collection('medical_records').add({
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

      _medicalRecords.add(record);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error adding medical record: $e');
      return false;
    }
  }

  // ========== HELPERS ==========

  Pet? getPetById(int id) {
    return _pets.firstWhere((pet) => pet.id == id);
  }

  List<Pet> getPetsByOwner(int ownerId) {
    return _pets.where((pet) => pet.ownerId == ownerId).toList();
  }

  List<MedicalRecord> getMedicalRecordsByPet(int petId) {
    return _medicalRecords.where((record) => record.petId == petId).toList();
  }

  Future<Pet?> getPetBySerialNumber(String serialNumber) async {
    try {
      final snapshot = await _firestore
          .collection('pets')
          .where('serialNumber', isEqualTo: serialNumber)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data();
        data['id'] =
            int.tryParse(snapshot.docs.first.id) ??
            snapshot.docs.first.id.hashCode;
        return Pet.fromMap(data);
      }
    } catch (e) {
      debugPrint('Error getting pet by serial number: $e');
    }
    return null;
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
