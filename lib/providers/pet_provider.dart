// lib/providers/pet_provider.dart
// Migrated to Supabase database (PostgreSQL) - 2026-01-31
// Uses String IDs for Supabase UUIDs

import 'package:flutter/material.dart';
import '../services/supabase_complete_service.dart';
import '../models/pet.dart';
import '../models/medical_record.dart';

/// PetProvider - Supabase Database Integration
///
/// Database: Supabase (PostgreSQL)
/// Tables used: pets, medical_records
///
/// All database operations now use Supabase client exclusively.
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

  // Supabase service instance for database operations (singleton)
  final SupabaseCompleteService _supabaseService =
      SupabaseCompleteService.instance;

  // ========== LOAD DATA ==========

  Future<void> loadPets({String? ownerId}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final pets = await _supabaseService.getPetsByOwner(ownerId ?? '');
      _pets = pets.map((data) => Pet.fromMap(data)).toList();
    } catch (e) {
      _error = 'Error loading pets: $e';
      debugPrint('Error loading pets: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadPetsByDoctor(String doctorId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final pets = await _supabaseService.getPetsByDoctor(doctorId);
      _pets = pets.map((data) => Pet.fromMap(data)).toList();
    } catch (e) {
      debugPrint('Error loading pets by doctor: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadPetsByLinkedDoctor(String doctorId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final pets = await _supabaseService.getPetsByLinkedDoctor(doctorId);
      _pets = pets.map((data) => Pet.fromMap(data)).toList();
    } catch (e) {
      debugPrint('Error loading pets by linked doctor: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMedicalRecords(String petId) async {
    try {
      final records = await _supabaseService.getMedicalRecords(petId: petId);
      _medicalRecords = records
          .map((data) => MedicalRecord.fromMap(data))
          .toList();
    } catch (e) {
      debugPrint('Error loading medical records: $e');
    }
    notifyListeners();
  }

  // ========== ADD PET ==========

  Future<bool> addPet(Pet pet, {String? doctorId}) async {
    try {
      // Add to Supabase
      final petData = pet.toMap();
      final id = await _supabaseService.insertPet(petData);

      // Create local Pet object with the UUID from Supabase
      final newPet = pet.copyWith(id: id);

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

        await _supabaseService.insertMedicalRecord(initialRecord.toMap());
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
      // Update in Supabase
      await _supabaseService.updatePet(pet.id!, pet.toMap());

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

  Future<bool> deletePet(String id) async {
    try {
      // Delete from Supabase
      await _supabaseService.deletePet(id);

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
      await _supabaseService.insertMedicalRecord(record.toMap());

      _medicalRecords.add(record);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error adding medical record: $e');
      return false;
    }
  }

  // ========== HELPERS ==========

  Pet? getPetById(String id) {
    return _pets.firstWhere((pet) => pet.id == id);
  }

  List<Pet> getPetsByOwner(String ownerId) {
    return _pets.where((pet) => pet.ownerId == ownerId).toList();
  }

  List<MedicalRecord> getMedicalRecordsByPet(String petId) {
    return _medicalRecords.where((record) => record.petId == petId).toList();
  }

  Future<Pet?> getPetBySerialNumber(String serialNumber) async {
    try {
      final pet = await _supabaseService.getPetBySerialNumber(serialNumber);
      if (pet != null) {
        return Pet.fromMap(pet);
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
