// lib/providers/medical_provider.dart
import 'package:flutter/material.dart';
import '../db/db_helper.dart';
import '../models/medical_record.dart';

class MedicalProvider extends ChangeNotifier {
  List<MedicalRecord> _medicalRecords = [];
  bool _isLoading = false;

  List<MedicalRecord> get medicalRecords => _medicalRecords;
  bool get isLoading => _isLoading;

  Future<void> loadMedicalRecords({int? doctorId}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await DBHelper.instance.getMedicalRecords(
        doctorId: doctorId,
      );
      _medicalRecords = data
          .map((item) => MedicalRecord.fromMap(item))
          .toList();
    } catch (e) {
      debugPrint('Error loading medical records: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMedicalRecordsByPet(int petId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await DBHelper.instance.getMedicalRecordsByPet(petId);
      _medicalRecords = data
          .map((item) => MedicalRecord.fromMap(item))
          .toList();
    } catch (e) {
      debugPrint('Error loading medical records by pet: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<MedicalRecord> getMedicalRecordsByPet(int petId) {
    return _medicalRecords.where((record) => record.petId == petId).toList();
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

  Future<bool> updateMedicalRecord(MedicalRecord record) async {
    if (record.id == null) return false;

    try {
      await DBHelper.instance.updateMedicalRecord(record.id!, record.toMap());
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

  Future<bool> deleteMedicalRecord(int id) async {
    try {
      await DBHelper.instance.deleteMedicalRecord(id);
      _medicalRecords.removeWhere((record) => record.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error deleting medical record: $e');
      return false;
    }
  }
}
