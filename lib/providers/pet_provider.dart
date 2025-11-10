// lib/providers/pet_provider.dart
import 'package:flutter/material.dart';
import '../db/db_helper.dart';
import '../models/pet.dart';
import '../models/medical_record.dart';
import '../models/vaccination_record.dart';
import '../models/document.dart';

class PetProvider extends ChangeNotifier {
  List<Pet> _pets = [];
  List<MedicalRecord> _medicalRecords = [];
  List<VaccinationRecord> _vaccinationRecords = [];
  List<Document> _documents = [];
  bool _isLoading = false;

  List<Pet> get pets => _pets;
  List<MedicalRecord> get medicalRecords => _medicalRecords;
  List<VaccinationRecord> get vaccinationRecords => _vaccinationRecords;
  List<Document> get documents => _documents;
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

  Future<void> loadVaccinationRecords(int petId) async {
    try {
      final data = await DBHelper.instance.getVaccinationRecordsByPet(petId);
      _vaccinationRecords
          .removeWhere((record) => record.petId == petId);
      _vaccinationRecords.addAll(
        data.map((item) => VaccinationRecord.fromMap(item)).toList(),
      );
    } catch (e) {
      debugPrint('Error loading vaccination records: $e');
    }
    notifyListeners();
  }

  Future<void> loadDocuments(int petId) async {
    try {
      final data = await DBHelper.instance.getDocumentsByPet(petId);
      _documents.removeWhere((doc) => doc.petId == petId);
      _documents.addAll(
        data.map((item) => Document.fromMap(item)).toList(),
      );
    } catch (e) {
      debugPrint('Error loading pet documents: $e');
    }
    notifyListeners();
  }

  Future<void> loadPetDetails(int petId) async {
    await Future.wait([
      loadMedicalRecords(petId),
      loadVaccinationRecords(petId),
      loadDocuments(petId),
    ]);
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

  Future<bool> addVaccinationRecord(VaccinationRecord record) async {
    try {
      final id =
          await DBHelper.instance.insertVaccinationRecord(record.toMap());
      final newRecord = record.copyWith(id: id);
      _vaccinationRecords.add(newRecord);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error adding vaccination record: $e');
      return false;
    }
  }

  Future<bool> updateVaccinationRecord(VaccinationRecord record) async {
    if (record.id == null) return false;
    try {
      await DBHelper.instance.updateVaccinationRecord(
        record.id!,
        record.toMap(),
      );
      final index = _vaccinationRecords.indexWhere((r) => r.id == record.id);
      if (index != -1) {
        _vaccinationRecords[index] = record;
        notifyListeners();
      }
      return true;
    } catch (e) {
      debugPrint('Error updating vaccination record: $e');
      return false;
    }
  }

  Future<bool> deleteVaccinationRecord(int id) async {
    try {
      await DBHelper.instance.deleteVaccinationRecord(id);
      _vaccinationRecords.removeWhere((record) => record.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error deleting vaccination record: $e');
      return false;
    }
  }

  Future<bool> addDocument(Document document) async {
    try {
      final id = await DBHelper.instance.insertDocument(document.toMap());
      final newDocument = Document(
        id: id,
        petId: document.petId,
        fileName: document.fileName,
        fileType: document.fileType,
        filePath: document.filePath,
        description: document.description,
        uploadDate: document.uploadDate,
      );
      _documents.add(newDocument);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error adding document: $e');
      return false;
    }
  }

  Future<bool> deleteDocument(int id) async {
    try {
      await DBHelper.instance.deleteDocument(id);
      _documents.removeWhere((doc) => doc.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error deleting document: $e');
      return false;
    }
  }

  Pet? getPetById(int id) {
    try {
      return _pets.firstWhere((pet) => pet.id == id);
    } catch (_) {
      return null;
    }
  }

  List<Pet> getPetsByOwner(int ownerId) {
    return _pets.where((pet) => pet.ownerId == ownerId).toList();
  }

  List<MedicalRecord> getMedicalRecordsByPet(int petId) {
    return _medicalRecords.where((record) => record.petId == petId).toList();
  }

  List<VaccinationRecord> getVaccinationRecordsByPet(int petId) {
    return _vaccinationRecords
        .where((record) => record.petId == petId)
        .toList();
  }

  List<Document> getDocumentsByPet(int petId) {
    return _documents.where((doc) => doc.petId == petId).toList();
  }
}
