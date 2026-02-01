// lib/providers/schedule_provider.dart
// Schedule Provider using Supabase for global sync
// Supports both int (local DB) and String (UUID) doctor IDs
// Migrated to Supabase database (PostgreSQL) - 2026-01-31

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/supabase_complete_service.dart';
import '../models/schedule.dart';

/// ScheduleProvider - Supabase Database Integration
///
/// Database: Supabase (PostgreSQL)
/// Tables used: schedules, system_settings
///
/// All database operations now use Supabase client exclusively.
/// Firestore has been completely removed.
class ScheduleProvider extends ChangeNotifier {
  // Supabase service instance for database operations
  final SupabaseCompleteService _supabaseService =
      SupabaseCompleteService.instance;

  List<DoctorSchedule> _schedules = [];
  Map<String, dynamic> _systemSettings = {};
  bool _isLoading = false;
  String? _currentDoctorId; // String for Supabase UUID queries

  List<DoctorSchedule> get schedules => _schedules;
  bool get isLoading => _isLoading;

  // Set current doctor and load their schedules
  // Accepts both int (local) and String (UUID) IDs
  void setCurrentDoctorId(dynamic doctorId) {
    // Convert to String for Supabase
    if (doctorId == null) {
      _currentDoctorId = null;
      return;
    }
    _currentDoctorId = doctorId.toString();
    loadSchedules(_currentDoctorId!);
  }

