// lib/providers/pet_provider.dart
import 'package:flutter/material.dart';
import '../db/db_helper.dart';
import '../models/pet.dart';
import '../models/medical_record.dart';

class PetProvider extends ChangeNotifier {
  List<Pet> _pets = [];
  List<MedicalRecord> _medicalRecords = [];
  bool _isLoading = false;

  List<Pet> get pets => _pets;
  List<MedicalRecord> get medicalRecords => _medicalRecords;
  bool get isLoading => _isLoading;

  Future<void> loadPets({int? ownerId}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = ownerId != null
          ? await DBHelper.instance.getPetsByOwner(ownerId)
          : []; // TODO: Implement getAllPets if needed
      _pets = data.map((item) => Pet.fromMap(item)).toList();
    } catch (e) {
      debugPrint('Error loading pets: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMedicalRecords(int petId) async {
    try {
      final data = await DBHelper.instance.getMedicalRecordsByPet(petId);
      _medicalRecords = data
          .map((item) => MedicalRecord.fromMap(item))
          .toList();
    } catch (e) {
      debugPrint('Error loading medical records: $e');
    }
    notifyListeners();
  }

  Future<bool> addPet(Pet pet) async {
    try {
      final id = await DBHelper.instance.insertPet(pet.toMap());
      final newPet = pet.copyWith(id: id);
      _pets.add(newPet);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error adding pet: $e');
      return false;
    }
  }

  Future<bool> updatePet(Pet pet) async {
    if (pet.id == null) return false;

    try {
      await DBHelper.instance.updatePet(pet.id!, pet.toMap());
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

  Future<bool> deletePet(int id) async {
    try {
      await DBHelper.instance.deletePet(id);
      _pets.removeWhere((pet) => pet.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error deleting pet: $e');
      return false;
    }
  }

  Future<bool> addMedicalRecord(MedicalRecord record) async {
    try {
      final id = await DBHelper.instance.insertMedicalRecord(record.toMap());
      final newRecord = record.copyWith(id: id);
      _medicalRecords.add(newRecord);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error adding medical record: $e');
      return false;
    }
  }

  Pet? getPetById(int id) {
    return _pets.firstWhere((pet) => pet.id == id);
  }

  List<Pet> getPetsByOwner(int ownerId) {
    return _pets.where((pet) => pet.ownerId == ownerId).toList();
  }

  List<MedicalRecord> getMedicalRecordsByPet(int petId) {
    return _medicalRecords.where((record) => record.petId == petId).toList();
  }
}
