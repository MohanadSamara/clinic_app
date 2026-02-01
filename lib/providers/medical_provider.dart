// lib/providers/medical_provider.dart
// Migrated to Supabase database (PostgreSQL) - 2026-01-31
// All data synced globally across devices via Supabase

import 'package:flutter/material.dart';
import '../services/supabase_complete_service.dart';
import '../models/medical_record.dart';

/// MedicalProvider - Supabase Database Integration
///
/// Database: Supabase (PostgreSQL)
/// Tables used: medical_records
///
/// All database operations now use Supabase client exclusively.
/// Firestore has been completely removed.
class MedicalProvider extends ChangeNotifier {
  List<MedicalRecord> _medicalRecords = [];
  bool _isLoading = false;
  String? _error;

  List<MedicalRecord> get medicalRecords => _medicalRecords;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Supabase service instance for database operations (singleton)
  final SupabaseCompleteService _supabaseService =
      SupabaseCompleteService.instance;

  // ========== LOAD DATA ==========

  Future<void> loadMedicalRecords({String? doctorId}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final records = await _supabaseService.getMedicalRecords(
        doctorId: doctorId,
      );

      _medicalRecords = records.map((data) {
        data['id'] = data['id'] ?? data['id'];
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

  Future<void> loadMedicalRecordsByPet(String petId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final records = await _supabaseService.getMedicalRecords(petId: petId);

      final seenIds = <String>{};
      _medicalRecords = records
          .map((data) {
            final id = data['id'] as String?;
            if (id == null) return null;
            final record = MedicalRecord.fromMap(data);
            if (!seenIds.contains(id)) {
              seenIds.add(id);
              return record;
            }
            return null;
          })
          .where((record) => record != null && record.id != null)
          .cast<MedicalRecord>()
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
      // Add to Supabase
      final recordData = record.toMap();
      final id = await _supabaseService.insertMedicalRecord(recordData);

      // Create local record object
      final newRecord = record.copyWith(id: id);

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
      // Find the record in local state to get the UUID
      final localRecord = _medicalRecords.firstWhere((r) => r.id == record.id);

      // Update in Supabase
      await _supabaseService.updateMedicalRecord(
        localRecord.id.toString(),
        record.toMap(),
      );

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

  Future<bool> deleteMedicalRecord(String id) async {
    try {
      // Find the record in local state
      final localRecord = _medicalRecords.firstWhere((r) => r.id == id);

      // Delete from Supabase
      await _supabaseService.deleteMedicalRecord(localRecord.id.toString());

      _medicalRecords.removeWhere((record) => record.id == id);
      notifyListeners();

      return true;
    } catch (e) {
      debugPrint('Error deleting medical record: $e');
      return false;
    }
  }

  // ========== HELPERS ==========

  List<MedicalRecord> getMedicalRecordsByPet(String petId) {
    return _medicalRecords.where((record) => record.petId == petId).toList();
  }

  MedicalRecord? getMedicalRecordById(String id) {
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