  // Load schedules from Supabase
  Future<void> loadSchedules(String doctorId) async {
    _isLoading = true;
    notifyListeners();

    try {
      // DEBUG: Log database read operation
      debugPrint('===========================================');
      debugPrint('DATABASE READ: Loading schedules from Supabase');
      debugPrint('DATABASE READ: Doctor ID: $doctorId');
      debugPrint('DATABASE READ: Table: schedules');

      final schedulesData = await _supabaseService.getSchedulesByDoctor(
        doctorId,
      );

      debugPrint('DATABASE READ: Found ${schedulesData.length} records');

      _schedules = schedulesData.map((data) {
        // Keep String UUID for Supabase compatibility
        debugPrint('DATABASE READ: Schedule ID: ${data['id']}');
        debugPrint('DATABASE READ: Schedule Data: $data');
        return DoctorSchedule.fromMap(data);
      }).toList();

      debugPrint('DATABASE READ: All schedules loaded successfully');
      debugPrint('===========================================');
    } catch (e) {
      debugPrint('Error loading schedules from Supabase: $e');
      _schedules = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load system settings from Supabase
  Future<void> loadSystemSettings() async {
    try {
      _systemSettings = await _supabaseService.getSystemSettings();
    } catch (e) {
      debugPrint('Error loading system settings: $e');
      _systemSettings = {};
    }
  }

  // Get system working hours
  String getSystemWorkingHoursStart() {
    return _systemSettings['working_hours_start'] ?? '08:00';
  }

  String getSystemWorkingHoursEnd() {
    return _systemSettings['working_hours_end'] ?? '18:00';
  }

  // Validate schedule against system working hours
  bool isScheduleValid(DoctorSchedule schedule) {
    final systemStart = getSystemWorkingHoursStart();
    final systemEnd = getSystemWorkingHoursEnd();

    final scheduleStart = schedule.startTime;
    final scheduleEnd = schedule.endTime;

    debugPrint('Validating schedule: $scheduleStart - $scheduleEnd');
    debugPrint('System hours: $systemStart - $systemEnd');

    if (schedule.isHoliday) {
      debugPrint('Validation passed: Holiday day (no work)');
      return true;
    }

    if (schedule.isFreeDay) {
      final startMinutes = _parseTime(scheduleStart);
      final endMinutes = _parseTime(scheduleEnd);
      final systemStartMinutes = _parseTime(systemStart);
      final systemEndMinutes = _parseTime(systemEnd);

      if (startMinutes >= systemStartMinutes &&
          endMinutes <= systemEndMinutes) {
        debugPrint(
          'Validation passed: Free day times are within system bounds',
        );
        return true;
      } else {
        debugPrint(
          'Validation failed: Free day times must be within system working hours',
        );
        return false;
      }
    }

    final startMinutes = _parseTime(scheduleStart);
    final endMinutes = _parseTime(scheduleEnd);
    final systemStartMinutes = _parseTime(systemStart);
    final systemEndMinutes = _parseTime(systemEnd);

    if (startMinutes >= systemStartMinutes && endMinutes <= systemEndMinutes) {
      debugPrint('Validation passed: Schedule is within system working hours');
      return true;
    } else {
      debugPrint(
        'Validation failed: Schedule must be within system working hours ($systemStart - $systemEnd)',
      );
      return false;
    }
  }

  // Add or update a schedule in Supabase
  Future<bool> saveSchedule(DoctorSchedule schedule) async {
    if (!isScheduleValid(schedule)) {
      debugPrint(
        'Schedule validation failed: times outside system working hours',
      );
      return false;
    }

    if (schedule.isHoliday) {
      final holidayCount = _schedules.where((s) => s.isHoliday).length;
      if (holidayCount >= 2 &&
          !_schedules.any((s) => s.id == schedule.id && s.isHoliday)) {
        debugPrint('Validation failed: Maximum 2 holiday days allowed');
        return false;
      }
    }

    try {
      // Ensure doctorId is a String for Supabase
      final supabaseDoctorId = schedule.doctorId.toString();

      final scheduleData = schedule.toMap()..remove('id');
      scheduleData['doctor_id'] = supabaseDoctorId;
      scheduleData.remove('doctorId');

      // DEBUG: Log data being sent to Supabase
      debugPrint('===========================================');
      debugPrint('PROVIDER DEBUG: Saving schedule to Supabase');
      debugPrint('PROVIDER DEBUG: Schedule ID: ${schedule.id ?? "NEW"}');
      debugPrint('PROVIDER DEBUG: Doctor ID: $supabaseDoctorId');
      debugPrint('PROVIDER DEBUG: Day: ${schedule.dayOfWeek}');
      debugPrint('PROVIDER DEBUG: Start Time: ${schedule.startTime}');
      debugPrint('PROVIDER DEBUG: End Time: ${schedule.endTime}');
      debugPrint('PROVIDER DEBUG: Is Holiday: ${schedule.isHoliday}');
      debugPrint('PROVIDER DEBUG: Is Free Day: ${schedule.isFreeDay}');
      debugPrint('PROVIDER DEBUG: Data: $scheduleData');
      debugPrint(
        'PROVIDER DEBUG: Timestamp: ${DateTime.now().toIso8601String()}',
      );
      debugPrint('===========================================');

      if (schedule.id == null || schedule.id!.isEmpty) {
        // Create new schedule
        final scheduleId = await _supabaseService.insertSchedule(scheduleData);
        // Use String UUID for Supabase compatibility

        final newSchedule = schedule.copyWith(
          id: scheduleId,
          doctorId: supabaseDoctorId,
        );
        _schedules.add(newSchedule);
        debugPrint('PROVIDER DEBUG: New schedule created with ID: $scheduleId');
      } else {
        // Update existing schedule
        final scheduleIdStr = schedule.id.toString();
        await _supabaseService.updateSchedule(scheduleIdStr, scheduleData);

        final index = _schedules.indexWhere((s) => s.id == schedule.id);
        if (index != -1) {
          _schedules[index] = schedule.copyWith(doctorId: supabaseDoctorId);
        }
        debugPrint('PROVIDER DEBUG: Existing schedule updated: ${schedule.id}');
      }
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error saving schedule to Supabase: $e');
      return false;
    }
  }

  // Delete a schedule from Supabase
  Future<bool> deleteSchedule(dynamic scheduleId) async {
    try {
      final scheduleIdStr = scheduleId.toString();
      await _supabaseService.deleteSchedule(scheduleIdStr);
      _schedules.removeWhere((s) => s.id == scheduleId);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error deleting schedule from Supabase: $e');
      return false;
    }
  }

  // Get schedule for a specific day
  DoctorSchedule? getScheduleForDay(dynamic doctorId, String dayOfWeek) {
    final docId = doctorId?.toString() ?? '';
    return _schedules.firstWhere(
      (schedule) =>
          schedule.doctorId == docId && schedule.dayOfWeek == dayOfWeek,
      orElse: () => DoctorSchedule(
        doctorId: docId,
        dayOfWeek: dayOfWeek,
        startTime: '08:00',
        endTime: '18:00',
        isActive: false,
        isHoliday: false,
        isFreeDay: false,
      ),
    );
  }

  // Check if doctor is available at a specific time
  bool isDoctorAvailable(dynamic doctorId, String dayOfWeek, String time) {
    final schedule = getScheduleForDay(doctorId, dayOfWeek);
    if (schedule == null || !schedule.isActive) return false;

    final startTime = _parseTime(schedule.startTime);
    final endTime = _parseTime(schedule.endTime);
    final checkTime = _parseTime(time);

    return checkTime >= startTime && checkTime <= endTime;
  }

  // Helper method to parse time string to minutes since midnight
  int _parseTime(String time) {
    final parts = time.split(':');
    if (parts.length != 2) return 0;
    final hours = int.tryParse(parts[0]) ?? 0;
    final minutes = int.tryParse(parts[1]) ?? 0;
    return hours * 60 + minutes;
  }

  // Clear schedules (useful when switching doctors)
  void clearSchedules() {
    _schedules = [];
    notifyListeners();
  }
}
